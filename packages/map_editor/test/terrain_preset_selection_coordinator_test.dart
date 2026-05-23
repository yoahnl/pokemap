import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/terrain_selection_mode.dart';
import 'package:map_editor/src/application/services/terrain_preset_resolver.dart';
import 'package:map_editor/src/application/services/terrain_preset_selection_coordinator.dart';

void main() {
  group('TerrainPresetSelectionCoordinator', () {
    const resolver = TerrainPresetResolver();
    const coordinator = TerrainPresetSelectionCoordinator(resolver: resolver);

    test('uses the shared application terrain selection mode model', () {
      const project = ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'Demo',
        maps: [],
        tilesets: [],
        terrainPresets: [
          ProjectTerrainPreset(
            id: 'grass-a',
            name: 'Grass A',
            terrainType: TerrainType.grass,
          ),
        ],
        pathPresets: [
          ProjectPathPreset(
            id: 'path-a',
            name: 'Path A',
          ),
        ],
      );

      final selection = coordinator.initial(project);

      expect(selection.selectionMode, TerrainSelectionMode.terrain);
      expect(selection.selectedTerrainType, TerrainType.grass);
      expect(selection.selectedTerrainPresetId, 'grass-a');
      expect(selection.selectedPathPresetId, 'path-a');
    });
  });
}
