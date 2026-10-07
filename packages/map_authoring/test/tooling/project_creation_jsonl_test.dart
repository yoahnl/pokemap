import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late WorkspacePolicy policy;
  late AuthoringReadApi read;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('creation_jsonl_');
    const reader = LocalProjectFileReader();
    policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    read = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
  });
  tearDown(() async => root.delete(recursive: true));

  JsonlWorker worker(
          {LocalProjectCreationService? service, Duration? timeout}) =>
      JsonlWorker(
          api: read,
          commandTimeout: timeout ?? const Duration(seconds: 10),
          projectCreation: ProjectCreationBootstrapApi(
              policy: policy,
              creation: service ?? const LocalProjectCreationService()));

  Map<String, Object?> request({String folder = 'game', String? parent}) => {
        'name': 'Jeu création',
        'folderName': folder,
        'parentPath': parent ?? root.path,
        'template': 'playable',
        'tileSize': 32,
        'mapWidth': 24,
        'mapHeight': 18
      };

  test(
      'JSONL creates an exclusive empty 3D project and binds camera to confirmation',
      () async {
    final host = worker();
    final args = {
      ...request(),
      'dimension': 'threeD',
      'template': 'empty',
      'spatialCamera': SpatialCameraProfile(distance: 55).toJson()
    };
    final described = await _request(host, 'describe', {});
    expect(jsonEncode(described.toJson()).contains('threeD'), isTrue);
    final preview =
        await _request(host, 'project_create_preview', {'request': args});
    expect(preview.status, AuthoringResultStatus.success,
        reason: preview.toJson().toString());
    expect(preview.data['writes'], ['project.json', 'maps/first-map.json']);
    expect(await root.list().toList(), isEmpty);
    final mismatch = await _request(host, 'project_create', {
      'request': {
        ...args,
        'spatialCamera': SpatialCameraProfile(distance: 60).toJson()
      },
      'confirmation': preview.data['confirmation']
    });
    expect(mismatch.status, AuthoringResultStatus.failure);
    final result = await _request(host, 'project_create',
        {'request': args, 'confirmation': preview.data['confirmation']});
    expect(result.status, AuthoringResultStatus.success,
        reason: result.toJson().toString());
    final projectRoot = result.data['projectPath'] as String;
    final manifest = ProjectManifest.fromJson(jsonDecode(
            await File(p.join(projectRoot, 'project.json')).readAsString())
        as Map<String, dynamic>);
    final map = MapData.fromJson(jsonDecode(
        await File(p.join(projectRoot, 'maps/first-map.json'))
            .readAsString()) as Map<String, dynamic>);
    expect(manifest.version, ProjectVersion.v9);
    expect(manifest.settings.dimension, ProjectDimension.threeD);
    expect(manifest.tilesets, isEmpty);
    expect(manifest.characters, isEmpty);
    expect(map.spatialScene!.camera.distance, 55);
    expect(map.spatialScene!.heightLevels.every((level) => level == 0), isTrue);
    expect(map.layers, isEmpty);
    expect(await Directory(p.join(projectRoot, 'assets')).exists(), isFalse);
    final opened = await _request(host, 'open', {'projectRoot': projectRoot});
    expect(opened.status, AuthoringResultStatus.success);
    for (final mode in GamePackageExportMode.values) {
      await expectLater(
          const CanonicalGamePackageExportService().build(
              projectRoot: Directory(projectRoot),
              profile: GamePackageExportProfile(
                  gameId: 'games.test.spatial',
                  gameVersion: '1.0.0',
                  title: '3D',
                  authorName: 'Test',
                  defaultLocale: 'fr',
                  supportedLocales: ['fr']),
              mode: mode),
          throwsA(isA<GamePackageExportException>()
              .having((e) => e.code, 'code', 'runtime3d.unsupported')));
    }
  });

  test('3D creation rejects 2D kits and 2D creation rejects a spatial camera',
      () async {
    final host = worker();
    for (final args in [
      {...request(), 'dimension': 'threeD'},
      {...request(), 'spatialCamera': SpatialCameraProfile().toJson()}
    ]) {
      final result =
          await _request(host, 'project_create_preview', {'request': args});
      expect(result.status, AuthoringResultStatus.failure);
      expect(await root.list().toList(), isEmpty);
    }
  });

  test(
      'JSONL preview is read-only and exact confirmation creates reopenable grid',
      () async {
    final host = worker();
    final described = await _request(host, 'describe', {});
    final commands = described.data['commands'] as List;
    expect(
        commands
            .where((entry) => (entry as Map)['actionId'] == 'project.create'),
        hasLength(2));
    final args = request();
    final preview =
        await _request(host, 'project_create_preview', {'request': args});
    expect(preview.status, AuthoringResultStatus.success);
    expect(preview.data['undoable'], false);
    expect(await root.list().toList(), isEmpty);
    final confirmation = preview.data['confirmation'];
    final changed = await _request(host, 'project_create', {
      'request': {...args, 'tileSize': 48},
      'confirmation': confirmation
    });
    expect(
        changed.error!.details['domainCode'], 'confirmation.binding_mismatch');
    expect(await root.list().toList(), isEmpty);
    final result = await _request(host, 'project_create',
        {'request': args, 'confirmation': confirmation});
    expect(result.status, AuthoringResultStatus.success);
    expect(result.data['tileWidth'], 32);
    final opened = await _request(
        host, 'open', {'projectRoot': result.data['projectPath']});
    expect(opened.status, AuthoringResultStatus.success);
    expect(await File(p.join(root.path, 'game', 'assets/starter.png')).exists(),
        true);
  });

  test(
      'parent outside configured narrow root and malformed request cannot write',
      () async {
    final host = worker();
    final outside = await Directory.systemTemp.createTemp('outside_creation_');
    addTearDown(() => outside.delete(recursive: true));
    final refused = await _request(host, 'project_create_preview',
        {'request': request(parent: outside.path)});
    expect(refused.error!.details['domainCode'],
        'workspace.path_outside_allowed_roots');
    final malformed = await _request(host, 'project_create_preview', {
      'request': {...request(), 'allowOverwrite': true}
    });
    expect(malformed.status, AuthoringResultStatus.failure);
    expect(await root.list().toList(), isEmpty);
    expect(await outside.list().toList(), isEmpty);
  });

  test('late existing destination is never replaced after preview', () async {
    final host = worker();
    final args = request();
    final preview =
        await _request(host, 'project_create_preview', {'request': args});
    final target = await Directory(p.join(root.path, 'game')).create();
    final original =
        await File(p.join(target.path, 'keep')).writeAsString('untouched');
    final result = await _request(host, 'project_create',
        {'request': args, 'confirmation': preview.data['confirmation']});
    expect(result.status, AuthoringResultStatus.failure);
    expect(await original.readAsString(), 'untouched');
    expect((await target.list().toList()).length, 1);
  });

  test('native parent whitespace is preserved by root authorization', () async {
    final selected = await Directory(p.join(root.path, ' selected ')).create();
    final homonym = await Directory(p.join(root.path, ' selected')).create();
    const reader = LocalProjectFileReader();
    final narrow = await WorkspacePolicy.create(
        allowedRootPaths: [selected.path], fileReader: reader);
    final bootstrap = ProjectCreationBootstrapApi(
        policy: narrow, creation: const LocalProjectCreationService());
    final args = Map<String, dynamic>.from(request(parent: selected.path));
    final preview = await bootstrap.preview(args);
    final receipt = await bootstrap.create(args,
        confirmation: preview['confirmation']! as String);
    expect(receipt['projectPath'],
        p.join(await selected.resolveSymbolicLinks(), 'game'));
    expect(await homonym.list().toList(), isEmpty);
    await expectLater(narrow.authorizeProjectRoot(homonym.path),
        throwsA(isA<WorkspaceAccessException>()));
  });

  test('confirmation expires and is consumed once', () async {
    var now = DateTime.utc(2026);
    final bootstrap = ProjectCreationBootstrapApi(
        policy: policy,
        creation: const LocalProjectCreationService(),
        clock: () => now);
    final args = Map<String, dynamic>.from(request());
    final preview = await bootstrap.preview(args);
    now = now.add(const Duration(minutes: 6));
    await expectLater(
        bootstrap.create(args,
            confirmation: preview['confirmation']! as String),
        throwsA(isA<AuthoringConfirmationException>()));
    expect(await root.list().toList(), isEmpty);
    final valid = await bootstrap.preview(args);
    await bootstrap.create(args,
        confirmation: valid['confirmation']! as String);
    await Directory(p.join(root.path, 'game')).delete(recursive: true);
    await expectLater(
        bootstrap.create(args, confirmation: valid['confirmation']! as String),
        throwsA(isA<AuthoringConfirmationException>()
            .having((error) => error.code, 'code', 'confirmation.used')));
    expect(await root.list().toList(), isEmpty);
  });

  test('native creation failure is enveloped without disclosing paths',
      () async {
    final host = worker(
        service: LocalProjectCreationService(checkpoint: (phase, path) async {
      if (phase == ProjectCreationCheckpoint.beforeReservation) {
        throw FileSystemException('native failure', path);
      }
    }));
    final args = request();
    final preview =
        await _request(host, 'project_create_preview', {'request': args});
    final failure = await _request(host, 'project_create',
        {'request': args, 'confirmation': preview.data['confirmation']});
    expect(failure.error!.details['domainCode'], 'project.creation_failed');
    expect(jsonEncode(failure.toJson()), isNot(contains(root.path)));
    expect(await root.list().toList(), isEmpty);
  });

  test('worker timeout abandons preparation before any write after release',
      () async {
    final held = Completer<void>();
    final entered = Completer<void>();
    final cleaned = Completer<void>();
    final service =
        LocalProjectCreationService(checkpoint: (phase, path) async {
      if (phase == ProjectCreationCheckpoint.beforeReservation) {
        entered.complete();
        await held.future;
        cleaned.complete();
      }
    });
    final bootstrap =
        ProjectCreationBootstrapApi(policy: policy, creation: service);
    final args = Map<String, dynamic>.from(request());
    final preview = await bootstrap.preview(args);
    final host = JsonlWorker(
        api: read,
        projectCreation: bootstrap,
        commandTimeout: const Duration(seconds: 1));
    final pending = _request(host, 'project_create',
        {'request': args, 'confirmation': preview['confirmation']});
    await entered.future;
    final timedOut = await pending;
    expect(timedOut.error!.details['domainCode'], 'worker.timeout');
    expect(timedOut.error!.retryable, false);
    held.complete();
    await cleaned.future;
    await Future<void>.value();
    expect(await root.list().toList(), isEmpty);
  });
}

Future<AuthoringResult> _request(
    JsonlWorker worker, String command, Map<String, Object?> args) async {
  final line = await worker.processLine(
      jsonEncode({'id': 'creation-test', 'command': command, 'args': args}));
  return AuthoringResult.fromJson(jsonDecode(line) as Map<String, dynamic>);
}
