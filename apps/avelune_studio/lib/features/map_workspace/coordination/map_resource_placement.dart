import 'package:map_core/map_core_domain.dart';

import '../../resources/application/resource_catalog.dart';
import '../../resources/coordination/resource_navigation.dart';
import '../application/map_workspace_controller.dart';
import '../application/environment_editing_commands.dart';
import '../application/map_workspace_editing_state.dart';

Future<bool> useMapResource({
  required MapWorkspaceController workspace,
  required ResourceItem item,
  required MapWorkspaceEditingState? Function() view,
  required bool Function() isActive,
  required Future<ProjectMapEntry?> Function(List<ProjectMapEntry>) chooseMap,
  required Future<TileLayerPaletteEntry?> Function(ProjectTilesetEntry)
  chooseTile,
}) async {
  if (workspace.project == null || workspace.project!.maps.isEmpty) {
    return false;
  }
  if (workspace.active == null) {
    final entry = await chooseMap([
      for (final entry in workspace.project!.maps)
        if (workspace.project!.resourceLibraryCatalog.availableForMap(
          item.canonicalKind,
          item.id,
          entry.id,
        ))
          entry,
    ]);
    if (entry == null) return false;
    await workspace.activate(entry);
  }
  if (!isActive() || view() == null) return false;
  final target = workspace.active;
  if (target == null ||
      !workspace.project!.resourceLibraryCatalog.availableForMap(
        item.canonicalKind,
        item.id,
        target.current.id,
      )) {
    return false;
  }
  final state = view()!;
  if (item.tileset != null) {
    final tile = await chooseTile(item.tileset!);
    if (tile == null || !isActive() || !identical(target, workspace.active)) {
      return false;
    }
    state
      ..tile = tile
      ..brush = null
      ..model3d = null
      ..terrain = null
      ..tool = StudioMapTool.paint;
  } else if (item.terrain != null) {
    state.prepareTerrainPainting(item.terrain!);
  } else if (item.border != null) {
    state
      ..borderBlueprintId = item.id
      ..borderDraft = null
      ..brush = null
      ..model3d = null
      ..tile = null
      ..terrain = null
      ..tool = StudioMapTool.border;
  } else if (item.character != null) {
    state.prepareCharacterPlacement();
    state
      ..character = item.character
      ..tool = StudioMapTool.character;
    return true;
  } else {
    state
      ..brush = item.element
      ..model3d = item.model3d
      ..tile = null
      ..terrain = null
      ..tool = StudioMapTool.place;
  }
  state.character = null;
  return true;
}

Future<bool> useMapEnvironment({
  required MapWorkspaceController workspace,
  required ResourceNavigation resources,
  required EnvironmentPreset preset,
  required MapWorkspaceEditingState? Function() view,
  required bool Function() isActive,
  required Future<ProjectMapEntry?> Function(List<ProjectMapEntry>) chooseMap,
}) async {
  final project = workspace.project;
  if (resources.busy || project == null) return false;
  if (resources.environments[preset.id]?.dirty == true) {
    resources.error = 'Enregistrez ou annulez la préparation de cet environnement avant de dessiner sa zone.';
    resources.changed();
    return false;
  }
  if (workspace.active == null) {
    final entry = await chooseMap([
      for (final entry in project.maps)
        if (project.resourceLibraryCatalog.availableForMap(
          'environmentPreset',
          preset.id,
          entry.id,
        ))
          entry,
    ]);
    if (entry == null || !isActive()) return false;
    await workspace.activate(entry, isCurrent: isActive);
  }
  final document = workspace.active;
  final current = workspace.project;
  final state = view();
  if (!isActive() || document == null || current == null || state == null) {
    return false;
  }
  final selected = current.environmentPresets
      .where((entry) => entry.id == preset.id)
      .firstOrNull;
  if (selected == null) return false;
  if (!current.resourceLibraryCatalog.availableForMap(
    'environmentPreset',
    selected.id,
    document.current.id,
  )) {
    resources.setImportError('Cet environnement est propre à une autre carte.');
    return false;
  }
  try {
    state.selectEnvironmentPreset(document, current, selected);
    return true;
  } on Object catch (failure) {
    resources.error = environmentEditingMessage(failure);
    resources.changed();
    return false;
  }
}
