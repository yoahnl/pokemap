import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('integer Fact adjustment', () {
    final counter = NarrativeFactDefinition(
      id: 'fact_counter',
      label: 'Counter',
      initialValue: NarrativeValue.integer(4),
    );

    test(
      'reads defaults then staged values and survives saved integer state',
      () {
        final writer = NarrativeFactRuntimeWriter(
          NarrativeFactRuntimeResolver.fromFacts([counter]),
        );
        const original = GameState(saveId: 'counter');
        final first = writer.adjustIntegerFact(
          gameState: original,
          factId: counter.id,
          delta: 3,
          minimum: -10,
          maximum: 20,
        );
        final second = writer.adjustIntegerFact(
          gameState: first.gameState,
          factId: counter.id,
          delta: -2,
          minimum: -10,
          maximum: 20,
        );
        expect(
          first.gameState.narrativeFactRuntimeState.valueFor(counter.id),
          NarrativeValue.integer(7),
        );
        expect(
          second.gameState.narrativeFactRuntimeState.valueFor(counter.id),
          NarrativeValue.integer(5),
        );
        final restored = gameStateFromSaveData(
          saveDataFromGameState(second.gameState),
        );
        final third = writer.adjustIntegerFact(
          gameState: restored,
          factId: counter.id,
          delta: 1,
          minimum: -10,
          maximum: 20,
        );
        expect(
          third.gameState.narrativeFactRuntimeState.valueFor(counter.id),
          NarrativeValue.integer(6),
        );
        expect(original.narrativeFactRuntimeState.valuesByFactId, isEmpty);
        expect(third.gameState.storyFlags, original.storyFlags);
      },
    );

    test('clamps exact large sums in both directions and equal bounds', () {
      const limit = 9007199254740991;
      for (final value in [limit, -limit]) {
        final fact = NarrativeFactDefinition(
          id: 'fact_large',
          label: 'Large',
          initialValue: NarrativeValue.integer(value),
        );
        final writer = NarrativeFactRuntimeWriter(
          NarrativeFactRuntimeResolver.fromFacts([fact]),
        );
        final result = writer.adjustIntegerFact(
          gameState: const GameState(saveId: 'large'),
          factId: fact.id,
          delta: value,
          minimum: -limit,
          maximum: limit,
        );
        expect(
          result.gameState.narrativeFactRuntimeState.valueFor(fact.id),
          NarrativeValue.integer(value),
        );
        final fixed = writer.adjustIntegerFact(
          gameState: result.gameState,
          factId: fact.id,
          delta: -value,
          minimum: 3,
          maximum: 3,
        );
        expect(
          fixed.gameState.narrativeFactRuntimeState.valueFor(fact.id),
          NarrativeValue.integer(3),
        );
      }
    });

    test(
      'rejects unknown ambiguous invalid-key and noninteger Facts atomically',
      () {
        const original = GameState(saveId: 'rejected');
        for (final entry in [
          (
            const <NarrativeFactDefinition>[],
            'fact_missing',
            NarrativeFactRuntimeWriteErrorCode.unknownFact,
          ),
          (
            [counter, counter],
            counter.id,
            NarrativeFactRuntimeWriteErrorCode.ambiguousFact,
          ),
          (
            [counter],
            ' ${counter.id}',
            NarrativeFactRuntimeWriteErrorCode.invalidRuntimeKey,
          ),
          (
            [NarrativeFactDefinition(id: counter.id, label: 'Boolean')],
            counter.id,
            NarrativeFactRuntimeWriteErrorCode.typeMismatch,
          ),
        ]) {
          final result =
              NarrativeFactRuntimeWriter(
                NarrativeFactRuntimeResolver.fromFacts(entry.$1),
              ).adjustIntegerFact(
                gameState: original,
                factId: entry.$2,
                delta: 1,
                minimum: -2,
                maximum: 2,
              );
          expect(result.errorCode, entry.$3);
          expect(identical(result.gameState, original), isTrue);
        }
        final malformedOverride = original.copyWith(
          narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
            valuesByFactId: {counter.id: const NarrativeValue.string('bad')},
          ),
        );
        final rejected =
            NarrativeFactRuntimeWriter(
              NarrativeFactRuntimeResolver.fromFacts([counter]),
            ).adjustIntegerFact(
              gameState: malformedOverride,
              factId: counter.id,
              delta: 1,
              minimum: -2,
              maximum: 2,
            );
        expect(
          rejected.errorCode,
          NarrativeFactRuntimeWriteErrorCode.typeMismatch,
        );
        expect(identical(rejected.gameState, malformedOverride), isTrue);
      },
    );

    test('rejects invalid integer parameters without mutating input', () {
      final writer = NarrativeFactRuntimeWriter(
        NarrativeFactRuntimeResolver.fromFacts([counter]),
      );
      const original = GameState(saveId: 'bounds');
      for (final values in [
        (1, 3, 2),
        (9007199254740992, -2, 2),
        (1, -9007199254740992, 2),
        (1, -2, 9007199254740992),
      ]) {
        expect(
          () => writer.adjustIntegerFact(
            gameState: original,
            factId: counter.id,
            delta: values.$1,
            minimum: values.$2,
            maximum: values.$3,
          ),
          throwsArgumentError,
        );
      }
      expect(original.narrativeFactRuntimeState.valuesByFactId, isEmpty);
    });
  });


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
