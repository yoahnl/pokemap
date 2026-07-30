import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/adaptive_map_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../../../shell_chrome_test_harness.dart';

const _appkitUiElementColorsChannel = MethodChannel('appkit_ui_element_colors');

void main() {
  group('WorldMapWorkspace', () {
    testWidgets(
        'composes Explorer, tool slot, adaptive inspector, and real MapCanvas',
        (tester) async {
      final toolFocusNode = FocusNode(debugLabel: 'workspace tool slot');
      addTearDown(toolFocusNode.dispose);

      await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
        toolFocusNode: toolFocusNode,
      );

      final workspace =
          find.byKey(const ValueKey<String>('world-map-workspace'));
      expect(workspace, findsOneWidget);
      expect(
        find.descendant(
          of: workspace,
          matching: find.byType(ProjectExplorerPanel),
        ),
        findsOneWidget,
      );
      expect(
        _opacity(tester, 'project-explorer-expanded-state'),
        1,
      );
      expect(
        _opacity(tester, 'project-explorer-reduced-state'),
        0,
      );
      expect(find.byType(MapCanvas), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('world-map-tool-slot'),
          ),
          matching: find.byKey(
            const ValueKey<String>('workspace-test-tool-focus'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('world-map-inspector-slot'),
          ),
          matching: find.byType(AdaptiveMapInspector),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.byType(AdaptiveMapInspector),
          matching: find.byType(PokeMapPanel),
        ),
        findsNothing,
        reason: 'AdaptiveMapInspector must own the only inspector panel.',
      );
      expect(
        tester
            .widget<Focus>(
              find.byKey(
                const ValueKey<String>('workspace-test-tool-focus'),
              ),
            )
            .focusNode,
        same(toolFocusNode),
      );
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-close'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('map-canvas-focus')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey<String>('world-map-canvas-region'),
              ),
            )
            .width,
        greaterThanOrEqualTo(PokeMapDesktopLayoutTokens.minCanvasWidth),
      );
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-dock'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-overlay'),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'uses the Explorer rail and inspector overlay without shrinking compact canvas',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(800, 600),
      );

      expect(
        _opacity(tester, 'project-explorer-expanded-state'),
        0,
      );
      expect(
        _opacity(tester, 'project-explorer-reduced-state'),
        1,
      );
      expect(
        find.byKey(
          const ValueKey<String>('project-explorer-reopen-toggle'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-overlay'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-dock'),
        ),
        findsNothing,
      );

      final canvasWidth = tester
          .getSize(
            find.byKey(
              const ValueKey<String>('world-map-canvas-region'),
            ),
          )
          .width;
      expect(
        canvasWidth,
        greaterThanOrEqualTo(PokeMapDesktopLayoutTokens.minCanvasWidth),
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorVisible,
        isTrue,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('project-explorer-reopen-toggle'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(worldMapWorkspaceSessionProvider),
        isA<WorldMapWorkspaceSession>()
            .having((session) => session.explorerExpanded, 'explorer', isTrue)
            .having(
              (session) => session.inspectorVisible,
              'compact inspector',
              isFalse,
            ),
      );
      expect(
        _opacity(tester, 'project-explorer-expanded-state'),
        1,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'closes and reopens the inspector and persists clamped dock resizing in session state',
        (tester) async {
      final toolFocusNode = FocusNode(debugLabel: 'workspace tool slot');
      addTearDown(toolFocusNode.dispose);
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1440, 900),
        toolFocusNode: toolFocusNode,
      );

      final region =
          find.byKey(const ValueKey<String>('right-inspector-region'));
      final handle = find.byKey(
        const ValueKey<String>('right-inspector-resize-handle'),
      );
      expect(tester.getSize(region).width, 360);

      await tester.drag(
        handle,
        const Offset(-52, 0),
        touchSlopX: 0,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(tester.getSize(region).width, 412);
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorWidth,
        412,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('workspace-test-inspector-toggle'),
        ),
      );
      await tester.pumpAndSettle();
      expect(region, findsNothing);
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorVisible,
        isFalse,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('workspace-test-inspector-toggle'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(region).width, 412);
      expect(
        tester
            .widget<Focus>(
              find.byKey(
                const ValueKey<String>('workspace-test-tool-focus'),
              ),
            )
            .focusNode,
        same(toolFocusNode),
      );
      expect(find.byType(AdaptiveMapInspector), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reopens the Explorer beside a docked inspector when both fit',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('project-explorer-toggle')),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(worldMapWorkspaceSessionProvider),
        isA<WorldMapWorkspaceSession>()
            .having((session) => session.explorerExpanded, 'explorer', isFalse)
            .having((session) => session.inspectorVisible, 'inspector', isTrue),
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('project-explorer-reopen-toggle'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(worldMapWorkspaceSessionProvider),
        isA<WorldMapWorkspaceSession>()
            .having((session) => session.explorerExpanded, 'explorer', isTrue)
            .having((session) => session.inspectorVisible, 'inspector', isTrue),
      );
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-dock'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey<String>('world-map-canvas-region'),
              ),
            )
            .width,
        greaterThanOrEqualTo(PokeMapDesktopLayoutTokens.minCanvasWidth),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'compact inspector overlay absorbs padding pointers and keeps controls interactive',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(800, 600),
      );
      final mapFocus = tester
          .widget<Focus>(
            find.byKey(const ValueKey<String>('map-canvas-focus')),
          )
          .focusNode!;
      mapFocus.unfocus();
      await tester.pump();
      expect(mapFocus.hasFocus, isFalse);

      final inspectorRect = tester.getRect(
        find.byKey(const ValueKey<String>('right-inspector-region')),
      );
      await tester.tapAt(
        Offset(inspectorRect.left + 4, inspectorRect.center.dy),
      );
      await tester.pump();

      expect(
        mapFocus.hasFocus,
        isFalse,
        reason: 'overlay padding must not pass the pointer to MapCanvas',
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('world-map-inspector-close'),
        ),
      );
      await tester.pump();
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorVisible,
        isFalse,
      );
      expect(
        find.byKey(const ValueKey<String>('right-inspector-region')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Future<ProviderContainer> _pumpWorkspace(
  WidgetTester tester, {
  required Size surfaceSize,
  FocusNode? toolFocusNode,
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_appkitUiElementColorsChannel, (call) async {
    return switch (call.method) {
      'getColorComponents' => <String, double>{'hueComponent': 0.58},
      'getColor' => 0xFF0A84FF,
      _ => null,
    };
  });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_appkitUiElementColorsChannel, null);
  });

  final container = ProviderContainer();
  final editorSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
  });
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  container.read(editorNotifierProvider.notifier).state = _editorState();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        builder: (context, child) => PokeMapMacosCompatibilityBridge(
          child: child ?? const SizedBox.shrink(),
        ),
        home: Material(
          child: WorldMapWorkspace(
            toolSlot: _TestToolSlot(focusNode: toolFocusNode),
            stageHeaderSlot: const SizedBox(
              key: ValueKey<String>('workspace-test-stage-header'),
              height: 36,
            ),
            explorerBuilder: (context, onCollapse) {
              return ProjectExplorerPanel(onCollapse: onCollapse);
            },
            explorerRailBuilder: (context, onReopen) {
              return PokeMapButton(
                key: const ValueKey<String>(
                  'project-explorer-reopen-toggle',
                ),
                onPressed: onReopen,
                size: PokeMapButtonSize.compact,
                child: const Text('Rouvrir'),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

double _opacity(WidgetTester tester, String key) {
  return tester
      .widget<AnimatedOpacity>(find.byKey(ValueKey<String>(key)))
      .opacity;
}

EditorState _editorState() {
  final map = buildShellChromeMap(
    id: 'workspace_map',
    name: 'Workspace Map',
    width: 8,
    height: 8,
    layers: const <MapLayer>[
      TileLayer(
        id: 'ground',
        name: 'Ground',
        tiles: <int>[],
      ),
    ],
  );
  return EditorState(
    projectRootPath: '/tmp/world_map_workspace_test',
    project: buildShellChromeProject(
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'workspace_map',
          name: 'Workspace Map',
          relativePath: 'maps/workspace_map.json',
        ),
      ],
    ),
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: map,
    activeLayerId: 'ground',
    savedMapSnapshot: map,
  );
}

class _TestToolSlot extends ConsumerWidget {
  const _TestToolSlot({this.focusNode});

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectorVisible = ref.watch(
      worldMapWorkspaceSessionProvider.select(
        (session) => session.inspectorVisible,
      ),
    );
    return Focus(
      key: const ValueKey<String>('workspace-test-tool-focus'),
      focusNode: focusNode,
      child: PokeMapButton(
        key: const ValueKey<String>('workspace-test-inspector-toggle'),
        onPressed: () {
          ref
              .read(worldMapWorkspaceSessionProvider.notifier)
              .setInspectorVisible(!inspectorVisible);
        },
        child: Text(inspectorVisible ? 'Fermer' : 'Rouvrir'),
      ),
    );
  }
}
