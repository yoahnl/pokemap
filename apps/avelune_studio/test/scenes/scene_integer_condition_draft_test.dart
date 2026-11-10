import 'package:avelune_studio/features/scenes/application/scene_integer_condition_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final project = ProjectManifest(
    name: 'Nombres',
    maps: [],
    tilesets: [],
    facts: [
      NarrativeFactDefinition(
        id: 'count',
        label: 'Compteur',
        initialValue: NarrativeValue.integer(4),
      ),
    ],
  );

  test('typed fact versus money comparison keeps authored labels', () {
    final source = SceneConditionSource.integerComparison(
      left: SceneIntegerOperand.integerFact('count'),
      comparison: NarrativeFactOperator.greaterThanOrEqual,
      right: SceneIntegerOperand.gameRead(SceneIntegerGameRead.money),
      label: 'Économie',
      debugTechnicalLabel: 'opaque',
    );
    final draft = SceneIntegerConditionDraft(
      project: project,
      current: source,
      changed: () {},
    );
    addTearDown(draft.dispose);
    expect(draft.prepared, source);
    draft.left = SceneIntegerOperand.integerFact('missing');
    expect(draft.prepared, isNull);
    expect(draft.current, same(source));
  });

  test(
    'item operands become unavailable when a selected item is removed',
    () async {
      var items = {'potion': 'Potion'};
      final draft = SceneIntegerConditionDraft(
        project: project,
        changed: () {},
        loadItems: () async => items,
      );
      addTearDown(draft.dispose);
      draft.left = SceneIntegerOperand.gameRead(
        SceneIntegerGameRead.itemCount,
        itemId: 'potion',
      );
      await draft.refreshItems();
      expect(draft.prepared, isNotNull);
      items = {};
      await draft.refreshItems();
      expect(draft.prepared, isNull);
    },
  );

  test('operand drafts reject invalid numbers and unavailable references', () {
    final draft = SceneIntegerOperandDraft(
      value: SceneIntegerOperand.literal(7),
      facts: {'count': 'Compteur'},
      items: {},
    );
    draft.number = 'invalid';
    expect(draft.prepare(facts: {}, items: {}), isNull);
    draft.source = 'integerFact';
    expect(
      draft.prepare(facts: {'count': 'Compteur'}, items: {}),
      SceneIntegerOperand.integerFact('count'),
    );
    expect(draft.prepare(facts: {}, items: {}), isNull);
  });
}
