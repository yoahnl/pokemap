import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeFactRuntimeWriter', () {
    test('writes explicit false and synchronizes both legacy stores', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          defaultValue: true,
          legacyFlagName: 'legacy_gate',
        ),
      ]);
      final writer = NarrativeFactRuntimeWriter(resolver);
      const original = GameState(
        saveId: 'writer_false',
        storyFlags: StoryFlags(
          activeFlags: {'legacy_gate', 'unrelated_runtime'},
        ),
        progression: PlayerProgression(
          storyFlags: ['legacy_gate', 'unrelated_progression'],
        ),
        consumedEventIds: {'legacy_event'},
      );

      final result = writer.setFact(
        gameState: original,
        factId: 'fact_gate',
        value: false,
      );

      expect(result, isA<NarrativeFactRuntimeWriteApplied>());
      expect(result.gameState.narrativeFactRuntimeState.overridesByFactId, {
        'fact_gate': false,
      });
      expect(result.gameState.storyFlags.activeFlags, {'unrelated_runtime'});
      expect(
        result.gameState.progression.storyFlags,
        ['unrelated_progression'],
      );
      expect(result.gameState.consumedEventIds, {'legacy_event'});
      expect(original.storyFlags.activeFlags, contains('legacy_gate'));
    });

    test('writes explicit true while preserving orphan overrides', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          legacyFlagName: 'legacy_gate',
        ),
      ]);
      final writer = NarrativeFactRuntimeWriter(resolver);
      final original = GameState(
        saveId: 'writer_true',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_orphan': false},
        ),
      );

      final result = writer.setFact(
        gameState: original,
        factId: 'fact_gate',
        value: true,
      );

      expect(result.success, isTrue);
      expect(result.gameState.narrativeFactRuntimeState.overridesByFactId, {
        'fact_gate': true,
        'fact_orphan': false,
      });
      expect(result.gameState.storyFlags.activeFlags, {'legacy_gate'});
      expect(result.gameState.progression.storyFlags, ['legacy_gate']);
    });

    test('writes typed values and rejects a mismatched type atomically', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_tide',
          label: 'Tide',
          initialValue: NarrativeValue.integer(0),
        ),
      ]);
      final writer = NarrativeFactRuntimeWriter(resolver);
      const original = GameState(saveId: 'writer_typed');

      final applied = writer.setFactValue(
        gameState: original,
        factId: 'fact_tide',
        value: NarrativeValue.integer(4),
      );
      final rejected = writer.setFactValue(
        gameState: applied.gameState,
        factId: 'fact_tide',
        value: const NarrativeValue.string('four'),
      );

      expect(applied.success, isTrue);
      expect(
        applied.gameState.narrativeFactRuntimeState.valueFor('fact_tide'),
        NarrativeValue.integer(4),
      );
      expect(
          rejected.errorCode, NarrativeFactRuntimeWriteErrorCode.typeMismatch);
      expect(identical(rejected.gameState, applied.gameState), isTrue);
      expect(applied.gameState.storyFlags.activeFlags, isEmpty);
    });

    test('keeps explicit intent across default and alias changes', () {
      final firstResolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          defaultValue: true,
          legacyFlagName: 'legacy_old',
        ),
      ]);
      final written = NarrativeFactRuntimeWriter(firstResolver).setFact(
        gameState: const GameState(saveId: 'writer_change'),
        factId: 'fact_gate',
        value: false,
      );
      final changedResolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate changed',
          defaultValue: false,
          legacyFlagName: 'legacy_new',
        ),
      ]);

      final resolved = changedResolver.resolve(
        factId: 'fact_gate',
        runtimeState: written.gameState.narrativeFactRuntimeState,
        storyFlags: const StoryFlags(activeFlags: {'legacy_new'}),
      ) as NarrativeFactRuntimeResolved;

      expect(resolved.value, isFalse);
      expect(resolved.source, NarrativeFactRuntimeValueSource.explicitOverride);
    });

    test('rejects unknown and ambiguous Facts with the original state', () {
      const original = GameState(saveId: 'writer_rejected');
      final unknown = NarrativeFactRuntimeWriter(
        NarrativeFactRuntimeResolver.fromFacts(const []),
      ).setFact(
        gameState: original,
        factId: 'fact_missing',
        value: true,
      );
      final ambiguous = NarrativeFactRuntimeWriter(
        NarrativeFactRuntimeResolver.fromFacts([
          NarrativeFactDefinition(id: 'fact_dup', label: 'A'),
          NarrativeFactDefinition(id: 'fact_dup', label: 'B'),
        ]),
      ).setFact(
        gameState: original,
        factId: 'fact_dup',
        value: true,
      );

      expect(unknown.success, isFalse);
      expect(unknown.errorCode, NarrativeFactRuntimeWriteErrorCode.unknownFact);
      expect(identical(unknown.gameState, original), isTrue);
      expect(
        ambiguous.errorCode,
        NarrativeFactRuntimeWriteErrorCode.ambiguousFact,
      );
      expect(identical(ambiguous.gameState, original), isTrue);
    });

    test('survives SaveData round-trip after explicit false', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          defaultValue: true,
          legacyFlagName: 'legacy_gate',
        ),
      ]);
      final written = NarrativeFactRuntimeWriter(resolver).setFact(
        gameState: const GameState(
          saveId: 'writer_round_trip',
          storyFlags: StoryFlags(activeFlags: {'legacy_gate'}),
          progression: PlayerProgression(storyFlags: ['legacy_gate']),
        ),
        factId: 'fact_gate',
        value: false,
      );

      final restored = gameStateFromSaveData(
        saveDataFromGameState(written.gameState),
      );
      final resolved = resolver.resolve(
        factId: 'fact_gate',
        runtimeState: restored.narrativeFactRuntimeState,
        storyFlags: restored.storyFlags,
      ) as NarrativeFactRuntimeResolved;

      expect(resolved.value, isFalse);
      expect(restored.storyFlags.activeFlags, isNot(contains('legacy_gate')));
      expect(
        restored.progression.storyFlags,
        isNot(contains('legacy_gate')),
      );
    });
  });
}
