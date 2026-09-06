import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/player/runtime_player_pause_data.dart';
import 'package:map_runtime/src/player/runtime_player_pause_data_builder.dart';

void main() {
  late Directory root;
  late _TrackedSpeciesDirectory speciesDirectory;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pause-evolution-items-');
    final directory = Directory('${root.path}/data/pokemon/species');
    await directory.create(recursive: true);
    speciesDirectory = _TrackedSpeciesDirectory(directory);
    for (final id in ['sproutle', 'bloomon']) {
      await File('${directory.path}/$id.json').writeAsString(jsonEncode({
        'schemaVersion': 1,
        'id': id,
        'names': {'en': id},
        'typing': {
          'types': ['grass']
        },
        'baseStats': {
          'hp': 80,
          'atk': 80,
          'def': 80,
          'spa': 80,
          'spd': 80,
          'spe': 80
        },
        'abilities': {'primary': 'overgrow'},
        'refs': {'learnset': id},
        'progression': {
          'growthRateId': 'medium',
          'baseExp': 100,
          'catchRate': 45
        },
      }));
    }
    final evolution =
        File('${root.path}/data/pokemon/evolutions/sproutle.json');
    await evolution.parent.create(recursive: true);
    await evolution.writeAsString(jsonEncode({
      'speciesId': 'sproutle',
      'evolutions': [
        {
          'targetSpeciesId': 'bloomon',
          'method': 'use_item',
          'itemId': 'leaf-stone'
        },
        {
          'targetSpeciesId': 'missing-mon',
          'method': 'use_item',
          'itemId': 'water-stone'
        },
      ],
    }));
  });

  tearDown(() => root.delete(recursive: true));

  Future<RuntimePlayerPauseDetailSnapshot> buildBag(
      List<BagEntry> entries) async {
    final createDirectory = Zone.current.bindUnaryCallback(Directory.new);
    final details = await IOOverrides.runZoned(
      () => const RuntimePlayerPauseDataBuilder().build(
        gameState: GameState(
          saveId: 'evolution-pause',
          party: const PlayerParty(members: [
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              level: 20,
              currentHp: 40,
            ),
          ]),
          bag: Bag(entries: entries),
        ),
        projectRootDirectory: root.path,
        pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ),
        locale: 'fr',
        itemCatalog: ItemCatalogSnapshot.fromCatalog(const ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            ProjectItemDefinition(
                id: 'leaf-stone',
                displayName: 'Pierre Plante',
                pocketId: 'evolution-items'),
            ProjectItemDefinition(
                id: 'water-stone',
                displayName: 'Pierre Eau',
                pocketId: 'evolution-items'),
            ProjectItemDefinition(
                id: 'town-map', displayName: 'Carte', pocketId: 'key-items'),
          ],
        )),
      ),
      createDirectory: (path) => path == speciesDirectory.path
          ? speciesDirectory
          : createDirectory(path),
    );
    return details[RuntimePlayerPauseSection.bag]!;
  }

  test('keeps an owned evolution item usable without loading unowned targets',
      () async {
    final bag =
        await buildBag(const [BagEntry(itemId: 'leaf-stone', quantity: 1)]);
    expect(bag.entries.single.bagItem!.itemId, 'leaf-stone');
    expect(bag.entries.single.bagAction!.isEnabled, isTrue);
    expect(bag.entries.single.bagAction!.usability, ItemUsabilityState.usable);
    expect(speciesDirectory.listCount, 2);
  });

  test('keeps every owned item with a valid evolution target usable', () async {
    final evolution =
        File('${root.path}/data/pokemon/evolutions/sproutle.json');
    await evolution.writeAsString(
        (await evolution.readAsString()).replaceAll('missing-mon', 'bloomon'));
    final bag = await buildBag(const [
      BagEntry(itemId: 'leaf-stone', quantity: 2),
      BagEntry(itemId: 'water-stone', quantity: 1),
    ]);
    expect(bag.entries, hasLength(2));
    expect(bag.entries.map((entry) => entry.bagAction!.isEnabled),
        everyElement(isTrue));
    expect(speciesDirectory.listCount, 2);
  });

  for (final scenario in <String, List<BagEntry>>{
    'empty inventory': [],
    'depleted evolution item': [BagEntry(itemId: 'leaf-stone', quantity: 0)],
    'unrelated inventory item': [BagEntry(itemId: 'town-map', quantity: 1)],
  }.entries) {
    test('does not rescan species for ${scenario.key}', () async {
      final bag = await buildBag(scenario.value);
      expect(
          bag.entries.map((entry) => entry.bagItem!.itemId),
          scenario.value
              .where((entry) => entry.quantity > 0)
              .map((entry) => entry.itemId));
      expect(speciesDirectory.listCount, 1);
    });
  }

  test('keeps an owned item unavailable when its evolution target is absent',
      () async {
    final bag =
        await buildBag(const [BagEntry(itemId: 'water-stone', quantity: 1)]);
    expect(bag.entries.single.bagAction!.isEnabled, isFalse);
  });
}

class _TrackedSpeciesDirectory extends Fake implements Directory {
  _TrackedSpeciesDirectory(this.delegate);

  final Directory delegate;
  int listCount = 0;

  @override
  String get path => delegate.path;

  @override
  Future<bool> exists() => delegate.exists();

  @override
  Stream<FileSystemEntity> list(
      {bool recursive = false, bool followLinks = true}) {
    listCount += 1;
    return delegate.list(recursive: recursive, followLinks: followLinks);
  }
}
