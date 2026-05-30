import 'dart:io';

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

  testWidgets('world rule section shows targeted rules and diagnostics',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: _projectWithWorldRules(
        worldRules: [
          _eventWorldRule(
            id: 'rule_gate',
            label: 'Gate follows fact',
          ),
          _eventWorldRule(
            id: 'rule_other_event',
            label: 'Other event rule',
            eventId: 'event_other',
          ),
          _eventWorldRule(
            id: 'rule_missing_fact',
            label: 'Missing fact rule',
            sourceId: 'missing_fact',
          ),
        ],
      ),
      activeMap: _mapWithEvent(const MapEventPage(pageNumber: 0)),
      activeLayerId: 'l_base',
      selectedMapEventId: 'event_gate',
    );

    await _pumpPanel(tester, container);

    expect(find.byKey(const ValueKey('world-rule-target-section')),
        findsOneWidget);
    expect(find.text('2 liée(s)'), findsOneWidget);
    expect(find.text('Gate follows fact'), findsOneWidget);
    expect(find.text('Other event rule'), findsNothing);
    expect(find.textContaining('Gate unlocked est vrai'), findsOneWidget);
    expect(find.textContaining('Event activé'), findsWidgets);
    expect(find.text('La World Rule référence un Fact absent du projet.'),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('world-rule-toggle-rule_gate')));
    await tester.pumpAndSettle();

    final rule = container
        .read(editorNotifierProvider)
        .project!
        .worldRules
        .firstWhere((worldRule) => worldRule.id == 'rule_gate');
    expect(rule.enabled, isFalse);
    expect(
      container.read(editorNotifierProvider).project!.worldRules,
      hasLength(3),
    );
  });

  testWidgets('world rule creation targets the selected event automatically',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: _projectWithWorldRules(),
      activeMap: _mapWithEvent(const MapEventPage(pageNumber: 0)),
      activeLayerId: 'l_base',
      selectedMapEventId: 'event_gate',
    );

    await _pumpPanel(tester, container);

    expect(
        find.byKey(const ValueKey('world-rule-empty-state')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('world-rule-create-label-field')),
      'Gate opens from fact',
    );
    await tester
        .tap(find.byKey(const ValueKey('world-rule-create-event-rule')));
    await tester.pumpAndSettle();

    final project = container.read(editorNotifierProvider).project!;
    expect(project.worldRules, hasLength(1));
    final rule = project.worldRules.single;
    expect(rule.label, 'Gate opens from fact');
    expect(rule.source.sourceId, 'fact_gate_unlocked');
    expect(rule.target.kind, WorldRuleTargetKind.mapEvent);
    expect(rule.target.mapId, 'map_test');
    expect(rule.target.eventId, 'event_gate');
    expect(rule.target.label, 'Gate');
    expect(rule.effect.kind, WorldRuleEffectKind.eventEnabled);
    expect(rule.enabled, isTrue);
    expect(find.text('Gate opens from fact'), findsOneWidget);
  });

  testWidgets('captures V1-27 World Rules map editor screenshot when requested',
      (tester) async {
    if (!const bool.fromEnvironment('NS_SCENES_V1_27_CAPTURE_SCREENSHOT')) {
      return;
    }
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: _projectWithWorldRules(
        worldRules: [
          _eventWorldRule(
            id: 'rule_gate',
            label: 'Gate follows fact',
          ),
          _eventWorldRule(
            id: 'rule_missing_fact',
            label: 'Missing fact rule',
            sourceId: 'missing_fact',
          ),
        ],
      ),
      activeMap: _mapWithEvent(const MapEventPage(pageNumber: 0)),
      activeLayerId: 'l_base',
      selectedMapEventId: 'event_gate',
    );

    await tester.binding.setSurfaceSize(const Size(900, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData.light(useMaterial3: false),
          darkTheme: ThemeData.dark(useMaterial3: false),
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: ValueKey('ns-scenes-v1-27-screenshot-root'),
                child: SizedBox(
                  width: 520,
                  height: 1450,
                  child: EventPropertiesPanel(embedded: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_27_world_rules_map_editor_integration_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('ns-scenes-v1-27-screenshot-root')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
    expect(find.textContaining('Selbrume'), findsNothing);
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

ProjectManifest _projectWithWorldRules({
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    facts: [
      NarrativeFactDefinition(
        id: 'fact_gate_unlocked',
        label: 'Gate unlocked',
      ),
    ],
    worldRules: worldRules,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

WorldRuleDefinition _eventWorldRule({
  required String id,
  required String label,
  String eventId = 'event_gate',
  String sourceId = 'fact_gate_unlocked',
  bool enabled = true,
}) {
  return WorldRuleDefinition(
    id: id,
    label: label,
    enabled: enabled,
    source: WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: sourceId,
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEvent,
      mapId: 'map_test',
      eventId: eventId,
      label: eventId == 'event_gate' ? 'Gate' : 'Other event',
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
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
