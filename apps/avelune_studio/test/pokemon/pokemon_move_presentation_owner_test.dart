import 'dart:io';

import 'package:avelune_studio/features/pokemon/data/pokemon_moves_projection.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart'
    show GamePackageExportProfile, GamePackageExportProfileStore;
import 'package:map_core/map_core.dart';

import '../support/m3_story_fixture.dart';
import '../support/pokemon_authoring_fixture.dart';

void main() {
  const catalog = PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: PokemonDataMeta(description: ''),
    entries: [
      {
        'id': 'growl',
        'name': 'Growl',
        'source': 'golden_item_system',
        'type': 'normal',
        'category': 'status',
      },
      {
        'id': 'custom-growl',
        'name': 'My Growl',
        'names': {'fr': 'Mon Cri'},
        'source': 'project_custom',
        'type': 'grass',
        'category': 'special',
        'power': 100,
      },
    ],
  );

  test(
    'project locale selects official and authored names without changing IDs',
    () {
      final french = projectPokemonMoves(catalog, 'moves.json', 'fr-FR');
      final english = projectPokemonMoves(catalog, 'moves.json', 'en');
      expect(french.entries.first.id, 'custom-growl');
      expect(french.entries.first.name, 'Mon Cri');
      expect(french.entries.first.userCreated, isTrue);
      expect(french.entries.last.id, 'growl');
      expect(french.entries.last.name, 'Rugissement');
      expect(french.entries.last.userCreated, isFalse);
      expect(english.entries.first.name, 'Growl');
      expect(english.entries.last.name, 'My Growl');
    },
  );

  test('the real Pokémon workspace uses the game export locale', () async {
    final fixture = await PokemonAuthoringFixture.create(
      prepareSource: _prepareFrenchMoves,
    );
    addTearDown(fixture.dispose);
    expect(await fixture.view(PokemonWorkspaceView.moves), isTrue);
    final names = {
      for (final move in fixture.pokemon.index!.moves.entries)
        move.id: move.name,
    };
    expect(names['growl'], 'Rugissement');
    expect(names['leech-seed'], 'Vampigraine');
    expect(names['protect'], 'Abri');
    expect(names['tackle'], 'Charge');
    expect(names.values, isNot(contains('Growl')));
  });
}

Future<void> _prepareFrenchMoves(M3StoryFixture source) async {
  final moves = File(
    '${source.directory.path}/data/pokemon/catalogs/moves.json',
  );
  await moves.parent.create(recursive: true);
  await File(
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/moves.json',
  ).copy(moves.path);
  await GamePackageExportProfileStore(projectRoot: source.directory).save(
    GamePackageExportProfile(
      gameId: 'pokemon.move.locale.test',
      gameVersion: '1.0.0',
      title: 'Test des attaques',
      authorName: 'Test',
      defaultLocale: 'fr',
      supportedLocales: ['fr', 'en'],
    ),
  );
}
