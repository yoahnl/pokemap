import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_legacy_migration_center.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_graph_read_only_view.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_node_read_only_inspector.dart';

void main() {
  testWidgets('full shell and migration state expose named semantic routes',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        NarrativeStudioProductShell(
          selectedDestination: NarrativeStudioDestination.cinematics,
          selectedLocation: NarrativeStudioRouteLocation.cinematics(),
          onSelectDestination: (_) {},
          onSelectLocation: (_) {},
          onOpenMaps: () {},
          workspace: NarrativeLegacyMigrationCenter(scan: _scan()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byKey(narrativeStudioProductShellKey)).label,
      contains('PokeMap, Narrative Studio'),
    );
    expect(
      tester.getSemantics(find.byKey(narrativeLegacyMigrationCenterKey)).label,
      contains('Narrative Studio legacy migration center'),
    );
    for (final key in const <ValueKey<String>>[
      ValueKey('narrative-studio-product-nav-overview'),
      ValueKey('narrative-studio-product-nav-storylines'),
      ValueKey('narrative-studio-product-nav-scenes'),
      ValueKey('narrative-studio-product-nav-events'),
      ValueKey('narrative-studio-product-nav-cinematics'),
      ValueKey('narrative-studio-product-nav-dialogues'),
      ValueKey('narrative-studio-product-nav-facts'),
      ValueKey('narrative-studio-product-nav-worldRules'),
      ValueKey('narrative-studio-product-nav-validator'),
    ]) {
      final navigationItem = find.byKey(key);
      final node = tester.getSemantics(
        find
            .descendant(
              of: navigationItem,
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue,
          reason: '$key');
      expect(node.getSemanticsData().label, isNotEmpty, reason: '$key');
    }
    semantics.dispose();
  });

  testWidgets('Scene graph input and output ports have semantic labels',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final scene = _sceneSummary();
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 900,
          height: 600,
          child: SceneGraphReadOnlyView(
            scene: scene,
            expandToFill: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Input port for node end'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Output port .+ for node start')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets(
    'Presentation cinematic nodes stay distinct in read-only Scene UI',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final scene = _presentationSceneSummary();

      await tester.pumpWidget(
        _host(
          Row(
            children: [
              Expanded(
                child: SceneGraphReadOnlyView(
                  scene: scene,
                  expandToFill: true,
                ),
              ),
              SizedBox(
                width: 380,
                child: SceneNodeReadOnlyInspector(
                  scene: scene,
                  selectedNodeId: 'presentation',
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Cinématique de présentation'),
        findsAtLeastNWidgets(2),
      );
      expect(find.text('presentationCinematicId'), findsOneWidget);
      expect(find.text('opening'), findsOneWidget);
      expect(find.text('presentation'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Input port for node presentation'),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );
}

NarrativeLegacyMigrationScan _scan() => NarrativeLegacyMigrationScan(
      schemaVersion: 1,
      minimumProjectVersion: 'v1',
      domains: const [
        NarrativeLegacyMigrationDomainScan(
          domain: NarrativeLegacyDomain.storyline,
          remainingCount: 0,
          readyCount: 0,
          blockerCount: 0,
          lossRiskCount: 0,
          dependencyCount: 0,
        ),
        NarrativeLegacyMigrationDomainScan(
          domain: NarrativeLegacyDomain.event,
          remainingCount: 1,
          readyCount: 0,
          blockerCount: 1,
          lossRiskCount: 1,
          dependencyCount: 1,
        ),
        NarrativeLegacyMigrationDomainScan(
          domain: NarrativeLegacyDomain.cinematic,
          remainingCount: 0,
          readyCount: 0,
          blockerCount: 0,
          lossRiskCount: 0,
          dependencyCount: 0,
        ),
      ],
    );

NarrativeSceneSummary _sceneSummary() {
  final scene = SceneAsset(
    id: 'scene_ports',
    name: 'Ports',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'start', x: 80, y: 120),
        SceneNodeLayout(nodeId: 'end', x: 440, y: 120),
      ],
    ),
  );
  final project = ProjectManifest(
    name: 'semantics',
    maps: const [],
    tilesets: const [],
    scenes: [scene],
  );
  return buildNarrativeWorkspaceProjection(project).scenes.single;
}

NarrativeSceneSummary _presentationSceneSummary() {
  final scene = SceneAsset(
    id: 'scene_presentation',
    name: 'Presentation',
    executionProfile: SceneExecutionProfile.preSession,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'presentation',
          kind: SceneNodeKind.presentationCinematic,
          payload: ScenePresentationCinematicPayload(
            presentationCinematicId: 'opening',
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_presentation',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'presentation',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_presentation_end',
          fromNodeId: 'presentation',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.presentationCompleted,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'start', x: 40, y: 120),
        SceneNodeLayout(nodeId: 'presentation', x: 340, y: 120),
        SceneNodeLayout(nodeId: 'end', x: 640, y: 120),
      ],
    ),
  );
  return NarrativeSceneSummary(
    id: scene.id,
    name: scene.name,
    nodeCount: scene.graph.nodes.length,
    edgeCount: scene.graph.edges.length,
    declaredOutcomeCount: 0,
    declaredOutcomes: const [],
    tags: const [],
    graph: scene.graph,
    layout: scene.layout,
    diagnostics: diagnoseScene(scene),
    outcomeDefinitions: const [],
  );
}

Widget _host(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: PokeMapTheme.dark(),
      home: Scaffold(body: child),
    );
