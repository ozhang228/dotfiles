local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  s("marimonb", {
    t({ "import marimo", "", 'app = marimo.App(width="full")', "", "with app.setup:", "    " }),
    i(1, "pass"),
    t({ "", "", "", "@app.cell", "def " }),
    i(2, "_"),
    t({ "():", "    " }),
    i(0),
    t({ "", "    return", "", "", 'if __name__ == "__main__":', "    app.run()", "" }),
  }),

  s("@app.cell", {
    t({ "@app.cell", "def " }),
    i(1, "_"),
    t({ "():", "    " }),
    i(0),
    t({ "", "    return" }),
  }),

  s("mo.md", {
    t({ 'mo.md("""', "" }),
    i(1),
    t({ "", '""")' }),
  }),
}
