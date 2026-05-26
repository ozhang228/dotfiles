return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  opts = {
    ensure_installed = {
      "typescript",
      "javascript",
      "tsx",
      "html",
      "css",

      "python",

      "c",
      "cpp",

      "lua",
      "luadoc",

      "rust",

      -- Misc
      "json",
      "yaml",
      "vimdoc",
      "markdown",
      "markdown_inline",
      "query",
      "regex",
      "toml",
    },
    highlight = {
      enable = true,
    },
    indent = {
      enable = true,
    },
  },
  build = ":TSUpdate",
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)

    -- nvim-treesitter is archived and its set-lang-from-info-string! directive
    -- uses the pre-0.12 match format (raw TSNode). In 0.12, match[id] is a
    -- table, so node:range() crashes. Overwrite with a 0.12-safe version.
    vim.treesitter.query.add_directive(
      "set-lang-from-info-string!",
      function(match, _, bufnr, pred, metadata)
        local capture_id = pred[2]
        local item = match[capture_id]
        if not item then return end
        -- 0.12 wraps the node in a list; older versions hand it directly
        local node = (type(item) == "table" and item[1]) or item
        if not node or not node.range then return end
        local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
        if not ok or not text then return end
        local alias = text:lower()
        local ft = vim.filetype.match({ filename = "a." .. alias })
        metadata["injection.language"] = ft or alias
      end,
      { force = true, all = false }
    )
  end,
}
