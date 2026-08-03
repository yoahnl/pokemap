import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/palette/map_layer_asset_palette.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  testWidgets(
    'selecting an element activates its existing recommended tile layer',
    (tester) async {
      final projectRoot = await tester.runAsync(() async {
        final directory = await Directory.systemTemp.createTemp(
          'recommended_layer_palette_',
        );
        final tilesetFile = File('${directory.path}/tilesets/interior.png');
        await tilesetFile.parent.create(recursive: true);
        await tilesetFile.writeAsBytes(base64Decode(_onePixelPngBase64));
        return directory;
      });
      expect(projectRoot, isNotNull);
      addTearDown(() async {
        if (await projectRoot!.exists()) {
          await projectRoot.delete(recursive: true);
        }
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: projectRoot!.path,
        project: _project(),
        activeMap: _map(),
        activeLayerId: 'l_tile_floor',
        selectedTilesetEditorId: 'ts_interior',
      );

      await tester.binding.setSurfaceSize(const Size(900, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 620,
                  height: 1000,
                  child: TilesetPalettePanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      for (var attempt = 0;
          attempt < 20 && find.text('Table du gardien').evaluate().isEmpty;
          attempt++) {
        await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(MapLayerAssetPalette), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MapLayerAssetPalette),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
      expect(find.text('Table du gardien'), findsOneWidget);
      await tester.tap(find.text('Table du gardien'));
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.activeLayerId, 'l_tile_furniture');
      expect(
        state.activeBrush.maybeMap(
          projectElement: (brush) => brush.elementId,
          orElse: () => null,
        ),
        'guardian_table',
      );
    },
  );
}

const _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNwOdPxHwAFiAKY2jkehAAAAABJRU5ErkJggg==';

ProjectManifest _project() {
  return const ProjectManifest(
    name: 'Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'ts_interior',
        name: 'Intérieur',
        relativePath: 'tilesets/interior.png',
      ),
    ],
    elementCategories: <ProjectElementCategory>[
      ProjectElementCategory(id: 'interior', name: 'Intérieur'),
    ],
    elements: <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'guardian_table',
        name: 'Table du gardien',
        tilesetId: 'ts_interior',
        categoryId: 'interior',
        recommendedLayerId: 'l_tile_furniture',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
          ),
        ],
      ),
    ],
    settings: ProjectSettings(tileWidth: 1, tileHeight: 1),
  );
}

MapData _map() {
  return const MapData(
    id: 'interior',
    name: 'Intérieur',
    size: GridSize(width: 2, height: 2),
    layers: <MapLayer>[
      TileLayer(
        id: 'l_tile_floor',
        name: 'Sol',
        tilesetId: 'ts_interior',
        tiles: <int>[0, 0, 0, 0],
      ),
      TileLayer(
        id: 'l_tile_furniture',
        name: 'Mobilier',
        tilesetId: 'ts_interior',
        tiles: <int>[0, 0, 0, 0],
      ),
    ],
  );
}
