return {
  "L3MON4D3/LuaSnip",
  build = "make install_jsregexp",
  config = function()
    local ls = require("luasnip")

    ls.config.set_config({
      history = true,
      updateevents = "TextChanged,TextChangedI",
    })

    -- load from multiple folders
    require("luasnip.loaders.from_lua").lazy_load({
      paths = {
        vim.fn.stdpath("config") .. "/lua/snippets",
      },
    })
  end,
}
