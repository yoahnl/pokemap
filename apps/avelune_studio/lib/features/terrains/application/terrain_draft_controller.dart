import 'package:map_core/map_core_domain.dart';

import '../domain/terrain_connections.dart';
import '../domain/terrain_draft_compatibility.dart';
import '../domain/terrain_spatial_draft.dart';

part 'terrain_draft_save.dart';
part 'terrain_draft_scratch.dart';
part 'terrain_draft_spatial_edits.dart';

typedef MutateTerrainResource = Future<ProjectManifest> Function(
  String actionId,
  Map<String, Object?> parameters,
);

class TerrainDraftController {
  TerrainDraftController({
    required this.manifest,
    required ProjectSmartTileAtlas atlas,
    required String id,
    String name = 'Nouveau terrain',
  }) : draft = createTerrainDraft(atlas, id, name) {
    example();
  }

  TerrainDraftController.resume({required this.manifest, required this.draft}) {
    final problem = terrainDraftCompatibilityProblem(manifest, draft);
    if (problem != null) throw StateError(problem);
    _saved = draft;
    example();
  }
  TerrainDraftController.spatial({
    required this.manifest,
    required ProjectModel3dEntry model,
    required String id,
  }) : draft = createSpatialTerrainDraft(model, id) {
    final problem = terrainDraftCompatibilityProblem(manifest, draft);
    if (problem != null) throw StateError(problem);
    example();
  }

  ProjectManifest manifest;
  ProjectSmartTileAuthoringDraft draft;
  ProjectSmartTileAuthoringDraft? _saved;
  final _undo = <ProjectSmartTileAuthoringDraft>[];
  final _redo = <ProjectSmartTileAuthoringDraft>[];
  static const historyLimit = 64;
  int selectedRule = 0;
  bool busy = false;
  String? error;
  bool publicationFailedAfterSave = false;
  static const scratchSize = 17;
  final Set<GridPos> scratch = {};
  List<SmartTileResolution> resolved = [];

  bool get dirty => draft != _saved;
  bool get canUndo => _undo.isNotEmpty && !busy;
  bool get canRedo => _redo.isNotEmpty && !busy;
  int get assignedCount =>
      draft.rules.where((r) => r.candidates.isNotEmpty).length;
  List<int> get missingRules => [
    for (var i = 0; i < draft.rules.length; i++)
      if (draft.rules[i].candidates.isEmpty) i,
  ];
  ProjectSmartTilePreset? get publishedPreset => manifest
      .smartTileCatalog
      .presets
      .where((preset) => preset.id == draft.targetPresetId)
      .firstOrNull;
  bool get hasUnpublishedChanges => publishedPreset != previewPreset;
  String get statusLabel => publicationFailedAfterSave
      ? 'Brouillon enregistré ; publication non effectuée'
      : dirty
      ? 'Modifications non enregistrées'
      : publishedPreset == null
      ? 'Brouillon enregistré'
      : hasUnpublishedChanges
      ? 'Modifications non publiées'
      : 'Version publiée';
  bool get complete => draft.rules.every((rule) => rule.candidates.isNotEmpty);
  bool get spatial => terrainDraftIsSpatial(draft);
  bool get uniform => spatial && draft.rules.length == 1;
  SmartTileVisualPart? partFor(int rule) =>
      rule < 0 || rule >= draft.rules.length
      ? null
      : draft.rules[rule].candidates.firstOrNull?.parts.firstOrNull;
  ProjectSmartTileAtlas get atlas =>
      draft.atlases.firstWhere((a) => a.id == draft.primaryAtlasId);
  SmartTileFrameRef? frameFor(int rule) {
    if (rule < 0 || rule >= draft.rules.length) return null;
    final parts = draft.rules[rule].candidates.firstOrNull?.parts;
    final source = parts?.firstOrNull?.source;
    return source is SmartTileFrameSource ? source.frame : null;
  }

  ProjectSmartTilePreset get previewPreset => terrainDraftPreset(draft);

  void _record(ProjectSmartTileAuthoringDraft next) {
    if (busy || next == draft) return;
    _undo.add(draft);
    if (_undo.length > historyLimit) _undo.removeAt(0);
    _redo.clear();
    draft = next;
    error = null;
    publicationFailedAfterSave = false;
    _resolve();
  }

  void undo() {
    if (!canUndo) return;
    _redo.add(draft);
    draft = _undo.removeLast();
    selectedRule = selectedRule.clamp(0, draft.rules.length - 1);
    error = null;
    publicationFailedAfterSave = false;
    _resolve();
  }

  void redo() {
    if (!canRedo) return;
    _undo.add(draft);
    draft = _redo.removeLast();
    selectedRule = selectedRule.clamp(0, draft.rules.length - 1);
    error = null;
    publicationFailedAfterSave = false;
    _resolve();
  }

  void rename(String name) {
    _record(
      draft.copyWith(
        name: name.trim().isEmpty ? 'Nouveau terrain' : name.trim(),
      ),
    );
  }

  void assignSelectedFrame(
    TilesetSourceRect source, {
    bool advanceMissing = false,
  }) {
    final wasMissing = frameFor(selectedRule) == null;
    assign(source.x, source.y);
    if (advanceMissing && wasMissing) selectNextMissing();
  }

  void assignSelectedModel(
    ProjectModel3dEntry source, {
    bool advanceMissing = false,
  }) {
    final wasMissing = partFor(selectedRule) == null;
    assignModel(source);
    if (advanceMissing && wasMissing) selectNextMissing();
  }

  void assign(int column, int row) {
    atlas.sourceRectFor(column: column, row: row);
    final expanded = selectedRule >= 16 && draft.rules.length == 16;
    final rules = <SmartTileRule>[
      ...draft.rules,
      if (expanded)
        for (var index = 16; index < 20; index++)
          terrainOuterCornerRule(index, null, draft.defaultMaterialId!),
    ];
    final frame = SmartTileFrameRef(
      atlasId: atlas.id,
      column: column,
      row: row,
    );
    rules[selectedRule] = selectedRule < 16
        ? terrainConnectionRule(selectedRule, frame, draft.defaultMaterialId!)
        : terrainOuterCornerRule(selectedRule, frame, draft.defaultMaterialId!);
    _record(
      draft.copyWith(
        rules: rules,
        topology: expanded ? SmartTileTopology.blob8 : draft.topology,
        templateHint: expanded
            ? SmartTileTemplateHint.blob47
            : draft.templateHint,
        guideId: expanded ? 'avelune-path20-v1' : draft.guideId,
      ),
    );
  }

  bool setSelectedModelAnimation(int? animationIndex) =>
      _setSelectedModelAnimation(animationIndex);

  void assignModel(
    ProjectModel3dEntry model, {
    bool all = false,
    double scale = 1,
    double? offsetX,
    double offsetY = 0,
    double? offsetZ,
    int quarterTurns = 0,
    int? animationIndex,
    bool changeAnimation = false,
  }) => _assignModel(
    model,
    all: all,
    scale: scale,
    offsetX: offsetX,
    offsetY: offsetY,
    offsetZ: offsetZ,
    quarterTurns: quarterTurns,
    animationIndex: animationIndex,
    changeAnimation: changeAnimation,
  );

  void setSpatialConnections(bool connections) =>
      _setSpatialConnections(connections);

  void removeAssignment([int? rule]) {
    final index = rule ?? selectedRule;
    if (index >= draft.rules.length) return;
    final rules = List<SmartTileRule>.of(draft.rules);
    rules[index] = spatial
        ? rules[index].copyWith(candidates: [])
        : index < 16
        ? terrainConnectionRule(index, null, draft.defaultMaterialId!)
        : terrainOuterCornerRule(index, null, draft.defaultMaterialId!);
    _record(draft.copyWith(rules: rules));
  }

  void selectNextMissing() {
    for (var step = 1; step <= draft.rules.length; step++) {
      final index = (selectedRule + step) % draft.rules.length;
      if (draft.rules[index].candidates.isEmpty) {
        selectedRule = index;
        return;
      }
    }
  }

  void clearScratch() => _clearScratch();

  void example() => _example();

  void paint(GridPos position, {bool erase = false}) =>
      _paint(position, erase: erase);

  void paintLine(GridPos from, GridPos to, {bool erase = false}) =>
      _paintLine(from, to, erase: erase);

  void inspect(GridPos position) => _inspect(position);

  Future<bool> save(MutateTerrainResource mutate, {bool publish = false}) =>
      _save(mutate, publish: publish);
}
