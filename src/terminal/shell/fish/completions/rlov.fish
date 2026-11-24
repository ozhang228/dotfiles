complete -c rlov -f
complete -c rlov -n "test (count (commandline -opc)) -eq 1" -a "(rlov complete apps)"
complete -c rlov -n "test (count (commandline -opc)) -eq 2" -a "(rlov complete components (commandline -opc)[2])"

