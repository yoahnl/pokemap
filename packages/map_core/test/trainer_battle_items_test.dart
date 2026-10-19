import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'trainer battle stock survives JSON without becoming a reward or held item',
    () {
      final trainer = ProjectTrainerEntry.fromJson({
        ..._trainer({'potion': 3, 'antidote': 1}),
        'rewardItemGrants': [
          {'itemId': 'potion', 'quantity': 7},
        ],
        'team': [
          {
            'speciesId': 'test_species',
            'level': 10,
            'heldItemId': 'held_charm',
            'ballItemId': 'lunar_orb',
          },
        ],
      });

      final json = trainer.toJson();
      expect(json['battleItems'], {'potion': 3, 'antidote': 1});
      expect(ProjectTrainerEntry.fromJson(json).toJson()['battleItems'], {
        'potion': 3,
        'antidote': 1,
      });
      expect(json['rewardItemGrants'], [
        {'itemId': 'potion', 'quantity': 7},
      ]);
      expect(
        (json['team'] as List).single,
        containsPair('heldItemId', 'held_charm'),
      );
      expect(
        (json['team'] as List).single,
        containsPair('ballItemId', 'lunar_orb'),
      );
    },
  );

  test('trainer battle stock defaults to an empty object when unauthored', () {
    final trainer = ProjectTrainerEntry.fromJson({
      'id': 'trainer_alpha',
      'name': 'Trainer Alpha',
      'trainerClass': 'Trainer',
    });
    expect(trainer.toJson()['battleItems'], <String, int>{});
    expect(
      const ProjectTrainerEntry(
        id: 'trainer_alpha',
        name: 'Trainer Alpha',
        trainerClass: 'Trainer',
      ).toJson()['battleItems'],
      <String, int>{},
    );
  });

  final malformedStocks = <String, Object?>{
    'explicit null': null,
    'a list': <Object?>[],
    'a boolean': true,
    'a string': 'potion',
    'a number': 1,
    'a decimal quantity': {'potion': 1.0},
    'a fractional quantity': {'potion': 1.5},
    'a boolean quantity': {'potion': true},
    'a string quantity': {'potion': '1'},
    'a null quantity': {'potion': null},
    'a non-string key': {1: 1},
  };
  for (final entry in malformedStocks.entries) {
    test('trainer battle stock rejects ${entry.key} during JSON decoding', () {
      expect(
        () => ProjectTrainerEntry.fromJson(_trainer(entry.value)),
        throwsA(anything),
      );
    });
  }

  for (final quantity in [-1, 0, 100]) {
    test('trainer battle stock rejects quantity $quantity', () {
      expect(
        () => ProjectValidator.validate(
          _project({'potion': quantity}),
          itemCatalog: _catalog(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  }

  for (final quantity in [1, 99]) {
    test('trainer battle stock accepts quantity $quantity', () {
      expect(
        () => ProjectValidator.validate(
          _project({'potion': quantity}),
          itemCatalog: _catalog(),
        ),
        returnsNormally,
      );
    });
  }

  for (final itemId in [
    '',
    ' ',
    ' potion ',
    'POTION',
    'legacy-potion',
    'missing',
  ]) {
    test('trainer battle stock requires the exact item ID "$itemId"', () {
      expect(
        () => ProjectValidator.validate(
          _project({itemId: 1}),
          itemCatalog: _catalog(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  }

  test('trainer battle stock accepts sixteen distinct item types', () {
    final stock = {for (var i = 0; i < 16; i++) 'tonic_$i': 1};
    expect(
      () => ProjectValidator.validate(
        _project(stock),
        itemCatalog: _tonicCatalog(16),
      ),
      returnsNormally,
    );
    expect(_project(stock).trainers.single.toJson()['battleItems'], stock);
  });

  test('trainer battle stock rejects seventeen distinct item types', () {
    expect(
      () => ProjectValidator.validate(
        _project({for (var i = 0; i < 17; i++) 'tonic_$i': 1}),
        itemCatalog: _tonicCatalog(17),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  for (final itemId in ['potion', 'max_potion', 'antidote', 'full_heal']) {
    test('trainer battle stock accepts the supported effect of $itemId', () {
      expect(
        () => ProjectValidator.validate(
          _project({itemId: 1}),
          itemCatalog: _catalog(),
        ),
        returnsNormally,
      );
    });
  }

  for (final itemId in [
    'revive',
    'ether',
    'reusable_tonic',
    'passive',
    'lunar_orb',
    'field_tonic',
  ]) {
    test('trainer battle stock rejects the unsupported item $itemId', () {
      expect(
        () => ProjectValidator.validate(
          _project({itemId: 1}),
          itemCatalog: _catalog(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  }

  for (final definition in [
    _potion.copyWith(
      uses: [
        _use(
          const ProjectItemEffectDefinition.healHp(
            mode: ProjectItemAmountMode.flat,
            amount: 20,
          ),
          target: ProjectItemTargetKind.world,
        ),
      ],
    ),
    _potion.copyWith(
      uses: [
        _use(
          const ProjectItemEffectDefinition.healHp(
            mode: ProjectItemAmountMode.flat,
            amount: 0,
          ),
        ),
      ],
    ),
  ]) {
    test(
      'trainer battle stock rejects an invalid catalogue definition ${definition.uses.single.toJson()}',
      () {
        expect(
          () => ProjectValidator.validate(
            _project({'potion': 1}),
            itemCatalog: ProjectItemCatalog(
              schemaVersion: 1,
              entries: [definition],
            ),
          ),
          throwsA(isA<ValidationException>()),
        );
      },
    );
  }

  test('trainer battle stock rejects an ambiguous catalogue identity', () {
    expect(
      () => ProjectValidator.validate(
        _project({'potion': 1}),
        itemCatalog: _catalog(duplicate: true),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test(
    'trainer structural validation remains available without a catalogue',
    () {
      expect(
        () => ProjectValidator.validate(_project({'potion': 1})),
        returnsNormally,
      );
      expect(
        () => ProjectValidator.validate(_project(<String, int>{})),
        returnsNormally,
      );
    },
  );

  test(
    'trainer battle stock is a distinct blocking editable item reference',
    () {
      final trainer = ProjectTrainerEntry.fromJson({
        ..._trainer({'potion': 2}),
        'rewardItemGrants': [
          {'itemId': 'potion', 'quantity': 4},
        ],
        'team': [
          {
            'speciesId': 'test_species',
            'level': 10,
            'heldItemId': 'potion',
            'ballItemId': 'lunar_orb',
          },
        ],
      });
      final index = buildProjectItemReferenceIndex(
        project: ProjectManifest(
          name: 'Trainer stock references',
          maps: [],
          tilesets: [],
          trainers: [trainer],
        ),
      );
      final references = index.blockingReferencesFor('potion');
      expect(references, hasLength(3));
      expect(references.map((reference) => reference.kind.name).toSet(), {
        'trainerBattleItem',
        'trainerReward',
        'trainerHeld',
      });
      final stock = references.singleWhere(
        (reference) => reference.kind.name == 'trainerBattleItem',
      );
      expect(stock.sourceKind, 'trainer');
      expect(stock.sourceId, 'trainer_alpha');
      expect(stock.editablePath, 'trainers[trainer_alpha].battleItems[potion]');
      expect(stock.blocksDeletion, isTrue);
      expect(
        index.blockingReferencesFor('lunar_orb').single.kind.name,
        'trainerBall',
      );
    },
  );
}

Map<String, dynamic> _trainer(Object? stock) => {
  'id': 'trainer_alpha',
  'name': 'Trainer Alpha',
  'trainerClass': 'Trainer',
  'battleItems': stock,
  'team': [
    {'speciesId': 'test_species', 'level': 10},
  ],
};

ProjectManifest _project(Object? stock) => ProjectManifest(
  name: 'Trainer battle stock',
  maps: [],
  tilesets: [],
  trainers: [ProjectTrainerEntry.fromJson(_trainer(stock))],
);

ProjectItemCatalog _tonicCatalog(int count) => ProjectItemCatalog(
  schemaVersion: 1,
  entries: [for (var i = 0; i < count; i++) _potion.copyWith(id: 'tonic_$i')],
);

ProjectItemCatalog _catalog({bool duplicate = false}) => ProjectItemCatalog(
  schemaVersion: 1,
  entries: [
    _potion,
    if (duplicate) _potion,
    _potion.copyWith(
      id: 'max_potion',
      uses: [
        _use(
          const ProjectItemEffectDefinition.healHp(
            mode: ProjectItemAmountMode.full,
          ),
        ),
      ],
    ),
    _potion.copyWith(
      id: 'antidote',
      uses: [
        _use(
          const ProjectItemEffectDefinition.cureStatus(
            mode: ProjectItemStatusCureMode.listed,
            statusIds: {'poison'},
          ),
        ),
      ],
    ),
    _potion.copyWith(
      id: 'full_heal',
      uses: [
        _use(
          const ProjectItemEffectDefinition.cureStatus(
            mode: ProjectItemStatusCureMode.all,
          ),
        ),
      ],
    ),
    _potion.copyWith(
      id: 'revive',
      uses: [
        _use(
          const ProjectItemEffectDefinition.revive(
            rateNumerator: 1,
            rateDenominator: 2,
          ),
        ),
      ],
    ),
    _potion.copyWith(
      id: 'ether',
      uses: [
        _use(
          const ProjectItemEffectDefinition.restorePp(
            mode: ProjectItemAmountMode.flat,
            amount: 10,
          ),
          target: ProjectItemTargetKind.partyMove,
        ),
      ],
    ),
    _potion.copyWith(
      id: 'reusable_tonic',
      uses: [
        _use(
          const ProjectItemEffectDefinition.healHp(
            mode: ProjectItemAmountMode.flat,
            amount: 20,
          ),
          consumption: ProjectItemConsumptionPolicy.never,
        ),
      ],
    ),
    _potion.copyWith(id: 'passive', uses: []),
    const ProjectItemDefinition(
      id: 'lunar_orb',
      displayName: 'Lunar Orb',
      pocketId: 'balls',
      capture: ProjectCaptureItemDefinition(
        rateNumerator: 1,
        rateDenominator: 1,
        allowedEncounterKinds: {EncounterKind.walk},
      ),
    ),
    _potion.copyWith(
      id: 'field_tonic',
      uses: [
        _use(
          const ProjectItemEffectDefinition.healHp(
            mode: ProjectItemAmountMode.flat,
            amount: 20,
          ),
          contexts: {ProjectItemUseContext.overworld},
        ),
      ],
    ),
  ],
);

ProjectItemUseDefinition _use(
  ProjectItemEffectDefinition effect, {
  Set<ProjectItemUseContext> contexts = const {ProjectItemUseContext.battle},
  ProjectItemTargetKind target = ProjectItemTargetKind.partyMember,
  ProjectItemConsumptionPolicy consumption =
      ProjectItemConsumptionPolicy.onApplied,
}) => ProjectItemUseDefinition(
  contexts: contexts,
  target: target,
  consumption: consumption,
  effect: effect,
);

const _potion = ProjectItemDefinition(
  id: 'potion',
  displayName: 'Potion',
  aliases: ['legacy-potion'],
  pocketId: 'medicine',
  uses: [
    ProjectItemUseDefinition(
      contexts: {ProjectItemUseContext.overworld, ProjectItemUseContext.battle},
      target: ProjectItemTargetKind.partyMember,
      consumption: ProjectItemConsumptionPolicy.onApplied,
      effect: ProjectItemEffectDefinition.healHp(
        mode: ProjectItemAmountMode.flat,
        amount: 20,
      ),
    ),
  ],
);

