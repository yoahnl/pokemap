import '../runner/evaluation_state_diff.dart';
import 'evaluation_policy.dart';
import 'evaluation_state_snapshot.dart';

enum EvaluationRunStatus {
  succeeded,
  failed,
  invalidScenario,
  infrastructureFailure,
  policyViolation,
  cancelled,
}

final class EvaluationStepResult {
  EvaluationStepResult({
    required this.index,
    required String stepId,
    required this.passed,
    Map<String, Object?> details = const <String, Object?>{},
  })  : stepId = _nonBlank(stepId, 'stepId'),
        details = _freezeMap(details);

  final int index;
  final String stepId;
  final bool passed;
  final Map<String, Object?> details;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'index': index,
      'stepId': stepId,
      'passed': passed,
      'details': details,
    };
  }
}

final class EvaluationProductCriterionResult {
  EvaluationProductCriterionResult({
    required String id,
    required String summary,
    required this.passed,
  })  : id = _nonBlank(id, 'criterion id'),
        summary = _nonBlank(summary, 'criterion summary');

  final String id;
  final String summary;
  final bool passed;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'summary': summary,
      'passed': passed,
    };
  }
}

final class EvaluationReceipt {
  EvaluationReceipt._({
    required this.runId,
    required this.projectId,
    required this.scenarioId,
    required this.scenarioVersion,
    required this.policy,
    required this.target,
    required this.evidenceLevel,
    required this.commit,
    required this.projectTreeHash,
    required this.commandDigest,
    required this.outputDigest,
    required this.startedAt,
    required this.finishedAt,
    required this.duration,
    required this.status,
    required this.exitCode,
    required this.initialState,
    required this.finalState,
    required this.diff,
    required this.stepResults,
    required this.shortcutsUsed,
    required this.checkpointProvenance,
    required this.artifacts,
    required this.error,
    required this.relativeReceiptPath,
    required this.declaredCriterionIds,
    required this.productCriteria,
  });

  factory EvaluationReceipt.validated({
    required String runId,
    required String projectId,
    required String scenarioId,
    required int scenarioVersion,
    required EvaluationPolicy policy,
    required EvaluationTarget target,
    required EvaluationEvidenceLevel evidenceLevel,
    required String? commit,
    required String projectTreeHash,
    required String commandDigest,
    required String outputDigest,
    required DateTime startedAt,
    required DateTime finishedAt,
    required Duration duration,
    required EvaluationRunStatus status,
    required int exitCode,
    required EvaluationStateSnapshot initialState,
    required EvaluationStateSnapshot finalState,
    required EvaluationStateDiff diff,
    required List<EvaluationStepResult> stepResults,
    required List<String> shortcutsUsed,
    Map<String, Object?>? checkpointProvenance,
    required List<String> artifacts,
    Map<String, Object?>? error,
    required String relativeReceiptPath,
    required List<String> declaredCriterionIds,
    required List<EvaluationProductCriterionResult> productCriteria,
  }) {
    runId = _nonBlank(runId, 'runId');
    projectId = _nonBlank(projectId, 'projectId');
    scenarioId = _nonBlank(scenarioId, 'scenarioId');
    if (scenarioVersion < 1) {
      throw ArgumentError.value(
        scenarioVersion,
        'scenarioVersion',
        'Scenario versions start at 1.',
      );
    }
    _validateHash(projectTreeHash, 'projectTreeHash');
    _validateHash(commandDigest, 'commandDigest');
    _validateHash(outputDigest, 'outputDigest');
    if (finishedAt.isBefore(startedAt)) {
      throw ArgumentError('finishedAt must not precede startedAt.');
    }
    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Duration must not be negative.',
      );
    }
    if (duration != finishedAt.difference(startedAt)) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Duration must match the receipt time range.',
      );
    }
    final expectedExitCode = _exitCodeFor(status);
    if (exitCode != expectedExitCode) {
      throw ArgumentError.value(
        exitCode,
        'exitCode',
        'Status ${status.name} requires exit code $expectedExitCode.',
      );
    }
    if (initialState.runId != runId ||
        finalState.runId != runId ||
        initialState.projectId != projectId ||
        finalState.projectId != projectId) {
      throw ArgumentError(
        'Receipt state snapshots must match its run and project ids.',
      );
    }

    final frozenStepResults =
        List<EvaluationStepResult>.unmodifiable(stepResults);
    final stepIds = <String>{};
    for (var index = 0; index < frozenStepResults.length; index += 1) {
      final result = frozenStepResults[index];
      if (result.index != index) {
        throw ArgumentError.value(
          result.index,
          'stepResults',
          'Step results must be ordered from index 0.',
        );
      }
      if (!stepIds.add(result.stepId)) {
        throw ArgumentError.value(
          result.stepId,
          'stepResults',
          'Step results must have unique ids.',
        );
      }
    }

    final frozenDeclaredCriterionIds = List<String>.unmodifiable(
      declaredCriterionIds.map(
        (id) => _nonBlank(id, 'declared criterion id'),
      ),
    );
    if (frozenDeclaredCriterionIds.toSet().length !=
        frozenDeclaredCriterionIds.length) {
      throw ArgumentError(
        'Declared product criterion ids must be unique.',
      );
    }
    final frozenCriteria =
        List<EvaluationProductCriterionResult>.unmodifiable(productCriteria);
    final criterionIds = <String>{};
    for (final criterion in frozenCriteria) {
      if (!criterionIds.add(criterion.id)) {
        throw ArgumentError.value(
          criterion.id,
          'productCriteria',
          'Product criterion results must be unique.',
        );
      }
      if (!frozenDeclaredCriterionIds.contains(criterion.id)) {
        throw ArgumentError.value(
          criterion.id,
          'productCriteria',
          'Product criterion result was not declared by the scenario.',
        );
      }
    }

    final frozenShortcuts = List<String>.unmodifiable(
      shortcutsUsed.map((shortcut) => _nonBlank(shortcut, 'shortcut')),
    );
    if (status != EvaluationRunStatus.succeeded &&
        evidenceLevel != EvaluationEvidenceLevel.diagnosticOnly) {
      throw ArgumentError(
        'Unsuccessful runs can only produce diagnostic evidence.',
      );
    }
    if (policy == EvaluationPolicy.probe &&
        evidenceLevel != EvaluationEvidenceLevel.diagnosticOnly) {
      throw ArgumentError('Probe runs can only produce diagnostic evidence.');
    }
    if (frozenShortcuts.isNotEmpty &&
        evidenceLevel != EvaluationEvidenceLevel.diagnosticOnly) {
      throw ArgumentError(
        'Shortcut-using runs can only produce diagnostic evidence.',
      );
    }
    if (evidenceLevel == EvaluationEvidenceLevel.releaseEvidence) {
      if (policy != EvaluationPolicy.certify ||
          frozenDeclaredCriterionIds.isEmpty ||
          frozenCriteria.length != frozenDeclaredCriterionIds.length ||
          !criterionIds.containsAll(frozenDeclaredCriterionIds) ||
          frozenCriteria.any((criterion) => !criterion.passed)) {
        throw ArgumentError(
          'Release evidence requires a successful certification with a '
          'complete passing criterion set.',
        );
      }
    }

    final frozenArtifacts = List<String>.unmodifiable(
      artifacts.map((path) => _relativePath(path, 'artifacts')),
    );
    relativeReceiptPath =
        _relativePath(relativeReceiptPath, 'relativeReceiptPath');

    return EvaluationReceipt._(
      runId: runId,
      projectId: projectId,
      scenarioId: scenarioId,
      scenarioVersion: scenarioVersion,
      policy: policy,
      target: target,
      evidenceLevel: evidenceLevel,
      commit: commit == null ? null : _nonBlank(commit, 'commit'),
      projectTreeHash: projectTreeHash,
      commandDigest: commandDigest,
      outputDigest: outputDigest,
      startedAt: startedAt.toUtc(),
      finishedAt: finishedAt.toUtc(),
      duration: duration,
      status: status,
      exitCode: exitCode,
      initialState: initialState,
      finalState: finalState,
      diff: diff,
      stepResults: frozenStepResults,
      shortcutsUsed: frozenShortcuts,
      checkpointProvenance: checkpointProvenance == null
          ? null
          : _freezeMap(checkpointProvenance),
      artifacts: frozenArtifacts,
      error: error == null ? null : _freezeMap(error),
      relativeReceiptPath: relativeReceiptPath,
      declaredCriterionIds: frozenDeclaredCriterionIds,
      productCriteria: frozenCriteria,
    );
  }

  factory EvaluationReceipt.fromJson(Map<String, Object?> json) {
    final schemaVersion = _jsonInt(json, 'schemaVersion');
    if (schemaVersion != EvaluationReceipt.schemaVersion) {
      throw FormatException(
        'Unsupported evaluation receipt schema version $schemaVersion.',
      );
    }

    final initialState = _snapshotFromJson(
      _jsonMap(json, 'initialState'),
      'initialState',
    );
    final finalState = _snapshotFromJson(
      _jsonMap(json, 'finalState'),
      'finalState',
    );
    final startedAt = _jsonDateTime(json, 'startedAt');
    final finishedAt = _jsonDateTime(json, 'finishedAt');
    final duration = finishedAt.difference(startedAt);
    if (_jsonInt(json, 'durationMilliseconds') != duration.inMilliseconds) {
      throw const FormatException(
        'Receipt duration must match its timestamp range.',
      );
    }

    return EvaluationReceipt.validated(
      runId: _jsonString(json, 'runId'),
      projectId: _jsonString(json, 'projectId'),
      scenarioId: _jsonString(json, 'scenarioId'),
      scenarioVersion: _jsonInt(json, 'scenarioVersion'),
      policy: _jsonEnum(
        EvaluationPolicy.values,
        _jsonString(json, 'policy'),
        'policy',
      ),
      target: _jsonEnum(
        EvaluationTarget.values,
        _jsonString(json, 'target'),
        'target',
      ),
      evidenceLevel: _jsonEnum(
        EvaluationEvidenceLevel.values,
        _jsonString(json, 'evidenceLevel'),
        'evidenceLevel',
      ),
      commit: _jsonNullableString(json, 'commit'),
      projectTreeHash: _jsonString(json, 'projectTreeHash'),
      commandDigest: _jsonString(json, 'commandDigest'),
      outputDigest: _jsonString(json, 'outputDigest'),
      startedAt: startedAt,
      finishedAt: finishedAt,
      duration: duration,
      status: _jsonEnum(
        EvaluationRunStatus.values,
        _jsonString(json, 'status'),
        'status',
      ),
      exitCode: _jsonInt(json, 'exitCode'),
      initialState: initialState,
      finalState: finalState,
      diff: _diffFromJson(_jsonMap(json, 'diff')),
      stepResults: _jsonList(json, 'stepResults').map((value) {
        final item = _valueAsMap(value, 'stepResults');
        return EvaluationStepResult(
          index: _jsonInt(item, 'index'),
          stepId: _jsonString(item, 'stepId'),
          passed: _jsonBool(item, 'passed'),
          details: _jsonMap(item, 'details'),
        );
      }).toList(growable: false),
      shortcutsUsed: _jsonStringList(json, 'shortcutsUsed'),
      checkpointProvenance: _jsonNullableMap(
        json,
        'checkpointProvenance',
      ),
      artifacts: _jsonStringList(json, 'artifacts'),
      error: _jsonNullableMap(json, 'error'),
      relativeReceiptPath: _jsonString(json, 'relativeReceiptPath'),
      declaredCriterionIds: _jsonStringList(json, 'declaredCriterionIds'),
      productCriteria: _jsonList(json, 'productCriteria').map((value) {
        final item = _valueAsMap(value, 'productCriteria');
        return EvaluationProductCriterionResult(
          id: _jsonString(item, 'id'),
          summary: _jsonString(item, 'summary'),
          passed: _jsonBool(item, 'passed'),
        );
      }).toList(growable: false),
    );
  }

  static const schemaVersion = 1;

  final String runId;
  final String projectId;
  final String scenarioId;
  final int scenarioVersion;
  final EvaluationPolicy policy;
  final EvaluationTarget target;
  final EvaluationEvidenceLevel evidenceLevel;
  final String? commit;
  final String projectTreeHash;
  final String commandDigest;
  final String outputDigest;
  final DateTime startedAt;
  final DateTime finishedAt;
  final Duration duration;
  final EvaluationRunStatus status;
  final int exitCode;
  final EvaluationStateSnapshot initialState;
  final EvaluationStateSnapshot finalState;
  final EvaluationStateDiff diff;
  final List<EvaluationStepResult> stepResults;
  final List<String> shortcutsUsed;
  final Map<String, Object?>? checkpointProvenance;
  final List<String> artifacts;
  final Map<String, Object?>? error;
  final String relativeReceiptPath;
  final List<String> declaredCriterionIds;
  final List<EvaluationProductCriterionResult> productCriteria;

  bool get isSuccessful => status == EvaluationRunStatus.succeeded;

  Iterable<EvaluationProductCriterionResult> get passedProductCriteria {
    return productCriteria.where((criterion) => criterion.passed);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'runId': runId,
      'projectId': projectId,
      'scenarioId': scenarioId,
      'scenarioVersion': scenarioVersion,
      'policy': policy.name,
      'target': target.name,
      'evidenceLevel': evidenceLevel.name,
      'commit': commit,
      'projectTreeHash': projectTreeHash,
      'commandDigest': commandDigest,
      'outputDigest': outputDigest,
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt.toIso8601String(),
      'durationMilliseconds': duration.inMilliseconds,
      'status': status.name,
      'exitCode': exitCode,
      'initialState': initialState.toJson(),
      'finalState': finalState.toJson(),
      'diff': diff.toJson(),
      'stepResults': stepResults.map((result) => result.toJson()).toList(),
      'shortcutsUsed': shortcutsUsed,
      'checkpointProvenance': checkpointProvenance,
      'artifacts': artifacts,
      'error': error,
      'relativeReceiptPath': relativeReceiptPath,
      'declaredCriterionIds': declaredCriterionIds,
      'productCriteria': productCriteria
          .map((criterion) => criterion.toJson())
          .toList(growable: false),
    };
  }
}

EvaluationStateSnapshot _snapshotFromJson(
  Map<String, Object?> json,
  String name,
) {
  final world = _jsonMap(json, 'world');
  final position = _jsonMap(world, 'position');
  final trainer = _jsonMap(json, 'trainer');
  return EvaluationStateSnapshot(
    projectId: _jsonString(json, 'projectId'),
    runId: _jsonString(json, 'runId'),
    mapId: _jsonString(world, 'mapId'),
    x: _jsonInt(position, 'x'),
    y: _jsonInt(position, 'y'),
    movementMode: _jsonString(world, 'movementMode'),
    entityVisibility: _jsonBoolMap(world, 'entityVisibility'),
    facts: _jsonMap(json, 'facts'),
    eventLedger: _jsonMap(json, 'eventLedger'),
    progression: _jsonMap(json, 'progression'),
    money: _jsonInt(trainer, 'money'),
    badges: _jsonStringList(trainer, 'badges'),
    bag: _jsonIntMap(json, 'bag'),
    shop: _jsonMap(json, 'shop'),
    party: _jsonMapList(json, 'party'),
    storage: _jsonMapList(json, 'storage'),
    activeDialogue: _jsonNullableMap(json, 'dialogue'),
    activeScene: _jsonNullableMap(json, 'scene'),
    activeBattle: _jsonNullableMap(json, 'battle'),
    saveMetadata: _jsonMap(json, 'save'),
  );
}

EvaluationStateDiff _diffFromJson(Map<String, Object?> json) {
  final changes = _jsonList(json, 'changes').map((value) {
    final item = _valueAsMap(value, 'diff.changes');
    return EvaluationStateChange(
      path: _jsonString(item, 'path'),
      kind: _jsonEnum(
        EvaluationChangeKind.values,
        _jsonString(item, 'kind'),
        'diff.changes.kind',
      ),
      before: item['before'],
      after: item['after'],
    );
  }).toList(growable: false);
  return EvaluationStateDiff(changes);
}

Map<String, Object?> _jsonMap(Map<String, Object?> json, String key) {
  return _valueAsMap(json[key], key);
}

Map<String, Object?>? _jsonNullableMap(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  return value == null ? null : _valueAsMap(value, key);
}

Map<String, Object?> _valueAsMap(Object? value, String name) {
  if (value is! Map) {
    throw FormatException('$name must be a JSON object.');
  }
  try {
    return Map<String, Object?>.from(value);
  } on TypeError {
    throw FormatException('$name must have string keys.');
  }
}

List<Object?> _jsonList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('$key must be a JSON array.');
  }
  return List<Object?>.from(value);
}

List<String> _jsonStringList(Map<String, Object?> json, String key) {
  return _jsonList(json, key).map((value) {
    if (value is! String) {
      throw FormatException('$key must contain only strings.');
    }
    return value;
  }).toList(growable: false);
}

List<Map<String, Object?>> _jsonMapList(
  Map<String, Object?> json,
  String key,
) {
  return _jsonList(json, key)
      .map((value) => _valueAsMap(value, key))
      .toList(growable: false);
}

Map<String, bool> _jsonBoolMap(Map<String, Object?> json, String key) {
  final values = _jsonMap(json, key);
  return values.map((entryKey, value) {
    if (value is! bool) {
      throw FormatException('$key.$entryKey must be a boolean.');
    }
    return MapEntry<String, bool>(entryKey, value);
  });
}

Map<String, int> _jsonIntMap(Map<String, Object?> json, String key) {
  final values = _jsonMap(json, key);
  return values.map((entryKey, value) {
    if (value is! int) {
      throw FormatException('$key.$entryKey must be an integer.');
    }
    return MapEntry<String, int>(entryKey, value);
  });
}

String _jsonString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('$key must be a string.');
  }
  return value;
}

String? _jsonNullableString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value != null && value is! String) {
    throw FormatException('$key must be a string or null.');
  }
  return value as String?;
}

int _jsonInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('$key must be an integer.');
  }
  return value;
}

bool _jsonBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('$key must be a boolean.');
  }
  return value;
}

DateTime _jsonDateTime(Map<String, Object?> json, String key) {
  final value = _jsonString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$key must be an ISO-8601 timestamp.');
  }
  return parsed.toUtc();
}

T _jsonEnum<T extends Enum>(
  List<T> values,
  String value,
  String key,
) {
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw FormatException('$key has unsupported value "$value".');
}

int _exitCodeFor(EvaluationRunStatus status) {
  return switch (status) {
    EvaluationRunStatus.succeeded => 0,
    EvaluationRunStatus.failed => 1,
    EvaluationRunStatus.invalidScenario => 2,
    EvaluationRunStatus.infrastructureFailure => 3,
    EvaluationRunStatus.policyViolation => 4,
    EvaluationRunStatus.cancelled => 130,
  };
}

void _validateHash(String value, String name) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      name,
      'Expected a lowercase SHA-256 digest.',
    );
  }
}

String _relativePath(String value, String name) {
  final normalized = value.replaceAll(r'\', '/');
  final segments = normalized.split('/');
  if (value.trim().isEmpty ||
      normalized.startsWith('/') ||
      RegExp(r'^[A-Za-z]:/').hasMatch(normalized) ||
      normalized.startsWith('file:') ||
      segments.any((segment) => segment.isEmpty || segment == '..')) {
    throw ArgumentError.value(
      value,
      name,
      'Expected a portable relative path without traversal.',
    );
  }
  return normalized;
}

String _nonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Value must not be blank.');
  }
  return value;
}

Map<String, Object?> _freezeMap(Map<String, Object?> value) {
  return Map<String, Object?>.unmodifiable(
    value.map(
      (key, item) => MapEntry<String, Object?>(key, _freezeValue(item)),
    ),
  );
}

Object? _freezeValue(Object? value) {
  return switch (value) {
    Map<String, Object?> map => _freezeMap(map),
    Map map => _freezeMap(Map<String, Object?>.from(map)),
    List list => List<Object?>.unmodifiable(list.map(_freezeValue)),
    double number when !number.isFinite => throw ArgumentError.value(
        value,
        'value',
        'Receipt numbers must be finite.',
      ),
    null || bool() || num() || String() => value,
    _ => throw ArgumentError.value(
        value,
        'value',
        'Receipt values must be JSON-compatible.',
      ),
  };
}
