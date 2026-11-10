import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pokemon_authoring_fixture.dart';
import '../support/synthetic_pokemon_media.dart';

void main() {
  test('a form reads shared media without copying or changing it', () async {
    final host = await PokemonAuthoringFixture.create(
      prepareSource: (source) async {
        const sample =
            '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10';
        final root = '${source.directory.path}/data/pokemon';
        final base = jsonDecode(
          await File('$sample/species/0001-bulbasaur.json').readAsString(),
        ) as Map<String, dynamic>;
        base['schemaVersion'] = 1;
        (base['forms'] as Map)['otherForms'] = ['mega'];
        final form = jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
        form['id'] = 'bulbasaur-mega';
        form['slug'] = 'bulbasaur-mega';
        form['nationalDex'] = 2;
        form['names'] = {'fr': 'Méga-Bulbizarre'};
        form['forms'] = {
          'baseFormId': 'bulbasaur',
          'isBaseForm': false,
          'formId': 'mega',
          'otherForms': ['base'],
        };
        (form['refs'] as Map)['learnset'] = '';
        (form['refs'] as Map)['evolution'] = '';
        for (final (name, document) in [
          ('bulbasaur.json', base),
          ('bulbasaur-mega.json', form),
        ]) {
          final file = File('$root/species/$name');
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode(document));
        }
        final media = jsonDecode(
          await File('$sample/media/bulbasaur.json').readAsString(),
        ) as Map<String, dynamic>;
        media['schemaVersion'] = 1;
        (media['variants'] as Map)['mega'] = (media['variants'] as Map)['base'];
        final file = File('$root/media/bulbasaur.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(media));
        final icon = File(
          '${source.directory.path}/assets/pokemon/sprites/bulbasaur/icon.png',
        );
        await icon.parent.create(recursive: true);
        await icon.writeAsBytes(syntheticPokemonMediaPng());
      },
    );
    addTearDown(host.dispose);
    final media = File(
      '${host.source.directory.path}/data/pokemon/media/bulbasaur.json',
    );
    final before = await media.readAsBytes();
    expect(await host.workflow.requestSpecies('bulbasaur-mega'), isTrue);
    final adapter = LocalPokemonWorkspaceAdapter(
      session: host.source.session,
      mapAdapter: host.source.maps,
    );
    addTearDown(adapter.close);
    final entry = (await adapter.loadIndex()).entries.singleWhere(
      (value) => value.id == 'bulbasaur-mega',
    );
    final species = await adapter.loadSpecies(entry);
    final thumbnail = await adapter.loadThumbnail(entry);
    expect(species.media?.relativePath, 'data/pokemon/media/bulbasaur.json');
    expect(species.media?.document?['speciesId'], 'bulbasaur');
    expect(thumbnail, isNotNull);
    expect(await media.readAsBytes(), before);
    expect(
      await File(
        '${host.source.directory.path}/data/pokemon/media/bulbasaur-mega.json',
      ).exists(),
      isFalse,
    );
  });
}
