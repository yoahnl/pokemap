import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:map_runtime/map_runtime.dart' show AveluneFrameRate;

class AveluneFrameRateBridge {
  static const _channel = MethodChannel('com.avelune.runtime/frame_rate');
  bool _attached = false;

  void attach() {
    if (_attached || defaultTargetPlatform != TargetPlatform.android) return;
    _attached = true;
    AveluneFrameRate.changes.addListener(_sendLimit);
    _sendLimit();
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    AveluneFrameRate.changes.removeListener(_sendLimit);
  }

  void _sendLimit() => unawaited(_request(AveluneFrameRate.limit));

  Future<void> _request(int limit) async {
    try {
      await _channel.invokeMethod<void>('setLimit', {'framesPerSecond': limit});
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
