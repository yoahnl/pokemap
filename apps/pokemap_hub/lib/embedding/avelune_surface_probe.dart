import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _surfaceProbeChannel = MethodChannel('com.avelune.runtime/surface_probe');

class AveluneSurfaceProbeSnapshot {
  const AveluneSurfaceProbeSnapshot({
    required this.sessionId,
    required this.value,
    required this.revision,
    required this.companionAttached,
  });

  final String sessionId;
  final int value;
  final int revision;
  final bool companionAttached;

  static AveluneSurfaceProbeSnapshot fromPayload(Object? payload) {
    if (payload is! Map ||
        payload['sessionId'] is! String ||
        (payload['sessionId'] as String).trim().isEmpty ||
        payload['value'] is! int ||
        (payload['value'] as int) < 0 ||
        payload['revision'] is! int ||
        (payload['revision'] as int) < 0 ||
        payload['companionAttached'] is! bool) {
      throw const FormatException('Invalid surface probe snapshot.');
    }
    return AveluneSurfaceProbeSnapshot(
      sessionId: payload['sessionId'] as String,
      value: payload['value'] as int,
      revision: payload['revision'] as int,
      companionAttached: payload['companionAttached'] as bool,
    );
  }

  Map<String, Object?> toPayload() => {
    'sessionId': sessionId,
    'value': value,
    'revision': revision,
    'companionAttached': companionAttached,
  };
}

class AveluneSurfaceProbeController
    extends ValueNotifier<AveluneSurfaceProbeSnapshot?> {
  AveluneSurfaceProbeController() : super(null);

  final _sourceSequences = <String, int>{};

  void start(String sessionId) {
    if (sessionId.trim().isEmpty) throw _invalidIntent();
    if (value?.sessionId == sessionId) return;
    _sourceSequences.clear();
    value = AveluneSurfaceProbeSnapshot(
      sessionId: sessionId,
      value: 0,
      revision: 0,
      companionAttached: false,
    );
  }

  void stop() {
    _sourceSequences.clear();
    value = null;
  }

  void setCompanionAttached(bool attached) {
    final snapshot = _active();
    if (snapshot.companionAttached == attached) return;
    value = AveluneSurfaceProbeSnapshot(
      sessionId: snapshot.sessionId,
      value: snapshot.value,
      revision: snapshot.revision + 1,
      companionAttached: attached,
    );
  }

  AveluneSurfaceProbeSnapshot applyIntent(Map<Object?, Object?> intent) {
    final snapshot = _active();
    final sessionId = intent['sessionId'];
    final sourceId = intent['sourceId'];
    final sequence = intent['sequence'];
    if (sessionId is! String ||
        sessionId.trim().isEmpty ||
        sourceId is! String ||
        sourceId.trim().isEmpty ||
        sequence is! int ||
        sequence <= 0 ||
        intent['action'] != 'increment') {
      throw _invalidIntent();
    }
    if (sessionId != snapshot.sessionId) {
      throw PlatformException(code: 'staleSession');
    }
    if (sequence <= (_sourceSequences[sourceId] ?? 0)) return snapshot;
    _sourceSequences[sourceId] = sequence;
    final next = AveluneSurfaceProbeSnapshot(
      sessionId: snapshot.sessionId,
      value: snapshot.value + 1,
      revision: snapshot.revision + 1,
      companionAttached: snapshot.companionAttached,
    );
    value = next;
    return next;
  }

  AveluneSurfaceProbeSnapshot _active() =>
      value ?? (throw PlatformException(code: 'probeInactive'));
}

PlatformException _invalidIntent() => PlatformException(code: 'invalidIntent');

class AveluneSurfaceProbeBridge {
  AveluneSurfaceProbeBridge(
    this.controller, {
    MethodChannel channel = _surfaceProbeChannel,
    bool Function()? canStart,
  }) : _channel = channel,
       _canStart = canStart ?? (() => true);

  final AveluneSurfaceProbeController controller;
  final MethodChannel _channel;
  final bool Function() _canStart;
  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    _channel.setMethodCallHandler(_handle);
    controller.addListener(_publish);
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    _channel.setMethodCallHandler(null);
    controller.removeListener(_publish);
  }

  Future<void> setCompanionEnabled(bool enabled) =>
      _channel.invokeMethod<void>('setCompanionEnabled', {'enabled': enabled});

  Future<void> exit() => _channel.invokeMethod<void>('exit');

  void _publish() {
    unawaited(_notify(controller.value?.toPayload()));
  }

  Future<void> _notify(Object? payload) async {
    try {
      await _channel.invokeMethod<void>('stateChanged', payload);
    } on PlatformException catch (error) {
      debugPrint('Avelune surface probe: ${error.code}');
    } on MissingPluginException {
      debugPrint('Avelune surface probe host unavailable.');
    }
  }

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'start':
        if (!_canStart()) throw PlatformException(code: 'runtimeBusy');
        final args = call.arguments;
        if (args is! Map || args['sessionId'] is! String) {
          throw _invalidIntent();
        }
        controller.start(args['sessionId'] as String);
      case 'stop':
        controller.stop();
      case 'snapshot':
        break;
      case 'setCompanionAttached':
        final args = call.arguments;
        if (args is! Map || args['attached'] is! bool) throw _invalidIntent();
        controller.setCompanionAttached(args['attached'] as bool);
      case 'intent':
        final args = call.arguments;
        if (args is! Map) throw _invalidIntent();
        controller.applyIntent(args);
      default:
        throw MissingPluginException('Unknown probe method: ${call.method}');
    }
    return controller.value?.toPayload();
  }
}

class AveluneCompanionProbeBridge
    extends ValueNotifier<AveluneSurfaceProbeSnapshot?> {
  AveluneCompanionProbeBridge({MethodChannel channel = _surfaceProbeChannel})
    : _channel = channel,
      super(null);

  final MethodChannel _channel;
  int _generation = 0;
  int _sequence = 0;
  int _notifications = 0;
  bool _attached = false;

  Future<void> attach() async {
    if (_attached) return;
    _attached = true;
    final generation = ++_generation;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'stateChanged') {
        throw MissingPluginException(
          'Unknown companion method: ${call.method}',
        );
      }
      _notifications++;
      _accept(call.arguments, generation);
      return null;
    });
    final notifications = _notifications;
    try {
      final payload = await _channel.invokeMethod<Object?>('companionReady');
      if (_notifications == notifications) _accept(payload, generation);
    } on PlatformException catch (error) {
      debugPrint('Avelune companion connection: ${error.code}');
    } on MissingPluginException {
      debugPrint('Avelune companion host unavailable.');
    }
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    _generation++;
    _channel.setMethodCallHandler(null);
  }

  Future<void> increment() async {
    final snapshot = value;
    if (!_attached || snapshot == null) {
      throw PlatformException(code: 'probeInactive');
    }
    final generation = _generation;
    final response = await _channel.invokeMethod<Object?>('intent', {
      'sessionId': snapshot.sessionId,
      'sourceId': 'companion',
      'sequence': ++_sequence,
      'action': 'increment',
    });
    if (response != null && value?.sessionId == snapshot.sessionId) {
      _accept(response, generation);
    }
  }

  void _accept(Object? payload, int generation) {
    if (!_attached || generation != _generation) return;
    if (payload == null) {
      value = null;
      return;
    }
    final snapshot = AveluneSurfaceProbeSnapshot.fromPayload(payload);
    final current = value;
    if (current?.sessionId == snapshot.sessionId &&
        snapshot.revision < current!.revision) {
      return;
    }
    value = snapshot;
  }
}
