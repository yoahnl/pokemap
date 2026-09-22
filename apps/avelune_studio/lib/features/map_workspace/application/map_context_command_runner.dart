import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/trigger_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';

class MapContextNavigation {
  const MapContextNavigation({
    this.openResource,
    this.editResource,
    this.openInteraction,
    this.openDestination,
    this.openStoryZone,
    this.copyCoordinates,
    this.showProperties,
    this.startMove,
  });
  final void Function(ProjectElementEntry entry)? openResource;
  final void Function(ProjectElementEntry entry)? editResource;
  final void Function(MapEntity entity)? openInteraction;
  final void Function(ProjectMapEntry entry)? openDestination;
  final void Function(MapTrigger trigger)? openStoryZone;
  final void Function(String text)? copyCoordinates;
  final void Function()? showProperties;
  final void Function(MapContextTarget target)? startMove;
}

/// The single place where a context command turns into a mutation: the menu,
/// the inspector and the keyboard all end up in the same editing commands.
class MapContextCommandRunner {
  const MapContextCommandRunner(this.context, {this.navigation});
  final MapContextActionContext context;
  final MapContextNavigation? navigation;

  /// Re-reads the target and its availability before acting, then runs it.
  /// Returns the refusal to show, or null when the command went through.
  String? run(MapContextCommand command, MapContextTarget? target) {
    final present = target == null
        ? null
        : mapContextTargetsAt(
            context.document,
            context.project,
            context.position,
          ).where((item) => item.id == target.id).firstOrNull;
    if (target != null &&
        (present == null || target.mapId != context.document.current.id)) {
      return 'Cet élément n’est plus à cet endroit.';
    }
    final action = mapContextActionsFor(
      present,
      context,
    ).where((item) => item.command == command).firstOrNull;
    if (action == null) return 'Cette action n’est pas disponible ici.';
    if (!action.enabled) return action.unavailable;
    try {
      _execute(command, present);
    } on StateError catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    }
    return null;
  }

  void _execute(MapContextCommand command, MapContextTarget? target) {
    final document = context.document;
    final project = context.project;
    switch (command) {
      case MapContextCommand.properties:
        navigation?.showProperties?.call();
      case MapContextCommand.copyCoordinates:
        navigation?.copyCoordinates?.call(
          '${context.position.x}, ${context.position.y}',
        );
      case MapContextCommand.eraseTile:
        _eraseTile();
      case MapContextCommand.move:
        if (target != null) navigation?.startMove?.call(target);
      case MapContextCommand.bringForward:
        _selectDecor(target);
        MapEditingCommands(document, project).reorder(forward: true);
      case MapContextCommand.sendBackward:
        _selectDecor(target);
        MapEditingCommands(document, project).reorder(forward: false);
      case MapContextCommand.openResource:
      case MapContextCommand.editResource:
        final entry = _decorEntry(target);
        if (entry == null) return;
        command == MapContextCommand.openResource
            ? navigation?.openResource?.call(entry)
            : navigation?.editResource?.call(entry);
      case MapContextCommand.openInteraction:
        final entity = CharacterEditingCommands(
          document,
          project,
        ).selected(target?.id);
        if (entity != null) navigation?.openInteraction?.call(entity);
      case MapContextCommand.openDestination:
        final warp = WarpEditingCommands(
          document,
          project,
        ).selected(target?.id);
        final entry = project.maps
            .where((item) => item.id == warp?.targetMapId)
            .firstOrNull;
        if (entry == null) {
          throw StateError('La carte d’arrivée est introuvable.');
        }
        navigation?.openDestination?.call(entry);
      case MapContextCommand.openNarrativeDocument:
        final trigger = TriggerEditingCommands(
          document,
          project,
        ).selected(target?.id);
        if (trigger == null) throw StateError('Cette zone n’existe plus.');
        navigation?.openStoryZone?.call(trigger);
      case MapContextCommand.delete:
        _delete(target);
    }
  }

  void _selectDecor(MapContextTarget? target) {
    if (target?.family == MapContextFamily.decor) {
      context.document.selectedId = target!.id;
    }
  }

  ProjectElementEntry? _decorEntry(MapContextTarget? target) {
    final decor = context.document.current.placedElements
        .where((item) => item.id == target?.id)
        .firstOrNull;
    return context.project.elements
        .where((item) => item.id == decor?.elementId)
        .firstOrNull;
  }

  /// Erases the tile of the topmost visual layer only: never an entity, a zone
  /// or a whole stack of decors.
  void _eraseTile() {
    final before = context.document.current;
    final plan = buildMapVisualCompositionPlan(before).plan;
    final layers = plan?.visibleTileLayersInPaintOrder ?? const <TileLayer>[];
    for (final layer in layers.reversed) {
      if (layer.purpose != MapLayerPurpose.visual) continue;
      final erased = eraseTileOnLayer(
        before,
        layerId: layer.id,
        pos: context.position,
      );
      if (erased != before) {
        context.document.commit(erased);
        return;
      }
    }
    throw StateError('Aucune tuile à effacer sur cette case.');
  }

  void _delete(MapContextTarget? target) {
    if (target == null) return;
    final document = context.document;
    final project = context.project;
    switch (target.family) {
      case MapContextFamily.decor:
        document.selectedId = target.id;
        MapEditingCommands(document, project).deleteSelected();
      case MapContextFamily.character:
        CharacterEditingCommands(document, project).delete(target.id);
      case MapContextFamily.marker:
        MapEntityEditingCommands(
          document,
          project,
          draftGuard: context.referenceGuard,
        ).delete(target.id);
      case MapContextFamily.warp:
        WarpEditingCommands(document, project).delete(target.id);
      case MapContextFamily.zone:
        GameplayZoneEditingCommands(document, project).delete(target.id);
      case MapContextFamily.trigger:
        TriggerEditingCommands(document, project).delete(target.id);
      case MapContextFamily.cell:
        return;
    }
  }
}
