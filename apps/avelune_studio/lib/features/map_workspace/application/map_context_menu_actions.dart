import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/trigger_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';

class MapContextActionContext {
  const MapContextActionContext({
    required this.document,
    required this.project,
    required this.position,
    this.referenceGuard,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final GridPos position;
  final MapReferenceGuard? referenceGuard;
}

/// The actions a family really supports. An unsupported capability is absent,
/// a temporarily blocked one is present with its reason.
List<MapContextAction> mapContextActionsFor(
  MapContextTarget? target,
  MapContextActionContext context,
) {
  if (target == null) return _cellActions(context);
  return switch (target.family) {
    MapContextFamily.decor => _decorActions(target, context),
    MapContextFamily.character => _characterActions(target, context),
    MapContextFamily.marker => _markerActions(target, context),
    MapContextFamily.warp => _warpActions(target, context),
    MapContextFamily.zone => _zoneActions(target),
    MapContextFamily.trigger => _triggerActions(target, context),
    MapContextFamily.cell => _cellActions(context),
  };
}

List<MapContextAction> _cellActions(MapContextActionContext context) {
  final map = context.document.current;
  final erasable = map.layers.whereType<TileLayer>().any(
    (layer) => layer.purpose == MapLayerPurpose.visual,
  );
  return [
    const MapContextAction(
      MapContextCommand.copyCoordinates,
      'Copier les coordonnées',
    ),
    MapContextAction(
      MapContextCommand.eraseTile,
      'Effacer la tuile de cette case',
      unavailable: erasable
          ? null
          : 'Cette carte n’a aucun calque de tuiles à effacer ici.',
    ),
  ];
}

List<MapContextAction> _decorActions(
  MapContextTarget target,
  MapContextActionContext context,
) {
  final commands = MapEditingCommands(context.document, context.project);
  final known = context.project.elements.any(
    (entry) =>
        entry.id ==
        context.document.current.placedElements
            .where((item) => item.id == target.id)
            .firstOrNull
            ?.elementId,
  );
  return [
    const MapContextAction(MapContextCommand.properties, 'Propriétés'),
    MapContextAction(
      MapContextCommand.openResource,
      'Ouvrir sa ressource',
      unavailable: known ? null : 'La ressource de ce décor est introuvable.',
    ),
    MapContextAction(
      MapContextCommand.editResource,
      'Modifier sa ressource',
      unavailable: known ? null : 'La ressource de ce décor est introuvable.',
    ),
    const MapContextAction(MapContextCommand.move, 'Déplacer'),
    MapContextAction(
      MapContextCommand.bringForward,
      'Passer devant',
      unavailable: commands.reorderProblemAt(
        instanceId: target.id,
        at: context.position,
        forward: true,
      ),
    ),
    MapContextAction(
      MapContextCommand.sendBackward,
      'Passer derrière',
      unavailable: commands.reorderProblemAt(
        instanceId: target.id,
        at: context.position,
        forward: false,
      ),
    ),
    const MapContextAction(MapContextCommand.delete, 'Supprimer le décor'),
  ];
}

List<MapContextAction> _characterActions(
  MapContextTarget target,
  MapContextActionContext context,
) {
  final blocked = CharacterEditingCommands(
    context.document,
    context.project,
    draftGuard: context.referenceGuard,
  ).deletionProblem(target.id);
  return [
    const MapContextAction(MapContextCommand.properties, 'Propriétés'),
    const MapContextAction(
      MapContextCommand.openInteraction,
      'Écrire son interaction',
    ),
    const MapContextAction(MapContextCommand.move, 'Déplacer'),
    MapContextAction(
      MapContextCommand.delete,
      'Supprimer le personnage',
      unavailable: blocked,
    ),
  ];
}

List<MapContextAction> _markerActions(
  MapContextTarget target,
  MapContextActionContext context,
) {
  final blocked = MapEntityEditingCommands(
    context.document,
    context.project,
    draftGuard: context.referenceGuard,
  ).deletionProblem(target.id);
  return [
    const MapContextAction(MapContextCommand.properties, 'Propriétés'),
    const MapContextAction(MapContextCommand.move, 'Déplacer'),
    MapContextAction(
      MapContextCommand.delete,
      'Supprimer',
      unavailable: blocked,
    ),
  ];
}

List<MapContextAction> _warpActions(
  MapContextTarget target,
  MapContextActionContext context,
) {
  final commands = WarpEditingCommands(context.document, context.project);
  final warp = commands.selected(target.id);
  final problem = warp == null ? null : commands.destinationProblem(warp);
  return [
    const MapContextAction(MapContextCommand.properties, 'Propriétés'),
    const MapContextAction(MapContextCommand.move, 'Déplacer'),
    MapContextAction(
      MapContextCommand.openDestination,
      'Ouvrir la carte d’arrivée',
      unavailable: problem,
    ),
    const MapContextAction(MapContextCommand.delete, 'Supprimer le passage'),
  ];
}

List<MapContextAction> _zoneActions(MapContextTarget target) => [
  const MapContextAction(MapContextCommand.properties, 'Propriétés'),
  const MapContextAction(MapContextCommand.move, 'Déplacer'),
  const MapContextAction(MapContextCommand.delete, 'Supprimer la zone'),
];

List<MapContextAction> _triggerActions(
  MapContextTarget target,
  MapContextActionContext context,
) {
  final blocked = TriggerEditingCommands(
    context.document,
    context.project,
    draftGuard: context.referenceGuard,
  ).deletionProblem(target.id);
  return [
    const MapContextAction(MapContextCommand.properties, 'Propriétés'),
    const MapContextAction(MapContextCommand.move, 'Déplacer'),
    const MapContextAction(
      MapContextCommand.openNarrativeDocument,
      'Ouvrir son interaction',
    ),
    MapContextAction(
      MapContextCommand.delete,
      'Supprimer la zone',
      unavailable: blocked,
    ),
  ];
}
