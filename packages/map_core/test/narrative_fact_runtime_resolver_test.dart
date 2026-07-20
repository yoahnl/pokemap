import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeFactRuntimeResolver', () {
    test('resolves override before alias and default', () {
      final fact = NarrativeFactDefinition(
        id: 'fact_gate',
        label: 'Gate',
        defaultValue: true,
        legacyFlagName: 'legacy_gate',
      );
      final resolver = NarrativeFactRuntimeResolver.fromFacts([fact]);
      final result = resolver.resolve(
        factId: fact.id,
        runtimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_gate': false},
        ),
        storyFlags: const StoryFlags(activeFlags: {'legacy_gate'}),
      );

      expect(result, isA<NarrativeFactRuntimeResolved>());
      final resolved = result as NarrativeFactRuntimeResolved;
      expect(resolved.value, isFalse);
      expect(resolved.source, NarrativeFactRuntimeValueSource.explicitOverride);
      expect(resolved.runtimeKey, 'legacy_gate');
    });

    test('resolves alias before a false default', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          legacyFlagName: 'legacy_gate',
        ),
      ]);

      final result = resolver.resolve(
        factId: 'fact_gate',
        runtimeState: const NarrativeFactRuntimeState.empty(),
        storyFlags: const StoryFlags(activeFlags: {'legacy_gate'}),
      ) as NarrativeFactRuntimeResolved;

      expect(result.value, isTrue);
      expect(result.source, NarrativeFactRuntimeValueSource.legacyStoryFlag);
    });

    test('falls back to false and true defaults', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(id: 'fact_false', label: 'False'),
        NarrativeFactDefinition(
          id: 'fact_true',
          label: 'True',
          defaultValue: true,
        ),
      ]);

      final falseResult = resolver.resolve(
        factId: 'fact_false',
        runtimeState: const NarrativeFactRuntimeState.empty(),
        storyFlags: const StoryFlags(),
      ) as NarrativeFactRuntimeResolved;
      final trueResult = resolver.resolve(
        factId: 'fact_true',
        runtimeState: const NarrativeFactRuntimeState.empty(),
        storyFlags: const StoryFlags(),
      ) as NarrativeFactRuntimeResolved;

      expect(falseResult.value, isFalse);
      expect(trueResult.value, isTrue);
      expect(falseResult.source, NarrativeFactRuntimeValueSource.defaultValue);
      expect(trueResult.source, NarrativeFactRuntimeValueSource.defaultValue);
    });

    test('resolves typed overrides and typed defaults without legacy flags',
        () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_tide',
          label: 'Tide',
          initialValue: NarrativeValue.integer(2),
        ),
        NarrativeFactDefinition(
          id: 'fact_name',
          label: 'Name',
          initialValue: const NarrativeValue.string('Selbrume'),
        ),
      ]);
      final state = NarrativeFactRuntimeState.typed(
        valuesByFactId: {'fact_tide': NarrativeValue.integer(5)},
      );

      final tide = resolver.resolve(
        factId: 'fact_tide',
        runtimeState: state,
        storyFlags: const StoryFlags(activeFlags: {'fact_tide'}),
      ) as NarrativeFactRuntimeResolved;
      final name = resolver.resolve(
        factId: 'fact_name',
        runtimeState: state,
        storyFlags: const StoryFlags(),
      ) as NarrativeFactRuntimeResolved;

      expect(tide.narrativeValue, NarrativeValue.integer(5));
      expect(tide.source, NarrativeFactRuntimeValueSource.explicitOverride);
      expect(name.narrativeValue, const NarrativeValue.string('Selbrume'));
      expect(name.source, NarrativeFactRuntimeValueSource.defaultValue);
    });

    test('does not use the raw Fact ID when an alias exists', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          legacyFlagName: 'legacy_gate',
        ),
      ]);

      final result = resolver.resolve(
        factId: 'fact_gate',
        runtimeState: const NarrativeFactRuntimeState.empty(),
        storyFlags: const StoryFlags(activeFlags: {'fact_gate'}),
      ) as NarrativeFactRuntimeResolved;

      expect(result.value, isFalse);
      expect(result.source, NarrativeFactRuntimeValueSource.defaultValue);
    });

    test('returns typed unknown and invalid key results', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts(const []);

      expect(
        resolver.resolve(
          factId: 'fact_missing',
          runtimeState: const NarrativeFactRuntimeState.empty(),
          storyFlags: const StoryFlags(),
        ),
        isA<NarrativeFactRuntimeUnknownFact>(),
      );
      expect(
        resolver.resolve(
          factId: ' fact_missing ',
          runtimeState: const NarrativeFactRuntimeState.empty(),
          storyFlags: const StoryFlags(),
        ),
        isA<NarrativeFactRuntimeInvalidRuntimeKey>(),
      );
    });

    test('detects every runtime catalog collision without choosing a winner',
        () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(id: 'fact_duplicate', label: 'Duplicate A'),
        NarrativeFactDefinition(id: 'fact_duplicate', label: 'Duplicate B'),
        NarrativeFactDefinition(
          id: 'fact_alias_a',
          label: 'Alias A',
          legacyFlagName: 'shared_alias',
        ),
        NarrativeFactDefinition(
          id: 'fact_alias_b',
          label: 'Alias B',
          legacyFlagName: 'shared_alias',
        ),
        NarrativeFactDefinition(id: 'fact_collision', label: 'Collision'),
        NarrativeFactDefinition(
          id: 'fact_other',
          label: 'Other',
          legacyFlagName: 'fact_collision',
        ),
      ]);

      expect(resolver.isValid, isFalse);
      expect(
        resolver.issues.map((issue) => issue.code),
        containsAll({
          NarrativeFactRuntimeCatalogIssueCode.duplicateFactId,
          NarrativeFactRuntimeCatalogIssueCode.duplicateLegacyFlagName,
          NarrativeFactRuntimeCatalogIssueCode
              .legacyFlagNameConflictsWithFactId,
          NarrativeFactRuntimeCatalogIssueCode.duplicateRuntimeKey,
        }),
      );
      expect(
        resolver.resolve(
          factId: 'fact_other',
          runtimeState: const NarrativeFactRuntimeState.empty(),
          storyFlags: const StoryFlags(),
        ),
        isA<NarrativeFactRuntimeAmbiguousFact>(),
      );
      expect(
        () => resolver.issues.add(
          resolver.issues.first,
        ),
        throwsUnsupportedError,
      );
    });

    test('keeps orphan overrides but never applies them to another Fact', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
      ]);
      final runtimeState = NarrativeFactRuntimeState(
        overridesByFactId: const {'fact_orphan': true},
      );

      final known = resolver.resolve(
        factId: 'fact_known',
        runtimeState: runtimeState,
        storyFlags: const StoryFlags(),
      ) as NarrativeFactRuntimeResolved;
      final orphan = resolver.resolve(
        factId: 'fact_orphan',
        runtimeState: runtimeState,
        storyFlags: const StoryFlags(),
      );

      expect(known.value, isFalse);
      expect(orphan, isA<NarrativeFactRuntimeUnknownFact>());
      expect(runtimeState.overridesByFactId['fact_orphan'], isTrue);
    });
  });
}
