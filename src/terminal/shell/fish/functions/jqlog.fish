# Pipes stdin to both a log file and pretty-printed colored output in the terminal.
# JSON lines are parsed and formatted, plain strings are passed through as-is.
# Usage: your-script 2>&1 | jqlog [-l logfile] [jq-filter]  (logfile defaults to app.log)

function jqlog
    argparse 'l/logfile=' -- $argv
    set -l logfile $_flag_logfile
    if test -z "$logfile"
        set logfile app.log
    end
    tee $logfile | jqp $argv
end
