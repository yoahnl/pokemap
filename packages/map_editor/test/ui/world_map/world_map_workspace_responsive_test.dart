import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_context_target.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/map_context_menu_controller.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_toolbelt.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  for (final brightness in <Brightness>[
    Brightness.light,
    Brightness.dark,
  ]) {
    for (final size in <Size>[
      const Size(800, 600),
      const Size(1279, 800),
      const Size(1280, 800),
      const Size(1281, 800),
      const Size(1439, 900),
      const Size(1440, 900),
      const Size(1441, 900),
    ]) {
      testWidgets(
        '${brightness.name} workspace stays usable at '
        '${size.width.toInt()}×${size.height.toInt()}',
        (tester) async {
          await _pumpWorkspace(
            tester,
            size: size,
            brightness: brightness,
          );

          expect(tester.takeException(), isNull);
          final viewport = Offset.zero & size;
          final canvasFinder = find.byKey(
            const ValueKey<String>('world-map-canvas-region'),
          );
          final canvasRect = _expectFullyOnScreen(
            tester,
            canvasFinder,
            viewport,
            reason: 'visible canvas at $size',
          );
          var visibleCanvasWidth = canvasRect.width;
          final inspectorOverlay = find.byKey(
            const ValueKey<String>('world-map-inspector-overlay'),
          );
          if (inspectorOverlay.hitTestable().evaluate().isNotEmpty) {
            final overlap = canvasRect.intersect(
              tester.getRect(inspectorOverlay.hitTestable()),
            );
            visibleCanvasWidth -= overlap.width;
          }
          expect(
            visibleCanvasWidth,
            greaterThanOrEqualTo(PokeMapDesktopLayoutTokens.minCanvasWidth),
            reason: 'actual unobscured canvas width at $size',
          );

          const enabledCriticalKeys = <String>[
            'world-map-command-save',
            'world-map-command-undo',
            'world-map-command-redo',
            'world-map-command-plus',
            'world-map-tool-selection',
            'world-map-tool-paint',
            'world-map-tool-erase',
            'world-map-tool-place',
            'world-map-tool-layers',
            'world-map-inspector-close',
          ];
          for (final key in enabledCriticalKeys) {
            _expectCriticalAction(
              tester,
              key: key,
              viewport: viewport,
              enabled: true,
              size: size,
            );
          }
          _expectCriticalAction(
            tester,
            key: 'world-map-inspector-pin',
            viewport: viewport,
            enabled: false,
            size: size,
          );

          final budget = PokeMapDesktopLayout.resolve(size);
          final activeExplorerKey = budget.explorerIsExpanded
              ? 'responsive-explorer-collapse'
              : 'responsive-explorer-reopen';
          final hiddenExplorerKey = budget.explorerIsExpanded
              ? 'responsive-explorer-reopen'
              : 'responsive-explorer-collapse';
          _expectCriticalAction(
            tester,
            key: activeExplorerKey,
            viewport: viewport,
            enabled: true,
            size: size,
          );
          expect(
            find.byKey(ValueKey<String>(hiddenExplorerKey)).hitTestable(),
            findsNothing,
          );

          if (!budget.explorerIsExpanded) {
            await tester.tap(
              find.byKey(
                const ValueKey<String>('world-map-inspector-close'),
              ),
            );
            await tester.pump();
            _expectCriticalAction(
              tester,
              key: 'responsive-explorer-collapse',
              viewport: viewport,
              enabled: true,
              size: size,
            );
          }
        },
      );
    }
  }

  testWidgets(
    'context menu opened near the compact viewport edge stays visible '
    'and restores its canvas invoker',
    (tester) async {
      const size = Size(800, 600);
      final viewport = Offset.zero & size;
      final container = await _pumpWorkspace(
        tester,
        size: size,
        brightness: Brightness.light,
      );
      final mapFocus = tester
          .widget<Focus>(
            find.byKey(const ValueKey<String>('map-canvas-focus')),
          )
          .focusNode!;
      mapFocus.requestFocus();
      await tester.pump();
      expect(mapFocus.hasFocus, isTrue);

      final edgeAnchor = viewport.bottomRight - const Offset(4, 4);
      final opened =
          container.read(mapContextMenuControllerProvider.notifier).open(
                target: const MapCellContextTarget(
                  position: GridPos(x: 7, y: 7),
                  layerId: 'ground',
                  isPainted: false,
                ),
                anchor: edgeAnchor,
                invocation: MapContextMenuInvocation.pointer,
                map: _map,
                project: _state.project,
                eventBuilderReadModel: null,
                activeLayerId: 'ground',
                invokerFocusNode: mapFocus,
              );
      expect(opened, isTrue);
      expect(
        viewport.right - edgeAnchor.dx,
        lessThanOrEqualTo(4),
      );
      expect(
        viewport.bottom - edgeAnchor.dy,
        lessThanOrEqualTo(4),
      );
      await tester.pump();
      await tester.pump();

      final menu = find.byWidgetPredicate(
        (widget) => widget is PokeMapContextMenu,
      );
      expect(menu, findsOneWidget);
      final menuPanel = find.descendant(
        of: menu,
        matching: find.byType(PokeMapPanel),
      );
      expect(menuPanel, findsOneWidget);
      _expectFullyOnScreen(
        tester,
        menuPanel,
        viewport,
        reason: 'context menu panel',
      );
      final rows = find.descendant(
        of: menu,
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.button == true,
        ),
      );
      expect(rows, findsWidgets);
      for (final element in rows.evaluate()) {
        _expectFullyOnScreen(
          tester,
          find.byElementPredicate((candidate) => candidate == element),
          viewport,
          reason: 'context menu row',
        );
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump();
      expect(menu, findsNothing);
      expect(mapFocus.hasFocus, isTrue);
    },
  );

  testWidgets(
    'long French labels remain overflow-free at 200 percent text scale',
    (tester) async {
      await _pumpWorkspace(
        tester,
        size: const Size(800, 600),
        brightness: Brightness.light,
        textScale: 2,
      );

      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: exception is FlutterError
            ? '${exception.toStringDeep()}\n${_overflowingFlexes(tester)}'
            : null,
      );
      expect(find.byTooltip('Enregistrer (Cmd/Ctrl+S)'), findsOneWidget);
      expect(
        find.byTooltip('Rétablir (Shift+Cmd/Ctrl+Z ou Cmd/Ctrl+Y)'),
        findsOneWidget,
      );
      expect(find.byTooltip('Sélectionner et manipuler'), findsOneWidget);
      expect(find.byTooltip('Ouvrir la gestion des calques'), findsOneWidget);
    },
  );
}

void _expectCriticalAction(
  WidgetTester tester, {
  required String key,
  required Rect viewport,
  required bool enabled,
  required Size size,
}) {
  final finder = find.byKey(ValueKey<String>(key));
  final rect = _expectFullyOnScreen(
    tester,
    finder,
    viewport,
    reason: '$key at $size',
  );
  expect(rect.width, greaterThanOrEqualTo(36), reason: '$key width at $size');
  expect(rect.height, greaterThanOrEqualTo(36), reason: '$key height at $size');

  final buttonSemantics = find.descendant(
    of: finder,
    matching: find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.button == true,
    ),
  );
  expect(buttonSemantics, findsWidgets, reason: '$key semantics at $size');
  final semanticWidgets = buttonSemantics
      .evaluate()
      .map((element) => element.widget)
      .whereType<Semantics>()
      .toList(growable: false);
  final focusDetectors = find
      .descendant(
        of: finder,
        matching: find.byType(FocusableActionDetector),
      )
      .evaluate()
      .map((element) => element.widget)
      .whereType<FocusableActionDetector>()
      .toList(growable: false);
  expect(focusDetectors, isNotEmpty, reason: '$key focus target at $size');

  if (enabled) {
    expect(finder.hitTestable(), findsOneWidget,
        reason: '$key hit test at $size');
    expect(
      semanticWidgets.any((widget) => widget.properties.enabled == true),
      isTrue,
      reason: '$key enabled semantics at $size',
    );
    expect(
      focusDetectors.any((widget) => widget.enabled),
      isTrue,
      reason: '$key focusability at $size',
    );
  } else {
    expect(
      semanticWidgets.any((widget) => widget.properties.enabled == false),
      isTrue,
      reason: '$key disabled-but-visible semantics at $size',
    );
    expect(
      focusDetectors.every((widget) => !widget.enabled),
      isTrue,
      reason: '$key must not enter focus traversal at $size',
    );
  }
}

Rect _expectFullyOnScreen(
  WidgetTester tester,
  Finder finder,
  Rect viewport, {
  required String reason,
}) {
  expect(finder, findsOneWidget, reason: reason);
  final rect = tester.getRect(finder);
  expect(rect.width, greaterThan(0), reason: '$reason width');
  expect(rect.height, greaterThan(0), reason: '$reason height');
  expect(rect.left, greaterThanOrEqualTo(viewport.left),
      reason: '$reason left');
  expect(rect.top, greaterThanOrEqualTo(viewport.top), reason: '$reason top');
  expect(
    rect.right,
    lessThanOrEqualTo(viewport.right),
    reason: '$reason right',
  );
  expect(
    rect.bottom,
    lessThanOrEqualTo(viewport.bottom),
    reason: '$reason bottom',
  );
  return rect;
}

String _overflowingFlexes(WidgetTester tester) {
  final diagnostics = <String>[];
  for (final flex in tester.allRenderObjects.whereType<RenderFlex>()) {
    RenderBox? child = flex.firstChild;
    var maxRight = 0.0;
    var maxBottom = 0.0;
    while (child != null) {
      final data = child.parentData! as FlexParentData;
      final childRight = data.offset.dx + child.size.width;
      final childBottom = data.offset.dy + child.size.height;
      if (childRight > maxRight) maxRight = childRight;
      if (childBottom > maxBottom) maxBottom = childBottom;
      child = flex.childAfter(child);
    }
    if (maxRight > flex.size.width + 0.1 ||
        maxBottom > flex.size.height + 0.1) {
      diagnostics.add(
        '${flex.debugCreator}: size=${flex.size}, '
        'childrenEnd=($maxRight, $maxBottom)',
      );
    }
  }
  return diagnostics.join('\n');
}

Future<ProviderContainer> _pumpWorkspace(
  WidgetTester tester, {
  required Size size,
  required Brightness brightness,
  double textScale = 1,
}) async {
  final container = ProviderContainer();
  final subscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    subscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
  });
  container.read(editorNotifierProvider.notifier).state = _state;
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final theme = brightness == Brightness.dark
      ? PokeMapTheme.dark()
      : PokeMapTheme.light();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Material(
            child: WorldMapWorkspace(
              onTargetEditorRequested: (_) async {},
              toolSlot: WorldMapToolbelt(
                onSave: () {},
                onUndo: () {},
                onRedo: () {},
                onNewProject: () {},
                onOpenProject: () {},
                onProjectSettings: () {},
                onExportGame: () {},
                onNewMap: () {},
                onResizeMap: () {},
              ),
              stageHeaderSlot: const SizedBox(height: 36),
              explorerBuilder: (context, onCollapse) => Align(
                alignment: Alignment.topLeft,
                child: PokeMapButton(
                  key: const ValueKey<String>('responsive-explorer-collapse'),
                  onPressed: onCollapse,
                  size: PokeMapButtonSize.compact,
                  child: const Text('Réduire l’explorateur'),
                ),
              ),
              explorerRailBuilder: (context, onReopen) => PokeMapIconButton(
                key: const ValueKey<String>('responsive-explorer-reopen'),
                onPressed: onReopen,
                size: 36,
                tooltip: 'Rouvrir l’explorateur',
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

final _map = MapData(
  id: 'responsive-map',
  name: 'Carte responsive',
  size: const GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Sol',
      tiles: List<int>.filled(64, 0, growable: false),
    ),
  ],
);

final _state = EditorState(
  project: const ProjectManifest(
    name: 'Responsive',
    tilesets: <ProjectTilesetEntry>[],
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'responsive-map',
        name: 'Carte responsive',
        relativePath: 'maps/responsive.json',
      ),
    ],
  ),
  activeMap: _map,
  activeLayerId: 'ground',
  savedMapSnapshot: _map,
  canUndoMap: true,
  canRedoMap: true,
);
