import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/pokemon_external_source_fixture.dart';

void main() {
  testWidgets('read-only search can leave A and cannot update project B', (
    tester,
  ) async {
    final source = HeldPokemonExternalSourceFixture();
    final home = StudioHomeNavigation();
    addTearDown(home.dispose);
    final first = await MapHostFixture.open(
      tester,
      home: home,
      pokemonExternalSource: source,
      prepareSource: (fixture) =>
          _seed(fixture.directory, 'Espèce du projet A'),
    );
    await first.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.text('Importer depuis une source'));
    await pumpIo(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('pokemon-external-query')),
        matching: find.byType(TextField),
      ),
      'bulbasaur',
    );
    await tester.pump();
    await tester.tap(find.text('Rechercher'));
    await tester.pump();
    final controller = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!;
    expect(controller.externalBusy, isTrue);
    expect(await home.allowSwitch!(), isTrue);
    await tester.pumpWidget(const SizedBox());
    source.gate.complete();
    await pumpIo(tester);
    final second = await MapHostFixture.open(
      tester,
      prepareSource: (fixture) =>
          _seed(fixture.directory, 'Espèce du projet B'),
    );
    await second.go('Pokémon');
    await pumpIo(tester);
    expect(find.text('Espèce du projet B'), findsWidgets);
    expect(find.text('Espèce du projet A'), findsNothing);
    expect(find.textContaining('Bulbasaur · #1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _seed(Directory directory, String name) async {
  final json = jsonDecode(await File(speciesPath).readAsString()) as Map;
  json['schemaVersion'] = 1;
  (json['names'] as Map)['fr'] = name;
  final file = File(
    '${directory.path}/data/pokemon/species/0001-bulbasaur.json',
  );
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(json));
}

const speciesPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
