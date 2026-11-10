import 'package:map_core/map_core_domain.dart';

import 'map_workspace_commands.dart';
import 'map_workspace_editing_state.dart';

class MapToolCommandRunner {
  const MapToolCommandRunner({
    required this.view,
    required this.paletteTab,
    required this.selectPalette,
    required this.spatial,
    required this.paletteVisible,
    required this.onChanged,
    required this.onMoreTools,
    required this.onResources,
  });

  final MapWorkspaceEditingState view;
  final String Function() paletteTab;
  final void Function(String) selectPalette;
  final bool spatial, paletteVisible;
  final void Function() onChanged, onMoreTools, onResources;

  void run(MapWorkspaceCommand command) {
    switch (command.kind) {
      case MapCommandKind.family:
        runFamily(command.label);
      case MapCommandKind.extra:
        runExtra(command.label);
      case MapCommandKind.history:
        return;
    }
  }

  void runFamily(String label) {
    switch (label) {
      case 'Sélection':
        view.tool = StudioMapTool.select;
      case 'Décors':
        selectPalette('Décors');
        view.tool = view.brush == null && view.model3d == null
            ? StudioMapTool.select
            : StudioMapTool.place;
      case 'Terrains':
        selectPalette('Terrains');
        view.tool = view.terrain == null && !spatial
            ? StudioMapTool.select
            : StudioMapTool.terrain;
      case 'Zones':
        view.tool = StudioMapTool.gameplayZone;
      case 'Bordures':
        if (spatial) selectPalette('Bordures');
        view.tool = StudioMapTool.border;
      case 'Environnements':
        selectPalette('Environnements');
        view.tool = StudioMapTool.environment;
      case 'Collisions':
        view.tool = StudioMapTool.collisionPaint;
      case 'Passages':
        selectPalette('Passages');
        view.prepareWarpPlacement();
      case 'Connexions':
        selectPalette('Passages');
        view.prepareConnections();
    }
    onChanged();
    if (!paletteVisible &&
        (label == 'Décors' ||
            label == 'Terrains' ||
            (label == 'Bordures' && spatial) ||
            label == 'Passages' ||
            label == 'Environnements')) {
      onMoreTools();
    }
  }

  void runExtra(String label) {
    switch (label) {
      case 'Déplacer la vue':
        view.tool = StudioMapTool.pan;
      case 'Peindre':
        view.tool =
            view.terrain != null || (spatial && paletteTab() == 'Terrains')
            ? StudioMapTool.terrain
            : view.brush != null
            ? StudioMapTool.place
            : StudioMapTool.paint;
      case 'Gomme de tuiles':
        view.tool = StudioMapTool.erase;
      case 'Gomme de décors':
        view.tool = StudioMapTool.eraseDecor;
      case 'Peindre les collisions':
        view.tool = StudioMapTool.collisionPaint;
      case 'Effacer les collisions':
        view.tool = StudioMapTool.collisionErase;
      case 'Placer un personnage':
        selectPalette('Personnages');
        view.prepareCharacterPlacement();
      case 'Placer le départ du joueur':
        view.tool = StudioMapTool.spawn;
      case 'Placer un panneau':
        view.tool = StudioMapTool.sign;
      case 'Placer un arbre à couper':
        selectPalette('Décors');
        view.prepareFieldObstaclePlacement(FieldObstacleKind.cutTree);
      case 'Placer un rocher à pousser':
        selectPalette('Décors');
        view.prepareFieldObstaclePlacement(FieldObstacleKind.strengthBoulder);
      case 'Placer un rocher à briser':
        selectPalette('Décors');
        view.prepareFieldObstaclePlacement(FieldObstacleKind.rockSmashRock);
      case 'Passages':
        selectPalette('Passages');
        view.prepareWarpPlacement();
      case 'Connexions':
        selectPalette('Passages');
        view.prepareConnections();
      case 'Dessiner une zone de jeu':
        view.tool = StudioMapTool.gameplayZone;
      case 'Dessiner une zone d’histoire':
        view.tool = StudioMapTool.zone;
      case 'Palette complète':
        onMoreTools();
        return;
      case 'Gérer les ressources':
        onResources();
        return;
    }
    onChanged();
    if (!paletteVisible &&
        (label == 'Placer un personnage' || label == 'Passages')) {
      onMoreTools();
    }
  }
}
