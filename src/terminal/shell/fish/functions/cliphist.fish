function cliphist
  set cyan (set_color cyan)
  set magenta (set_color magenta)
  set yellow (set_color yellow)
  set reset (set_color normal)

  echo $cyan"─── Current Clipboard ───────────────────────"$reset

  set mime (copyq read '?' 0)
  if string match -q '*image*' $mime
    echo $magenta"[image]"$reset
  else if string match -q '*uri-list*' $mime
    echo $yellow"[file] "$reset(copyq read 0)
  else
    copyq read 0
  end

  echo ""
  echo $cyan"─── Recent History ──────────────────────────"$reset

  copyq eval '
    var lines = [];
    for (var i = 1; i < Math.min(size(), 30); i++) {
      var mime = str(read("?", i));
      var label = mime.indexOf("image") !== -1 ? "[image] " :
                  mime.indexOf("uri-list") !== -1 ? "[file] " : "";
      var text = label + str(read(i)).split(String.fromCharCode(10)).join(" ").substring(0, 80);
      lines.push(i + ": " + text);
    }
    print(lines.join(String.fromCharCode(10)));
  ' | while read -l line
    if string match -rq '^\d+: \[image\]' $line
      echo $magenta$line$reset
    else if string match -rq '^\d+: \[file\]' $line
      echo $yellow$line$reset
    else
      echo $line
    end
  end
end
