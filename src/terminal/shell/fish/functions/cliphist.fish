function cliphist
  set cyan (set_color cyan)
  set reset (set_color normal)

  echo $cyan"─── Current Clipboard ───────────────────────"$reset
  copyq read 0
  echo ""
  echo $cyan"─── Recent History ──────────────────────────"$reset

  copyq eval "
    var lines = [];
    for (var i = 1; i < Math.min(size(), 10); i++) {
      var text = str(read(i));
      var cleaned = text.split(String.fromCharCode(10)).join(' ').substring(0, 80);
      lines.push(i + ': ' + cleaned);
    }
    print(lines.join(String.fromCharCode(10)));
  "
end
