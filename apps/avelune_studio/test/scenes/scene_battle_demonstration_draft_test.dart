import 'package:avelune_studio/features/scenes/application/scene_battle_demonstration_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

ProjectManifest _project({
  ProjectDimension dimension = ProjectDimension.threeD,
}) => ProjectManifest(
  name: 'Demo',
  maps: [],
  tilesets: [],
  settings: ProjectSettings(dimension: dimension),
  trainers: const [
    ProjectTrainerEntry(
      id: 'guide',
      name: 'Guide de capture',
      trainerClass: 'Guide',
      team: [ProjectTrainerPokemonEntry(speciesId: 'bird', level: 5)],
    ),
  ],
);

void main() {
  test(
    'named teams and capture items build the same temporary demonstration',
    () {
      final draft = SceneBattleDemonstrationDraft(
        project: _project(),
        value: null,
        items: {'potion': 'Potion', 'poke-ball': 'Poké Ball'},
        captureItems: {'poke-ball': 'Poké Ball'},
      );
      expect(draft.available, isTrue);
      expect(draft.teams, {'guide': 'Guide de capture'});
      draft.enable(true);
      expect(draft.value!.playerTrainerId, 'guide');
      expect(draft.value!.bagItems.single.itemId, 'poke-ball');
      expect(draft.value!.bagItems.single.quantity, 20);
      expect(draft.captureBag, {'poke-ball': 'Poké Ball'});
      expect(draft.quantity(0, '7'), isTrue);
      draft.addItem();
      expect(draft.value!.bagItems.map((entry) => entry.itemId), [
        'poke-ball',
        'potion',
      ]);
      expect(draft.value!.bagItems.first.quantity, 7);
      expect(draft.captureBag, {'poke-ball': 'Poké Ball'});
      draft.enable(false);
      expect(draft.value, isNull);
    },
  );

  test('missing catalogues and 2D cannot create an invalid demonstration', () {
    for (final project in [
      _project(dimension: ProjectDimension.twoD),
      ProjectManifest(name: 'Empty', maps: [], tilesets: []),
    ]) {
      final draft = SceneBattleDemonstrationDraft(
        project: project,
        value: null,
        captureItems: {'ball': 'Ball'},
      );
      expect(draft.available, isFalse);
      draft.enable(true);
      expect(draft.value, isNull);
    }
    final noCapture = SceneBattleDemonstrationDraft(
      project: _project(),
      value: null,
    );
    noCapture.enable(true);
    expect(noCapture.value, isNull);
  });

  test('capture item replacement preserves coherent choices and referenced items cannot disappear', () {
    final draft = SceneBattleDemonstrationDraft(
      project: _project(),
      value: null,
      items: {'ball': 'Ball', 'great-ball': 'Super Ball', 'potion': 'Potion'},
      captureItems: {'ball': 'Ball', 'great-ball': 'Super Ball'},
    );
    draft.enable(true);
    expect(draft.replacementItems(0).keys, ['ball', 'great-ball']);
    draft.replaceItem(0, 'great-ball');
    expect(draft.value!.bagItems.single.itemId, 'great-ball');
    expect(draft.value!.choices.single.itemId, 'great-ball');
    final original = draft.value;
    draft.removeItem(0);
    expect(draft.value, same(original));
    draft.addChoice();
    draft.moveChoiceUp(1);
    expect(draft.value!.choices.first.kind, 'fight');
    draft.removeChoice(1);
    draft.removeItem(0);
    expect(draft.value!.bagItems, isEmpty);
    final last = draft.value;
    draft.removeChoice(0);
    expect(draft.value, same(last));
  });

  test(
    'quantity and delay reject invalid input without changing the draft',
    () {
      final draft = SceneBattleDemonstrationDraft(
        project: _project(),
        value: null,
        captureItems: {'ball': 'Ball'},
      );
      draft.enable(true);
      final original = draft.value;
      for (final text in ['0', '1000', '1.5', 'invalid']) {
        expect(draft.quantity(0, text), isFalse);
        expect(draft.value, same(original));
      }
      for (final text in ['49', '10001', '1.5', 'invalid']) {
        expect(draft.delay(text), isFalse);
        expect(draft.value, same(original));
      }
      expect(draft.delay('50'), isTrue);
      expect(draft.value!.stepDelayMs, 50);
      expect(
        SceneBattleDemonstration.fromJson(draft.value!.toJson()),
        draft.value,
      );
    },
  );
}
