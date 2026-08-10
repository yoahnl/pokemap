import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../../contracts/action_descriptor.dart';
import '../../../contracts/authoring_diff.dart';
import '../../../contracts/json_contract_support.dart';
import '../../../contracts/resource_ref.dart';
import '../../../transactions/authoring_plan.dart';
import '../../../transactions/change_set.dart';
import '../../../workspace/project_snapshot.dart';
import '../../maps/map_lifecycle_adapter.dart';

final class CharacterStudioActionException implements Exception {
  CharacterStudioActionException(
    this.code,
    this.message, {
    Map<String, Object?> details = const <String, Object?>{},
  }) : details = freezeContractJsonObject(details, field: 'details');

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'CharacterStudioActionException($code): $message';
}

AuthoringActionDescriptor characterStudioActionDescriptor(
  String id,
  String summary, {
  AuthoringRiskLevel risk = AuthoringRiskLevel.medium,
}) {
  return AuthoringActionDescriptor(
    id: id,
    version: 1,
    summary: summary,
    inputSchemaId: 'pokemap.authoring/$id.input.v1',
    outputSchemaId: 'pokemap.authoring/$id.output.v1',
    riskLevel: risk,
    resourceKinds: const <String>[
      'project',
      'characterStudioCatalog',
      'characterStudioDependency',
    ],
    capabilityIds: const <String>[
      'authoring.characterStudio.catalog',
    ],
    requiredPermissions: const <AuthoringPermission>[
      AuthoringPermission.projectWrite,
    ],
    guarantees: const <AuthoringGuarantee>[
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.atomic,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
    ],
  );
}

AuthoringMutationDraft characterStudioProjectDraft(
  ProjectSnapshot snapshot,
  ProjectManifest projected, {
  required String operation,
  required String path,
  Object? before,
  Object? after,
  Map<String, MapData> projectedMaps = const <String, MapData>{},
  Map<String, Object?> preview = const <String, Object?>{},
}) {
  final project = AuthoringResourceRef(
    kind: 'project',
    id: 'project',
    revision: snapshot.resourceFingerprints['project'],
  );
  final mapIds = projectedMaps.keys.toList()..sort();
  final mapChanges = <AuthoringResourceChange>[];
  final mapDiffs = <AuthoringDiffEntry>[];
  for (final mapId in mapIds) {
    final map = projectedMaps[mapId]!;
    final resourceIdentity = 'map:$mapId';
    final revision = snapshot.resourceFingerprints[resourceIdentity];
    final storageKey = snapshot.resourceStorageKeys[resourceIdentity];
    if (revision == null || storageKey == null) {
      throw CharacterStudioActionException(
        'character_studio.map_resource_unavailable',
        'A referenced map cannot be changed by Character Studio.',
        details: <String, Object?>{'mapId': mapId},
      );
    }
    final mapResource = AuthoringResourceRef(
      kind: 'map',
      id: mapId,
      revision: revision,
    );
    mapChanges.add(
      AuthoringResourceChange(
        resource: mapResource,
        storageKey: storageKey,
        beforeBytes: snapshot.resourceBytes(resourceIdentity),
        afterBytes: encodeMapAuthoringDocument(map),
      ),
    );
    mapDiffs.add(
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: mapResource,
        path: '/entities',
        before: <String, Object?>{'characterReferencesChanged': true},
        after: <String, Object?>{'characterReferencesChanged': true},
      ),
    );
  }
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: <AuthoringResourceChange>[
        AuthoringResourceChange(
          resource: project,
          storageKey: snapshot.resourceStorageKeys['project'] ?? 'project.json',
          beforeBytes: snapshot.resourceBytes('project'),
          afterBytes: _encodeCharacterStudioProject(snapshot, projected),
        ),
        ...mapChanges,
      ],
      diff: AuthoringDiff(<AuthoringDiffEntry>[
        AuthoringDiffEntry(
          operation: after == null
              ? AuthoringDiffOperation.remove
              : before == null
                  ? AuthoringDiffOperation.add
                  : AuthoringDiffOperation.replace,
          resource: project,
          path: path,
          before: before,
          after: after,
        ),
        ...mapDiffs,
      ]),
    ),
    preview: <String, Object?>{
      'operation': operation,
      'path': path,
      ...preview,
    },
  );
}

List<int> _encodeCharacterStudioProject(
  ProjectSnapshot snapshot,
  ProjectManifest projected,
) {
  final bytes = encodeProjectAuthoringDocument(snapshot, projected);
  if (projected.characterStudioCatalog.portraitStates.isNotEmpty ||
      projected.characterStudioCatalog.customAnimationDefinitions.isNotEmpty) {
    return bytes;
  }
  final json = Map<String, Object?>.from(
    jsonDecode(utf8.decode(bytes)) as Map,
  )..remove('characterStudioCatalog');
  return utf8.encode(const JsonEncoder.withIndent('  ').convert(json));
}

final class CharacterStudioActionParameters {
  CharacterStudioActionParameters(this.values);

  final Map<String, Object?> values;

  void allow(Set<String> allowed) {
    final unknown = values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw CharacterStudioActionException(
        'character_studio.parameters.unknown',
        'The request contains unsupported Character Studio parameters.',
        details: <String, Object?>{'parameters': unknown},
      );
    }
  }

  String string(String key) {
    final value = values[key];
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw CharacterStudioActionException(
        'character_studio.parameters.string_required',
        '$key must be a nonblank trimmed string.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  String? optionalString(String key) {
    if (!values.containsKey(key) || values[key] == null) return null;
    return string(key);
  }

  bool contains(String key) => values.containsKey(key);

  int positiveInt(String key) {
    final value = values[key];
    if (value is! int || value <= 0) {
      throw CharacterStudioActionException(
        'character_studio.parameters.positive_int_required',
        '$key must be a positive integer.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  int integer(String key) {
    final value = values[key];
    if (value is! int) {
      throw CharacterStudioActionException(
        'character_studio.parameters.int_required',
        '$key must be an integer.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  int nonNegativeInt(String key) {
    final value = integer(key);
    if (value < 0) {
      throw CharacterStudioActionException(
        'character_studio.parameters.non_negative_int_required',
        '$key must be a non-negative integer.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  int? optionalNonNegativeInt(String key) {
    if (!values.containsKey(key) || values[key] == null) return null;
    return nonNegativeInt(key);
  }

  int? optionalPositiveInt(String key) {
    if (!values.containsKey(key) || values[key] == null) return null;
    return positiveInt(key);
  }

  bool boolean(String key) {
    final value = values[key];
    if (value is! bool) {
      throw CharacterStudioActionException(
        'character_studio.parameters.boolean_required',
        '$key must be a boolean.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  bool? optionalBoolean(String key) {
    if (!values.containsKey(key) || values[key] == null) return null;
    return boolean(key);
  }

  List<String> strings(String key) {
    final value = values[key];
    if (value is! List || value.any((item) => item is! String)) {
      throw CharacterStudioActionException(
        'character_studio.parameters.string_list_required',
        '$key must be a list of strings.',
        details: <String, Object?>{'parameter': key},
      );
    }
    final result = <String>[];
    for (final item in value.cast<String>()) {
      if (item.trim().isEmpty || item != item.trim() || result.contains(item)) {
        throw CharacterStudioActionException(
          'character_studio.parameters.string_list_invalid',
          '$key must contain unique nonblank trimmed strings.',
          details: <String, Object?>{'parameter': key},
        );
      }
      result.add(item);
    }
    return result;
  }

  List<String>? optionalStrings(String key) {
    if (!values.containsKey(key) || values[key] == null) return null;
    return strings(key);
  }

  Map<String, Object?> object(String key) {
    final value = values[key];
    if (value is! Map || value.keys.any((entry) => entry is! String)) {
      throw CharacterStudioActionException(
        'character_studio.parameters.object_required',
        '$key must be an object.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return Map<String, Object?>.from(value);
  }

  List<Map<String, Object?>> objects(String key) {
    final value = values[key];
    if (value is! List) {
      throw CharacterStudioActionException(
        'character_studio.parameters.object_list_required',
        '$key must be a list of objects.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return <Map<String, Object?>>[
      for (final item in value)
        if (item is Map && item.keys.every((entry) => entry is String))
          Map<String, Object?>.from(item)
        else
          throw CharacterStudioActionException(
            'character_studio.parameters.object_list_required',
            '$key must be a list of objects.',
            details: <String, Object?>{'parameter': key},
          ),
    ];
  }
}

String characterStudioSlug(String value) {
  const replacements = <String, String>{
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'œ': 'oe',
    'æ': 'ae',
  };
  final lowered = value.toLowerCase();
  final normalized = StringBuffer();
  for (final rune in lowered.runes) {
    final character = String.fromCharCode(rune);
    normalized.write(replacements[character] ?? character);
  }
  final slug = normalized
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isEmpty) {
    throw CharacterStudioActionException(
      'character_studio.id_derivation_failed',
      'The display name cannot produce a stable Character Studio identifier.',
      details: <String, Object?>{'displayName': value},
    );
  }
  return slug;
}

Map<String, Object?> characterStudioReferenceJson(
  CharacterStudioReference reference,
) {
  return <String, Object?>{
    'targetKind': reference.targetKind.name,
    'targetId': reference.targetId,
    'sourceKind': reference.sourceKind.name,
    'sourceId': reference.sourceId,
    'path': reference.path,
  };
}

void requireCharacterStudioActionMode({
  required String actionId,
  required bool dryRun,
  required bool plan,
}) {
  if (plan && !dryRun) {
    throw CharacterStudioActionException(
      'character_studio.delete_plan_requires_dry_run',
      '$actionId must be requested with dryRun enabled.',
    );
  }
  if (!plan && dryRun) {
    throw CharacterStudioActionException(
      'character_studio.delete_requires_apply_mode',
      '$actionId must be requested with dryRun disabled.',
    );
  }
}
