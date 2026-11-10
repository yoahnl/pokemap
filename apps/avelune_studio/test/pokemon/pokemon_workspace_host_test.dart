import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_media_editing_session.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
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
import '../support/pokemon_authoring_fixture.dart';

void main() {
  testWidgets('Pokémon is a real workspace destination', (tester) async {
    final host = await MapHostFixture.open(tester);

    await host.go('Pokémon');

    expect(find.text('Pokédex'), findsWidgets);
    expect(find.text('Attaques'), findsWidgets);
    expect(find.text('Importer un JSON'), findsNothing);
    expect(find.text('Importer depuis une source'), findsNothing);
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
    expect(find.text('Médias'), findsNothing);
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
    await captureM3Widget(tester, captureKey, 'pokemon-fiche-brouillon');
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
      final species = jsonDecode(
        await File(
          '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
        ).readAsString(),
      ) as Map<String, dynamic>;
      final learnset = jsonDecode(
        await File(
          '${host.source.directory.path}/data/pokemon/learnsets/bulbasaur.json',
        ).readAsString(),
      ) as Map<String, dynamic>;
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

  test('JSON preview does not write and apply reopens imported identity', () async {
    final host = await PokemonAuthoringFixture.create();
    addTearDown(host.dispose);
    final importRoot = Directory('${host.source.directory.path}/incoming');
    await _seedImportSource(importRoot);
    final sourceFile = File('${importRoot.path}/species/0001-bulbasaur.json');
    final destination = File(
      '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
    );
    final project = File('${host.source.directory.path}/project.json');
    final projectBefore = await project.readAsBytes();
    expect(await host.workflow.pickJson(() async => sourceFile.path), isTrue);
    expect(host.pokemon.importPreview!.speciesId, 'bulbasaur');
    expect(await destination.exists(), isFalse);
    expect(await project.readAsBytes(), projectBefore);
    expect(
      await host.workflow.applyJsonImport(() async {
        throw StateError('New content needs no overwrite decision.');
      }),
      isTrue,
    );
    expect(await destination.exists(), isTrue);
    expect(host.pokemon.selectedId, 'bulbasaur');
    expect(host.pokemon.selectedDraft!.id, 'bulbasaur');
    expect(host.pokemon.importPreview, isNull);
    final owner = LocalPokemonWorkspaceAdapter(
      session: host.source.session,
      mapAdapter: host.source.maps,
    );
    addTearDown(owner.close);
    final reopened = await owner.loadSpecies(
      (await owner.loadIndex()).entries.single,
    );
    expect(reopened.species.document!['id'], 'bulbasaur');
    expect(reopened.learnset!.document!['speciesId'], 'bulbasaur');
  });

  test('menu PNG uses canonical import and preserves an existing role', () async {
    const sourcePng =
        '../../examples/playable_runtime_host/golden_item_system/assets/pokemon/sprites/sproutle/front.png';
    final host = await PokemonAuthoringFixture.create(
      prepareSource: (source) async {
        await _seedSpecies(source);
        final media = File(
          '${source.directory.path}/data/pokemon/media/bulbasaur.json',
        );
        final data = jsonDecode(await media.readAsString()) as Map;
        ((data['variants'] as Map)['base'] as Map).remove('icon');
        await media.writeAsString(jsonEncode(data));
      },
    );
    addTearDown(host.dispose);
    expect(await host.workflow.requestSpecies('bulbasaur'), isTrue);
    final session = PokemonMediaEditingSession(current: () => host.pokemon);
    addTearDown(session.dispose);
    expect(session.canImportPng, isTrue);
    expect(
      await session.choosePng(() async => File(sourcePng).absolute.path),
      isTrue,
    );
    expect(host.pokemon.notice, contains('PNG associé'));
    final media = File(
      '${host.source.directory.path}/data/pokemon/media/bulbasaur.json',
    );
    final saved = jsonDecode(await media.readAsString()) as Map;
    final icon = ((saved['variants'] as Map)['base'] as Map)['icon'] as String;
    expect(icon, startsWith('assets/pokemon/menu/bulbasaur/base/'));
    expect(session.path, icon);
    expect(await session.probeRole('icon'), PokemonMediaFileStatus.present);
    final adapter = LocalPokemonWorkspaceAdapter(
      session: host.source.session,
      mapAdapter: host.source.maps,
    );
    addTearDown(adapter.close);
    final entry = (await adapter.loadIndex()).entries.single;
    expect(await adapter.loadThumbnail(entry), isNotNull);
    final reopened = await adapter.loadSpecies(entry);
    expect(reopened.media!.document!['variants']['base']['icon'], icon);
    final before = await media.readAsBytes();
    var replacementPicks = 0;
    expect(session.canImportPng, isFalse);
    expect(
      await session.choosePng(() async {
        replacementPicks++;
        return File(sourcePng).absolute.path;
      }),
      isFalse,
    );
    expect(replacementPicks, 0);
    expect(await media.readAsBytes(), before);
    expect(session.path, icon);
  });

  test('clearing a missing role and saving allows a canonical PNG import', () async {
    const sourcePng =
        '../../examples/playable_runtime_host/golden_item_system/assets/pokemon/sprites/sproutle/front.png';
    final host = await PokemonAuthoringFixture.create(
      prepareSource: _seedSpecies,
    );
    addTearDown(host.dispose);
    expect(await host.workflow.requestSpecies('bulbasaur'), isTrue);
    final session = PokemonMediaEditingSession(current: () => host.pokemon);
    addTearDown(session.dispose);
    final missing = session.path;
    expect(missing, isNotEmpty);
    expect(await session.probeRole('icon'), PokemonMediaFileStatus.missing);
    expect(session.canImportPng, isFalse);
    session.setPath('');
    expect(host.pokemon.hasPendingChanges, isTrue);
    var picksBeforeSave = 0;
    expect(
      await session.choosePng(() async {
        picksBeforeSave++;
        return File(sourcePng).absolute.path;
      }),
      isFalse,
    );
    expect(picksBeforeSave, 0);
    expect(await host.pokemon.saveActiveOwner(), isTrue);
    expect(session.canImportPng, isTrue);
    expect(
      await session.choosePng(() async => File(sourcePng).absolute.path),
      isTrue,
    );
    expect(
      host.pokemon.notice,
      contains('PNG associé à la forme base pour le rôle Icône'),
    );
    final media = File(
      '${host.source.directory.path}/data/pokemon/media/bulbasaur.json',
    );
    final saved = jsonDecode(await media.readAsString()) as Map;
    final icon = ((saved['variants'] as Map)['base'] as Map)['icon'] as String;
    expect(icon, startsWith('assets/pokemon/menu/bulbasaur/base/'));
    expect(icon, isNot(missing));
    expect(await session.probeRole('icon'), PokemonMediaFileStatus.present);
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
    expect(find.text('Cible'), findsOneWidget);
    expect(find.text('Une cible'), findsOneWidget);
    await captureM3Widget(tester, captureKey, 'pokemon-attaques');
    await tester.tap(find.text('Préparer la synchronisation'));
    await pumpIo(tester);
    await tester.tap(find.text('Prévisualiser la synchronisation'));
    await pumpIo(tester);
    expect(find.textContaining('créations'), findsOneWidget);
    await captureM3Widget(tester, captureKey, 'pokemon-10-synchronisation');
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
  await _copySpeciesDocuments(root, '');
}

Future<void> _seedSpecies(M3StoryFixture source) async {
  final root = source.directory.path;
  await _copySpeciesDocuments(source.directory, 'data/pokemon/');
  final moves = File('$root/data/pokemon/catalogs/moves.json');
  await moves.parent.create(recursive: true);
  await File(
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/moves.json',
  ).copy(moves.path);
}

Future<void> _copySpeciesDocuments(Directory root, String prefix) async {
  const sourcePath =
      '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10';
  for (final (folder, file) in [
    ('species', '0001-bulbasaur.json'),
    ('learnsets', 'bulbasaur.json'),
    ('evolutions', 'bulbasaur.json'),
    ('media', 'bulbasaur.json'),
  ]) {
    final target = File('${root.path}/$prefix$folder/$file');
    await target.parent.create(recursive: true);
    final data = jsonDecode(
      await File('$sourcePath/$folder/$file').readAsString(),
    ) as Map<String, dynamic>;
    data['schemaVersion'] = 1;
    await target.writeAsString(jsonEncode(data));
  }
}
