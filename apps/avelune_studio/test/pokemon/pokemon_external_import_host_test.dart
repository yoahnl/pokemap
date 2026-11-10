import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pokemon_authoring_fixture.dart';
import '../support/pokemon_external_source_fixture.dart';

void main() {
  test(
    'external search previews without writing and imports through workflow',
    () async {
      final host = await PokemonAuthoringFixture.create(
        externalSource: const PokemonExternalSourceFixture(),
      );
      addTearDown(host.dispose);
      final controller = host.pokemon;
      final file = File(
        '${host.source.directory.path}/data/pokemon/species/bulbasaur.json',
      );
      final project = File('${host.source.directory.path}/project.json');
      final projectBefore = await project.readAsBytes();
      expect(await controller.searchExternal('bulbasaur'), isTrue);
      expect(controller.externalSearch!.suggestions.single.id, 'bulbasaur');
      expect(await controller.previewExternal('bulbasaur'), isTrue);
      expect(controller.externalPreview!.speciesId, 'bulbasaur');
      expect(await file.exists(), isFalse);
      expect(await project.readAsBytes(), projectBefore);
      expect(
        await host.workflow.applyExternal(
          PokemonExternalConflictPolicy.failOnConflict,
          () async =>
              throw StateError('New content needs no overwrite decision.'),
        ),
        isTrue,
      );
      expect(await file.exists(), isTrue);
      final adapter = LocalPokemonWorkspaceAdapter(
        session: host.source.session,
        mapAdapter: host.source.maps,
      );
      addTearDown(adapter.close);
      final reopened = await adapter.loadSpecies(
        (await adapter.loadIndex()).entries.single,
      );
      expect(reopened.species.document!['id'], 'bulbasaur');
      expect(reopened.learnset?.document?['speciesId'], 'bulbasaur');
      final importedBytes = await file.readAsBytes();
      expect(await controller.previewExternal('bulbasaur'), isTrue);
      expect(controller.externalPreview!.hasConflicts, isTrue);
      final conflictPreview = controller.externalPreview;
      expect(
        await host.workflow.applyExternal(
          PokemonExternalConflictPolicy.failOnConflict,
          () async =>
              throw StateError('Conflicts cannot be implicitly accepted.'),
        ),
        isFalse,
      );
      expect(controller.error, isNotNull);
      expect(controller.externalPreview, same(conflictPreview));
      expect(await file.readAsBytes(), importedBytes);
      var confirmations = 0;
      expect(
        await host.workflow.applyExternal(
          PokemonExternalConflictPolicy.overwriteExisting,
          () async {
            confirmations++;
            return false;
          },
        ),
        isFalse,
      );
      expect(confirmations, 1);
      expect(controller.externalPreview, same(conflictPreview));
      expect(await file.readAsBytes(), importedBytes);
      expect(
        await host.workflow.applyExternal(
          PokemonExternalConflictPolicy.skipExisting,
          () async =>
              throw StateError('Keeping files needs no overwrite decision.'),
        ),
        isTrue,
      );
      expect(await file.readAsBytes(), importedBytes);
      expect(controller.externalResult!.skipped, greaterThan(0));
      expect(await controller.previewExternal('bulbasaur'), isTrue);
      final confirmation = Completer<bool>();
      final applying = host.workflow.applyExternal(
        PokemonExternalConflictPolicy.overwriteExisting,
        () {
          confirmations++;
          return confirmation.future;
        },
      );
      expect(confirmations, 2);
      expect(await file.readAsBytes(), importedBytes);
      await file.writeAsBytes([...importedBytes, 32]);
      final changedBytes = await file.readAsBytes();
      confirmation.complete(true);
      expect(await applying, isFalse);
      expect(controller.error, contains('Reprévisualisez'));
      expect(await file.readAsBytes(), changedBytes);
    },
  );

  test('external network error preserves local project', () async {
    final host = await PokemonAuthoringFixture.create(
      externalSource: const PokemonExternalSourceFixture(networkFailure: true),
    );
    addTearDown(host.dispose);
    final project = File('${host.source.directory.path}/project.json');
    final before = await project.readAsBytes();
    expect(await host.pokemon.searchExternal('bulbasaur'), isTrue);
    expect(host.pokemon.externalSearch!.suggestions, isEmpty);
    expect(host.pokemon.externalSearch!.message, contains('indisponible'));
    expect(await project.readAsBytes(), before);
  });

  test(
    'external preview refuses a companion owned by another species',
    () async {
      final host = await PokemonAuthoringFixture.create(
        prepareSource: (fixture) async {
          final file = File(
            '${fixture.directory.path}/data/pokemon/learnsets/bulbasaur.json',
          );
          await file.parent.create(recursive: true);
          final json =
              jsonDecode(await File(learnsetPath).readAsString()) as Map;
          json['schemaVersion'] = 1;
          json['speciesId'] = 'ivysaur';
          await file.writeAsString(jsonEncode(json));
        },
        externalSource: const PokemonExternalSourceFixture(),
      );
      addTearDown(host.dispose);
      final companion = File(
        '${host.source.directory.path}/data/pokemon/learnsets/bulbasaur.json',
      );
      final destination = File(
        '${host.source.directory.path}/data/pokemon/species/bulbasaur.json',
      );
      final before = await companion.readAsBytes();
      expect(await host.pokemon.searchExternal('bulbasaur'), isTrue);
      expect(await host.pokemon.previewExternal('bulbasaur'), isFalse);
      expect(host.pokemon.externalPreview, isNull);
      expect(host.pokemon.error, contains('appartient déjà'));
      expect(await companion.readAsBytes(), before);
      expect(await destination.exists(), isFalse);
    },
  );

  test('external import attaches companions to empty references after confirmation', () async {
    final host = await PokemonAuthoringFixture.create(
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
      externalSource: const PokemonExternalSourceFixture(),
    );
    addTearDown(host.dispose);
    final root = host.source.directory.path;
    final species = File('$root/data/pokemon/species/bulbasaur.json');
    final before = await species.readAsBytes();
    expect(await host.pokemon.searchExternal('bulbasaur'), isTrue);
    expect(await host.pokemon.previewExternal('bulbasaur'), isTrue);
    var confirmations = 0;
    expect(
      await host.workflow.applyExternal(
        PokemonExternalConflictPolicy.overwriteExisting,
        () async {
          confirmations++;
          expect(await species.readAsBytes(), before);
          expect(
            await File('$root/data/pokemon/learnsets/bulbasaur.json').exists(),
            isFalse,
          );
          return true;
        },
      ),
      isTrue,
    );
    expect(confirmations, 1);
    final saved = jsonDecode(await species.readAsString()) as Map;
    expect((saved['refs'] as Map)['learnset'], 'bulbasaur');
    expect(
      await File('$root/data/pokemon/learnsets/bulbasaur.json').exists(),
      isTrue,
    );
    expect(await File('$root/data/pokemon/learnsets/.json').exists(), isFalse);
  });
}

const learnsetPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/learnsets/bulbasaur.json';
const speciesPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
