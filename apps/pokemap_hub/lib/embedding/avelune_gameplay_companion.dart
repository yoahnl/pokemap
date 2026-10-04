import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:map_runtime/map_runtime.dart';

const _gameplayCompanionChannel = MethodChannel('com.avelune.runtime/companion');

enum AveluneGameplayCompanionMode { waiting, menu, battle, blocked }

class AveluneGameplayCompanionData {
  const AveluneGameplayCompanionData({
    required this.mode,
    this.player,
    this.battle,
    this.presentation = const {},
  });

  final AveluneGameplayCompanionMode mode;
  final RuntimePlayerSnapshot? player;
  final BattleCommandOverlaySnapshot? battle;
  final Map<String, Object?> presentation;

  Map<String, Object?> toPayload() => {
    'mode': mode.name,
    'player': player == null ? null : RuntimeCompanionPresentationCodec.encodePlayer(player!),
    'battle': battle == null ? null : RuntimeCompanionPresentationCodec.encodeBattleCommandOverlaySnapshot(battle!),
    'presentation': presentation,
  };
}

class AveluneGameplayCompanionSnapshot extends AveluneGameplayCompanionData {
  const AveluneGameplayCompanionSnapshot({
    required this.sessionId,
    required this.revision,
    required this.companionAttached,
    required super.mode,
    super.player,
    super.battle,
    super.presentation,
    Map<String, Object?>? encodedData,
  }) : _encodedData = encodedData;

  final String sessionId;
  final int revision;
  final bool companionAttached;
  final Map<String, Object?>? _encodedData;
  Map<String, Object?> get dataPayload => _encodedData ?? super.toPayload();

  factory AveluneGameplayCompanionSnapshot.fromPayload(Object? payload) {
    final map = _map(payload);
    if (map['sessionId'] is! String || (map['sessionId'] as String).trim().isEmpty ||
        map['revision'] is! int || (map['revision'] as int) < 0 || map['companionAttached'] is! bool) {
      throw const FormatException('Invalid gameplay companion state.');
    }
    return AveluneGameplayCompanionSnapshot(
      sessionId: map['sessionId'] as String,
      revision: map['revision'] as int,
      companionAttached: map['companionAttached'] as bool,
      mode: AveluneGameplayCompanionMode.values.byName(map['mode'] as String),
      player: map['player'] == null ? null : RuntimeCompanionPresentationCodec.decodePlayer(_map(map['player'])),
      battle: map['battle'] == null ? null : RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(_map(map['battle'])),
      presentation: _map(map['presentation']),
      encodedData: {'mode': map['mode'], 'player': map['player'], 'battle': map['battle'], 'presentation': map['presentation']},
    );
  }

  @override
  Map<String, Object?> toPayload() => {
    'sessionId': sessionId,
    'revision': revision,
    'companionAttached': companionAttached,
    ...dataPayload,
  };
}

abstract interface class AveluneGameplayCompanionOwnerPort {
  bool get isPaused;
  Future<AveluneGameplayCompanionData> read();
  Future<void> execute(String kind, Map<String, Object?> payload, AveluneGameplayCompanionSnapshot expected);
}

class AveluneGameplayCompanionOwner extends ValueNotifier<AveluneGameplayCompanionSnapshot?> {
  AveluneGameplayCompanionOwner() : super(null);

  AveluneGameplayCompanionOwnerPort? _port;
  final _sourceSequences = <String, int>{};
  int _generation = 0;
  int _readGeneration = 0;
  bool _busy = false;
  Future<void>? _refreshing;
  bool _readRequested = false;
  String? _dataFingerprint;

  void start(String sessionId) {
    if (sessionId.trim().isEmpty) throw PlatformException(code: 'invalidSession');
    if (value?.sessionId == sessionId) return;
    if (value != null) throw PlatformException(code: 'runtimeBusy');
    _generation++;
    _sourceSequences.clear();
    _busy = false;
    value = AveluneGameplayCompanionSnapshot(
      sessionId: sessionId, revision: 0, companionAttached: false,
      mode: AveluneGameplayCompanionMode.waiting,
    );
    _dataFingerprint = jsonEncode(value!.dataPayload);
  }

  void stop(String sessionId) {
    if (value == null) return;
    if (value!.sessionId != sessionId) throw PlatformException(code: 'staleSession');
    _generation++;
    _readGeneration++;
    _port = null;
    _busy = false;
    _readRequested = false;
    _dataFingerprint = null;
    _sourceSequences.clear();
    value = null;
  }

  void bind(AveluneGameplayCompanionOwnerPort port) {
    _port = port;
    invalidate();
  }

  void unbind(AveluneGameplayCompanionOwnerPort port) {
    if (!identical(_port, port)) return;
    _port = null;
    _readGeneration++;
  }

  void invalidate() => unawaited(refresh());

  Future<void> refresh() {
    if (value == null || _port == null) return Future<void>.value();
    _readRequested = true;
    final pending = _refreshing;
    if (pending != null) return pending;
    final complete = Completer<void>();
    _refreshing = complete.future;
    unawaited(_drainReads().then((_) {
      _refreshing = null;
      complete.complete();
    }, onError: (Object error, StackTrace stack) {
      _refreshing = null;
      complete.completeError(error, stack);
    }));
    return complete.future;
  }

  Future<void> _drainReads() async {
    while (_readRequested && value != null && _port != null) {
      _readRequested = false;
      final port = _port!;
      final generation = _generation;
      final read = _readGeneration;
      try {
        final data = await port.read();
        if (generation != _generation || read != _readGeneration || !identical(port, _port) || _readRequested) continue;
        _publishData(data);
      } on Object catch (error) {
        if (generation != _generation || read != _readGeneration || !identical(port, _port) || _readRequested) continue;
        debugPrint('Avelune gameplay companion read: $error');
        _publishData(const AveluneGameplayCompanionData(mode: AveluneGameplayCompanionMode.blocked));
      }
    }
  }

  void setCompanionAttached(String sessionId, bool attached) {
    final current = _active();
    if (current.sessionId != sessionId) throw PlatformException(code: 'staleSession');
    if (current.companionAttached == attached) return;
    value = AveluneGameplayCompanionSnapshot(
      sessionId: current.sessionId, revision: current.revision + 1, companionAttached: attached,
      mode: current.mode, player: current.player, battle: current.battle, presentation: current.presentation,
      encodedData: current.dataPayload,
    );
  }

  Future<AveluneGameplayCompanionSnapshot?> applyIntent(Map<Object?, Object?> intent) async {
    final current = _active();
    if (intent['sessionId'] != current.sessionId) throw PlatformException(code: 'staleSession');
    if (!current.companionAttached) throw PlatformException(code: 'companionDetached');
    final sourceId = intent['sourceId'];
    final sequence = intent['sequence'];
    if (sourceId is! String || sourceId.trim().isEmpty || sequence is! int || sequence <= 0) {
      throw PlatformException(code: 'invalidIntent');
    }
    if (sequence <= (_sourceSequences[sourceId] ?? 0)) return current;
    if (intent['revision'] != current.revision) throw PlatformException(code: 'staleRevision');
    if (intent['mode'] != current.mode.name) throw PlatformException(code: 'staleMode');
    if (_busy) throw PlatformException(code: 'runtimeBusy');
    final port = _port;
    if (port == null || current.mode == AveluneGameplayCompanionMode.waiting || current.mode == AveluneGameplayCompanionMode.blocked) {
      throw PlatformException(code: 'companionUnavailable');
    }
    final kind = intent['kind'];
    if (kind is! String) throw PlatformException(code: 'invalidIntent');
    final payload = _map(intent['payload']);
    final generation = _generation;
    _sourceSequences[sourceId] = sequence;
    _busy = true;
    try {
      await port.execute(kind, payload, current);
      if (generation != _generation || !identical(port, _port) || value?.sessionId != current.sessionId) {
        throw PlatformException(code: 'staleSession');
      }
      await refresh();
      if (generation != _generation || value?.sessionId != current.sessionId) throw PlatformException(code: 'staleSession');
      return value;
    } finally {
      if (generation == _generation) _busy = false;
    }
  }

  Map<String, Object?>? inputPayload(RuntimeInputEvent event) {
    final current = value;
    if (current == null || !current.companionAttached || current.mode != AveluneGameplayCompanionMode.menu || _port?.isPaused != true) return null;
    return {
      'sessionId': current.sessionId, 'revision': current.revision,
      'control': event.control.name, 'phase': event.phase.name, 'isRepeat': event.isRepeat,
    };
  }

  void _publishData(AveluneGameplayCompanionData data) {
    final current = value;
    if (current == null) return;
    final payload = data.toPayload();
    final fingerprint = jsonEncode(payload);
    if (fingerprint == _dataFingerprint) return;
    _dataFingerprint = fingerprint;
    value = AveluneGameplayCompanionSnapshot(
      sessionId: current.sessionId, revision: current.revision + 1, companionAttached: current.companionAttached,
      mode: data.mode, player: data.player, battle: data.battle, presentation: data.presentation,
      encodedData: payload,
    );
  }

  AveluneGameplayCompanionSnapshot _active() => value ?? (throw PlatformException(code: 'companionInactive'));

  @override
  void dispose() {
    _generation++;
    _readGeneration++;
    _port = null;
    _readRequested = false;
    super.dispose();
  }
}

class AveluneGameplayCompanionBridge {
  AveluneGameplayCompanionBridge(this.owner, {MethodChannel channel = _gameplayCompanionChannel, bool Function()? canStart})
      : _channel = channel, _canStart = canStart ?? (() => true);

  final AveluneGameplayCompanionOwner owner;
  final MethodChannel _channel;
  final bool Function() _canStart;
  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    _channel.setMethodCallHandler(_handle);
    owner.addListener(_publish);
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    _channel.setMethodCallHandler(null);
    owner.removeListener(_publish);
  }

  Future<void> stopOwnedSession() async {
    final sessionId = owner.value?.sessionId;
    if (sessionId == null) return;
    owner.stop(sessionId);
    await _notify('stateChanged', null);
  }

  bool forwardInput(RuntimeInputEvent event) {
    final payload = owner.inputPayload(event);
    if (!_attached || payload == null) return false;
    unawaited(_notify('input', payload));
    return true;
  }

  void _publish() => unawaited(_notify('stateChanged', owner.value?.toPayload()));

  Future<void> _notify(String method, Object? payload) async {
    try {
      await _channel.invokeMethod<void>(method, payload);
    } on PlatformException catch (error) {
      debugPrint('Avelune gameplay companion: ${error.code}');
    } on MissingPluginException {
      debugPrint('Avelune gameplay companion host unavailable.');
    }
  }

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'start':
        if (!_canStart()) throw PlatformException(code: 'runtimeBusy');
        owner.start(_session(call.arguments));
        await owner.refresh();
      case 'stop':
        final sessionId = _session(call.arguments);
        if (owner.value != null && owner.value!.sessionId != sessionId) throw PlatformException(code: 'staleSession');
        await stopOwnedSession();
        return null;
      case 'snapshot':
        await owner.refresh();
      case 'setCompanionAttached':
        final args = _map(call.arguments);
        if (args['attached'] is! bool) throw PlatformException(code: 'invalidIntent');
        if (owner.value == null && args['attached'] == false) return null;
        owner.setCompanionAttached(_session(args), args['attached'] as bool);
      case 'intent':
        await owner.applyIntent(_map(call.arguments));
      default:
        throw MissingPluginException('Unknown gameplay companion method: ${call.method}');
    }
    return owner.value?.toPayload();
  }
}

class AveluneGameplayCompanionRemote extends ValueNotifier<AveluneGameplayCompanionSnapshot?> {
  AveluneGameplayCompanionRemote({MethodChannel channel = _gameplayCompanionChannel}) : _channel = channel, super(null);

  final MethodChannel _channel;
  final _inputs = StreamController<RuntimeInputEvent>.broadcast(sync: true);
  Stream<RuntimeInputEvent> get inputs => _inputs.stream;
  int _generation = 0;
  int _sequence = 0;
  int _notifications = 0;
  bool _attached = false;
  bool _busy = false;
  bool get busy => _busy;

  Future<void> attach() async {
    if (_attached) return;
    _attached = true;
    final generation = ++_generation;
    _channel.setMethodCallHandler((call) async {
      if (!_attached || generation != _generation) return null;
      switch (call.method) {
        case 'stateChanged':
          _notifications++;
          _accept(call.arguments, generation);
        case 'input':
          _acceptInput(call.arguments);
        default:
          throw MissingPluginException('Unknown companion method: ${call.method}');
      }
      return null;
    });
    final notifications = _notifications;
    try {
      final payload = await _channel.invokeMethod<Object?>('companionReady');
      if (_notifications == notifications) _accept(payload, generation);
    } on PlatformException catch (error) {
      debugPrint('Avelune gameplay companion connection: ${error.code}');
    } on MissingPluginException {
      debugPrint('Avelune gameplay companion host unavailable.');
    }
  }

  Future<void> send(String kind, Map<String, Object?> payload) async {
    final current = value;
    if (!_attached || current == null || !current.companionAttached) throw PlatformException(code: 'companionDetached');
    if (_busy) throw PlatformException(code: 'runtimeBusy');
    final generation = _generation;
    _busy = true;
    notifyListeners();
    try {
      final response = await _channel.invokeMethod<Object?>('intent', {
        'sessionId': current.sessionId, 'revision': current.revision, 'mode': current.mode.name,
        'sourceId': 'companion', 'sequence': ++_sequence, 'kind': kind, 'payload': payload,
      });
      if (response != null && value?.sessionId == current.sessionId) _accept(response, generation);
    } finally {
      if (generation == _generation) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> surfaceReady({bool ready = true}) async {
    final current = value;
    if (!_attached || current == null) return;
    final generation = _generation;
    try {
      final payload = await _channel.invokeMethod<Object?>('surfaceReady', {'sessionId': current.sessionId, 'ready': ready});
      if (payload != null && value?.sessionId == current.sessionId) _accept(payload, generation);
    } on PlatformException catch (error) {
      debugPrint('Avelune companion surface readiness: ${error.code}');
    } on MissingPluginException {
      debugPrint('Avelune companion surface readiness unavailable.');
    }
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    _generation++;
    _channel.setMethodCallHandler(null);
  }

  void _accept(Object? payload, int generation) {
    if (!_attached || generation != _generation) return;
    if (payload == null) {
      value = null;
      return;
    }
    final next = AveluneGameplayCompanionSnapshot.fromPayload(payload);
    final current = value;
    if (current != null && (next.sessionId != current.sessionId || next.revision <= current.revision)) return;
    value = next;
  }

  void _acceptInput(Object? payload) {
    final current = value;
    final input = _map(payload);
    if (current == null || !current.companionAttached || input['sessionId'] != current.sessionId ||
        input['revision'] != current.revision || current.mode != AveluneGameplayCompanionMode.menu) {
      return;
    }
    final control = RuntimeInputControl.values.byName(input['control'] as String);
    final event = switch (input['phase']) {
      'press' => RuntimeInputEvent.press(control, isRepeat: input['isRepeat'] as bool),
      'release' => RuntimeInputEvent.release(control),
      _ => throw const FormatException('Invalid companion input phase.'),
    };
    _inputs.add(event);
  }

  @override
  void dispose() {
    detach();
    unawaited(_inputs.close());
    super.dispose();
  }
}

Map<String, dynamic> _map(Object? payload) {
  if (payload is! Map || payload.keys.any((key) => key is! String)) throw const FormatException('Invalid companion message.');
  return RuntimeCompanionPresentationCodec.normalizeMap(payload);
}

String _session(Object? payload) {
  final sessionId = _map(payload)['sessionId'];
  if (sessionId is! String || sessionId.trim().isEmpty) throw PlatformException(code: 'invalidSession');
  return sessionId;
}
