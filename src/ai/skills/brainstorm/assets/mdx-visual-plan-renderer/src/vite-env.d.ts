/// <reference types="vite/client" />

declare module "*.mdx" {
  import type { ComponentType } from "react";
  import type { MDXComponents } from "mdx/types.js";

  const MDXComponent: ComponentType<{ components?: MDXComponents }>;
  export default MDXComponent;
}
