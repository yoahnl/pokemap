import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';

import '../support/pokemon_authoring_fixture.dart';
import '../support/pokemon_external_source_fixture.dart';

void main() {
  test(
    'kept species changing during import prevents orphan companion',
    () async {
      final reader = _RaceReader(changeReference: true);
      final host = await _openHost(reader);
      addTearDown(host.dispose);
      final root = host.source.directory.path;
      await _previewKeptImport(host);
      reader.projectRoot = root;
      reader.armed = true;
      expect(
        await host.workflow.applyExternal(
          PokemonExternalConflictPolicy.skipExisting,
          () async =>
              throw StateError('Keeping files needs no overwrite decision.'),
        ),
        isFalse,
      );
      final species = jsonDecode(
        await File('$root/data/pokemon/species/bulbasaur.json').readAsString(),
      ) as Map;
      expect(reader.triggered, isTrue);
      expect((species['refs'] as Map)['learnset'], 'other-learn');
      expect(
        await File('$root/data/pokemon/learnsets/bulbasaur.json').exists(),
        isFalse,
      );
      expect(host.pokemon.error, contains('Reprévisualisez'));
    },
  );

  test('unchanged kept species can receive its missing companion', () async {
    final reader = _RaceReader(changeReference: false);
    final host = await _openHost(reader);
    addTearDown(host.dispose);
    final root = host.source.directory.path;
    await _previewKeptImport(host);
    reader.projectRoot = root;
    reader.armed = true;
    expect(
      await host.workflow.applyExternal(
        PokemonExternalConflictPolicy.skipExisting,
        () async =>
            throw StateError('Keeping files needs no overwrite decision.'),
      ),
      isTrue,
    );
    expect(reader.triggered, isTrue);
    expect(reader.speciesProbes, 2);
    expect(reader.referenceAtPrecondition, 'bulbasaur');
    expect(
      await File('$root/data/pokemon/learnsets/bulbasaur.json').exists(),
      isTrue,
    );
    expect(host.pokemon.error, isNull);
    expect(host.pokemon.externalResult, isNotNull);
  });

  test(
    'transaction precondition rejects a kept species edited after snapshot',
    () async {
      final reader = _RaceReader(
        changeReference: false,
        changeAtPrecondition: true,
      );
      final host = await _openHost(reader);
      addTearDown(host.dispose);
      final root = host.source.directory.path;
      await _previewKeptImport(host);
      reader.projectRoot = root;
      reader.armed = true;
      expect(
        await host.workflow.applyExternal(
          PokemonExternalConflictPolicy.skipExisting,
          () async =>
              throw StateError('Keeping files needs no overwrite decision.'),
        ),
        isFalse,
      );
      expect(reader.speciesProbes, 2);
      expect(reader.referenceAtFirstProbe, 'bulbasaur');
      expect(reader.referenceAtPrecondition, 'bulbasaur');
      expect(reader.changedAtPrecondition, isTrue);
      final species = jsonDecode(
        await File('$root/data/pokemon/species/bulbasaur.json').readAsString(),
      ) as Map;
      expect((species['refs'] as Map)['learnset'], 'other-learn');
      expect(
        await File('$root/data/pokemon/learnsets/bulbasaur.json').exists(),
        isFalse,
      );
      expect(host.pokemon.error, contains('Reprévisualisez'));
      expect(host.pokemon.externalResult, isNull);
    },
  );
}

Future<PokemonAuthoringFixture> _openHost(_RaceReader reader) =>
    PokemonAuthoringFixture.create(
      externalSource: const PokemonExternalSourceFixture(),
      reader: reader,
      prepareSource: (fixture) async {
        final file = File(
          '${fixture.directory.path}/data/pokemon/species/bulbasaur.json',
        );
        final species =
            jsonDecode(await File(_speciesPath).readAsString()) as Map;
        species['schemaVersion'] = 1;
        (species['refs'] as Map)['learnset'] = 'bulbasaur';
        (species['refs'] as Map)['evolution'] = '';
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(species));
      },
    );

Future<void> _previewKeptImport(PokemonAuthoringFixture host) async {
  expect(await host.pokemon.searchExternal('bulbasaur'), isTrue);
  expect(await host.pokemon.previewExternal('bulbasaur'), isTrue);
  expect(host.pokemon.externalPreview!.hasConflicts, isTrue);
}

final class _RaceReader
    implements
        ProjectFileReader,
        ProjectDirectoryReader,
        ProjectResourceProbeReader {
  _RaceReader({
    required this.changeReference,
    this.changeAtPrecondition = false,
  });

  final bool changeReference;
  final bool changeAtPrecondition;
  final LocalProjectFileReader _delegate = const LocalProjectFileReader();
  String? projectRoot;
  bool armed = false;
  bool triggered = false;
  bool changedAtPrecondition = false;
  int _companionProbes = 0;
  int speciesProbes = 0;
  String? referenceAtFirstProbe;
  String? referenceAtPrecondition;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) =>
      _delegate.readBytes(projectRoot: projectRoot, relativePath: relativePath);

  @override
  Future<List<String>> listFiles({
    required String projectRoot,
    required String relativeDirectory,
  }) => _delegate.listFiles(
    projectRoot: projectRoot,
    relativeDirectory: relativeDirectory,
  );

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) async {
    final result = await _delegate.probeResource(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    if (armed && relativePath == 'data/pokemon/species/bulbasaur.json') {
      final file = File('${this.projectRoot}/$relativePath');
      final species = jsonDecode(file.readAsStringSync()) as Map;
      final reference = (species['refs'] as Map)['learnset'] as String;
      speciesProbes++;
      if (speciesProbes == 1) referenceAtFirstProbe = reference;
      if (speciesProbes == 2) {
        referenceAtPrecondition = reference;
        if (changeAtPrecondition) {
          (species['refs'] as Map)['learnset'] = 'other-learn';
          file.writeAsStringSync(jsonEncode(species));
          changedAtPrecondition = true;
        }
      }
    }
    if (armed &&
        relativePath == 'data/pokemon/learnsets/bulbasaur.json' &&
        ++_companionProbes == 2) {
      triggered = true;
      if (changeReference) {
        final file = File(
          '${this.projectRoot}/data/pokemon/species/bulbasaur.json',
        );
        final species = jsonDecode(await file.readAsString()) as Map;
        (species['refs'] as Map)['learnset'] = 'other-learn';
        await file.writeAsString(jsonEncode(species));
      }
    }
    return result;
  }
}

const _speciesPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
