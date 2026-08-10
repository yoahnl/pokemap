import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_toolbelt.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('Escape steps out of the environment page back to the layers',
      (tester) async {
    final container = await _pumpWorkspace(tester);
    container
        .read(worldMapWorkspaceSessionProvider.notifier)
        .pinInspector(WorldMapInspectorKind.environment);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    final session = container.read(worldMapWorkspaceSessionProvider);
    expect(session.pinnedInspectorKind, isNull);
    expect(session.activeFamily, WorldMapToolFamily.layers);
  });

  testWidgets('Escape outside a layer sub-page leaves the session alone',
      (tester) async {
    final container = await _pumpWorkspace(tester);
    final before = container.read(worldMapWorkspaceSessionProvider);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(container.read(worldMapWorkspaceSessionProvider), before);
  });
}

Future<ProviderContainer> _pumpWorkspace(WidgetTester tester) async {
  final container = ProviderContainer();
  // Escape is bound on the workspace subtree, so the test needs a focus node
  // inside it — the inspector's is the one a real author would be holding.
  final inspectorFocus = FocusNode(debugLabel: 'inspector');
  addTearDown(inspectorFocus.dispose);
  final subscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, _) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    subscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
  });
  container.read(editorNotifierProvider.notifier).state = _state;
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Material(
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
            inspectorFocusNode: inspectorFocus,
            stageHeaderSlot: const SizedBox(height: 36),
            explorerBuilder: (context, onCollapse) => const SizedBox.shrink(),
            explorerRailBuilder: (context, onReopen) => PokeMapIconButton(
              onPressed: onReopen,
              size: 36,
              tooltip: 'Rouvrir l’explorateur',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  inspectorFocus.requestFocus();
  await tester.pump();
  return container;
}

final _map = MapData(
  id: 'escape-map',
  name: 'Carte',
  size: const GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Sol',
      cells: List<int>.filled(64, 0, growable: false),
    ),
  ],
);

final _state = EditorState(
  project: const ProjectManifest(
    name: 'Escape',
    tilesets: <ProjectTilesetEntry>[],
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'escape-map',
        name: 'Carte',
        relativePath: 'maps/escape.json',
      ),
    ],
  ),
  activeMap: _map,
  activeLayerId: 'ground',
  savedMapSnapshot: _map,
);
