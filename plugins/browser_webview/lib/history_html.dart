
const String html = """
<!DOCTYPE html>
<html>
<head>
  <title>history</title>
  <meta name="referrer" content="never">
</head>
<body>
  <script>
   var list = {{0}};

    var backCount = 0;
    var hasCurrent = false;
    for (var i = 0, t = list.length; i < t; ++i) {
      var item = list[i];
      if (i == 0) {
        history.replaceState({}, item.title, item.url);
      } else {
        history.pushState({}, item.title, item.url);
      }
      if (hasCurrent) {
        backCount--;
      } else {
        if (item.current) {
          hasCurrent = true;
          document.head.querySelector('title').innerText = item.title;
        }
      }
    }
    if (backCount == 0) {
      location.reload();
    } else {
      history.go(backCount);
      setTimeout(() => {
          if (backCount !== 0) {
              location.reload();
          }
      });
    }
  </script>
</body>
</html>
""";