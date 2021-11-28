
import 'dart:async';

import 'package:flutter/gestures.dart';

enum _OneFingerZoomState {
  None,
  Detecting,
  Moving
}

typedef OneFingerCallback = void Function(PointerEvent event);

GestureArenaTeam _team = GestureArenaTeam();

class OneFingerZoomGestureRecognizer extends OneSequenceGestureRecognizer {
  @override
  final String debugDescription = "one_finger_zoom";

  PointerEvent? startPointer;
  Timer? _timer;

  _OneFingerZoomState _state = _OneFingerZoomState.None;
  Offset _offset = Offset.zero;

  OneFingerCallback? onStart;
  OneFingerCallback? onUpdate;
  OneFingerCallback? onEnd;
  OneFingerCallback? onTap;

  OneFingerZoomGestureRecognizer() {
    // this.team = _team;
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    startPointer = null;
    _state = _OneFingerZoomState.None;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (startPointer?.pointer == event.pointer) {
        startPointer = null;
        if (_state == _OneFingerZoomState.Moving)
          onEnd?.call(event);
        else if (event is PointerUpEvent) {
          onTap?.call(event);
        }
      }
      stopTrackingPointer(event.pointer);
    } else if (event is PointerMoveEvent) {
      if (_state == _OneFingerZoomState.Detecting) {
        if ((event.position - _offset).distance > 8) {
          _cancel();
        }
      } else {
        if (startPointer?.pointer == event.pointer) {
          onUpdate?.call(event);
        }
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
      _timer = Timer(Duration(milliseconds: 400), _onTimer);
    } else if (_state == _OneFingerZoomState.Detecting) {
      _cancel();
    }
  }

  void _cancel() {
    resolve(GestureDisposition.rejected);
    if (startPointer != null)
      stopTrackingPointer(startPointer!.pointer);
    _timer?.cancel();
    _timer = null;
  }

  void _onTimer() {
    _timer = null;
    resolve(GestureDisposition.accepted);
    _state = _OneFingerZoomState.Moving;
    onStart?.call(startPointer!);
  }

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
  }

}