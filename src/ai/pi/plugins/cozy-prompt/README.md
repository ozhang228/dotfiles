# Cozy prompt

A Catppuccin Macchiato composer and compact toolbar for Pi 1.5. Keeps regular
terminal scrollback and the native editor's input, paste, shortcuts, cursor and
autocomplete behavior. No extra commands or keybindings.

The single footer row below the prompt reads Pi's existing project/branch, model, reasoning and context
information. The native working indicator stays embedded in the rounded prompt
border, including compaction and retry progress. Context is shown as unknown
until Pi has a usage estimate. Other extensions' footer statuses remain visible.

The dark composer, lavender frame and `❯` prompt marker match the Macchiato theme. Rows are not
added inside the editor, so native mouse selection remains aligned. Narrow
terminals retain the native border. This is an appearance extension; transcript
tool calls remain visible. In Neovim terminal normal mode you can scroll and
search ordinary terminal history; the composer is not pinned while scrolling.

Run the input and completion regressions against the installed Pi SDK:

```sh
NODE_PATH=/usr/lib/pi/lib/node_modules /usr/lib/drw-nodejs-pi/bin/node --test src/ai/pi/plugins/cozy-prompt/index.test.mjs
```
