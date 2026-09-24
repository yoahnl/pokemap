import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/pokemon_external_source_fixture.dart';

void main() {
  testWidgets(
    'external search previews without writing and imports in Studio',
    (tester) async {
      await tester.runAsync(loadDesktopCaptureFonts);
      final captureKey = GlobalKey();
      final host = await MapHostFixture.open(
        tester,
        pokemonExternalSource: const PokemonExternalSourceFixture(),
        captureKey: captureKey,
      );
      final file = File(
        '${host.source.directory.path}/data/pokemon/species/bulbasaur.json',
      );
      final project = File('${host.source.directory.path}/project.json');
      final projectBefore = (await tester.runAsync(project.readAsBytes))!;
      await host.go('Pokémon');
      await pumpIo(tester);
      await tester.tap(find.text('Importer depuis une source'));
      await pumpIo(tester);
      expect(find.text('Importer une espèce externe'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('pokemon-external-query')),
          matching: find.byType(TextField),
        ),
        'bulbasaur',
      );
      await tester.pump();
      final searchButton = tester.widget<StudioButton>(
        find.ancestor(
          of: find.text('Rechercher'),
          matching: find.byType(StudioButton),
        ),
      );
      expect(searchButton.onPressed, isNotNull);
      await tester.tap(find.text('Rechercher'));
      await pumpIo(tester);
      final state = tester
          .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
          .controller!;
      expect(
        state.externalSearch,
        isNotNull,
        reason: 'query=${state.externalBusy}, error=${state.error}',
      );
      expect(
        find.textContaining('Bulbasaur · #1'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((item) => item.data)
            .whereType<String>()
            .join(' | '),
      );
      await captureM3Widget(tester, captureKey, 'pokemon-08-recherche-externe');
      await tester.tap(find.textContaining('Bulbasaur · #1'));
      await pumpIo(tester);
      expect(find.textContaining('Aperçu ·'), findsOneWidget);
      await captureM3Widget(tester, captureKey, 'pokemon-import-externe');
      expect((await tester.runAsync(file.exists))!, isFalse);
      expect((await tester.runAsync(project.readAsBytes))!, projectBefore);
      await tester.tap(find.text('Appliquer l’import'));
      await pumpIo(tester);
      expect((await tester.runAsync(file.exists))!, isTrue);
      final reopened = (await tester.runAsync(() async {
        final adapter = LocalPokemonWorkspaceAdapter(
          session: host.source.session,
          mapAdapter: host.source.maps,
        );
        final entry = (await adapter.loadIndex()).entries.single;
        return adapter.loadSpecies(entry);
      }))!;
      expect(reopened.species.document!['id'], 'bulbasaur');
      expect(reopened.learnset?.document?['speciesId'], 'bulbasaur');
      final importedBytes = (await tester.runAsync(file.readAsBytes))!;
      await tester.tap(find.text('Importer depuis une source'));
      await pumpIo(tester);
      await tester.tap(find.textContaining('Bulbasaur · #1'));
      await pumpIo(tester);
      expect(find.textContaining('existe déjà'), findsWidgets);
      await captureM3Widget(tester, captureKey, 'pokemon-09-conflits-externes');
      expect(find.text('Appliquer l’import'), findsOneWidget);
      await tester.tap(find.text('Refuser les conflits'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garder les fichiers existants').last);
      await tester.pump();
      await tester.tap(find.text('Appliquer l’import'));
      await pumpIo(tester);
      expect((await tester.runAsync(file.readAsBytes))!, importedBytes);
      expect(find.textContaining('conservé(s)'), findsWidgets);
      await tester.tap(find.text('Importer depuis une source'));
      await pumpIo(tester);
      await tester.tap(find.textContaining('Bulbasaur · #1'));
      await pumpIo(tester);
      final changedBytes = (await tester.runAsync(() async {
        await file.writeAsBytes([...importedBytes, 32]);
        return file.readAsBytes();
      }))!;
      await tester.tap(find.text('Refuser les conflits'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remplacer après confirmation').last);
      await tester.pump();
      await tester.tap(find.text('Appliquer l’import'));
      await tester.pump();
      await tester.tap(find.text('Remplacer').last);
      await pumpIo(tester);
      expect(find.textContaining('Reprévisualisez'), findsWidgets);
      expect((await tester.runAsync(file.readAsBytes))!, changedBytes);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('external network error preserves local project', (tester) async {
    final host = await MapHostFixture.open(
      tester,
      pokemonExternalSource: const PokemonExternalSourceFixture(
        networkFailure: true,
      ),
    );
    final project = File('${host.source.directory.path}/project.json');
    final before = (await tester.runAsync(project.readAsBytes))!;
    await host.go('Pokémon');
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
    final searchButton = tester.widget<StudioButton>(
      find.ancestor(
        of: find.text('Rechercher'),
        matching: find.byType(StudioButton),
      ),
    );
    expect(searchButton.onPressed, isNotNull);
    await tester.tap(find.text('Rechercher'));
    await pumpIo(tester);
    final state = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!;
    expect(
      state.externalSearch,
      isNotNull,
      reason: 'query=${state.externalBusy}, error=${state.error}',
    );
    expect(
      find.textContaining('indisponible'),
      findsWidgets,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((item) => item.data)
          .whereType<String>()
          .join(' | '),
    );
    expect((await tester.runAsync(project.readAsBytes))!, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('external preview refuses a companion owned by another species', (
    tester,
  ) async {
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
      pokemonExternalSource: const PokemonExternalSourceFixture(),
    );
    final companion = File(
      '${host.source.directory.path}/data/pokemon/learnsets/bulbasaur.json',
    );
    final destination = File(
      '${host.source.directory.path}/data/pokemon/species/bulbasaur.json',
    );
    final before = (await tester.runAsync(companion.readAsBytes))!;
    await host.go('Pokémon');
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
    await pumpIo(tester);
    await tester.tap(find.textContaining('Bulbasaur · #1'));
    await pumpIo(tester);
    expect(find.textContaining('appartient déjà'), findsWidgets);
    expect((await tester.runAsync(companion.readAsBytes))!, before);
    expect((await tester.runAsync(destination.exists))!, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('external import attaches companions to empty references', (
    tester,
  ) async {
    final host = await MapHostFixture.open(
      tester,
      prepareSource: (fixture) async {
        final file = File(
          '${fixture.directory.path}/data/pokemon/species/bulbasaur.json',
        );
        await file.parent.create(recursive: true);
        final json = jsonDecode(await File(speciesPath).readAsString()) as Map;
        json['schemaVersion'] = 1;
        final refs = json['refs'] as Map;
        refs['learnset'] = '';
        refs['evolution'] = '';
        await file.writeAsString(jsonEncode(json));
      },
      pokemonExternalSource: const PokemonExternalSourceFixture(),
    );
    await host.go('Pokémon');
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
    await pumpIo(tester);
    await tester.tap(find.textContaining('Bulbasaur · #1'));
    await pumpIo(tester);
    await tester.tap(find.text('Refuser les conflits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remplacer après confirmation').last);
    await tester.pump();
    await tester.tap(find.text('Appliquer l’import'));
    await tester.pump();
    await tester.tap(find.text('Remplacer').last);
    await pumpIo(tester);
    final root = host.source.directory.path;
    final saved = (await tester.runAsync(() async {
      return jsonDecode(
            await File(
              '$root/data/pokemon/species/bulbasaur.json',
            ).readAsString(),
          )
          as Map;
    }))!;
    final refs = saved['refs'] as Map;
    expect(refs['learnset'], 'bulbasaur');
    expect(
      (await tester.runAsync(
        () => File('$root/data/pokemon/learnsets/bulbasaur.json').exists(),
      ))!,
      isTrue,
    );
    expect(
      (await tester.runAsync(
        () => File('$root/data/pokemon/learnsets/.json').exists(),
      ))!,
      isFalse,
    );
  });
}

const learnsetPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/learnsets/bulbasaur.json';
const speciesPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
