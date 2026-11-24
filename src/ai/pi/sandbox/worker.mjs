import { spawn } from "node:child_process";
import { Socket } from "node:net";
import { lstatSync, readFileSync } from "node:fs";
import { dirname } from "node:path";
import { once } from "node:events";
import { createInterface } from "node:readline";
import { pathToFileURL } from "node:url";

function quote(value) {
  return `'${value.replaceAll("'", "'\\''")}'`;
}

function bounded(value, limit) {
  if (typeof value === "string") {
    const text = value.replace(
      /\[Showing [^\n]*Full output:[^\n]*\]/g,
      "[Sandbox output limited; full output is not retained.]",
    );
    return Buffer.from(text).subarray(0, limit).toString("utf8");
  }
  if (Array.isArray(value)) return value.map((item) => bounded(item, limit));
  if (value !== null && typeof value === "object") {
    const result = Object.fromEntries(
      Object.entries(value)
        .filter(([key]) => key !== "fullOutputPath" && key !== "full_output_path")
        .map(([key, item]) => [key, bounded(item, limit)]),
    );
    if (typeof value.output === "string" && Buffer.byteLength(value.output) > limit)
      result.truncated = true;
    return result;
  }
  return value;
}

function emit(type, result) {
  let limit = 65536;
  let message = JSON.stringify({ type, result: bounded(result, limit) });
  while (Buffer.byteLength(message) > 262000 && limit > 1024) {
    limit /= 2;
    message = JSON.stringify({ type, result: bounded(result, limit) });
  }
  if (Buffer.byteLength(message) > 262000) throw new Error("Worker output exceeds transport limit");
  process.stdout.write(`${message}\n`);
}

async function executeNative(modulePath) {
  const lines = createInterface({ input: process.stdin });
  const [line] = await once(lines, "line");
  lines.close();
  const request = JSON.parse(line);
  const factories = {
    edit: "createEditToolDefinition",
    write: "createWriteToolDefinition",
    bash: "createBashToolDefinition",
  };
  if (!Object.hasOwn(factories, request.tool)) throw new Error("Unsupported worker tool");
  const tools = await import(new URL(`./${request.tool}.js`, pathToFileURL(modulePath)).href);
  const factory = tools[factories[request.tool]];
  if (typeof factory !== "function") throw new Error("Unsupported Pi tool module");
  const tool = factory(process.cwd());
  const result = await tool.execute(
    "sandbox",
    request.args,
    new AbortController().signal,
    (update) => emit("update", update),
  );
  emit("result", result);
}

async function supervise(runtimePath, policyPath, lifelineFd, modulePath, lockFd) {
  const lifeline = new Socket({ fd: Number(lifelineFd), readable: true, writable: false });
  let child;
  let disconnected = false;
  const interrupt = new AbortController();
  function stop() {
    disconnected = true;
    interrupt.abort();
    child?.kill("SIGKILL");
  }
  lifeline.on("end", stop);
  lifeline.on("error", stop);
  lifeline.resume();
  process.on("SIGINT", stop);
  process.on("SIGTERM", stop);
  const { SandboxManager } = await import(pathToFileURL(runtimePath).href);
  try {
    await SandboxManager.initialize(JSON.parse(readFileSync(policyPath, "utf8")));
    if (disconnected) throw new Error("Controller disconnected");
    const { linuxGetCwdMandatoryDenyPaths } = await import(
      new URL("./sandbox/linux-sandbox-utils.js", pathToFileURL(runtimePath)).href
    );
    const missing = new Set();
    for (const denied of linuxGetCwdMandatoryDenyPaths()) {
      let candidate;
      for (let path = denied; path !== dirname(path); path = dirname(path)) {
        try {
          lstatSync(path);
          break;
        } catch (error) {
          if (error.code !== "ENOENT" && error.code !== "ENOTDIR") throw error;
          candidate = path;
        }
      }
      if (candidate) missing.add(candidate);
    }
    const command = [process.execPath, import.meta.filename, "native", modulePath]
      .map(quote)
      .join(" ");
    const wrapped = await SandboxManager.wrapWithSandbox(
      command,
      undefined,
      undefined,
      interrupt.signal,
    );
    if (disconnected) throw new Error("Controller disconnected");
    // exec makes bwrap our direct child: --die-with-parent protects supervisor crashes.
    child = spawn(`exec ${wrapped}`, {
      shell: "/bin/sh",
      stdio: ["inherit", "inherit", "inherit", Number(lockFd)],
      env: {
        ...process.env,
        PI_SANDBOX_LOCK_FD: "3",
        PI_SANDBOX_MISSING_PATHS: JSON.stringify([...missing]),
      },
    });
    const [code, signal] = await once(child, "exit");
    process.exitCode = disconnected || signal ? 1 : (code ?? 1);
  } finally {
    SandboxManager.cleanupAfterCommand();
    await SandboxManager.reset();
    lifeline.destroy();
  }
}

try {
  if (process.argv[2] === "native") await executeNative(process.argv[3]);
  else if (process.argv[2] === "supervise") await supervise(...process.argv.slice(3));
  else throw new Error("Invalid worker mode");
} catch (error) {
  process.stdout.write(
    `${JSON.stringify({ type: "error", error: error instanceof Error ? error.message : "Worker failed" })}\n`,
  );
  process.exitCode = 1;
}
