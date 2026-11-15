import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';

import 'editable_map_document.dart';
import 'gameplay_zone_editing_commands.dart';
import 'map_context_command_runner.dart';
import 'map_context_deletion_guard.dart';
import 'map_context_menu_actions.dart';
import 'map_context_menu_model.dart';
import 'map_editing_commands.dart';
import 'map_element_clipboard.dart';
import 'map_entity_editing_commands.dart';
import 'map_failure_message.dart';
import 'map_selection_context.dart';
import 'map_workspace_editing_state.dart';
import 'spatial_model_editing_commands.dart';
import 'trigger_editing_commands.dart';
import 'warp_editing_commands.dart';

export 'map_element_clipboard.dart';

part 'map_selection_insertion.dart';

class MapSelectionCommands {
  MapSelectionCommands(this.document, this.project, {this.historyGuard});
  final EditableMapDocument document;
  final ProjectManifest project;
  final String? Function(MapData before, MapData after)? historyGuard;
  static int _sequence = 0;

  MapElementClipboard copy(List<MapSelectionTarget> targets) =>
      copyMapElements(document, project, targets);

  List<MapSelectionTarget> paste(MapElementClipboard clipboard, {GridPos? at}) {
    final origin = clipboard.origin;
    final (dx, dy) = at != null
        ? (at.x - origin.x, at.y - origin.y)
        : clipboard.sourceMapId == document.current.id && !clipboard.cut
        ? (1, 1)
        : (0, 0);
    return _batch(
      (scratch) => [
        for (final item in clipboard.items) _insert(scratch, item, dx, dy),
      ],
    );
  }

  List<MapSelectionTarget> duplicate(List<MapSelectionTarget> targets) {
    final clipboard = copy(targets);
    return _batch(
      (scratch) => [
        for (final item in clipboard.items) _insert(scratch, item, 1, 1),
      ],
    );
  }

  MapElementClipboard cut(
    List<MapSelectionTarget> targets, {
    MapContextDeletionGuard? guard,
  }) {
    final copied = copy(targets);
    delete(targets, guard: guard);
    return MapElementClipboard(
      sourceMapId: copied.sourceMapId,
      items: copied.items,
      cut: true,
    );
  }

  void delete(
    List<MapSelectionTarget> targets, {
    MapContextDeletionGuard? guard,
  }) => _batch((scratch) {
    for (final target in targets) {
      final placement = locateMapContextTarget(
        scratch,
        project,
        contextFamilyOf(target.family),
        target.id,
      );
      if (placement == null) continue;
      final refusal =
          guard?.call(placement.target) ??
          MapContextCommandRunner(
            MapContextActionContext(
              document: scratch,
              project: project,
              position: placement.at,
            ),
          ).run(MapContextCommand.delete, placement.target) ??
          scratch.error;
      if (refusal != null) throw StateError(refusal);
    }
  });

  void move(List<MapSelectionTarget> targets, int dx, int dy) =>
      translate(targets, dx: dx.toDouble(), dz: dy.toDouble());

  void translate(
    List<MapSelectionTarget> targets, {
    double dx = 0,
    double dz = 0,
    double elevation = 0,
  }) => _batch((scratch) {
    final cells = GridPos(x: dx.round(), y: dz.round());
    for (final target in targets) {
      if (target.family == MapSelectionFamily.decor) {
        final spatial = SpatialModelEditingCommands(scratch, project);
        final instance = spatial.selected(target.id);
        if (instance != null) {
          spatial.update(
            target.id,
            x: instance.position.x + dx,
            z: instance.position.z + dz,
            heightOffset: spatial.elevationOf(instance) + elevation,
          );
          continue;
        }
      }
      if (cells.x != 0 || cells.y != 0) _moveCells(scratch, target, cells);
      if (scratch.error case final error?) throw StateError(error);
    }
  });

  void rotate(List<MapSelectionTarget> targets, double degrees) {
    final spatial = SpatialModelEditingCommands(document, project);
    final rotatable = [
      for (final target in targets)
        if (target.family == MapSelectionFamily.decor &&
            spatial.selected(target.id) != null)
          target,
    ];
    if (rotatable.isEmpty) {
      throw StateError('Seuls les décors 3D peuvent tourner.');
    }
    _batch((scratch) {
      final commands = SpatialModelEditingCommands(scratch, project);
      for (final target in rotatable) {
        final instance = commands.selected(target.id)!;
        commands.update(
          target.id,
          rotation: (instance.rotationDegrees + degrees) % 360,
        );
      }
    });
  }

  T _batch<T>(T Function(EditableMapDocument scratch) apply) {
    final before = document.current;
    final scratch =
        EditableMapDocument(
            MapWorkspaceDocument(
              map: before,
              mapId: document.base.mapId,
              revision: document.base.revision,
            ),
          )
          ..editor = document.editor
          ..modelDeletionProblem = document.modelDeletionProblem;
    final T result;
    try {
      result = apply(scratch);
    } on StateError {
      rethrow;
    } catch (failure) {
      throw StateError(mapFailureMessage(failure));
    }
    final problem = historyGuard?.call(before, scratch.current);
    if (problem != null) throw StateError(problem);
    document.commit(scratch.current);
    return result;
  }
}
