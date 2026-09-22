import 'dart:math' as math;
import 'package:map_core/map_core_domain.dart';
import '../../../features/characters/application/character_editing_commands.dart';
import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_editing_commands.dart';
import '../../../features/map_workspace/application/gameplay_zone_editing_commands.dart';
import '../../../features/map_workspace/application/map_entity_editing_commands.dart';
import '../../../features/map_workspace/application/trigger_editing_commands.dart';
import '../../../features/map_workspace/application/warp_editing_commands.dart';
import 'map_workspace_view_state.dart';

class MapCharacterGesture {
  MapCharacterGesture._(
    this.document,
    this.project,
    this.view,
    this.origin,
    this.entity,
    this.zone, {
    this.warp,
  }) : source = document.current,
       end = origin;
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceViewState view;
  final GridPos origin;
  final MapData source;
  final MapEntity? entity;
  final bool zone;
  final MapWarp? warp;
  GridPos end;

  static MapCharacterGesture? start({
    required EditableMapDocument document,
    required ProjectManifest project,
    required MapWorkspaceViewState view,
    required GridPos origin,
  }) {
    final commands = CharacterEditingCommands(document, project);
    final size = document.current.size;
    if (origin.x < 0 ||
        origin.y < 0 ||
        origin.x >= size.width ||
        origin.y >= size.height) {
      return null;
    }
    if (view.tool == StudioMapTool.zone ||
        view.tool == StudioMapTool.gameplayZone) {
      return MapCharacterGesture._(document, project, view, origin, null, true);
    }
    final placed = switch (view.tool) {
      StudioMapTool.spawn => MapEntityKind.spawn,
      StudioMapTool.sign => MapEntityKind.sign,
      _ => null,
    };
    if (placed != null) {
      final entity = MapEntityEditingCommands(
        document,
        project,
      ).place(placed, origin);
      view
        ..clearSelection()
        ..selectedPlacementId = entity.id;
      document.selectedId = null;
      document.stackPosition = origin;
      return MapCharacterGesture._(document, project, view, origin, null, false);
    }
    if (view.tool == StudioMapTool.warp && view.warpDestination != null) {
      final warp = WarpEditingCommands(
        document,
        project,
      ).place(view.warpDestination!, origin);
      view.selectedWarpId = warp.id;
      view.selectedEntityId = null;
      document.selectedId = null;
      document.stackPosition = origin;
      return MapCharacterGesture._(document, project, view, origin, null, false);
    }
    if (view.tool == StudioMapTool.character && view.character != null) {
      final entity = commands.place(view.character!, origin);
      view.selectedEntityId = entity.id;
      document.selectedId = null;
      document.stackPosition = origin;
      return MapCharacterGesture._(
        document,
        project,
        view,
        origin,
        null,
        false,
      );
    }
    if (view.tool != StudioMapTool.select) return null;
    final hits = commands.at(origin);
    if (hits.isEmpty) {
      final placements = MapEntityEditingCommands(document, project).at(origin);
      final marker =
          placements
              .where((entry) => entry.id == view.selectedPlacementId)
              .firstOrNull ??
          placements.firstOrNull;
      if (marker != null) {
        view
          ..clearSelection()
          ..selectedPlacementId = marker.id;
        document.selectedId = null;
        document.stackPosition = origin;
        return MapCharacterGesture._(
          document,
          project,
          view,
          origin,
          marker,
          false,
        );
      }
      final warps = WarpEditingCommands(document, project).at(origin);
      final chosen =
          warps.where((entry) => entry.id == view.selectedWarpId).firstOrNull ??
          warps.firstOrNull;
      if (chosen != null) {
        view.selectedWarpId = chosen.id;
        view.selectedEntityId = null;
        document.selectedId = null;
        document.stackPosition = origin;
        return MapCharacterGesture._(
          document,
          project,
          view,
          origin,
          null,
          false,
          warp: chosen,
        );
      }
    }
    final selected = hits
        .where((entry) => entry.id == view.selectedEntityId)
        .firstOrNull;
    final selectedDecorHere =
        document.selected != null &&
        MapEditingCommands(
          document,
          project,
        ).stack(origin).any((entry) => entry.id == document.selectedId);
    if (hits.isEmpty || (selected == null && selectedDecorHere)) {
      return null;
    }
    final entity = selected ?? hits.first;
    view.selectedEntityId = entity.id;
    document.selectedId = null;
    document.stackPosition = origin;
    return MapCharacterGesture._(
      document,
      project,
      view,
      origin,
      entity,
      false,
    );
  }

  MapRect get rectangle => MapRect(
    pos: GridPos(x: math.min(origin.x, end.x), y: math.min(origin.y, end.y)),
    size: GridSize(
      width: (origin.x - end.x).abs() + 1,
      height: (origin.y - end.y).abs() + 1,
    ),
  );

  GridPos? get destination {
    final travelling = warp;
    if (travelling != null) {
      return GridPos(
        x: (travelling.pos.x + end.x - origin.x).clamp(
          0,
          source.size.width - 1,
        ),
        y: (travelling.pos.y + end.y - origin.y).clamp(
          0,
          source.size.height - 1,
        ),
      );
    }
    final moving = entity;
    if (moving == null) return null;
    return GridPos(
      x: (moving.pos.x + end.x - origin.x).clamp(
        0,
        source.size.width - moving.size.width,
      ),
      y: (moving.pos.y + end.y - origin.y).clamp(
        0,
        source.size.height - moving.size.height,
      ),
    );
  }

  MapData get preview {
    final position = destination;
    if (position == null || entity == null) return document.current;
    return moveEntityOnMap(source, entityId: entity!.id, pos: position);
  }

  void move(GridPos cell) {
    end = GridPos(
      x: cell.x.clamp(0, source.size.width - 1),
      y: cell.y.clamp(0, source.size.height - 1),
    );
  }

  MapRect? commit() {
    if (document.current != source) return null;
    if (zone) {
      final area = rectangle;
      final single = area.size.width == 1 && area.size.height == 1;
      if (view.tool != StudioMapTool.gameplayZone) {
        if (single) {
          final existing = TriggerEditingCommands(
            document,
            project,
          ).at(area.pos).firstOrNull;
          if (existing != null) {
            view
              ..clearSelection()
              ..selectedTriggerId = existing.id;
            return null;
          }
        }
        return area;
      }
      final commands = GameplayZoneEditingCommands(document, project);
      final existing = single ? commands.at(area.pos).firstOrNull : null;
      view
        ..clearSelection()
        ..selectedZoneId = (existing ?? commands.place(view.zoneKind, area)).id;
      return null;
    }
    final position = destination;
    if (position == null) return null;
    final travelling = warp;
    if (travelling != null) {
      if (position != travelling.pos) {
        WarpEditingCommands(document, project).move(travelling.id, position);
      }
      return null;
    }
    CharacterEditingCommands(document, project).move(entity!.id, position);
    return null;
  }
}
