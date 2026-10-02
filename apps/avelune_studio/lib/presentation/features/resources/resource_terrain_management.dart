import 'package:map_core/map_core_domain.dart';
import '../../../features/resources/domain/resource_port.dart';
import '../../../features/terrains/application/terrain_draft_controller.dart';
import 'resource_navigation.dart';

extension ResourceTerrainManagement on ResourceNavigation {
  List<TerrainDraftController> terrainManagementModels(
    Map<String, Object?> parameters,
  ) => terrains.values.where((model) {
    final draft = model.draft;
    return parameters['draftId'] == draft.id ||
        parameters['presetId'] == draft.targetPresetId ||
        parameters['presetId'] == draft.sourcePresetId;
  }).toList();

  List<String> terrainManagementOwners(
    String action,
    Map<String, Object?> parameters,
  ) => [
    for (final model in terrainManagementModels(parameters))
      if (model.dirty) 'Terrain · ${model.draft.name}',
    if (action == 'smart_tile.preset.delete')
      for (final document in workspace.documents.values)
        if (document.dirty &&
            document.current.layers.whereType<SmartTileLayer>().any(
              (layer) => layer.presetId == parameters['presetId'],
            ))
          'Carte · ${document.current.name}',
  ];

  void reconcileTerrainManagement(ResourceMutationReceipt receipt) {
    if (!const {
      'smart_tile.preset.rename',
      'smart_tile.preset.duplicate',
      'smart_tile.preset.delete',
      'smart_tile.preset.draft.delete',
    }.contains(receipt.actionId)) {
      return;
    }
    final before = receipt.before.smartTileCatalog;
    final after = receipt.manifest.smartTileCatalog;
    final changedPresets = {
      for (final preset in before.presets)
        if (!after.presets.any((entry) => entry == preset)) preset.id,
    };
    final changedDrafts = {
      for (final draft in before.drafts)
        if (!after.drafts.any((entry) => entry == draft)) draft.id,
    };
    terrains.removeWhere((id, model) {
      final affected =
          changedDrafts.contains(id) ||
          changedPresets.contains(model.draft.targetPresetId) ||
          changedPresets.contains(model.draft.sourcePresetId);
      if (!affected || model.dirty) return false;
      if (identical(terrain, model)) {
        terrain = null;
        page = ResourcePage.library;
      }
      return true;
    });
  }

  void discardLocalTerrain(String draftId) {
    final model = terrains.remove(draftId);
    if (identical(terrain, model)) {
      terrain = null;
      page = ResourcePage.library;
    }
    changed();
  }
}
