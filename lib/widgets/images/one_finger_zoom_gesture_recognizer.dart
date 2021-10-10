
import 'dart:async';

import 'package:flutter/gestures.dart';

enum _OneFingerZoomState {
  None,
  Detecting,
  Moving
}

typedef OneFingerStartCallback = void Function(PointerEvent event);
typedef OneFingerUpdateCallback = void Function(PointerEvent event);
typedef OneFingerStopCallback = void Function(PointerEvent event);

class OneFingerZoomGestureRecognizer extends OneSequenceGestureRecognizer {
  @override
  final String debugDescription = "one_finger_zoom";

  PointerEvent startPointer;
  Timer _timer;

  _OneFingerZoomState _state = _OneFingerZoomState.None;
  Offset _offset = Offset.zero;

  OneFingerStartCallback onStart;
  OneFingerUpdateCallback onUpdate;
  OneFingerStopCallback onEnd;

  @override
  void didStopTrackingLastPointer(int pointer) {
    startPointer = null;
    _state = _OneFingerZoomState.None;
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (startPointer?.pointer == event.pointer) {
        startPointer = null;
        onEnd?.call(event);
      }
      stopTrackingPointer(event.pointer);
    } else if (event is PointerMoveEvent) {
      if (_state == _OneFingerZoomState.Detecting) {
        if ((event.position - _offset).distance > 4) {
          _cancel();
        }
      } else {
        if (startPointer?.pointer == event.pointer)
          onUpdate?.call(event);
      }
    }
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (startPointer == null) {
      _offset = event.position;
      _state = _OneFingerZoomState.Detecting;
      startTrackingPointer(event.pointer, event.transform);
      startPointer = event;
      _timer = Timer(Duration(seconds: 1), _onTimer);
    } else if (_state == _OneFingerZoomState.Detecting) {
      _cancel();
    }
  }

  void _cancel() {
    resolve(GestureDisposition.rejected);
    stopTrackingPointer(startPointer.pointer);
    _timer?.cancel();
    _timer = null;
  }

  void _onTimer() {
    _timer = null;
    resolve(GestureDisposition.accepted);
    _state = _OneFingerZoomState.Moving;
    onStart?.call(startPointer);
  }
}