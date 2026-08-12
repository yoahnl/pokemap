import 'dart:convert';

import 'package:map_core/map_core.dart';

final class EditorPerformanceSpanName {
  const EditorPerformanceSpanName._();

  static const pointerPreDispatch = 'pointer.pre_dispatch';
  static const pointerToStatePublish = 'pointer.to_state_publish';
  static const mutationLocal = 'mutation.local';
  static const statePublish = 'state.publish';
  static const canvasPrepare = 'canvas.prepare';
  static const canvasFutureBuilderBody = 'canvas.future_builder_body';
  static const canvasPaintRecording = 'canvas.paint_recording';
  static const maskReadback = 'mask.readback';
  static const maskPointerMove = 'mask.pointer_move';
  static const maskCommit = 'mask.commit';
  static const maskBuild = 'mask.build';
  static const maskPaint = 'mask.paint';
  static const snapshot = 'snapshot';
  static const plan = 'plan';
  static const apply = 'apply';
  static const saveQueue = 'save.queue';
  static const saveEncode = 'save.encode';

  static const all = <String>[
    pointerPreDispatch,
    pointerToStatePublish,
    mutationLocal,
    statePublish,
    canvasPrepare,
    canvasFutureBuilderBody,
    canvasPaintRecording,
    maskReadback,
    maskPointerMove,
    maskCommit,
    maskBuild,
    maskPaint,
    snapshot,
    plan,
    apply,
    saveQueue,
    saveEncode,
  ];
}

final class EditorPerformanceCounterName {
  const EditorPerformanceCounterName._();

  static const filesystemRead = 'filesystem.read';
  static const filesystemWrite = 'filesystem.write';
  static const filesystemMetadata = 'filesystem.metadata';
  static const jsonEncode = 'json.encode';
  static const jsonDecode = 'json.decode';
  static const base64Encode = 'base64.encode';
  static const base64Decode = 'base64.decode';

  static const all = <String>[
    filesystemRead,
    filesystemWrite,
    filesystemMetadata,
    jsonEncode,
    jsonDecode,
    base64Encode,
    base64Decode,
  ];
}

final class EditorPerformanceRecorder {
  EditorPerformanceRecorder({
    int Function()? clock,
    this.maxSamplesPerSpan = 10000,
  }) : _clock = clock ?? _monotonicMicroseconds {
    if (maxSamplesPerSpan <= 0) {
      throw ArgumentError.value(
        maxSamplesPerSpan,
        'maxSamplesPerSpan',
        'must be positive',
      );
    }
    for (final name in EditorPerformanceSpanName.all) {
      _spanSamples[name] = <int>[];
    }
    for (final name in EditorPerformanceCounterName.all) {
      _counters[name] = 0;
    }
  }

  static final Stopwatch _stopwatch = Stopwatch()..start();

  static int _monotonicMicroseconds() => _stopwatch.elapsedMicroseconds;

  final int Function() _clock;
  final int maxSamplesPerSpan;
  final Map<String, List<int>> _spanSamples = <String, List<int>>{};
  final Map<String, int> _counters = <String, int>{};
  int _droppedSampleCount = 0;

  EditorPerformanceSpan startSpan(String name) {
    _spanSamples.putIfAbsent(name, () => <int>[]);
    return EditorPerformanceSpan._(this, name, _clock());
  }

  void incrementCounter(String name, {int by = 1}) {
    if (by < 0) {
      throw ArgumentError.value(by, 'by', 'must be non-negative');
    }
    _counters.update(name, (value) => value + by, ifAbsent: () => by);
  }

  EditorPerformanceSnapshot snapshot() {
    return EditorPerformanceSnapshot._(
      spanSamples: <String, List<int>>{
        for (final entry in _spanSamples.entries)
          entry.key: List<int>.unmodifiable(entry.value),
      },
      counters: Map<String, int>.unmodifiable(_counters),
      droppedSampleCount: _droppedSampleCount,
    );
  }

  EditorPerformanceSnapshot deltaSince(EditorPerformanceSnapshot before) {
    return snapshot().deltaSince(before);
  }

  void _finishSpan(String name, int startedAtMicroseconds) {
    final duration = _clock() - startedAtMicroseconds;
    final samples = _spanSamples.putIfAbsent(name, () => <int>[]);
    if (samples.length >= maxSamplesPerSpan) {
      _droppedSampleCount++;
      return;
    }
    samples.add(duration < 0 ? 0 : duration);
  }
}

final class EditorPerformanceSpan {
  EditorPerformanceSpan._(
    this._recorder,
    this._name,
    this._startedAtMicroseconds,
  );

  final EditorPerformanceRecorder _recorder;
  final String _name;
  final int _startedAtMicroseconds;
  bool _finished = false;

  void finish() {
    if (_finished) return;
    _finished = true;
    _recorder._finishSpan(_name, _startedAtMicroseconds);
  }
}

final class EditorPerformanceSnapshot {
  const EditorPerformanceSnapshot._({
    required Map<String, List<int>> spanSamples,
    required Map<String, int> counters,
    required this.droppedSampleCount,
  }) : _spanSamples = spanSamples,
       _counters = counters;

  final Map<String, List<int>> _spanSamples;
  final Map<String, int> _counters;
  final int droppedSampleCount;

  List<int> spanSamples(String name) => _spanSamples[name] ?? const <int>[];

  int counter(String name) => _counters[name] ?? 0;

  EditorPerformanceSnapshot deltaSince(EditorPerformanceSnapshot before) {
    final spanNames = <String>{
      ..._spanSamples.keys,
      ...before._spanSamples.keys,
    };
    final counterNames = <String>{..._counters.keys, ...before._counters.keys};
    return EditorPerformanceSnapshot._(
      spanSamples: <String, List<int>>{
        for (final name in spanNames)
          name: List<int>.unmodifiable(
            spanSamples(name).skip(before.spanSamples(name).length),
          ),
      },
      counters: Map<String, int>.unmodifiable(<String, int>{
        for (final name in counterNames)
          name: counter(name) - before.counter(name),
      }),
      droppedSampleCount: droppedSampleCount - before.droppedSampleCount,
    );
  }

  Map<String, Object?> toJson() {
    final spanNames = _orderedNames(
      EditorPerformanceSpanName.all,
      _spanSamples.keys,
    );
    final counterNames = _orderedNames(
      EditorPerformanceCounterName.all,
      _counters.keys,
    );
    return <String, Object?>{
      'spans': <String, Object?>{
        for (final name in spanNames) name: _spanMetrics(spanSamples(name)),
      },
      'counters': <String, Object?>{
        for (final name in counterNames) name: counter(name),
      },
      'droppedSampleCount': droppedSampleCount,
    };
  }
}

final class EditorPerformanceRecording {
  EditorPerformanceRecording._(this._recorder, this._previousRecording);

  final EditorPerformanceRecorder _recorder;
  final EditorPerformanceRecording? _previousRecording;
  bool _closed = false;

  void close() {
    if (_closed) return;
    if (!identical(EditorPerformanceTelemetry._activeRecording, this)) {
      throw StateError('Performance recordings must close in LIFO order.');
    }
    _closed = true;
    EditorPerformanceTelemetry._activeRecording = _previousRecording;
  }
}

final class EditorPerformanceTelemetry {
  const EditorPerformanceTelemetry._();

  static EditorPerformanceRecording? _activeRecording;

  static EditorPerformanceRecording startRecording(
    EditorPerformanceRecorder recorder,
  ) {
    final recording = EditorPerformanceRecording._(recorder, _activeRecording);
    _activeRecording = recording;
    return recording;
  }

  static EditorPerformanceSpan? startSpan(String name) {
    return _activeRecording?._recorder.startSpan(name);
  }

  static void incrementCounter(String name, {int by = 1}) {
    _activeRecording?._recorder.incrementCounter(name, by: by);
  }

  static String encodeJson(Object? value) {
    incrementCounter(EditorPerformanceCounterName.jsonEncode);
    return jsonEncode(value);
  }

  static Object? decodeJson(String value) {
    incrementCounter(EditorPerformanceCounterName.jsonDecode);
    return jsonDecode(value);
  }

  static String encodePackedCollisionMask({
    required int widthPx,
    required int heightPx,
    required List<bool> solidPixels,
  }) {
    incrementCounter(EditorPerformanceCounterName.base64Encode);
    return ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: solidPixels,
    );
  }

  static List<bool> decodePackedCollisionMask({
    required int widthPx,
    required int heightPx,
    required String dataBase64,
  }) {
    incrementCounter(EditorPerformanceCounterName.base64Decode);
    return ElementCollisionMaskCodec.decodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      dataBase64: dataBase64,
    );
  }

  static List<GridPos> collisionCellsFromPixelMask({
    required ElementCollisionPixelMask mask,
    required int tileWidth,
    required int tileHeight,
    required int sourceWidthInTiles,
    required int sourceHeightInTiles,
  }) {
    incrementCounter(EditorPerformanceCounterName.base64Decode);
    return ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: mask,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      sourceWidthInTiles: sourceWidthInTiles,
      sourceHeightInTiles: sourceHeightInTiles,
    );
  }
}

List<String> _orderedNames(List<String> canonical, Iterable<String> recorded) {
  final extra = recorded.where((name) => !canonical.contains(name)).toList()
    ..sort();
  return <String>[...canonical, ...extra];
}

Map<String, Object?> _spanMetrics(List<int> samples) {
  if (samples.isEmpty) {
    return <String, Object?>{
      'count': 0,
      'totalUs': 0,
      'p50Us': 0,
      'p95Us': 0,
      'p99Us': 0,
      'maxUs': 0,
    };
  }
  final sorted = List<int>.of(samples)..sort();
  return <String, Object?>{
    'count': sorted.length,
    'samplesUs': sorted,
    'totalUs': sorted.fold<int>(0, (total, value) => total + value),
    'p50Us': _percentile(sorted, 0.50),
    'p95Us': _percentile(sorted, 0.95),
    'p99Us': _percentile(sorted, 0.99),
    'maxUs': sorted.last,
  };
}

int _percentile(List<int> sorted, double percentile) {
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}
