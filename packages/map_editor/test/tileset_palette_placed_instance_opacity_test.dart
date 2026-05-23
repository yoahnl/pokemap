import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';

void main() {
  testWidgets('selected placed element instance exposes editable opacity',
      (tester) async {
    final temp = await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'placed_opacity_',
      );
      final tilesetFile = File('${directory.path}/tilesets/main.png');
      await tilesetFile.parent.create(recursive: true);
      await tilesetFile.writeAsBytes(base64Decode(_onePixelPngBase64));
      return directory;
    });
    expect(temp, isNotNull);
    addTearDown(() async {
      if (await temp!.exists()) {
        await temp.delete(recursive: true);
      }
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: temp!.path,
      project: _project(),
      activeMap: _map(),
      activeLayerId: 'layer',
      selectedTilesetEditorId: 'ts',
      tilesElementsPanelMode: TilesElementsPanelMode.placedInstances,
      selectedPlacedElementInstanceId: 'layer::1::1',
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
    for (var i = 0; i < 20 && find.text('Opacité').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Opacité'), findsOneWidget);
    expect(find.text('75 %'), findsOneWidget);

    final sliderFinder =
        find.byKey(const ValueKey('placed-instance-opacity-slider'));
    expect(sliderFinder, findsOneWidget);
    final slider = tester.widget<MacosSlider>(sliderFinder);
    slider.onChanged(0.5);
    await tester.pump();

    final state = container.read(editorNotifierProvider);
    expect(state.activeMap!.placedElements.single.opacity, 0.5);
    expect(state.selectedPlacedElementInstanceId, 'layer::1::1');
  });
}

const _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNwOdPxHwAFiAKY2jkehAAAAABJRU5ErkJggg==';

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'ts',
        name: 'Tileset',
        relativePath: 'tilesets/main.png',
      ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'cat', name: 'Cat'),
    ],
    elements: const [
      ProjectElementEntry(
        id: 'lamp',
        name: 'Lamp',
        tilesetId: 'ts',
        categoryId: 'cat',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
          ),
        ],
      ),
    ],
    settings: const ProjectSettings(tileWidth: 1, tileHeight: 1),
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

MapData _map() {
  return const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 4, height: 4),
    layers: [
      MapLayer.tile(
        id: 'layer',
        name: 'Layer',
        tilesetId: 'ts',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    ],
    placedElements: [
      MapPlacedElement(
        id: 'layer::1::1',
        layerId: 'layer',
        elementId: 'lamp',
        pos: GridPos(x: 1, y: 1),
        opacity: 0.75,
      ),
    ],
  );
}
