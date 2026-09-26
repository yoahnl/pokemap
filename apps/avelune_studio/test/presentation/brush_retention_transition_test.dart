import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_panels.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/resource_stress_fixture.dart';

void main() {
  testWidgets(
    'tool integration retains one brush with hidden palette and small budget',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late ResourceStressFixture fixture;
      late MapWorkspaceController controller;
      late StudioMapResources resources;
      await tester.runAsync(() async {
        fixture = await ResourceStressFixture.create(
          atlasCount: 4,
          errorCount: 0,
        );
        controller = MapWorkspaceController(
          fixture.session,
          LocalMapWorkspaceAdapter(),
        );
        await controller.initialize();
      });
      addTearDown(() async {
        controller.dispose();
        await resources.dispose();
        await fixture.dispose();
      });
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
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: MapWorkspaceScreen(
            controller: controller,
            loadVisuals: (_, _) async => resources,
            runtimeBuilder: (_, _, _) => const SizedBox(),
            onClose: () async {},
            registerExitGuard: (_) {},
          ),
        ),
      );
      Future<void> settle() async {
        for (var i = 0; i < 30; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(tester.takeException(), isNull);
      }

      Future<void> openPalette() async {
        await tester.tap(find.byTooltip('Palette'));
        await tester.pumpAndSettle();
      }

      Future<void> closePalette() async {
        await tester.tap(find.byTooltip('Retour à la carte'));
        await tester.pumpAndSettle();
      }

      Future<void> chooseTool(String label) async {
        await openPalette();
        await tester.tap(find.byTooltip(label));
        await closePalette();
      }

      await settle();
      await openPalette();
      await tester.tap(find.text('Décor du pinceau').first);
      await settle();
      expect(resources.store.priority, contains(stressAtlasId(1)));
      await chooseTool('Déplacer la vue');
      await openPalette();
      resources.store.request(stressAtlasId(0));
      await settle();
      expect(resources.images.containsKey(stressAtlasId(1)), isTrue);
      await closePalette();
      await chooseTool('Peindre');
      expect(resources.store.priority, contains(stressAtlasId(1)));
      await openPalette();
      final palette = tester.widget<MapWorkspacePalette>(
        find.byType(MapWorkspacePalette),
      );
      palette.view
        ..brush = null
        ..terrain = null
        ..tile = TileLayerPaletteEntry(
          tilesetId: stressAtlasId(2),
          localTileId: 0,
        )
        ..tool = StudioMapTool.paint;
      palette.onChanged();
      await settle();
      expect(resources.store.priority, contains(stressAtlasId(2)));
      expect(resources.store.priority, isNot(contains(stressAtlasId(1))));
      await openPalette();
      await tester.tap(
        find.descendant(
          of: find.byType(MapWorkspacePalette),
          matching: find.text('Terrains'),
        ),
      );
      await tester.pump();
      await tester.tap(find.text(terrain.previewPreset.name).first);
      await settle();
      await chooseTool('Déplacer la vue');
      await openPalette();
      await closePalette();
      expect(find.byType(MapWorkspacePalette), findsNothing);
      expect(resources.store.priority, contains(stressAtlasId(2)));
      await openPalette();
      await closePalette();
      await chooseTool('Peindre');
      await settle();
      expect(resources.store.priority, contains(stressAtlasId(2)));
      expect(
        resources.decodedBytes,
        lessThanOrEqualTo(fixture.decodedAtlasBytes * 2),
      );
      await openPalette();
      await tester.tap(find.text('Personnages').last);
      await tester.pump();
      await tester.tap(find.text(character.name).first);
      await settle();
      expect(resources.store.priority, contains(stressAtlasId(1)));
      expect(resources.store.priority, isNot(contains(stressAtlasId(2))));
      await chooseTool('Déplacer la vue');
      await openPalette();
      resources.store.request(stressAtlasId(0));
      await settle();
      await closePalette();
      await chooseTool('Placer un personnage');
      await settle();
      expect(resources.images.containsKey(stressAtlasId(1)), isTrue);
      expect(resources.store.priority, contains(stressAtlasId(1)));
      expect(
        resources.decodedBytes,
        lessThanOrEqualTo(fixture.decodedAtlasBytes * 2),
      );
      await tester.pumpWidget(const SizedBox());
      await resources.dispose();
      expect(resources.images, isEmpty);
    },
  );
}
