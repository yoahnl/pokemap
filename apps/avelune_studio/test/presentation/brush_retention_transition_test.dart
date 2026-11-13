import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_loader.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/resource_stress_fixture.dart';

void main() {
  testWidgets(
    'retained resource and tool owners retain one brush under a small real cache budget',
    (tester) async {
      late ResourceStressFixture fixture;
      late MapWorkspaceController controller;
      late StudioMapResources resources;
      await tester.runAsync(() async {
        final qa = Directory(
          '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
        );
        await qa.create(recursive: true);
        fixture = await IOOverrides.runZoned(
          () => ResourceStressFixture.create(atlasCount: 4, errorCount: 0),
          getSystemTempDirectory: () => qa,
        );
        controller = MapWorkspaceController(
          fixture.session,
          LocalMapWorkspaceAdapter(),
        );
        await controller.initialize();
      });
      addTearDown(
        () => tester.runAsync(() async {
          controller.dispose();
          await resources.dispose();
          await fixture.dispose();
        }),
      );
      final decor = fixture.manifest.elements.first.copyWith(
        id: 'brush-only',
        name: 'Décor du pinceau',
        tilesetId: stressAtlasId(1),
        frames: [
          const TilesetVisualFrame(
            source: TilesetSourceRect(x: 2, y: 0, width: 2, height: 3),
          ),
        ],
      );
      final atlas = ProjectSmartTileAtlas(
        id: 'brush-terrain',
        name: 'Terrain',
        tilesetId: stressAtlasId(2),
        columns: 10,
        rows: 4,
        cellWidth: 16,
        cellHeight: 16,
      );
      final terrain = TerrainDraftController(
        manifest: fixture.manifest,
        atlas: atlas,
        id: 'terrain-brush',
      )..assign(0, 0);
      controller.project = controller.project!.copyWith(
        elements: [decor],
        smartTileCatalog: ProjectSmartTileCatalog(
          atlases: [atlas],
          materials: terrain.draft.materials,
          presets: [terrain.previewPreset],
        ),
      );
      final character = fixture.manifest.characters.first.copyWith(
        id: 'npc-brush',
        name: 'Personnage du pinceau',
        tilesetId: stressAtlasId(1),
      );
      controller.project = controller.project!.copyWith(
        characters: [...fixture.manifest.characters, character],
      );
      await tester.runAsync(() async {
        resources = await StudioMapResources.load(
          fixture.session,
          controller.project!,
          maximumBytes: fixture.decodedAtlasBytes * 2,
        );
      });
      await tester.runAsync(() async {
        final view = MapWorkspaceEditingState();
        void retain() => retainWorkspaceBrush(resources, view);
        void useTool(StudioMapTool tool) {
          view.tool = tool;
          retain();
        }

        Future<void> settle() async {
          await resources.settled;
          expect(tester.takeException(), isNull);
        }

        Future<void> choose(String identity) async {
          final item = resourceCatalog(controller.project!)
              .firstWhere((item) => item.identity == identity);
          expect(
            await useMapResource(
              workspace: controller,
              item: item,
              view: () => view,
              isActive: () => true,
              chooseMap: (_) async => null,
              chooseTile: (source) async =>
                  TileLayerPaletteEntry(tilesetId: source.id, localTileId: 0),
            ),
            isTrue,
          );
          retain();
          await settle();
        }

        resources.setActiveMap(controller.active!.current);
        await settle();
        await choose('element:${decor.id}');
        expect(resources.store.priority, contains(stressAtlasId(1)));
        useTool(StudioMapTool.pan);
        resources.store.request(stressAtlasId(0));
        await settle();
        expect(resources.images.containsKey(stressAtlasId(1)), isTrue);
        useTool(StudioMapTool.place);
        expect(resources.store.priority, contains(stressAtlasId(1)));
        await choose('tileset:${stressAtlasId(2)}');
        expect(view.tool, StudioMapTool.paint);
        expect(resources.store.priority, contains(stressAtlasId(2)));
        expect(resources.store.priority, isNot(contains(stressAtlasId(1))));
        await choose('smartTilePreset:${terrain.previewPreset.id}');
        useTool(StudioMapTool.pan);
        expect(resources.store.priority, contains(stressAtlasId(2)));
        useTool(StudioMapTool.terrain);
        await settle();
        expect(resources.store.priority, contains(stressAtlasId(2)));
        expect(
          resources.decodedBytes,
          lessThanOrEqualTo(fixture.decodedAtlasBytes * 2),
        );
        await choose('character:${character.id}');
        expect(resources.store.priority, contains(stressAtlasId(1)));
        expect(resources.store.priority, isNot(contains(stressAtlasId(2))));
        useTool(StudioMapTool.pan);
        resources.store.request(stressAtlasId(0));
        await settle();
        view.prepareCharacterPlacement();
        retain();
        await settle();
        expect(view.tool, StudioMapTool.character);
        expect(resources.images.containsKey(stressAtlasId(1)), isTrue);
        expect(resources.store.priority, contains(stressAtlasId(1)));
        expect(
          resources.decodedBytes,
          lessThanOrEqualTo(fixture.decodedAtlasBytes * 2),
        );
        await resources.dispose();
        expect(resources.images, isEmpty);
      });
    },
  );
}
