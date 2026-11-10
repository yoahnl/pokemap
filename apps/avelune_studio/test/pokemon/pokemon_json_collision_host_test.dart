import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/m3_story_fixture.dart';
import '../support/pokemon_authoring_fixture.dart';

void main() {
  test('confirmed overwrite reloads selected species before further editing', () async {
    final host = await PokemonAuthoringFixture.create(
      prepareSource: _seedSpecies,
    );
    addTearDown(host.dispose);
    final source = await _createSource(host, name: 'Bulbizarre importé');
    final destination = File(
      '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
    );
    final before = await destination.readAsBytes();
    expect(await host.workflow.requestSpecies('bulbasaur'), isTrue);
    final originalDraft = host.pokemon.selectedDraft;
    expect(await host.workflow.pickJson(() async => source.path), isTrue);
    final preview = host.pokemon.importPreview;
    expect(preview!.hasConflicts, isTrue);
    var confirmations = 0;
    expect(
      await host.workflow.applyJsonImport(() async {
        confirmations++;
        return false;
      }),
      isFalse,
    );
    expect(confirmations, 1);
    expect(host.pokemon.importPreview, same(preview));
    expect(host.pokemon.selectedDraft, same(originalDraft));
    expect(await destination.readAsBytes(), before);
    final confirmation = Completer<bool>();
    final applying = host.workflow.applyJsonImport(() {
      confirmations++;
      return confirmation.future;
    });
    expect(confirmations, 2);
    expect(await destination.readAsBytes(), before);
    confirmation.complete(true);
    expect(await applying, isTrue);
    expect(host.pokemon.selectedDraft, isNot(same(originalDraft)));
    expect(
      host.pokemon.selectedDraft!.document(
        PokemonDocumentFamily.species,
      )!['names']['fr'],
      'Bulbizarre importé',
    );
    host.pokemon.edit(PokemonDocumentFamily.species, (json) {
      (json['names'] as Map)['fr'] = 'Bulbizarre après import';
    });
    expect(await host.pokemon.saveActiveOwner(), isTrue);
    final saved = jsonDecode(await destination.readAsString()) as Map;
    expect((saved['names'] as Map)['fr'], 'Bulbizarre après import');
  });

  test('JSON import does not replace a different species by filename', () async {
    final host = await PokemonAuthoringFixture.create(
      prepareSource: _seedSpecies,
    );
    addTearDown(host.dispose);
    final source = await _createSource(host, id: 'ivysaur');
    final destination = File(
      '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
    );
    final before = await destination.readAsBytes();
    expect(await host.workflow.pickJson(() async => source.path), isFalse);
    expect(host.pokemon.importPreview, isNull);
    expect(host.pokemon.error, contains('appartient déjà'));
    expect(await destination.readAsBytes(), before);
  });

  test('invalid companion rejects JSON preview before writing', () async {
    final host = await PokemonAuthoringFixture.create();
    addTearDown(host.dispose);
    final source = await _createSource(host, invalidCompanion: true);
    final destination = File(
      '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
    );
    expect(await host.workflow.pickJson(() async => source.path), isFalse);
    expect(host.pokemon.importPreview, isNull);
    expect(host.pokemon.error, contains('Import JSON refusé'));
    expect(await destination.exists(), isFalse);
  });

  test('JSON import keeps a legacy companion reference identity', () async {
    final host = await PokemonAuthoringFixture.create();
    addTearDown(host.dispose);
    final source = await _createSource(host, companionId: 'custom-learn');
    expect(await host.workflow.pickJson(() async => source.path), isTrue);
    expect(host.pokemon.importPreview!.items, hasLength(2));
    expect(
      await host.workflow.applyJsonImport(() async {
        throw StateError('New content needs no overwrite decision.');
      }),
      isTrue,
    );
    final companion = File(
      '${host.source.directory.path}/data/pokemon/learnsets/custom-learn.json',
    );
    expect(await companion.exists(), isTrue);
    final saved = jsonDecode(await companion.readAsString()) as Map;
    expect(saved['speciesId'], 'custom-learn');
    final draft = host.pokemon.selectedDraft!;
    expect(draft.id, 'bulbasaur');
    expect(
      draft.document(PokemonDocumentFamily.species)!['refs']['learnset'],
      'custom-learn',
    );
    expect(
      draft.document(PokemonDocumentFamily.learnset)!['speciesId'],
      'custom-learn',
    );
  });

  test('JSON import refuses a companion owned by another species', () async {
    final host = await PokemonAuthoringFixture.create(
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
    );
    addTearDown(host.dispose);
    final source = await _createSource(host, companionId: 'bulbasaur');
    final companion = File(
      '${host.source.directory.path}/data/pokemon/learnsets/bulbasaur.json',
    );
    final destination = File(
      '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
    );
    final before = await companion.readAsBytes();
    expect(await host.workflow.pickJson(() async => source.path), isFalse);
    expect(host.pokemon.importPreview, isNull);
    expect(host.pokemon.error, contains('appartient déjà'));
    expect(await companion.readAsBytes(), before);
    expect(await destination.exists(), isFalse);
  });
}

Future<void> _seedSpecies(M3StoryFixture fixture) async {
  final destination = File(
    '${fixture.directory.path}/data/pokemon/species/0001-bulbasaur.json',
  );
  await destination.parent.create(recursive: true);
  final json = jsonDecode(await File(fixturePath).readAsString()) as Map;
  json['schemaVersion'] = 1;
  await destination.writeAsString(jsonEncode(json));
}

Future<File> _createSource(
  PokemonAuthoringFixture host, {
  String id = 'bulbasaur',
  String? name,
  String? companionId,
  bool invalidCompanion = false,
}) async {
  final root = '${host.source.directory.path}/incoming';
  final species = File('$root/species/0001-bulbasaur.json');
  await species.parent.create(recursive: true);
  final json = jsonDecode(await File(fixturePath).readAsString()) as Map;
  json['schemaVersion'] = 1;
  json['id'] = id;
  json['slug'] = id;
  if (name != null) (json['names'] as Map)['fr'] = name;
  if (companionId != null) (json['refs'] as Map)['learnset'] = companionId;
  await species.writeAsString(jsonEncode(json));
  if (companionId != null || invalidCompanion) {
    final learnset = File('$root/learnsets/${companionId ?? 'bulbasaur'}.json');
    await learnset.parent.create(recursive: true);
    if (invalidCompanion) {
      await learnset.writeAsString('{bad json');
    } else {
      final data = jsonDecode(await File(learnsetPath).readAsString()) as Map;
      data['schemaVersion'] = 1;
      data['speciesId'] = companionId;
      await learnset.writeAsString(jsonEncode(data));
    }
  }
  return species;
}

const fixturePath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
const learnsetPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/learnsets/bulbasaur.json';
