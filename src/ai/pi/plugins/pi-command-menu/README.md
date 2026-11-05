# Pi command menu

Filters slash-command autocomplete using `allowed-commands.json`. Command names
omit the leading `/`; `skill:*` includes every loaded skill automatically.
Unlisted commands remain callable when typed in full. Argument suggestions,
file completion, and keyboard shortcuts are preserved.

Edit the whitelist and run `/reload` in Pi. The extension is enabled in
`src/ai/pi/settings.json`; no package installation is needed.

Run the tests against the installed Pi modules:

```sh
NODE_PATH=/usr/lib/pi/lib/node_modules /usr/lib/drw-nodejs-pi/bin/node --test src/ai/pi/plugins/pi-command-menu/index.test.mjs
```
