set -gx NVM_DIR "$HOME/.nvm"
if status is-interactive; and test -s "$NVM_DIR/nvm.sh"
    set -l default_version
    if test -r "$NVM_DIR/alias/default"
        read default_version <"$NVM_DIR/alias/default"
    end
    set -l default_root "$NVM_DIR/versions/node/v"(string replace -r '^v' '' -- "$default_version")
    if test "$NVM_BIN" != "$default_root/bin"
        or test "$NVM_INC" != "$default_root/include/node"
        or test "$(command -s node)" != "$default_root/bin/node"
        or test "$(command -s npm)" != "$default_root/bin/npm"
        or test "$(command -s npx)" != "$default_root/bin/npx"
        or test "$NVM_SYMLINK_CURRENT" = true
        bass source "$NVM_DIR/nvm.sh" --no-use ';' nvm use default >/dev/null 2>&1
    end
end
