# PMCP-060 — Contenu intégral des fichiers créés

Cette annexe reproduit intégralement les fichiers texte créés par le lot.

## `packages/map_authoring/lib/src/domains/gameplay/pokemon_catalog_actions.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/json_contract_support.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/project_file_reader.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';

enum PokemonDocumentKind { catalog, species, learnset, evolution, media }

final class PokemonJsonDocument {
  PokemonJsonDocument._(this.kind, Map<String, Object?> json)
      : _json = freezeContractJsonObject(json, field: 'document') {
    _validateIdentity();
  }

  factory PokemonJsonDocument.fromJson(
    PokemonDocumentKind kind,
    Map<String, dynamic> json,
  ) =>
      PokemonJsonDocument._(kind, Map<String, Object?>.from(json));

  final PokemonDocumentKind kind;
  final Map<String, Object?> _json;

  String get identity {
    final key = kind == PokemonDocumentKind.catalog
        ? 'catalog'
        : kind == PokemonDocumentKind.species
            ? 'id'
            : 'speciesId';
    return _json[key] as String;
  }

  Map<String, Object?> toJson() => freezeContractJsonObject(
        _json,
        field: 'document',
      );

  void _validateIdentity() {
    final key = kind == PokemonDocumentKind.catalog
        ? 'catalog'
        : kind == PokemonDocumentKind.species
            ? 'id'
            : 'speciesId';
    final value = _json[key];
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw FormatException('${kind.name} document requires "$key".');
    }
    if (kind == PokemonDocumentKind.catalog) {
      _validatedCatalogEntries(_json['entries']);
    }
  }
}

final class PokemonCatalogAuthoringService {
  const PokemonCatalogAuthoringService();

  PokemonJsonDocument upsertEntry(
    PokemonJsonDocument catalog,
    Map<String, dynamic> entry,
  ) {
    _requireCatalog(catalog);
    final id = _entryId(entry);
    final entries = _validatedCatalogEntries(catalog.toJson()['entries']);
    var replaced = false;
    final next = <Map<String, Object?>>[
      for (final current in entries)
        if (_entryId(current) == id)
          (replaced = true, Map<String, Object?>.from(entry)).$2
        else
          current,
      if (!replaced) Map<String, Object?>.from(entry),
    ];
    return PokemonJsonDocument._(
      PokemonDocumentKind.catalog,
      {...catalog.toJson(), 'entries': next},
    );
  }

  PokemonJsonDocument deleteEntry(
    PokemonJsonDocument catalog, {
    required String entryId,
  }) {
    _requireCatalog(catalog);
    final entries = _validatedCatalogEntries(catalog.toJson()['entries']);
    if (!entries.any((entry) => _entryId(entry) == entryId)) {
      throw ArgumentError.value(entryId, 'entryId', 'is unknown');
    }
    return PokemonJsonDocument._(
      PokemonDocumentKind.catalog,
      {
        ...catalog.toJson(),
        'entries': [
          for (final entry in entries)
            if (_entryId(entry) != entryId) entry,
        ],
      },
    );
  }

  void _requireCatalog(PokemonJsonDocument document) {
    if (document.kind != PokemonDocumentKind.catalog) {
      throw ArgumentError.value(document.kind, 'catalog', 'must be a catalog');
    }
  }
}

enum PokemonDataIssueSeverity { warning, error }

final class PokemonDataIssue {
  const PokemonDataIssue({
    required this.code,
    required this.path,
    required this.message,
    this.severity = PokemonDataIssueSeverity.error,
  });

  final String code;
  final String path;
  final String message;
  final PokemonDataIssueSeverity severity;

  Map<String, Object?> toJson() => {
        'code': code,
        'path': path,
        'message': message,
        'severity': severity.name,
      };
}

final class PokemonDataValidationReport {
  PokemonDataValidationReport(Iterable<PokemonDataIssue> issues)
      : issues = List.unmodifiable(
          issues.toList()
            ..sort((left, right) {
              final path = left.path.compareTo(right.path);
              return path != 0 ? path : left.code.compareTo(right.code);
            }),
        );

  final List<PokemonDataIssue> issues;

  bool get canPublish => issues.every(
        (issue) => issue.severity != PokemonDataIssueSeverity.error,
      );

  Map<String, Object?> toJson() => {
        'canPublish': canPublish,
        'issues': [for (final issue in issues) issue.toJson()],
      };
}

final class PokemonDataBatchValidator {
  const PokemonDataBatchValidator();

  PokemonDataValidationReport validate({
    Iterable<PokemonJsonDocument> catalogs = const [],
    Iterable<PokemonJsonDocument> species = const [],
    Iterable<PokemonJsonDocument> learnsets = const [],
    Iterable<PokemonJsonDocument> evolutions = const [],
    Iterable<PokemonJsonDocument> media = const [],
  }) {
    final issues = <PokemonDataIssue>[];
    final speciesIds = _uniqueIdentities(species, 'species', issues);
    _uniqueIdentities(catalogs, 'catalog', issues);
    _uniqueIdentities(learnsets, 'learnset', issues);
    _uniqueIdentities(evolutions, 'evolution', issues);
    _uniqueIdentities(media, 'media', issues);

    for (final document in [...learnsets, ...evolutions, ...media]) {
      if (!speciesIds.contains(document.identity)) {
        issues.add(PokemonDataIssue(
          code: '${document.kind.name}.species_missing',
          path: '/${document.kind.name}/${document.identity}',
          message: 'The document references an unknown species.',
        ));
      }
    }
    for (final document in evolutions) {
      final entries = document.toJson()['evolutions'];
      if (entries is! List) continue;
      for (var index = 0; index < entries.length; index++) {
        final raw = entries[index];
        if (raw is! Map) continue;
        final target = raw['targetSpeciesId'];
        if (target is String && !speciesIds.contains(target)) {
          issues.add(PokemonDataIssue(
            code: 'evolution.target_missing',
            path: '/evolution/${document.identity}/evolutions/$index',
            message: 'Evolution target "$target" is unknown.',
          ));
        }
      }
    }
    for (final document in media) {
      final json = document.toJson();
      final defaultForm = json['defaultFormId'];
      final variants = json['variants'];
      if (defaultForm is String &&
          defaultForm.isNotEmpty &&
          (variants is! Map || !variants.containsKey(defaultForm))) {
        issues.add(PokemonDataIssue(
          code: 'media.default_form_missing',
          path: '/media/${document.identity}/defaultFormId',
          message: 'Default media form "$defaultForm" has no variant.',
        ));
      }
    }
    return PokemonDataValidationReport(issues);
  }
}

final class PokemonImportPreview {
  PokemonImportPreview({
    required this.sourceId,
    required this.requiresNetwork,
    required this.networkAuthorized,
    required this.canApply,
    required this.fingerprint,
    required this.documentCount,
  });

  final String sourceId;
  final bool requiresNetwork;
  final bool networkAuthorized;
  final bool canApply;
  final String fingerprint;
  final int documentCount;
  bool get sideEffectsApplied => false;

  Map<String, Object?> toJson() => {
        'sourceId': sourceId,
        'requiresNetwork': requiresNetwork,
        'networkAuthorized': networkAuthorized,
        'canApply': canApply,
        'fingerprint': fingerprint,
        'documentCount': documentCount,
        'sideEffectsApplied': sideEffectsApplied,
      };
}

final class PokemonImportPlanner {
  const PokemonImportPlanner();

  PokemonImportPreview preview({
    required String sourceId,
    required bool requiresNetwork,
    required bool allowNetwork,
    required Iterable<PokemonJsonDocument> documents,
  }) {
    final normalizedSource = sourceId.trim();
    if (normalizedSource.isEmpty || normalizedSource != sourceId) {
      throw ArgumentError.value(sourceId, 'sourceId', 'must be nonblank');
    }
    final payloads = [for (final document in documents) document.toJson()];
    return PokemonImportPreview(
      sourceId: sourceId,
      requiresNetwork: requiresNetwork,
      networkAuthorized: !requiresNetwork || allowNetwork,
      canApply: !requiresNetwork || allowNetwork,
      fingerprint: computeAuthoringJsonFingerprint(
        {'sourceId': sourceId, 'documents': payloads},
        logicalName: 'pokemon-import-preview.json',
      ),
      documentCount: payloads.length,
    );
  }
}

final class PokemonCatalogActions {
  const PokemonCatalogActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const [
      ('pokemon.catalog.write', PokemonDocumentKind.catalog, false),
      ('pokemon.species.write', PokemonDocumentKind.species, false),
      ('pokemon.species.delete', PokemonDocumentKind.species, true),
      ('pokemon.learnset.write', PokemonDocumentKind.learnset, false),
      ('pokemon.learnset.delete', PokemonDocumentKind.learnset, true),
      ('pokemon.evolution.write', PokemonDocumentKind.evolution, false),
      ('pokemon.evolution.delete', PokemonDocumentKind.evolution, true),
      ('pokemon.media.write', PokemonDocumentKind.media, false),
      ('pokemon.media.delete', PokemonDocumentKind.media, true),
    ])
      _descriptor(entry.$1, delete: entry.$3),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final actionId = context.request.actionId;
    final kind = _kindForAction(actionId);
    final deleting = actionId.endsWith('.delete');
    final parameters = context.request.parameters;
    final allowed = deleting
        ? const {'relativePath', 'resourceId', 'beforeBytesBase64'}
        : const {'relativePath', 'document', 'beforeBytesBase64'};
    final unknown = parameters.keys.where((key) => !allowed.contains(key));
    if (unknown.isNotEmpty) {
      throw ArgumentError.value(unknown.toList(), 'parameters', 'unknown keys');
    }
    final relativePath = _string(parameters, 'relativePath');
    _validateStoragePath(context.snapshot.manifest.pokemon, kind, relativePath);
    final beforeBytes = _optionalBytes(parameters['beforeBytesBase64']);
    final PokemonJsonDocument? document = deleting
        ? null
        : PokemonJsonDocument.fromJson(
            kind,
            _object(parameters, 'document'),
          );
    final resourceId =
        deleting ? _string(parameters, 'resourceId') : document!.identity;
    if (deleting && beforeBytes == null) {
      throw ArgumentError('Delete requires exact beforeBytesBase64.');
    }
    if (beforeBytes != null) {
      final raw = jsonDecode(utf8.decode(beforeBytes));
      if (raw is! Map) {
        throw const FormatException('Before bytes must contain a JSON object.');
      }
      final before = PokemonJsonDocument.fromJson(
        kind,
        Map<String, dynamic>.from(raw),
      );
      if (before.identity != resourceId) {
        throw const FormatException('Before document identity mismatch.');
      }
    }
    final afterBytes = document == null ? null : _encode(document.toJson());
    final resource = AuthoringResourceRef(
      kind: 'pokemonDocument',
      id: '${kind.name}:$resourceId',
      revision: beforeBytes == null
          ? null
          : computeAuthoringBytesFingerprint(
              beforeBytes,
              logicalName: relativePath,
            ),
    );
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: resource,
            storageKey: relativePath,
            beforeBytes: beforeBytes,
            afterBytes: afterBytes,
          ),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: deleting
                ? AuthoringDiffOperation.remove
                : beforeBytes == null
                    ? AuthoringDiffOperation.add
                    : AuthoringDiffOperation.replace,
            resource: resource,
            path: '/pokemon/${kind.name}/$resourceId',
            after: document?.toJson(),
          ),
        ]),
      ),
      preview: {
        'kind': kind.name,
        'resourceId': resourceId,
        'relativePath': relativePath,
        'deleting': deleting,
        'exactPreimageProvided': beforeBytes != null,
      },
    );
  }
}

AuthoringActionDescriptor _descriptor(String id, {required bool delete}) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: delete
          ? 'Delete one exact Pokemon data document'
          : 'Create or replace one validated Pokemon data document',
      inputSchemaId: 'pokemap.authoring/$id.input.v1',
      outputSchemaId: 'pokemap.authoring/$id.output.v1',
      riskLevel: delete ? AuthoringRiskLevel.high : AuthoringRiskLevel.medium,
      resourceKinds: const ['project', 'pokemonDocument'],
      capabilityIds: const ['authoring.gameData.pokemon'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

PokemonDocumentKind _kindForAction(String actionId) {
  for (final kind in PokemonDocumentKind.values) {
    if (actionId.startsWith('pokemon.${kind.name}.')) return kind;
  }
  throw ArgumentError.value(actionId, 'actionId', 'unsupported Pokemon action');
}

void _validateStoragePath(
  ProjectPokemonConfig pokemon,
  PokemonDocumentKind kind,
  String relativePath,
) {
  validateProjectRelativePath(relativePath);
  final valid = switch (kind) {
    PokemonDocumentKind.catalog =>
      pokemon.catalogFiles.values.contains(relativePath),
    PokemonDocumentKind.species =>
      relativePath.startsWith('${pokemon.speciesDir}/'),
    PokemonDocumentKind.learnset =>
      relativePath.startsWith('${pokemon.learnsetsDir}/'),
    PokemonDocumentKind.evolution =>
      relativePath.startsWith('${pokemon.evolutionsDir}/'),
    PokemonDocumentKind.media =>
      relativePath.startsWith('${pokemon.mediaDir}/'),
  };
  if (!valid || !relativePath.endsWith('.json')) {
    throw ArgumentError.value(
      relativePath,
      'relativePath',
      'is outside the configured Pokemon data family',
    );
  }
}

Map<String, dynamic> _object(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is! Map) throw ArgumentError.value(value, key, 'must be an object');
  return Map<String, dynamic>.from(value);
}

String _string(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw ArgumentError.value(value, key, 'must be a nonblank string');
  }
  return value;
}

List<int>? _optionalBytes(Object? value) {
  if (value == null) return null;
  if (value is! String || value.isEmpty) {
    throw ArgumentError.value(value, 'beforeBytesBase64', 'must be base64');
  }
  try {
    return base64Decode(value);
  } on FormatException {
    throw ArgumentError.value(value, 'beforeBytesBase64', 'must be base64');
  }
}

List<int> _encode(Map<String, Object?> json) =>
    utf8.encode('${const JsonEncoder.withIndent('  ').convert(json)}\n');

List<Map<String, Object?>> _validatedCatalogEntries(Object? raw) {
  if (raw is! List) {
    throw const FormatException('Catalog entries must be a list.');
  }
  final entries = <Map<String, Object?>>[];
  final ids = <String>{};
  for (final value in raw) {
    if (value is! Map) {
      throw const FormatException('Catalog entry must be an object.');
    }
    final entry = Map<String, Object?>.from(value);
    final id = _entryId(entry);
    if (!ids.add(id)) throw FormatException('Duplicate catalog entry "$id".');
    entries.add(entry);
  }
  return entries;
}

String _entryId(Map<Object?, Object?> entry) {
  final value = entry['id'] ?? entry['slug'];
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw const FormatException('Catalog entry requires a stable id or slug.');
  }
  return value;
}

Set<String> _uniqueIdentities(
  Iterable<PokemonJsonDocument> documents,
  String family,
  List<PokemonDataIssue> issues,
) {
  final ids = <String>{};
  for (final document in documents) {
    if (!ids.add(document.identity)) {
      issues.add(PokemonDataIssue(
        code: '$family.duplicate_id',
        path: '/$family/${document.identity}',
        message: 'Duplicate $family identity.',
      ));
    }
  }
  return ids;
}
```
## `packages/map_authoring/test/domains/gameplay/pokemon_catalog_authoring_test.dart`

```dart
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('Pokemon catalog authoring', () {
    test('generic catalog edits preserve unknown JSON fields losslessly', () {
      final catalog = PokemonJsonDocument.fromJson(
        PokemonDocumentKind.catalog,
        {
          'schemaVersion': 1,
          'kind': 'pokemon_catalog',
          'catalog': 'moves',
          'vendorExtension': {'kept': true},
          'entries': [
            {
              'id': 'tackle',
              'power': 40,
              'custom': ['legacy']
            },
          ],
        },
      );

      final updated = const PokemonCatalogAuthoringService().upsertEntry(
        catalog,
        {
          'id': 'ember',
          'power': 40,
          'custom': {'source': 'manual'}
        },
      );

      expect(updated.toJson()['vendorExtension'], {'kept': true});
      expect(
        (updated.toJson()['entries'] as List).first,
        {
          'id': 'tackle',
          'power': 40,
          'custom': ['legacy']
        },
      );
      expect(jsonDecode(jsonEncode(updated.toJson())), updated.toJson());
    });

    test('batch validation reports broken evolution and media references', () {
      final species = PokemonJsonDocument.fromJson(
        PokemonDocumentKind.species,
        {
          'id': 'sproutle',
          'forms': {'entries': []}
        },
      );
      final evolution = PokemonJsonDocument.fromJson(
        PokemonDocumentKind.evolution,
        {
          'speciesId': 'sproutle',
          'evolutions': [
            {'targetSpeciesId': 'missing', 'method': 'level'},
          ],
        },
      );
      final media = PokemonJsonDocument.fromJson(
        PokemonDocumentKind.media,
        {
          'speciesId': 'sproutle',
          'defaultFormId': 'base',
          'variants': <String, Object?>{},
        },
      );

      final report = const PokemonDataBatchValidator().validate(
        species: [species],
        evolutions: [evolution],
        media: [media],
      );

      expect(report.canPublish, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        containsAll({'evolution.target_missing', 'media.default_form_missing'}),
      );
    });

    test('network import remains blocked without an explicit opt-in', () {
      final blocked = const PokemonImportPlanner().preview(
        sourceId: 'pokeapi',
        requiresNetwork: true,
        allowNetwork: false,
        documents: const [],
      );
      final ready = const PokemonImportPlanner().preview(
        sourceId: 'pokeapi',
        requiresNetwork: true,
        allowNetwork: true,
        documents: const [],
      );

      expect(blocked.canApply, isFalse);
      expect(blocked.sideEffectsApplied, isFalse);
      expect(ready.canApply, isTrue);
      expect(ready.networkAuthorized, isTrue);
    });

    test('registered document actions cover all Pokemon file families', () {
      final actionIds = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();
      expect(
        actionIds,
        containsAll({
          'pokemon.catalog.write',
          'pokemon.species.write',
          'pokemon.species.delete',
          'pokemon.learnset.write',
          'pokemon.evolution.write',
          'pokemon.media.write',
        }),
      );
      expect(
        AuthoringResourceKindRegistry.canonicalMinimal()
            .resourceKinds
            .map((kind) => kind.id),
        contains('pokemonDocument'),
      );
    });
  });
}
```
