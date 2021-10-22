
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:glib/main/models.dart';
import 'package:glib/utils/git_repository.dart';

class GitRepositoryChecker {
  static GitRepositoryChecker _instance;

  static GitRepositoryChecker get instance {
    if (_instance == null) {
      _instance = GitRepositoryChecker();
    }
    return _instance;
  }

  Set<ValueChanged<String>> _listeners = Set();

  void addListener(ValueChanged<String> listener) {
    _listeners.add(listener);
  }

  void removeListener(ValueChanged<String> listener) {
    _listeners.remove(listener);
  }

  void trigger(String url) {
    for (var cb in _listeners) {
      cb(url);
    }
  }

  void checkout(GitRepository repository) async {
    String key = "checkout:git:${repository.path}";
    String value = KeyValue.get(key);
    if (value.isNotEmpty) {
      int time = int.parse(value);
      if (time + 6 * 3600 * 1000 < DateTime.now().millisecondsSinceEpoch) {
        return;
      }
    }

    repository.control();
    var action = repository.checkout();
    action.control();
    Completer completer = Completer();
    action.setOnComplete(() {
      completer.complete();
    });
    await completer.future;
    KeyValue.set(key, "${DateTime.now().millisecondsSinceEpoch}");
    trigger(repository.path);
    action.release();
    repository.release();
  }
}