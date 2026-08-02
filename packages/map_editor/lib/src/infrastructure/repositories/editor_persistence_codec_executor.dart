import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import '../../application/models/narrative_event_authoring_session.dart';

typedef EditorPersistenceWorkerRunner = Future<T> Function<T>(
  T Function() operation,
);

enum EditorPersistenceCodecFailureKind {
  currentProjectInvalid,
  eventRegistryReadOnly,
  eventRegistryConflict,
  updatedProjectInvalid,
}

final class EditorPersistenceCodecException implements Exception {
  const EditorPersistenceCodecException({
    required this.kind,
    required this.message,
  });

  final EditorPersistenceCodecFailureKind kind;
  final String message;

  @override
  String toString() => 'EditorPersistenceCodecException(${kind.name}): '
      '$message';
}

final class EditorPersistenceCodecDiagnostics {
  const EditorPersistenceCodecDiagnostics({
    required this.localOperations,
    required this.workerOperations,
    required this.workerFailures,
  });

  final int localOperations;
  final int workerOperations;
  final int workerFailures;
}

final class EditorPreparedProjectUpdate {
  const EditorPreparedProjectUpdate({
    required this.bytes,
  });

  final List<int> bytes;
}

/// Executes pure project JSON/model work outside the UI isolate for large
/// payloads. File ownership, locks, recovery gates, revision checks and writes
/// deliberately remain in [FileProjectRepository].
final class EditorPersistenceCodecExecutor {
  EditorPersistenceCodecExecutor({
    this.offloadThresholdBytes = defaultOffloadThresholdBytes,
    EditorPersistenceWorkerRunner? workerRunner,
  }) : _workerRunner = workerRunner ?? _runEditorPersistenceWorker {
    if (offloadThresholdBytes < 0) {
      throw ArgumentError.value(
        offloadThresholdBytes,
        'offloadThresholdBytes',
        'must not be negative',
      );
    }
  }

  /// Phase 0 measurements show JSON costs becoming visible around 1–2 MiB.
  static const int defaultOffloadThresholdBytes = 1024 * 1024;

  final int offloadThresholdBytes;
  final EditorPersistenceWorkerRunner _workerRunner;

  var _localOperations = 0;
  var _workerOperations = 0;
  var _workerFailures = 0;

  EditorPersistenceCodecDiagnostics get diagnostics =>
      EditorPersistenceCodecDiagnostics(
        localOperations: _localOperations,
        workerOperations: _workerOperations,
        workerFailures: _workerFailures,
      );

  Future<Map<String, Object?>> decodeProjectRoot(List<int> bytes) {
    final ownedBytes = _ownedBytes(bytes);
    return _execute(
      ownedBytes.length,
      () => _decodeStrictProjectRoot(ownedBytes),
    );
  }

  Future<ProjectManifest> decodeValidatedProject(List<int> bytes) {
    final ownedBytes = _ownedBytes(bytes);
    return _execute(
      ownedBytes.length,
      () => decodeValidatedNarrativeEventAuthoringProject(ownedBytes).manifest,
    );
  }

  Future<List<int>> encodeNewProject(ProjectManifest project) {
    final projectJson = project.toJson();
    final estimatedBytes = _estimateJsonBytesUpTo(
      projectJson,
      offloadThresholdBytes,
    );
    return _execute(
      estimatedBytes,
      () => utf8.encode(
        const JsonEncoder.withIndent('  ').convert(projectJson),
      ),
    );
  }

  Future<List<int>> mergeAndEncodeProject({
    required Map<String, Object?> currentRoot,
    required ProjectManifest project,
    required int inputByteLength,
  }) {
    final ownedRoot = Map<String, Object?>.from(currentRoot);
    return _execute(
      inputByteLength,
      () => _mergeAndEncodeProject(ownedRoot, project),
    );
  }

  /// Decodes, checks and merges an existing project in one worker transfer.
  ///
  /// The caller still owns the recovery gate, lock, before/live revision
  /// checks and final write. Only pure JSON/model work happens here.
  Future<EditorPreparedProjectUpdate> prepareExistingProjectUpdate({
    required List<int> currentBytes,
    required ProjectManifest project,
  }) {
    final ownedBytes = _ownedBytes(currentBytes);
    final estimatedOutputBytes = ownedBytes.length >= offloadThresholdBytes
        ? ownedBytes.length
        : _estimateJsonBytesUpTo(project.toJson(), offloadThresholdBytes);
    return _execute(
      ownedBytes.length > estimatedOutputBytes
          ? ownedBytes.length
          : estimatedOutputBytes,
      () => _prepareExistingProjectUpdate(ownedBytes, project),
    );
  }

  Future<String> fingerprintProjectBytes(List<int> bytes) {
    final ownedBytes = _ownedBytes(bytes);
    return _execute(
      ownedBytes.length,
      () => narrativeEventBytesFingerprint(ownedBytes),
    );
  }

  Future<bool> projectBytesMatch(List<int> expected, List<int> actual) {
    final ownedExpected = _ownedBytes(expected);
    final ownedActual = _ownedBytes(actual);
    return _execute(
      ownedExpected.length > ownedActual.length
          ? ownedExpected.length
          : ownedActual.length,
      () => _projectBytesMatch(ownedExpected, ownedActual),
    );
  }

  Future<T> _execute<T>(int inputByteLength, T Function() operation) async {
    if (inputByteLength < offloadThresholdBytes) {
      _localOperations++;
      return operation();
    }
    _workerOperations++;
    try {
      return await _workerRunner(operation);
    } on Object {
      _workerFailures++;
      rethrow;
    }
  }
}

Future<T> _runEditorPersistenceWorker<T>(T Function() operation) {
  return Isolate.run(operation);
}

bool _projectBytesMatch(List<int> expected, List<int> actual) {
  if (expected.length != actual.length) return false;
  for (var index = 0; index < expected.length; index++) {
    if (expected[index] != actual[index]) return false;
  }
  return true;
}

Map<String, Object?> _decodeStrictProjectRoot(List<int> bytes) {
  return _strictJsonObject(
    decodeNarrativeEventJsonStrict(utf8.decode(bytes)),
  );
}

List<int> _mergeAndEncodeProject(
  Map<String, Object?> currentRoot,
  ProjectManifest project,
) {
  final serializedProject = _strictJsonObject(project.toJson());
  final nextRoot = Map<String, Object?>.from(currentRoot)
    ..addAll(serializedProject);
  if (currentRoot.containsKey('eventRegistry')) {
    nextRoot['eventRegistry'] = currentRoot['eventRegistry'];
  } else {
    nextRoot.remove('eventRegistry');
  }
  canonicalizeNarrativeEventJson(nextRoot);
  return utf8.encode(
    const JsonEncoder.withIndent('  ').convert(nextRoot),
  );
}

EditorPreparedProjectUpdate _prepareExistingProjectUpdate(
  List<int> currentBytes,
  ProjectManifest project,
) {
  late final Map<String, Object?> currentRoot;
  try {
    currentRoot = _decodeStrictProjectRoot(currentBytes);
  } on Object catch (error) {
    throw EditorPersistenceCodecException(
      kind: EditorPersistenceCodecFailureKind.currentProjectInvalid,
      message: '$error',
    );
  }

  final currentRegistry = decodeNarrativeEventRegistry(
    currentRoot['eventRegistry'],
  );
  if (!currentRegistry.writable) {
    throw EditorPersistenceCodecException(
      kind: EditorPersistenceCodecFailureKind.eventRegistryReadOnly,
      message: currentRegistry.diagnostics.join(' '),
    );
  }
  if (!_sameEventRegistry(
    currentRegistry.registryOrNull,
    project.eventRegistry,
  )) {
    throw const EditorPersistenceCodecException(
      kind: EditorPersistenceCodecFailureKind.eventRegistryConflict,
      message: 'The Event registry changed outside the generic project save.',
    );
  }
  try {
    return EditorPreparedProjectUpdate(
      bytes: _mergeAndEncodeProject(currentRoot, project),
    );
  } on Object catch (error) {
    throw EditorPersistenceCodecException(
      kind: EditorPersistenceCodecFailureKind.updatedProjectInvalid,
      message: '$error',
    );
  }
}

bool _sameEventRegistry(
  NarrativeEventRegistry? left,
  NarrativeEventRegistry? right,
) {
  return canonicalizeNarrativeEventJson(left?.toJson()) ==
      canonicalizeNarrativeEventJson(right?.toJson());
}

Map<String, Object?> _strictJsonObject(Object? value) {
  if (value is! Map) {
    throw const FormatException('Project root must be an object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('Project keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

int _estimateJsonBytesUpTo(Object? value, int limit) {
  if (limit <= 0) return limit;
  if (value == null) return _capToLimit(4, limit);
  if (value is String) return _jsonStringEncodedBytesUpTo(value, limit);
  if (value is num || value is bool) {
    return _capToLimit(value.toString().length, limit);
  }
  if (value is List) {
    var total = _capToLimit(2, limit);
    for (final item in value) {
      if (total >= limit) return limit;
      total += _estimateJsonBytesUpTo(item, limit - total);
      if (total >= limit) return limit;
      total++;
    }
    return _capToLimit(total, limit);
  }
  if (value is Map) {
    var total = _capToLimit(2, limit);
    for (final entry in value.entries) {
      if (total >= limit) return limit;
      total += _jsonStringEncodedBytesUpTo(
        entry.key.toString(),
        limit - total,
      );
      if (total >= limit) return limit;
      total = _capToLimit(total + 2, limit);
      if (total >= limit) return limit;
      total += _estimateJsonBytesUpTo(entry.value, limit - total);
      if (total >= limit) return limit;
      total++;
    }
    return _capToLimit(total, limit);
  }
  return _capToLimit(value.toString().length, limit);
}

int _jsonStringEncodedBytesUpTo(String value, int limit) {
  if (limit <= 0) return limit;
  var total = 2;
  final units = value.codeUnits;
  for (var index = 0; index < units.length; index++) {
    final unit = units[index];
    if (unit == 0x22 || unit == 0x5c) {
      total += 2;
    } else if (unit <= 0x1f) {
      total += switch (unit) {
        0x08 || 0x09 || 0x0a || 0x0c || 0x0d => 2,
        _ => 6,
      };
    } else if (unit <= 0x7f) {
      total += 1;
    } else if (unit <= 0x7ff) {
      total += 2;
    } else if (unit >= 0xd800 &&
        unit <= 0xdbff &&
        index + 1 < units.length &&
        units[index + 1] >= 0xdc00 &&
        units[index + 1] <= 0xdfff) {
      total += 4;
      index++;
    } else {
      total += 3;
    }
    if (total >= limit) return limit;
  }
  return _capToLimit(total, limit);
}

int _capToLimit(int value, int limit) => value < limit ? value : limit;

Uint8List _ownedBytes(List<int> bytes) {
  return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
}
