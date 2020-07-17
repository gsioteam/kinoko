
import 'package:glib/core/core.dart';
import 'package:glib/utils/git_repository.dart';
import '../progress_dialog.dart';

class GitItem extends ProgressItem {
  GitAction action;
  GitRepository repo;
  String url;

  GitItem.clone(GitRepository repo, String url) {
    this.defaultText = "Clone from $url";
    this.repo = repo;
    this.url = url;
    start();
  }

  void start() {
    action = repo.cloneFromRemote(url);
    action.control();
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
        this.fail(action.getError());
      } else {
        this.complete();
      }
    });
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