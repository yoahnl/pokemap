import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pokemon_external_source_fixture.dart';
import '../support/pokemon_authoring_fixture.dart';

void main() {
  test(
    'legacy companion is replaced at its existing identity and path',
    () async {
      final host = await PokemonAuthoringFixture.create(
        externalSource: const PokemonExternalSourceFixture(),
        prepareSource: (fixture) async {
          final species =
              jsonDecode(await File(speciesPath).readAsString()) as Map;
          species['schemaVersion'] = 1;
          (species['refs'] as Map)['learnset'] = 'custom-learn';
          final learnset =
              jsonDecode(await File(learnsetPath).readAsString()) as Map;
          learnset['schemaVersion'] = 1;
          learnset['speciesId'] = 'custom-learn';
          learnset['startingMoves'] = ['growl'];
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
      addTearDown(host.dispose);
      expect(await host.workflow.requestSpecies('bulbasaur'), isTrue);
      await _prepareExternal(host);
      final root = host.source.directory.path;
      final companion = File('$root/data/pokemon/learnsets/custom-learn.json');
      final before = await companion.readAsBytes();
      var confirmations = 0;
      expect(
        await host.workflow.applyExternal(
          PokemonExternalConflictPolicy.overwriteExisting,
          () async {
            confirmations++;
            expect(await companion.readAsBytes(), before);
            return true;
          },
        ),
        isTrue,
      );
      expect(confirmations, 1);
      final onDisk = jsonDecode(await companion.readAsString()) as Map;
      expect(onDisk['speciesId'], 'custom-learn');
      expect(onDisk['startingMoves'], contains('tackle'));
      expect(onDisk['startingMoves'], isNot(['growl']));
      final adapter = LocalPokemonWorkspaceAdapter(
        session: host.source.session,
        mapAdapter: host.source.maps,
      );
      addTearDown(adapter.close);
      final reopened = await adapter.loadSpecies(
        (await adapter.loadIndex()).entries.single,
      );
      expect(reopened.species.document!['refs']['learnset'], 'custom-learn');
      expect(reopened.learnset!.document!['speciesId'], 'custom-learn');
      expect(
        reopened.learnset!.document!['startingMoves'],
        onDisk['startingMoves'],
      );
      expect(
        reopened.learnset!.relativePath,
        'data/pokemon/learnsets/custom-learn.json',
      );
      expect(
        await File('$root/data/pokemon/learnsets/bulbasaur.json').exists(),
        isFalse,
      );
    },
  );

  test(
    'keeping a species with empty ref excludes unattached companion',
    () async {
      final host = await PokemonAuthoringFixture.create(
        externalSource: const PokemonExternalSourceFixture(),
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
      addTearDown(host.dispose);
      final root = host.source.directory.path;
      final speciesFile = File('$root/data/pokemon/species/bulbasaur.json');
      final before = await speciesFile.readAsBytes();
      await _prepareExternal(host);
      final plan = host.pokemon.externalPreview!.plan(
        PokemonExternalConflictPolicy.skipExisting,
      );
      expect(plan.selected, isEmpty);
      expect(plan.excluded, isNotEmpty);
      expect(
        await host.workflow.applyExternal(
          PokemonExternalConflictPolicy.skipExisting,
          () async =>
              throw StateError('Keeping files needs no overwrite decision.'),
        ),
        isTrue,
      );
      expect(await speciesFile.readAsBytes(), before);
      expect(
        await File('$root/data/pokemon/learnsets/bulbasaur.json').exists(),
        isFalse,
      );
      expect(host.pokemon.externalResult!.noChange, isTrue);
      expect(host.pokemon.externalResult!.excluded, plan.excluded.length);
    },
  );

  test(
    'a changed retained reference invalidates an external preview',
    () async {
      final host = await PokemonAuthoringFixture.create(
        externalSource: const PokemonExternalSourceFixture(),
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
      addTearDown(host.dispose);
      await _prepareExternal(host);
      final root = host.source.directory.path;
      final speciesFile = File('$root/data/pokemon/species/bulbasaur.json');
      final species = jsonDecode(await speciesFile.readAsString()) as Map;
      (species['refs'] as Map)['learnset'] = 'changed-learn';
      await speciesFile.writeAsString(jsonEncode(species));
      final changed = await speciesFile.readAsBytes();
      expect(
        await host.workflow.applyExternal(
          PokemonExternalConflictPolicy.skipExisting,
          () async =>
              throw StateError('Keeping files needs no overwrite decision.'),
        ),
        isFalse,
      );
      expect(host.pokemon.error, contains('Reprévisualisez'));
      expect(await speciesFile.readAsBytes(), changed);
      expect(
        await File('$root/data/pokemon/learnsets/custom-learn.json').exists(),
        isFalse,
      );
    },
  );
}

Future<void> _prepareExternal(PokemonAuthoringFixture host) async {
  expect(await host.pokemon.searchExternal('bulbasaur'), isTrue);
  expect(await host.pokemon.previewExternal('bulbasaur'), isTrue);
}

const speciesPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
const learnsetPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/learnsets/bulbasaur.json';
