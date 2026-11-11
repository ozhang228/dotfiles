import { existsSync, readFileSync, readdirSync, realpathSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join, resolve, sep } from "node:path";
import { createFindToolDefinition, createLsToolDefinition } from "@earendil-works/pi-coding-agent";

function hiddenMounts() {
  const directory = process.env.PI_SANDBOX_HIDDEN_MOUNTS;
  if (!directory) return [];
  return readdirSync(directory)
    .filter((name) => name.endsWith(".json"))
    .flatMap((name) => {
      let paths: unknown;
      try {
        paths = JSON.parse(readFileSync(join(directory, name), "utf8"));
      } catch (error: unknown) {
        // A worker may finish between listing the manifests and reading one.
        if (error instanceof Error && "code" in error && error.code === "ENOENT") return [];
        throw error;
      }
      if (
        !Array.isArray(paths) ||
        !paths.every((path: unknown) => typeof path === "string" && isAbsolute(path))
      )
        throw new Error("Invalid synthetic mount paths");
      return paths.filter((path: unknown): path is string => typeof path === "string");
    });
}

function isHidden(path: string, mounts: readonly string[]) {
  return mounts.some((mount) => path === mount || path.startsWith(mount + sep));
}

export function sandboxLs(cwd: string) {
  return createLsToolDefinition(cwd, {
    operations: {
      exists: existsSync,
      stat: statSync,
      readdir(path) {
        const mounts = hiddenMounts();
        const directory = realpathSync(path);
        return readdirSync(path).filter((name) => !isHidden(join(directory, name), mounts));
      },
    },
  });
}

export function sandboxFind(cwd: string) {
  const native = createFindToolDefinition(cwd);
  return {
    ...native,
    async execute(...parameters: Parameters<typeof native.execute>) {
      const [, args, , , ctx] = parameters;
      const mounts = hiddenMounts();
      const result = await native.execute(...parameters);
      const hidden = [...mounts, ...hiddenMounts()];
      if (!hidden.length) return result;
      const path = (args.path || ".").replace(/^@/, "").replace(/^~(?=\/|$)/, homedir());
      const root = realpathSync(resolve(ctx?.cwd || cwd, path));
      return {
        ...result,
        content: result.content.map((item) => {
          if (item.type !== "text") return item;
          const text = item.text
            .split("\n")
            .filter((line) => !isHidden(resolve(root, line), hidden))
            .join("\n");
          return { ...item, text: text || "No files found matching pattern" };
        }),
      };
    },
  };
}
