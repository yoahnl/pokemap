import 'package:map_core/map_core_domain.dart';

import '../../terrains/application/terrain_brush.dart';
import 'editable_map_document.dart';

class MapTerrainSettingsCommands {
  MapTerrainSettingsCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;

  bool _change(
    ProjectSmartTilePreset preset,
    MapData Function(MapData, SmartTileLayer) change,
  ) {
    if (document.saving) return false;
    try {
      final prepared = prepareTerrainStrokeLayer(
        map: document.current,
        manifest: project,
        preset: preset,
      );
      if (prepared == null) return false;
      document.commit(change(prepared.map, prepared.layer));
      return true;
    } on ValidationException catch (error) {
      document.error = error.message;
    } on StateError catch (error) {
      document.error = error.message;
    }
    return false;
  }

  bool animation(
    ProjectSmartTilePreset preset,
    SmartTileAnimationActivation activation,
  ) => _change(
    preset,
    (map, layer) => setSmartTileLayerAnimationActivation(
      map,
      layerId: layer.id,
      activation: activation,
    ),
  );

  bool encounter(
    ProjectSmartTilePreset preset,
    String tableId, {
    String? materialId,
  }) => _change(preset, (map, layer) {
    if (tableId.isEmpty) {
      return setSmartTileLayerEncounterBehavior(
        map,
        manifest: project,
        layerId: layer.id,
        behavior: null,
      );
    }
    if (!project.encounterTables.any(
      (table) =>
          table.id == tableId && table.encounterKind == EncounterKind.walk,
    )) {
      throw StateError('Cette table de rencontres n’est plus disponible.');
    }
    final previous = layer.encounterBehavior;
    final behavior = previous == null
        ? SmartTileEncounterBehavior(
            materialId: preset.allowedMaterialIds.contains(materialId)
                ? materialId!
                : preset.defaultMaterialId,
            encounter: EncounterZonePayload(
              encounterTableId: tableId,
              encounterKind: EncounterKind.walk,
            ),
          )
        : previous.copyWith(
            encounter: previous.encounter.copyWith(
              encounterTableId: tableId,
              encounterKind: EncounterKind.walk,
            ),
          );
    return setSmartTileLayerEncounterBehavior(
      map,
      manifest: project,
      layerId: layer.id,
      behavior: behavior,
    );
  });
}
