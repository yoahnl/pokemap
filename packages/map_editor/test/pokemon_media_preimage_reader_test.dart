import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/application/authoring_api/pokemon_media_preimage_reader.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory qaDirectory;
  late Directory project;
  var createdQaDirectory = false;

  setUpAll(() async {
    final supplied = Platform.environment['AVELUNE_QA_ROOT'];
    final home = Platform.environment['HOME'];
    if (supplied != null && supplied.isNotEmpty) {
      if (!p.isAbsolute(supplied)) {
        throw ArgumentError('AVELUNE_QA_ROOT must be absolute.');
      }
      qaDirectory = Directory(supplied);
      if (!await qaDirectory.exists()) {
        throw ArgumentError('AVELUNE_QA_ROOT must exist.');
      }
    } else if (Platform.isMacOS) {
      if (home == null || home.isEmpty) throw StateError('HOME is required.');
      qaDirectory = Directory(
        p.join(
          home,
          'Library',
          'Caches',
          'AveluneQA',
          'pokemon-media-preimage-tests',
        ),
      );
      if (!await qaDirectory.exists()) {
        await qaDirectory.create(recursive: true);
        createdQaDirectory = true;
      }
    } else {
      qaDirectory = Directory.systemTemp;
    }
    if (Platform.isMacOS) {
      if (home == null || home.isEmpty) throw StateError('HOME is required.');
      final root = await Directory(
        p.join(home, 'Library', 'Caches', 'AveluneQA'),
      ).resolveSymbolicLinks();
      if (!p.isWithin(root, await qaDirectory.resolveSymbolicLinks())) {
        throw ArgumentError('AVELUNE_QA_ROOT must be inside AveluneQA.');
      }
    }
  });

  tearDownAll(() async {
    if (createdQaDirectory) {
      try {
        await qaDirectory.delete();
      } on FileSystemException {
        return;
      }
    }
  });

  setUp(() async {
    project = await qaDirectory.createTemp('media-preimage-');
  });

  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  test('captures the exact bytes and decoded media from the same read', () async {
    final file = File('${project.path}/custom/media/oshawott.json');
    await file.parent.create(recursive: true);
    final bytes = utf8.encode(
      ' { "vendor" : 3, "schemaVersion": 2, "speciesId": "oshawott", "defaultFormId": "base", "variants": {"base": {"frontAnimated": "front.gif"}} }\n',
    );
    await file.writeAsBytes(bytes);
    final snapshot = await const PokemonMediaPreimageReader().read(
      projectRoot: project.path,
      mediaDirectory: 'custom/media',
      mediaId: 'oshawott',
    );
    expect(snapshot.relativePath, 'custom/media/oshawott.json');
    expect(snapshot.bytes, bytes);
    expect(snapshot.media!.variants['base']!.frontAnimated, 'front.gif');
    expect(snapshot.media!.toJson()['vendor'], 3);
    expect(() => snapshot.bytes![0] = 0, throwsUnsupportedError);
    expect(await file.readAsBytes(), bytes);
  });

  test('captures absence and supports a root media directory', () async {
    for (final directory in ['', '.']) {
      final snapshot = await const PokemonMediaPreimageReader().read(
        projectRoot: project.path,
        mediaDirectory: directory,
        mediaId: 'oshawott',
      );
      expect(snapshot.relativePath, 'oshawott.json');
      expect(snapshot.bytes, isNull);
      expect(snapshot.media, isNull);
    }
  });

  test('rejects unsafe identities, directories and project metadata', () async {
    for (final id in [
      '../outside',
      'other/file',
      r'other\file',
      '..',
      '.',
      '',
    ]) {
      await expectLater(
        const PokemonMediaPreimageReader().read(
          projectRoot: project.path,
          mediaDirectory: 'data/pokemon/media',
          mediaId: id,
        ),
        throwsFormatException,
      );
    }
    for (final directory in [
      '../outside',
      '/outside',
      r'C:\outside',
      'data//media',
      'catalog',
      'Catalog/objects',
      '.POKEMAP/authoring',
    ]) {
      await expectLater(
        const PokemonMediaPreimageReader().read(
          projectRoot: project.path,
          mediaDirectory: directory,
          mediaId: 'oshawott',
        ),
        throwsFormatException,
      );
    }
    await expectLater(
      const PokemonMediaPreimageReader().read(
        projectRoot: project.path,
        mediaDirectory: '.',
        mediaId: 'project',
      ),
      throwsFormatException,
    );
  });

  test('rejects a mismatched document and symbolic links', () async {
    final file = File('${project.path}/media/oshawott.json');
    await file.parent.create(recursive: true);
    final bytes = utf8.encode(
      '{"schemaVersion":1,"speciesId":"other","defaultFormId":"base","variants":{}}',
    );
    await file.writeAsBytes(bytes);
    await expectLater(
      const PokemonMediaPreimageReader().read(
        projectRoot: project.path,
        mediaDirectory: 'media',
        mediaId: 'oshawott',
      ),
      throwsFormatException,
    );
    expect(await file.readAsBytes(), bytes);
    if (!Platform.isWindows) {
      final outside = await Directory('${project.path}-outside').create();
      addTearDown(() => outside.delete(recursive: true));
      await Link('${project.path}/linked').create(outside.path);
      await expectLater(
        const PokemonMediaPreimageReader().read(
          projectRoot: project.path,
          mediaDirectory: 'linked',
          mediaId: 'oshawott',
        ),
        throwsA(
          isA<TransactionFileGatewayException>().having(
            (error) => error.code,
            'code',
            'transaction.storage_parent_invalid',
          ),
        ),
      );
    }
  });

  for (final catalog in [false, true]) {
  test('writes through canonical authoring and preserves a concurrent edit, catalog $catalog', () async {
    final manifest = const ProjectManifest(name: 'media', maps: [], tilesets: []);
    if (catalog) {
      final store = await CatalogStorageStore.open(projectRoot: project.path);
      await WorkingProjectCatalog.create(store: store, projectId: 'media-test', project: manifest);
    } else {
      await File('${project.path}/project.json').writeAsString(jsonEncode(manifest.toJson()));
    }
    const speciesPath = 'data/pokemon/species/0001-oshawott.json';
    final speciesFile = File('${project.path}/$speciesPath');
    await speciesFile.parent.create(recursive: true);
    await speciesFile.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'id': 'oshawott',
      'refs': {'media': 'oshawott'},
    }));
    final mediaFile = File('${project.path}/data/pokemon/media/oshawott.json');
    await mediaFile.parent.create(recursive: true);
    final before = utf8.encode('{"schemaVersion":2,"speciesId":"oshawott","defaultFormId":"base","variants":{"base":{"frontAnimated":"front.gif"}}}');
    await mediaFile.writeAsBytes(before);
    const reader = EditorProjectFileReader();
    final policy = await WorkspacePolicy.create(allowedRootPaths: [project.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(policy: policy, fileReader: reader, handles: handles, workshopScope: true, initializeSceneOwners: false, catalogMetadataFields: {});
    final opened = await opener.openProject(project.path);
    final api = LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: ProjectSnapshotLoader(handles: handles), catalogFileReader: reader);
    await api.attachProject(projectRootPath: project.path, workspaceHandle: opened.workspaceHandle, projectHandle: opened.projectHandle);
    await api.prepareWorkshopCatalog(opened.projectHandle);
    await api.detachWorkspace(opened.workspaceHandle);
    opener.closeWorkspace(opened.workspaceHandle);
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(fileReader: reader, queries: queries, projectRoots: reader);
    addTearDown(() async {
      await mutations.closeAll();
      await queries.closeAll();
    });

    final preimage = await const PokemonMediaPreimageReader().read(projectRoot: project.path, mediaDirectory: manifest.pokemon.mediaDir, mediaId: 'oshawott');
    const edited = PokemonMediaFile(
      speciesId: 'oshawott',
      defaultFormId: 'base',
      variants: {'base': PokemonMediaVariant(frontStatic: 'front.png')},
    );
    final receipt = await mutations.savePokemonMediaDraft(
      project.path,
      preimage: preimage,
      edited: edited,
      speciesId: 'oshawott',
      speciesRelativePath: speciesPath,
    );
    expect(receipt.actionId, 'pokemon.media.write');
    expect((jsonDecode(await mediaFile.readAsString()) as Map)['variants']['base']['frontAnimated'], 'front.gif');
    await mutations.undo(project.path, entryId: receipt.receiptId, idempotencyKey: 'undo-media-editor');
    expect(await mediaFile.readAsBytes(), before);

    final concurrent = utf8.encode('{"schemaVersion":2,"speciesId":"oshawott","defaultFormId":"base","variants":{"base":{"frontAnimated":"other.gif"}}}');
    await mediaFile.writeAsBytes(concurrent);
    await expectLater(
      mutations.savePokemonMediaDraft(project.path, preimage: preimage, edited: edited, speciesId: 'oshawott', speciesRelativePath: speciesPath),
      throwsA(isA<EditorAuthoringMutationFailure>().having(
        (error) => error.code, 'code', anyOf('revision.conflict', 'plan.stale'),
      )),
    );
    expect(await mediaFile.readAsBytes(), concurrent);
    await mediaFile.writeAsBytes(before);
    await speciesFile.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'id': 'oshawott',
      'refs': {'media': 'different'},
    }));
    await expectLater(
      mutations.savePokemonMediaDraft(project.path, preimage: preimage, edited: edited, speciesId: 'oshawott', speciesRelativePath: speciesPath),
      throwsA(isA<EditorAuthoringMutationFailure>().having(
        (error) => error.code, 'code', 'pokemon.media_reference_changed',
      )),
    );
    expect(await mediaFile.readAsBytes(), before);
  });
  }
}
