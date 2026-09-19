import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/resource_stress_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'terrain brush loads only its shared resolver dependencies before any map stroke',
    () async {
      final fixture = await ResourceStressFixture.create();
      addTearDown(fixture.dispose);
      final atlas = ProjectSmartTileAtlas(
        id: 'terrain-atlas',
        name: 'Terrain',
        tilesetId: fixture.lateAtlasId,
        columns: 5,
        rows: 2,
        cellWidth: 32,
        cellHeight: 32,
      );
      final draft = TerrainDraftController(
        manifest: fixture.manifest,
        atlas: atlas,
        id: 'terrain',
      );
      draft.assign(0, 0);
      final preset = draft.previewPreset;
      final manifest = fixture.manifest.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          atlases: [atlas],
          materials: draft.draft.materials,
          presets: [preset],
        ),
      );
      final resources = await StudioMapResources.load(
        fixture.session,
        manifest,
      );
      addTearDown(resources.dispose);
      expect(resources.images, isEmpty);
      resources.setTerrainBrush(preset);
      await resources.settled;
      expect(resources.images.keys, [fixture.lateAtlasId]);
      expect(resources.store.decoder.decodes, 1);
      expect(resources.store.priority, {fixture.lateAtlasId});
      await resources.updateCatalog(manifest);
      await resources.settled;
      expect(resources.store.decoder.decodes, 1);
      expect(resources.store.priority, {fixture.lateAtlasId});
      resources.setTerrainBrush(null);
      expect(resources.store.priority, isEmpty);
      expect(resources.diagnostics, isEmpty);
    },
  );
}
