import { randomUUID } from "node:crypto";
import { appendFileSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

export type Task = { name: string; task: string; context: string };
export type Status = "running" | "done" | "failed" | "cancelled";
export type Row = { name: string; status: Status; activity: string };
export type Result = Row & { answer: string; log: string };
export type WorkerSession = {
  subscribe(listener: (event: unknown) => void): () => void;
  prompt(text: string): Promise<void>;
  answer: string;
  abort(): Promise<void>;
  dispose(): void;
};
type WorkerOptions<Model, Effort> = {
  task: Task;
  model: Model;
  effort: Effort;
  signal: AbortSignal;
};
type Log = { path: string; bytes: number };
type Batch = { logs: Map<string, Log>; completed: boolean; bytes: number };

function explanation(error: unknown) {
  return error instanceof Error ? error.message : String(error);
}

export class BatchRunner<Model, Effort> {
  private readonly directory = mkdtempSync(join(tmpdir(), "pi-subagents-"));
  private readonly batches: Batch[] = [];
  private readonly active = new Set<{ stop: AbortController; settled: Promise<Result[]> }>();
  private readonly create:
    | ((options: WorkerOptions<Model, Effort>) => Promise<WorkerSession>)
    | undefined;
  private readonly workerBytes: number;
  private readonly totalBytes: number;
  private closed = false;
  private cachedLog: { handle: string; content: string } | undefined;

  constructor(options: {
    create?: (options: WorkerOptions<Model, Effort>) => Promise<WorkerSession>;
    workerBytes?: number;
    totalBytes?: number;
  }) {
    this.create = options.create;
    this.workerBytes = options.workerBytes ?? 2 * 1024 * 1024;
    this.totalBytes = options.totalBytes ?? 32 * 1024 * 1024;
    if (this.workerBytes < 1536 || this.totalBytes < 4 * this.workerBytes)
      throw new Error("Log budget must reserve space for four complete workers");
  }

  readLog(options: { handle: string; offset: number; limit: number }) {
    if (
      !Number.isInteger(options.offset) ||
      options.offset < 0 ||
      !Number.isInteger(options.limit) ||
      options.limit < 1 ||
      options.limit > 16384
    )
      throw new Error("Log pages require a nonnegative offset and 1–16384 characters");
    const batch = this.batches.find((entry) => entry.logs.has(options.handle));
    const log = batch?.logs.get(options.handle);
    if (this.closed || !log) throw new Error("Subagent log expired or unknown");
    const content =
      this.cachedLog?.handle === options.handle
        ? this.cachedLog.content
        : readFileSync(log.path, "utf8");
    // Retain at most one decoded transcript; active logs must remain fresh.
    if (batch?.completed && log.bytes <= 2 * 1024 * 1024)
      this.cachedLog = { handle: options.handle, content };
    const text = content.slice(options.offset, options.offset + options.limit);
    const nextOffset = options.offset + text.length;
    return { text, nextOffset, done: nextOffset >= content.length };
  }

  run(options: {
    tasks: readonly Task[];
    model: Model;
    effort: Effort;
    signal?: AbortSignal;
    update?: (rows: Row[]) => void;
    create?: (options: WorkerOptions<Model, Effort>) => Promise<WorkerSession>;
  }) {
    const create = options.create ?? this.create;
    if (!create) throw new Error("Provide a worker session factory");
    if (this.closed) throw new Error("Subagents stopped");
    if (this.active.size) throw new Error("A subagent batch is already running");
    if (
      options.tasks.length < 1 ||
      options.tasks.length > 4 ||
      new Set(options.tasks.map((task) => task.name)).size !== options.tasks.length
    )
      throw new Error("Provide one to four uniquely named tasks");
    while (
      this.batches.length >= 16 ||
      this.batches.reduce((bytes, batch) => bytes + batch.bytes, 0) + 4 * this.workerBytes >
        this.totalBytes
    ) {
      const old = this.batches[0];
      if (!old?.completed) throw new Error("Subagent log retention budget exhausted");
      this.batches.shift();
      if (this.cachedLog && old.logs.has(this.cachedLog.handle)) this.cachedLog = undefined;
      for (const log of old.logs.values()) rmSync(log.path);
    }
    const batch: Batch = { logs: new Map(), bytes: 0, completed: false };
    this.batches.push(batch);
    const stop = new AbortController();
    const cancel = () => stop.abort();
    options.signal?.addEventListener("abort", cancel, { once: true });
    if (options.signal?.aborted) stop.abort();
    const rows: Row[] = options.tasks.map((task) => ({
      name: task.name,
      status: "running",
      activity: "starting",
    }));
    const publish = () => options.update?.(rows.map((row) => ({ ...row })));
    const handles = options.tasks.map(() => randomUUID());
    const workers = options.tasks.map(async (task, index): Promise<Result> => {
      const row = rows[index];
      if (!row) throw new Error("Missing task status");
      const handle = handles[index];
      if (!handle) throw new Error("Missing log handle");
      const log = { path: join(this.directory, `${handle}.jsonl`), bytes: 0 };
      batch.logs.set(handle, log);
      writeFileSync(log.path, "", { mode: 0o600 });
      const childStop = new AbortController();
      const signal = AbortSignal.any([stop.signal, childStop.signal]);
      let session: WorkerSession | undefined;
      let unsubscribe: (() => void) | undefined;
      let aborting: Promise<void> | undefined;
      let logError: string | undefined;
      const record = (event: unknown) => {
        const line = `${JSON.stringify(event)}\n`;
        const bytes = Buffer.byteLength(line);
        if (log.bytes + bytes > this.workerBytes - 1024) {
          logError =
            "Worker transcript budget exceeded; worker stopped before recording the next event";
          childStop.abort();
          return;
        }
        appendFileSync(log.path, line);
        log.bytes += bytes;
        batch.bytes += bytes;
      };
      const abort = () => {
        if (session && !aborting) {
          aborting = session.abort();
          void aborting.catch(() => {});
        }
      };
      signal.addEventListener("abort", abort, { once: true });
      let answer = "";
      try {
        record({ type: "dispatch", task, effort: options.effort });
        signal.throwIfAborted();
        session = await create({ task, model: options.model, effort: options.effort, signal });
        signal.throwIfAborted();
        unsubscribe = session.subscribe((event) => {
          if (logError) return;
          if (typeof event === "object" && event !== null && "type" in event) {
            // Updates contain cumulative snapshots; terminal messages retain the
            // complete transcript without quadratic storage growth.
            try {
              if (event.type !== "message_update" && event.type !== "tool_execution_update")
                record(event);
            } catch (error: unknown) {
              logError = `Transcript storage failed: ${explanation(error)}`;
              childStop.abort();
            }
            if ("toolName" in event && typeof event.toolName === "string")
              row.activity = event.toolName;
            else if (event.type === "message_update") row.activity = "thinking";
            publish();
          }
        });
        publish();
        await session.prompt(`Task: ${task.task}\n\nParent context:\n${task.context}`);
        if (logError) throw new Error(logError);
        signal.throwIfAborted();
        answer = session.answer;
        row.status = "done";
      } catch (error: unknown) {
        row.status = logError ? "failed" : signal.aborted ? "cancelled" : "failed";
        answer = logError ?? (signal.aborted ? "Cancelled" : explanation(error));
      } finally {
        if (session) {
          try {
            abort();
            await aborting;
          } catch (error: unknown) {
            row.status = "failed";
            answer = `Worker cleanup failed: ${explanation(error)}`;
          } finally {
            try {
              unsubscribe?.();
              session.dispose();
            } catch (error: unknown) {
              row.status = "failed";
              answer = `Worker disposal failed: ${explanation(error)}`;
            }
          }
        }
        signal.removeEventListener("abort", abort);
        row.activity = "";
        // Reserve the final diagnostic independently of streamed event budget.
        const line = `${JSON.stringify({ type: "terminal", status: row.status, diagnostic: row.status === "done" ? undefined : answer.slice(0, 100) })}\n`;
        try {
          appendFileSync(log.path, line);
          log.bytes += Buffer.byteLength(line);
          batch.bytes += Buffer.byteLength(line);
        } catch (error: unknown) {
          row.status = "failed";
          answer = `Transcript storage failed: ${explanation(error)}`;
        }
        publish();
      }
      return { ...row, answer, log: handle };
    });
    const settled = Promise.allSettled(workers).then((outcomes) =>
      outcomes.map((outcome, index): Result => {
        if (outcome.status === "fulfilled") return outcome.value;
        const row = rows[index];
        const log = handles[index];
        if (!row || !log) throw new Error("Missing worker result");
        return { ...row, status: "failed", activity: "", answer: explanation(outcome.reason), log };
      }),
    );
    const active = { stop, settled };
    this.active.add(active);
    return settled.finally(() => {
      batch.completed = true;
      this.active.delete(active);
      options.signal?.removeEventListener("abort", cancel);
    });
  }

  async close() {
    this.closed = true;
    this.cachedLog = undefined;
    for (const active of this.active) active.stop.abort();
    await Promise.allSettled([...this.active].map((active) => active.settled));
    rmSync(this.directory, { recursive: true, force: true });
  }
}
