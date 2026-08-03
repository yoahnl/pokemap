import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'smart_tile_grid_detector.dart';
import 'smart_tile_connection_profile.dart';
import 'smart_tile_guide.dart';
import 'smart_tile_guide_placement.dart';

const String smartTileStudioAuthoringRequiresStn04Code =
    'smart_tile_studio_authoring_requires_stn04';

enum SmartTileMaterialRemovalBlocker {
  defaultMaterial,
  activeMaterial,
  mappedMaterial,
}

final class SmartTileMaterialInUseException implements Exception {
  const SmartTileMaterialInUseException(this.materialId, this.blocker);

  final String materialId;
  final SmartTileMaterialRemovalBlocker blocker;

  @override
  String toString() =>
      'SmartTileMaterialInUseException($materialId, ${blocker.name})';
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
    this.status = SmartTilePresetStatus.draft,
    Map<int, List<SmartTileCandidate>> mappings =
        const <int, List<SmartTileCandidate>>{},
    List<ProjectSmartTileAnimation> animations =
        const <ProjectSmartTileAnimation>[],
  })  : materials = List<ProjectSmartTileMaterial>.unmodifiable(materials),
        mappings = UnmodifiableMapView<int, List<SmartTileCandidate>>(
          <int, List<SmartTileCandidate>>{
            for (final entry in mappings.entries)
              entry.key: List<SmartTileCandidate>.unmodifiable(entry.value),
          },
        ),
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
  final SmartTilePresetStatus status;
  final Map<int, List<SmartTileCandidate>> mappings;
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
    SmartTilePresetStatus? status,
    Map<int, List<SmartTileCandidate>>? mappings,
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
      status: status ?? this.status,
      mappings: mappings ?? this.mappings,
      animations: animations ?? this.animations,
    );
  }
}

/// Pure in-memory authoring controller for one native Smart Tile preset.
///
/// The controller never reads or writes disk. Draft compilation remains
/// available in memory, but persistence is delegated to the canonical API and
/// remains blocked here until the STN-04 no-code adapter is wired.
final class SmartTileAuthoringController {
  SmartTileAuthoringController({
    SmartTileAuthoringDraft? initialState,
  })  : _state = initialState ?? SmartTileAuthoringDraft(),
        _canonicalBase = null;

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
    for (final rule in draft.rules) {
      final mask = smartTileMaskForSignature(
        rule.signature,
        topology: draft.topology,
      );
      if (mask != null) mappings[mask] = rule.candidates;
    }
    _canonicalBase = draft;
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
      status: SmartTilePresetStatus.draft,
      mappings: mappings,
      animations: draft.animations,
    );
  }

  /// Projects incomplete local state into the durable core draft schema.
  ProjectSmartTileAuthoringDraft compileAuthoringDraft({
    required SmartTileAuthoringStage lastStage,
    String? guideId,
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
      guideId: guideId ?? base?.guideId,
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
  }

  void configureConnections(
    SmartTileConnectionConfiguration configuration, {
    required bool clearMappings,
  }) {
    final changesContract = _state.topology != configuration.topology ||
        _state.templateHint != configuration.templateHint;
    if (changesContract && _state.mappings.isNotEmpty && !clearMappings) {
      throw StateError(
        'Changing a Smart Tile connection contract requires mapping confirmation.',
      );
    }
    _state = _state.copyWith(
      topology: configuration.topology,
      templateHint: configuration.templateHint,
      boundaryPolicy: configuration.boundaryPolicy,
      coveragePolicy: configuration.coveragePolicy,
      mappings: changesContract && clearMappings
          ? const <int, List<SmartTileCandidate>>{}
          : _state.mappings,
    );
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
    );
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
    );
  }

  /// Replaces the current mapping with every cell from a validated guide.
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

    final mappings = <int, List<SmartTileCandidate>>{};
    for (final placed in placement.frames) {
      final cell = placed.guideCell;
      mappings.putIfAbsent(cell.mask, () => <SmartTileCandidate>[]).add(
            SmartTileCandidate(
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
            ),
          );
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
    candidates[candidateIndex] = current.copyWith(
      parts: <SmartTileVisualPart>[
        SmartTileVisualPart(
          source: SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(
              atlasId: _state.atlasId,
              column: column,
              row: row,
            ),
          ),
          channel: channel,
        ),
      ],
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

  void clearMappings() {
    _state = _state.copyWith(
      mappings: const <int, List<SmartTileCandidate>>{},
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
    final masks = _state.mappings.keys.toList()..sort();
    return ProjectSmartTilePreset(
      id: _state.id,
      name: _state.name,
      usage: usage,
      topology: topology,
      templateHint: _state.templateHint,
      status: _state.status,
      coveragePolicy: _state.coveragePolicy,
      coverageProfile: const SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      boundaryPolicy: _state.boundaryPolicy,
      defaultMaterialId: _state.defaultMaterialId,
      allowedMaterialIds:
          _state.materials.map((material) => material.id).toList(),
      rules: <SmartTileRule>[
        for (final mask in masks)
          SmartTileRule(
            id: smartTileCanonicalRuleId(mask),
            // Simple owns a center texture, not a universal neighborhood rule.
            // Keeping the material explicit prevents a future multi-material
            // draft from resolving the same visual for every center.
            centerMatch: _state.templateHint == SmartTileTemplateHint.simple
                ? SmartTileSlotMatch.material(_state.defaultMaterialId)
                : const SmartTileSlotMatch.any(),
            signature: smartTileSignatureForMask(mask, topology: topology),
            candidates: _state.mappings[mask]!,
          ),
      ],
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

  ProjectManifest applyToManifest(ProjectManifest manifest) {
    throw StateError(
      smartTileStudioAuthoringRequiresStn04Code,
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
    ];
  }

  void _upsertCandidate({
    required int mask,
    required SmartTileCandidate candidate,
  }) {
    final normalized = _normalizeMask(mask);
    final candidates =
        List<SmartTileCandidate>.from(_state.mappings[normalized] ?? const []);
    final index = candidates.indexWhere((item) => item.id == candidate.id);
    if (index < 0) {
      candidates.add(candidate);
    } else {
      candidates[index] = candidate;
    }
    _replaceMapping(normalized, candidates);
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
