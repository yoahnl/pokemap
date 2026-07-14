import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import 'border_studio_draft.dart';

/// In-memory authoring state for Border Studio.
///
/// This controller never writes to disk and never invokes the publication
/// transaction. Persisting the [ProjectManifest] returned by [saveDraft] or
/// [deleteSelectedDraft] remains the editor session's responsibility.
final class BorderStudioDraftController
    extends StateNotifier<BorderStudioDraftState> {
  BorderStudioDraftController({ProjectManifest? manifest})
      : super(BorderStudioDraftState()) {
    if (manifest != null) {
      loadFromManifest(manifest);
    }
  }

  ProjectManifest? _manifest;
  Object? _projectIdentity;
  Map<String, Map<String, String>> _loadedFingerprintsByBlueprintId =
      const <String, Map<String, String>>{};
  Map<String, Set<String>> _reanalyzedDivergenceIdsByBlueprintId =
      const <String, Set<String>>{};
  BorderDiagnosticsReport _externalDiagnostics =
      const BorderDiagnosticsReport.empty();

  void loadFromManifest(ProjectManifest? manifest) {
    _load(manifest);
  }

  void reloadFromManifest(ProjectManifest? manifest) {
    if (identical(manifest, _manifest)) {
      return;
    }
    _load(manifest, preferredBlueprintId: state.selectedBlueprintId);
  }

  /// Incorporates an editor-level manifest emission without discarding local
  /// unsaved work. Explicit user reloads should call [reloadFromManifest].
  void synchronizeFromManifest(
    ProjectManifest? manifest, {
    Object? projectIdentity,
  }) {
    if (projectIdentity != _projectIdentity) {
      _projectIdentity = projectIdentity;
      _load(manifest, preferredBlueprintId: state.selectedBlueprintId);
      return;
    }
    if (identical(manifest, _manifest)) {
      return;
    }
    final previousManifest = _manifest;
    final working = state.workingDraft;
    if (manifest == null || previousManifest == null) {
      _load(manifest, preferredBlueprintId: state.selectedBlueprintId);
      return;
    }

    _manifest = manifest;
    final previousFingerprints = _loadedFingerprintsByBlueprintId;
    final previousReanalyzed = _reanalyzedDivergenceIdsByBlueprintId;
    _loadedFingerprintsByBlueprintId = <String, Map<String, String>>{
      for (final record in manifest.borderCatalog.records)
        record.id: _publishedRevisionChanged(previousManifest, record) ||
                previousFingerprints[record.id] == null
            ? _primitiveFingerprints(record.draft.definition.primitives)
            : previousFingerprints[record.id]!,
      if (working != null &&
          manifest.borderCatalog.recordById(working.id) == null)
        working.id: state.loadedAssetFingerprints,
    };
    _reanalyzedDivergenceIdsByBlueprintId = <String, Set<String>>{
      for (final record in manifest.borderCatalog.records)
        record.id: _publishedRevisionChanged(previousManifest, record)
            ? const <String>{}
            : previousReanalyzed[record.id] ?? const <String>{},
      if (working != null &&
          manifest.borderCatalog.recordById(working.id) == null)
        working.id: state.reanalyzedDivergedPrimitiveIds,
    };

    final incoming =
        working == null ? null : manifest.borderCatalog.recordById(working.id);
    final selectedPublicationChanged = incoming != null &&
        _publishedRevisionChanged(previousManifest, incoming);
    if (working != null && state.isDirty && !selectedPublicationChanged) {
      _externalDiagnostics = const BorderDiagnosticsReport.empty();
      _setState(
        state.copyWith(
          catalogRecords: manifest.borderCatalog.records,
          selectedHasPublishedRevision: incoming?.latestPublished != null,
          diagnosticsAreCurrent: false,
          acknowledgedWarningCodes: const <String>{},
        ),
      );
      return;
    }

    final selected = incoming ??
        (manifest.borderCatalog.records.isEmpty
            ? null
            : manifest.borderCatalog.records.first);
    if (selected == null) {
      _setState(BorderStudioDraftState());
      return;
    }
    _selectRecord(selected, manifest.borderCatalog.records);
  }

  void selectBlueprint(String blueprintId) {
    final manifest = _requireManifest();
    final selected = manifest.borderCatalog.recordById(blueprintId);
    if (selected == null) {
      throw ArgumentError.value(
        blueprintId,
        'blueprintId',
        'does not exist in the loaded Border catalog',
      );
    }
    _selectRecord(selected, manifest.borderCatalog.records);
  }

  void createBlueprint({
    required String id,
    required String name,
    required BorderBlueprintTemplate template,
  }) {
    final manifest = _requireManifest();
    _requireNewBlueprintId(manifest.borderCatalog, id);
    final definition = BorderBlueprintDraftDefinition(
      name: name,
      previewSeed: _initialPreviewSeed(id),
      template: template,
      primitives: const <BorderPrimitiveDraft>[],
      defaults: _defaultGenerationParams(),
      sortOrder: manifest.borderCatalog.recordCount,
    );
    _loadedFingerprintsByBlueprintId = <String, Map<String, String>>{
      ..._loadedFingerprintsByBlueprintId,
      id: const <String, String>{},
    };
    _reanalyzedDivergenceIdsByBlueprintId = <String, Set<String>>{
      ..._reanalyzedDivergenceIdsByBlueprintId,
      id: const <String>{},
    };
    _externalDiagnostics = const BorderDiagnosticsReport.empty();
    _setState(
      BorderStudioDraftState(
        catalogRecords: manifest.borderCatalog.records,
        selectedBlueprintId: id,
        workingDraft: BorderStudioDraft(
          id: id,
          blueprint: BorderBlueprintDraft(
            baseRevision: 0,
            definition: definition,
          ),
        ),
        isDirty: true,
      ),
    );
  }

  void copyBlueprint({
    required String sourceBlueprintId,
    required String newBlueprintId,
    required String name,
  }) {
    final manifest = _requireManifest();
    _requireNewBlueprintId(manifest.borderCatalog, newBlueprintId);
    final selectedDraft = state.workingDraft;
    final source = selectedDraft?.id == sourceBlueprintId
        ? selectedDraft!.blueprint
        : manifest.borderCatalog.recordById(sourceBlueprintId)?.draft;
    if (source == null) {
      throw ArgumentError.value(
        sourceBlueprintId,
        'sourceBlueprintId',
        'does not exist in the loaded Border catalog',
      );
    }
    final definition = _copyDefinition(
      source.definition,
      name: name,
      previewSeed: _initialPreviewSeed(newBlueprintId),
    );
    final loadedFingerprints = _primitiveFingerprints(definition.primitives);
    _loadedFingerprintsByBlueprintId = <String, Map<String, String>>{
      ..._loadedFingerprintsByBlueprintId,
      newBlueprintId: loadedFingerprints,
    };
    _reanalyzedDivergenceIdsByBlueprintId = <String, Set<String>>{
      ..._reanalyzedDivergenceIdsByBlueprintId,
      newBlueprintId: const <String>{},
    };
    _externalDiagnostics = const BorderDiagnosticsReport.empty();
    _setState(
      BorderStudioDraftState(
        catalogRecords: manifest.borderCatalog.records,
        selectedBlueprintId: newBlueprintId,
        workingDraft: BorderStudioDraft(
          id: newBlueprintId,
          blueprint: BorderBlueprintDraft(
            baseRevision: 0,
            definition: definition,
          ),
        ),
        isDirty: true,
        loadedAssetFingerprints: loadedFingerprints,
      ),
    );
  }

  void renameBlueprint(String name) {
    _updateDefinition(
      (definition) => _copyDefinition(definition, name: name),
    );
  }

  void setTemplate(BorderBlueprintTemplate template) {
    final definition = _requireWorkingDraft().blueprint.definition;
    _validatePrimitiveRoles(definition.primitives, template);
    _updateDefinition(
      (current) => _copyDefinition(current, template: template),
    );
  }

  void setGenerationParams(BorderGenerationParams defaults) {
    _updateDefinition(
      (definition) => _copyDefinition(definition, defaults: defaults),
    );
  }

  void setGround(BorderGroundDraft? ground) {
    _updateDefinition(
      (definition) => _copyDefinition(
        definition,
        ground: ground,
        replaceGround: true,
      ),
    );
  }

  void replacePrimitives(List<BorderPrimitiveDraft> primitives) {
    final definition = _requireWorkingDraft().blueprint.definition;
    _validatePrimitiveRoles(primitives, definition.template);
    _validateUniquePrimitiveIds(primitives);
    _updateDefinition(
      (current) => _copyDefinition(current, primitives: primitives),
    );
  }

  /// Adds one primitive prepared from a normal project element.
  ///
  /// Asset IO stays in the dedicated application service; this controller
  /// only owns the draft mutation and its diagnostic invalidation.
  void addPreparedPrimitive(BorderPrimitiveDraft primitive) {
    final primitives = _requireWorkingDraft().blueprint.definition.primitives;
    if (primitives.any((candidate) => candidate.id == primitive.id)) {
      throw ArgumentError.value(
        primitive.id,
        'primitive.id',
        'already exists in the working draft',
      );
    }
    replacePrimitives(<BorderPrimitiveDraft>[...primitives, primitive]);
  }

  /// Replaces only the metrics produced by an explicit current-source read.
  ///
  /// Reanalysis must not become a back door for changing role, weight,
  /// transforms, or provenance. When pixels changed, the existing divergence
  /// machinery records that republishing is still required.
  void replacePrimitiveAfterReanalysis(BorderPrimitiveDraft primitive) {
    final primitives = _requireWorkingDraft().blueprint.definition.primitives;
    final index = primitives.indexWhere(
      (candidate) => candidate.id == primitive.id,
    );
    if (index < 0) {
      throw ArgumentError.value(
        primitive.id,
        'primitive.id',
        'does not exist in the working draft',
      );
    }
    final previous = primitives[index];
    if (previous.sourceElementId != primitive.sourceElementId ||
        previous.role != primitive.role ||
        previous.weight != primitive.weight ||
        previous.anchorPx != primitive.anchorPx ||
        previous.transforms != primitive.transforms) {
      throw ArgumentError.value(
        primitive,
        'primitive',
        'reanalysis may only replace current asset metrics',
      );
    }
    final updated = List<BorderPrimitiveDraft>.of(primitives);
    updated[index] = primitive;
    replacePrimitives(updated);
    if (state.sourceDivergedPrimitiveIds.contains(primitive.id)) {
      markPrimitiveReanalyzed(primitive.id);
    }
  }

  void removePrimitive(String primitiveId) {
    final primitives = _requireWorkingDraft().blueprint.definition.primitives;
    if (!primitives.any((primitive) => primitive.id == primitiveId)) {
      throw ArgumentError.value(
        primitiveId,
        'primitiveId',
        'does not exist in the working draft',
      );
    }
    replacePrimitives(<BorderPrimitiveDraft>[
      for (final primitive in primitives)
        if (primitive.id != primitiveId) primitive,
    ]);
  }

  void newPreviewVariation() {
    final working = _requireWorkingDraft();
    final currentSeed = working.blueprint.definition.previewSeed;
    _updateDefinition(
      (definition) => _copyDefinition(
        definition,
        previewSeed: _nextPreviewSeed(working.id, currentSeed),
      ),
    );
  }

  void setDiagnostics(BorderDiagnosticsReport diagnostics) {
    _externalDiagnostics = diagnostics;
    final warningCodes = <String>{
      for (final diagnostic in diagnostics.diagnostics)
        if (diagnostic.severity == BorderDiagnosticSeverity.warning)
          diagnostic.code,
    };
    _setState(
      state.copyWith(
        diagnosticsAreCurrent: true,
        acknowledgedWarningCodes:
            state.acknowledgedWarningCodes.where(warningCodes.contains).toSet(),
      ),
    );
  }

  void acknowledgeWarningCode(String code) {
    if (!state.warningCodes.contains(code)) {
      throw ArgumentError.value(
        code,
        'code',
        'is not a current Border warning code',
      );
    }
    _setState(
      state.copyWith(
        acknowledgedWarningCodes: <String>{
          ...state.acknowledgedWarningCodes,
          code,
        },
      ),
    );
  }

  void markPrimitiveReanalyzed(String primitiveId) {
    if (!state.sourceDivergedPrimitiveIds.contains(primitiveId)) {
      throw ArgumentError.value(
        primitiveId,
        'primitiveId',
        'does not have a detected source divergence',
      );
    }
    final reanalyzed = <String>{
      ...state.reanalyzedDivergedPrimitiveIds,
      primitiveId,
    };
    _rememberReanalyzedDivergences(
      _requireWorkingDraft().id,
      reanalyzed,
    );
    _externalDiagnostics = const BorderDiagnosticsReport.empty();
    _setState(
      state.copyWith(
        reanalyzedDivergedPrimitiveIds: reanalyzed,
        diagnosticsAreCurrent: false,
        acknowledgedWarningCodes: const <String>{},
      ),
    );
  }

  ProjectManifest saveDraft() {
    final manifest = _requireManifest();
    final working = _requireWorkingDraft();
    final existing = manifest.borderCatalog.recordById(working.id);
    final replacement = BorderBlueprintRecord(
      id: working.id,
      draft: working.blueprint,
      latestPublished: existing?.latestPublished,
      isDeprecated: existing?.isDeprecated ?? false,
    );
    final updatedCatalog = existing == null
        ? addBorderBlueprintRecord(manifest.borderCatalog, replacement)
        : replaceBorderBlueprintRecord(manifest.borderCatalog, replacement);
    final updated = replaceProjectBorderCatalog(manifest, updatedCatalog);
    _manifest = updated;
    _setState(
      state.copyWith(
        catalogRecords: updatedCatalog.records,
        selectedBlueprintId: replacement.id,
        workingDraft: BorderStudioDraft(
          id: replacement.id,
          blueprint: replacement.draft,
        ),
        isDirty: false,
        selectedHasPublishedRevision: replacement.latestPublished != null,
      ),
    );
    return updated;
  }

  ProjectManifest deleteSelectedDraft() {
    final manifest = _requireManifest();
    final working = _requireWorkingDraft();
    final existing = manifest.borderCatalog.recordById(working.id);
    if (existing == null) {
      _forgetBlueprintSessionState(working.id);
      _selectFirstRecord(manifest);
      return manifest;
    }
    if (existing.latestPublished != null) {
      throw StateError(
        'A published Border blueprint identity cannot be deleted',
      );
    }
    final updatedCatalog = removeBorderBlueprintRecord(
      manifest.borderCatalog,
      existing.id,
    );
    final updated = replaceProjectBorderCatalog(manifest, updatedCatalog);
    _forgetBlueprintSessionState(existing.id);
    _selectFirstRecord(updated);
    return updated;
  }

  void _forgetBlueprintSessionState(String blueprintId) {
    _loadedFingerprintsByBlueprintId = Map<String, Map<String, String>>.of(
      _loadedFingerprintsByBlueprintId,
    )..remove(blueprintId);
    _reanalyzedDivergenceIdsByBlueprintId = Map<String, Set<String>>.of(
      _reanalyzedDivergenceIdsByBlueprintId,
    )..remove(blueprintId);
  }

  void _selectFirstRecord(ProjectManifest manifest) {
    _manifest = manifest;
    _externalDiagnostics = const BorderDiagnosticsReport.empty();
    final records = manifest.borderCatalog.records;
    if (records.isEmpty) {
      _setState(BorderStudioDraftState());
      return;
    }
    _selectRecord(records.first, records);
  }

  void _load(
    ProjectManifest? manifest, {
    String? preferredBlueprintId,
  }) {
    _manifest = manifest;
    _externalDiagnostics = const BorderDiagnosticsReport.empty();
    final records =
        manifest?.borderCatalog.records ?? const <BorderBlueprintRecord>[];
    _loadedFingerprintsByBlueprintId = <String, Map<String, String>>{
      for (final record in records)
        record.id: _primitiveFingerprints(record.draft.definition.primitives),
    };
    _reanalyzedDivergenceIdsByBlueprintId = <String, Set<String>>{
      for (final record in records) record.id: const <String>{},
    };
    BorderBlueprintRecord? selected;
    if (preferredBlueprintId != null && manifest != null) {
      selected = manifest.borderCatalog.recordById(preferredBlueprintId);
    }
    selected ??= records.isEmpty ? null : records.first;
    if (selected == null) {
      _setState(BorderStudioDraftState(catalogRecords: records));
      return;
    }
    _selectRecord(selected, records);
  }

  void _selectRecord(
    BorderBlueprintRecord selected,
    List<BorderBlueprintRecord> records,
  ) {
    _externalDiagnostics = const BorderDiagnosticsReport.empty();
    final loadedFingerprints = _loadedFingerprintsByBlueprintId[selected.id] ??
        const <String, String>{};
    final divergence = _sourceDivergenceIds(
      selected.draft.definition.primitives,
      loadedFingerprints,
    );
    final reanalyzed = <String>{
      for (final id in _reanalyzedDivergenceIdsByBlueprintId[selected.id] ??
          const <String>{})
        if (divergence.contains(id)) id,
    };
    _setState(
      BorderStudioDraftState(
        catalogRecords: records,
        selectedBlueprintId: selected.id,
        workingDraft: BorderStudioDraft(
          id: selected.id,
          blueprint: selected.draft,
        ),
        selectedHasPublishedRevision: selected.latestPublished != null,
        loadedAssetFingerprints: loadedFingerprints,
        sourceDivergedPrimitiveIds: divergence,
        reanalyzedDivergedPrimitiveIds: reanalyzed,
      ),
    );
  }

  void _updateDefinition(
    BorderBlueprintDraftDefinition Function(
      BorderBlueprintDraftDefinition definition,
    ) update,
  ) {
    final working = _requireWorkingDraft();
    final previousFingerprints = _primitiveFingerprints(
      working.blueprint.definition.primitives,
    );
    final nextDefinition = update(working.blueprint.definition);
    final nextFingerprints = _primitiveFingerprints(nextDefinition.primitives);
    final divergence = _sourceDivergenceIds(
      nextDefinition.primitives,
      state.loadedAssetFingerprints,
    );
    final stillReanalyzed = <String>{
      for (final id in state.reanalyzedDivergedPrimitiveIds)
        if (divergence.contains(id) &&
            previousFingerprints[id] == nextFingerprints[id])
          id,
    };
    _rememberReanalyzedDivergences(working.id, stillReanalyzed);
    _externalDiagnostics = const BorderDiagnosticsReport.empty();
    _setState(
      state.copyWith(
        workingDraft: BorderStudioDraft(
          id: working.id,
          blueprint: BorderBlueprintDraft(
            baseRevision: working.blueprint.baseRevision,
            definition: nextDefinition,
          ),
        ),
        isDirty: true,
        diagnosticsAreCurrent: false,
        acknowledgedWarningCodes: const <String>{},
        sourceDivergedPrimitiveIds: divergence,
        reanalyzedDivergedPrimitiveIds: stillReanalyzed,
      ),
    );
  }

  void _setState(BorderStudioDraftState next) {
    state = next.copyWith(
      diagnostics: _composeDiagnostics(next),
      diagnosticsAreCurrent: next.workingDraft != null && _manifest != null,
    );
  }

  BorderDiagnosticsReport _composeDiagnostics(BorderStudioDraftState next) {
    final diagnostics = <BorderDiagnostic>[
      ..._automaticAuthoringDiagnostics(next).diagnostics,
      ..._externalDiagnostics.diagnostics,
    ];
    final primitiveById = <String, BorderPrimitiveDraft>{
      for (final primitive
          in next.workingDraft?.blueprint.definition.primitives ??
              const <BorderPrimitiveDraft>[])
        primitive.id: primitive,
    };
    final divergenceIds = next.sourceDivergedPrimitiveIds.toList(
      growable: false,
    )..sort();
    for (final primitiveId in divergenceIds) {
      final primitive = primitiveById[primitiveId];
      final loadedFingerprint = next.loadedAssetFingerprints[primitiveId];
      if (primitive == null || loadedFingerprint == null) {
        continue;
      }
      final wasReanalyzed =
          next.reanalyzedDivergedPrimitiveIds.contains(primitiveId);
      diagnostics.add(
        BorderDiagnostic(
          code: wasReanalyzed
              ? borderStudioSourceRepublishRequiredDiagnosticCode
              : borderStudioSourceReanalysisRequiredDiagnosticCode,
          severity: wasReanalyzed
              ? BorderDiagnosticSeverity.info
              : BorderDiagnosticSeverity.error,
          phase: BorderDiagnosticPhase.authoring,
          scope: BorderDiagnosticScope.primitive,
          blueprintId: next.selectedBlueprintId,
          parameters: <String, Object?>{
            'primitiveId': primitiveId,
            'loadedFingerprint': loadedFingerprint,
            'currentFingerprint': primitive.currentMetrics.assetFingerprint,
          },
          suggestedAction: wasReanalyzed
              ? 'border.action.republish_blueprint'
              : 'border.action.reanalyze_source_asset',
        ),
      );
    }
    return BorderDiagnosticsReport(diagnostics: diagnostics);
  }

  BorderDiagnosticsReport _automaticAuthoringDiagnostics(
    BorderStudioDraftState next,
  ) {
    final manifest = _manifest;
    final working = next.workingDraft;
    if (manifest == null || working == null) {
      return const BorderDiagnosticsReport.empty();
    }
    final existing = manifest.borderCatalog.recordById(working.id);
    return diagnoseBorderBlueprint(
      BorderBlueprintRecord(
        id: working.id,
        draft: working.blueprint,
        isDeprecated: existing?.isDeprecated ?? false,
      ),
      project: manifest,
      purpose: BorderBlueprintValidationPurpose.authoring,
      snapshotIntegrity: const <String, BorderVisualSnapshotIntegrity>{},
    );
  }

  ProjectManifest _requireManifest() {
    final manifest = _manifest;
    if (manifest == null) {
      throw StateError('Border Studio requires an open project');
    }
    return manifest;
  }

  BorderStudioDraft _requireWorkingDraft() {
    final working = state.workingDraft;
    if (working == null) {
      throw StateError('Border Studio has no selected working draft');
    }
    return working;
  }

  void _rememberReanalyzedDivergences(
    String blueprintId,
    Set<String> primitiveIds,
  ) {
    _reanalyzedDivergenceIdsByBlueprintId = <String, Set<String>>{
      ..._reanalyzedDivergenceIdsByBlueprintId,
      blueprintId: Set<String>.unmodifiable(primitiveIds),
    };
  }
}

bool _publishedRevisionChanged(
  ProjectManifest previousManifest,
  BorderBlueprintRecord incomingRecord,
) {
  final previousRevision = previousManifest.borderCatalog
      .recordById(incomingRecord.id)
      ?.latestPublished;
  return previousRevision != incomingRecord.latestPublished;
}

BorderBlueprintDraftDefinition _copyDefinition(
  BorderBlueprintDraftDefinition source, {
  String? name,
  BorderSignedInt64? previewSeed,
  BorderBlueprintTemplate? template,
  List<BorderPrimitiveDraft>? primitives,
  BorderGenerationParams? defaults,
  BorderGroundDraft? ground,
  bool replaceGround = false,
}) {
  return BorderBlueprintDraftDefinition(
    name: name ?? source.name,
    previewSeed: previewSeed ?? source.previewSeed,
    template: template ?? source.template,
    primitives: primitives ?? source.primitives,
    defaults: defaults ?? source.defaults,
    ground: replaceGround ? ground : source.ground,
    categoryId: source.categoryId,
    sortOrder: source.sortOrder,
  );
}

void _requireNewBlueprintId(ProjectBorderCatalog catalog, String id) {
  if (id.trim().isEmpty || id != id.trim()) {
    throw ArgumentError.value(
      id,
      'id',
      'must be nonblank and already trimmed',
    );
  }
  if (catalog.recordById(id) != null) {
    throw ArgumentError.value(id, 'id', 'already exists');
  }
}

void _validatePrimitiveRoles(
  List<BorderPrimitiveDraft> primitives,
  BorderBlueprintTemplate template,
) {
  final allowed = borderAllowedPrimitiveRolesForTemplate(template);
  for (final primitive in primitives) {
    if (!allowed.contains(primitive.role)) {
      throw ArgumentError.value(
        primitive.role,
        'primitives',
        'role is not supported by ${template.name}',
      );
    }
  }
}

void _validateUniquePrimitiveIds(List<BorderPrimitiveDraft> primitives) {
  final ids = <String>{};
  for (final primitive in primitives) {
    if (!ids.add(primitive.id)) {
      throw ArgumentError.value(
        primitive.id,
        'primitives',
        'primitive IDs must be unique',
      );
    }
  }
}

Map<String, String> _primitiveFingerprints(
  List<BorderPrimitiveDraft> primitives,
) {
  return Map<String, String>.unmodifiable(<String, String>{
    for (final primitive in primitives)
      primitive.id: primitive.currentMetrics.assetFingerprint,
  });
}

Set<String> _sourceDivergenceIds(
  List<BorderPrimitiveDraft> primitives,
  Map<String, String> loadedFingerprints,
) {
  return Set<String>.unmodifiable(<String>{
    for (final primitive in primitives)
      if (loadedFingerprints[primitive.id] case final loadedFingerprint?)
        if (loadedFingerprint != primitive.currentMetrics.assetFingerprint)
          primitive.id,
  });
}

BorderGenerationParams _defaultGenerationParams() {
  return BorderGenerationParams(
    irregularityPermille: 250,
    detailDensityPermille: 500,
    variationPermille: 300,
    maxOverlapPx: 4,
    gapTolerancePx: 1,
    depthRows: 1,
  );
}

BorderSignedInt64 _initialPreviewSeed(String blueprintId) {
  final rng = BorderDeterministicRng.fromComponents(
    <BorderRngKeyComponent>[
      const BorderRngKeyComponent.text('border-studio-preview-seed-v1'),
      BorderRngKeyComponent.text(blueprintId),
    ],
  );
  return BorderSignedInt64(_asSignedInt64(rng.nextUint64()));
}

BorderSignedInt64 _nextPreviewSeed(
  String blueprintId,
  BorderSignedInt64 current,
) {
  final rng = BorderDeterministicRng.fromComponents(
    <BorderRngKeyComponent>[
      const BorderRngKeyComponent.text('border-studio-preview-variation-v1'),
      BorderRngKeyComponent.text(blueprintId),
      BorderRngKeyComponent.signedInt64(current),
    ],
  );
  var next = BorderSignedInt64(_asSignedInt64(rng.nextUint64()));
  while (next == current) {
    next = BorderSignedInt64(_asSignedInt64(rng.nextUint64()));
  }
  return next;
}

BigInt _asSignedInt64(BigInt unsigned) {
  final signBit = BigInt.one << 63;
  return unsigned >= signBit ? unsigned - (BigInt.one << 64) : unsigned;
}
