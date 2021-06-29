
import 'dart:async';

import '../core/callback.dart';

import '../core/core.dart';

class TimerInfo {
  Timer timer;
  Callback callback;
  int id;

  void Function(int) onRelease;

  TimerInfo(this.callback) {
    callback.control();
  }

  repeatTimeup(Timer timer) {
    callback.invoke([]);
  }

  timeup() {
    callback.invoke([]);
    callback.release();
    onRelease(id);
  }

  cancel() {
    timer.cancel();
    callback.release();
  }
}

Set<Platform> _platformCache = Set();

class Platform extends Base {
  static reg() {
    Base.reg(Platform, "gs::DartPlatform", Base)
      ..constructor = ((ptr) {
        return Platform().setID(ptr);
      });
  }

  Map<int, TimerInfo> timers = Map();
  static String Function() onGetLanguage;

  initialize() {
    super.initialize();
    on("startTimer", startTimer);
    on("cancelTimer", cancelTimer);
    on("control", control);
    on("getLanguage", getLanguage);
    _platformCache.add(this);
  }

  startTimer(Callback callback, double time, bool repeat, int id) {
    TimerInfo timer = TimerInfo(callback);
    Duration duration = Duration(milliseconds: (time * 1000).toInt());
    if (repeat) {
      timer.timer = Timer.periodic(duration, timer.repeatTimeup);
    } else {
      timer.timer = Timer(duration, timer.timeup);
    }
    timer.id = id;
    timers[id] = timer;
    timer.onRelease = onRelease;
    return id;
  }

  cancelTimer(int id) {
    TimerInfo timer = timers[id];
    if (timer != null) {
      timer.cancel();
      timers.remove(id);
    }
  }

  void _removeAll() {
    timers.forEach((key, value) {
      value.timer.cancel();
    });
    timers.clear();
  }

  onRelease(int id) {
    timers.remove(id);
  }

  @override
  void destroy() {
    _removeAll();
    _platformCache.remove(this);
  }

  String getLanguage() {
    return onGetLanguage?.call();
  }

  static clearPlatform() {
    _platformCache.forEach((element) {element._removeAll();});
    _platformCache.clear();
  }
}