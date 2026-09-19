import 'package:map_core/map_core_domain.dart';

import '../domain/terrain_connections.dart';

typedef MutateTerrainResource =
    Future<ProjectManifest> Function(
      String actionId,
      Map<String, Object?> parameters,
    );

class TerrainDraftController {
  TerrainDraftController({
    required this.manifest,
    required ProjectSmartTileAtlas atlas,
    required String id,
    String name = 'Nouveau terrain',
  }) : draft = ProjectSmartTileAuthoringDraft(
         id: 'draft-$id',
         targetPresetId: id,
         name: name,
         usage: SmartTileUsage.path,
         lastStage: SmartTileAuthoringStage.connections,
         guideId: 'avelune-cardinal4-v1',
         topology: SmartTileTopology.cardinal4,
         templateHint: SmartTileTemplateHint.edge16,
         coveragePolicy: SmartTileCoveragePolicy.sparse,
         sourceTilesetIds: [atlas.tilesetId],
         atlases: [atlas],
         primaryAtlasId: atlas.id,
         materials: [
           ProjectSmartTileMaterial(
             id: 'material-$id',
             name: name,
             connectionGroupId: 'connection-$id',
           ),
         ],
         defaultMaterialId: 'material-$id',
         allowedMaterialIds: ['material-$id'],
         rules: List.generate(
           16,
           (mask) => terrainConnectionRule(mask, null, 'material-$id'),
         ),
       ) {
    example();
  }

  TerrainDraftController.resume({required this.manifest, required this.draft}) {
    if (draft.guideId != 'avelune-cardinal4-v1' ||
        draft.topology != SmartTileTopology.cardinal4 ||
        draft.rules.length != 16 ||
        !List.generate(
          16,
          (index) => index,
        ).every((index) => draft.rules[index].id == 'connection-$index')) {
      throw StateError(
        'Ce modèle reste utilisable mais pas encore éditable dans Studio.',
      );
    }
    _saved = draft;
    example();
  }

  ProjectManifest manifest;
  ProjectSmartTileAuthoringDraft draft;
  ProjectSmartTileAuthoringDraft? _saved;
  int selectedRule = 0;
  bool busy = false;
  String? error;
  static const scratchSize = 17;
  final Set<GridPos> scratch = {};
  List<SmartTileResolution> resolved = [];

  bool get dirty => draft != _saved;
  bool get complete => draft.rules.every((rule) => rule.candidates.isNotEmpty);
  ProjectSmartTileAtlas get atlas =>
      draft.atlases.firstWhere((a) => a.id == draft.primaryAtlasId);
  SmartTileFrameRef? frameFor(int rule) {
    final parts = draft.rules[rule].candidates.firstOrNull?.parts;
    final source = parts?.firstOrNull?.source;
    return source is SmartTileFrameSource ? source.frame : null;
  }

  ProjectSmartTilePreset get previewPreset => ProjectSmartTilePreset(
    id: draft.targetPresetId,
    name: draft.name,
    usage: draft.usage,
    topology: draft.topology,
    templateHint: draft.templateHint,
    coveragePolicy: draft.coveragePolicy,
    coverageProfile: draft.coverageProfile,
    transformPolicy: draft.transformPolicy,
    defaultMaterialId: draft.defaultMaterialId!,
    allowedMaterialIds: draft.allowedMaterialIds,
    rules: draft.rules,
  );

  void rename(String name) {
    draft = draft.copyWith(
      name: name.trim().isEmpty ? 'Nouveau terrain' : name.trim(),
    );
  }

  void assign(int column, int row) {
    atlas.sourceRectFor(column: column, row: row);
    final rules = List<SmartTileRule>.of(draft.rules);
    rules[selectedRule] = terrainConnectionRule(
      selectedRule,
      SmartTileFrameRef(atlasId: atlas.id, column: column, row: row),
      draft.defaultMaterialId!,
    );
    draft = draft.copyWith(rules: rules);
    error = null;
    _resolve();
  }

  void example() {
    scratch.clear();
    for (var mask = 0; mask < 16; mask++) {
      final x = 2 + mask % 4 * 4;
      final y = 2 + mask ~/ 4 * 4;
      scratch.add(GridPos(x: x, y: y));
      if (mask & 1 != 0) scratch.add(GridPos(x: x, y: y - 1));
      if (mask & 2 != 0) scratch.add(GridPos(x: x + 1, y: y));
      if (mask & 4 != 0) scratch.add(GridPos(x: x, y: y + 1));
      if (mask & 8 != 0) scratch.add(GridPos(x: x - 1, y: y));
    }
    _resolve();
  }

  void paint(GridPos position, {bool erase = false}) {
    if (position.x < 0 ||
        position.y < 0 ||
        position.x >= scratchSize ||
        position.y >= scratchSize) {
      return;
    }
    erase ? scratch.remove(position) : scratch.add(position);
    _resolve();
  }

  void inspect(GridPos position) {
    final result = resolved[position.y * scratchSize + position.x];
    final index = draft.rules.indexWhere((rule) => rule.id == result.ruleId);
    if (index >= 0) selectedRule = index;
  }

  void _resolve() {
    final resolver = PreparedSmartTileResolver(
      preset: previewPreset,
      materials: draft.materials,
    );
    resolved = List.generate(scratchSize * scratchSize, (index) {
      final x = index % scratchSize, y = index ~/ scratchSize;
      return resolver.resolve(
        context: SmartTileCellContext.fromCellGrid(
          width: scratchSize,
          height: scratchSize,
          x: x,
          y: y,
          materialAt: (x, y) => scratch.contains(GridPos(x: x, y: y))
              ? draft.defaultMaterialId
              : null,
        ),
        x: x,
        y: y,
      );
    });
  }

  Future<bool> save(
    MutateTerrainResource mutate, {
    bool publish = false,
  }) async {
    if (busy) return false;
    if (publish && !complete) {
      error = 'Associez les 16 raccords avant de publier.';
      return false;
    }
    busy = true;
    error = null;
    final snapshot = draft;
    try {
      manifest = await mutate('smart_tile.preset.draft.upsert', {
        'draft': snapshot.toJson(),
      });
      _saved = snapshot;
      if (publish) {
        manifest = await mutate('smart_tile.preset.publish', {
          'draftId': snapshot.id,
        });
      }
      return true;
    } catch (failure) {
      error = failure.toString();
      return false;
    } finally {
      busy = false;
    }
  }
}
