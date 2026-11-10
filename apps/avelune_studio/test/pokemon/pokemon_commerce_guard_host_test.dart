import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_workflow.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/pokemon_authoring_fixture.dart';
import '../support/m3_story_fixture.dart';

void main() {
  Future<PokemonAuthoringFixture> fixture() async {
    final host = await PokemonAuthoringFixture.create(prepareSource: _seed);
    addTearDown(host.dispose);
    return host;
  }

  test('item draft stays intact when changing owner is refused', () async {
    final host = await fixture();
    await _editItem(host, 'Potion en cours');
    host.decision = PokemonDraftDecision.stay;
    expect(await host.view(PokemonWorkspaceView.pokedex), isFalse);
    expect(host.draftConfirmations, 1);
    expect(host.pokemon.view, PokemonWorkspaceView.items);
    expect(host.commerce.item!.displayName, 'Potion en cours');
    expect(host.commerce.dirty, isTrue);
  });

  test('discard resets item before entering the Pokedex', () async {
    final host = await fixture();
    await _editItem(host, 'Potion en cours');
    host.decision = PokemonDraftDecision.discard;
    expect(await host.view(PokemonWorkspaceView.pokedex), isTrue);
    expect(host.pokemon.view, PokemonWorkspaceView.pokedex);
    expect(host.commerce.item!.displayName, 'Potion');
    expect(host.commerce.dirty, isFalse);
  });

  test(
    'save writes the item and independent reopen sees it before switching',
    () async {
      final host = await fixture();
      await _editItem(host, 'Potion du quai');
      host.decision = PokemonDraftDecision.save;
      expect(await host.view(PokemonWorkspaceView.pokedex), isTrue);
      expect(host.pokemon.view, PokemonWorkspaceView.pokedex);
      final session = ProjectSession(
        sessionId: 'commerce-reopen',
        name: host.source.session.name,
        directoryPath: host.source.directory.path,
      );
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadProject(session);
      final reopened = await LocalPokemonCommerceAdapter(
        session: session,
        mapAdapter: maps,
      ).load();
      expect(
        reopened.catalog!.entries
            .firstWhere((item) => item.id == 'potion')
            .displayName,
        'Potion du quai',
      );
    },
  );

  test('species draft cannot be hidden by the item owner', () async {
    final host = await fixture();
    expect(await host.pokemon.selectSpecies('bulbasaur'), isTrue);
    host.pokemon.edit(
      PokemonDocumentFamily.species,
      (json) => (json['names'] as Map)['fr'] = 'Bulbizarre en cours',
    );
    host.decision = PokemonDraftDecision.stay;
    expect(await host.view(PokemonWorkspaceView.items), isFalse);
    expect(host.draftConfirmations, 1);
    expect(host.pokemon.view, PokemonWorkspaceView.pokedex);
    expect(host.pokemon.selectedDraft!.dirty, isTrue);
  });

  test('shop draft cannot be hidden by the move owner', () async {
    final host = await fixture();
    expect(await host.view(PokemonWorkspaceView.shops), isTrue);
    expect(
      host.commerce.selectShop(
        host.commerce.snapshot!.shops.singleWhere((shop) => shop.id == 'gare'),
      ),
      isTrue,
    );
    host.commerce.editShop((shop) => shop.copyWith(label: 'Boutique modifiée'));
    host.decision = PokemonDraftDecision.stay;
    expect(await host.view(PokemonWorkspaceView.moves), isFalse);
    expect(host.draftConfirmations, 1);
    expect(host.pokemon.view, PokemonWorkspaceView.shops);
    expect(host.commerce.shop!.label, 'Boutique modifiée');
  });

  test(
    'revision conflict blocks owner change and preserves both drafts',
    () async {
      final host = await fixture();
      await _editItem(host, 'Brouillon local');
      final file = File(
        '${host.source.directory.path}/data/pokemon/catalogs/items.json',
      );
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      (json['entries'] as List).first['displayName'] = 'Modification externe';
      await file.writeAsString(jsonEncode(json));
      host.decision = PokemonDraftDecision.save;
      expect(await host.view(PokemonWorkspaceView.shops), isFalse);
      expect(host.pokemon.view, PokemonWorkspaceView.items);
      expect(host.commerce.item!.displayName, 'Brouillon local');
      expect(host.commerce.error, contains('changé sur le disque'));
      expect(await file.readAsString(), contains('Modification externe'));
    },
  );
}

Future<void> _editItem(PokemonAuthoringFixture host, String name) async {
  expect(await host.view(PokemonWorkspaceView.items), isTrue);
  expect(
    host.commerce.selectItem(
      host.commerce.snapshot!.catalog!.entries.firstWhere(
        (item) => item.id == 'potion',
      ),
    ),
    isTrue,
  );
  host.commerce.editItem((item) => item.copyWith(displayName: name));
  expect(host.commerce.dirty, isTrue);
}

Future<void> _seed(M3StoryFixture fixture) async {
  final root = fixture.directory.path;
  final target = File('$root/data/pokemon/catalogs/items.json');
  await target.parent.create(recursive: true);
  await File(
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/items.json',
  ).copy(target.path);
  const sourcePath =
      '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10';
  for (final (folder, file) in [
    ('species', '0001-bulbasaur.json'),
    ('learnsets', 'bulbasaur.json'),
    ('evolutions', 'bulbasaur.json'),
    ('media', 'bulbasaur.json'),
  ]) {
    final document = jsonDecode(
      await File('$sourcePath/$folder/$file').readAsString(),
    ) as Map<String, dynamic>;
    document['schemaVersion'] = 1;
    final destination = File('$root/data/pokemon/$folder/$file');
    await destination.parent.create(recursive: true);
    await destination.writeAsString(jsonEncode(document));
  }
  final manifestFile = File('$root/project.json');
  final manifest = ProjectManifest.fromJson(
    jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
  );
  await manifestFile.writeAsString(
    jsonEncode(
      manifest
          .copyWith(
            shops: [
              const ShopDefinition(id: 'gare', label: 'Boutique de la gare'),
            ],
          )
          .toJson(),
    ),
  );
}
