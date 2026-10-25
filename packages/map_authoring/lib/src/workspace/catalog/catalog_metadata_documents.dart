import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../support/authoring_fingerprint.dart';

typedef CatalogMetadataDocumentLookup = Future<CatalogDefinitionUnit?> Function(
    CatalogDefinitionKey key);

final class CatalogMetadataDocumentSelection {
  CatalogMetadataDocumentSelection._(this.project, this.documents, this.counts);

  final ProjectManifest project;
  final Map<String, Map<String, CatalogDefinitionUnit>> documents;
  final Map<String, int> counts;
}

abstract final class CatalogMetadataDocuments {
  static const fields = {
    'maps',
    'groups',
    'encounterTables',
    'dialogueFolders',
    'dialogues',
    'scripts',
    'scenarios',
    'cinematics',
    'presentationCinematics',
    'cinematicMediaAssets',
    'facts',
    'worldRules',
    'narrativeDiagnosticSuppressions',
    'scenes',
    'storylines',
    'shops',
    'badges',
    'trainers',
    'presentationPresets',
  };

  static CatalogDefinitionKey documentKey(String field, String id) =>
      CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
          jsonEncode(['metadataDocument', field, id]));

  static CatalogDefinitionKey fieldKey(String field) => CatalogDefinitionKey(
      CatalogDefinitionKind.workspaceState,
      jsonEncode(['metadataField', field]));

  static CatalogDefinitionKey definitionKey(String field, int position) =>
      CatalogDefinitionKey(CatalogDefinitionKind.catalogMetadata,
          jsonEncode(['projectDefinition', field, position]));

  static CatalogDefinitionKey trainerItemKey(String itemId) =>
      CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
          jsonEncode(['trainerItem', itemId]));

  static final doubleTrainersKey = CatalogDefinitionKey(
      CatalogDefinitionKind.workspaceState, jsonEncode(['doubleTrainers']));

  static CatalogDefinitionKey sceneDialogueKey(String dialogueId) =>
      CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
          jsonEncode(['sceneDialogue', dialogueId]));

  static List<CatalogDefinitionUnit> initialize(
      Iterable<CatalogDefinitionUnit> units) {
    final byField = <String, Map<int, CatalogDefinitionUnit>>{};
    for (final unit in units) {
      final location = _location(unit.key);
      if (location == null) continue;
      _definition(unit, location.$1, location.$2);
      final positions = byField.putIfAbsent(location.$1, () => {});
      if (positions.containsKey(location.$2)) _invalid('duplicate_position');
      positions[location.$2] = unit;
    }
    final result = <CatalogDefinitionUnit>[];
    final trainerFacets = <CatalogDefinitionKey, Set<String>>{};
    final sceneFacets = <CatalogDefinitionKey, Set<String>>{};
    for (final field in fields) {
      final positions = byField[field] ?? const <int, CatalogDefinitionUnit>{};
      final ids = <String>{};
      for (var position = 0; position < positions.length; position++) {
        final unit = positions[position];
        if (unit == null) _invalid('positions_not_contiguous');
        final id = _identity(_definition(unit, field, position), field);
        if (!ids.add(id)) _invalid('duplicate_identity');
        result.add(_row(field, id, position, unit));
        if (field == 'trainers') {
          for (final facet in _trainerFacets(unit)) {
            trainerFacets.putIfAbsent(facet, () => {}).add(id);
          }
        }
        if (field == 'scenes') {
          for (final facet in _sceneFacets(unit)) {
            sceneFacets.putIfAbsent(facet, () => {}).add(id);
          }
        }
      }
      result.add(_state(field, positions.length));
    }
    for (final entry in trainerFacets.entries) {
      result.add(_facetRow(entry.key, entry.value));
    }
    for (final entry in sceneFacets.entries) {
      result.add(_facetRow(entry.key, entry.value, idsField: 'sceneIds'));
    }
    return result;
  }

  static Future<Set<String>> readSceneIdsForDialogue({
    required CatalogSnapshot snapshot,
    required String dialogueId,
  }) async {
    _requireId(dialogueId);
    final count = _count(await snapshot.lookup(fieldKey('scenes')), 'scenes');
    if (count > snapshot.limits.maxDefinitions ||
        await snapshot.lookup(definitionKey('scenes', count)) != null) {
      _invalid('index_stale');
    }
    return Set.unmodifiable(_facetIds(
        await snapshot.lookup(sceneDialogueKey(dialogueId)),
        idsField: 'sceneIds'));
  }

  static Future<Set<String>> readTrainerIds({
    required CatalogSnapshot snapshot,
    String? itemId,
    bool doublesOnly = false,
  }) async {
    if ((itemId != null) == doublesOnly) {
      throw ArgumentError('Select an item or double trainers.');
    }
    if (itemId != null) _requireId(itemId);
    final state = await snapshot.lookup(fieldKey('trainers'));
    final count = _count(state, 'trainers');
    if (state!.payload['trainerReferencesVersion'] != 1 ||
        count > snapshot.limits.maxDefinitions ||
        await snapshot.lookup(definitionKey('trainers', count)) != null) {
      _invalid('preparation_required');
    }
    final key = itemId == null ? doubleTrainersKey : trainerItemKey(itemId);
    return Set.unmodifiable(_facetIds(await snapshot.lookup(key)));
  }

  static Future<CatalogMetadataDocumentSelection> readDocuments({
    required CatalogSnapshot snapshot,
    required ProjectManifest project,
    required Map<String, Set<String>> ids,
  }) async {
    final json = project.toJson();
    final documents = <String, Map<String, CatalogDefinitionUnit>>{};
    final counts = <String, int>{};
    for (final entry in ids.entries) {
      _requireField(entry.key);
      final count =
          _count(await snapshot.lookup(fieldKey(entry.key)), entry.key);
      if (count > snapshot.limits.maxDefinitions ||
          await snapshot.lookup(definitionKey(entry.key, count)) != null) {
        _invalid('index_stale');
      }
      counts[entry.key] = count;
      final selected = <String, CatalogDefinitionUnit>{};
      for (final id in entry.value) {
        _requireId(id);
        final row = await snapshot.lookup(documentKey(entry.key, id));
        if (row == null) continue;
        final position = _position(row, entry.key, id, count);
        final unit = await snapshot.lookup(definitionKey(entry.key, position));
        if (unit == null ||
            _identity(_definition(unit, entry.key, position), entry.key) !=
                id ||
            row.payload['fingerprint'] != _fingerprint(unit)) {
          _invalid('index_stale');
        }
        selected[id] = unit;
      }
      final ordered = selected.values.toList()
        ..sort((a, b) => (a.payload['position'] as int)
            .compareTo(b.payload['position'] as int));
      json[entry.key] = [
        for (final unit in ordered) (unit.payload['value'] as Map)['definition']
      ];
      documents[entry.key] = Map.unmodifiable(selected);
    }
    return CatalogMetadataDocumentSelection._(ProjectManifest.fromJson(json),
        Map.unmodifiable(documents), Map.unmodifiable(counts));
  }

  static Future<List<CatalogDefinitionUnit>> maintain({
    required CatalogMetadataDocumentLookup lookup,
    required Iterable<CatalogDefinitionUnit> upserts,
    Iterable<CatalogDefinitionKey> removals = const [],
  }) async {
    final changes = <String, List<CatalogDefinitionUnit>>{};
    final invalidated = <String>{};
    for (final key in removals) {
      final location = _location(key);
      if (location != null) invalidated.add(location.$1);
    }
    for (final unit in upserts) {
      final location = _location(unit.key);
      if (location == null) continue;
      _definition(unit, location.$1, location.$2);
      changes.putIfAbsent(location.$1, () => []).add(unit);
    }
    final result = <CatalogDefinitionUnit>[];
    for (final field in {...changes.keys, ...invalidated}) {
      final pending = <CatalogDefinitionUnit>[];
      final facetAdds = <CatalogDefinitionKey, Set<String>>{};
      final facetRemovals = <CatalogDefinitionKey, Set<String>>{};
      var valid = !invalidated.contains(field);
      var count = 0;
      if (valid) {
        try {
          count = _count(await lookup(fieldKey(field)), field);
        } on FormatException {
          valid = false;
        }
      }
      final ordered = changes[field] ?? [];
      ordered.sort((a, b) => (a.payload['position'] as int)
          .compareTo(b.payload['position'] as int));
      final changedIds = <String>{};
      final changedPositions = <int>{};
      for (final unit in ordered) {
        if (!valid) break;
        final position = unit.payload['position'] as int;
        final id = _identity(_definition(unit, field, position), field);
        if (!changedIds.add(id) || !changedPositions.add(position)) {
          _invalid('duplicate_mutation');
        }
        final before = await lookup(unit.key);
        final row = await lookup(documentKey(field, id));
        if (position < count) {
          if (before == null ||
              _identity(_definition(before, field, position), field) != id ||
              row == null ||
              _position(row, field, id, count) != position ||
              row.payload['fingerprint'] != _fingerprint(before)) {
            valid = false;
            break;
          }
        } else if (position == count && before == null && row == null) {
          count++;
        } else {
          valid = false;
          break;
        }
        pending.add(_row(field, id, position, unit));
        if (field == 'trainers' || field == 'scenes') {
          final previousFacets = before == null
              ? <CatalogDefinitionKey>{}
              : _documentFacets(before, field);
          final nextFacets = _documentFacets(unit, field);
          for (final facet in previousFacets.difference(nextFacets)) {
            facetRemovals.putIfAbsent(facet, () => {}).add(id);
          }
          for (final facet in nextFacets.difference(previousFacets)) {
            facetAdds.putIfAbsent(facet, () => {}).add(id);
          }
        }
      }
      if (valid) {
        result.addAll(pending);
        for (final facet in {...facetAdds.keys, ...facetRemovals.keys}) {
          final idsField = field == 'scenes' ? 'sceneIds' : 'trainerIds';
          final ids = _facetIds(await lookup(facet), idsField: idsField);
          final removed = facetRemovals[facet] ?? const <String>{};
          final added = facetAdds[facet] ?? const <String>{};
          if (!ids.containsAll(removed) || added.any(ids.contains)) {
            _invalid('index_stale');
          }
          ids.removeAll(removed);
          ids.addAll(added);
          result.add(_facetRow(facet, ids, idsField: idsField));
        }
      }
      result.add(_state(field, count, valid: valid));
    }
    return result;
  }

  static (String, int)? _location(CatalogDefinitionKey key) {
    if (key.kind != CatalogDefinitionKind.catalogMetadata) return null;
    Object? value;
    try {
      value = jsonDecode(key.id);
    } on FormatException {
      return null;
    }
    if (value is! List || value.isEmpty || value.first != 'projectDefinition') {
      return null;
    }
    if (value.length != 3 ||
        value[1] is! String ||
        value[2] is! int ||
        (value[2] as int) < 0) {
      _invalid('identity_invalid');
    }
    final field = value[1] as String;
    _requireField(field);
    if (key != definitionKey(field, value[2] as int)) {
      _invalid('identity_invalid');
    }
    return (field, value[2] as int);
  }

  static Map _definition(
      CatalogDefinitionUnit unit, String field, int position) {
    final value = unit.payload['value'];
    if (unit.key != definitionKey(field, position) ||
        unit.payload['section'] != r'$projectDefinition' ||
        unit.payload['id'] != unit.key.id ||
        unit.payload['position'] != position ||
        value is! Map ||
        value['field'] != field ||
        value['definition'] is! Map) {
      _invalid('identity_invalid');
    }
    final definition = value['definition'] as Map;
    _identity(definition, field);
    return definition;
  }

  static String _identity(Map definition, String field) {
    final id = definition[
        field == 'narrativeDiagnosticSuppressions' ? 'diagnosticId' : 'id'];
    if (id is! String) _invalid('identity_invalid');
    _requireId(id);
    return id;
  }

  static int _count(CatalogDefinitionUnit? unit, String field) {
    if (unit == null ||
        unit.key != fieldKey(field) ||
        unit.payload['schemaVersion'] != 1 ||
        unit.payload['field'] != field ||
        unit.payload['valid'] != true ||
        (field == 'trainers' &&
            unit.payload['trainerReferencesVersion'] != 1) ||
        (field == 'scenes' &&
            unit.payload['sceneDialogueReferencesVersion'] != 1) ||
        unit.payload['count'] is! int ||
        (unit.payload['count'] as int) < 0) {
      _invalid('preparation_required');
    }
    return unit.payload['count'] as int;
  }

  static int _position(
      CatalogDefinitionUnit row, String field, String id, int count) {
    final position = row.payload['position'];
    if (row.key != documentKey(field, id) ||
        row.payload['schemaVersion'] != 1 ||
        row.payload['field'] != field ||
        row.payload['documentId'] != id ||
        position is! int ||
        position < 0 ||
        position >= count ||
        row.payload['fingerprint'] is! String) {
      _invalid('index_stale');
    }
    return position;
  }

  static CatalogDefinitionUnit _row(
          String field, String id, int position, CatalogDefinitionUnit unit) =>
      CatalogDefinitionUnit(
        key: documentKey(field, id),
        payload: {
          'schemaVersion': 1,
          'field': field,
          'documentId': id,
          'position': position,
          'fingerprint': _fingerprint(unit)
        },
      );

  static CatalogDefinitionUnit _state(String field, int count,
          {bool valid = true}) =>
      CatalogDefinitionUnit(
        key: fieldKey(field),
        payload: {
          'schemaVersion': 1,
          'field': field,
          'count': count,
          'valid': valid,
          if (field == 'trainers') 'trainerReferencesVersion': 1,
          if (field == 'scenes') 'sceneDialogueReferencesVersion': 1,
        },
      );

  static Set<CatalogDefinitionKey> _trainerFacets(CatalogDefinitionUnit unit) {
    final position = unit.payload['position'] as int;
    final trainer = ProjectTrainerEntry.fromJson(
        Map<String, dynamic>.from(_definition(unit, 'trainers', position)));
    return {
      for (final id in trainer.battleItems.keys) trainerItemKey(id),
      for (final pokemon in trainer.team)
        if (pokemon.ballItemId case final String id) trainerItemKey(id),
      if (trainer.battleFormat == BattleFormat.doubles) doubleTrainersKey,
    };
  }

  static Set<CatalogDefinitionKey> _documentFacets(
          CatalogDefinitionUnit unit, String field) =>
      field == 'scenes' ? _sceneFacets(unit) : _trainerFacets(unit);

  static Set<CatalogDefinitionKey> _sceneFacets(CatalogDefinitionUnit unit) {
    final position = unit.payload['position'] as int;
    final scene = SceneAsset.fromJson(
        Map<String, dynamic>.from(_definition(unit, 'scenes', position)));
    return {
      for (final node in scene.graph.nodes)
        if (node.payload case final SceneYarnDialoguePayload payload)
          sceneDialogueKey(payload.dialogueId),
    };
  }

  static Set<String> _facetIds(CatalogDefinitionUnit? row,
      {String idsField = 'trainerIds'}) {
    if (row == null) return {};
    final ids = row.payload[idsField];
    if (row.payload['schemaVersion'] != 1 ||
        ids is! List ||
        ids.any((id) => id is! String || id.isEmpty || id.trim() != id) ||
        ids.toSet().length != ids.length) {
      _invalid('index_stale');
    }
    return ids.cast<String>().toSet();
  }

  static CatalogDefinitionUnit _facetRow(
          CatalogDefinitionKey key, Set<String> ids,
          {String idsField = 'trainerIds'}) =>
      CatalogDefinitionUnit(
        key: key,
        payload: {'schemaVersion': 1, idsField: ids.toList()..sort()},
      );

  static String _fingerprint(CatalogDefinitionUnit unit) =>
      computeAuthoringJsonFingerprint(unit.toJson(),
          logicalName: 'metadata-document');

  static void _requireField(String field) {
    if (!fields.contains(field)) _invalid('field_unsupported');
  }

  static void _requireId(String id) {
    if (id.isEmpty || id.trim() != id) _invalid('identity_invalid');
  }

  static Never _invalid(String code) =>
      throw FormatException('catalog.metadata_documents.$code');
}
