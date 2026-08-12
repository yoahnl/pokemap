import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final snapshot = ItemCatalogSnapshot.fromCatalog(_catalog());
  final service = PlayerItemUseService(snapshot: snapshot);
  final resolver = ItemCapabilityResolver(snapshot);

  group('supported item capability matrix', () {
    test('overworld and battle healing consume exactly one unit', () {
      for (final context in ProjectItemUseContext.values) {
        final initial = _state(itemId: 'dual-potion', quantity: 2);
        final result = service.use(
          _request(initial, 'dual-potion', context: context),
        );

        expect(result.isSuccess, isTrue);
        expect(result.state.party.members.single.currentHp, 30);
        expect(result.state.bag.entries.single.quantity, 1);
        expect(
          result.consumptionReceipt,
          const ItemConsumptionReceipt(
            itemId: 'dual-potion',
            quantity: 1,
            quantityBefore: 2,
            quantityAfter: 1,
            reason: ItemConsumptionReason.appliedEffect,
          ),
        );
        expect(
          result.consumptionReceipt,
          isNot(
            const ItemConsumptionReceipt(
              itemId: 'dual-potion',
              quantity: 1,
              quantityBefore: 2,
              quantityAfter: 1,
              reason: ItemConsumptionReason.captureAttempt,
            ),
          ),
        );
      }
    });

    test('party move target with never consumption changes PP only', () {
      final initial = _state(itemId: 'reusable-ether', quantity: 1);
      final result = service.use(
        _request(
          initial,
          'reusable-ether',
          moveId: 'tackle',
          maxPpByMoveId: const <String, int>{'tackle': 35},
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.state.party.members.single.currentPpByMoveId,
        const <String, int>{'tackle': 15},
      );
      expect(result.state.bag, initial.bag);
      expect(result.consumptionReceipt, isNull);
    });

    test('passive and unavailable capabilities remain distinct', () {
      expect(
        resolver.classifyUse(
          itemId: 'passive-key',
          context: ProjectItemUseContext.overworld,
        ),
        ItemUsabilityState.passive,
      );
      expect(
        resolver.classifyUse(
          itemId: 'field-tonic',
          context: ProjectItemUseContext.battle,
        ),
        ItemUsabilityState.unavailableInContext,
      );
      expect(
        resolver.classifyUse(
          itemId: 'missing',
          context: ProjectItemUseContext.overworld,
        ),
        ItemUsabilityState.invalidDefinition,
      );
    });
  });

  group('failed item capability matrix', () {
    test('wrong target and invalid party target are atomic', () {
      final wrongTarget = _state(itemId: 'world-effect');
      final invalidTarget = _state(itemId: 'dual-potion');

      _expectAtomicFailure(
        service.use(_request(wrongTarget, 'world-effect')),
        wrongTarget,
        PlayerItemUseFailure.wrongTarget,
      );
      _expectAtomicFailure(
        service.use(
          _request(invalidTarget, 'dual-potion', partyIndex: 4),
        ),
        invalidTarget,
        PlayerItemUseFailure.invalidTarget,
      );
    });

    test('unknown definition and unavailable context are atomic', () {
      final unknown = _state(itemId: 'missing');
      final unavailable = _state(itemId: 'field-tonic');

      _expectAtomicFailure(
        service.use(_request(unknown, 'missing')),
        unknown,
        PlayerItemUseFailure.unknownDefinition,
      );
      _expectAtomicFailure(
        service.use(
          _request(
            unavailable,
            'field-tonic',
            context: ProjectItemUseContext.battle,
          ),
        ),
        unavailable,
        PlayerItemUseFailure.unavailableInContext,
      );
    });

    test('insufficient quantity and no effect are atomic', () {
      final empty = _state(itemId: 'dual-potion', quantity: 0);
      final fullHp = _state(
        itemId: 'dual-potion',
        currentHp: 50,
      );

      _expectAtomicFailure(
        service.use(_request(empty, 'dual-potion')),
        empty,
        PlayerItemUseFailure.insufficientQuantity,
      );
      _expectAtomicFailure(
        service.use(_request(fullHp, 'dual-potion')),
        fullHp,
        PlayerItemUseFailure.noEffect,
      );
    });

    test('unsupported and protected key item uses are atomic', () {
      final unsupported = _state(itemId: 'unsupported-repel');
      final protected = _state(itemId: 'protected-tonic');

      _expectAtomicFailure(
        service.use(_request(unsupported, 'unsupported-repel')),
        unsupported,
        PlayerItemUseFailure.unsupportedCapability,
      );
      _expectAtomicFailure(
        service.use(_request(protected, 'protected-tonic')),
        protected,
        PlayerItemUseFailure.protectedKeyItem,
      );
    });

    test('passive item use is refused without inventing a receipt', () {
      final passive = _state(itemId: 'passive-key');

      _expectAtomicFailure(
        service.use(_request(passive, 'passive-key')),
        passive,
        PlayerItemUseFailure.unavailableInContext,
      );
    });
  });

  test('unsupported catalog capabilities are blocked before playtest', () {
    final report = validateProjectItemCatalog(
      ProjectItemCatalog(
        schemaVersion: 1,
        entries: <ProjectItemDefinition>[
          snapshot.definitionFor('unsupported-repel')!,
        ],
      ),
      capabilityTruth: itemSystemV1CapabilityTruth,
    );

    expect(report.hasBlockingDiagnostics, isTrue);
    expect(
      report.assessmentFor('unsupported-repel')?.readiness,
      ItemCapabilityReadiness.unsupported,
    );
    expect(
      report.diagnostics.map((diagnostic) => diagnostic.code),
      contains(ProjectItemCatalogDiagnosticCode.unsupportedCapability),
    );
  });
}

void _expectAtomicFailure(
  PlayerItemUseResult result,
  GameState initial,
  PlayerItemUseFailure failure,
) {
  expect(result.failure, failure);
  expect(result.state, same(initial));
  expect(result.state.bag, same(initial.bag));
  expect(result.consumptionReceipt, isNull);
}

PlayerItemUseRequest _request(
  GameState state,
  String itemId, {
  ProjectItemUseContext context = ProjectItemUseContext.overworld,
  int partyIndex = 0,
  String? moveId,
  Map<String, int> maxPpByMoveId = const <String, int>{},
}) {
  return PlayerItemUseRequest(
    state: state,
    itemId: itemId,
    context: context,
    partyIndex: partyIndex,
    maxHp: 50,
    moveId: moveId,
    maxPpByMoveId: maxPpByMoveId,
  );
}

GameState _state({
  required String itemId,
  int quantity = 1,
  int currentHp = 10,
}) {
  return GameState(
    saveId: 'item-matrix',
    bag: Bag(
      entries: quantity == 0
          ? const <BagEntry>[]
          : <BagEntry>[BagEntry(itemId: itemId, quantity: quantity)],
    ),
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'fixture-mon',
          natureId: 'hardy',
          abilityId: 'fixture-ability',
          level: 10,
          currentHp: currentHp,
          knownMoveIds: const <String>['tackle'],
          currentPpByMoveId: const <String, int>{'tackle': 5},
        ),
      ],
    ),
  );
}

ProjectItemCatalog _catalog() {
  const heal = ProjectItemEffectDefinition.healHp(
    mode: ProjectItemAmountMode.flat,
    amount: 20,
  );
  return const ProjectItemCatalog(
    schemaVersion: 1,
    entries: <ProjectItemDefinition>[
      ProjectItemDefinition(
        id: 'dual-potion',
        displayName: 'Dual Potion',
        pocketId: 'medicine',
        uses: <ProjectItemUseDefinition>[
          ProjectItemUseDefinition(
            contexts: <ProjectItemUseContext>{
              ProjectItemUseContext.overworld,
              ProjectItemUseContext.battle,
            },
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: heal,
          ),
        ],
      ),
      ProjectItemDefinition(
        id: 'field-tonic',
        displayName: 'Field Tonic',
        pocketId: 'medicine',
        uses: <ProjectItemUseDefinition>[
          ProjectItemUseDefinition(
            contexts: <ProjectItemUseContext>{
              ProjectItemUseContext.overworld,
            },
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: heal,
          ),
        ],
      ),
      ProjectItemDefinition(
        id: 'reusable-ether',
        displayName: 'Reusable Ether',
        pocketId: 'medicine',
        uses: <ProjectItemUseDefinition>[
          ProjectItemUseDefinition(
            contexts: <ProjectItemUseContext>{
              ProjectItemUseContext.overworld,
            },
            target: ProjectItemTargetKind.partyMove,
            consumption: ProjectItemConsumptionPolicy.never,
            effect: ProjectItemEffectDefinition.restorePp(
              mode: ProjectItemAmountMode.flat,
              amount: 10,
            ),
          ),
        ],
      ),
      ProjectItemDefinition(
        id: 'world-effect',
        displayName: 'World Effect',
        pocketId: 'items',
        uses: <ProjectItemUseDefinition>[
          ProjectItemUseDefinition(
            contexts: <ProjectItemUseContext>{
              ProjectItemUseContext.overworld,
            },
            target: ProjectItemTargetKind.world,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.semanticAction(
              actionId: 'fixture.world',
            ),
          ),
        ],
      ),
      ProjectItemDefinition(
        id: 'unsupported-repel',
        displayName: 'Unsupported Repel',
        pocketId: 'items',
        uses: <ProjectItemUseDefinition>[
          ProjectItemUseDefinition(
            contexts: <ProjectItemUseContext>{
              ProjectItemUseContext.overworld,
            },
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.repel(steps: 100),
          ),
        ],
      ),
      ProjectItemDefinition(
        id: 'protected-tonic',
        displayName: 'Protected Tonic',
        pocketId: 'key_items',
        tags: <String>{'key-item'},
        uses: <ProjectItemUseDefinition>[
          ProjectItemUseDefinition(
            contexts: <ProjectItemUseContext>{
              ProjectItemUseContext.overworld,
            },
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: heal,
          ),
        ],
      ),
      ProjectItemDefinition(
        id: 'passive-key',
        displayName: 'Passive Key',
        pocketId: 'key_items',
        tags: <String>{'key-item'},
      ),
    ],
  ).normalized();
}
