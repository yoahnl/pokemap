import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_context_command.dart';
import 'package:map_editor/src/features/editor/application/map_context_target.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/map_context_menu_controller.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/map_context_menu_host.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('renders one frozen projected menu for pointer and keyboard',
      (tester) async {
    final harness = await _pumpHarness(tester);
    addTearDown(harness.dispose);

    harness.open(
      target: const MapCellContextTarget(
        position: GridPos(x: 2, y: 3),
        layerId: 'ground',
        isPainted: true,
      ),
      invocation: MapContextMenuInvocation.pointer,
    );
    await tester.pump();

    expect(find.byType(PokeMapContextMenu<MapContextCommand>), findsOneWidget);
    final pointerMenu = tester.widget<PokeMapContextMenu<MapContextCommand>>(
      find.byType(PokeMapContextMenu<MapContextCommand>),
    );
    final pointerItems = pointerMenu.items;
    expect(
      pointerItems.map((item) => item.value),
      <MapContextCommand>[
        MapContextCommand.eraseCell,
        MapContextCommand.activateLayer,
        MapContextCommand.copyCoordinates,
      ],
    );
    expect(pointerItems.first.destructive, isTrue);
    expect(pointerItems[1].enabled, isFalse);
    expect(pointerItems[1].disabledReason, 'Ce calque est déjà actif.');
    expect(
      () => harness.openState.entries.clear(),
      throwsUnsupportedError,
    );

    harness.open(
      target: const MapCellContextTarget(
        position: GridPos(x: 2, y: 3),
        layerId: 'ground',
        isPainted: true,
      ),
      invocation: MapContextMenuInvocation.keyboard,
    );
    await tester.pump();

    expect(find.byType(PokeMapContextMenu<MapContextCommand>), findsOneWidget);
    final keyboardMenu = tester.widget<PokeMapContextMenu<MapContextCommand>>(
      find.byType(PokeMapContextMenu<MapContextCommand>),
    );
    expect(
      keyboardMenu.items
          .map((item) => (item.value, item.label, item.enabled))
          .toList(),
      pointerItems
          .map((item) => (item.value, item.label, item.enabled))
          .toList(),
    );
    expect(harness.openState.invocation, MapContextMenuInvocation.keyboard);
  });

  testWidgets('a second open replaces the first menu without stacking',
      (tester) async {
    final harness = await _pumpHarness(tester);
    addTearDown(harness.dispose);

    harness.open(
      target: const MapCellContextTarget(
        position: GridPos(x: 1, y: 1),
        layerId: 'ground',
        isPainted: false,
      ),
      invocation: MapContextMenuInvocation.pointer,
    );
    harness.open(
      target: const MapLayerContextTarget('ground'),
      invocation: MapContextMenuInvocation.keyboard,
    );
    await tester.pump();

    expect(find.byType(PokeMapContextMenu<MapContextCommand>), findsOneWidget);
    expect(harness.openState.target, const MapLayerContextTarget('ground'));
    expect(find.text('Renommer le calque'), findsOneWidget);
    expect(find.text('Copier les coordonnées'), findsNothing);
  });

  testWidgets('open menu blocks the workspace behind it from semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final harness = await _pumpHarness(tester);
    addTearDown(harness.dispose);

    expect(find.semantics.byLabel('Canvas derrière le menu'), findsOneWidget);
    harness.open(
      target: const MapCellContextTarget(
        position: GridPos(x: 1, y: 1),
        layerId: 'ground',
        isPainted: false,
      ),
      invocation: MapContextMenuInvocation.keyboard,
    );
    await tester.pump();
    await tester.pump();

    expect(find.semantics.byLabel('Canvas derrière le menu'), findsNothing);
    expect(
      find.semantics.byLabel('Actions contextuelles de la carte'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('Tab and Shift Tab stay trapped and wrap inside the open menu',
      (tester) async {
    final harness = await _pumpHarness(tester);
    addTearDown(harness.dispose);
    harness.invoker.requestFocus();
    await tester.pump();
    harness.open(
      target: const MapCellContextTarget(
        position: GridPos(x: 1, y: 1),
        layerId: 'ground',
        isPainted: true,
      ),
      invocation: MapContextMenuInvocation.keyboard,
    );
    await tester.pump();
    await tester.pump();

    expect(
        FocusManager.instance.primaryFocus?.debugLabel, 'context menu item 0');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(
        FocusManager.instance.primaryFocus?.debugLabel, 'context menu item 2');

    for (var index = 0; index < 6; index += 1) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(harness.invoker.hasFocus, isFalse);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        startsWith('context menu item '),
      );
    }
  });

  testWidgets('selection, Escape and outside click close and restore invoker',
      (tester) async {
    final harness = await _pumpHarness(tester);
    addTearDown(harness.dispose);
    harness.invoker.requestFocus();
    await tester.pump();

    harness.open(
      target: const MapCellContextTarget(
        position: GridPos(x: 1, y: 1),
        layerId: 'ground',
        isPainted: false,
      ),
      invocation: MapContextMenuInvocation.keyboard,
    );
    await tester.pump();
    await tester.pump();
    expect(harness.invoker.hasFocus, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.byType(PokeMapContextMenu<MapContextCommand>), findsNothing);
    expect(harness.invoker.hasFocus, isTrue);

    harness.open(
      target: const MapCellContextTarget(
        position: GridPos(x: 1, y: 1),
        layerId: 'ground',
        isPainted: false,
      ),
      invocation: MapContextMenuInvocation.pointer,
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('pokemap-context-menu-barrier')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(find.byType(PokeMapContextMenu<MapContextCommand>), findsNothing);
    expect(harness.invoker.hasFocus, isTrue);

    harness.open(
      target: const MapCellContextTarget(
        position: GridPos(x: 1, y: 1),
        layerId: 'ground',
        isPainted: false,
      ),
      invocation: MapContextMenuInvocation.pointer,
    );
    await tester.pump();
    await tester.tap(find.text('Copier les coordonnées'));
    await tester.pump();

    expect(harness.selected, <MapContextCommand>[
      MapContextCommand.copyCoordinates,
    ]);
    expect(find.byType(PokeMapContextMenu<MapContextCommand>), findsNothing);
    expect(harness.invoker.hasFocus, isTrue);
  });

  testWidgets(
      'an async command failure closes, restores focus, and reports sober feedback',
      (tester) async {
    late _Harness harness;
    var focusWasRestoredBeforeCommand = false;
    harness = await _pumpHarness(
      tester,
      onCommandSelected: (command, menu) async {
        focusWasRestoredBeforeCommand = harness.invoker.hasFocus;
        throw StateError('technical storage detail');
      },
    );
    addTearDown(harness.dispose);
    harness.invoker.requestFocus();
    await tester.pump();

    harness.open(
      target: const MapCellContextTarget(
        position: GridPos(x: 1, y: 1),
        layerId: 'ground',
        isPainted: false,
      ),
      invocation: MapContextMenuInvocation.keyboard,
    );
    await tester.pump();
    await tester.pump();
    expect(harness.invoker.hasFocus, isFalse);

    await tester.tap(find.text('Copier les coordonnées'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(PokeMapContextMenu<MapContextCommand>), findsNothing);
    expect(focusWasRestoredBeforeCommand, isTrue);
    expect(harness.invoker.hasFocus, isTrue);
    expect(
      harness.rejected,
      const <String>['Impossible d’exécuter cette action. Réessayez.'],
    );
    expect(harness.rejected.single, isNot(contains('technical')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('map and tool changes close the transient menu', (tester) async {
    final harness = await _pumpHarness(tester);
    addTearDown(harness.dispose);

    harness.open(
      target: const MapCellContextTarget(
        position: GridPos(x: 1, y: 1),
        layerId: 'ground',
        isPainted: false,
      ),
      invocation: MapContextMenuInvocation.pointer,
    );
    harness.container.read(editorNotifierProvider.notifier).state =
        harness.container.read(editorNotifierProvider).copyWith(
              activeTool: EditorToolType.eraser,
            );
    await tester.pump();
    expect(
      harness.container.read(mapContextMenuControllerProvider),
      isA<MapContextMenuClosed>(),
    );

    harness.open(
      target: const MapCellContextTarget(
        position: GridPos(x: 1, y: 1),
        layerId: 'ground',
        isPainted: false,
      ),
      invocation: MapContextMenuInvocation.pointer,
    );
    harness.container.read(editorNotifierProvider.notifier).state =
        harness.container.read(editorNotifierProvider).copyWith(
              activeMap: _map.copyWith(id: 'other-map'),
            );
    await tester.pump();
    expect(
      harness.container.read(mapContextMenuControllerProvider),
      isA<MapContextMenuClosed>(),
    );
  });
}

final class _Harness {
  _Harness({
    required this.container,
    required this.keepAlive,
    required this.editorKeepAlive,
    required this.invoker,
    required this.selected,
    required this.rejected,
  });

  final ProviderContainer container;
  final ProviderSubscription<MapContextMenuState> keepAlive;
  final ProviderSubscription<EditorState> editorKeepAlive;
  final FocusNode invoker;
  final List<MapContextCommand> selected;
  final List<String> rejected;

  MapContextMenuOpen get openState =>
      container.read(mapContextMenuControllerProvider) as MapContextMenuOpen;

  void open({
    required MapContextTarget target,
    required MapContextMenuInvocation invocation,
  }) {
    container.read(mapContextMenuControllerProvider.notifier).open(
          target: target,
          anchor: const Offset(80, 60),
          invocation: invocation,
          map: _map,
          project: null,
          eventBuilderReadModel: null,
          activeLayerId: 'ground',
          invokerFocusNode: invoker,
        );
  }

  void dispose() {
    keepAlive.close();
    editorKeepAlive.close();
    invoker.dispose();
    container.dispose();
  }
}

Future<_Harness> _pumpHarness(
  WidgetTester tester, {
  MapContextCommandSelected? onCommandSelected,
}) async {
  final container = ProviderContainer();
  final editorKeepAlive = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  container.read(editorNotifierProvider.notifier).state = EditorState(
    activeMap: _map,
    activeLayerId: 'ground',
  );
  final keepAlive = container.listen<MapContextMenuState>(
    mapContextMenuControllerProvider,
    (_, __) {},
    fireImmediately: true,
  );
  final invoker = FocusNode(debugLabel: 'map context menu test invoker');
  final selected = <MapContextCommand>[];
  final rejected = <String>[];

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Semantics(
                  label: 'Canvas derrière le menu',
                  child: Focus(
                    focusNode: invoker,
                    child: const SizedBox(width: 32, height: 32),
                  ),
                ),
              ),
              MapContextMenuHost(
                onCommandSelected: onCommandSelected ??
                    (command, menu) async {
                      selected.add(command);
                    },
                onCommandRejected: rejected.add,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return _Harness(
    container: container,
    keepAlive: keepAlive,
    editorKeepAlive: editorKeepAlive,
    invoker: invoker,
    selected: selected,
    rejected: rejected,
  );
}

final _map = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v3,
  size: const GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tilesetId: 'tiles',
      tiles: List<int>.filled(16, 0),
    ),
  ],
);
