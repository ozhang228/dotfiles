#!/usr/bin/env fish

set SCRIPT_DIR (dirname (status -f))

begin
    cat "$SCRIPT_DIR/context.md"
    echo ""
    
    for f in "$SCRIPT_DIR"/drw_related/*.md
        echo "---"
        echo ""
        cat "$f"
        echo ""
    end
end | xclip -selection clipboard
