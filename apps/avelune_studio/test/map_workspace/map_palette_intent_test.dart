import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_palette_intent.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

const _alice = ProjectCharacterEntry(
  id: 'alice',
  name: 'Alice',
  tilesetId: 'atlas',
);

void main() {
  test('choosing decors without a decor names an unarmed selection', () {
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    view
      ..paletteTab = 'Décors'
      ..tool = StudioMapTool.select;
    final intent = mapPaletteIntent(view);
    expect(intent.action, 'Sélection');
    expect(intent.armed, isFalse);
    expect(intent.next, contains('Choisissez un décor'));
    view
      ..brush = workspaceElement
      ..tool = StudioMapTool.place;
    final armed = mapPaletteIntent(view);
    expect(armed.action, 'Placement de décor');
    expect(armed.group, MapIntentGroup.build);
    expect(armed.resource, 'Arbre');
    expect(armed.paletteTab, 'Décors');
    expect(armed.armed, isTrue);
  });

  test('moving from a cliff to a character never keeps the border active', () {
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    view
      ..paletteTab = 'Bordures'
      ..tool = StudioMapTool.border
      ..borderBlueprintId = 'falaise';
    expect(mapPaletteIntent(view).action, 'Tracé de bordure');
    view.character = _alice;
    view.prepareCharacterPlacement();
    final intent = mapPaletteIntent(view);
    expect(intent.group, MapIntentGroup.populate);
    expect(intent.action, 'Placement de personnage');
    expect(intent.paletteTab, 'Personnages');
    expect(intent.resource, 'Alice');
    expect(intent.resource, isNot(contains('falaise')));
  });

  test('collisions and spawn use no resource palette', () {
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    for (final tool in [
      StudioMapTool.collisionPaint,
      StudioMapTool.collisionErase,
      StudioMapTool.spawn,
      StudioMapTool.gameplayZone,
    ]) {
      view.tool = tool;
      final intent = mapPaletteIntent(view);
      expect(intent.paletteTab, isNull, reason: '$tool');
      expect(intent.armed, isTrue, reason: '$tool');
    }
  });

  testWidgets('decors without a decor shows the next step near the map', (
    tester,
  ) async {
    final view = await _mount(tester);
    await tester.tap(find.widgetWithText(StudioButton, 'Décors'));
    await tester.pumpAndSettle();
    expect(view.tool, StudioMapTool.select);
    final status = find.byKey(const ValueKey('map-intent-status'));
    expect(status, findsOneWidget);
    expect(
      find.descendant(
        of: status,
        matching: find.textContaining('Choisissez un décor'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('populate intents are visible and no longer duplicated in …', (
    tester,
  ) async {
    final view = await _mount(tester);
    await tester.tap(find.byTooltip('Autres outils de carte'));
    await tester.pumpAndSettle();
    for (final label in [
      'Passages',
      'Connexions',
      'Dessiner une zone de jeu',
      'Peindre les collisions',
      'Effacer les collisions',
      'Placer un personnage',
      'Placer le départ du joueur',
    ]) {
      expect(
        find.widgetWithText(PopupMenuItem<String>, label),
        findsNothing,
        reason: label,
      );
    }
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Peupler la carte'));
    await tester.pumpAndSettle();
    for (final label in [
      'Placer un personnage',
      'Placer le départ du joueur',
      'Placer un panneau',
      'Placer un arbre à couper',
    ]) {
      expect(
        find.widgetWithText(PopupMenuItem<String>, label),
        findsOneWidget,
        reason: label,
      );
    }
    await tester.tap(
      find.widgetWithText(PopupMenuItem<String>, 'Placer le départ du joueur'),
    );
    await tester.pumpAndSettle();
    expect(view.tool, StudioMapTool.spawn);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-intent-status')),
        matching: find.textContaining('Départ du joueur'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('collisions name the unused palette and can reopen it', (
    tester,
  ) async {
    final view = await _mount(tester);
    await tester.tap(find.widgetWithText(StudioButton, 'Environnements'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(StudioButton, 'Collisions'));
    await tester.pumpAndSettle();
    expect(view.paletteTab, 'Environnements');
    expect(find.byKey(const ValueKey('map-palette-not-used')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-palette-reveal')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-palette-not-used')), findsNothing);
    expect(view.tool, StudioMapTool.collisionPaint);
    await tester.tap(find.widgetWithText(StudioButton, 'Sélection'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(StudioButton, 'Collisions'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-palette-not-used')), findsOneWidget);
  });

  testWidgets(
    'connections without their panel say why instead of pointing right',
    (tester) async {
      await _mount(tester);
      await tester.tap(find.widgetWithText(StudioButton, 'Connexions'));
      await tester.pumpAndSettle();
      expect(find.textContaining('à droite'), findsNothing);
      expect(find.textContaining('dans le panneau de droite'), findsNothing);
      expect(
        find.textContaining(
          'Les connexions entre cartes ne sont pas modifiables',
        ),
        findsWidgets,
      );
    },
  );

  testWidgets('3D maps offer zones from no tool menu', (tester) async {
    await _mount(tester, spatial: true);
    final zones = tester.widget<StudioButton>(
      find.descendant(
        of: find.byType(MapWorkspaceToolStrip),
        matching: find.widgetWithText(StudioButton, 'Zones'),
      ),
    );
    expect(zones.onPressed, isNull);
    for (final menu in ['Autres outils de carte', 'Peupler la carte']) {
      await tester.tap(find.byTooltip(menu));
      await tester.pumpAndSettle();
      for (final item in tester.widgetList<PopupMenuItem<String>>(
        find.byType(PopupMenuItem<String>),
      )) {
        if (item.value?.contains('zone') ?? false) {
          expect(item.enabled, isFalse, reason: item.value);
        }
      }
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
    }
  });
}

Future<MapWorkspaceViewState> _mount(
  WidgetTester tester, {
  bool spatial = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1600, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final port = WorkspaceMemoryPort();
  if (spatial) port.saved['a'] = spatialEnvironmentMap();
  final controller = MapWorkspaceController(workspaceSession, port);
  await controller.initialize();
  final view = MapWorkspaceViewState();
  final search = TextEditingController();
  final homeSearch = TextEditingController();
  addTearDown(controller.dispose);
  addTearDown(view.dispose);
  addTearDown(search.dispose);
  addTearDown(homeSearch.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: StatefulBuilder(
        builder: (context, update) => MapWorkspaceLayout(
          controller: controller,
          view: view,
          visuals: WorkspaceTestVisuals(),
          search: search,
          homeSearch: homeSearch,
          error: null,
          palette: true,
          inspector: null,
          generation: 0,
          onPalette: () {},
          onInspector: () {},
          onChanged: () => update(() {}),
          onToolChanged: () => update(() {}),
          onActivate: (_) {},
          onSave: () => controller.save(controller.active!),
          onTest: () {},
          onClose: () {},
          onResources: () {},
          onMap: () {},
          onExport: () {},
          onPokemon: () {},
          onOpenElement: (_) {},
          onEditElement: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
  return view;
}
