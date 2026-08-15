import '../contracts/evaluation_receipt.dart';

sealed class EvaluationWorkerMessage {
  const EvaluationWorkerMessage();

  Map<String, Object?> toJson();
}

final class EvaluationWorkerRequest extends EvaluationWorkerMessage {
  EvaluationWorkerRequest._({
    required this.runId,
    required this.projectRoot,
    required this.expectedProjectTreeHash,
    required this.scenarioPath,
    required this.outputDirectory,
  });

  factory EvaluationWorkerRequest.run({
    required String runId,
    required String projectRoot,
    required String expectedProjectTreeHash,
    required String scenarioPath,
    required String outputDirectory,
  }) {
    return EvaluationWorkerRequest._(
      runId: _nonBlank(runId, 'runId'),
      projectRoot: _portablePath(projectRoot, 'projectRoot'),
      expectedProjectTreeHash: _sha256(
        expectedProjectTreeHash,
        'expectedProjectTreeHash',
      ),
      scenarioPath: _portablePath(scenarioPath, 'scenarioPath'),
      outputDirectory: _portablePath(outputDirectory, 'outputDirectory'),
    );
  }

  factory EvaluationWorkerRequest.fromJson(Map<String, Object?> json) {
    _expectKeys(
      json,
      const <String>{
        'schemaVersion',
        'messageType',
        'runId',
        'projectRoot',
        'expectedProjectTreeHash',
        'scenarioPath',
        'outputDirectory',
      },
    );
    if (json['schemaVersion'] != schemaVersion ||
        json['messageType'] != 'run') {
      throw const FormatException('Unsupported evaluation worker request.');
    }
    return EvaluationWorkerRequest.run(
      runId: _string(json['runId'], 'runId'),
      projectRoot: _string(json['projectRoot'], 'projectRoot'),
      expectedProjectTreeHash: _string(
        json['expectedProjectTreeHash'],
        'expectedProjectTreeHash',
      ),
      scenarioPath: _string(json['scenarioPath'], 'scenarioPath'),
      outputDirectory: _string(json['outputDirectory'], 'outputDirectory'),
    );
  }

  static const schemaVersion = 2;

  final String runId;
  final String projectRoot;
  final String expectedProjectTreeHash;
  final String scenarioPath;
  final String outputDirectory;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'messageType': 'run',
      'runId': runId,
      'projectRoot': projectRoot,
      'expectedProjectTreeHash': expectedProjectTreeHash,
      'scenarioPath': scenarioPath,
      'outputDirectory': outputDirectory,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is EvaluationWorkerRequest &&
        other.runId == runId &&
        other.projectRoot == projectRoot &&
        other.expectedProjectTreeHash == expectedProjectTreeHash &&
        other.scenarioPath == scenarioPath &&
        other.outputDirectory == outputDirectory;
  }

  @override
  int get hashCode => Object.hash(
        runId,
        projectRoot,
        expectedProjectTreeHash,
        scenarioPath,
        outputDirectory,
      );
}

final class EvaluationWorkerResult extends EvaluationWorkerMessage {
  EvaluationWorkerResult._({
    required this.runId,
    required this.status,
    required this.exitCode,
    required this.receiptPath,
    required this.message,
  });

  factory EvaluationWorkerResult.completed({
    required String runId,
    required EvaluationRunStatus status,
    required int exitCode,
    String? receiptPath,
    String? message,
  }) {
    final expectedExitCode = _exitCodeFor(status);
    if (exitCode != expectedExitCode) {
      throw ArgumentError.value(
        exitCode,
        'exitCode',
        'Status ${status.name} requires exit code $expectedExitCode.',
      );
    }
    return EvaluationWorkerResult._(
      runId: _nonBlank(runId, 'runId'),
      status: status,
      exitCode: exitCode,
      receiptPath: receiptPath == null
          ? null
          : _portablePath(receiptPath, 'receiptPath'),
      message: message == null ? null : _nonBlank(message, 'message'),
    );
  }

  factory EvaluationWorkerResult.infrastructureFailure({
    required String runId,
    required String message,
  }) {
    return EvaluationWorkerResult.completed(
      runId: runId,
      status: EvaluationRunStatus.infrastructureFailure,
      exitCode: 3,
      message: message,
    );
  }

  factory EvaluationWorkerResult.fromJson(Map<String, Object?> json) {
    _expectKeys(
      json,
      const <String>{
        'schemaVersion',
        'messageType',
        'runId',
        'status',
        'exitCode',
        'receiptPath',
        'message',
      },
    );
    if (json['schemaVersion'] != schemaVersion ||
        json['messageType'] != 'result') {
      throw const FormatException('Unsupported evaluation worker result.');
    }
    final statusName = _string(json['status'], 'status');
    final status = EvaluationRunStatus.values
        .where((candidate) => candidate.name == statusName)
        .firstOrNull;
    if (status == null) {
      throw FormatException('Unknown evaluation worker status "$statusName".');
    }
    final exitCode = json['exitCode'];
    if (exitCode is! int) {
      throw const FormatException('Worker exitCode must be an integer.');
    }
    final receiptPath = json['receiptPath'];
    final message = json['message'];
    if (receiptPath != null && receiptPath is! String) {
      throw const FormatException('Worker receiptPath must be a string.');
    }
    if (message != null && message is! String) {
      throw const FormatException('Worker message must be a string.');
    }
    return EvaluationWorkerResult.completed(
      runId: _string(json['runId'], 'runId'),
      status: status,
      exitCode: exitCode,
      receiptPath: receiptPath as String?,
      message: message as String?,
    );
  }

  static const schemaVersion = 1;

  final String runId;
  final EvaluationRunStatus status;
  final int exitCode;
  final String? receiptPath;
  final String? message;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'messageType': 'result',
      'runId': runId,
      'status': status.name,
      'exitCode': exitCode,
      'receiptPath': receiptPath,
      'message': message,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is EvaluationWorkerResult &&
        other.runId == runId &&
        other.status == status &&
        other.exitCode == exitCode &&
        other.receiptPath == receiptPath &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(
        runId,
        status,
        exitCode,
        receiptPath,
        message,
      );
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

void _expectKeys(Map<String, Object?> json, Set<String> expected) {
  if (json.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(json.keys.toSet()).isNotEmpty) {
    throw const FormatException(
      'Evaluation worker message fields do not match the V1 schema.',
    );
  }
}

String _string(Object? value, String name) {
  if (value is! String) {
    throw FormatException('Worker $name must be a string.');
  }
  return value;
}

String _nonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Value must not be blank.');
  }
  return value;
}

String _sha256(String value, String name) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, name, 'Expected a lowercase SHA-256.');
  }
  return value;
}

String _portablePath(String value, String name) {
  final normalized = value.replaceAll(r'\', '/');
  final segments = normalized.split('/');
  if (value.trim().isEmpty ||
      normalized.startsWith('/') ||
      RegExp(r'^[A-Za-z]:/').hasMatch(normalized) ||
      normalized.startsWith('file:') ||
      segments.any(
        (segment) => segment.isEmpty || segment == '.' || segment == '..',
      )) {
    throw ArgumentError.value(
      value,
      name,
      'Expected a portable relative path without traversal.',
    );
  }
  return normalized;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
