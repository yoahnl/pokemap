import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets('save follows manifest and companion refs, not species id', (
    tester,
  ) async {
    final host = await MapHostFixture.open(
      tester,
      prepareSource: (fixture) async {
        final root = '${fixture.directory.path}/data/pokemon';
        final species =
            jsonDecode(
                  await File(
                    '$sourcePath/species/0001-bulbasaur.json',
                  ).readAsString(),
                )
                as Map<String, dynamic>;
        final learnset =
            jsonDecode(
                  await File(
                    '$sourcePath/learnsets/bulbasaur.json',
                  ).readAsString(),
                )
                as Map<String, dynamic>;
        species['schemaVersion'] = 1;
        learnset['schemaVersion'] = 1;
        (species['refs'] as Map)['learnset'] = 'custom-learn';
        final speciesFile = File('$root/species/custom-filename.json');
        final learnsetFile = File('$root/learnsets/custom-learn.json');
        await speciesFile.parent.create(recursive: true);
        await learnsetFile.parent.create(recursive: true);
        await speciesFile.writeAsString(jsonEncode(species));
        await learnsetFile.writeAsString(jsonEncode(learnset));
        final moves = File('$root/catalogs/moves.json');
        await moves.parent.create(recursive: true);
        await File(movesFixturePath).copy(moves.path);
      },
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
    await pumpIo(tester);
    await tester.enterText(
      find.byKey(const ValueKey('species-names.fr')),
      'Nom personnalisé',
    );
    await tester.tap(find.text('Apprentissages').last);
    await pumpIo(tester);
    await tester.tap(find.text('Ajouter une attaque').first);
    await pumpIo(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('move-leech-seed')),
        matching: find.byTooltip('Choisir cette attaque'),
      ),
    );
    await pumpIo(tester);
    await tester.tap(find.text('Enregistrer').first);
    await pumpIo(tester);
    final root = '${host.source.directory.path}/data/pokemon';
    final result = (await tester.runAsync(() async {
      final species =
          jsonDecode(
                await File('$root/species/custom-filename.json').readAsString(),
              )
              as Map;
      final learnset =
          jsonDecode(
                await File('$root/learnsets/custom-learn.json').readAsString(),
              )
              as Map;
      final conventional = await File(
        '$root/learnsets/bulbasaur.json',
      ).exists();
      return (species, learnset, conventional);
    }))!;
    expect((result.$1['names'] as Map)['fr'], 'Nom personnalisé');
    expect((result.$2['startingMoves'] as List), contains('leech-seed'));
    expect(result.$3, isFalse);
    expect(tester.takeException(), isNull);
  });
}

const sourcePath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10';
const movesFixturePath =
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/moves.json';
