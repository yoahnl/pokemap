import 'package:map_core/map_core_domain.dart';

import '../domain/terrain_connections.dart';
import '../domain/terrain_draft_compatibility.dart';

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
  }) : draft = createTerrainDraft(atlas, id, name) {
    example();
  }

  TerrainDraftController.resume({required this.manifest, required this.draft}) {
    final problem = terrainDraftCompatibilityProblem(manifest, draft);
    if (problem != null) throw StateError(problem);
    _saved = draft;
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
    for (var i = 0; i < 16; i++)
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
  ProjectSmartTileAtlas get atlas =>
      draft.atlases.firstWhere((a) => a.id == draft.primaryAtlasId);
  SmartTileFrameRef? frameFor(int rule) {
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
    error = null;
    publicationFailedAfterSave = false;
    _resolve();
  }

  void redo() {
    if (!canRedo) return;
    _undo.add(draft);
    draft = _redo.removeLast();
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

  void assign(int column, int row) {
    atlas.sourceRectFor(column: column, row: row);
    final rules = List<SmartTileRule>.of(draft.rules);
    rules[selectedRule] = terrainConnectionRule(
      selectedRule,
      SmartTileFrameRef(atlasId: atlas.id, column: column, row: row),
      draft.defaultMaterialId!,
    );
    _record(draft.copyWith(rules: rules));
  }

  void removeAssignment([int? rule]) {
    final index = rule ?? selectedRule;
    final rules = List<SmartTileRule>.of(draft.rules);
    rules[index] = terrainConnectionRule(index, null, draft.defaultMaterialId!);
    _record(draft.copyWith(rules: rules));
  }

  void selectNextMissing() {
    for (var step = 1; step <= 16; step++) {
      final index = (selectedRule + step) % 16;
      if (draft.rules[index].candidates.isEmpty) {
        selectedRule = index;
        return;
      }
    }
  }

  void clearScratch() {
    scratch.clear();
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
    if (!_inside(position)) return;
    erase ? scratch.remove(position) : scratch.add(position);
    _resolve();
  }

  bool _inside(GridPos p) =>
      p.x >= 0 && p.y >= 0 && p.x < scratchSize && p.y < scratchSize;

  void paintLine(GridPos from, GridPos to, {bool erase = false}) {
    if (!_inside(from) || !_inside(to)) return;
    final dx = to.x - from.x, dy = to.y - from.y;
    final steps = dx.abs() > dy.abs() ? dx.abs() : dy.abs();
    for (var step = 0; step <= steps; step++) {
      final p = steps == 0
          ? from
          : GridPos(
              x: (from.x + dx * step / steps).round(),
              y: (from.y + dy * step / steps).round(),
            );
      erase ? scratch.remove(p) : scratch.add(p);
    }
    _resolve();
  }

  void inspect(GridPos position) {
    if (!scratch.contains(position)) return;
    final x = position.x, y = position.y;
    selectedRule =
        (scratch.contains(GridPos(x: x, y: y - 1)) ? 1 : 0) |
        (scratch.contains(GridPos(x: x + 1, y: y)) ? 2 : 0) |
        (scratch.contains(GridPos(x: x, y: y + 1)) ? 4 : 0) |
        (scratch.contains(GridPos(x: x - 1, y: y)) ? 8 : 0);
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
    if (publishedPreset case final preset?) {
      final problem = terrainPresetCompatibilityProblem(manifest, preset);
      if (problem != null) {
        error = problem;
        return false;
      }
      draft = draft.copyWith(sourcePresetId: draft.targetPresetId);
    }
    if (publish && !complete) {
      error = 'Associez les 16 raccords avant de publier.';
      return false;
    }
    busy = true;
    error = null;
    publicationFailedAfterSave = false;
    final snapshot = draft;
    var saved = false;
    try {
      final canonical = manifest.smartTileCatalog.drafts
          .where((d) => d.id == snapshot.id)
          .firstOrNull;
      if (_saved != snapshot || canonical != snapshot || !publish) {
        manifest = await mutate('smart_tile.preset.draft.upsert', {
          'draft': snapshot.toJson(),
        });
        _saved =
            manifest.smartTileCatalog.drafts
                .where((d) => d.id == snapshot.id)
                .firstOrNull ??
            snapshot;
        if (draft == snapshot) draft = _saved!;
      }
      saved = true;
      if (publish) {
        manifest = await mutate('smart_tile.preset.publish', {
          'draftId': snapshot.id,
        });
        if (draft == _saved) {
          draft = draft.copyWith(sourcePresetId: draft.targetPresetId);
          _saved = draft;
        }
      }
      return true;
    } catch (failure) {
      publicationFailedAfterSave = publish && saved;
      error = publicationFailedAfterSave
          ? 'Brouillon enregistré ; publication non effectuée\n$failure'
          : failure.toString();
      return false;
    } finally {
      busy = false;
    }
  }
}
