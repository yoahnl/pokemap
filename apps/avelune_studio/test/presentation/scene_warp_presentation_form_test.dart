import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

ProjectManifest project() => ProjectManifest(name: 'Transitions',
  maps: const [ProjectMapEntry(id: 'cave', name: 'Grotte', relativePath: 'maps/cave.json')],
  tilesets: const [ProjectTilesetEntry(id: 'sheet', name: 'Picture', relativePath: 'tilesets/picture.png',
    source: ProjectRegularAtlasTilesetSource(assetId: 'sheet', pixelWidth: 512, pixelHeight: 384,
      tileWidth: 512, tileHeight: 384))],
  elements: const [ProjectElementEntry(id: 'picture', name: 'Image de la grotte',
    tilesetId: 'sheet', categoryId: 'pictures',
    frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))])]);
SceneActionPayload payload() => SceneActionPayload.interactive(SceneInteractiveCommand.warp(
  destinationMapId: 'cave', warpId: 'arrival',
  presentation: SceneWarpPresentation(mode: SceneWarpPresentationMode.illustrated,
    illustrationElementId: 'picture')));
Finder select(String label) => find.byWidgetPredicate((w) => w is StudioSelect && w.label == label);
StudioButton apply(WidgetTester tester) => tester.widget<StudioButton>(find.byWidgetPredicate(
  (w) => w is StudioButton && w.label == 'Appliquer l’action'));
Future<void> pick(WidgetTester tester, String label, String value) async {
  await tester.tap(find.descendant(of: select(label), matching: find.byType(DropdownButtonFormField<String>)));
  await tester.pumpAndSettle(); await tester.tap(find.text(value).last); await tester.pumpAndSettle();
}
Future<void> pump(WidgetTester tester, List<SceneNodePayload> applied, {ProjectManifest? manifest, SceneActionPayload? current}) async {
  tester.view.physicalSize = const Size(1000, 1800); tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(theme: studioTheme(), home: Scaffold(body: SizedBox(width: 500,
    child: SceneActionForm(project: manifest ?? project(), current: current ?? payload(),
      loadMap: (_) async => MapData(id: 'cave', name: 'Grotte', size: const GridSize(width: 8, height: 8),
        warps: const [MapWarp(id: 'arrival', pos: GridPos(x: 2, y: 3), targetMapId: 'cave', targetPos: GridPos(x: 2, y: 3))]),
      onApply: applied.add))))); await tester.pump();
}
void main() {
  testWidgets('existing illustrated warp reopens with guided native image and exact values', (tester) async {
    final applied = <SceneNodePayload>[]; await pump(tester, applied);
    expect(find.textContaining('paramètres avancés'), findsNothing);
    expect(select('Présentation du passage'), findsOneWidget);
    expect(tester.widget<StudioSelect>(select('Illustration')).options, {'picture': 'Image de la grotte'});
    expect(apply(tester).onPressed, isNotNull);
    await tester.tap(find.text('Appliquer l’action'));
    expect(applied.single, payload());
  });
  testWidgets('switching to cave exit clears the image through the typed builder', (tester) async {
    final applied = <SceneNodePayload>[]; await pump(tester, applied);
    await pick(tester, 'Présentation du passage', 'Sortie de grotte');
    expect(select('Illustration'), findsNothing);
    expect(apply(tester).onPressed, isNotNull);
    await tester.tap(find.text('Appliquer l’action'));
    final command = (applied.single as SceneActionPayload).interactiveCommand! as SceneWarpInteractiveCommand;
    expect(command.presentation!.mode, SceneWarpPresentationMode.caveExit);
    expect(command.presentation!.illustrationElementId, isNull);
    expect(command.presentation!.illustrationHoldMs, isNull);
  });
  testWidgets('unavailable image disables apply and never offers a raw ID field', (tester) async {
    final applied = <SceneNodePayload>[]; await pump(tester, applied, manifest: project().copyWith(elements: []));
    expect(apply(tester).onPressed, isNull);
    expect(find.byKey(const ValueKey('action-warp-illustrationElementId')), findsNothing);
  });
  testWidgets('3D basic warp hides presentation while preserving its existing command', (tester) async {
    final applied = <SceneNodePayload>[]; final p = project();
    final plain = SceneActionPayload.interactive(SceneInteractiveCommand.warp(destinationMapId: 'cave', warpId: 'arrival'));
    await pump(tester, applied, manifest: p.copyWith(settings: p.settings.copyWith(dimension: ProjectDimension.threeD)), current: plain);
    expect(select('Présentation du passage'), findsNothing);
    expect(select('Illustration'), findsNothing);
    expect(apply(tester).onPressed, isNotNull);
    await tester.tap(find.text('Appliquer l’action')); expect(applied.single, plain);
  });
}
