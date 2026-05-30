import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/event_properties_panel.dart';

void main() {
  testWidgets('scene picker selects and clears a real Scene V1 target',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final map = _mapWithEvent(
      const MapEventPage(
        pageNumber: 0,
        message: 'Legacy message',
        script: ScriptRef(scriptId: 'script_intro'),
      ),
    );
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: _projectWithScene(),
      activeMap: map,
      activeLayerId: 'l_base',
      selectedMapEventId: 'event_gate',
    );

    await _pumpPanel(tester, container);

    expect(find.byKey(const ValueKey('event-scene-target-dropdown')),
        findsOneWidget);
    expect(find.text('Lien authoring uniquement, runtime Scene à venir.'),
        findsOneWidget);
    expect(find.textContaining('message ou un script legacy'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('event-scene-target-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Intro Scene (scene_intro)').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-save-page-button')),
    );
    await tester.tap(find.byKey(const ValueKey('event-save-page-button')));
    await tester.pumpAndSettle();

    var page = container
        .read(editorNotifierProvider)
        .activeMap!
        .events
        .single
        .pages
        .single;
    expect(page.sceneTarget, const MapEventSceneTarget(sceneId: 'scene_intro'));
    expect(page.message, 'Legacy message');
    expect(page.script, const ScriptRef(scriptId: 'script_intro'));

    await tester.tap(find.byKey(const ValueKey('event-clear-scene-target')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-save-page-button')),
    );
    await tester.tap(find.byKey(const ValueKey('event-save-page-button')));
    await tester.pumpAndSettle();

    page = container
        .read(editorNotifierProvider)
        .activeMap!
        .events
        .single
        .pages
        .single;
    expect(page.sceneTarget, isNull);
    expect(page.message, 'Legacy message');
    expect(page.script, const ScriptRef(scriptId: 'script_intro'));
    expect(
        container.read(editorNotifierProvider).project!.scenes, hasLength(1));
  });

  testWidgets('scene picker shows an honest empty state when no scenes exist',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: _projectWithoutScenes(),
      activeMap: _mapWithEvent(const MapEventPage(pageNumber: 0)),
      activeLayerId: 'l_base',
      selectedMapEventId: 'event_gate',
    );

    await _pumpPanel(tester, container);

    expect(find.text('Aucune Scene V1 disponible'), findsOneWidget);
    expect(find.text('Aucune Scene V1'), findsOneWidget);
  });
}

Future<void> _pumpPanel(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData.light(useMaterial3: false),
        darkTheme: ThemeData.dark(useMaterial3: false),
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: SizedBox(
            width: 520,
            height: 1450,
            child: EventPropertiesPanel(embedded: true),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MapData _mapWithEvent(MapEventPage page) {
  return MapData(
    id: 'map_test',
    name: 'Test Map',
    size: const GridSize(width: 8, height: 8),
    layers: [
      MapLayer.tile(
        id: 'l_base',
        name: 'Base',
        tiles: List<int>.filled(64, 0),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_gate',
        title: 'Gate',
        position: const EventPosition(layerId: 'l_base', x: 2, y: 2),
        pages: [page],
      ),
    ],
  );
}

ProjectManifest _projectWithScene() {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    scripts: const [
      ProjectScriptEntry(
        id: 'script_intro',
        name: 'Intro Script',
        asset: ScriptAsset(
          id: 'script_intro',
          nodes: [ScriptNode(id: 'start')],
        ),
      ),
    ],
    scenes: [_validScene('scene_intro')],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

ProjectManifest _projectWithoutScenes() {
  return const ProjectManifest(
    name: 'Project',
    maps: [],
    tilesets: [],
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
  );
}

SceneAsset _validScene(String id) {
  return SceneAsset(
    id: id,
    name: 'Intro Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}
