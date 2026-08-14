part of 'smart_tile_catalog_actions.dart';

AuthoringActionDescriptor _descriptor(
  String id,
  String summary, {
  required List<String> resourceKinds,
  AuthoringRiskLevel risk = AuthoringRiskLevel.medium,
}) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'pokemap.authoring.$id.input.v1',
      outputSchemaId: 'pokemap.authoring.smart_tile.mutation.v1',
      riskLevel: risk,
      resourceKinds: resourceKinds,
      capabilityIds: const <String>['authoring.smart_tiles'],
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
      extensions: const <String, Object?>{
        'catalogFormatVersion': ProjectSmartTileCatalog.currentFormatVersion,
        'projectWidePreflight': true,
      },
    );

T _decode<T>(
  Map<String, Object?> json, {
  required String field,
  required T Function(Map<String, dynamic>) decode,
}) {
  try {
    return decode(Map<String, dynamic>.from(json));
  } on Object catch (error) {
    throw semanticFailure(
      'smart_tile.request_invalid',
      'Parameter "$field" is not a valid Smart Tile document.',
      details: <String, Object?>{
        'parameter': field,
        'validationType': error.runtimeType.toString(),
      },
    );
  }
}

ProjectManifest _nativeManifest(
  ProjectManifest manifest,
  ProjectSmartTileCatalog catalog,
) =>
    manifest.copyWith(
      smartTileCatalog: catalog,
    );

ProjectSmartTileCatalog _catalogWith(
  ProjectSmartTileCatalog catalog, {
  List<ProjectSmartTileAtlas>? atlases,
  List<ProjectSmartTileMaterial>? materials,
  List<ProjectSmartTileAnimation>? animations,
  List<ProjectSmartTilePreset>? presets,
  List<ProjectSmartTilePattern>? patterns,
  List<ProjectSmartTileAuthoringDraft>? drafts,
}) =>
    ProjectSmartTileCatalog(
      categories: catalog.categories,
      atlases: atlases ?? catalog.atlases,
      materials: materials ?? catalog.materials,
      animations: animations ?? catalog.animations,
      presets: presets ?? catalog.presets,
      patterns: patterns ?? catalog.patterns,
      drafts: drafts ?? catalog.drafts,
    );

List<T> _upsertById<T>(
  Iterable<T> values,
  T replacement,
  String Function(T) idOf,
) {
  final result = <T>[
    for (final value in values)
      if (idOf(value) != idOf(replacement)) value,
    replacement,
  ]..sort((left, right) => idOf(left).compareTo(idOf(right)));
  return List<T>.unmodifiable(result);
}

T? _findById<T>(Iterable<T> values, String id, String Function(T) idOf) {
  for (final value in values) {
    if (idOf(value) == id) return value;
  }
  return null;
}

void _validateDraftTarget(
  ProjectSmartTileCatalog catalog,
  ProjectSmartTileAuthoringDraft draft, {
  required String replacingDraftId,
}) {
  final competingDraft = catalog.drafts
      .where(
        (candidate) =>
            candidate.id != replacingDraftId &&
            candidate.targetPresetId == draft.targetPresetId,
      )
      .firstOrNull;
  if (competingDraft != null) {
    throw semanticFailure(
      'smart_tile.draft.target_in_use',
      'Another Smart Tile draft already targets this preset.',
      details: <String, Object?>{
        'draftId': draft.id,
        'targetPresetId': draft.targetPresetId,
        'competingDraftId': competingDraft.id,
      },
    );
  }
  final publishedTarget = _findById(
    catalog.presets,
    draft.targetPresetId,
    (item) => item.id,
  );
  if (publishedTarget != null && draft.sourcePresetId != draft.targetPresetId) {
    throw semanticFailure(
      'smart_tile.draft.target_conflict',
      'The draft target already identifies a published preset.',
      details: <String, Object?>{
        'draftId': draft.id,
        'targetPresetId': draft.targetPresetId,
        'sourcePresetId': draft.sourcePresetId,
      },
      remediation: const <String>[
        'Open the published preset for editing or choose a new preset id.',
      ],
    );
  }
}

void _validateSharedDraftDependencies(
  ProjectSmartTileCatalog catalog,
  ProjectSmartTileAuthoringDraft draft,
) {
  final excludedPresetIds = <String>{
    draft.targetPresetId,
    if (draft.sourcePresetId != null) draft.sourcePresetId!,
  };
  final otherPresets = catalog.presets
      .where((preset) => !excludedPresetIds.contains(preset.id))
      .toList(growable: false);
  final conflicts = <Map<String, Object?>>[];

  for (final incoming in draft.atlases) {
    final existing = _findById(catalog.atlases, incoming.id, (item) => item.id);
    if (existing == null || existing == incoming) continue;
    final presetIds = otherPresets
        .where((preset) => _presetReferencesAtlas(catalog, preset, incoming.id))
        .map((preset) => preset.id)
        .toList(growable: false);
    final patternIds = catalog.patterns
        .where(
            (pattern) => _patternReferencesAtlas(catalog, pattern, incoming.id))
        .map((pattern) => pattern.id)
        .toList(growable: false);
    if (presetIds.isNotEmpty || patternIds.isNotEmpty) {
      conflicts.add(<String, Object?>{
        'resourceKind': 'smartTileAtlas',
        'resourceId': incoming.id,
        'presetIds': presetIds,
        'patternIds': patternIds,
      });
    }
  }
  for (final incoming in draft.materials) {
    final existing =
        _findById(catalog.materials, incoming.id, (item) => item.id);
    if (existing == null || existing == incoming) continue;
    final presetIds = otherPresets
        .where((preset) => preset.allowedMaterialIds.contains(incoming.id))
        .map((preset) => preset.id)
        .toList(growable: false);
    if (presetIds.isNotEmpty) {
      conflicts.add(<String, Object?>{
        'resourceKind': 'smartTileMaterial',
        'resourceId': incoming.id,
        'presetIds': presetIds,
      });
    }
  }
  for (final incoming in draft.animations) {
    final existing =
        _findById(catalog.animations, incoming.id, (item) => item.id);
    if (existing == null || existing == incoming) continue;
    final presetIds = otherPresets
        .where((preset) => _presetReferencesAnimation(preset, incoming.id))
        .map((preset) => preset.id)
        .toList(growable: false);
    final patternIds = catalog.patterns
        .where((pattern) => _patternReferencesAnimation(pattern, incoming.id))
        .map((pattern) => pattern.id)
        .toList(growable: false);
    if (presetIds.isNotEmpty || patternIds.isNotEmpty) {
      conflicts.add(<String, Object?>{
        'resourceKind': 'smartTileAnimation',
        'resourceId': incoming.id,
        'presetIds': presetIds,
        'patternIds': patternIds,
      });
    }
  }

  if (conflicts.isNotEmpty) {
    throw semanticFailure(
      'smart_tile.draft.shared_dependency_conflict',
      'The draft changes resources shared by another published preset.',
      details: <String, Object?>{
        'draftId': draft.id,
        'conflicts': conflicts,
      },
      remediation: const <String>[
        'Duplicate the shared resource into this draft before publishing.',
      ],
    );
  }
}

bool _presetReferencesAtlas(
  ProjectSmartTileCatalog catalog,
  ProjectSmartTilePreset preset,
  String atlasId,
) {
  for (final source in _presetVisualSources(preset)) {
    if (source case SmartTileFrameSource(:final frame)) {
      if (frame.atlasId == atlasId) return true;
    }
    if (source case SmartTileAnimationSource(:final animationId)) {
      final animation =
          _findById(catalog.animations, animationId, (item) => item.id);
      if (animation?.frames.any((frame) => frame.frame.atlasId == atlasId) ??
          false) {
        return true;
      }
    }
  }
  return false;
}

bool _presetReferencesAnimation(
  ProjectSmartTilePreset preset,
  String animationId,
) =>
    _presetVisualSources(preset).any(
      (source) =>
          source is SmartTileAnimationSource &&
          source.animationId == animationId,
    );

bool _patternReferencesAtlas(
  ProjectSmartTileCatalog catalog,
  ProjectSmartTilePattern pattern,
  String atlasId,
) {
  for (final source in _patternVisualSources(pattern)) {
    if (source case SmartTileFrameSource(:final frame)) {
      if (frame.atlasId == atlasId) return true;
    }
    if (source case SmartTileAnimationSource(:final animationId)) {
      final animation =
          _findById(catalog.animations, animationId, (item) => item.id);
      if (animation?.frames.any((frame) => frame.frame.atlasId == atlasId) ??
          false) {
        return true;
      }
    }
  }
  return false;
}

bool _patternReferencesAnimation(
  ProjectSmartTilePattern pattern,
  String animationId,
) =>
    _patternVisualSources(pattern).any(
      (source) =>
          source is SmartTileAnimationSource &&
          source.animationId == animationId,
    );

Iterable<SmartTileVisualSource> _presetVisualSources(
  ProjectSmartTilePreset preset,
) sync* {
  for (final rule in preset.rules) {
    for (final candidate in rule.candidates) {
      for (final part in candidate.parts) {
        yield part.source;
      }
    }
  }
}

Iterable<SmartTileVisualSource> _patternVisualSources(
  ProjectSmartTilePattern pattern,
) sync* {
  for (final cell in pattern.cells) {
    for (final part in cell.parts) {
      yield part.source;
    }
  }
}
