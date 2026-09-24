import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/presentation/features/pokemon/pokemon_media_preview.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/m3_story_fixture.dart';
import '../support/map_host_fixture.dart';
import '../support/pokemon_external_source_fixture.dart';

void main() {
  testWidgets('Lot A surfaces use the real workspace and local media', (
    tester,
  ) async {
    await tester.runAsync(loadDesktopCaptureFonts);
    final captureKey = GlobalKey();
    final host = await MapHostFixture.open(
      tester,
      prepareSource: _seedVisualProject,
      captureKey: captureKey,
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    expect(find.text('Pokédex · 3 espèces'), findsOneWidget);
    await captureM3Widget(tester, captureKey, 'pokemon-01-bibliotheque');

    await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
    await pumpIo(tester);
    expect(find.text('Bulbizarre'), findsWidgets);
    await captureM3Widget(tester, captureKey, 'pokemon-02-vue-ensemble');

    for (final (tab, screenshot) in [
      ('Formes', 'pokemon-03-formes'),
      ('Apprentissages', 'pokemon-04-apprentissages'),
      ('Évolutions', 'pokemon-05-evolutions'),
      ('Médias', 'pokemon-06-medias'),
    ]) {
      await tester.tap(find.text(tab).last);
      await pumpIo(tester);
      if (tab == 'Médias') {
        expect(find.byType(PokemonMediaPreview), findsOneWidget);
      }
      await captureM3Widget(tester, captureKey, screenshot);
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(
      find.byKey(const ValueKey('media-role-overworld')),
    );
    await tester.tap(find.byKey(const ValueKey('media-role-overworld')));
    await pumpIo(tester);
    await captureM3Widget(tester, captureKey, 'pokemon-06-media-absent');

    await tester.tap(find.text('Attaques').first);
    await pumpIo(tester);
    await captureM3Widget(tester, captureKey, 'pokemon-10-attaques');
    expect(find.text('Vampigraine'), findsWidgets);
    expect(find.text('Brasier personnel'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('move-brasier-personnel')));
    await pumpIo(tester);
    await captureM3Widget(tester, captureKey, 'pokemon-10-attaque-personnelle');
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Attack and import views keep essential actions', (
    tester,
  ) async {
    await tester.runAsync(loadDesktopCaptureFonts);
    final captureKey = GlobalKey();
    final host = await MapHostFixture.open(
      tester,
      size: const Size(1024, 640),
      textScale: 1.5,
      prepareSource: _seedVisualProject,
      pokemonExternalSource: const PokemonExternalSourceFixture(),
      captureKey: captureKey,
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.text('Attaques').first);
    await pumpIo(tester);
    expect(find.text('Synchronisation'), findsOneWidget);
    await captureM3Widget(tester, captureKey, 'pokemon-compact-attaques-150');
    await tester.tap(find.text('Pokédex').first);
    await pumpIo(tester);
    await tester.tap(find.text('Importer depuis une source'));
    await pumpIo(tester);
    expect(find.text('Rechercher'), findsOneWidget);
    await captureM3Widget(tester, captureKey, 'pokemon-compact-import-150');
    expect(tester.takeException(), isNull);
  });

  testWidgets('200% text keeps focused save reachable', (tester) async {
    await tester.runAsync(loadDesktopCaptureFonts);
    final captureKey = GlobalKey();
    final host = await MapHostFixture.open(
      tester,
      size: const Size(1024, 640),
      textScale: 2,
      prepareSource: _seedVisualProject,
      captureKey: captureKey,
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
    await pumpIo(tester);
    final field = find.byKey(const ValueKey('species-names.fr'));
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Bulbizarre accessible');
    await tester.pumpAndSettle();
    final save = find.ancestor(
      of: find.text('Enregistrer').first,
      matching: find.byType(StudioButton),
    );
    expect(tester.widget<StudioButton>(save).onPressed, isNotNull);
    await captureM3Widget(tester, captureKey, 'pokemon-compact-fiche-200');
    await tester.tap(save);
    await pumpIo(tester);
    expect(find.text('Enregistré'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _seedVisualProject(M3StoryFixture fixture) async {
  const sample =
      '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10';
  const assets = '../../selbrume/assets/pokemon';
  final root = fixture.directory.path;
  for (final (speciesFile, id) in [
    ('0001-bulbasaur', 'bulbasaur'),
    ('0004-charmander', 'charmander'),
    ('0007-squirtle', 'squirtle'),
  ]) {
    for (final (family, file) in [
      ('species', '$speciesFile.json'),
      ('learnsets', '$id.json'),
      ('evolutions', '$id.json'),
      ('media', '$id.json'),
    ]) {
      final data =
          jsonDecode(await File('$sample/$family/$file').readAsString())
              as Map<String, dynamic>;
      data['schemaVersion'] = 1;
      final destination = File('$root/data/pokemon/$family/$file');
      await destination.parent.create(recursive: true);
      await destination.writeAsString(jsonEncode(data));
    }
    for (final (source, destination) in [
      ('sprites/$id/front.png', 'sprites/$id/front.png'),
      ('sprites/$id/back.png', 'sprites/$id/back.png'),
      ('sprites/$id/front_shiny.png', 'sprites/$id/front_shiny.png'),
      ('sprites/$id/back_shiny.png', 'sprites/$id/back_shiny.png'),
      ('sprites/$id/front.png', 'sprites/$id/icon.png'),
      ('sprites/$id/front.png', 'sprites/$id/party.png'),
      ('portraits/$id.png', 'portraits/$id.png'),
      ('cries/$id.ogg', 'cries/$id.ogg'),
    ]) {
      final target = File('$root/assets/pokemon/$destination');
      await target.parent.create(recursive: true);
      await File('$assets/$source').copy(target.path);
    }
  }
  final moves = File('$root/data/pokemon/catalogs/moves.json');
  await moves.parent.create(recursive: true);
  await File(
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/moves.json',
  ).copy(moves.path);
  final catalog = jsonDecode(await moves.readAsString()) as Map;
  (catalog['entries'] as List).add({
    'id': 'brasier-personnel',
    'name': 'Personal Blaze',
    'names': {'fr': 'Brasier personnel'},
    'source': 'project_custom',
    'type': 'fire',
    'category': 'special',
    'power': 120,
    'pp': 10,
  });
  await moves.writeAsString(jsonEncode(catalog));
}
