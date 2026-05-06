function fish_title
    set -l branch (git branch --show-current 2>/dev/null)
    set -l label
    if set -q KITTY_TAB_TITLE; and test -n "$KITTY_TAB_TITLE"
        set label $KITTY_TAB_TITLE
    else
        set label (prompt_pwd)
    end
    if test -n "$branch"
        echo "$label [$branch]"
    else
        echo $label
    end
end
