import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'creates a bounded typed batch with canonical ids and unchanged input',
    () {
      final source = _project([
        NarrativeFactDefinition(id: 'fact_gate', label: 'Gate'),
      ]);
      final facts = [
        NarrativeFactDefinition(
          id: 'fact_gate_2',
          label: ' Gate ',
          description: ' Description ',
          category: ' Progress ',
          tags: ['tag', 'tag'],
          legacyFlagName: 'legacy.gate',
        ),
        NarrativeFactDefinition(
          id: 'fact_score',
          label: 'Score',
          initialValue: NarrativeValue.integer(5),
        ),
        NarrativeFactDefinition(
          id: 'fact_name',
          label: 'Name',
          initialValue: NarrativeValue.string('Johto'),
        ),
      ];
      final result = addNarrativeFacts(source, facts: facts);
      expect(source.facts.map((f) => f.id), ['fact_gate']);
      expect(result.facts.skip(1), facts);
      expect(
        ProjectManifest.fromJson(result.toJson()).toJson(),
        result.toJson(),
      );
      var single = source;
      for (final fact in facts) {
        single = addNarrativeFact(
          single,
          label: fact.label,
          description: fact.description,
          category: fact.category,
          initialValue: fact.initialValue,
          tags: fact.tags,
          legacyFlagName: fact.legacyFlagName,
        ).updatedProject;
      }
      expect(result.toJson(), single.toJson());
    },
  );

  test('accepts maximum size and rejects bounds without mutating input', () {
    final source = _project();
    NarrativeFactDefinition indexed(int i) =>
        NarrativeFactDefinition(id: 'fact_batch_$i', label: 'Batch $i');
    expect(
      addNarrativeFacts(source, facts: List.generate(128, indexed)).facts,
      hasLength(128),
    );
    for (final facts in [
      <NarrativeFactDefinition>[],
      List.generate(129, indexed),
    ]) {
      expect(
        () => addNarrativeFacts(source, facts: facts),
        throwsArgumentError,
      );
      expect(source.facts, isEmpty);
    }
  });

  test(
    'rejects duplicate ids existing collisions and noncanonical final ids atomically',
    () {
      final source = _project([
        NarrativeFactDefinition(id: 'fact_gate', label: 'Gate'),
      ]);
      final before = source.toJson();
      final first = NarrativeFactDefinition(id: 'fact_first', label: 'First');
      for (final last in [
        first,
        source.facts.single,
        NarrativeFactDefinition(id: 'wrong', label: 'Last'),
      ]) {
        expect(
          () => addNarrativeFacts(source, facts: [first, last]),
          throwsA(
            isA<NarrativeFactBatchException>().having(
              (e) => e.index,
              'index',
              1,
            ),
          ),
        );
        expect(source.toJson(), before);
      }
    },
  );

  test('shares exact canonical slug rules and ordered suffix allocation', () {
    final facts = [
      NarrativeFactDefinition(id: 'fact_r_putation', label: 'Réputation'),
      NarrativeFactDefinition(id: 'fact_r_putation_2', label: 'Réputation'),
      NarrativeFactDefinition(id: 'fact_item', label: '!!!'),
    ];
    expect(addNarrativeFacts(_project(), facts: facts).facts, facts);
  });

  test('preserves unrelated preexisting runtime catalog diagnostics', () {
    final source = _project([
      NarrativeFactDefinition(
        id: 'fact_old_a',
        label: 'Old A',
        legacyFlagName: 'shared',
      ),
      NarrativeFactDefinition(
        id: 'fact_old_b',
        label: 'Old B',
        legacyFlagName: 'shared',
      ),
    ]);
    final beforeIssues = NarrativeFactRuntimeResolver.fromFacts(
      source.facts,
    ).issues;
    final fact = NarrativeFactDefinition(id: 'fact_new', label: 'New');
    final batch = addNarrativeFacts(source, facts: [fact]);
    final single = addNarrativeFact(source, label: fact.label).updatedProject;
    expect(batch.toJson(), single.toJson());
    expect(
      NarrativeFactRuntimeResolver.fromFacts(
        batch.facts,
      ).issues.map((issue) => issue.message),
      beforeIssues.map((issue) => issue.message),
    );
  });

  test('rejects runtime aliases colliding with existing ids', () {
    final source = _project([
      NarrativeFactDefinition(id: 'fact_gate', label: 'Gate'),
    ]);
    expect(
      () => addNarrativeFacts(
        source,
        facts: [
          NarrativeFactDefinition(
            id: 'fact_alias',
            label: 'Alias',
            legacyFlagName: 'fact_gate',
          ),
        ],
      ),
      throwsA(
        isA<NarrativeFactBatchException>().having((e) => e.index, 'index', 0),
      ),
    );
  });
}

ProjectManifest _project([List<NarrativeFactDefinition> facts = const []]) =>
    ProjectManifest(
      name: 'Batch facts',
      tilesets: const [],
      maps: const [],
      facts: facts,
    );
