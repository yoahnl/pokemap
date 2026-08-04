import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'smart_tile_connection_profile.dart';
import 'smart_tile_grid_detector.dart';
import 'smart_tile_guide.dart';
import 'smart_tile_guide_placement.dart';

enum SmartTileMaterialRemovalBlocker {
  defaultMaterial,
  activeMaterial,
  mappedMaterial,
}

/// Human-editable positions of a native Wang signature.
enum SmartTileAuthoringSlot {
  northWestCorner,
  northEdge,
  northEastCorner,
  eastEdge,
  southEastCorner,
  southEdge,
  southWestCorner,
  westEdge,
}

final class SmartTileMaterialInUseException implements Exception {
  const SmartTileMaterialInUseException(this.materialId, this.blocker);

  final String materialId;
  final SmartTileMaterialRemovalBlocker blocker;

  @override
  String toString() =>
      'SmartTileMaterialInUseException($materialId, ${blocker.name})';
}

final class SmartTileTransformProposal {
  SmartTileTransformProposal({
    required this.currentPolicy,
    required this.proposedPolicy,
    required Iterable<SmartTileTransformImpact> gainedForms,
    required Iterable<SmartTileTransformImpact> lostForms,
  })  : gainedForms = List<SmartTileTransformImpact>.unmodifiable(gainedForms),
        lostForms = List<SmartTileTransformImpact>.unmodifiable(lostForms);

  final SmartTileTransformPolicy currentPolicy;
  final SmartTileTransformPolicy proposedPolicy;
  final List<SmartTileTransformImpact> gainedForms;
  final List<SmartTileTransformImpact> lostForms;

  List<int> get gainedMasks =>
      List<int>.unmodifiable(gainedForms.map((impact) => impact.mask));
  List<int> get lostMasks =>
      List<int>.unmodifiable(lostForms.map((impact) => impact.mask));

  bool get hasChanges => currentPolicy != proposedPolicy;
}

final class SmartTileTransformImpact {
  const SmartTileTransformImpact({
    required this.mask,
    required this.sourceMask,
    required this.transform,
  });

  final int mask;
  final int sourceMask;
  final SmartTileSpriteTransform transform;
}

final class SmartTileAuthoringDraft {
  SmartTileAuthoringDraft({
    this.id = '',
    this.name = '',
    List<ProjectSmartTileMaterial> materials =
        const <ProjectSmartTileMaterial>[],
    this.defaultMaterialId = '',
    this.activeMaterialId = '',
    this.atlasId = '',
    this.atlasName = '',
    this.tilesetId = '',
    this.gridGeometry,
    this.usage,
    this.topology,
    this.templateHint = SmartTileTemplateHint.free,
    this.boundaryPolicy = SmartTileBoundaryPolicy.empty,
    this.coveragePolicy = SmartTileCoveragePolicy.complete,
    this.transformPolicy = const SmartTileTransformPolicy(),
    this.status = SmartTilePresetStatus.draft,
    Map<int, List<SmartTileCandidate>> mappings =
        const <int, List<SmartTileCandidate>>{},
    List<SmartTileRule> transitionCases = const <SmartTileRule>[],
    List<ProjectSmartTileAnimation> animations =
        const <ProjectSmartTileAnimation>[],
  })  : materials = List<ProjectSmartTileMaterial>.unmodifiable(materials),
        mappings = UnmodifiableMapView<int, List<SmartTileCandidate>>(
          <int, List<SmartTileCandidate>>{
            for (final entry in mappings.entries)
              entry.key: List<SmartTileCandidate>.unmodifiable(entry.value),
          },
        ),
        transitionCases = List<SmartTileRule>.unmodifiable(transitionCases),
        animations = List<ProjectSmartTileAnimation>.unmodifiable(animations);

  final String id;
  final String name;
  final List<ProjectSmartTileMaterial> materials;
  final String defaultMaterialId;
  final String activeMaterialId;
  final String atlasId;
  final String atlasName;
  final String tilesetId;
  final SmartTileGridGeometry? gridGeometry;
  final SmartTileUsage? usage;
  final SmartTileTopology? topology;
  final SmartTileTemplateHint templateHint;
  final SmartTileBoundaryPolicy boundaryPolicy;
  final SmartTileCoveragePolicy coveragePolicy;
  final SmartTileTransformPolicy transformPolicy;
  final SmartTilePresetStatus status;
  final Map<int, List<SmartTileCandidate>> mappings;
  final List<SmartTileRule> transitionCases;
  final List<ProjectSmartTileAnimation> animations;

  SmartTileAuthoringDraft copyWith({
    String? id,
    String? name,
    List<ProjectSmartTileMaterial>? materials,
    String? defaultMaterialId,
    String? activeMaterialId,
    String? atlasId,
    String? atlasName,
    String? tilesetId,
    SmartTileGridGeometry? gridGeometry,
    SmartTileUsage? usage,
    SmartTileTopology? topology,
    SmartTileTemplateHint? templateHint,
    SmartTileBoundaryPolicy? boundaryPolicy,
    SmartTileCoveragePolicy? coveragePolicy,
    SmartTileTransformPolicy? transformPolicy,
    SmartTilePresetStatus? status,
    Map<int, List<SmartTileCandidate>>? mappings,
    List<SmartTileRule>? transitionCases,
    List<ProjectSmartTileAnimation>? animations,
  }) {
    return SmartTileAuthoringDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      materials: materials ?? this.materials,
      defaultMaterialId: defaultMaterialId ?? this.defaultMaterialId,
      activeMaterialId: activeMaterialId ?? this.activeMaterialId,
      atlasId: atlasId ?? this.atlasId,
      atlasName: atlasName ?? this.atlasName,
      tilesetId: tilesetId ?? this.tilesetId,
      gridGeometry: gridGeometry ?? this.gridGeometry,
      usage: usage ?? this.usage,
      topology: topology ?? this.topology,
      templateHint: templateHint ?? this.templateHint,
      boundaryPolicy: boundaryPolicy ?? this.boundaryPolicy,
      coveragePolicy: coveragePolicy ?? this.coveragePolicy,
      transformPolicy: transformPolicy ?? this.transformPolicy,
      status: status ?? this.status,
      mappings: mappings ?? this.mappings,
      transitionCases: transitionCases ?? this.transitionCases,
      animations: animations ?? this.animations,
    );
  }
}

/// Pure in-memory authoring controller for one native Smart Tile preset.
///
/// The controller never reads or writes disk. It compiles the durable core
/// draft consumed by the Studio's canonical authoring adapter.
final class SmartTileAuthoringController {
  SmartTileAuthoringController({
    SmartTileAuthoringDraft? initialState,
  })  : _state = initialState ?? SmartTileAuthoringDraft(),
        _canonicalBase = null,
        _preservedCoverageProfile = null;

  factory SmartTileAuthoringController.blank() =>
      SmartTileAuthoringController();

  factory SmartTileAuthoringController.fromCanonicalDraft(
    ProjectSmartTileAuthoringDraft draft, {
    Iterable<ProjectSmartTileMaterial> catalogMaterials =
        const <ProjectSmartTileMaterial>[],
  }) {
    final controller = SmartTileAuthoringController.blank();
    controller.replaceFromCanonicalDraft(
      draft,
      catalogMaterials: catalogMaterials,
    );
    return controller;
  }

  SmartTileAuthoringDraft _state;
  ProjectSmartTileAuthoringDraft? _canonicalBase;
  SmartTileCoverageProfile? _preservedCoverageProfile;

  SmartTileAuthoringDraft get state => _state;

  /// Replaces local editable state with the canonical post-apply snapshot.
  void replaceFromCanonicalDraft(
    ProjectSmartTileAuthoringDraft draft, {
    Iterable<ProjectSmartTileMaterial> catalogMaterials =
        const <ProjectSmartTileMaterial>[],
  }) {
    final atlas = draft.atlases
        .where((candidate) => candidate.id == draft.primaryAtlasId)
        .firstOrNull;
    final materialsById = <String, ProjectSmartTileMaterial>{
      for (final material in catalogMaterials) material.id: material,
      for (final material in draft.materials) material.id: material,
    };
    final materials = <ProjectSmartTileMaterial>[
      for (final id in draft.allowedMaterialIds)
        if (materialsById[id] case final material?) material,
    ];
    final mappings = <int, List<SmartTileCandidate>>{};
    final transitionCases = <SmartTileRule>[];
    for (final rule in draft.rules) {
      final mask = smartTileMaskForSignature(
        rule.signature,
        topology: draft.topology,
      );
      final isBinaryTemplateRule = mask != null &&
          (rule.centerMatch.kind == SmartTileMatchKind.any ||
              draft.templateHint == SmartTileTemplateHint.simple &&
                  rule.centerMatch.kind == SmartTileMatchKind.material &&
                  rule.centerMatch.materialId == draft.defaultMaterialId);
      if (isBinaryTemplateRule) {
        mappings[mask] = rule.candidates;
      } else {
        transitionCases.add(rule);
      }
    }
    _canonicalBase = draft;
    _preservedCoverageProfile = draft.coverageProfile;
    _state = SmartTileAuthoringDraft(
      id: draft.targetPresetId,
      name: draft.name,
      materials: materials,
      defaultMaterialId: draft.defaultMaterialId ?? '',
      activeMaterialId: draft.defaultMaterialId ?? '',
      atlasId: atlas?.id ?? draft.primaryAtlasId ?? '',
      atlasName: atlas?.name ?? '',
      tilesetId: atlas?.tilesetId ?? draft.sourceTilesetIds.firstOrNull ?? '',
      gridGeometry: atlas == null ? null : _geometryFromAtlas(atlas),
      usage: draft.usage,
      topology: draft.topology,
      templateHint: draft.templateHint,
      boundaryPolicy: draft.boundaryPolicy,
      coveragePolicy: draft.coveragePolicy,
      transformPolicy: draft.transformPolicy,
      status: SmartTilePresetStatus.draft,
      mappings: mappings,
      transitionCases: transitionCases,
      animations: draft.animations,
    );
  }

  /// Projects incomplete local state into the durable core draft schema.
  ProjectSmartTileAuthoringDraft compileAuthoringDraft({
    required SmartTileAuthoringStage lastStage,
    String? guideId,
    bool clearGuide = false,
    List<String>? sourceTilesetIds,
  }) {
    final usage = _state.usage;
    if (usage == null) {
      throw StateError('Choose a Smart Tile usage before saving the draft.');
    }
    final base = _canonicalBase;
    final atlas = _tryCompileAtlas();
    final topology =
        _state.topology ?? base?.topology ?? SmartTileTopology.uniform;
    final rules = _compileRules(topology);
    final draft = (base ??
            ProjectSmartTileAuthoringDraft(
              id: _state.id,
              targetPresetId: _state.id,
              name: _state.name,
              usage: usage,
              lastStage: lastStage,
            ))
        .copyWith(
      targetPresetId: _state.id,
      name: _state.name,
      usage: usage,
      lastStage: lastStage,
      guideId: clearGuide ? null : guideId ?? base?.guideId,
      sourceTilesetIds: sourceTilesetIds ??
          (atlas == null
              ? base?.sourceTilesetIds ?? const <String>[]
              : <String>[atlas.tilesetId]),
      atlases: atlas == null
          ? base?.atlases ?? const <ProjectSmartTileAtlas>[]
          : <ProjectSmartTileAtlas>[atlas],
      primaryAtlasId: atlas?.id ?? base?.primaryAtlasId,
      materials: _state.materials,
      animations: _state.animations,
      defaultMaterialId: _state.defaultMaterialId.trim().isEmpty
          ? null
          : _state.defaultMaterialId,
      allowedMaterialIds:
          _state.materials.map((material) => material.id).toList(),
      topology: topology,
      templateHint: _state.templateHint,
      boundaryPolicy: _state.boundaryPolicy,
      coveragePolicy: _state.coveragePolicy,
      coverageProfile: _compileCoverageProfile(topology),
      transformPolicy: _state.transformPolicy,
      rules: rules,
    );
    _canonicalBase = draft;
    return draft;
  }

  void configureIdentity({
    required String id,
    required String name,
    String materialId = '',
    String materialName = '',
    String? connectionGroupId,
  }) {
    final normalizedMaterialId = materialId.trim();
    final normalizedMaterialName = materialName.trim();
    final initialMaterials =
        normalizedMaterialId.isEmpty || normalizedMaterialName.isEmpty
            ? const <ProjectSmartTileMaterial>[]
            : <ProjectSmartTileMaterial>[
                ProjectSmartTileMaterial(
                  id: normalizedMaterialId,
                  name: normalizedMaterialName,
                  connectionGroupId:
                      (connectionGroupId ?? normalizedMaterialId).trim(),
                ),
              ];
    _state = _state.copyWith(
      id: id.trim(),
      name: name.trim(),
      materials: initialMaterials,
      defaultMaterialId: initialMaterials.firstOrNull?.id ?? '',
      activeMaterialId: initialMaterials.firstOrNull?.id ?? '',
    );
  }

  void addMaterial(
    ProjectSmartTileMaterial material, {
    bool makeActive = true,
  }) {
    final materials = List<ProjectSmartTileMaterial>.from(_state.materials);
    final index =
        materials.indexWhere((candidate) => candidate.id == material.id);
    if (index < 0) {
      materials.add(material);
    } else {
      materials[index] = material;
    }
    final firstId = materials.first.id;
    _state = _state.copyWith(
      materials: materials,
      defaultMaterialId:
          _state.defaultMaterialId.isEmpty ? firstId : _state.defaultMaterialId,
      activeMaterialId: makeActive
          ? material.id
          : (_state.activeMaterialId.isEmpty
              ? firstId
              : _state.activeMaterialId),
    );
    _preservedCoverageProfile = null;
  }

  ProjectSmartTileMaterial createMaterial({required String name}) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Material name is required.');
    }
    final idBase = '${_state.id}-material-${_slugify(normalizedName)}';
    var id = idBase;
    var suffix = 2;
    final occupied = _state.materials.map((material) => material.id).toSet();
    while (occupied.contains(id)) {
      id = '$idBase-$suffix';
      suffix += 1;
    }
    final material = ProjectSmartTileMaterial(
      id: id,
      name: normalizedName,
      connectionGroupId: id,
      sortOrder: _state.materials.length,
    );
    addMaterial(material);
    return material;
  }

  void setDefaultMaterial(String materialId) {
    _requireMaterial(materialId);
    if (_state.defaultMaterialId != materialId) {
      _preservedCoverageProfile = null;
    }
    _state = _state.copyWith(defaultMaterialId: materialId);
  }

  void setActiveMaterial(String materialId) {
    _requireMaterial(materialId);
    _state = _state.copyWith(activeMaterialId: materialId);
  }

  SmartTileMaterialRemovalBlocker? materialRemovalBlocker(String materialId) {
    _requireMaterial(materialId);
    if (_state.defaultMaterialId == materialId) {
      return SmartTileMaterialRemovalBlocker.defaultMaterial;
    }
    if (_state.activeMaterialId == materialId) {
      return SmartTileMaterialRemovalBlocker.activeMaterial;
    }
    if (_state.transitionCases.any(
      (rule) => _ruleUsesMaterial(rule, materialId),
    )) {
      return SmartTileMaterialRemovalBlocker.mappedMaterial;
    }
    final base = _canonicalBase;
    if (base != null &&
        base.rules.any((rule) => _ruleUsesMaterial(rule, materialId))) {
      return SmartTileMaterialRemovalBlocker.mappedMaterial;
    }
    return null;
  }

  void removeMaterial(String materialId) {
    final blocker = materialRemovalBlocker(materialId);
    if (blocker != null) {
      throw SmartTileMaterialInUseException(materialId, blocker);
    }
    _state = _state.copyWith(
      materials: _state.materials
          .where((material) => material.id != materialId)
          .toList(),
    );
    _preservedCoverageProfile = null;
  }

  void configureConnections(
    SmartTileConnectionConfiguration configuration, {
    required bool clearMappings,
  }) {
    final nextCoveragePolicy =
        configuration.coveragePolicy ?? _state.coveragePolicy;
    final changesContract = _state.topology != configuration.topology ||
        _state.templateHint != configuration.templateHint;
    final changesCoverage = changesContract ||
        _state.boundaryPolicy != configuration.boundaryPolicy ||
        _state.coveragePolicy != nextCoveragePolicy;
    final hasAuthoredCases =
        _state.mappings.isNotEmpty || _state.transitionCases.isNotEmpty;
    if (changesContract && hasAuthoredCases && !clearMappings) {
      throw StateError(
        'Changing a Smart Tile connection contract requires mapping confirmation.',
      );
    }
    _state = _state.copyWith(
      topology: configuration.topology,
      templateHint: configuration.templateHint,
      boundaryPolicy: configuration.boundaryPolicy,
      coveragePolicy: nextCoveragePolicy,
      mappings: changesContract && clearMappings
          ? const <int, List<SmartTileCandidate>>{}
          : _state.mappings,
      transitionCases: changesContract && clearMappings
          ? const <SmartTileRule>[]
          : _state.transitionCases,
    );
    if (changesCoverage) _preservedCoverageProfile = null;
  }

  void setCoveragePolicy(SmartTileCoveragePolicy policy) {
    if (_state.coveragePolicy == policy) return;
    _state = _state.copyWith(coveragePolicy: policy);
    _preservedCoverageProfile = null;
  }

  void configureAtlas({
    required String atlasId,
    required String atlasName,
    required String tilesetId,
    required SmartTileGridGeometry geometry,
  }) {
    if (geometry.columns <= 0 || geometry.rows <= 0) {
      throw ArgumentError('The Smart Tile atlas grid must contain cells.');
    }
    _state = _state.copyWith(
      atlasId: atlasId.trim(),
      atlasName: atlasName.trim(),
      tilesetId: tilesetId.trim(),
      gridGeometry: geometry,
    );
  }

  void selectUsage(SmartTileUsage usage) {
    final (topology, template) = switch (usage) {
      SmartTileUsage.terrain => (
          SmartTileTopology.cardinal4,
          SmartTileTemplateHint.edge16,
        ),
      SmartTileUsage.path || SmartTileUsage.forestSurface => (
          SmartTileTopology.blob8,
          SmartTileTemplateHint.blob47,
        ),
    };
    _state = _state.copyWith(
      usage: usage,
      topology: topology,
      templateHint: template,
      coveragePolicy: usage == SmartTileUsage.terrain
          ? SmartTileCoveragePolicy.complete
          : SmartTileCoveragePolicy.sparse,
      mappings: const <int, List<SmartTileCandidate>>{},
      transitionCases: const <SmartTileRule>[],
    );
    _preservedCoverageProfile = null;
  }

  void selectTemplate(SmartTileTemplateHint template) {
    if (template == SmartTileTemplateHint.legacy20) {
      throw ArgumentError(
        'Legacy 20 is read through its historical adapter and is not a '
        'native authoring template.',
      );
    }
    final topology = _state.usage == SmartTileUsage.terrain &&
            template == SmartTileTemplateHint.edge16
        ? SmartTileTopology.cardinal4
        : smartTileTopologyForTemplate(template);
    _state = _state.copyWith(
      templateHint: template,
      topology: topology,
      mappings: const <int, List<SmartTileCandidate>>{},
      transitionCases: const <SmartTileRule>[],
    );
    _preservedCoverageProfile = null;
  }

  /// Prefills every cell from a validated guide without deleting manual work.
  ///
  /// Validation happens before building the replacement map, so a rejected
  /// placement cannot leave the draft half-configured.
  void applyGuidePlacement({
    required SmartTileGuideDefinition guide,
    required SmartTileGuidePlacementResult placement,
  }) {
    if (!placement.isValid) {
      throw StateError(
        'Le guide dépasse l’atlas pour les cellules '
        '${placement.outOfBoundsNumbers.join(', ')}.',
      );
    }
    if (placement.frames.length != guide.cells.length) {
      throw StateError('Le placement du guide est incomplet.');
    }
    final usage = _state.usage;
    if (usage == null || !guide.supportedUsages.contains(usage)) {
      throw StateError('Le guide sélectionné ne convient pas à cet usage.');
    }

    final mappings = <int, List<SmartTileCandidate>>{
      for (final entry in _state.mappings.entries)
        entry.key: List<SmartTileCandidate>.from(entry.value),
    };
    for (final placed in placement.frames) {
      final cell = placed.guideCell;
      final candidates =
          mappings.putIfAbsent(cell.mask, () => <SmartTileCandidate>[]);
      final candidate = SmartTileCandidate(
        id: 'guide_cell_${cell.number}',
        parts: <SmartTileVisualPart>[
          SmartTileVisualPart(
            source: SmartTileVisualSource.frame(
              frame: SmartTileFrameRef(
                atlasId: _state.atlasId,
                column: placed.column,
                row: placed.row,
              ),
            ),
          ),
        ],
      );
      final existingIndex = candidates.indexWhere(
        (existing) => existing.id == candidate.id,
      );
      if (existingIndex < 0) {
        candidates.add(candidate);
      } else {
        candidates[existingIndex] = candidate;
      }
    }

    if (mappings.keys.any((mask) => !_state.mappings.containsKey(mask))) {
      _preservedCoverageProfile = null;
    }

    _state = _state.copyWith(
      topology: guide.topology,
      templateHint: guide.templateHint,
      mappings: mappings,
    );
  }

  /// Replaces one visual candidate without deleting sibling variants.
  void replaceAtlasCandidate({
    required int mask,
    required int column,
    required int row,
    required String candidateId,
    SmartTileRenderChannel channel = SmartTileRenderChannel.ground,
  }) {
    _ensureAtlasCell(
      column: column,
      row: row,
      columnSpan: 1,
      rowSpan: 1,
    );
    final normalized = _normalizeMask(mask);
    final candidates = List<SmartTileCandidate>.from(
      _state.mappings[normalized] ?? const <SmartTileCandidate>[],
    );
    final candidateIndex =
        candidates.indexWhere((candidate) => candidate.id == candidateId);
    if (candidateIndex < 0) {
      throw ArgumentError('Unknown Smart Tile candidate "$candidateId".');
    }
    final current = candidates[candidateIndex];
    final replacement = SmartTileVisualPart(
      source: SmartTileVisualSource.frame(
        frame: SmartTileFrameRef(
          atlasId: _state.atlasId,
          column: column,
          row: row,
        ),
      ),
      channel: channel,
    );
    final parts = List<SmartTileVisualPart>.from(current.parts);
    final partIndex = parts.indexWhere((part) => part.channel == channel);
    if (partIndex < 0) {
      parts.add(replacement);
    } else {
      final previous = parts[partIndex];
      parts[partIndex] = replacement.copyWith(
        transform: previous.transform,
        frameSampling: previous.frameSampling,
        offsetUnit: previous.offsetUnit,
        offsetX: previous.offsetX,
        offsetY: previous.offsetY,
        footprintWidth: previous.footprintWidth,
        footprintHeight: previous.footprintHeight,
        anchorX: previous.anchorX,
        anchorY: previous.anchorY,
        drawOrder: previous.drawOrder,
      );
    }
    candidates[candidateIndex] = current.copyWith(
      parts: parts,
    );
    _state = _state.copyWith(
      mappings: <int, List<SmartTileCandidate>>{
        ..._state.mappings,
        normalized: candidates,
      },
    );
  }

  void setStatus(SmartTilePresetStatus status) {
    _state = _state.copyWith(status: status);
  }

  List<SmartTileSpriteTransform> get allowedTransforms =>
      smartTileAllowedTransforms(_state.transformPolicy);

  void setTransformPolicy(SmartTileTransformPolicy policy) {
    _state = _state.copyWith(transformPolicy: policy);
  }

  SmartTileTransformProposal proposeTransformPolicy(
    SmartTileTransformPolicy policy,
  ) {
    final topology = _state.topology;
    if (topology == null) {
      throw StateError('Choose a Smart Tile topology before transforms.');
    }
    final universe = <int>{
      ..._theoreticalMasksForPolicy(
        _state.transformPolicy,
        topology: topology,
      ),
      ..._theoreticalMasksForPolicy(policy, topology: topology),
    };
    final current = _resolvedFormsForPolicy(
      _state.transformPolicy,
      topology: topology,
      masks: universe,
    );
    final proposed = _resolvedFormsForPolicy(
      policy,
      topology: topology,
      masks: universe,
    );
    final gainedMasks = proposed.keys.toSet().difference(current.keys.toSet())
      ..retainAll(universe);
    final lostMasks = current.keys.toSet().difference(proposed.keys.toSet())
      ..retainAll(universe);
    final gained = gainedMasks.map((mask) => proposed[mask]!).toList()
      ..sort((left, right) => left.mask.compareTo(right.mask));
    final lost = lostMasks.map((mask) => current[mask]!).toList()
      ..sort((left, right) => left.mask.compareTo(right.mask));
    return SmartTileTransformProposal(
      currentPolicy: _state.transformPolicy,
      proposedPolicy: policy,
      gainedForms: gained,
      lostForms: lost,
    );
  }

  void clearMappings() {
    if (_state.mappings.isNotEmpty || _state.transitionCases.isNotEmpty) {
      _preservedCoverageProfile = null;
    }
    _state = _state.copyWith(
      mappings: const <int, List<SmartTileCandidate>>{},
      transitionCases: const <SmartTileRule>[],
    );
  }

  SmartTileRule createTransitionCase({
    SmartTileSlotMatch? centerMatch,
  }) {
    final selectedCenter = centerMatch ??
        SmartTileSlotMatch.material(
          _state.activeMaterialId.isNotEmpty
              ? _state.activeMaterialId
              : _state.defaultMaterialId,
        );
    _validateCenterMatch(selectedCenter);
    final occupied = _state.transitionCases.map((rule) => rule.id).toSet();
    var sequence = _state.transitionCases.length + 1;
    var id = 'transition_case_$sequence';
    while (occupied.contains(id)) {
      sequence += 1;
      id = 'transition_case_$sequence';
    }
    final rule = SmartTileRule(
      id: id,
      centerMatch: selectedCenter,
    );
    _state = _state.copyWith(
      transitionCases: <SmartTileRule>[..._state.transitionCases, rule],
    );
    _preservedCoverageProfile = null;
    return rule;
  }

  void setTransitionCaseCenter({
    required String caseId,
    required SmartTileSlotMatch match,
  }) {
    _validateCenterMatch(match);
    _replaceTransitionCase(
      caseId,
      _requireTransitionCase(caseId).copyWith(centerMatch: match),
    );
  }

  void setTransitionCaseSlot({
    required String caseId,
    required SmartTileAuthoringSlot slot,
    required SmartTileSlotMatch match,
  }) {
    _validateSlotMatch(match);
    final rule = _requireTransitionCase(caseId);
    final signature = switch (slot) {
      SmartTileAuthoringSlot.northWestCorner =>
        rule.signature.copyWith(northWestCorner: match),
      SmartTileAuthoringSlot.northEdge =>
        rule.signature.copyWith(northEdge: match),
      SmartTileAuthoringSlot.northEastCorner =>
        rule.signature.copyWith(northEastCorner: match),
      SmartTileAuthoringSlot.eastEdge =>
        rule.signature.copyWith(eastEdge: match),
      SmartTileAuthoringSlot.southEastCorner =>
        rule.signature.copyWith(southEastCorner: match),
      SmartTileAuthoringSlot.southEdge =>
        rule.signature.copyWith(southEdge: match),
      SmartTileAuthoringSlot.southWestCorner =>
        rule.signature.copyWith(southWestCorner: match),
      SmartTileAuthoringSlot.westEdge =>
        rule.signature.copyWith(westEdge: match),
    };
    _replaceTransitionCase(caseId, rule.copyWith(signature: signature));
  }

  void removeTransitionCase(String caseId) {
    _requireTransitionCase(caseId);
    _state = _state.copyWith(
      transitionCases:
          _state.transitionCases.where((rule) => rule.id != caseId).toList(),
    );
    _preservedCoverageProfile = null;
  }

  void addTransitionCaseAtlasVariant({
    required String caseId,
    required int column,
    required int row,
    required String candidateId,
    int weight = 1,
    SmartTileRenderChannel channel = SmartTileRenderChannel.ground,
    int columnSpan = 1,
    int rowSpan = 1,
  }) {
    _requireCandidateWeight(weight);
    _ensureAtlasCell(
      column: column,
      row: row,
      columnSpan: columnSpan,
      rowSpan: rowSpan,
    );
    final rule = _requireTransitionCase(caseId);
    final candidates = List<SmartTileCandidate>.from(rule.candidates);
    final candidate = SmartTileCandidate(
      id: candidateId,
      weight: weight,
      parts: <SmartTileVisualPart>[
        SmartTileVisualPart(
          source: SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(
              atlasId: _state.atlasId,
              column: column,
              row: row,
              columnSpan: columnSpan,
              rowSpan: rowSpan,
            ),
          ),
          channel: channel,
        ),
      ],
    );
    final index = candidates.indexWhere((item) => item.id == candidateId);
    if (index < 0) {
      candidates.add(candidate);
    } else {
      candidates[index] = candidate;
    }
    _replaceTransitionCase(
      caseId,
      rule.copyWith(candidates: candidates),
    );
  }

  void replaceTransitionCaseAtlasCandidate({
    required String caseId,
    required int column,
    required int row,
    required String candidateId,
    SmartTileRenderChannel channel = SmartTileRenderChannel.ground,
  }) {
    _ensureAtlasCell(
      column: column,
      row: row,
      columnSpan: 1,
      rowSpan: 1,
    );
    final rule = _requireTransitionCase(caseId);
    final candidates = List<SmartTileCandidate>.from(rule.candidates);
    final candidateIndex =
        candidates.indexWhere((candidate) => candidate.id == candidateId);
    if (candidateIndex < 0) {
      throw ArgumentError('Unknown Smart Tile candidate "$candidateId".');
    }
    final current = candidates[candidateIndex];
    final replacement = SmartTileVisualPart(
      source: SmartTileVisualSource.frame(
        frame: SmartTileFrameRef(
          atlasId: _state.atlasId,
          column: column,
          row: row,
        ),
      ),
      channel: channel,
    );
    final parts = List<SmartTileVisualPart>.from(current.parts);
    final partIndex = parts.indexWhere((part) => part.channel == channel);
    if (partIndex < 0) {
      parts.add(replacement);
    } else {
      final previous = parts[partIndex];
      parts[partIndex] = replacement.copyWith(
        transform: previous.transform,
        frameSampling: previous.frameSampling,
        offsetUnit: previous.offsetUnit,
        offsetX: previous.offsetX,
        offsetY: previous.offsetY,
        footprintWidth: previous.footprintWidth,
        footprintHeight: previous.footprintHeight,
        anchorX: previous.anchorX,
        anchorY: previous.anchorY,
        drawOrder: previous.drawOrder,
      );
    }
    candidates[candidateIndex] = current.copyWith(parts: parts);
    _replaceTransitionCase(
      caseId,
      rule.copyWith(candidates: candidates),
    );
  }

  void addTransitionCaseAnimationVariant({
    required String caseId,
    required String animationId,
    required String candidateId,
    int weight = 1,
    SmartTileRenderChannel channel = SmartTileRenderChannel.ground,
  }) {
    _requireCandidateWeight(weight);
    if (!_state.animations.any((item) => item.id == animationId)) {
      throw ArgumentError('Unknown Smart Tile animation "$animationId".');
    }
    final rule = _requireTransitionCase(caseId);
    final candidates = List<SmartTileCandidate>.from(rule.candidates);
    final candidate = SmartTileCandidate(
      id: candidateId,
      weight: weight,
      parts: <SmartTileVisualPart>[
        SmartTileVisualPart(
          source: SmartTileVisualSource.animation(animationId: animationId),
          channel: channel,
        ),
      ],
    );
    final index = candidates.indexWhere((item) => item.id == candidateId);
    if (index < 0) {
      candidates.add(candidate);
    } else {
      candidates[index] = candidate;
    }
    _replaceTransitionCase(
      caseId,
      rule.copyWith(candidates: candidates),
    );
  }

  void updateTransitionCaseCandidateWeight({
    required String caseId,
    required String candidateId,
    required int weight,
  }) {
    _requireCandidateWeight(weight);
    final rule = _requireTransitionCase(caseId);
    final candidates = List<SmartTileCandidate>.from(rule.candidates);
    final index = candidates.indexWhere((item) => item.id == candidateId);
    if (index < 0) {
      throw ArgumentError('Unknown Smart Tile candidate "$candidateId".');
    }
    candidates[index] = candidates[index].copyWith(weight: weight);
    _replaceTransitionCase(
      caseId,
      rule.copyWith(candidates: candidates),
    );
  }

  void removeTransitionCaseCandidate({
    required String caseId,
    required String candidateId,
  }) {
    final rule = _requireTransitionCase(caseId);
    final candidates = List<SmartTileCandidate>.from(rule.candidates);
    final index = candidates.indexWhere((item) => item.id == candidateId);
    if (index < 0) {
      throw ArgumentError('Unknown Smart Tile candidate "$candidateId".');
    }
    candidates.removeAt(index);
    _replaceTransitionCase(
      caseId,
      rule.copyWith(candidates: candidates),
    );
  }

  void reorderTransitionCaseCandidate({
    required String caseId,
    required String candidateId,
    required int newIndex,
  }) {
    final rule = _requireTransitionCase(caseId);
    final candidates = List<SmartTileCandidate>.from(rule.candidates);
    final currentIndex =
        candidates.indexWhere((candidate) => candidate.id == candidateId);
    if (currentIndex < 0) {
      throw ArgumentError('Unknown Smart Tile candidate "$candidateId".');
    }
    if (newIndex < 0 || newIndex >= candidates.length) {
      throw RangeError.range(newIndex, 0, candidates.length - 1, 'newIndex');
    }
    final candidate = candidates.removeAt(currentIndex);
    candidates.insert(newIndex, candidate);
    _replaceTransitionCase(
      caseId,
      rule.copyWith(candidates: candidates),
    );
  }

  void addAtlasVariant({
    required int mask,
    required int column,
    required int row,
    required String candidateId,
    int weight = 1,
    SmartTileRenderChannel channel = SmartTileRenderChannel.ground,
    int columnSpan = 1,
    int rowSpan = 1,
  }) {
    _requireCandidateWeight(weight);
    _ensureAtlasCell(
      column: column,
      row: row,
      columnSpan: columnSpan,
      rowSpan: rowSpan,
    );
    _upsertCandidate(
      mask: mask,
      candidate: SmartTileCandidate(
        id: candidateId,
        weight: weight,
        parts: <SmartTileVisualPart>[
          SmartTileVisualPart(
            source: SmartTileVisualSource.frame(
              frame: SmartTileFrameRef(
                atlasId: _state.atlasId,
                column: column,
                row: row,
                columnSpan: columnSpan,
                rowSpan: rowSpan,
              ),
            ),
            channel: channel,
          ),
        ],
      ),
    );
  }

  void addAnimationVariant({
    required int mask,
    required String animationId,
    required String candidateId,
    int weight = 1,
    SmartTileRenderChannel channel = SmartTileRenderChannel.ground,
  }) {
    _requireCandidateWeight(weight);
    if (!_state.animations.any((item) => item.id == animationId)) {
      throw ArgumentError('Unknown Smart Tile animation "$animationId".');
    }
    _upsertCandidate(
      mask: mask,
      candidate: SmartTileCandidate(
        id: candidateId,
        weight: weight,
        parts: <SmartTileVisualPart>[
          SmartTileVisualPart(
            source: SmartTileVisualSource.animation(
              animationId: animationId,
            ),
            channel: channel,
          ),
        ],
      ),
    );
  }

  void updateCandidateWeight({
    required int mask,
    required String candidateId,
    required int weight,
  }) {
    _requireCandidateWeight(weight);
    final normalized = _normalizeMask(mask);
    final candidates =
        List<SmartTileCandidate>.from(_state.mappings[normalized] ?? const []);
    final index = candidates.indexWhere((item) => item.id == candidateId);
    if (index < 0) {
      throw ArgumentError('Unknown Smart Tile candidate "$candidateId".');
    }
    candidates[index] = candidates[index].copyWith(weight: weight);
    _replaceMapping(normalized, candidates);
  }

  void removeCandidate({
    required int mask,
    required String candidateId,
  }) {
    final normalized = _normalizeMask(mask);
    final candidates = List<SmartTileCandidate>.from(
      _state.mappings[normalized] ?? const <SmartTileCandidate>[],
    );
    final candidateIndex =
        candidates.indexWhere((item) => item.id == candidateId);
    if (candidateIndex < 0) {
      throw ArgumentError('Unknown Smart Tile candidate "$candidateId".');
    }
    candidates.removeAt(candidateIndex);
    final mappings = <int, List<SmartTileCandidate>>{..._state.mappings};
    if (candidates.isEmpty) {
      mappings.remove(normalized);
      _preservedCoverageProfile = null;
    } else {
      mappings[normalized] = candidates;
    }
    _state = _state.copyWith(mappings: mappings);
  }

  void reorderCandidate({
    required int mask,
    required String candidateId,
    required int newIndex,
  }) {
    final normalized = _normalizeMask(mask);
    final candidates = List<SmartTileCandidate>.from(
      _state.mappings[normalized] ?? const <SmartTileCandidate>[],
    );
    final currentIndex =
        candidates.indexWhere((candidate) => candidate.id == candidateId);
    if (currentIndex < 0) {
      throw ArgumentError('Unknown Smart Tile candidate "$candidateId".');
    }
    if (newIndex < 0 || newIndex >= candidates.length) {
      throw RangeError.range(newIndex, 0, candidates.length - 1, 'newIndex');
    }
    final candidate = candidates.removeAt(currentIndex);
    candidates.insert(newIndex, candidate);
    _replaceMapping(normalized, candidates);
  }

  void replaceCandidateWithAnimation({
    required int mask,
    required String candidateId,
    required String animationId,
  }) {
    if (!_state.animations.any((animation) => animation.id == animationId)) {
      throw ArgumentError('Unknown Smart Tile animation "$animationId".');
    }
    final normalized = _normalizeMask(mask);
    final candidates = List<SmartTileCandidate>.from(
      _state.mappings[normalized] ?? const <SmartTileCandidate>[],
    );
    final index =
        candidates.indexWhere((candidate) => candidate.id == candidateId);
    if (index < 0) {
      throw ArgumentError('Unknown Smart Tile candidate "$candidateId".');
    }
    final current = candidates[index];
    final firstPart = current.parts.firstOrNull;
    candidates[index] = current.copyWith(
      parts: <SmartTileVisualPart>[
        SmartTileVisualPart(
          source: SmartTileVisualSource.animation(animationId: animationId),
          transform: firstPart?.transform ?? const SmartTileSpriteTransform(),
          channel: firstPart?.channel ?? SmartTileRenderChannel.ground,
          frameSampling:
              firstPart?.frameSampling ?? SmartTileFrameSampling.fullFrame,
          offsetUnit: firstPart?.offsetUnit ?? SmartTileOffsetUnit.pixel,
          offsetX: firstPart?.offsetX ?? 0,
          offsetY: firstPart?.offsetY ?? 0,
          footprintWidth: firstPart?.footprintWidth ?? 1,
          footprintHeight: firstPart?.footprintHeight ?? 1,
          anchorX: firstPart?.anchorX ?? 0,
          anchorY: firstPart?.anchorY ?? 0,
          drawOrder: firstPart?.drawOrder ?? 0,
        ),
        ...current.parts.skip(1),
      ],
    );
    _replaceMapping(normalized, candidates);
  }

  void addVisualPart({
    required int mask,
    required String candidateId,
    required SmartTileVisualPart part,
  }) {
    final normalized = _normalizeMask(mask);
    final candidates =
        List<SmartTileCandidate>.from(_state.mappings[normalized] ?? const []);
    final index = candidates.indexWhere((item) => item.id == candidateId);
    if (index < 0) {
      throw ArgumentError('Unknown Smart Tile candidate "$candidateId".');
    }
    candidates[index] = candidates[index].copyWith(
      parts: <SmartTileVisualPart>[
        ...candidates[index].parts,
        part,
      ],
    );
    _replaceMapping(normalized, candidates);
  }

  void addAnimation(ProjectSmartTileAnimation animation) {
    final animations = List<ProjectSmartTileAnimation>.from(_state.animations);
    final index = animations.indexWhere((item) => item.id == animation.id);
    if (index < 0) {
      animations.add(animation);
    } else {
      animations[index] = animation;
    }
    _state = _state.copyWith(animations: animations);
  }

  ProjectSmartTileAnimation createAnimation({
    required String name,
    required List<SmartTileFrameRef> frames,
    required int durationMs,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Animation name is required.');
    }
    if (frames.isEmpty) {
      throw ArgumentError.value(frames, 'frames', 'Choose at least one frame.');
    }
    if (durationMs < 1 || durationMs > 60000) {
      throw RangeError.range(durationMs, 1, 60000, 'durationMs');
    }
    for (final frame in frames) {
      if (frame.atlasId != _state.atlasId) {
        throw ArgumentError('Animation frames must use the active atlas.');
      }
      _ensureAtlasCell(
        column: frame.column,
        row: frame.row,
        columnSpan: frame.columnSpan,
        rowSpan: frame.rowSpan,
      );
    }
    final idBase = '${_state.id}-animation-${_slugify(normalizedName)}';
    final occupied = _state.animations.map((animation) => animation.id).toSet();
    var id = idBase;
    var suffix = 2;
    while (occupied.contains(id)) {
      id = '$idBase-$suffix';
      suffix += 1;
    }
    final animation = ProjectSmartTileAnimation(
      id: id,
      name: normalizedName,
      frames: <ProjectSmartTileAnimationFrame>[
        for (final frame in frames)
          ProjectSmartTileAnimationFrame(
            frame: frame,
            durationMs: durationMs,
          ),
      ],
    );
    addAnimation(animation);
    return animation;
  }

  ProjectSmartTileAtlas compileAtlas() {
    final geometry = _requireGrid();
    _requireText(_state.atlasId, 'atlas id');
    _requireText(_state.atlasName, 'atlas name');
    _requireText(_state.tilesetId, 'tileset id');
    return ProjectSmartTileAtlas(
      id: _state.atlasId,
      name: _state.atlasName,
      tilesetId: _state.tilesetId,
      cellWidth: geometry.cellWidth,
      cellHeight: geometry.cellHeight,
      originX: geometry.originX,
      originY: geometry.originY,
      marginX: geometry.marginX,
      marginY: geometry.marginY,
      spacingX: geometry.spacingX,
      spacingY: geometry.spacingY,
      columns: geometry.columns,
      rows: geometry.rows,
    );
  }

  ProjectSmartTilePreset compilePreset() {
    _requireText(_state.id, 'preset id');
    _requireText(_state.name, 'preset name');
    _requireText(_state.defaultMaterialId, 'default material id');
    final usage = _state.usage;
    final topology = _state.topology;
    if (usage == null || topology == null) {
      throw StateError('Choose a Smart Tile usage before compiling.');
    }
    return ProjectSmartTilePreset(
      id: _state.id,
      name: _state.name,
      usage: usage,
      topology: topology,
      templateHint: _state.templateHint,
      status: _state.status,
      coveragePolicy: _state.coveragePolicy,
      coverageProfile: _compileCoverageProfile(topology),
      transformPolicy: _state.transformPolicy,
      boundaryPolicy: _state.boundaryPolicy,
      defaultMaterialId: _state.defaultMaterialId,
      allowedMaterialIds:
          _state.materials.map((material) => material.id).toList(),
      rules: _compileRules(topology),
    );
  }

  ProjectSmartTileCatalog compileCatalog() {
    if (_state.materials.isEmpty) {
      throw StateError('At least one Smart Tile material is required.');
    }
    return ProjectSmartTileCatalog(
      atlases: <ProjectSmartTileAtlas>[compileAtlas()],
      materials: _state.materials,
      animations: _state.animations,
      presets: <ProjectSmartTilePreset>[compilePreset()],
    );
  }

  ProjectSmartTileAtlas? _tryCompileAtlas() {
    final geometry = _state.gridGeometry;
    if (geometry == null ||
        _state.atlasId.trim().isEmpty ||
        _state.atlasName.trim().isEmpty ||
        _state.tilesetId.trim().isEmpty) {
      return null;
    }
    return compileAtlas();
  }

  List<SmartTileRule> _compileRules(SmartTileTopology topology) {
    final masks = _state.mappings.keys.toList()..sort();
    return <SmartTileRule>[
      for (final mask in masks)
        SmartTileRule(
          id: smartTileCanonicalRuleId(mask),
          centerMatch: _state.templateHint == SmartTileTemplateHint.simple
              ? SmartTileSlotMatch.material(_state.defaultMaterialId)
              : const SmartTileSlotMatch.any(),
          signature: smartTileSignatureForMask(mask, topology: topology),
          candidates: _state.mappings[mask]!,
        ),
      ..._state.transitionCases,
    ];
  }

  SmartTileCoverageProfile _compileCoverageProfile(
    SmartTileTopology topology,
  ) {
    final preserved = _preservedCoverageProfile;
    if (preserved != null) return preserved;
    final transitionScenarios = <SmartTileCoverageScenario>[
      for (final rule in _state.transitionCases) _coverageScenarioForRule(rule),
    ];
    if (_state.coveragePolicy == SmartTileCoveragePolicy.complete) {
      return SmartTileCoverageProfile(
        mode: transitionScenarios.isEmpty
            ? SmartTileCoverageMode.template
            : SmartTileCoverageMode.templateAndExplicit,
        requiredScenarios: transitionScenarios,
      );
    }
    final masks = _state.mappings.keys.toList()..sort();
    final materialIds = _state.materials
        .where((material) => !material.isEmpty)
        .map((material) => material.id)
        .toList()
      ..sort();
    return SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.explicit,
      requiredScenarios: <SmartTileCoverageScenario>[
        for (final materialId in materialIds)
          for (final mask in masks)
            SmartTileCoverageScenario(
              id: 'sparse_${materialId}_${smartTileCanonicalRuleId(mask)}',
              centerMaterialId: materialId,
              signature: _exactSignatureForMask(
                mask,
                topology: topology,
                materialId: materialId,
              ),
            ),
        ...transitionScenarios,
      ],
    );
  }

  SmartTileCoverageScenario _coverageScenarioForRule(SmartTileRule rule) {
    final centerMaterialId = switch (rule.centerMatch.kind) {
      SmartTileMatchKind.material => rule.centerMatch.materialId,
      SmartTileMatchKind.any || SmartTileMatchKind.empty => null,
      SmartTileMatchKind.same || SmartTileMatchKind.different => null,
    };
    final centerGroup = centerMaterialId == null
        ? null
        : _state.materials
            .where((material) => material.id == centerMaterialId)
            .firstOrNull
            ?.connectionGroupId;
    final differentMaterialId = _state.materials
        .where(
          (material) =>
              !material.isEmpty &&
              (centerGroup == null ||
                  material.connectionGroupId != centerGroup),
        )
        .map((material) => material.id)
        .firstOrNull;
    String? observed(SmartTileSlotMatch match) => switch (match.kind) {
          SmartTileMatchKind.material => match.materialId,
          SmartTileMatchKind.same => centerMaterialId,
          SmartTileMatchKind.different => differentMaterialId,
          SmartTileMatchKind.any || SmartTileMatchKind.empty => null,
        };
    final signature = rule.signature;
    return SmartTileCoverageScenario(
      id: 'transition:${rule.id}',
      centerMaterialId: centerMaterialId,
      signature: SmartTileExactSignature(
        northWestCorner: observed(signature.northWestCorner),
        northEdge: observed(signature.northEdge),
        northEastCorner: observed(signature.northEastCorner),
        eastEdge: observed(signature.eastEdge),
        southEastCorner: observed(signature.southEastCorner),
        southEdge: observed(signature.southEdge),
        southWestCorner: observed(signature.southWestCorner),
        westEdge: observed(signature.westEdge),
      ),
    );
  }

  Set<int> _theoreticalMasksForPolicy(
    SmartTileTransformPolicy policy, {
    required SmartTileTopology topology,
  }) {
    final masks = <int>{};
    for (final sourceMask in _state.mappings.keys) {
      final signature = smartTileSignatureForMask(
        sourceMask,
        topology: topology,
      );
      for (final transform in smartTileAllowedTransforms(policy)) {
        final generated = smartTileMaskForSignature(
          transformSmartTileSignature(signature, transform),
          topology: topology,
        );
        if (generated != null) masks.add(generated);
      }
    }
    return masks;
  }

  Map<int, SmartTileTransformImpact> _resolvedFormsForPolicy(
    SmartTileTransformPolicy policy, {
    required SmartTileTopology topology,
    required Set<int> masks,
  }) {
    if (masks.isEmpty || _state.mappings.isEmpty) {
      return const <int, SmartTileTransformImpact>{};
    }
    final materialId = _state.defaultMaterialId.isNotEmpty
        ? _state.defaultMaterialId
        : _state.materials
            .where((material) => !material.isEmpty)
            .map((material) => material.id)
            .firstOrNull;
    if (materialId == null || materialId.isEmpty) {
      return const <int, SmartTileTransformImpact>{};
    }
    final sortedMasks = masks.toList()..sort();
    final scenarios = <SmartTileCoverageScenario>[
      for (final mask in sortedMasks)
        SmartTileCoverageScenario(
          id: 'transform_${smartTileCanonicalRuleId(mask)}',
          centerMaterialId: materialId,
          signature: _exactSignatureForMask(
            mask,
            topology: topology,
            materialId: materialId,
          ),
        ),
    ];
    final preset = compilePreset().copyWith(
      templateHint: SmartTileTemplateHint.free,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
        requiredScenarios: scenarios,
      ),
      transformPolicy: policy,
    );
    final report = analyzeSmartTileCoverage(
      preset: preset,
      materials: _state.materials,
      atlases: <ProjectSmartTileAtlas>[compileAtlas()],
      animations: _state.animations,
    );
    final impacts = <int, SmartTileTransformImpact>{};
    for (var index = 0; index < report.cases.length; index += 1) {
      final coverageCase = report.cases[index];
      if (coverageCase.status != SmartTileCoverageStatus.exact &&
          coverageCase.status != SmartTileCoverageStatus.transformed) {
        continue;
      }
      final resolution = resolveSmartTile(
        preset: preset,
        materials: _state.materials,
        context: coverageCase.context,
        x: index,
        y: 0,
        mapId: 'smart_tile_transform_proposal',
        layerId: preset.id,
      );
      final ruleId = resolution.ruleId;
      if (resolution.status != SmartTileResolutionStatus.resolved ||
          ruleId == null) {
        continue;
      }
      final rule =
          preset.rules.where((candidate) => candidate.id == ruleId).firstOrNull;
      if (rule == null) continue;
      final sourceMask = smartTileMaskForSignature(
        rule.signature,
        topology: topology,
      );
      if (sourceMask == null) continue;
      final mask = sortedMasks[index];
      impacts[mask] = SmartTileTransformImpact(
        mask: mask,
        sourceMask: sourceMask,
        transform: resolution.transform,
      );
    }
    return impacts;
  }

  void _upsertCandidate({
    required int mask,
    required SmartTileCandidate candidate,
  }) {
    final normalized = _normalizeMask(mask);
    final addsCoverageForm = !_state.mappings.containsKey(normalized);
    final candidates =
        List<SmartTileCandidate>.from(_state.mappings[normalized] ?? const []);
    final index = candidates.indexWhere((item) => item.id == candidate.id);
    if (index < 0) {
      candidates.add(candidate);
    } else {
      candidates[index] = candidate;
    }
    _replaceMapping(normalized, candidates);
    if (addsCoverageForm) _preservedCoverageProfile = null;
  }

  void _replaceMapping(int mask, List<SmartTileCandidate> candidates) {
    final mappings = <int, List<SmartTileCandidate>>{
      ..._state.mappings,
      mask: candidates,
    };
    _state = _state.copyWith(mappings: mappings);
  }

  int _normalizeMask(int mask) {
    if (_state.templateHint == SmartTileTemplateHint.blob47 ||
        _state.topology == SmartTileTopology.blob8) {
      return normalizeSmartTileBlobMask(mask);
    }
    return mask & smartTileEightNeighborMask;
  }

  SmartTileRule _requireTransitionCase(String caseId) {
    final rule = _state.transitionCases
        .where((candidate) => candidate.id == caseId)
        .firstOrNull;
    if (rule == null) {
      throw ArgumentError('Unknown Smart Tile transition case "$caseId".');
    }
    return rule;
  }

  void _replaceTransitionCase(String caseId, SmartTileRule replacement) {
    final index =
        _state.transitionCases.indexWhere((rule) => rule.id == caseId);
    if (index < 0) {
      throw ArgumentError('Unknown Smart Tile transition case "$caseId".');
    }
    final cases = List<SmartTileRule>.from(_state.transitionCases);
    cases[index] = replacement;
    _state = _state.copyWith(transitionCases: cases);
    _preservedCoverageProfile = null;
  }

  void _validateCenterMatch(SmartTileSlotMatch match) {
    if (match.kind == SmartTileMatchKind.same ||
        match.kind == SmartTileMatchKind.different) {
      throw ArgumentError('A center cannot be relative to itself.');
    }
    _validateSlotMatch(match);
  }

  void _validateSlotMatch(SmartTileSlotMatch match) {
    final materialId = match.materialId;
    if (match.kind == SmartTileMatchKind.material && materialId != null) {
      _requireMaterial(materialId);
    }
  }

  ProjectSmartTileMaterial _requireMaterial(String materialId) {
    final material = _state.materials
        .where((candidate) => candidate.id == materialId)
        .firstOrNull;
    if (material == null) {
      throw ArgumentError('Unknown Smart Tile material "$materialId".');
    }
    return material;
  }

  void _ensureAtlasCell({
    required int column,
    required int row,
    required int columnSpan,
    required int rowSpan,
  }) {
    final geometry = _requireGrid();
    if (column < 0 ||
        row < 0 ||
        columnSpan <= 0 ||
        rowSpan <= 0 ||
        column + columnSpan > geometry.columns ||
        row + rowSpan > geometry.rows) {
      throw RangeError('Selected Smart Tile cell is outside the atlas grid.');
    }
  }

  SmartTileGridGeometry _requireGrid() {
    final geometry = _state.gridGeometry;
    if (geometry == null) {
      throw StateError('Configure the Smart Tile atlas before compiling.');
    }
    return geometry;
  }
}

SmartTileExactSignature _exactSignatureForMask(
  int mask, {
  required SmartTileTopology topology,
  required String materialId,
}) {
  final normalized = topology == SmartTileTopology.blob8
      ? normalizeSmartTileBlobMask(mask)
      : mask & smartTileEightNeighborMask;
  String? materialAt(int bit) => normalized & bit == 0 ? null : materialId;

  return switch (topology) {
    SmartTileTopology.uniform => const SmartTileExactSignature(),
    SmartTileTopology.cardinal4 ||
    SmartTileTopology.wangEdge4 =>
      SmartTileExactSignature(
        northEdge: materialAt(smartTileNorthBit),
        eastEdge: materialAt(smartTileEastBit),
        southEdge: materialAt(smartTileSouthBit),
        westEdge: materialAt(smartTileWestBit),
      ),
    SmartTileTopology.wangCorner4 => SmartTileExactSignature(
        northWestCorner: materialAt(smartTileNorthWestBit),
        northEastCorner: materialAt(smartTileNorthEastBit),
        southEastCorner: materialAt(smartTileSouthEastBit),
        southWestCorner: materialAt(smartTileSouthWestBit),
      ),
    SmartTileTopology.blob8 ||
    SmartTileTopology.wang8 =>
      SmartTileExactSignature(
        northWestCorner: materialAt(smartTileNorthWestBit),
        northEdge: materialAt(smartTileNorthBit),
        northEastCorner: materialAt(smartTileNorthEastBit),
        eastEdge: materialAt(smartTileEastBit),
        southEastCorner: materialAt(smartTileSouthEastBit),
        southEdge: materialAt(smartTileSouthBit),
        southWestCorner: materialAt(smartTileSouthWestBit),
        westEdge: materialAt(smartTileWestBit),
      ),
  };
}

bool _ruleUsesMaterial(SmartTileRule rule, String materialId) {
  if (rule.centerMatch.materialId == materialId) return true;
  final signature = rule.signature;
  return <SmartTileSlotMatch>[
    signature.northWestCorner,
    signature.northEdge,
    signature.northEastCorner,
    signature.eastEdge,
    signature.southEastCorner,
    signature.southEdge,
    signature.southWestCorner,
    signature.westEdge,
  ].any((match) => match.materialId == materialId);
}

String _slugify(String value) {
  const replacements = <String, String>{
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'ã': 'a',
    'å': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'œ': 'oe',
    'æ': 'ae',
  };
  final normalized = value
      .toLowerCase()
      .split('')
      .map(
        (character) => replacements[character] ?? character,
      )
      .join();
  final slug = normalized
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  return slug.isEmpty ? 'material' : slug;
}

SmartTileGridGeometry _geometryFromAtlas(ProjectSmartTileAtlas atlas) {
  final usedWidth =
      atlas.columns * atlas.cellWidth + (atlas.columns - 1) * atlas.spacingX;
  final usedHeight =
      atlas.rows * atlas.cellHeight + (atlas.rows - 1) * atlas.spacingY;
  return SmartTileGridGeometry(
    imageWidth: atlas.originX + atlas.marginX + usedWidth,
    imageHeight: atlas.originY + atlas.marginY + usedHeight,
    cellWidth: atlas.cellWidth,
    cellHeight: atlas.cellHeight,
    originX: atlas.originX,
    originY: atlas.originY,
    marginX: atlas.marginX,
    marginY: atlas.marginY,
    spacingX: atlas.spacingX,
    spacingY: atlas.spacingY,
  );
}

void _requireText(String value, String label) {
  if (value.trim().isEmpty) {
    throw StateError('Smart Tile $label is required.');
  }
}

void _requireCandidateWeight(int weight) {
  if (weight < 1 || weight > 1000) {
    throw RangeError.range(weight, 1, 1000, 'weight');
  }
}
