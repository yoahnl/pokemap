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
  ) {
    return PokemonJsonDocument._(
      kind,
      _canonicalSharedPokemonDocument(kind, json),
    );
  }

  final PokemonDocumentKind kind;
  final Map<String, Object?> _json;

  String get identity {
    if (kind == PokemonDocumentKind.catalog && !_json.containsKey('catalog')) {
      return 'items';
    }
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
    if (kind == PokemonDocumentKind.catalog && !_json.containsKey('catalog')) {
      decodeProjectItemCatalog(Map<String, dynamic>.from(_json));
      return;
    }
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

typedef PokemonDataIssueSeverity = PokemonCatalogDiagnosticSeverity;
typedef PokemonDataIssue = PokemonCatalogDiagnostic;
typedef PokemonDataValidationReport = PokemonCatalogCoherenceReport;

final class PokemonDataBatchValidator {
  const PokemonDataBatchValidator();

  PokemonDataValidationReport validate({
    required PokemonRulesetProfile ruleset,
    Iterable<PokemonJsonDocument> catalogs = const [],
    Iterable<PokemonJsonDocument> species = const [],
    Iterable<PokemonJsonDocument> learnsets = const [],
    Iterable<PokemonJsonDocument> evolutions = const [],
    Iterable<PokemonJsonDocument> media = const [],
  }) {
    return const PokemonCatalogCoherenceValidator().validate(
      PokemonCatalogCoherenceSnapshot(
        ruleset: ruleset,
        catalogs: _decodeDocuments(
          catalogs,
          PokemonCatalogFile.fromJson,
          'catalogs',
        ),
        species: _decodeDocuments(
          species,
          PokemonSpeciesFile.fromJson,
          'species',
        ),
        learnsets: _decodeDocuments(
          learnsets,
          PokemonLearnsetFile.fromJson,
          'learnsets',
        ),
        evolutions: _decodeDocuments(
          evolutions,
          PokemonEvolutionFile.fromJson,
          'evolutions',
        ),
        media: _decodeDocuments(
          media,
          PokemonMediaFile.fromJson,
          'media',
        ),
      ),
    );
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
    _descriptor('pokemon.documents.write', delete: false),
    _descriptor('pokemon.catalog.entries.add', delete: false),
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
    if (actionId == 'pokemon.documents.write') return _buildBatch(context);
    if (actionId == 'pokemon.catalog.entries.add') {
      return _buildCatalogAddition(context);
    }
    return _buildDocument(context, actionId, context.request.parameters);
  }

  AuthoringMutationDraft _buildCatalogAddition(
      AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    if (parameters.length != 2 ||
        parameters['entries'] is! List ||
        (parameters['entries'] as List).isEmpty ||
        (parameters['entries'] as List).length > 200) {
      throw const FormatException(
          'Expected a catalog relativePath and 1 to 200 new entries.');
    }
    final relativePath = _string(parameters, 'relativePath');
    _validateStoragePath(context.snapshot.manifest.pokemon,
        PokemonDocumentKind.catalog, relativePath);
    final identities = context.snapshot.resourceStorageKeys.entries
        .where((entry) => entry.value == relativePath)
        .map((entry) => entry.key)
        .toList();
    if (identities.length != 1) {
      throw const FormatException(
          'Catalog additions require one existing catalog in the enabled Pokemon inventory.');
    }
    final identity = identities.single;
    final before = context.snapshot.resourceBytes(identity);
    final document = _jsonCatalogBytes(before);
    final entries = _validatedCatalogEntries(document['entries']);
    final ids = entries.map((entry) => _entryId(entry)).toSet();
    for (final entry in _validatedCatalogEntries(parameters['entries'])) {
      if (!ids.add(_entryId(entry))) {
        throw const FormatException(
            'Catalog additions cannot replace an existing entry.');
      }
      entries.add(entry);
    }
    return _buildDocument(context, 'pokemon.catalog.write', {
      'relativePath': relativePath,
      'beforeBytesBase64': base64Encode(before),
      'document': {...document, 'entries': entries},
    });
  }

  AuthoringMutationDraft _buildBatch(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    final raw = parameters['documents'];
    if (parameters.length != 1 ||
        raw is! List ||
        raw.isEmpty ||
        raw.length > 200) {
      throw const FormatException(
          'Expected a batch of 1 to 200 typed Pokemon document writes.');
    }
    final drafts = <AuthoringMutationDraft>[];
    const allowedActions = {
      'pokemon.species.write',
      'pokemon.learnset.write',
      'pokemon.evolution.write',
      'pokemon.media.write',
    };
    for (final entry in raw) {
      if (entry is! Map ||
          entry.length != 2 ||
          !allowedActions.contains(entry['actionId']) ||
          entry['parameters'] is! Map) {
        throw const FormatException(
            'Batch members require a supported document write actionId and parameters.');
      }
      drafts.add(_buildDocument(context, entry['actionId'] as String,
          Map<String, Object?>.from(entry['parameters'] as Map)));
    }
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: drafts.expand((draft) => draft.changeSet.changes),
        diff: AuthoringDiff(
            drafts.expand((draft) => draft.changeSet.diff.entries)),
      ),
      preview: {
        'operation': 'pokemon.documents.write',
        'documentCount': drafts.length,
        'documents': [for (final draft in drafts) draft.preview]
      },
      referenceImpact: {
        'documents': [for (final draft in drafts) draft.referenceImpact]
      },
    );
  }

  AuthoringMutationDraft _buildDocument(AuthoringPlanningContext context,
      String actionId, Map<String, Object?> parameters) {
    final kind = _kindForAction(actionId);
    final deleting = actionId.endsWith('.delete');
    final allowed = deleting
        ? const {'relativePath', 'resourceId', 'beforeBytesBase64'}
        : const {'relativePath', 'document', 'beforeBytesBase64'};
    final unknown = parameters.keys.where((key) => !allowed.contains(key));
    if (unknown.isNotEmpty) {
      throw ArgumentError.value(unknown.toList(), 'parameters', 'unknown keys');
    }
    final relativePath = _string(parameters, 'relativePath');
    _validateStoragePath(context.snapshot.manifest.pokemon, kind, relativePath);
    final isItemCatalog = kind == PokemonDocumentKind.catalog &&
        relativePath == context.snapshot.manifest.pokemon.catalogFiles['items'];
    final beforeBytes = _optionalBytes(parameters['beforeBytesBase64']);
    final PokemonJsonDocument? document = deleting
        ? null
        : PokemonJsonDocument.fromJson(
            kind,
            _object(parameters, 'document'),
          );
    final resourceId =
        deleting ? _string(parameters, 'resourceId') : document!.identity;
    if (!deleting &&
        kind == PokemonDocumentKind.catalog &&
        ((resourceId == 'items') != isItemCatalog)) {
      throw const FormatException(
          'An item catalog must use its configured canonical path.');
    }
    if (deleting && beforeBytes == null) {
      throw ArgumentError('Delete requires exact beforeBytesBase64.');
    }
    if (beforeBytes != null) {
      final raw = jsonDecode(utf8.decode(beforeBytes));
      if (raw is! Map) {
        throw const FormatException('Before bytes must contain a JSON object.');
      }
      if (!isItemCatalog) {
        final before = PokemonJsonDocument.fromJson(
          kind,
          Map<String, dynamic>.from(raw),
        );
        if (before.identity != resourceId) {
          throw const FormatException('Before document identity mismatch.');
        }
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
          : id == 'pokemon.documents.write'
              ? 'Atomically write 1 to 200 typed species, learnset, evolution or media documents with exact preimages'
              : id == 'pokemon.catalog.entries.add'
                  ? 'Add 1 to 200 new entries to a canonical catalog while preserving every existing definition'
                  : id == 'pokemon.evolution.write'
                      ? 'Write evolution rules; conditional and catalog-only methods preserve source conditions and do not execute in gameplay'
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

Map<String, dynamic> _jsonCatalogBytes(List<int> bytes) =>
    Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);

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

Map<String, Object?> _canonicalSharedPokemonDocument(
  PokemonDocumentKind kind,
  Map<String, dynamic> json,
) =>
    switch (kind) {
      PokemonDocumentKind.catalog =>
        !json.containsKey('catalog') || json['catalog'] == 'items'
            ? encodeProjectItemCatalog(decodeProjectItemCatalog(json))
            : PokemonCatalogFile.fromJson(json).toJson(),
      PokemonDocumentKind.species => PokemonSpeciesFile.fromJson(json).toJson(),
      PokemonDocumentKind.learnset =>
        PokemonLearnsetFile.fromJson(json).toJson(),
      PokemonDocumentKind.evolution =>
        PokemonEvolutionFile.fromJson(json).toJson(),
      PokemonDocumentKind.media => PokemonMediaFile.fromJson(json).toJson(),
    };

List<PokemonCatalogDocument<T>> _decodeDocuments<T>(
  Iterable<PokemonJsonDocument> documents,
  T Function(Map<String, dynamic>) decode,
  String family,
) {
  final result = <PokemonCatalogDocument<T>>[];
  var index = 0;
  for (final document in documents) {
    result.add(
      PokemonCatalogDocument<T>(
        path: '$family/${document.identity}-$index.json',
        value: decode(Map<String, dynamic>.from(document.toJson())),
      ),
    );
    index += 1;
  }
  return result;
}
