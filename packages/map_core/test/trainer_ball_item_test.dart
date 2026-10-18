import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('trainer Ball survives JSON and remains absent when unauthored', () {
    final authored = ProjectTrainerPokemonEntry.fromJson({
      'speciesId': 'sproutle',
      'level': 10,
      'ballItemId': 'lunar_orb',
    });
    expect(authored.toJson()['ballItemId'], 'lunar_orb');
    expect(
      const ProjectTrainerPokemonEntry(
        speciesId: 'sproutle',
        level: 10,
      ).toJson().containsKey('ballItemId'),
      isFalse,
    );
  });

  test('trainer Ball rejects malformed JSON values', () {
    for (final value in <Object>[
      true,
      3,
      <String>['lunar_orb'],
      <String, Object>{},
    ]) {
      expect(
        () => ProjectTrainerPokemonEntry.fromJson({
          'speciesId': 'sproutle',
          'level': 10,
          'ballItemId': value,
        }),
        throwsA(anything),
        reason: '$value must not be silently discarded',
      );
    }
  });

  test(
    'trainer Ball presentation accepts a capture item limited to wild encounters',
    () {
      expect(
        () => ProjectValidator.validate(
          _project('lunar_orb'),
          itemCatalog: _catalog(),
        ),
        returnsNormally,
      );
    },
  );

  for (final id in ['', ' ', ' lunar_orb ', 'missing', 'potion']) {
    test('trainer Ball rejects invalid reference "$id"', () {
      expect(
        () => ProjectValidator.validate(_project(id), itemCatalog: _catalog()),
        throwsA(isA<ValidationException>()),
      );
    });
  }

  test('trainer Ball rejects an ambiguous catalogue reference', () {
    expect(
      () => ProjectValidator.validate(
        _project('lunar_orb'),
        itemCatalog: _catalog(duplicate: true),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('trainer without an authored Ball needs no item catalogue', () {
    expect(() => ProjectValidator.validate(_project(null)), returnsNormally);
  });

  test('trainer Ball participates in blocking editable item references', () {
    final references = buildProjectItemReferenceIndex(
      project: _project('lunar_orb'),
    ).blockingReferencesFor('lunar_orb');
    expect(references, hasLength(1));
    expect(references.single.editablePath, 'trainers[lysa].team[0].ballItemId');
  });
}

ProjectManifest _project(String? ballItemId) => ProjectManifest(
  name: 'Trainer Balls',
  maps: const [],
  tilesets: const [],
  trainers: [
    ProjectTrainerEntry.fromJson({
      'id': 'lysa',
      'name': 'Lysa',
      'trainerClass': 'Trainer',
      'team': [
        {'speciesId': 'sproutle', 'level': 10, 'ballItemId': ballItemId},
      ],
    }),
  ],
);

ProjectItemCatalog _catalog({bool duplicate = false}) => ProjectItemCatalog(
  schemaVersion: 1,
  entries: [
    _ball,
    if (duplicate) _ball,
    const ProjectItemDefinition(
      id: 'potion',
      displayName: 'Potion',
      pocketId: 'medicine',
    ),
  ],
);

const _ball = ProjectItemDefinition(
  id: 'lunar_orb',
  displayName: 'Orbe lunaire',
  pocketId: 'balls',
  capture: ProjectCaptureItemDefinition(
    rateNumerator: 1,
    rateDenominator: 1,
    allowedEncounterKinds: {EncounterKind.walk},
  ),
);
