import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('stale party selection resolves the same individual after reorder', () {
    const operations = PlayerStorageOperations();
    final original = _state(
      party: <PlayerPokemon>[
        _pokemon('pkm_lead', 'lead'),
        _pokemon('pkm_target', 'target'),
        _pokemon('pkm_other', 'other'),
      ],
    );
    final reordered = operations.swapPartyMembers(
      state: original,
      firstIndex: 0,
      secondIndex: 1,
    );

    final deposited = operations.depositByIndividualId(
      state: reordered.state,
      individualId: 'pkm_target',
    );

    expect(deposited.isSuccess, isTrue);
    expect(
      deposited.state.pokemonStorage.storedPokemon.single.individualId,
      'pkm_target',
    );
    expect(
      deposited.state.party.members.map((pokemon) => pokemon.individualId),
      isNot(contains('pkm_target')),
    );
  });

  test('party and box swap preserves both stable identities and forms', () {
    const operations = PlayerStorageOperations();
    final state = _state(
      party: <PlayerPokemon>[
        _pokemon('pkm_party', 'rotom', formId: 'heat'),
      ],
      boxes: <PokemonBox>[
        PokemonBox(
          id: 'box-a',
          label: 'A',
          pokemon: <PlayerPokemon>[
            _pokemon('pkm_box', 'rotom', formId: 'wash'),
          ],
        ),
      ],
    );

    final result = operations.swapPartyWithBoxByIndividualId(
      state: state,
      partyIndividualId: 'pkm_party',
      boxIndividualId: 'pkm_box',
    );

    expect(result.isSuccess, isTrue);
    expect(result.state.party.members.single.individualId, 'pkm_box');
    expect(result.state.party.members.single.formId, 'wash');
    expect(
      result.state.pokemonStorage.storedPokemon.single.individualId,
      'pkm_party',
    );
    expect(result.state.pokemonStorage.storedPokemon.single.formId, 'heat');
  });

  test('item evolution targets an individual after party reorder', () {
    const storage = PlayerStorageOperations();
    const evolutions = PokemonEvolutionItemOperations();
    final state = _state(
      party: <PlayerPokemon>[
        _pokemon('pkm_other', 'other'),
        _pokemon('pkm_evolve', 'sproutle', formId: 'autumn'),
      ],
      bag: const Bag(entries: <BagEntry>[
        BagEntry(itemId: 'item_leaf_stone', quantity: 1),
      ]),
    );
    final reordered = storage.setLeadByIndividualId(
      state: state,
      individualId: 'pkm_evolve',
    );

    final result = evolutions.useItemByIndividualId(
      reordered.state,
      itemId: 'item_leaf_stone',
      individualId: 'pkm_evolve',
      candidate: _evolutionCandidate,
      sourceMaxHp: 20,
      itemCatalog: _itemCatalog,
    );

    expect(result.isSuccess, isTrue);
    expect(result.evolution?.pokemon.individualId, 'pkm_evolve');
    expect(result.evolution?.pokemon.formId, 'autumn');
    expect(result.evolution?.pokemon.speciesId, 'bloomon');
  });

  test('held-item command resolves its individual after party reorder', () {
    const storage = PlayerStorageOperations();
    const heldItems = HeldItemOperations();
    final state = _state(
      party: <PlayerPokemon>[
        _pokemon('pkm_other', 'other'),
        _pokemon('pkm_target', 'target'),
      ],
      bag: const Bag(
        entries: <BagEntry>[
          BagEntry(itemId: 'oran-berry', quantity: 1),
        ],
      ),
    );
    final reordered = storage.setLeadByIndividualId(
      state: state,
      individualId: 'pkm_target',
    );

    final equipped = heldItems.equipByIndividualId(
      reordered.state,
      individualId: 'pkm_target',
      itemId: 'oran-berry',
    );

    expect(equipped.isSuccess, isTrue);
    expect(equipped.state.party.members.first.individualId, 'pkm_target');
    expect(equipped.state.party.members.first.heldItemId, 'oran-berry');
    expect(equipped.state.party.members.last.heldItemId, isEmpty);
  });
}

final _evolutionCandidate = PokemonEvolutionCandidate(
  opportunityId: 'sproutle-leaf-stone',
  sourceSpeciesId: 'sproutle',
  targetSpeciesId: 'bloomon',
  condition: const PokemonEvolutionCondition.item(
    itemId: 'item_leaf_stone',
  ),
  targetBaseStats: PokemonBaseStats(
    hp: 60,
    attack: 60,
    defense: 60,
    specialAttack: 60,
    specialDefense: 60,
    speed: 60,
  ),
  targetPrimaryAbilityId: 'overgrow',
  targetAbilityIds: <String>['overgrow'],
);

final _itemCatalog = ItemCatalogSnapshot.fromCatalog(
  const ProjectItemCatalog(
    schemaVersion: 1,
    entries: <ProjectItemDefinition>[
      ProjectItemDefinition(
        id: 'item_leaf_stone',
        displayName: 'Leaf Stone',
        pocketId: 'items',
      ),
    ],
  ),
);

GameState _state({
  required List<PlayerPokemon> party,
  List<PokemonBox> boxes = const <PokemonBox>[],
  Bag bag = const Bag(),
}) =>
    GameState(
      saveId: 'identity-operations',
      party: PlayerParty(members: party),
      pokemonStorage: PokemonStorage(boxes: boxes).normalized(),
      bag: bag,
    );

PlayerPokemon _pokemon(
  String individualId,
  String speciesId, {
  String formId = '',
}) =>
    PlayerPokemon(
      individualId: individualId,
      speciesId: speciesId,
      formId: formId,
      natureId: 'hardy',
      abilityId: speciesId == 'sproutle' ? 'overgrow' : 'ability',
      level: 10,
      currentHp: 10,
    );
