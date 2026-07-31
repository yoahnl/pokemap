import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'smart_tile_grid_detector.dart';

final class SmartTileAuthoringDraft {
  SmartTileAuthoringDraft({
    this.id = '',
    this.name = '',
    this.materialId = '',
    this.materialName = '',
    this.connectionGroupId = '',
    this.atlasId = '',
    this.atlasName = '',
    this.tilesetId = '',
    this.gridGeometry,
    this.usage,
    this.topology,
    this.templateHint = SmartTileTemplateHint.free,
    this.status = SmartTilePresetStatus.draft,
    Map<int, List<SmartTileCandidate>> mappings =
        const <int, List<SmartTileCandidate>>{},
    List<ProjectSmartTileAnimation> animations =
        const <ProjectSmartTileAnimation>[],
  })  : mappings = UnmodifiableMapView<int, List<SmartTileCandidate>>(
          <int, List<SmartTileCandidate>>{
            for (final entry in mappings.entries)
              entry.key: List<SmartTileCandidate>.unmodifiable(entry.value),
          },
        ),
        animations = List<ProjectSmartTileAnimation>.unmodifiable(animations);

  final String id;
  final String name;
  final String materialId;
  final String materialName;
  final String connectionGroupId;
  final String atlasId;
  final String atlasName;
  final String tilesetId;
  final SmartTileGridGeometry? gridGeometry;
  final SmartTileUsage? usage;
  final SmartTileTopology? topology;
  final SmartTileTemplateHint templateHint;
  final SmartTilePresetStatus status;
  final Map<int, List<SmartTileCandidate>> mappings;
  final List<ProjectSmartTileAnimation> animations;

  SmartTileAuthoringDraft copyWith({
    String? id,
    String? name,
    String? materialId,
    String? materialName,
    String? connectionGroupId,
    String? atlasId,
    String? atlasName,
    String? tilesetId,
    SmartTileGridGeometry? gridGeometry,
    SmartTileUsage? usage,
    SmartTileTopology? topology,
    SmartTileTemplateHint? templateHint,
    SmartTilePresetStatus? status,
    Map<int, List<SmartTileCandidate>>? mappings,
    List<ProjectSmartTileAnimation>? animations,
  }) {
    return SmartTileAuthoringDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      materialId: materialId ?? this.materialId,
      materialName: materialName ?? this.materialName,
      connectionGroupId: connectionGroupId ?? this.connectionGroupId,
      atlasId: atlasId ?? this.atlasId,
      atlasName: atlasName ?? this.atlasName,
      tilesetId: tilesetId ?? this.tilesetId,
      gridGeometry: gridGeometry ?? this.gridGeometry,
      usage: usage ?? this.usage,
      topology: topology ?? this.topology,
      templateHint: templateHint ?? this.templateHint,
      status: status ?? this.status,
      mappings: mappings ?? this.mappings,
      animations: animations ?? this.animations,
    );
  }
}

/// Pure in-memory authoring controller for one native Smart Tile preset.
///
/// The controller never reads or writes disk. Calling [applyToManifest] is an
/// explicit v4 transaction that preserves every unrelated legacy record.
final class SmartTileAuthoringController {
  SmartTileAuthoringController({
    SmartTileAuthoringDraft? initialState,
  }) : _state = initialState ?? SmartTileAuthoringDraft();

  factory SmartTileAuthoringController.blank() =>
      SmartTileAuthoringController();

  SmartTileAuthoringDraft _state;

  SmartTileAuthoringDraft get state => _state;

  void configureIdentity({
    required String id,
    required String name,
    required String materialId,
    required String materialName,
    String? connectionGroupId,
  }) {
    _state = _state.copyWith(
      id: id.trim(),
      name: name.trim(),
      materialId: materialId.trim(),
      materialName: materialName.trim(),
      connectionGroupId: (connectionGroupId ?? materialId).trim(),
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

  void setStatus(SmartTilePresetStatus status) {
    _state = _state.copyWith(status: status);
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
    _requireText(_state.materialId, 'material id');
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
      defaultMaterialId: _state.materialId,
      allowedMaterialIds: <String>[_state.materialId],
      rules: <SmartTileRule>[
        for (final mask in masks)
          SmartTileRule(
            id: smartTileCanonicalRuleId(mask),
            signature: smartTileSignatureForMask(mask, topology: topology),
            candidates: _state.mappings[mask]!,
          ),
      ],
    );
  }

  ProjectSmartTileCatalog compileCatalog() {
    _requireText(_state.materialName, 'material name');
    _requireText(_state.connectionGroupId, 'connection group id');
    return ProjectSmartTileCatalog(
      atlases: <ProjectSmartTileAtlas>[compileAtlas()],
      materials: <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: _state.materialId,
          name: _state.materialName,
          connectionGroupId: _state.connectionGroupId,
        ),
      ],
      animations: _state.animations,
      presets: <ProjectSmartTilePreset>[compilePreset()],
    );
  }

  ProjectManifest applyToManifest(ProjectManifest manifest) {
    final compiled = compileCatalog();
    final current = manifest.smartTileCatalog;
    final nextCatalog = ProjectSmartTileCatalog(
      formatVersion: current.formatVersion,
      categories: current.categories,
      atlases: _upsertById(
        current.atlases,
        compiled.atlases.single,
        (item) => item.id,
      ),
      materials: _upsertById(
        current.materials,
        compiled.materials.single,
        (item) => item.id,
      ),
      animations: <ProjectSmartTileAnimation>[
        for (final animation in current.animations)
          if (!compiled.animations.any((item) => item.id == animation.id))
            animation,
        ...compiled.animations,
      ],
      presets: _upsertById(
        current.presets,
        compiled.presets.single,
        (item) => item.id,
      ),
    );
    return manifest.copyWith(
      version: ProjectVersion.v4,
      smartTileCatalog: nextCatalog,
    );
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

void _requireText(String value, String label) {
  if (value.trim().isEmpty) {
    throw StateError('Smart Tile $label is required.');
  }
}

List<T> _upsertById<T>(
  List<T> current,
  T replacement,
  String Function(T item) idOf,
) {
  return <T>[
    for (final item in current)
      if (idOf(item) != idOf(replacement)) item,
    replacement,
  ];
}
