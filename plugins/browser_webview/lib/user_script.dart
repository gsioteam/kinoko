
enum InjectPosition {
  start,
  end,
}

class UserScript {
  final String script;
  final InjectPosition position;
  final Map arguments;

  const UserScript({
    required this.script,
    this.position = InjectPosition.end,
    this.arguments = const {},
  });

  toData() => {
    "script": script,
    "position": position.index,
    "arguments": arguments,
  };
}

typedef ScriptEventHandler = void Function(dynamic data);