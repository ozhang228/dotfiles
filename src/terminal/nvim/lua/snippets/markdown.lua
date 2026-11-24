local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  s("\\frac", {
    t("\\frac{}{}"),
    i(0),
  }),

  -- (n choose k)
  s("\\binom", {
    t("\\binom{}{}"),
    i(0),
  }),

  s("\\left", {
    t("\\left \\right"),
    i(0),
  }),
}
