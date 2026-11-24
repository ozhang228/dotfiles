#!/bin/sh
set -eu

repo_dir=$(dirname "$(dirname "$(dirname "$(readlink -f "$0")")")")
sandbox_dir="$repo_dir/src/ai/pi/sandbox"

if [ "$(uname -s)" != Linux ]; then
    echo 'Pi sandbox setup requires Linux.' >&2
    exit 1
fi

for dependency in python3 npm bwrap socat rg; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        echo "Missing dependency: $dependency. Install it and rerun dotfiles setup." >&2
        exit 1
    fi
done

runtime_dir="$HOME/.local/share/pi-sandbox/runtime"
mkdir -p "$runtime_dir"
cp "$sandbox_dir/package.json" "$sandbox_dir/package-lock.json" "$runtime_dir/"
npm ci --prefix "$runtime_dir" --ignore-scripts --no-audit --no-fund

if python3 "$sandbox_dir/tests/smoke.py"; then
    echo 'Pi sandbox setup passed. Run pi normally.'
    exit 0
fi

restriction=/proc/sys/kernel/apparmor_restrict_unprivileged_userns
if [ -f "$restriction" ] && [ "$(cat "$restriction")" = 1 ]; then
    source_profile="$sandbox_dir/apparmor/bwrap"
    installed_profile=/etc/apparmor.d/pi-bubblewrap
    for profile in /etc/apparmor.d/bwrap /etc/apparmor.d/pi-bubblewrap; do
        if [ -e "$profile" ] || [ -L "$profile" ]; then
            if ! cmp -s "$source_profile" "$profile"; then
                echo "Existing AppArmor profile differs: $profile. Leaving it unchanged." >&2
                exit 1
            fi
            installed_profile="$profile"
        fi
    done
    echo 'Loading the Bubblewrap AppArmor profile (sudo may ask for your password).'
    if [ ! -e "$installed_profile" ]; then
        sudo install -o root -g root -m 644 "$source_profile" "$installed_profile"
    fi
    sudo apparmor_parser -r "$installed_profile"
fi

python3 "$sandbox_dir/tests/smoke.py"
echo 'Pi sandbox setup passed. Run pi normally.'
