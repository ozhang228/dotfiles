# Wrapper around jq for mixed JSON/string streams with colors and error handling baked in.
# JSON lines are parsed, formatted, and colored. Plain strings pass through as-is.
# Usage: cat app.log | jqp
#        cat app.log | jqp 'select(.level == "error")'
#        cat app.log | jqp 'select(.duration_ms > 300) | .message'

function jqp
    set -l filter $argv[1]
    if test -z "$filter"
        set filter '.'
    end
    jq -R ". as \$raw | try (fromjson | $filter) catch \$raw" --color-output
end
