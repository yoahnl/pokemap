part of 'map_workspace_tool_strip.dart';

extension _MapWorkspaceToolStripActions on MapWorkspaceToolStrip {
  void _select(String label) {
    switch (label) {
      case 'Sélection':
        view.tool = StudioMapTool.select;
      case 'Décors':
        view.paletteTab = 'Décors';
        view.tool = view.brush == null && view.model3d == null
            ? StudioMapTool.select
            : StudioMapTool.place;
      case 'Terrains':
        view.paletteTab = 'Terrains';
        view.tool = view.terrain == null
            ? StudioMapTool.select
            : StudioMapTool.terrain;
      case 'Zones':
        view.tool = StudioMapTool.gameplayZone;
      case 'Bordures':
        view.tool = StudioMapTool.border;
      case 'Environnements':
        view.tool = StudioMapTool.environment;
      case 'Collisions':
        view.tool = StudioMapTool.collisionPaint;
      case 'Passages':
        view.prepareWarpPlacement();
    }
    onChanged();
    if (!paletteVisible &&
        (label == 'Décors' || label == 'Terrains' || label == 'Passages')) {
      onMoreTools();
    }
  }

  void _selectExtra(String label) {
    switch (label) {
      case 'Déplacer la vue':
        view.tool = StudioMapTool.pan;
      case 'Peindre':
        view.tool = view.terrain != null
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
        view.prepareCharacterPlacement();
      case 'Placer le départ du joueur':
        view.tool = StudioMapTool.spawn;
      case 'Placer un panneau':
        view.tool = StudioMapTool.sign;
      case 'Passages':
        view.prepareWarpPlacement();
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
