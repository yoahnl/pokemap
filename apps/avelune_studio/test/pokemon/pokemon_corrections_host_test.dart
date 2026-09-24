import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/pokemon_external_source_fixture.dart';

void main() {
  testWidgets('ambiguous legacy companion leaves the species readable', (
    tester,
  ) async {
    final host = await MapHostFixture.open(
      tester,
      prepareSource: (fixture) async {
        final root = fixture.directory.path;
        final template =
            jsonDecode(await File(speciesPath).readAsString()) as Map;
        for (final id in ['bulbasaur', 'second']) {
          final species = jsonDecode(jsonEncode(template)) as Map;
          species['schemaVersion'] = 1;
          species['id'] = id;
          species['slug'] = id;
          (species['refs'] as Map)['learnset'] = 'shared-learn';
          final file = File('$root/data/pokemon/species/$id.json');
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode(species));
        }
        final learnset =
            jsonDecode(await File(learnsetPath).readAsString()) as Map;
        learnset['schemaVersion'] = 1;
        learnset['speciesId'] = 'shared-learn';
        final file = File('$root/data/pokemon/learnsets/shared-learn.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(learnset));
      },
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
    await pumpIo(tester);
    expect(find.text('Identité et description'), findsOneWidget);
    await tester.tap(find.text('Apprentissages'));
    await pumpIo(tester);
    expect(find.textContaining('sans propriétaire unique'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'legacy companion is replaced at its existing identity and path',
    (tester) async {
      await tester.runAsync(loadDesktopCaptureFonts);
      final captureKey = GlobalKey();
      final host = await MapHostFixture.open(
        tester,
        captureKey: captureKey,
        pokemonExternalSource: const PokemonExternalSourceFixture(),
        prepareSource: (fixture) async {
          final species =
              jsonDecode(await File(speciesPath).readAsString()) as Map;
          species['schemaVersion'] = 1;
          (species['refs'] as Map)['learnset'] = 'custom-learn';
          final learnset =
              jsonDecode(await File(learnsetPath).readAsString()) as Map;
          learnset['schemaVersion'] = 1;
          learnset['speciesId'] = 'custom-learn';
          final root = fixture.directory.path;
          final speciesFile = File('$root/data/pokemon/species/bulbasaur.json');
          final companion = File(
            '$root/data/pokemon/learnsets/custom-learn.json',
          );
          await speciesFile.parent.create(recursive: true);
          await companion.parent.create(recursive: true);
          await speciesFile.writeAsString(jsonEncode(species));
          await companion.writeAsString(jsonEncode(learnset));
        },
      );
      await host.go('Pokémon');
      await pumpIo(tester);
      await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
      await pumpIo(tester);
      expect(find.text('Apprentissages'), findsOneWidget);
      await _prepareExternal(tester);
      expect(find.textContaining('Aperçu ·'), findsOneWidget);
      await captureM3Widget(tester, captureKey, 'correction-06-import-legacy');
      await tester.tap(find.text('Refuser les conflits'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remplacer après confirmation').last);
      await tester.pump();
      await tester.tap(find.text('Appliquer l’import'));
      await tester.pump();
      await tester.tap(find.text('Remplacer').last);
      await pumpIo(tester);
      final root = host.source.directory.path;
      final adapter = LocalPokemonWorkspaceAdapter(
        session: host.source.session,
        mapAdapter: host.source.maps,
      );
      final entry = (await tester.runAsync(adapter.loadIndex))!.entries.single;
      final reopened = (await tester.runAsync(
        () => adapter.loadSpecies(entry),
      ))!;
      expect(reopened.species.document!['refs']['learnset'], 'custom-learn');
      expect(reopened.learnset!.document!['speciesId'], 'custom-learn');
      expect(
        reopened.learnset!.relativePath,
        'data/pokemon/learnsets/custom-learn.json',
      );
      expect(
        (await tester.runAsync(
          () => File('$root/data/pokemon/learnsets/bulbasaur.json').exists(),
        ))!,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keeping a species with empty ref excludes unattached companion',
    (tester) async {
      await tester.runAsync(loadDesktopCaptureFonts);
      final captureKey = GlobalKey();
      final host = await MapHostFixture.open(
        tester,
        captureKey: captureKey,
        pokemonExternalSource: const PokemonExternalSourceFixture(),
        prepareSource: (fixture) async {
          final species =
              jsonDecode(await File(speciesPath).readAsString()) as Map;
          species['schemaVersion'] = 1;
          (species['refs'] as Map)['learnset'] = '';
          (species['refs'] as Map)['evolution'] = '';
          final file = File(
            '${fixture.directory.path}/data/pokemon/species/bulbasaur.json',
          );
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode(species));
        },
      );
      final root = host.source.directory.path;
      final speciesFile = File('$root/data/pokemon/species/bulbasaur.json');
      final before = (await tester.runAsync(speciesFile.readAsBytes))!;
      await host.go('Pokémon');
      await pumpIo(tester);
      await _prepareExternal(tester);
      await tester.tap(find.text('Refuser les conflits'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garder les fichiers existants').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('exclu(s)'), findsWidgets);
      await captureM3Widget(tester, captureKey, 'correction-07-exclusion');
      await tester.tap(find.text('Terminer sans importer'));
      await pumpIo(tester);
      expect((await tester.runAsync(speciesFile.readAsBytes))!, before);
      expect(
        (await tester.runAsync(
          () => File('$root/data/pokemon/learnsets/bulbasaur.json').exists(),
        ))!,
        isFalse,
      );
      expect(find.textContaining('exclu(s) sans rattachement'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('a changed retained reference invalidates an external preview', (
    tester,
  ) async {
    final host = await MapHostFixture.open(
      tester,
      pokemonExternalSource: const PokemonExternalSourceFixture(),
      prepareSource: (fixture) async {
        final species =
            jsonDecode(await File(speciesPath).readAsString()) as Map;
        species['schemaVersion'] = 1;
        (species['refs'] as Map)['learnset'] = 'custom-learn';
        final file = File(
          '${fixture.directory.path}/data/pokemon/species/bulbasaur.json',
        );
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(species));
      },
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await _prepareExternal(tester);
    final root = host.source.directory.path;
    final speciesFile = File('$root/data/pokemon/species/bulbasaur.json');
    await tester.runAsync(() async {
      final species = jsonDecode(await speciesFile.readAsString()) as Map;
      (species['refs'] as Map)['learnset'] = 'changed-learn';
      await speciesFile.writeAsString(jsonEncode(species));
    });
    await tester.tap(find.text('Refuser les conflits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Garder les fichiers existants').last);
    await tester.pump();
    await tester.tap(find.text('Appliquer l’import'));
    await pumpIo(tester);
    expect(find.textContaining('Reprévisualisez'), findsWidgets);
    expect(
      (await tester.runAsync(
        () => File('$root/data/pokemon/learnsets/custom-learn.json').exists(),
      ))!,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _prepareExternal(WidgetTester tester) async {
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
  await pumpIo(tester);
  await tester.tap(find.textContaining('Bulbasaur · #1'));
  await pumpIo(tester);
}

const speciesPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
const learnsetPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/learnsets/bulbasaur.json';
