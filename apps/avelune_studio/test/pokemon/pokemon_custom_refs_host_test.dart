import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';

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
        final evolution =
            jsonDecode(
                  await File(
                    '$sourcePath/evolutions/bulbasaur.json',
                  ).readAsString(),
                )
                as Map<String, dynamic>;
        final media =
            jsonDecode(
                  await File('$sourcePath/media/bulbasaur.json').readAsString(),
                )
                as Map<String, dynamic>;
        species['schemaVersion'] = 1;
        learnset['schemaVersion'] = 1;
        evolution['schemaVersion'] = 1;
        media['schemaVersion'] = 1;
        (species['refs'] as Map)['learnset'] = 'custom-learn';
        (species['refs'] as Map)['evolution'] = 'custom-evolution';
        (species['refs'] as Map)['media'] = 'custom-media';
        learnset['speciesId'] = 'custom-learn';
        evolution['speciesId'] = 'custom-evolution';
        media['speciesId'] = 'custom-media';
        final speciesFile = File('$root/species/custom-filename.json');
        final learnsetFile = File('$root/learnsets/custom-learn.json');
        final evolutionFile = File('$root/evolutions/custom-evolution.json');
        final mediaFile = File('$root/media/custom-media.json');
        await speciesFile.parent.create(recursive: true);
        await learnsetFile.parent.create(recursive: true);
        await evolutionFile.parent.create(recursive: true);
        await mediaFile.parent.create(recursive: true);
        await speciesFile.writeAsString(jsonEncode(species));
        await learnsetFile.writeAsString(jsonEncode(learnset));
        await evolutionFile.writeAsString(jsonEncode(evolution));
        await mediaFile.writeAsString(jsonEncode(media));
        final moves = File('$root/catalogs/moves.json');
        await moves.parent.create(recursive: true);
        await File(movesFixturePath).copy(moves.path);
      },
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
    await pumpIo(tester);
    final draft = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!
        .selectedDraft!;
    expect(
      draft.document(PokemonDocumentFamily.learnset)?['speciesId'],
      'custom-learn',
    );
    expect(
      draft.document(PokemonDocumentFamily.evolution)?['speciesId'],
      'custom-evolution',
    );
    expect(
      draft.document(PokemonDocumentFamily.media)?['speciesId'],
      'custom-media',
    );
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
      final evolution =
          jsonDecode(
                await File(
                  '$root/evolutions/custom-evolution.json',
                ).readAsString(),
              )
              as Map;
      final media =
          jsonDecode(await File('$root/media/custom-media.json').readAsString())
              as Map;
      return (species, learnset, conventional, evolution, media);
    }))!;
    expect((result.$1['names'] as Map)['fr'], 'Nom personnalisé');
    expect((result.$2['startingMoves'] as List), contains('leech-seed'));
    expect(result.$3, isFalse);
    expect(result.$4['speciesId'], 'custom-evolution');
    expect(result.$5['speciesId'], 'custom-media');
    expect(tester.takeException(), isNull);
  });
}

const sourcePath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10';
const movesFixturePath =
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/moves.json';
