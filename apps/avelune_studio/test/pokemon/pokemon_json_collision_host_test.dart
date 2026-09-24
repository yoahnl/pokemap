import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets('overwriting selected species reloads its draft before editing', (
    tester,
  ) async {
    final source = (await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'avelune_pokemon_reimport_',
      );
      final file = File('${directory.path}/species/0001-bulbasaur.json');
      await file.parent.create(recursive: true);
      final json = jsonDecode(await File(fixturePath).readAsString()) as Map;
      json['schemaVersion'] = 1;
      (json['names'] as Map)['fr'] = 'Bulbizarre importé';
      await file.writeAsString(jsonEncode(json));
      return file;
    }))!;
    addTearDown(() async => source.parent.parent.delete(recursive: true));
    final host = await MapHostFixture.open(
      tester,
      prepareSource: (fixture) async {
        final destination = File(
          '${fixture.directory.path}/data/pokemon/species/0001-bulbasaur.json',
        );
        await destination.parent.create(recursive: true);
        final json = jsonDecode(await File(fixturePath).readAsString()) as Map;
        json['schemaVersion'] = 1;
        await destination.writeAsString(jsonEncode(json));
      },
      pokemonJsonPicker: () async => source.path,
    );
    final destination = File(
      '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
    await pumpIo(tester);
    await tester.tap(find.text('Importer un JSON'));
    await pumpIo(tester);
    await tester.tap(find.text('Importer bulbasaur'));
    await pumpIo(tester);
    await tester.tap(find.text('Confirmer le remplacement'));
    await pumpIo(tester);
    expect(find.text('Bulbizarre importé'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('species-names.fr')),
      'Bulbizarre après import',
    );
    await tester.pump();
    await tester.tap(find.text('Enregistrer').first);
    await pumpIo(tester);
    final saved = (await tester.runAsync(() async {
      return jsonDecode(await destination.readAsString()) as Map;
    }))!;
    expect((saved['names'] as Map)['fr'], 'Bulbizarre après import');
    expect(tester.takeException(), isNull);
  });

  testWidgets('JSON import does not replace a different species by filename', (
    tester,
  ) async {
    const fixture =
        '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
    final source = (await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'avelune_pokemon_collision_',
      );
      final file = File('${directory.path}/0001-bulbasaur.json');
      final json = jsonDecode(await File(fixture).readAsString()) as Map;
      json['schemaVersion'] = 1;
      json['id'] = 'ivysaur';
      json['slug'] = 'ivysaur';
      await file.writeAsString(jsonEncode(json));
      return file;
    }))!;
    addTearDown(() async => source.parent.delete(recursive: true));
    final host = await MapHostFixture.open(
      tester,
      prepareSource: (fixture) async {
        final destination = File(
          '${fixture.directory.path}/data/pokemon/species/0001-bulbasaur.json',
        );
        await destination.parent.create(recursive: true);
        final json = jsonDecode(await File(fixturePath).readAsString()) as Map;
        json['schemaVersion'] = 1;
        await destination.writeAsString(jsonEncode(json));
      },
      pokemonJsonPicker: () async => source.path,
    );
    final destination = File(
      '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
    );
    final before = (await tester.runAsync(destination.readAsBytes))!;
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.text('Importer un JSON'));
    await pumpIo(tester);
    expect(find.textContaining('appartient déjà'), findsWidgets);
    expect((await tester.runAsync(destination.readAsBytes))!, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid companion rejects JSON preview before writing', (
    tester,
  ) async {
    final source = (await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'avelune_pokemon_invalid_companion_',
      );
      final species = File('${directory.path}/species/0001-bulbasaur.json');
      final learnset = File('${directory.path}/learnsets/bulbasaur.json');
      await species.parent.create(recursive: true);
      await learnset.parent.create(recursive: true);
      final json = jsonDecode(await File(fixturePath).readAsString()) as Map;
      json['schemaVersion'] = 1;
      await species.writeAsString(jsonEncode(json));
      await learnset.writeAsString('{bad json');
      return species;
    }))!;
    addTearDown(() async => source.parent.parent.delete(recursive: true));
    final host = await MapHostFixture.open(
      tester,
      pokemonJsonPicker: () async => source.path,
    );
    final destination = File(
      '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.text('Importer un JSON'));
    await pumpIo(tester);
    expect(find.textContaining('Import JSON refusé'), findsWidgets);
    expect((await tester.runAsync(destination.exists))!, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('JSON import refuses a companion owned by another species', (
    tester,
  ) async {
    final source = (await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'avelune_pokemon_companion_collision_',
      );
      final species = File('${directory.path}/species/0001-bulbasaur.json');
      final learnset = File('${directory.path}/learnsets/bulbasaur.json');
      await species.parent.create(recursive: true);
      await learnset.parent.create(recursive: true);
      final speciesJson =
          jsonDecode(await File(fixturePath).readAsString()) as Map;
      speciesJson['schemaVersion'] = 1;
      await species.writeAsString(jsonEncode(speciesJson));
      final learnsetJson =
          jsonDecode(await File(learnsetPath).readAsString()) as Map;
      learnsetJson['schemaVersion'] = 1;
      await learnset.writeAsString(jsonEncode(learnsetJson));
      return species;
    }))!;
    addTearDown(() async => source.parent.parent.delete(recursive: true));
    final host = await MapHostFixture.open(
      tester,
      prepareSource: (fixture) async {
        final file = File(
          '${fixture.directory.path}/data/pokemon/learnsets/bulbasaur.json',
        );
        await file.parent.create(recursive: true);
        final json = jsonDecode(await File(learnsetPath).readAsString()) as Map;
        json['schemaVersion'] = 1;
        json['speciesId'] = 'ivysaur';
        await file.writeAsString(jsonEncode(json));
      },
      pokemonJsonPicker: () async => source.path,
    );
    final companion = File(
      '${host.source.directory.path}/data/pokemon/learnsets/bulbasaur.json',
    );
    final destination = File(
      '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
    );
    final before = (await tester.runAsync(companion.readAsBytes))!;
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.text('Importer un JSON'));
    await pumpIo(tester);
    expect(find.textContaining('appartient déjà'), findsWidgets);
    expect((await tester.runAsync(companion.readAsBytes))!, before);
    expect((await tester.runAsync(destination.exists))!, isFalse);
    expect(tester.takeException(), isNull);
  });
}

const fixturePath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
const learnsetPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/learnsets/bulbasaur.json';
