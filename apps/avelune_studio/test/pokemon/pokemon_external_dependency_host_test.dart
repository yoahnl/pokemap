import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';

import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/pokemon_external_source_fixture.dart';

void main() {
  testWidgets('kept species changing during import prevents orphan companion', (
    tester,
  ) async {
    final reader = _RaceReader(changeReference: true);
    final host = await _openHost(tester, reader);
    final root = host.source.directory.path;
    await _previewKeptImport(tester, host);
    reader.projectRoot = root;
    reader.armed = true;

    await tester.tap(find.text('Appliquer l’import'));
    await pumpIo(tester);

    final species =
        jsonDecode(
              (await tester.runAsync(
                () => File(
                  '$root/data/pokemon/species/bulbasaur.json',
                ).readAsString(),
              ))!,
            )
            as Map;
    expect(reader.triggered, isTrue);
    expect((species['refs'] as Map)['learnset'], 'other-learn');
    expect(
      (await tester.runAsync(
        () => File('$root/data/pokemon/learnsets/bulbasaur.json').exists(),
      ))!,
      isFalse,
    );
    final controller = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!;
    expect(controller.error, contains('Reprévisualisez'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('unchanged kept species can receive its missing companion', (
    tester,
  ) async {
    final reader = _RaceReader(changeReference: false);
    final host = await _openHost(tester, reader);
    final root = host.source.directory.path;
    await _previewKeptImport(tester, host);
    reader.projectRoot = root;
    reader.armed = true;

    await tester.tap(find.text('Appliquer l’import'));
    await pumpIo(tester);

    expect(reader.triggered, isTrue);
    expect(
      (await tester.runAsync(
        () => File('$root/data/pokemon/learnsets/bulbasaur.json').exists(),
      ))!,
      isTrue,
    );
    final controller = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!;
    expect(controller.error, isNull);
    expect(tester.takeException(), isNull);
  });
}

Future<MapHostFixture> _openHost(WidgetTester tester, _RaceReader reader) =>
    MapHostFixture.open(
      tester,
      pokemonExternalSource: const PokemonExternalSourceFixture(),
      pokemonReader: reader,
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

Future<void> _previewKeptImport(
  WidgetTester tester,
  MapHostFixture host,
) async {
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
  await tester.tap(find.text('Garder les fichiers existants').last);
  await tester.pump();
}

final class _RaceReader
    implements
        ProjectFileReader,
        ProjectDirectoryReader,
        ProjectResourceProbeReader {
  _RaceReader({required this.changeReference});

  final bool changeReference;
  final LocalProjectFileReader _delegate = const LocalProjectFileReader();
  String? projectRoot;
  bool armed = false;
  bool triggered = false;
  int _companionProbes = 0;

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
