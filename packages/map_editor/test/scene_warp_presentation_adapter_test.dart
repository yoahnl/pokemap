import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  for (final illustrated in [false, true]) {
    testWidgets('legacy canonical adapter preserves ${illustrated ? 'illustrated' : 'plain'} warp', (tester) async {
      tester.view.physicalSize = const Size(1000, 1800); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      SceneNodePayload? submitted;
      final original = SceneActionPayload.interactive(SceneInteractiveCommand.warp(destinationMapId: 'cave', warpId: 'arrival',
        presentation: illustrated ? SceneWarpPresentation(mode: SceneWarpPresentationMode.illustrated, illustrationElementId: 'picture') : null));
      final project = ProjectManifest(name: 'Warp', maps: const [ProjectMapEntry(id: 'cave', name: 'Cave', relativePath: 'maps/cave.json')],
        tilesets: const [ProjectTilesetEntry(id: 'sheet', name: 'Picture', relativePath: 'picture.png',
          source: ProjectRegularAtlasTilesetSource(assetId: 'sheet', pixelWidth: 4, pixelHeight: 3, tileWidth: 4, tileHeight: 3))],
        elements: const [ProjectElementEntry(id: 'picture', name: 'Cave image', categoryId: 'pictures', tilesetId: 'sheet',
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))])]);
      await tester.pumpWidget(MaterialApp(theme: PokeMapTheme.dark(), home: Scaffold(body: SingleChildScrollView(child: SceneActionBuilder(
        initialCommandId: 'warp', initialPayload: original, project: project,
        pickerOptions: const {NarrativeCommandParameterKind.map: [SceneActionPickerOption(id: 'cave', label: 'Cave')]},
        loadWarpMap: (_) async => MapData(id: 'cave', name: 'Cave', size: const GridSize(width: 8, height: 8),
          warps: const [MapWarp(id: 'arrival', pos: GridPos(x: 2, y: 3), targetMapId: 'cave', targetPos: GridPos(x: 2, y: 3))]),
        onSubmit: (value) => submitted = value))))); await tester.pump();
      final apply = tester.widget<PokeMapButton>(find.byKey(const ValueKey('scene-action-submit')));
      expect(apply.onPressed, isNotNull); apply.onPressed!(); await tester.pump();
      expect(submitted, original);
    });
  }
}
