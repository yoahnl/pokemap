import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';

void main() {
  testWidgets('Facts manager opens from sidebar and edits bool facts',
      (tester) async {
    final container = await _pumpNarrativeShell(
      tester,
      project: _project(),
      workspaceMode: EditorWorkspaceMode.narrativeOverview,
      activeMap: _map(),
    );

    await tester
        .tap(find.byKey(const ValueKey('narrative-studio-sidebar-facts')));
    await tester.pumpAndSettle();

    expect(container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.facts);
    expect(find.byKey(const ValueKey('facts-world-rules-workspace')),
        findsOneWidget);
    expect(find.text('Facts & World Rules'), findsNothing);
    expect(find.text('Faits du monde et changements visibles, sans ID manuel.'),
        findsNothing);
    expect(find.byKey(const ValueKey('facts-manager-empty-state')),
        findsOneWidget);
    expect(find.text('Facts'), findsWidgets);
    expect(find.textContaining('Nécessite un modèle'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('facts-create-name-field')),
      'Bridge lowered',
    );
    await tester.tap(find.byKey(const ValueKey('facts-create-submit')));
    await tester.pumpAndSettle();

    var updatedProject = container.read(editorNotifierProvider).project!;
    expect(updatedProject.facts.single.id, 'fact_bridge_lowered');
    expect(updatedProject.facts.single.label, 'Bridge lowered');
    expect(find.text('Bridge lowered'), findsWidgets);
    expect(find.text('fact_bridge_lowered'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('fact-editor-label-field')),
      'Bridge is lowered',
    );
    await tester.enterText(
      find.byKey(const ValueKey('fact-editor-description-field')),
      'Readable persistent world state.',
    );
    await tester.enterText(
      find.byKey(const ValueKey('fact-editor-category-field')),
      'Progression',
    );
    await tester.tap(find.byKey(const ValueKey('fact-editor-default-toggle')));
    await tester.tap(find.byKey(const ValueKey('fact-editor-save')));
    await tester.pumpAndSettle();

    updatedProject = container.read(editorNotifierProvider).project!;
    expect(updatedProject.facts.single.label, 'Bridge is lowered');
    expect(updatedProject.facts.single.description,
        'Readable persistent world state.');
    expect(updatedProject.facts.single.category, 'Progression');
    expect(updatedProject.facts.single.defaultValue, isTrue);

    await tester.tap(find.byKey(const ValueKey('fact-editor-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('facts-confirm-delete')));
    await tester.pumpAndSettle();

    expect(container.read(editorNotifierProvider).project!.facts, isEmpty);
  });

  testWidgets(
      'World Rules manager creates, toggles and deletes a fact to event rule',
      (tester) async {
    final fact = NarrativeFactDefinition(
      id: 'fact_gate_open',
      label: 'Gate open',
      category: 'World',
    );
    final container = await _pumpNarrativeShell(
      tester,
      project: _project(facts: [fact]),
      workspaceMode: EditorWorkspaceMode.narrativeOverview,
      activeMap: _map(),
    );

    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-sidebar-world-rules')),
    );
    await tester.pumpAndSettle();

    expect(container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.worldRules);
    expect(find.text('Facts & World Rules'), findsNothing);
    expect(find.text('Faits du monde et changements visibles, sans ID manuel.'),
        findsNothing);
    expect(find.byKey(const ValueKey('world-rules-manager-empty-state')),
        findsOneWidget);
    expect(find.text('Règles du monde'), findsWidgets);
    expect(find.text('Gate open'), findsWidgets);
    expect(find.text('Gate event'), findsWidgets);
    expect(find.text('Event désactivé'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('world-rule-create-submit')));
    await tester.pumpAndSettle();

    var updatedProject = container.read(editorNotifierProvider).project!;
    expect(updatedProject.worldRules, hasLength(1));
    expect(updatedProject.worldRules.single.source.sourceId, 'fact_gate_open');
    expect(updatedProject.worldRules.single.target.kind,
        WorldRuleTargetKind.mapEvent);
    expect(updatedProject.worldRules.single.target.eventId, 'event_gate');
    expect(updatedProject.worldRules.single.effect.kind,
        WorldRuleEffectKind.eventDisabled);
    expect(
      find.text('Si Gate open est vrai alors Event désactivé sur Gate event'),
      findsWidgets,
    );

    await tester.tap(find.byKey(const ValueKey('world-rule-toggle-enabled')));
    await tester.pumpAndSettle();
    updatedProject = container.read(editorNotifierProvider).project!;
    expect(updatedProject.worldRules.single.enabled, isFalse);

    await tester.enterText(
      find.byKey(const ValueKey('world-rule-editor-label-field')),
      'Disable gate while open',
    );
    await tester.enterText(
      find.byKey(const ValueKey('world-rule-editor-priority-field')),
      '7',
    );
    await tester.tap(find.byKey(const ValueKey('world-rule-editor-save')));
    await tester.pumpAndSettle();
    updatedProject = container.read(editorNotifierProvider).project!;
    expect(updatedProject.worldRules.single.label, 'Disable gate while open');
    expect(updatedProject.worldRules.single.priority, 7);

    await tester.tap(find.byKey(const ValueKey('world-rule-editor-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('world-rules-confirm-delete')));
    await tester.pumpAndSettle();

    expect(container.read(editorNotifierProvider).project!.worldRules, isEmpty);
  });

  testWidgets('Facts manager warns before deleting a used fact',
      (tester) async {
    final fact = NarrativeFactDefinition(
      id: 'fact_gate_open',
      label: 'Gate open',
    );
    final container = await _pumpNarrativeShell(
      tester,
      project: _project(
        facts: [fact],
        worldRules: [_worldRule()],
      ),
      workspaceMode: EditorWorkspaceMode.facts,
      activeMap: _map(),
    );

    expect(find.text('Utilisé par 1 élément'), findsWidgets);
    expect(find.byKey(const ValueKey('fact-editor-delete-blocked')),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fact-editor-delete-blocked')));
    await tester.pumpAndSettle();
    expect(container.read(editorNotifierProvider).project!.facts, [fact]);
  });

  testWidgets('writes V1-35 Facts and World Rules manager screenshot',
      (tester) async {
    final fact = NarrativeFactDefinition(
      id: 'fact_gate_open',
      label: 'Gate open',
      description: 'Readable state for a visible world change.',
      category: 'World',
    );
    await _pumpNarrativeShell(
      tester,
      project: _project(
        facts: [fact],
        worldRules: [_worldRule()],
      ),
      workspaceMode: EditorWorkspaceMode.worldRules,
      activeMap: _map(),
    );

    await expectLater(
      find.byKey(const ValueKey('facts-world-rules-workspace')),
      matchesGoldenFile(
        '../../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_35_facts_world_rules_manager_ui_v0.png',
      ),
    );
  });
}

Future<ProviderContainer> _pumpNarrativeShell(
  WidgetTester tester, {
  required ProjectManifest project,
  required EditorWorkspaceMode workspaceMode,
  required MapData activeMap,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer();
  addTearDown(container.dispose);
  final subscription = container.listen(editorNotifierProvider, (_, __) {});
  addTearDown(subscription.close);
  container.read(editorNotifierProvider.notifier).state = EditorState(
    project: project,
    workspaceMode: workspaceMode,
    activeMap: activeMap,
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
  return container;
}

ProjectManifest _project({
  List<NarrativeFactDefinition> facts = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Manager test',
    maps: const [
      ProjectMapEntry(
        id: 'map_gate',
        name: 'Gate map',
        relativePath: 'maps/gate.json',
      ),
    ],
    tilesets: const [],
    facts: facts,
    worldRules: worldRules,
  );
}

MapData _map() {
  return const MapData(
    id: 'map_gate',
    name: 'Gate map',
    size: GridSize(width: 10, height: 8),
    entities: [
      MapEntity(
        id: 'entity_gate',
        name: 'Gate entity',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(displayName: 'Gate entity'),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_gate',
        title: 'Gate event',
        pages: [
          MapEventPage(pageNumber: 0),
        ],
        position: EventPosition(layerId: 'events', x: 1, y: 1),
      ),
    ],
  );
}

WorldRuleDefinition _worldRule() {
  return WorldRuleDefinition(
    id: 'world_rule_gate',
    label: 'Gate rule',
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact_gate_open',
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEvent,
      mapId: 'map_gate',
      eventId: 'event_gate',
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventDisabled),
  );
}
