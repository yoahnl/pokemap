import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';

import '../support/map_host_fixture.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/m3_story_fixture.dart';
import '../support/pokemon_moves_source_fixture.dart';

void main() {
  testWidgets('Pokémon is a real workspace destination', (tester) async {
    final host = await MapHostFixture.open(tester);

    await host.go('Pokémon');

    expect(find.text('Pokédex'), findsWidgets);
    expect(find.text('Attaques'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('focused species and learnset edits survive independent reopen', (
    tester,
  ) async {
    await tester.runAsync(loadDesktopCaptureFonts);
    final captureKey = GlobalKey();
    final host = await MapHostFixture.open(
      tester,
      prepareSource: _seedSpecies,
      captureKey: captureKey,
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await captureM3Widget(tester, captureKey, 'pokemon-pokedex');
    expect(find.text('Bulbizarre'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
    await pumpIo(tester);
    await captureM3Widget(tester, captureKey, 'pokemon-fiche');
    final pokemon = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!;
    if (pokemon.selectedDraft == null) {
      fail(
        'selected=${pokemon.selectedId} loading=${pokemon.loading} error=${pokemon.error}',
      );
    }
    if (find.byKey(const ValueKey('species-names.fr')).evaluate().isEmpty) {
      fail(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((widget) => widget.data)
            .whereType<String>()
            .join(' | '),
      );
    }
    await tester.enterText(
      find.byKey(const ValueKey('species-names.fr')),
      'Bulbizarre du Train',
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
    final (species, learnset) = (await tester.runAsync(() async {
      final species =
          jsonDecode(
                await File(
                  '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      final learnset =
          jsonDecode(
                await File(
                  '${host.source.directory.path}/data/pokemon/learnsets/bulbasaur.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      return (species, learnset);
    }))!;
    expect((species['names'] as Map)['fr'], 'Bulbizarre du Train');
    expect((learnset['startingMoves'] as List).length, 3);
    final reopened = (await tester.runAsync(() async {
      final session = ProjectSession(
        sessionId: 'reopened-pokemon',
        name: host.source.session.name,
        directoryPath: host.source.directory.path,
      );
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadProject(session);
      final owner = LocalPokemonWorkspaceAdapter(
        session: session,
        mapAdapter: maps,
      );
      final entry = (await owner.loadIndex()).entries.single;
      return owner.loadSpecies(entry);
    }))!;
    expect(reopened.species.document!['id'], 'bulbasaur');
    expect(
      (reopened.species.document!['names'] as Map)['fr'],
      'Bulbizarre du Train',
    );
    expect(
      (reopened.learnset!.document!['startingMoves'] as List),
      contains('leech-seed'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'JSON preview does not write and apply reopens imported identity',
    (tester) async {
      final importRoot = (await tester.runAsync(() async {
        final directory = await Directory.systemTemp.createTemp(
          'avelune_pokemon_source_',
        );
        await _seedImportSource(directory);
        return directory;
      }))!;
      addTearDown(() async {
        if (await importRoot.exists()) await importRoot.delete(recursive: true);
      });
      final sourceFile = File('${importRoot.path}/species/0001-bulbasaur.json');
      final host = await MapHostFixture.open(
        tester,
        pokemonJsonPicker: () async => sourceFile.path,
      );
      final destination = File(
        '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
      );
      await host.go('Pokémon');
      await tester.tap(find.text('Importer un JSON'));
      await pumpIo(tester);
      expect(find.textContaining('Aperçu de l’import'), findsOneWidget);
      expect((await tester.runAsync(destination.exists))!, isFalse);
      await tester.tap(find.text('Importer bulbasaur'));
      await pumpIo(tester);
      expect((await tester.runAsync(destination.exists))!, isTrue);
      expect(find.text('Bulbizarre'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('menu PNG uses canonical import and preserves an existing role', (
    tester,
  ) async {
    const sourcePng =
        '../../examples/playable_runtime_host/golden_item_system/assets/pokemon/sprites/sproutle/front.png';
    final host = await MapHostFixture.open(
      tester,
      prepareSource: (source) async {
        await _seedSpecies(source);
        final media = File(
          '${source.directory.path}/data/pokemon/media/bulbasaur.json',
        );
        final data =
            jsonDecode(await media.readAsString()) as Map<String, dynamic>;
        ((data['variants'] as Map)['base'] as Map).remove('icon');
        await media.writeAsString(jsonEncode(data));
      },
      pokemonPngPicker: () async => sourcePng,
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
    await pumpIo(tester);
    await tester.tap(find.text('Médias').last);
    await pumpIo(tester);
    final importIcon = find.text('Importer PNG · icon');
    await tester.ensureVisible(importIcon);
    await tester.tap(importIcon);
    await pumpIo(tester);
    expect(find.textContaining('PNG associé'), findsOneWidget);
    final mediaPath =
        '${host.source.directory.path}/data/pokemon/media/bulbasaur.json';
    final icon = (await tester.runAsync(() async {
      final data = jsonDecode(await File(mediaPath).readAsString()) as Map;
      return ((data['variants'] as Map)['base'] as Map)['icon'] as String;
    }))!;
    expect(icon, startsWith('assets/pokemon/menu/bulbasaur/base/'));
    final thumbnail = (await tester.runAsync(() async {
      final adapter = LocalPokemonWorkspaceAdapter(
        session: host.source.session,
        mapAdapter: host.source.maps,
      );
      return adapter.loadThumbnail((await adapter.loadIndex()).entries.single);
    }))!;
    expect(thumbnail, isNotNull);
    await tester.ensureVisible(importIcon);
    await tester.tap(importIcon);
    await pumpIo(tester);
    expect(find.textContaining('déjà choisi est conservé'), findsOneWidget);
    final after = (await tester.runAsync(() async {
      final data = jsonDecode(await File(mediaPath).readAsString()) as Map;
      return ((data['variants'] as Map)['base'] as Map)['icon'] as String;
    }))!;
    expect(after, icon);
    expect(tester.takeException(), isNull);
  });

  testWidgets('moves preview is read only and apply writes merged catalog', (
    tester,
  ) async {
    await tester.runAsync(loadDesktopCaptureFonts);
    final captureKey = GlobalKey();
    final host = await MapHostFixture.open(
      tester,
      prepareSource: _seedSpecies,
      pokemonMovesSource: const PokemonMovesSourceFixture(),
      captureKey: captureKey,
    );
    final catalog = File(
      '${host.source.directory.path}/data/pokemon/catalogs/moves.json',
    );
    final before = (await tester.runAsync(catalog.readAsBytes))!;
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.text('Attaques').first);
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('move-leech-seed')));
    await pumpIo(tester);
    expect(find.text('Cible : Une cible'), findsOneWidget);
    await captureM3Widget(tester, captureKey, 'pokemon-attaques');
    await tester.tap(find.text('Prévisualiser la synchronisation'));
    await pumpIo(tester);
    expect(find.textContaining('créations'), findsOneWidget);
    expect((await tester.runAsync(catalog.readAsBytes))!, before);
    await tester.tap(find.text('Appliquer la synchronisation'));
    await pumpIo(tester);
    final ids = (await tester.runAsync(() async {
      final value = jsonDecode(await catalog.readAsString()) as Map;
      return (value['entries'] as List)
          .map((entry) => (entry as Map)['id'])
          .toSet();
    }))!;
    expect(ids, contains('thunderbolt'));
    expect(ids, contains('leech-seed'));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _seedImportSource(Directory root) async {
  const sourcePath =
      '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10';
  for (final (folder, file) in [
    ('species', '0001-bulbasaur.json'),
    ('learnsets', 'bulbasaur.json'),
    ('evolutions', 'bulbasaur.json'),
    ('media', 'bulbasaur.json'),
  ]) {
    final target = File('${root.path}/$folder/$file');
    await target.parent.create(recursive: true);
    final data =
        jsonDecode(await File('$sourcePath/$folder/$file').readAsString())
            as Map<String, dynamic>;
    data['schemaVersion'] = 1;
    await target.writeAsString(jsonEncode(data));
  }
}

Future<void> _seedSpecies(M3StoryFixture source) async {
  final root = source.directory.path;
  const sourcePath =
      '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10';
  for (final (folder, file) in [
    ('species', '0001-bulbasaur.json'),
    ('learnsets', 'bulbasaur.json'),
    ('evolutions', 'bulbasaur.json'),
    ('media', 'bulbasaur.json'),
  ]) {
    final target = File('$root/data/pokemon/$folder/$file');
    await target.parent.create(recursive: true);
    final data =
        jsonDecode(await File('$sourcePath/$folder/$file').readAsString())
            as Map<String, dynamic>;
    data['schemaVersion'] = 1;
    await target.writeAsString(jsonEncode(data));
  }
  final moves = File('$root/data/pokemon/catalogs/moves.json');
  await moves.parent.create(recursive: true);
  await File(
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/moves.json',
  ).copy(moves.path);
}
