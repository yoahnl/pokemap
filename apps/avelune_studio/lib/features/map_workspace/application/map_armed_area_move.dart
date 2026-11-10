import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/trigger_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';

class MapArmedAreaMove {
  const MapArmedAreaMove(this.document, this.project, this.target);
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapSelectionTarget target;

  MapRect? get area => switch (target.family) {
    MapSelectionFamily.zone => GameplayZoneEditingCommands(
      document,
      project,
    ).selected(target.id)?.area,
    MapSelectionFamily.trigger => TriggerEditingCommands(
      document,
      project,
    ).selected(target.id)?.area,
    _ => null,
  };

  MapRect? previewAt(GridSize bounds, GridPos delta) {
    final current = area;
    if (current == null) return null;
    return MapRect(
      pos: GridPos(
        x: (current.pos.x + delta.x).clamp(
          0,
          bounds.width - current.size.width,
        ),
        y: (current.pos.y + delta.y).clamp(
          0,
          bounds.height - current.size.height,
        ),
      ),
      size: current.size,
    );
  }

  void commit(GridPos position) {
    final current = area;
    if (current == null || current.pos == position) return;
    try {
      if (target.family == MapSelectionFamily.zone) {
        GameplayZoneEditingCommands(
          document,
          project,
        ).move(target.id, position);
      } else {
        TriggerEditingCommands(document, project).move(target.id, position);
      }
    } on ValidationException catch (error) {
      document.error = error.message;
    }
  }
}
