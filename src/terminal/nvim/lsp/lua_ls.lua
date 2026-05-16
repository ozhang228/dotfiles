---@type vim.lsp.Config
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = {
    { ".emmyrc.json", ".luarc.json", ".luarc.jsonc" },
    { ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml" },
    { ".git" },
  },
  settings = {
    Lua = {
      codeLens = { enable = true },
      completion = {
        postfix = ".",
      },
      hint = {
        enable = true,
        semicolon = "Disable",
        setType = true,
        arrayIndex = "Enable",
      },
      signatureHelp = { enabled = true },
      telemetry = { enable = false },
      workspace = {
        checkThirdParty = "Disable",
      },
    },
  },
}
