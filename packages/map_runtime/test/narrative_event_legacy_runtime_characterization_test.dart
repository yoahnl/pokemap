import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  late List<MapData> maps;
  late List<ScenarioAsset> scenarios;

  setUpAll(() {
    final source = File(
      '../map_core/test/fixtures/narrative_event_legacy_corpus/corpus_v0.json',
    ).readAsStringSync();
    final fixture = Map<String, Object?>.from(
      decodeNarrativeEventJsonStrict(source)! as Map,
    );
    maps = List<Object?>.from(fixture['maps']! as List)
        .map(
          (value) => MapData.fromJson(
            Map<String, dynamic>.from(value! as Map),
          ),
        )
        .toList(growable: false);
    scenarios = List<Object?>.from(fixture['scenarios']! as List)
        .map(
          (value) => ScenarioAsset.fromJson(
            Map<String, dynamic>.from(value! as Map),
          ),
        )
        .toList(growable: false);
  });

  group('NS-EVENT-V2 Phase C1 legacy runtime characterization', () {
    test('first-valid keeps list order and ignores hidden/disabled flags', () {
      final event = maps
          .singleWhere((map) => map.id == 'c1_map_a')
          .events
          .singleWhere((candidate) => candidate.id == 'evt_page_order');
      const resolver = EventPageResolver();

      ActiveEventPage resolve(Set<String> flags) {
        return resolver.resolve(
          event,
          GameState(
            saveId: 'save_c1_pages',
            storyFlags: StoryFlags(activeFlags: flags),
          ),
        )!;
      }

      final fallback = resolve(const {});
      expect(fallback.pageIndex, 2);
      expect(fallback.page.pageNumber, 10);

      final hidden = resolve(const {'flagA'});
      expect(hidden.pageIndex, 0);
      expect(hidden.page.pageNumber, 30);
      expect(hidden.page.isHidden, isTrue);

      final disabled = resolve(const {'flagB'});
      expect(disabled.pageIndex, 1);
      expect(disabled.page.pageNumber, 20);
      expect(disabled.page.isDisabled, isTrue);

      final firstWins = resolve(const {'flagA', 'flagB'});
      expect(firstWins.pageIndex, 0);
      expect(firstWins.page.pageNumber, 30);
    });

    test('exact corpus sources each reach their single dialogue trace', () {
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_map_enter',
        source: ScenarioRuntimeSourceEvent.mapEnter(mapId: 'c1_map_a'),
        expectedDialogueId: 'dialogue_map_enter',
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_trigger_enter',
        source: ScenarioRuntimeSourceEvent.triggerEnter(
          mapId: 'c1_map_a',
          triggerId: 'evt_trigger_script',
        ),
        expectedDialogueId: 'dialogue_trigger',
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_entity_a',
        source: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'c1_map_a',
          entityId: 'npc_actor',
        ),
        expectedDialogueId: 'dialogue_entity',
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_entity_b',
        source: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'c1_map_a',
          entityId: 'npc_actor',
        ),
        expectedDialogueId: 'dialogue_entity',
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_outcome',
        source: ScenarioRuntimeSourceEvent.outcomeReceived(
          outcomeId: 'victory',
        ),
        expectedDialogueId: 'dialogue_outcome',
      );
    });

    test('full corpus keeps first matching Scenario order explicit', () {
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_map_enter',
        source: ScenarioRuntimeSourceEvent.mapEnter(mapId: 'c1_map_a'),
        expectedDialogueId: 'dialogue_map_enter',
        useFullCorpus: true,
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_trigger_enter',
        source: ScenarioRuntimeSourceEvent.triggerEnter(
          mapId: 'c1_map_a',
          triggerId: 'evt_trigger_script',
        ),
        expectedDialogueId: 'dialogue_trigger',
        useFullCorpus: true,
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_entity_a',
        source: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'c1_map_a',
          entityId: 'npc_actor',
        ),
        expectedDialogueId: 'dialogue_entity',
        useFullCorpus: true,
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_outcome',
        source: ScenarioRuntimeSourceEvent.outcomeReceived(
          outcomeId: 'victory',
        ),
        expectedDialogueId: 'dialogue_outcome',
        useFullCorpus: true,
      );
    });
  });
}

void _expectDialogueDispatch({
  required List<ScenarioAsset> scenarios,
  required String scenarioId,
  required ScenarioRuntimeSourceEvent source,
  required String expectedDialogueId,
  bool useFullCorpus = false,
}) {
  final selected =
      scenarios.singleWhere((candidate) => candidate.id == scenarioId);
  final opened = <String>[];
  const executor = ScenarioRuntimeExecutor();
  final result = executor.dispatch(
    scenarios: useFullCorpus ? scenarios : [selected],
    sourceEvent: source,
    context: ScenarioRuntimeExecutionContext(
      gameState: const GameState(saveId: 'save_c1_runtime'),
      onGameStateUpdated: (_) {},
      openDialogue: (dialogueId, {startNode, runtimeSourceId}) {
        opened.add(dialogueId);
        return true;
      },
      runScript: (_, {startNode, runtimeSourceId}) => false,
      showMessage: (_) {},
    ),
  );
  expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
  expect(result.scenarioId, scenarioId);
  expect(result.sourceNodeId, 'source');
  expect(result.effect.type, ScenarioRuntimeEffectType.dialogue);
  expect(opened, [expectedDialogueId]);
}
