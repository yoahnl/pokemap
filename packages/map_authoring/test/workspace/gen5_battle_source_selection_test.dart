import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_project_reader.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_workshop_selection.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('selects only the species and the two MCSS storage units', () async {
    final root = await Directory.systemTemp.createTemp('gen5-selection-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final project = ProjectManifest(
      name: 'Synthetic',
      maps: const [],
      tilesets: const [],
      pokemon: const ProjectPokemonConfig(
          enabled: true, ruleset: PokemonRulesetProfile.pokeMapBetaV1),
    );
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
      store: store,
      projectId: 'gen5-selection',
      project: project,
    );
    addTearDown(working.close);
    const speciesPath = 'data/pokemon/species/alternate-filename.json';
    final file = File('${root.path}/$speciesPath');
    await file.parent.create(recursive: true);
    final speciesBytes = utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'id': 'local-mon',
      'nationalDex': 25,
    }));
    await file.writeAsBytes(speciesBytes);
    await File('${file.parent.path}/unrelated.json')
        .writeAsString('{malformed');
    final bundle = Gen5BattleSourceBundle(
      species: 'syntheticmon',
      nationalDex: 25,
      release: 'synthetic-release',
      sourceRepository: 'fuddlesworth/pokebw2',
      sourceRevision: 'a' * 40,
      sourceDirectory: 'res/pokemon/syntheticmon',
      reconstruction: 'unverified',
      redistributionStatus: 'unverified',
      assets: {
        for (var i = 0; i < gen5BattleBundleAssetNames.length; i++)
          gen5BattleBundleAssetNames[i]: Uint8List.fromList([i + 1]),
      },
    );
    final binding = Gen5BattleSourceBinding.fromBundle(
      projectSpeciesId: 'local-mon',
      projectNationalDex: 25,
      bundle: bundle,
    );
    final descriptor =
        jsonDecode(await File('${root.path}/project.json').readAsString())
            as Map<String, dynamic>;
    final reader = (await CatalogProjectReader.open(
      store: store,
      descriptor: descriptor,
      metadataFields: const {},
    ))!;
    final selection = await CatalogWorkshopSelection.read(
      reader: reader,
      projectHandle: const ProjectHandle('project'),
      actionId: 'pokemon.gen5_battle_source.import',
      parameters: {
        'binding': jsonDecode(utf8.decode(binding.encode())),
        'bundleHandle': 'artifact',
        'speciesPath': speciesPath,
      },
    );
    expect(selection.resourceRevisions.keys.toSet(),
        {speciesPath, binding.bindingPath, binding.bundlePath});
    expect(
        selection.snapshot
            .findResourceBytes(pokemonSpeciesResourceIdentity('local-mon')),
        speciesBytes);
    expect(
        selection.snapshot
            .resourceStorageKeys[pokemonSpeciesResourceIdentity('local-mon')],
        speciesPath);
    expect(selection.resourceRevisions[binding.bindingPath], isNull);
    expect(selection.resourceRevisions[binding.bundlePath], isNull);
    await file
        .writeAsString('{"schemaVersion":1,"id":"local-mon","nationalDex":26}');
    await expectLater(
        selection.requireCurrent(),
        throwsA(isA<AuthoringPlanException>()
            .having((error) => error.code, 'code', 'plan.stale')));
  });
}
