import { access } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { createServer } from "vite";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";

const rendererDirectory = fileURLToPath(new URL("..", import.meta.url));
const planPath = join(rendererDirectory, ".runtime", "plan.mdx");
await access(planPath);
const vite = await createServer({
  appType: "custom",
  root: rendererDirectory,
  server: { middlewareMode: true },
});

try {
  const plan = await vite.ssrLoadModule(planPath);
  const components = await vite.ssrLoadModule(join(rendererDirectory, "src", "planComponents.tsx"));
  const html = renderToStaticMarkup(
    React.createElement(plan.default, { components: components.planComponents }),
  );
  if (html.trim().length === 0) {
    throw new Error("Plan rendered no content.");
  }
  console.log(`SSR_OK length=${html.length}`);
} finally {
  await vite.close();
}
