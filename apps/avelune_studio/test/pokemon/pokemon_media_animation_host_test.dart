import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_species_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets('animation references and custom local PNG reopen from disk', (
    tester,
  ) async {
    final reader = _CountingReader();
    final host = await MapHostFixture.open(
      tester,
      pokemonReader: reader,
      prepareSource: (fixture) async {
        for (final (folder, file) in [
          ('species', '0001-bulbasaur.json'),
          ('media', 'bulbasaur.json'),
        ]) {
          final destination = File(
            '${fixture.directory.path}/data/pokemon/$folder/$file',
          );
          final json = jsonDecode(
            await File('$sourcePath/$folder/$file').readAsString(),
          ) as Map<String, dynamic>;
          json['schemaVersion'] = 1;
          if (folder == 'media') {
            json['schemaVersion'] = 2;
            final variant = (json['variants'] as Map)['base'] as Map;
            variant['frontAnimated'] = 'assets/custom/front.gif';
            variant['futureVariant'] = {'preserve': true};
            ((variant['animations'] as Map)['idle'] as Map)['sheet'] =
                'assets/custom/battle.png';
          }
          await destination.parent.create(recursive: true);
          await destination.writeAsString(jsonEncode(json));
          if (folder == 'species') {
            for (var index = 0; index < 9; index++) {
              final other =
                  jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
              other['id'] = 'unrelated-$index';
              other['slug'] = 'unrelated-$index';
              other['nationalDex'] = index + 20;
              await File('${destination.parent.path}/unrelated-$index.json')
                  .writeAsString(jsonEncode(other));
            }
          }
        }
        final image = File(
          '${fixture.directory.path}/assets/custom/battle.png',
        );
        await image.parent.create(recursive: true);
        await File(sourcePng).copy(image.path);
      },
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
    await pumpIo(tester);
    await tester.tap(find.text('Médias').last);
    await pumpIo(tester);
    final animation = find.text('Animation idle');
    await tester.ensureVisible(animation);
    expect(animation, findsOneWidget);
    final animationId = find.byKey(
      const ValueKey('media-variants.base.animations.idle.animationId'),
    );
    await tester.ensureVisible(animationId);
    await tester.enterText(animationId, 'idle-train');
    await tester.pump();
    expect(
      tester
          .widgetList<PokemonSpeciesThumbnail>(
            find.byType(PokemonSpeciesThumbnail),
          )
          .where((thumbnail) => thumbnail.entry.id == 'bulbasaur')
          .every((thumbnail) => thumbnail.mediaRevision == 0),
      isTrue,
    );
    reader.paths.clear();
    await tester.tap(find.text('Enregistrer').first);
    await pumpIo(tester);
    expect(
      tester
          .widgetList<PokemonSpeciesThumbnail>(
            find.byType(PokemonSpeciesThumbnail),
          )
          .where((thumbnail) => thumbnail.entry.id == 'bulbasaur')
          .any((thumbnail) => thumbnail.mediaRevision == 1),
      isTrue,
    );
    expect(reader.paths.where((path) => path.contains('unrelated-')), isEmpty);
    final bundle = (await tester.runAsync(() async {
      final adapter = LocalPokemonWorkspaceAdapter(
        session: host.source.session,
        mapAdapter: host.source.maps,
      );
      final entry = (await adapter.loadIndex()).entries.singleWhere(
        (entry) => entry.id == 'bulbasaur',
      );
      final image = await adapter.loadImage('assets/custom/battle.png');
      return (await adapter.loadSpecies(entry), image);
    }))!;
    final media = bundle.$1.media!.document!;
    final variant = (media['variants'] as Map)['base'] as Map;
    final idle = (variant['animations'] as Map)['idle'] as Map;
    expect(idle['sheet'], 'assets/custom/battle.png');
    expect(idle['animationId'], 'idle-train');
    expect(variant['frontAnimated'], 'assets/custom/front.gif');
    expect(variant['futureVariant'], {'preserve': true});
    expect(bundle.$2, isNotNull);
    expect(tester.takeException(), isNull);
  });
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectDirectoryReader,
        ProjectResourceProbeReader,
        ProjectResourceStreamReader {
  final _reader = const LocalProjectFileReader();
  final paths = <String>[];

  @override
  bool get supportsStreamingResources => true;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _reader.canonicalizeDirectory(path);

  @override
  Future<List<String>> listFiles({
    required String projectRoot,
    required String relativeDirectory,
  }) => _reader.listFiles(
    projectRoot: projectRoot,
    relativeDirectory: relativeDirectory,
  );

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => _reader.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return _reader.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return _reader.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

const sourcePath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10';
const sourcePng =
    '../../examples/playable_runtime_host/golden_item_system/assets/pokemon/sprites/sproutle/front.png';
