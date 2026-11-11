import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_media_editing_session.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/m3_story_fixture.dart';
import '../support/pokemon_authoring_fixture.dart';

void main() {
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
