import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  final readCounts = <String, int>{};
  for (final catalog in [false, true]) {
    for (final version in [1, 2]) {
      for (final unrelated in [0, 9]) {
        for (final mediaDir in [
          'data/pokemon/media',
          if (version == 2 && unrelated == 0) ...['', '.', 'custom/media'],
        ]) {
          test(
            'Studio media saves preserve v$version and stay local with catalog=$catalog unrelated=$unrelated mediaDir="$mediaDir"',
            () async {
              final root = await Directory.systemTemp.createTemp(
                'studio-media-',
              );
              addTearDown(() => root.delete(recursive: true));
              final project = ProjectManifest(
                name: 'Media',
                maps: const [],
                tilesets: const [],
                pokemon: ProjectPokemonConfig(
                  ruleset: PokemonRulesetProfile.standardV1,
                  mediaDir: mediaDir,
                ),
              );
              if (catalog) {
                final store = await CatalogStorageStore.open(
                  projectRoot: root.path,
                );
                await WorkingProjectCatalog.create(
                  store: store,
                  projectId: 'media',
                  project: project,
                );
              } else {
                await File('${root.path}/project.json')
                    .writeAsString(jsonEncode(project.toJson()));
              }
              final speciesDirectory = Directory(
                '${root.path}/data/pokemon/species',
              );
              final mediaDirectory = mediaDir.isEmpty || mediaDir == '.'
                  ? root
                  : Directory('${root.path}/$mediaDir');
              await speciesDirectory.create(recursive: true);
              await mediaDirectory.create(recursive: true);
              final sourceSpecies = jsonDecode(
                await File(
                  '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json',
                ).readAsString(),
              ) as Map<String, dynamic>;
              sourceSpecies['schemaVersion'] = 1;
              final sourceMedia = jsonDecode(
                await File(
                  '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/media/bulbasaur.json',
                ).readAsString(),
              ) as Map<String, dynamic>;
              sourceMedia['schemaVersion'] = version;
              sourceMedia['foreignDocument'] = {'preserve': true};
              final variant = (sourceMedia['variants'] as Map)['base'] as Map;
              variant['frontAnimated'] = 'assets/front.gif';
              variant['foreignVariant'] = {'preserve': 7};
              final speciesFile = File(
                '${speciesDirectory.path}/bulbasaur.json',
              );
              final mediaFile = File('${mediaDirectory.path}/bulbasaur.json');
              await speciesFile.writeAsString(jsonEncode(sourceSpecies));
              await mediaFile.writeAsString(jsonEncode(sourceMedia));
              for (var index = 0; index < unrelated; index++) {
                final other = Map<String, dynamic>.from(
                  jsonDecode(jsonEncode(sourceSpecies)) as Map,
                );
                other['id'] = 'unrelated-$index';
                other['slug'] = 'unrelated-$index';
                other['nationalDex'] = 20 + index;
                await File('${speciesDirectory.path}/unrelated-$index.json')
                    .writeAsString(jsonEncode(other));
              }
              final reader = _CountingReader();
              final sessions = LocalProjectSessionAdapter(fileReader: reader);
              final session = await sessions.open(root.path);
              addTearDown(() => sessions.close(session));
              final maps = LocalMapWorkspaceAdapter(reader: reader);
              if (catalog) {
                await maps.loadCatalog(session);
              } else {
                await maps.loadProject(session);
              }
              final port = LocalPokemonWorkspaceAdapter(
                session: session,
                mapAdapter: maps,
                reader: reader,
              );
              addTearDown(port.close);
              final controller = PokemonWorkspaceController(
                port,
                changed: () {},
              );
              addTearDown(controller.dispose);
              await controller.load();
              expect(
                await controller.selectSpecies('bulbasaur'),
                isTrue,
                reason:
                    '${controller.error}; ${controller.index?.entries.map((e) => e.id).toList()}',
              );
              List<int>? first;
              for (var attempt = 0; attempt < 2; attempt++) {
                controller.edit(PokemonDocumentFamily.media, (document) {
                  ((document['variants'] as Map)['base']
                          as Map)['frontStatic'] =
                      'assets/front-$attempt.png';
                });
                reader.paths.clear();
                final watch = Stopwatch()..start();
                expect(
                  await controller.saveActiveOwner(),
                  isTrue,
                  reason: controller.error,
                );
                watch.stop();
                final key = '$catalog/$version/$mediaDir/$attempt';
                expect(
                  reader.paths.length,
                  readCounts.putIfAbsent(key, () => reader.paths.length),
                );
                debugPrint(
                  'media-save catalog=$catalog version=$version mediaDir="$mediaDir" unrelated=$unrelated attempt=$attempt elapsedMs=${watch.elapsedMilliseconds} reads=${reader.paths.length}',
                );
                expect(
                  reader.paths.where((path) => path.contains('unrelated-')),
                  isEmpty,
                );
                final saved = jsonDecode(await mediaFile.readAsString()) as Map;
                final values = (saved['variants'] as Map)['base'] as Map;
                expect(saved['schemaVersion'], version);
                expect(saved['foreignDocument'], {'preserve': true});
                expect(values['frontAnimated'], 'assets/front.gif');
                expect(values['foreignVariant'], {'preserve': 7});
                expect(values['frontStatic'], 'assets/front-$attempt.png');
                first ??= await mediaFile.readAsBytes();
              }
              final latest = await mediaFile.readAsBytes();
              controller.edit(PokemonDocumentFamily.media, (document) {
                ((document['variants'] as Map)['base'] as Map)['frontStatic'] =
                    'assets/conflict.png';
              });
              final concurrent = utf8.encode(
                jsonEncode({
                  ...(jsonDecode(utf8.decode(latest)) as Map),
                  'concurrentChange': true,
                }),
              );
              await mediaFile.writeAsBytes(concurrent);
              expect(await controller.saveActiveOwner(), isFalse);
              expect(await mediaFile.readAsBytes(), concurrent);
              expect(controller.selectedDraft!.dirty, isTrue);
              await mediaFile.writeAsBytes(latest);
              final speciesBefore = await speciesFile.readAsBytes();
              await speciesFile.writeAsString(
                jsonEncode({...sourceSpecies, 'concurrentChange': true}),
              );
              expect(await controller.saveActiveOwner(), isFalse);
              expect(await mediaFile.readAsBytes(), latest);
              await speciesFile.writeAsBytes(speciesBefore);
              controller.discardSelectedSpecies();
              final policy = await WorkspacePolicy.create(
                allowedRootPaths: [root.path],
                fileReader: reader,
              );
              final handles = WorkspaceHandleStore();
              final opener = ProjectOpenService(
                policy: policy,
                handles: handles,
                fileReader: reader,
                catalogMetadataFields: {},
                workshopScope: true,
                initializeSceneOwners: false,
              );
              final opened = await opener.openProject(root.path);
              final api = LocalMapAuthoringMutationApi(
                policy: policy,
                snapshotLoader: ProjectSnapshotLoader(handles: handles),
              );
              await api.attachProject(
                projectRootPath: root.path,
                workspaceHandle: opened.workspaceHandle,
                projectHandle: opened.projectHandle,
              );
              final history = await api.listMutationHistory(
                opened.projectHandle,
                limit: 20,
              );
              final entry = history.page.entries.firstWhere(
                (entry) => entry.receipt.actionId == 'pokemon.media.write',
              );
              await api.undoMutation(
                opened.projectHandle,
                entryId: entry.entryId,
                idempotencyKey: 'undo-media',
              );
              expect(await mediaFile.readAsBytes(), first);
              await api.redoMutation(
                opened.projectHandle,
                entryId: entry.entryId,
                idempotencyKey: 'redo-media',
              );
              expect(await mediaFile.readAsBytes(), latest);
              await api.detachWorkspace(opened.workspaceHandle);
              opener.closeWorkspace(opened.workspaceHandle);
              final reopened = LocalPokemonWorkspaceAdapter(
                session: session,
                mapAdapter: maps,
                reader: reader,
              );
              final reloadedIndex = await reopened.loadIndex();
              final reloaded = await reopened.loadSpecies(
                reloadedIndex.entries.singleWhere(
                  (entry) => entry.id == 'bulbasaur',
                ),
              );
              expect(reloaded.media!.bytes, latest);
              await reopened.close();
            },
          );
        }
      }
    }
  }
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
