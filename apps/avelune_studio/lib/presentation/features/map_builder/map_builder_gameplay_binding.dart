import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_field_obstacle_eligibility.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_connection_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_connection_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/domain/studio_search_text.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';

part 'map_builder_gameplay_obstacles.dart';
part 'map_builder_gameplay_passages.dart';
part 'map_builder_gameplay_zones.dart';

const mapBuilderGameplayRubrics = {
  'connections',
  'movement',
  'encounters',
  'spawns',
  'fieldObjects',
};

const mapBuilderMovementZoneKinds = {
  GameplayZoneKind.movement,
  GameplayZoneKind.movementEffect,
};

MapConnectionPort? configuredConnectionPort(MapConnectionPort Function() read) {
  try {
    return read();
  } on Object {
    return null;
  }
}

class MapBuilderGameplayBinding {
  MapBuilderGameplayBinding({
    required this.maps,
    required this.view,
    required MapConnectionPort? port,
    required bool Function() isActive,
    required this.changed,
    required this.labels,
    this.entityDeletionProblem,
    this.storyProject,
  }) : links = MapWorkspaceConnectionActions(
         controller: maps,
         port: port,
         isActive: isActive,
         changed: changed,
       );

  final MapWorkspaceController maps;
  final MapWorkspaceEditingState? Function() view;
  final void Function() changed;
  final AppLocalizations Function() labels;
  final String? Function(String entityId)? entityDeletionProblem;
  final ProjectManifest Function(ProjectManifest project)? storyProject;
  final MapWorkspaceConnectionActions links;
  ({String mapId, MapConnectionDirection? direction})? _connection;
  ({String mapId, Set<String> known})? _warpDraft;
  ({String mapId, Set<String> known})? _spawnDraft;
  ({String mapId, Set<String> known})? _zoneDraft;
  ({String mapId, Set<String> known, FieldObstacleKind kind})? _obstacleDraft;
  bool shown = false;
  String rubric = 'connections';
  String query = '';
  String? warpError;
  String? entityError;
  String? zoneError;
  String? encounterTablesError;

  MapData? get map => maps.active?.current;

  String mapName(String id) =>
      maps.project?.maps.where((entry) => entry.id == id).firstOrNull?.name ??
      labels().mapMissing;

  bool get spatial => map?.spatialScene != null;

  bool get placing => switch (view()?.tool) {
    StudioMapTool.warp ||
    StudioMapTool.spawn ||
    StudioMapTool.collisionPaint ||
    StudioMapTool.collisionErase ||
    StudioMapTool.encounterPaint ||
    StudioMapTool.encounterErase ||
    StudioMapTool.fieldObstacle ||
    StudioMapTool.gameplayZone => true,
    _ => false,
  };

  StudioMapTool? get tool => view()?.tool;

  void openRubric(String id) {
    if (id == rubric) return;
    final document = maps.active;
    if (document != null) view()?.clearSelection(document);
    leave();
    rubric = id;
    query = '';
    reconcile();
    changed();
    if (id == 'encounters') unawaited(_loadEncounterTables());
  }

  void search(String value) {
    query = value;
    changed();
  }

  void _clearDrafts() {
    _obstacleDraft = null;
    _connection = null;
    _warpDraft = null;
    _spawnDraft = null;
    _zoneDraft = null;
  }

  void release() {
    final state = view();
    if (state == null || !placing) return;
    state.tool = StudioMapTool.select;
    changed();
  }

  void leave() {
    _obstacleDraft = null;
    _warpDraft = null;
    _spawnDraft = null;
    _zoneDraft = null;
    view()
      ?..revealCollisions = false
      ..revealedZones = const {};
    _connection = null;
    release();
  }

  void reconcile() {
    view()
      ?..revealCollisions = shown && rubric == 'movement'
      ..revealedZones = !shown
          ? const {}
          : switch (rubric) {
              'movement' => mapBuilderMovementZoneKinds,
              'encounters' => const {GameplayZoneKind.encounter},
              _ => const {},
            };
    final zoneDraft = _zoneDraft;
    final drawn = this.map;
    if (zoneDraft != null &&
        drawn != null &&
        zoneDraft.mapId == drawn.id &&
        (selectedZone != null ||
            drawn.gameplayZones.any(
              (zone) => !zoneDraft.known.contains(zone.id),
            ))) {
      _zoneDraft = null;
      view()?.tool = StudioMapTool.select;
    }
    final obstacleDraft = _obstacleDraft;
    final dropped = this.map;
    if (obstacleDraft != null &&
        dropped != null &&
        obstacleDraft.mapId == dropped.id &&
        dropped.entities.any(
          (entity) => !obstacleDraft.known.contains(entity.id),
        )) {
      _obstacleDraft = null;
      view()?.tool = StudioMapTool.select;
    }
    final spawnDraft = _spawnDraft;
    final placed = this.map;
    if (spawnDraft != null &&
        placed != null &&
        spawnDraft.mapId == placed.id &&
        placed.entities.any(
          (entity) => !spawnDraft.known.contains(entity.id),
        )) {
      _spawnDraft = null;
      view()?.tool = StudioMapTool.select;
    }
    final draft = _warpDraft;
    final map = this.map;
    if (draft == null || map == null || draft.mapId != map.id) return;
    if (map.warps.any((warp) => !draft.known.contains(warp.id))) {
      _warpDraft = null;
      view()?.tool = StudioMapTool.select;
    }
  }
}

class _GuardedEntityCommands extends MapEntityEditingCommands {
  _GuardedEntityCommands(super.document, super.project, this._problem);

  final String? Function(String entityId)? _problem;

  @override
  String? deletionProblem(String id) =>
      _problem?.call(id) ?? super.deletionProblem(id);
}
