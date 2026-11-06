import 'package:map_core/map_core_domain.dart';

import 'map_workspace_view_state.dart';

enum MapIntentGroup { select, build, populate, rules }

final class MapPaletteIntent {
  const MapPaletteIntent({
    required this.group,
    required this.action,
    required this.next,
    required this.armed,
    this.paletteTab,
    this.resource,
  });

  final MapIntentGroup group;
  final String action, next;
  final bool armed;
  final String? paletteTab, resource;

  bool get usesPalette => paletteTab != null;
}

const _selectionHints = {
  'Décors': 'Choisissez un décor dans la palette pour le placer.',
  'Terrains': 'Choisissez un terrain dans la palette pour le peindre.',
  'Personnages': 'Choisissez un personnage dans la palette pour le placer.',
  'Passages': 'Choisissez la carte de destination du passage.',
  'Environnements': 'Choisissez un environnement pour dessiner sa zone.',
};

MapPaletteIntent mapPaletteIntent(
  MapWorkspaceViewState view, {
  bool spatial = false,
  bool connectionsAvailable = true,
}) {
  return switch (view.tool) {
    StudioMapTool.select => MapPaletteIntent(
      group: MapIntentGroup.select,
      action: 'Sélection',
      next:
          _selectionHints[view.paletteTab] ??
          'Cliquez un élément de la carte pour le modifier.',
      armed: false,
    ),
    StudioMapTool.pan => const MapPaletteIntent(
      group: MapIntentGroup.select,
      action: 'Déplacer la vue',
      next: 'Faites glisser la carte pour explorer.',
      armed: true,
    ),
    StudioMapTool.place => _resourceIntent(
      group: MapIntentGroup.build,
      action: 'Placement de décor',
      tab: 'Décors',
      resource: view.brush?.name ?? view.model3d?.name,
      armedNext: 'Cliquez sur la carte pour placer ce décor.',
      emptyNext: 'Choisissez un décor dans la palette.',
    ),
    StudioMapTool.paint => _resourceIntent(
      group: MapIntentGroup.build,
      action: 'Peinture de tuiles',
      tab: 'Tuiles',
      resource: view.tile == null ? null : 'tuile choisie',
      armedNext: 'Peignez sur la carte.',
      emptyNext: 'Choisissez une tuile dans son atlas.',
    ),
    StudioMapTool.terrain => MapPaletteIntent(
      group: MapIntentGroup.build,
      action: 'Peinture de terrain',
      paletteTab: 'Terrains',
      resource: view.terrain?.name,
      armed: view.terrain != null || spatial,
      next: view.terrain != null || spatial
          ? 'Peignez sur la carte : les raccords se calculent automatiquement.'
          : 'Choisissez un terrain dans la palette.',
    ),
    StudioMapTool.erase => const MapPaletteIntent(
      group: MapIntentGroup.build,
      action: 'Gomme de tuiles',
      next: 'Effacez les tuiles et terrains sous le curseur.',
      armed: true,
    ),
    StudioMapTool.eraseDecor => const MapPaletteIntent(
      group: MapIntentGroup.build,
      action: 'Gomme de décors',
      next: 'Cliquez sur un décor pour l’effacer.',
      armed: true,
    ),
    StudioMapTool.border => MapPaletteIntent(
      group: MapIntentGroup.build,
      action: 'Tracé de bordure',
      paletteTab: spatial ? 'Bordures' : null,
      armed: true,
      next: 'Cliquez pour poser les points du contour.',
    ),
    StudioMapTool.environment => MapPaletteIntent(
      group: MapIntentGroup.build,
      action: 'Zone d’environnement',
      paletteTab: 'Environnements',
      armed: view.environment != null,
      next: view.environment != null
          ? 'Dessinez la zone sur la carte.'
          : 'Choisissez un environnement dans la palette.',
    ),
    StudioMapTool.character => _resourceIntent(
      group: MapIntentGroup.populate,
      action: 'Placement de personnage',
      tab: 'Personnages',
      resource: view.character?.name,
      armedNext: 'Cliquez sur la case de départ du personnage.',
      emptyNext: 'Choisissez un personnage dans la palette.',
    ),
    StudioMapTool.spawn => const MapPaletteIntent(
      group: MapIntentGroup.populate,
      action: 'Départ du joueur',
      next: 'Cliquez la case où le joueur commence la partie.',
      armed: true,
    ),
    StudioMapTool.sign => const MapPaletteIntent(
      group: MapIntentGroup.populate,
      action: 'Panneau',
      next: 'Cliquez la case du panneau, puis écrivez son texte.',
      armed: true,
    ),
    StudioMapTool.fieldObstacle => const MapPaletteIntent(
      group: MapIntentGroup.populate,
      action: 'Obstacle de terrain',
      paletteTab: 'Décors',
      next: 'Choisissez le visuel de l’obstacle, puis cliquez sur sa case.',
      armed: true,
    ),
    StudioMapTool.warp => MapPaletteIntent(
      group: MapIntentGroup.rules,
      action: 'Passage',
      paletteTab: 'Passages',
      resource: view.warpDestination?.name,
      armed:
          view.warpDestination != null ||
          view.warpPlacementMode == MapWarpTriggerMode.sceneOnly,
      next:
          view.warpDestination != null ||
              view.warpPlacementMode == MapWarpTriggerMode.sceneOnly
          ? 'Cliquez sur la case du passage.'
          : 'Choisissez la carte de destination du passage.',
    ),
    StudioMapTool.connection => MapPaletteIntent(
      group: MapIntentGroup.rules,
      action: 'Connexions',
      armed: false,
      next: connectionsAvailable
          ? 'Réglez le bord, la carte voisine et le décalage dans le panneau Connexions.'
          : mapConnectionsUnavailable,
    ),
    StudioMapTool.zone => const MapPaletteIntent(
      group: MapIntentGroup.rules,
      action: 'Zone d’histoire',
      next: 'Tracez la zone qui déclenche une interaction.',
      armed: true,
    ),
    StudioMapTool.gameplayZone ||
    StudioMapTool.encounterPaint ||
    StudioMapTool.encounterErase => const MapPaletteIntent(
      group: MapIntentGroup.rules,
      action: 'Zone de jeu',
      next: 'Tracez une zone de rencontres, de déplacement ou d’effet.',
      armed: true,
    ),
    StudioMapTool.collisionPaint => const MapPaletteIntent(
      group: MapIntentGroup.rules,
      action: 'Bloquer les cases',
      next: 'Cliquez ou glissez pour bloquer les cases.',
      armed: true,
    ),
    StudioMapTool.collisionErase => const MapPaletteIntent(
      group: MapIntentGroup.rules,
      action: 'Libérer les cases',
      next: 'Cliquez ou glissez pour libérer les cases bloquées.',
      armed: true,
    ),
  };
}

const mapConnectionsUnavailable =
    'Les connexions entre cartes ne sont pas modifiables dans cette session, qui n’a pas chargé le projet complet. Pour relier deux cartes, utilisez l’outil Passages.';

MapPaletteIntent _resourceIntent({
  required MapIntentGroup group,
  required String action,
  required String tab,
  required String? resource,
  required String armedNext,
  required String emptyNext,
}) => MapPaletteIntent(
  group: group,
  action: action,
  paletteTab: tab,
  resource: resource,
  armed: resource != null,
  next: resource != null ? armedNext : emptyNext,
);
