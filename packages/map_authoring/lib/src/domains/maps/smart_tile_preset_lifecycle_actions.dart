part of 'smart_tile_catalog_actions.dart';

AuthoringActionDescriptor _presetLifecycleDescriptor(String id,
        {required bool duplicate}) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: duplicate
          ? 'Duplicate a saved Smart Tile source into an independent draft'
          : 'Rename a Smart Tile preset or draft without publishing visual changes',
      inputSchemaId: 'pokemap.authoring.$id.input.v1',
      outputSchemaId: 'pokemap.authoring.smart_tile.mutation.v1',
      riskLevel: AuthoringRiskLevel.medium,
      resourceKinds: const ['project', 'smartTilePreset', 'smartTileDraft'],
      capabilityIds: const ['authoring.smart_tiles'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable
      ],
      extensions: {
        'inputSchema': {
          'type': 'object',
          'additionalProperties': false,
          'properties': {
            'presetId': {'type': 'string', 'minLength': 1},
            'draftId': {'type': 'string', 'minLength': 1},
            'name': {'type': 'string', 'minLength': 1},
            if (duplicate) 'newDraftId': {'type': 'string', 'minLength': 1},
            if (duplicate) 'targetPresetId': {'type': 'string', 'minLength': 1},
          },
          'required': [
            'name',
            if (duplicate) 'newDraftId',
            if (duplicate) 'targetPresetId'
          ],
          'oneOf': [
            {
              'required': ['presetId']
            },
            {
              'required': ['draftId']
            }
          ],
        },
      },
    );

SemanticParameters _presetLifecycleParameters(AuthoringPlanningContext planning,
    {bool duplicate = false}) {
  final fields = planning.request.parameters;
  final parameters = SemanticParameters({
    ...fields,
    if (fields['name'] case final String name) 'name': name.trim(),
  }, allowed: {
    'presetId',
    'draftId',
    'name',
    if (duplicate) 'newDraftId',
    if (duplicate) 'targetPresetId'
  });
  if (parameters.contains('presetId') == parameters.contains('draftId')) {
    throw semanticFailure('smart_tile.request_invalid',
        'Select exactly one saved preset or draft.');
  }
  return parameters;
}

AuthoringMutationDraft _renameSmartTilePreset(
    AuthoringPlanningContext planning) {
  final parameters = _presetLifecycleParameters(planning);
  final name = parameters.string('name');
  final presetId = parameters.optionalString('presetId');
  final draftId = parameters.optionalString('draftId');
  final catalog = planning.snapshot.manifest.smartTileCatalog;
  final preset = presetId == null
      ? null
      : _findById(catalog.presets, presetId, (item) => item.id);
  final draft = draftId == null
      ? null
      : _findById(catalog.drafts, draftId, (item) => item.id);
  if (preset == null && draft == null) {
    throw semanticFailure('smart_tile.lifecycle.unknown',
        'The selected Smart Tile source no longer exists.');
  }
  final projected = _catalogWith(catalog, presets: [
    for (final item in catalog.presets)
      if (item.id == presetId) item.copyWith(name: name) else item
  ], drafts: [
    for (final item in catalog.drafts)
      if (item.id == draftId ||
          (presetId != null &&
              (item.targetPresetId == presetId ||
                  item.sourcePresetId == presetId)))
        item.copyWith(name: name)
      else
        item
  ]);
  if (projected == catalog) {
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet.noChanges(),
      preview: {'operation': planning.request.actionId, 'unchanged': true},
    );
  }
  return _manifestDraft(planning,
      manifest: _nativeManifest(planning.snapshot.manifest, projected),
      operation: planning.request.actionId,
      path: presetId != null
          ? '/smartTileCatalog/presets/$presetId/name'
          : '/smartTileCatalog/drafts/$draftId/name',
      before: preset?.name ?? draft!.name,
      after: name);
}

AuthoringMutationDraft _duplicateSmartTilePreset(
    AuthoringPlanningContext planning) {
  final parameters = _presetLifecycleParameters(planning, duplicate: true);
  final catalog = planning.snapshot.manifest.smartTileCatalog;
  final newDraftId = parameters.string('newDraftId');
  final targetId = parameters.string('targetPresetId');
  if (catalog.drafts.any((draft) =>
          draft.id == newDraftId || draft.targetPresetId == targetId) ||
      catalog.presets.any((preset) => preset.id == targetId)) {
    throw semanticFailure('smart_tile.duplicate.identity_conflict',
        'The new draft or preset identity already exists.');
  }
  final draftId = parameters.optionalString('draftId');
  final presetId = parameters.optionalString('presetId');
  final saved = draftId == null
      ? null
      : _findById(catalog.drafts, draftId, (item) => item.id);
  final preset = presetId == null
      ? null
      : _findById(catalog.presets, presetId, (item) => item.id);
  if (saved == null && preset == null) {
    throw semanticFailure('smart_tile.lifecycle.unknown',
        'The selected Smart Tile source no longer exists.');
  }
  final source = saved == null
      ? _authoringDraftFromPreset(catalog, preset!)
      : _withReferencedDraftDependencies(catalog, saved);
  final copy = _independentSmartTileDraft(
      catalog, source, newDraftId, targetId, parameters.string('name'));
  final projected = _catalogWith(catalog, drafts: [...catalog.drafts, copy]);
  return _manifestDraft(planning,
      manifest: _nativeManifest(planning.snapshot.manifest, projected),
      operation: planning.request.actionId,
      path: '/smartTileCatalog/drafts/$newDraftId',
      after: copy.toJson(),
      preview: {
        'newDraftId': newDraftId,
        'targetPresetId': targetId,
        'sourceVersion': saved != null ? 'savedDraft' : 'published',
        'published': false
      });
}

ProjectSmartTileAuthoringDraft _authoringDraftFromPreset(
    ProjectSmartTileCatalog catalog, ProjectSmartTilePreset preset) {
  final presetJson = preset.toJson();
  final animationIds = _smartTileReferenceIds(presetJson, {'animationId'});
  final animations = catalog.animations
      .where((animation) => animationIds.contains(animation.id))
      .toList();
  final atlasIds = _smartTileReferenceIds(
      [presetJson, for (final animation in animations) animation.toJson()],
      {'atlasId'});
  final atlases =
      catalog.atlases.where((atlas) => atlasIds.contains(atlas.id)).toList();
  final materialIds = _smartTileReferenceIds(presetJson, {
    'defaultMaterialId',
    'allowedMaterialIds',
    'materialId',
    'centerMaterialId',
    ..._smartTileSignatureKeys
  });
  return ProjectSmartTileAuthoringDraft.fromJson({
    ...presetJson,
    'id': 'source-${preset.id}',
    'targetPresetId': preset.id,
    'sourcePresetId': preset.id,
    'lastStage': 'connections',
    'guideId': preset.topology == SmartTileTopology.cardinal4
        ? 'avelune-cardinal4-v1'
        : 'avelune-path20-v1',
    'sourceTilesetIds':
        atlases.map((atlas) => atlas.tilesetId).toSet().toList(),
    'atlases': [for (final atlas in atlases) atlas.toJson()],
    'primaryAtlasId': atlases.firstOrNull?.id,
    'materials': [
      for (final material in catalog.materials)
        if (materialIds.contains(material.id)) material.toJson()
    ],
    'animations': [for (final animation in animations) animation.toJson()],
  }..remove('status'));
}

const _smartTileSignatureKeys = {
  'northWestCorner',
  'northEdge',
  'northEastCorner',
  'eastEdge',
  'southEastCorner',
  'southEdge',
  'southWestCorner',
  'westEdge'
};

Set<String> _smartTileReferenceIds(Object? value, Set<String> keys) {
  final result = <String>{};
  void visit(Object? current, [String? key]) {
    if (current is Map) {
      for (final entry in current.entries) {
        visit(entry.value, entry.key as String);
      }
    } else if (current is List) {
      for (final item in current) {
        visit(item, key);
      }
    } else if (current is String && keys.contains(key)) {
      result.add(current);
    }
  }

  visit(value);
  return result;
}

ProjectSmartTileAuthoringDraft _withReferencedDraftDependencies(
    ProjectSmartTileCatalog catalog, ProjectSmartTileAuthoringDraft draft) {
  List<T> retain<T>(List<T> owned, List<T> published, Set<String> referenced,
      String Function(T) idOf) {
    final ownedIds = owned.map(idOf).toSet();
    return [
      ...owned,
      for (final item in published)
        if (referenced.contains(idOf(item)) && !ownedIds.contains(idOf(item)))
          item
    ];
  }

  final json = draft.toJson();
  final animations = retain(draft.animations, catalog.animations,
      _smartTileReferenceIds(json, {'animationId'}), (item) => item.id);
  return draft.copyWith(
      animations: animations,
      atlases: retain(
          draft.atlases,
          catalog.atlases,
          _smartTileReferenceIds(
              [json, for (final animation in animations) animation.toJson()],
              {'atlasId', 'primaryAtlasId'}),
          (item) => item.id),
      materials: retain(
          draft.materials,
          catalog.materials,
          _smartTileReferenceIds(json, {
            'defaultMaterialId',
            'allowedMaterialIds',
            'materialId',
            'centerMaterialId',
            ..._smartTileSignatureKeys
          }),
          (item) => item.id));
}

ProjectSmartTileAuthoringDraft _independentSmartTileDraft(
    ProjectSmartTileCatalog catalog,
    ProjectSmartTileAuthoringDraft source,
    String draftId,
    String targetId,
    String name) {
  Map<String, String> identities(
      Iterable<String> sourceIds, Iterable<String> existingIds) {
    final occupied = existingIds.toSet();
    return {
      for (final id in sourceIds)
        id: (() {
          final base = '$targetId-$id';
          var candidate = base;
          var suffix = 2;
          while (occupied.contains(candidate)) {
            candidate = '$base-${suffix++}';
          }
          occupied.add(candidate);
          return candidate;
        })()
    };
  }

  final atlases = identities(source.atlases.map((item) => item.id), [
    ...catalog.atlases.map((item) => item.id),
    for (final draft in catalog.drafts) ...draft.atlases.map((item) => item.id)
  ]);
  final materials = identities(source.materials.map((item) => item.id), [
    ...catalog.materials.map((item) => item.id),
    for (final draft in catalog.drafts)
      ...draft.materials.map((item) => item.id)
  ]);
  final animations = identities(source.animations.map((item) => item.id), [
    ...catalog.animations.map((item) => item.id),
    for (final draft in catalog.drafts)
      ...draft.animations.map((item) => item.id)
  ]);
  Object? remap(Object? value, [String? key]) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key as String: remap(entry.value, entry.key as String)
      };
    }
    if (value is List) return [for (final item in value) remap(item, key)];
    if (value is! String) return value;
    if (key == 'atlasId' || key == 'primaryAtlasId') {
      return atlases[value] ?? value;
    }
    if (key == 'animationId') return animations[value] ?? value;
    if ({
      'materialId',
      'centerMaterialId',
      'defaultMaterialId',
      'allowedMaterialIds',
      ..._smartTileSignatureKeys
    }.contains(key)) {
      return materials[value] ?? value;
    }
    return value;
  }

  final json = remap(source.toJson()) as Map<String, dynamic>;
  json['id'] = draftId;
  json['targetPresetId'] = targetId;
  json['sourcePresetId'] = null;
  json['name'] = name;
  for (final (key, replacements) in [
    ('atlases', atlases),
    ('materials', materials),
    ('animations', animations)
  ]) {
    for (final item in json[key] as List) {
      final entry = item as Map;
      entry['id'] = replacements[entry['id']]!;
    }
  }
  return ProjectSmartTileAuthoringDraft.fromJson(json);
}
