import 'dart:math' as math;

import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/trigger_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_armed_area_move.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';

part 'map_character_gesture_start.dart';

class MapCharacterGesture {
  MapCharacterGesture._(
    this.document,
    this.project,
    this.view,
    this.origin,
    this.entity,
    this.zone, {
    this.warp,
    this.armed,
  }) : source = document.current,
       end = origin;
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceEditingState view;
  final GridPos origin;
  final MapData source;
  final MapEntity? entity;
  final bool zone;
  final MapWarp? warp;

  final MapSelectionTarget? armed;
  GridPos end;

  static MapCharacterGesture? start({
    required EditableMapDocument document,
    required ProjectManifest project,
    required MapWorkspaceEditingState view,
    required GridPos origin,
  }) => _startMapCharacterGesture(
    document: document,
    project: project,
    view: view,
    origin: origin,
  );

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

  MapArmedAreaMove? get _areaMove {
    final target = armed;
    return target == null ? null : MapArmedAreaMove(document, project, target);
  }

  MapRect? get armedArea => _areaMove?.previewAt(
    source.size,
    GridPos(x: end.x - origin.x, y: end.y - origin.y),
  );

  bool get movesArea => _areaMove?.area != null;

  bool get isLocked {
    final target = armed;
    if (target != null &&
        view.isUnavailable(document, target.family, target.id)) {
      return true;
    }
    if (entity != null && document.isElementLocked('entity', entity!.id)) {
      return true;
    }
    return warp != null && document.isElementLocked('warp', warp!.id);
  }

  MapRect? commit() {
    if (document.current != source || isLocked) return null;
    final move = _areaMove;
    if (move != null) {
      view.pendingMove = null;
      final area = armedArea;
      if (area != null) {
        move.commit(area.pos);
        return null;
      }
    }
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
            view.select(document, MapSelectionFamily.trigger, existing.id);
            return null;
          }
        }
        return area;
      }
      final commands = GameplayZoneEditingCommands(document, project);
      final existing = single ? commands.at(area.pos).firstOrNull : null;
      final zone = existing ?? commands.place(view.zoneKind, area);
      view.select(document, MapSelectionFamily.zone, zone.id);
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
