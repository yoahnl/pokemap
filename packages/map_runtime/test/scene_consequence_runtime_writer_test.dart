import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('SceneConsequenceRuntimeWriter', () {
    test('setFact true activates Fact runtime key', () {
      const state = GameState(saveId: 'save_test');
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
            ),
          ],
        ),
      );

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_gate_open', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(
          result.gameState.storyFlags.activeFlags, contains('fact_gate_open'));
      expect(
        result.gameState.narrativeFactRuntimeState.overridesByFactId,
        {'fact_gate_open': true},
      );
      expect(
        result.gameState.progression.storyFlags,
        contains('fact_gate_open'),
      );
      expect(state.storyFlags.activeFlags, isEmpty);
    });

    test('setFact false overrides a true default and clears both flag stores',
        () {
      const state = GameState(
        saveId: 'save_test',
        storyFlags: StoryFlags(
          activeFlags: {'legacy_gate_open', 'runtime_other'},
        ),
        progression: PlayerProgression(
          storyFlags: ['legacy_gate_open', 'progression_other'],
        ),
        consumedEventIds: {'legacy_event'},
      );
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
              defaultValue: true,
              legacyFlagName: 'legacy_gate_open',
            ),
          ],
        ),
      );

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_gate_open', value: false),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(
        result.gameState.storyFlags.activeFlags,
        {'runtime_other'},
      );
      expect(result.gameState.progression.storyFlags, ['progression_other']);
      expect(
        result.gameState.narrativeFactRuntimeState.overridesByFactId,
        {'fact_gate_open': false},
      );
      expect(result.gameState.consumedEventIds, {'legacy_event'});
      expect(state.storyFlags.activeFlags, contains('legacy_gate_open'));
    });

    test('setFact uses legacyFlagName when present', () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
              legacyFlagName: 'legacy_gate_flag',
            ),
          ],
        ),
      );

      final result = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [
          SceneConsequence.setFact(factId: 'fact_gate_open', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(
        result.gameState.storyFlags.activeFlags,
        contains('legacy_gate_flag'),
      );
      expect(
        result.gameState.storyFlags.activeFlags,
        isNot(contains('fact_gate_open')),
      );
      expect(
        result.gameState.narrativeFactRuntimeState.overridesByFactId,
        {'fact_gate_open': true},
      );
    });

    test('setFact unknown Fact fails without mutating the original state', () {
      const state = GameState(saveId: 'save_test');
      final writer = SceneConsequenceRuntimeWriter(project: _project());

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_missing', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.unknownFact,
      );
      expect(result.gameState, state);
      expect(state.storyFlags.activeFlags, isEmpty);
    });

    test('setFact ambiguous Fact fails without choosing a winner', () {
      const state = GameState(saveId: 'save_test');
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(id: 'fact_dup', label: 'A'),
            NarrativeFactDefinition(id: 'fact_dup', label: 'B'),
          ],
        ),
      );

      final result = writer.applyAll(
        state,
        [SceneConsequence.setFact(factId: 'fact_dup', value: true)],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.ambiguousFact,
      );
      expect(identical(result.gameState, state), isTrue);
    });

    test('rolls back every consequence when a later setFact fails', () {
      const state = GameState(
        saveId: 'save_test',
        storyFlags: StoryFlags(activeFlags: {'original'}),
      );
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
          ],
        ),
      );

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_known', value: true),
          SceneConsequence.setFact(factId: 'fact_missing', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(identical(result.gameState, state), isTrue);
      expect(result.appliedConsequences, isEmpty);
      expect(state.storyFlags.activeFlags, {'original'});
      expect(state.narrativeFactRuntimeState.overridesByFactId, isEmpty);
    });

    test('markEventConsumed adds consumed event id using existing convention',
        () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          maps: const [
            ProjectMapEntry(
              id: 'map_test',
              name: 'Map Test',
              relativePath: 'maps/map_test.json',
            ),
          ],
        ),
        mapsById: {
          'map_test': _map(events: [_event('event_gate')]),
        },
      );

      final result = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [
          SceneConsequence.markEventConsumed(
            mapId: 'map_test',
            eventId: 'event_gate',
          ),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(result.gameState.consumedEventIds, contains('event_gate'));
      expect(
        result.gameState.consumedEventIds,
        isNot(contains('map_test:event_gate')),
      );
    });

    test('markEventConsumed unknown map fails clearly', () {
      final writer = SceneConsequenceRuntimeWriter(project: _project());

      final result = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [
          SceneConsequence.markEventConsumed(
            mapId: 'map_missing',
            eventId: 'event_gate',
          ),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.unknownMap,
      );
    });

    test('markEventConsumed unknown event fails clearly', () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          maps: const [
            ProjectMapEntry(
              id: 'map_test',
              name: 'Map Test',
              relativePath: 'maps/map_test.json',
            ),
          ],
        ),
        mapsById: {
          'map_test': _map(events: [_event('event_other')]),
        },
      );

      final result = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [
          SceneConsequence.markEventConsumed(
            mapId: 'map_test',
            eventId: 'event_gate',
          ),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.unknownEvent,
      );
    });

    test('does not apply World Rules or complete StorySteps directly', () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
            ),
          ],
          worldRules: [
            WorldRuleDefinition(
              id: 'world_rule_gate',
              label: 'Gate world rule',
              source: const WorldRuleSource(
                kind: WorldRuleSourceKind.fact,
                sourceId: 'fact_gate_open',
                predicate: WorldRuleSourcePredicate.isTrue,
              ),
              target: const WorldRuleTarget(
                kind: WorldRuleTargetKind.mapEvent,
                mapId: 'map_test',
                eventId: 'event_gate',
              ),
              effect: const WorldRuleEffect(
                kind: WorldRuleEffectKind.eventHidden,
              ),
            ),
          ],
        ),
      );
      const state = GameState(
        saveId: 'save_test',
        progression: PlayerProgression(completedStepIds: ['already_done']),
      );

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_gate_open', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(result.gameState.progression.completedStepIds, ['already_done']);
      expect(
          result.gameState.storyFlags.activeFlags, contains('fact_gate_open'));
    });

    test('is deterministic and idempotent for repeated same consequence', () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
            ),
          ],
        ),
      );
      final consequence =
          SceneConsequence.setFact(factId: 'fact_gate_open', value: true);

      final first = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [consequence, consequence],
      );
      final second = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [consequence, consequence],
      );

      expect(first.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(first.gameState, second.gameState);
      expect(first.gameState.storyFlags.activeFlags, hasLength(1));
      expect(
        first.gameState.storyFlags.activeFlags,
        contains('fact_gate_open'),
      );
    });
  });
}

ProjectManifest _project({
  List<ProjectMapEntry> maps = const [],
  List<NarrativeFactDefinition> facts = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Scene consequence runtime writer test',
    maps: maps,
    tilesets: const [],
    facts: facts,
    worldRules: worldRules,
  );
}

MapData _map({List<MapEventDefinition> events = const []}) {
  return MapData(
    id: 'map_test',
    name: 'Map Test',
    size: const GridSize(width: 4, height: 4),
    events: events,
  );
}

MapEventDefinition _event(String id) {
  return MapEventDefinition(
    id: id,
    position: const EventPosition(layerId: 'l_base', x: 1, y: 1),
    pages: const [MapEventPage(pageNumber: 0)],
  );
}
