import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/facts_world_rules/world_state_simulator_panel.dart';

void main() {
  testWidgets(
      'simulates Facts, Steps and outcomes without mutating the project',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(520, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = _project();
    final projectBefore = project.toJson();

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        darkTheme: PokeMapTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: WorldStateSimulatorPanel(
            project: project,
            maps: const [_map],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('world-state-simulator-panel')),
      findsOneWidget,
    );
    expect(find.text('Règles applicables : 0'), findsOneWidget);
    expect(find.text('Visible'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('world-state-fact-toggle-fact_gate')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Règles applicables : 1'), findsOneWidget);
    expect(find.text('Cachée'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('world-state-after-step')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Étapes terminées : 1'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('world-state-before-step')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Étapes terminées : 0'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('world-state-victory-preset')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Issue hypothétique : victoire'), findsOneWidget);
    expect(project.toJson(), projectBefore);
  });
}

ProjectManifest _project() => ProjectManifest(
      name: 'Simulator UI',
      maps: const [
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port',
          relativePath: 'maps/port.json',
        ),
      ],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(id: 'fact_gate', label: 'Gate closed'),
      ],
      storylines: [
        StorylineAsset(
          id: 'story_port',
          type: StorylineType.main,
          title: 'Port',
          chapters: [
            StorylineChapter(
              id: 'chapter_port',
              title: 'Port',
              order: 0,
              steps: [
                StorylineStep(
                  id: 'step_port',
                  title: 'Reach the port',
                  order: 0,
                ),
              ],
            ),
          ],
        ),
      ],
      worldRules: [
        WorldRuleDefinition(
          id: 'rule_hide_guard',
          label: 'Hide guard',
          source: const WorldRuleSource(
            kind: WorldRuleSourceKind.fact,
            sourceId: 'fact_gate',
            predicate: WorldRuleSourcePredicate.isTrue,
          ),
          target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'map_port',
            entityId: 'npc_guard',
          ),
          effect: const WorldRuleEffect(
            kind: WorldRuleEffectKind.entityHidden,
          ),
        ),
      ],
    );

const _map = MapData(
  id: 'map_port',
  name: 'Port',
  size: GridSize(width: 6, height: 6),
  entities: [
    MapEntity(
      id: 'npc_guard',
      name: 'Guard',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 2, y: 2),
      npc: MapEntityNpcData(displayName: 'Guard'),
    ),
  ],
);
