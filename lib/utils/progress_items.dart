
import 'dart:async';

import 'package:glib/core/core.dart';
import 'package:glib/utils/git_repository.dart';
import '../progress_dialog.dart';

class GitError extends Error {
  final String msg;

  GitError(this.msg);

  @override
  String toString() => msg;
}

class GitItem extends ProgressItem {
  GitAction action;
  GitRepository repo;
  String url;
  int retryCount = 5;

  GitItem.clone(GitRepository repo, String url) {
    this.defaultText = "Clone from $url";
    this.repo = repo;
    this.url = url;
    start();
  }

  void start() async {
    String lastError;
    for (int i = 0; i < retryCount; ++i) {
      try {
        await _clone();
      } catch (e) {
        lastError = e.toString();
        continue;
      }
      complete();
      return;
    }
    fail(lastError);
  }

  Future<void> _clone() {
    Completer<void> completer = Completer();
    action?.release();
    action = repo.cloneFromRemote(url).control();
    this.progress(defaultText);
    action.setOnProgress((String text, int receive, int total) {
      String title = text;
      switch (text) {
        case "checkout": {
          title = "Checkout... ($receive/$total)";
          break;
        }
        case "fetch": {
          title = "Fetch... ($receive/$total)";
          break;
        }
      }
      this.progress(title);
    });
    action.setOnComplete(() {
      if (action.hasError()) {
        completer.completeError(new GitError(action.getError()));
      } else {
        completer.complete();
      }
    });
    return completer.future;
  }

  @override
  void cancel() {
    if (action != null) {
      action.cancel();
      action.release();
      action = null;
    }
  }

  @override
  void complete() {
    if (action != null) {
      action.release();
      action = null;
    }
//    r(repo);
    super.complete();
  }

  @override
  void fail(String msg) {
    if (action != null) {
      action.release();
      action = null;
    }
//    r(repo);
    super.fail(msg);
  }

  @override
  void retry() {
    r(action);
    start();
  }
}