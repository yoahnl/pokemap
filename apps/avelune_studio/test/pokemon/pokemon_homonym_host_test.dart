import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_species_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets('homonyms keep distinct identities through filtering and save', (
    tester,
  ) async {
    final host = await MapHostFixture.open(
      tester,
      prepareSource: (fixture) async {
        final root = '${fixture.directory.path}/data/pokemon/species';
        final original =
            jsonDecode(await File(sourcePath).readAsString()) as Map;
        original['schemaVersion'] = 1;
        final second = jsonDecode(jsonEncode(original)) as Map;
        second['id'] = 'ivysaur';
        second['slug'] = 'ivysaur';
        second['nationalDex'] = 2;
        final refs = second['refs'] as Map;
        refs['learnset'] = 'ivysaur';
        refs['evolution'] = 'ivysaur';
        refs['media'] = 'ivysaur';
        await Directory(root).create(recursive: true);
        await File(
          '$root/0001-bulbasaur.json',
        ).writeAsString(jsonEncode(original));
        await File('$root/0002-ivysaur.json').writeAsString(jsonEncode(second));
      },
    );
    final first = File(
      '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
    );
    final beforeFirst = (await tester.runAsync(first.readAsBytes))!;
    await host.go('Pokémon');
    await pumpIo(tester);
    expect(find.byKey(const ValueKey('species-bulbasaur')), findsOneWidget);
    expect(find.byKey(const ValueKey('species-ivysaur')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('species-ivysaur')));
    await pumpIo(tester);
    final search = find.descendant(
      of: find.byType(PokemonSpeciesLibrary),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, 'bulbasaur');
    await tester.pump();
    expect(find.textContaining('masquée par les filtres'), findsOneWidget);
    final controller = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!;
    expect(controller.selectedId, 'ivysaur');
    await tester.enterText(search, '');
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('species-names.fr')),
      'Bulbizarre II',
    );
    await tester.pump();
    await tester.tap(find.text('Enregistrer').first);
    await pumpIo(tester);
    expect((await tester.runAsync(first.readAsBytes))!, beforeFirst);
    final second = (await tester.runAsync(() async {
      return jsonDecode(
            await File(
              '${host.source.directory.path}/data/pokemon/species/0002-ivysaur.json',
            ).readAsString(),
          )
          as Map;
    }))!;
    expect(second['id'], 'ivysaur');
    expect((second['names'] as Map)['fr'], 'Bulbizarre II');
    expect(tester.takeException(), isNull);
  });
}

const sourcePath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
