import 'dart:convert';

enum CinematicV2FinalEvidenceId {
  preSessionRails,
  authoringTransports,
  replacementCanary,
  previewRuntimeParity,
  offlinePackaging,
  saveRollback,
  platformMatrix,
  runtimePerformance,
  observabilityPrivacy,
  accessibilityLifecycle,
  mediaFailureHandling,
  zeroLegacyCutover,
}

enum CinematicV2FinalEvidenceStatus { passed, failed, blocked }

enum CinematicV2DependencyWorkflowStatus { todo, doing, toReview, done }

enum CinematicV2TechnicalVerdict { pass, partial, fail }

final class CinematicV2FinalDependency {
  const CinematicV2FinalDependency({
    required this.ticket,
    required this.workflowStatus,
    required this.technicalVerdict,
    required this.sourceCommit,
  });

  factory CinematicV2FinalDependency.fromJson(Map<String, Object?> json) {
    _expectKeys(json, const <String>{
      'ticket',
      'workflowStatus',
      'technicalVerdict',
      'sourceCommit',
    }, r'$.dependencies[]');
    return CinematicV2FinalDependency(
      ticket: _string(json['ticket'], r'$.dependencies[].ticket'),
      workflowStatus: _enumByName(
        CinematicV2DependencyWorkflowStatus.values,
        json['workflowStatus'],
        r'$.dependencies[].workflowStatus',
      ),
      technicalVerdict: _enumByName(
        CinematicV2TechnicalVerdict.values,
        json['technicalVerdict'],
        r'$.dependencies[].technicalVerdict',
      ),
      sourceCommit: _digest(
        json['sourceCommit'],
        r'$.dependencies[].sourceCommit',
        40,
      ),
    );
  }

  final String ticket;
  final CinematicV2DependencyWorkflowStatus workflowStatus;
  final CinematicV2TechnicalVerdict technicalVerdict;
  final String sourceCommit;

  bool get passed =>
      workflowStatus == CinematicV2DependencyWorkflowStatus.done &&
      technicalVerdict == CinematicV2TechnicalVerdict.pass;

  Map<String, Object?> toJson() => <String, Object?>{
    'ticket': ticket,
    'workflowStatus': workflowStatus.name,
    'technicalVerdict': technicalVerdict.name,
    'sourceCommit': sourceCommit,
  };
}

final class CinematicV2FinalEvidence {
  CinematicV2FinalEvidence({
    required this.id,
    required this.sourceTicket,
    required this.sourceCommit,
    required this.status,
    required this.summary,
    required this.command,
    required this.resultSha256,
    required List<String> limitations,
  }) : limitations = List<String>.unmodifiable(limitations);

  factory CinematicV2FinalEvidence.fromJson(Map<String, Object?> json) {
    _expectKeys(json, const <String>{
      'id',
      'sourceTicket',
      'sourceCommit',
      'status',
      'summary',
      'command',
      'resultSha256',
      'limitations',
    }, r'$.evidence[]');
    return CinematicV2FinalEvidence(
      id: _enumByName(
        CinematicV2FinalEvidenceId.values,
        json['id'],
        r'$.evidence[].id',
      ),
      sourceTicket: _string(json['sourceTicket'], r'$.evidence[].sourceTicket'),
      sourceCommit: _digest(
        json['sourceCommit'],
        r'$.evidence[].sourceCommit',
        40,
      ),
      status: _enumByName(
        CinematicV2FinalEvidenceStatus.values,
        json['status'],
        r'$.evidence[].status',
      ),
      summary: _string(json['summary'], r'$.evidence[].summary'),
      command: _nullableString(json['command'], r'$.evidence[].command'),
      resultSha256: _nullableDigest(
        json['resultSha256'],
        r'$.evidence[].resultSha256',
        64,
      ),
      limitations: _strings(json['limitations'], r'$.evidence[].limitations'),
    );
  }

  final CinematicV2FinalEvidenceId id;
  final String sourceTicket;
  final String sourceCommit;
  final CinematicV2FinalEvidenceStatus status;
  final String summary;
  final String? command;
  final String? resultSha256;
  final List<String> limitations;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id.name,
    'sourceTicket': sourceTicket,
    'sourceCommit': sourceCommit,
    'status': status.name,
    'summary': summary,
    'command': command,
    'resultSha256': resultSha256,
    'limitations': limitations,
  };
}

final class CinematicV2FinalCertificationReceipt {
  CinematicV2FinalCertificationReceipt({
    this.schemaVersion = 1,
    required this.releaseCommit,
    required this.treeFingerprint,
    required this.evidenceSha256,
    required List<CinematicV2FinalDependency> dependencies,
    required List<CinematicV2FinalEvidence> evidence,
  }) : dependencies = List<CinematicV2FinalDependency>.unmodifiable(
         dependencies.toList()..sort(
           (left, right) => requiredDependencyTickets
               .indexOf(left.ticket)
               .compareTo(requiredDependencyTickets.indexOf(right.ticket)),
         ),
       ),
       evidence = List<CinematicV2FinalEvidence>.unmodifiable(
         evidence.toList()
           ..sort((left, right) => left.id.index.compareTo(right.id.index)),
       ) {
    _validate();
  }

  factory CinematicV2FinalCertificationReceipt.fromJson(
    Map<String, Object?> json,
  ) {
    _expectKeys(json, const <String>{
      'schemaVersion',
      'releaseCommit',
      'treeState',
      'treeFingerprint',
      'evidenceSha256',
      'verdict',
      'blockingDependencies',
      'blockingEvidence',
      'dependencies',
      'evidence',
    }, r'$');
    if (json['schemaVersion'] != 1) {
      throw const FormatException(r'$.schemaVersion must be 1.');
    }
    if (json['treeState'] != 'clean') {
      throw const FormatException(r'$.treeState must be clean.');
    }
    final dependencies = _maps(
      json['dependencies'],
      r'$.dependencies',
    ).map(CinematicV2FinalDependency.fromJson).toList(growable: false);
    final evidence = _maps(
      json['evidence'],
      r'$.evidence',
    ).map(CinematicV2FinalEvidence.fromJson).toList(growable: false);
    final rebuilt = CinematicV2FinalCertificationReceipt(
      releaseCommit: _digest(json['releaseCommit'], r'$.releaseCommit', 40),
      treeFingerprint: _digest(
        json['treeFingerprint'],
        r'$.treeFingerprint',
        64,
      ),
      evidenceSha256: _digest(json['evidenceSha256'], r'$.evidenceSha256', 64),
      dependencies: dependencies,
      evidence: evidence,
    );
    if (!_deepEquals(rebuilt.toJson(), json)) {
      throw const FormatException(
        'CIN-008 receipt is non-canonical or inconsistent.',
      );
    }
    return rebuilt;
  }

  static const List<String> requiredDependencyTickets = <String>[
    'BETA-CIN-010',
    'BETA-CIN-028',
    'BETA-CIN-033',
    'BETA-CIN-036',
    'BETA-CIN-038',
    'BETA-CIN-041',
    'BETA-LCH-001',
  ];

  static const Map<CinematicV2FinalEvidenceId, String> _expectedSourceTickets =
      <CinematicV2FinalEvidenceId, String>{
        CinematicV2FinalEvidenceId.preSessionRails: 'BETA-LCH-001',
        CinematicV2FinalEvidenceId.authoringTransports: 'BETA-CIN-033',
        CinematicV2FinalEvidenceId.replacementCanary: 'BETA-CIN-042',
        CinematicV2FinalEvidenceId.previewRuntimeParity: 'BETA-CIN-041',
        CinematicV2FinalEvidenceId.offlinePackaging: 'BETA-CIN-027',
        CinematicV2FinalEvidenceId.saveRollback: 'BETA-CIN-036',
        CinematicV2FinalEvidenceId.platformMatrix: 'BETA-CIN-028',
        CinematicV2FinalEvidenceId.runtimePerformance: 'BETA-CIN-038',
        CinematicV2FinalEvidenceId.observabilityPrivacy: 'BETA-CIN-037',
        CinematicV2FinalEvidenceId.accessibilityLifecycle: 'BETA-CIN-040',
        CinematicV2FinalEvidenceId.mediaFailureHandling: 'BETA-CIN-032',
        CinematicV2FinalEvidenceId.zeroLegacyCutover: 'BETA-CIN-010',
      };

  static String expectedSourceTicket(CinematicV2FinalEvidenceId id) =>
      _expectedSourceTickets[id]!;

  final int schemaVersion;
  final String releaseCommit;
  final String treeFingerprint;
  final String evidenceSha256;
  final List<CinematicV2FinalDependency> dependencies;
  final List<CinematicV2FinalEvidence> evidence;

  List<String> get blockingDependencies => List<String>.unmodifiable(
    dependencies.where((entry) => !entry.passed).map((entry) => entry.ticket),
  );

  List<CinematicV2FinalEvidenceId> get blockingEvidence =>
      List<CinematicV2FinalEvidenceId>.unmodifiable(
        evidence
            .where(
              (entry) => entry.status != CinematicV2FinalEvidenceStatus.passed,
            )
            .map((entry) => entry.id),
      );

  bool get passed => blockingDependencies.isEmpty && blockingEvidence.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'releaseCommit': releaseCommit,
    'treeState': 'clean',
    'treeFingerprint': treeFingerprint,
    'evidenceSha256': evidenceSha256,
    'verdict': passed ? 'passed' : 'failed',
    'blockingDependencies': blockingDependencies,
    'blockingEvidence': blockingEvidence.map((id) => id.name).toList(),
    'dependencies': dependencies.map((entry) => entry.toJson()).toList(),
    'evidence': evidence.map((entry) => entry.toJson()).toList(),
  };

  String encodeCanonical() => jsonEncode(toJson());

  void _validate() {
    if (schemaVersion != 1) {
      throw const FormatException(r'$.schemaVersion must be 1.');
    }
    _digest(releaseCommit, r'$.releaseCommit', 40);
    _digest(treeFingerprint, r'$.treeFingerprint', 64);
    _digest(evidenceSha256, r'$.evidenceSha256', 64);
    final dependencyTickets = dependencies
        .map((entry) => entry.ticket)
        .toList();
    if (!_sameStrings(dependencyTickets, requiredDependencyTickets)) {
      throw const FormatException(
        r'$.dependencies must contain every CIN-008 blocker exactly once.',
      );
    }
    for (final dependency in dependencies) {
      _digest(dependency.sourceCommit, r'$.dependencies[].sourceCommit', 40);
      final matchingEvidence = evidence
          .where((entry) => entry.sourceTicket == dependency.ticket)
          .toList();
      if (matchingEvidence.length != 1 ||
          matchingEvidence.single.sourceCommit != dependency.sourceCommit) {
        throw FormatException(
          r'$.dependencies.'
          '${dependency.ticket} must match its evidence source commit.',
        );
      }
    }
    final evidenceIds = evidence.map((entry) => entry.id).toList();
    if (evidenceIds.length != CinematicV2FinalEvidenceId.values.length ||
        evidenceIds.toSet().length != evidenceIds.length) {
      throw const FormatException(
        r'$.evidence must contain every CIN-008 dimension exactly once.',
      );
    }
    for (final id in CinematicV2FinalEvidenceId.values) {
      if (!evidenceIds.contains(id)) {
        throw FormatException(r'$.evidence is missing ' + id.name + '.');
      }
    }
    for (final entry in evidence) {
      final path = r'$.evidence.' + entry.id.name;
      if (entry.sourceTicket != expectedSourceTicket(entry.id)) {
        throw FormatException('$path.sourceTicket is inconsistent.');
      }
      _digest(entry.sourceCommit, '$path.sourceCommit', 40);
      _safeText(entry.summary, '$path.summary');
      for (final limitation in entry.limitations) {
        _safeText(limitation, '$path.limitations');
      }
      if (entry.status == CinematicV2FinalEvidenceStatus.blocked) {
        if (entry.command != null ||
            entry.resultSha256 != null ||
            entry.limitations.isEmpty) {
          throw FormatException(
            '$path blocked evidence requires limitations and no result.',
          );
        }
      } else {
        if (entry.command == null || entry.resultSha256 == null) {
          throw FormatException(
            '$path executed evidence requires command and result digest.',
          );
        }
        _safeText(entry.command!, '$path.command');
        _digest(entry.resultSha256!, '$path.resultSha256', 64);
      }
    }
  }
}

T _enumByName<T extends Enum>(List<T> values, Object? value, String path) {
  if (value is! String) throw FormatException('$path must be a string.');
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw FormatException('$path has an unsupported value.');
}

String _string(Object? value, String path) {
  if (value is! String || value.isEmpty) {
    throw FormatException('$path must be a non-empty string.');
  }
  return value;
}

String? _nullableString(Object? value, String path) {
  if (value == null) return null;
  return _string(value, path);
}

String _digest(Object? value, String path, int length) {
  final digest = _string(value, path);
  if (!RegExp('^[0-9a-f]{$length}\$').hasMatch(digest)) {
    throw FormatException('$path must be a lowercase hexadecimal digest.');
  }
  return digest;
}

String? _nullableDigest(Object? value, String path, int length) {
  if (value == null) return null;
  return _digest(value, path, length);
}

List<String> _strings(Object? value, String path) {
  if (value is! List<Object?>) {
    throw FormatException('$path must be an array.');
  }
  return List<String>.unmodifiable(
    value.indexed.map((entry) => _string(entry.$2, '$path[${entry.$1}]')),
  );
}

List<Map<String, Object?>> _maps(Object? value, String path) {
  if (value is! List<Object?>) {
    throw FormatException('$path must be an array.');
  }
  return value.indexed
      .map((entry) {
        final item = entry.$2;
        if (item is! Map) {
          throw FormatException('$path[${entry.$1}] must be an object.');
        }
        return item.map((key, value) => MapEntry(key.toString(), value));
      })
      .toList(growable: false);
}

void _safeText(String value, String path) {
  if (value.length > 600 ||
      RegExp(
        r'(^|[\s"\x27(])/(Users|home|private|tmp|var|etc)/',
      ).hasMatch(value) ||
      RegExp(r'[A-Za-z]:\\').hasMatch(value) ||
      RegExp(
        r'(bearer\s+|api[_-]?key\s*[=:]|token\s*[=:])',
        caseSensitive: false,
      ).hasMatch(value)) {
    throw FormatException('$path contains unsafe text.');
  }
}

void _expectKeys(Map<String, Object?> json, Set<String> expected, String path) {
  if (!_sameStrings(json.keys, expected)) {
    throw FormatException('$path has unexpected or missing keys.');
  }
}

bool _sameStrings(Iterable<String> left, Iterable<String> right) {
  final leftList = left.toList();
  final rightList = right.toList();
  return leftList.length == rightList.length &&
      leftList.toSet().containsAll(rightList) &&
      rightList.toSet().containsAll(leftList);
}

bool _deepEquals(Object? left, Object? right) {
  if (left is Map && right is Map) {
    return _sameStrings(
          left.keys.map((key) => key.toString()),
          right.keys.map((key) => key.toString()),
        ) &&
        left.keys.every((key) => _deepEquals(left[key], right[key]));
  }
  if (left is List && right is List) {
    return left.length == right.length &&
        List.generate(
          left.length,
          (index) => _deepEquals(left[index], right[index]),
        ).every((value) => value);
  }
  return left == right;
}
