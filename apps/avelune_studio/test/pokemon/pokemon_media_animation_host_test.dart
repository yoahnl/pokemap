import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_document_editing.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_media_editing_session.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

import '../support/pokemon_authoring_fixture.dart';

void main() {
  test('animation references and custom local PNG reopen from disk', () async {
    final reader = _CountingReader();
    final host = await PokemonAuthoringFixture.create(
      reader: reader,
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
            (json['variants'] as Map)['alternate'] = jsonDecode(
              jsonEncode(variant),
            );
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
    addTearDown(host.dispose);
    expect(await host.workflow.requestSpecies('bulbasaur'), isTrue);
    final controller = host.pokemon;
    final session = PokemonMediaEditingSession(current: () => controller);
    addTearDown(session.dispose);
    session.setDefaultForm('alternate');
    final mediaPath = controller.selectedDraft!.base.media!.relativePath;
    controller.edit(PokemonDocumentFamily.media, (json) {
      PokemonDocumentEditing.write(json, [
        'variants',
        'base',
        'animations',
        'idle',
        'animationId',
      ], 'idle-train');
    });
    expect(controller.mediaRevision(mediaPath), 0);
    reader.paths.clear();
    expect(await controller.saveActiveOwner(), isTrue);
    expect(controller.mediaRevision(mediaPath), 1);
    expect(reader.paths.where((path) => path.contains('unrelated-')), isEmpty);
    final adapter = LocalPokemonWorkspaceAdapter(
      session: host.source.session,
      mapAdapter: host.source.maps,
    );
    addTearDown(adapter.close);
    final entry = (await adapter.loadIndex()).entries.singleWhere(
      (entry) => entry.id == 'bulbasaur',
    );
    final bundle = (
      await adapter.loadSpecies(entry),
      await adapter.loadImage('assets/custom/battle.png'),
    );
    final media = bundle.$1.media!.document!;
    expect(media['defaultFormId'], 'alternate');
    final variant = (media['variants'] as Map)['base'] as Map;
    final idle = (variant['animations'] as Map)['idle'] as Map;
    expect(idle['sheet'], 'assets/custom/battle.png');
    expect(idle['animationId'], 'idle-train');
    expect(variant['frontAnimated'], 'assets/custom/front.gif');
    expect(variant['futureVariant'], {'preserve': true});
    expect(bundle.$2, isNotNull);
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
