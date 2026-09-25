import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets('large Pokédex scrolls locally at 150% text scale', (
    tester,
  ) async {
    await tester.runAsync(loadDesktopCaptureFonts);
    final captureKey = GlobalKey();
    final host = await MapHostFixture.open(
      tester,
      size: const Size(1024, 640),
      textScale: 1.5,
      captureKey: captureKey,
      prepareSource: (fixture) async {
        final template =
            jsonDecode(await File(fixturePath).readAsString())
                as Map<String, dynamic>;
        final folder = Directory(
          '${fixture.directory.path}/data/pokemon/species',
        );
        await folder.create(recursive: true);
        for (var index = 0; index < 260; index++) {
          final id = 'species-${index.toString().padLeft(3, '0')}';
          final species = jsonDecode(jsonEncode(template)) as Map;
          species['schemaVersion'] = 1;
          species['id'] = id;
          species['slug'] = id;
          species['nationalDex'] = index + 1;
          species['names'] = {'fr': 'Espèce $index', 'en': 'Species $index'};
          species['refs'] = {'learnset': '', 'evolution': '', 'media': ''};
          await File(
            '${folder.path}/$id.json',
          ).writeAsString(jsonEncode(species));
        }
        final moves = File(
          '${fixture.directory.path}/data/pokemon/catalogs/moves.json',
        );
        await moves.parent.create(recursive: true);
        await File(movesFixturePath).copy(moves.path);
      },
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    expect(find.text('Pokédex · 260 espèces'), findsOneWidget);
    await captureM3Widget(tester, captureKey, 'pokemon-petite-fenetre');
    final list = find.byKey(const PageStorageKey('pokemon-species-list'));
    expect(list, findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('species-species-259')),
      400,
      scrollable: find.descendant(of: list, matching: find.byType(Scrollable)),
      maxScrolls: 100,
    );
    expect(find.byKey(const ValueKey('species-species-259')), findsOneWidget);
    await tester.drag(list, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('species-species-259')));
    await pumpIo(tester);
    expect(find.text('Retour au Pokédex'), findsOneWidget);
    final name = find.byKey(const ValueKey('species-names.fr'));
    await tester.ensureVisible(name);
    await tester.enterText(name, 'Espèce finale');
    await tester.pump();
    await tester.tap(find.text('Enregistrer').first);
    await pumpIo(tester);
    final saved = (await tester.runAsync(() async {
      final file = File(
        '${host.source.directory.path}/data/pokemon/species/species-259.json',
      );
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    }))!;
    expect((saved['names'] as Map)['fr'], 'Espèce finale');
    await tester.tap(find.text('Attaques').first);
    await pumpIo(tester);
    final moves = find.byKey(const PageStorageKey('pokemon-moves-list'));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('move-leech-seed')),
      180,
      scrollable: find.descendant(of: moves, matching: find.byType(Scrollable)),
    );
    await tester.drag(moves, const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('move-leech-seed')));
    await pumpIo(tester);
    expect(find.text('Retour aux attaques'), findsOneWidget);
    await tester.tap(find.text('Retour aux attaques'));
    await pumpIo(tester);
    expect(find.byKey(const ValueKey('move-leech-seed')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const fixturePath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
const movesFixturePath =
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/moves.json';
