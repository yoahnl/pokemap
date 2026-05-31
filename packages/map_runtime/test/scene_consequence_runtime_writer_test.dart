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
      expect(state.storyFlags.activeFlags, isEmpty);
    });

    test('setFact false clears Fact runtime key', () {
      const state = GameState(
        saveId: 'save_test',
        storyFlags: StoryFlags(activeFlags: {'fact_gate_open'}),
      );
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
          SceneConsequence.setFact(factId: 'fact_gate_open', value: false),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(
        result.gameState.storyFlags.activeFlags,
        isNot(contains('fact_gate_open')),
      );
      expect(state.storyFlags.activeFlags, contains('fact_gate_open'));
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
