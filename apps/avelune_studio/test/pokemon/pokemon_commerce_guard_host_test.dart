import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/m3_story_fixture.dart';
import '../support/map_host_fixture.dart';

void main() {
  testWidgets('item draft stays intact when changing view is refused', (
    tester,
  ) async {
    final host = await MapHostFixture.open(tester, prepareSource: _seed);
    await _editItem(tester, host, 'Potion en cours');
    await tester.tap(find.text('Pokédex').first);
    await pumpIo(tester);
    expect(find.text('Conserver le brouillon Pokémon ?'), findsOneWidget);
    await tester.tap(find.text('Rester'));
    await pumpIo(tester);
    expect(_pokemon(tester).view, PokemonWorkspaceView.items);
    expect(_pokemon(tester).commerce!.item!.displayName, 'Potion en cours');
    expect(_pokemon(tester).commerce!.dirty, isTrue);
  });

  testWidgets('discard resets item before entering Pokédex', (tester) async {
    final host = await MapHostFixture.open(tester, prepareSource: _seed);
    await _editItem(tester, host, 'Potion en cours');
    await tester.tap(find.text('Pokédex').first);
    await pumpIo(tester);
    await tester.tap(find.text('Annuler les modifications').last);
    await pumpIo(tester);
    expect(_pokemon(tester).view, PokemonWorkspaceView.pokedex);
    expect(_pokemon(tester).commerce!.item!.displayName, 'Potion');
    expect(_pokemon(tester).commerce!.dirty, isFalse);
  });

  testWidgets('save writes item and independent reopen sees it', (
    tester,
  ) async {
    final host = await MapHostFixture.open(tester, prepareSource: _seed);
    await _editItem(tester, host, 'Potion du quai');
    await tester.tap(find.text('Pokédex').first);
    await pumpIo(tester);
    await tester.tap(find.text('Enregistrer').last);
    await pumpIo(tester);
    expect(_pokemon(tester).view, PokemonWorkspaceView.pokedex);
    final reopened = (await tester.runAsync(() async {
      final session = ProjectSession(
        sessionId: 'commerce-reopen',
        name: host.source.session.name,
        directoryPath: host.source.directory.path,
      );
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadProject(session);
      return LocalPokemonCommerceAdapter(
        session: session,
        mapAdapter: maps,
      ).load();
    }))!;
    expect(
      reopened.catalog!.entries
          .firstWhere((item) => item.id == 'potion')
          .displayName,
      'Potion du quai',
    );
  });

  testWidgets('species draft cannot be hidden by Objets', (tester) async {
    final host = await MapHostFixture.open(tester, prepareSource: _seed);
    await host.go('Pokémon');
    await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
    await pumpIo(tester);
    await tester.enterText(
      find.byKey(const ValueKey('species-names.fr')),
      'Bulbizarre en cours',
    );
    await tester.tap(find.text('Objets').first);
    await pumpIo(tester);
    expect(find.text('Conserver le brouillon Pokémon ?'), findsOneWidget);
    await tester.tap(find.text('Rester'));
    await pumpIo(tester);
    expect(_pokemon(tester).view, PokemonWorkspaceView.pokedex);
    expect(_pokemon(tester).selectedDraft!.dirty, isTrue);
  });

  testWidgets('shop draft cannot be hidden by Attaques', (tester) async {
    final host = await MapHostFixture.open(tester, prepareSource: _seed);
    await host.go('Pokémon');
    await tester.tap(find.text('Boutiques').first);
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('shop-gare')));
    await pumpIo(tester);
    await tester.enterText(
      find.byKey(const ValueKey('shop-label-gare')),
      'Boutique modifiée',
    );
    await tester.tap(find.text('Attaques').first);
    await pumpIo(tester);
    expect(find.text('Conserver le brouillon Pokémon ?'), findsOneWidget);
    await tester.tap(find.text('Rester'));
    await pumpIo(tester);
    expect(_pokemon(tester).view, PokemonWorkspaceView.shops);
    expect(_pokemon(tester).commerce!.shop!.label, 'Boutique modifiée');
  });

  testWidgets('revision conflict blocks view change and preserves draft', (
    tester,
  ) async {
    final host = await MapHostFixture.open(tester, prepareSource: _seed);
    await _editItem(tester, host, 'Brouillon local');
    final file = File(
      '${host.source.directory.path}/data/pokemon/catalogs/items.json',
    );
    await tester.runAsync(() async {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      (json['entries'] as List).first['displayName'] = 'Modification externe';
      await file.writeAsString(jsonEncode(json));
    });
    await tester.tap(find.text('Boutiques').first);
    await pumpIo(tester);
    await tester.tap(find.text('Enregistrer').last);
    await pumpIo(tester);
    expect(_pokemon(tester).view, PokemonWorkspaceView.items);
    expect(_pokemon(tester).commerce!.item!.displayName, 'Brouillon local');
    expect(_pokemon(tester).commerce!.error, contains('changé sur le disque'));
    expect(
      await tester.runAsync(file.readAsString),
      contains('Modification externe'),
    );
  });
}

PokemonWorkspaceController _pokemon(WidgetTester tester) => tester
    .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
    .controller!;

Future<void> _editItem(
  WidgetTester tester,
  MapHostFixture host,
  String name,
) async {
  await host.go('Pokémon');
  await tester.tap(find.text('Objets').first);
  await pumpIo(tester);
  await tester.tap(find.byKey(const ValueKey('item-potion')));
  await pumpIo(tester);
  await tester.enterText(find.byKey(const ValueKey('item-name-potion')), name);
  expect(_pokemon(tester).commerce!.dirty, isTrue);
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
    final document =
        jsonDecode(await File('$sourcePath/$folder/$file').readAsString())
            as Map<String, dynamic>;
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
