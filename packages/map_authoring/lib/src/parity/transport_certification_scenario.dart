import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../support/authoring_fingerprint.dart';

part 'transport_certification_artifacts.dart';

enum AuthoringTransportRevisionScope { auto, project }

final class AuthoringTransportScenario {
  const AuthoringTransportScenario._(
    this.id,
    this.projectRoot,
    this.steps,
    this.catalogPreparation,
  );

  static List<AuthoringTransportScenario> parse(Object? input) {
    final manifest = transportEvidenceObject(input, 'recipe manifest');
    transportEvidenceFields(manifest, const {'schemaVersion', 'scenarios'});
    if (manifest['schemaVersion'] != 1) {
      throw const FormatException('Unsupported transport recipe version.');
    }
    final scenarios = transportEvidenceList(manifest['scenarios'], 'scenarios');
    final ids = <String>{};
    return List.unmodifiable(scenarios.map((input) {
      final json = transportEvidenceObject(input, 'scenario');
      transportEvidenceFields(
        json,
        const {'id', 'projectRoot', 'steps'},
        optional: const {'catalogPreparation'},
      );
      final id = json['id'];
      if (id is! String ||
          !RegExp(r'^[a-z][a-z0-9_-]{0,63}$').hasMatch(id) ||
          !ids.add(id)) {
        throw FormatException('Invalid or duplicate scenario id: $id');
      }
      final preparation = json['catalogPreparation'];
      if (json.containsKey('catalogPreparation') &&
          (preparation is! List ||
              preparation
                  .any((scope) => scope is! String || scope.trim().isEmpty) ||
              preparation.toSet().length != preparation.length)) {
        throw FormatException('Invalid catalog preparation for $id.');
      }
      return AuthoringTransportScenario._(
        id,
        transportEvidencePath(json['projectRoot']),
        List.unmodifiable(
          transportEvidenceList(json['steps'], 'steps')
              .map((step) => AuthoringTransportStep.fromJson(
                    transportEvidenceObject(step, 'step'),
                  )),
        ),
        preparation is List ? List<String>.unmodifiable(preparation) : null,
      );
    }));
  }

  final String id;
  final String projectRoot;
  final List<AuthoringTransportStep> steps;
  final List<String>? catalogPreparation;
}

final class AuthoringTransportStep {
  const AuthoringTransportStep._(
    this.actionId,
    this.actionVersion,
    this.parameters,
    this.confirm,
    this.planOnly,
    this.revisionScope,
    this.artifacts,
    this.observations,
  );

  factory AuthoringTransportStep.fromJson(Map<String, Object?> json) {
    transportEvidenceFields(json, const {
      'actionId',
      'actionVersion',
      'parameters',
      'observations',
    }, optional: const {
      'confirm',
      'planOnly',
      'revisionScope',
      'artifact',
      'artifacts',
    });
    final actionId = json['actionId'];
    final actionVersion = json['actionVersion'];
    final confirm = json.containsKey('confirm') ? json['confirm'] : false;
    final planOnly = json.containsKey('planOnly') ? json['planOnly'] : false;
    final scopeName =
        json.containsKey('revisionScope') ? json['revisionScope'] : 'auto';
    final revisionScope =
        AuthoringTransportRevisionScope.values.asNameMap()[scopeName];
    final parameters =
        transportEvidenceObject(json['parameters'], 'parameters');
    if (actionId is! String ||
        !RegExp(r'^[a-zA-Z][a-zA-Z0-9._-]+$').hasMatch(actionId) ||
        actionVersion is! int ||
        actionVersion < 1 ||
        confirm is! bool ||
        planOnly is! bool ||
        revisionScope == null) {
      throw const FormatException('Invalid authoring step identity.');
    }
    final previewAction = const {
      'presentation.preset.import_plan',
      'presentation.preset.delete_plan',
    }.contains(actionId);
    if (planOnly != previewAction || (planOnly && confirm)) {
      throw FormatException('Invalid plan-only step: $actionId.');
    }
    return AuthoringTransportStep._(
      actionId,
      actionVersion,
      parameters,
      confirm,
      planOnly,
      revisionScope,
      _parseArtifactBindings(json, parameters),
      List.unmodifiable(
        transportEvidenceList(json['observations'], 'observations').map(
          (input) => AuthoringTransportObservation.fromJson(
            transportEvidenceObject(input, 'observation'),
          ),
        ),
      ),
    );
  }

  final String actionId;
  final int actionVersion;
  final Map<String, Object?> parameters;
  final bool confirm;
  final bool planOnly;
  final AuthoringTransportRevisionScope revisionScope;
  final List<AuthoringTransportArtifact> artifacts;
  final List<AuthoringTransportObservation> observations;

  Map<String, Object?> bindArtifactHandles(List<String> handles) {
    if (handles.length != artifacts.length) {
      throw FormatException('Wrong staged artifact count for $actionId.');
    }
    if (artifacts.isEmpty) return parameters;
    final result = transportEvidenceObject(
      jsonDecode(canonicalAuthoringJson(parameters)),
      'action parameters',
    );
    for (final (index, artifact) in artifacts.indexed) {
      artifact._slot(result)[artifact.parameterPath.last as String] =
          handles[index];
    }
    return result;
  }

  Future<List<Object?>> observe(Directory root) async => [
        for (final observation in observations) await observation.read(root),
      ];

  void verify(List<Object?> before, List<Object?> after) {
    if (before.length != observations.length ||
        after.length != observations.length) {
      throw FormatException('Invalid observation count for $actionId.');
    }
    for (final (index, observation) in observations.indexed) {
      observation.verify(before[index], after[index]);
    }
    final unchanged =
        canonicalAuthoringJson(before) == canonicalAuthoringJson(after);
    if (planOnly != unchanged) {
      throw FormatException(planOnly
          ? '$actionId changed its persisted observations during planning.'
          : '$actionId left its persisted observations unchanged.');
    }
  }
}

final class AuthoringTransportObservation {
  const AuthoringTransportObservation._(
      this.path, this.at, this.condition, this.expected);

  factory AuthoringTransportObservation.fromJson(Map<String, Object?> json) {
    const conditions = {'equals', 'exists', 'absent', 'sha256'};
    transportEvidenceFields(json, const {'path'},
        optional: {'at', ...conditions});
    final selected = json.keys.where(conditions.contains).toList();
    if (selected.length != 1) {
      throw const FormatException(
          'An observation requires exactly one condition.');
    }
    final condition = selected.single;
    final expected = json[condition];
    final path = transportEvidencePath(json['path']);
    final at = json['at'] ?? const [];
    if (path.split('/').first == '.pokemap' ||
        at is! List ||
        at.any((value) => value is! String && (value is! int || value < 0)) ||
        (condition == 'sha256' &&
            (at.isNotEmpty || !isTransportEvidenceDigest(expected))) ||
        ((condition == 'exists' || condition == 'absent') &&
            expected != true)) {
      throw FormatException('Invalid persisted observation: $path.');
    }
    return AuthoringTransportObservation._(
        path, List.unmodifiable(at), condition, expected);
  }

  final String path;
  final List<Object?> at;
  final String condition;
  final Object? expected;

  Future<Map<String, Object?>> read(Directory root) async {
    final file = File(p.join(root.path, path));
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return const {'present': false};
    if (type != FileSystemEntityType.file ||
        !p.isWithin(root.path, await file.resolveSymbolicLinks())) {
      throw FormatException(
          'Observation must read a regular project file: $path.');
    }
    Object? value;
    if (condition == 'sha256') {
      value = 'sha256:${(await sha256.bind(file.openRead()).first)}';
    } else if (at.isNotEmpty || condition == 'equals') {
      value = jsonDecode(await file.readAsString());
      for (final selector in at) {
        if (selector is String && value is Map && value.containsKey(selector)) {
          value = value[selector];
        } else if (selector is int &&
            value is List &&
            selector < value.length) {
          value = value[selector];
        } else {
          return const {'present': false};
        }
      }
    }
    return {'present': true, 'value': value};
  }

  void verify(Object? rawBefore, Object? rawAfter) {
    final before = _validatedObservation(rawBefore);
    final after = _validatedObservation(rawAfter);
    final matches = switch (condition) {
      'absent' => after['present'] == false,
      'exists' => after['present'] == true,
      _ => after['present'] == true &&
          canonicalAuthoringJson(after['value']) ==
              canonicalAuthoringJson(expected),
    };
    if (!matches) {
      throw FormatException(
        'Persisted observation $path $at expected $condition $expected, got $after.',
      );
    }
    if (condition == 'sha256' &&
        before['present'] == true &&
        !isTransportEvidenceDigest(before['value'])) {
      throw FormatException('Invalid prior file digest: $path.');
    }
  }

  Map<String, Object?> _validatedObservation(Object? input) {
    final result = transportEvidenceObject(input, 'observation result');
    final present = result['present'];
    if (present is! bool) {
      throw const FormatException('Missing observation presence.');
    }
    transportEvidenceFields(result, {'present', if (present) 'value'});
    return result;
  }
}

Map<String, Object?> transportEvidenceObject(Object? value, String field) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$field must be a JSON object.');
  }
  return Map<String, Object?>.from(value);
}

List<Object?> transportEvidenceList(Object? value, String field) {
  if (value is! List || value.isEmpty) {
    throw FormatException('$field must be a non-empty JSON array.');
  }
  return List<Object?>.from(value);
}

void transportEvidenceFields(
  Map<String, Object?> object,
  Set<String> required, {
  Set<String> optional = const {},
}) {
  final keys = object.keys.toSet();
  if (!keys.containsAll(required) ||
      keys.difference({...required, ...optional}).isNotEmpty) {
    throw FormatException('Invalid fields: ${keys.join(', ')}.');
  }
}

String transportEvidencePath(Object? value) {
  if (value is! String ||
      p.isAbsolute(value) ||
      value.contains(r'\') ||
      value
          .split('/')
          .any((part) => part.isEmpty || part == '.' || part == '..')) {
    throw FormatException('Expected a relative evidence path: $value.');
  }
  return value;
}

bool isTransportEvidenceDigest(Object? value) =>
    value is String && RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value);

String transportEvidenceDigest(Object? value) =>
    'sha256:${sha256.convert(utf8.encode(canonicalAuthoringJson(value)))}';
