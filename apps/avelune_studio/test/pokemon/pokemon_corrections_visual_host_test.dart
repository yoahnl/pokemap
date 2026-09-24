import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/presentation/features/pokemon/pokemon_move_detail.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_moves_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/map_host_fixture.dart';
import '../support/m3_story_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets(
    '1145 species and 754 moves fill and scroll their own viewports',
    (tester) async {
      await tester.runAsync(loadDesktopCaptureFonts);
      final captureKey = GlobalKey();
      final host = await MapHostFixture.open(
        tester,
        captureKey: captureKey,
        prepareSource: _seedLargeProject,
      );
      await host.go('Pokémon');
      await pumpIo(tester);
      expect(find.text('Pokédex · 1145 espèces'), findsOneWidget);
      final list = find.byKey(const PageStorageKey('pokemon-species-list'));
      final viewport = tester.getSize(list);
      expect(viewport.height, greaterThan(450));
      final listState = tester.state<ScrollableState>(
        find.descendant(of: list, matching: find.byType(Scrollable)),
      );
      expect(listState.position.maxScrollExtent, greaterThan(20000));
      await captureM3Widget(tester, captureKey, 'correction-01-pokedex');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('species-species-1144')),
        500,
        scrollable: find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        ),
        maxScrolls: 200,
      );
      expect(
        find.byKey(const ValueKey('species-species-1144')),
        findsOneWidget,
      );
      listState.position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('species-species-0000')));
      await pumpIo(tester);
      expect(find.text('Description du Pokédex · texte commun'), findsWidgets);
      expect(find.text('Type principal'), findsWidgets);
      expect(find.text('Afficher les identifiants'), findsOneWidget);
      await captureM3Widget(tester, captureKey, 'correction-04-vue-ensemble');
      await tester.tap(find.text('Voir les 2 langues disponibles'));
      await pumpIo(tester);
      await captureM3Widget(tester, captureKey, 'correction-05-traductions');
      await tester.tap(find.text('Attaques').first);
      await pumpIo(tester);
      expect(find.text('Attaques · 754'), findsOneWidget);
      await captureM3Widget(tester, captureKey, 'correction-02-attaques');
      await tester.tap(find.byKey(const ValueKey('move-move-0000')));
      await pumpIo(tester);
      final detail = find.byType(PokemonMoveDetail);
      final library = find.byType(PokemonMovesLibrary);
      expect(
        tester.getTopLeft(detail).dy - tester.getTopLeft(library).dy,
        lessThan(110),
      );
      await captureM3Widget(tester, captureKey, 'correction-03-attaque');
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _seedLargeProject(M3StoryFixture fixture) async {
  final root = fixture.directory.path;
  final template = jsonDecode(await File(speciesPath).readAsString()) as Map;
  final speciesFolder = Directory('$root/data/pokemon/species');
  await speciesFolder.create(recursive: true);
  for (var index = 0; index < 1145; index++) {
    final id = 'species-${index.toString().padLeft(4, '0')}';
    final species = jsonDecode(jsonEncode(template)) as Map;
    species['schemaVersion'] = 1;
    species['id'] = id;
    species['slug'] = id;
    species['nationalDex'] = index + 1;
    species['names'] = {'fr': 'Espèce $index', 'en': 'Species $index'};
    species['refs'] = {'learnset': '', 'evolution': '', 'media': ''};
    await File(
      '$root/data/pokemon/species/$id.json',
    ).writeAsString(jsonEncode(species));
  }
  final moves = File('$root/data/pokemon/catalogs/moves.json');
  await moves.parent.create(recursive: true);
  await moves.writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, dynamic>{},
      'entries': [
        for (var index = 0; index < 754; index++)
          {
            'id': 'move-${index.toString().padLeft(4, '0')}',
            'name': 'Move $index',
            'names': {'fr': 'Attaque ${index.toString().padLeft(4, '0')}'},
            'type': 'normal',
            'category': 'physical',
            'power': 40,
            'pp': 20,
            'effectText': 'Description source du catalogue.',
          },
      ],
    }),
  );
}

const speciesPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
