import 'dart:math' as math;
import 'package:map_core/map_core_domain.dart';
import '../../../features/characters/application/character_editing_commands.dart';
import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_editing_commands.dart';
import 'map_workspace_view_state.dart';

class MapCharacterGesture {
  MapCharacterGesture._(
    this.document,
    this.project,
    this.view,
    this.origin,
    this.entity,
    this.zone,
  ) : source = document.current,
      end = origin;
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceViewState view;
  final GridPos origin;
  final MapData source;
  final MapEntity? entity;
  final bool zone;
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
    if (view.tool == StudioMapTool.zone) {
      return MapCharacterGesture._(document, project, view, origin, null, true);
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
    if (position == null) return document.current;
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
    if (zone) return rectangle;
    final position = destination;
    if (position != null) {
      CharacterEditingCommands(document, project).move(entity!.id, position);
    }
    return null;
  }
}
