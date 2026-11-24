# Miller but pretty
# Wrapper around mlr for CSV with colored, compact table output.
# Right-aligned values, each column gets a distinct color.
# Usage: cat data.csv | mlrp
#        cat data.csv | mlrp cut -f instrument,cash-pnl

function mlrp
    if test (count $argv) -eq 0
        mlr --icsv --opprint --barred --right cat
    else
        mlr --icsv --opprint --barred --right $argv
    end | awk '
        BEGIN {
            CYAN="\033[36m"; RST="\033[0m"
            split("31,32,33,34,35,36,91,92,93,94,95,96", cc, ",")
            ncolors = 12
        }
        /^\+/ { printf "%s%s%s\n", CYAN, $0, RST; next }
        {
            n = split($0, cells, "|")
            line = ""
            for (i = 2; i < n; i++) {
                ci = ((i - 2) % ncolors) + 1
                if (NR == 2) {
                    line = line "|" sprintf("\033[1;%sm%s%s", cc[ci], cells[i], RST)
                } else {
                    line = line "|" sprintf("\033[%sm%s%s", cc[ci], cells[i], RST)
                }
            }
            line = line "|"
            print line
        }
    '
end
