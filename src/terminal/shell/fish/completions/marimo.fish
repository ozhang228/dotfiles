function _marimo_completion
    set -l response (env _MARIMO_COMPLETE=fish_complete COMP_WORDS=(commandline -cp) COMP_CWORD=(commandline -t) marimo)

    for i in (seq 1 3 (count $response))
        set -l type $response[$i]
        set -l value $response[(math $i + 1)]
        set -l help $response[(math $i + 2)]

        if test "$type" = "dir"
            __fish_complete_directories $value
        else if test "$type" = "file"
            __fish_complete_path $value
        else if test "$type" = "plain"
            if test "$help" != "_"
                echo $value\t$help
            else
                echo $value
            end
        end
    end
end

complete --no-files --command marimo --arguments "(_marimo_completion)"
