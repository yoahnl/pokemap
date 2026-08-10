import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_scene_focus_provider.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart';

void main() {
  test('Event diagnostic keeps the exact event, map and dependency path', () {
    const diagnostic = NarrativeProjectDiagnostic(
      code: 'narrativeEventSourceMissing',
      severity: NarrativeProjectDiagnosticSeverity.error,
      domain: NarrativeProjectDiagnosticDomain.event,
      message: 'Source absente.',
      path: 'eventRegistry.records.evt_port.source',
      destination: NarrativeProjectDiagnosticDestination.event,
      mapId: 'map_port',
      eventId: 'evt_port',
    );

    final resolution = resolveNarrativeProjectDiagnostic(diagnostic);

    expect(resolution.kind, NarrativeStudioNavigationResolutionKind.internal);
    expect(resolution.location?.destination, NarrativeStudioDestination.events);
    expect(
        resolution.location?.selection?.kind, NarrativeStudioAssetKind.event);
    expect(resolution.location?.selection?.assetId, 'evt_port');
    expect(resolution.location?.selection?.parentId, 'map_port');
    expect(
      resolution.location?.selection?.sourceContext,
      'eventRegistry.records.evt_port.source',
    );
  });

  testWidgets('Scene validation destination focuses the exact Scene safely',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = ProjectManifest(
      name: 'Validation navigation',
      maps: const [],
      tilesets: const [],
      scenes: [_scene('scene_a'), _scene('scene_b')],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(editorNotifierProvider, (_, _) {});
    addTearDown(subscription.close);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: project,
      workspaceMode: EditorWorkspaceMode.scenes,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          darkTheme: PokeMapTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: SizedBox(
              width: 1440,
              height: 900,
              child: NarrativeWorkspaceCanvas(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('scenes-selected-summary-scene_a')),
      findsOneWidget,
    );

    container.read(narrativeSceneFocusProvider.notifier).focus('scene_b');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('scenes-selected-summary-scene_b')),
      findsOneWidget,
    );

    container.read(narrativeSceneFocusProvider.notifier).focus('scene_deleted');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('scenes-selected-summary-scene_b')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('scenes-route-restoration-failure')),
      findsNothing,
    );
    expect(container.read(editorNotifierProvider).project, same(project));
  });
}

SceneAsset _scene(String id) {
  return SceneAsset(
    id: id,
    name: 'Scene $id',
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
