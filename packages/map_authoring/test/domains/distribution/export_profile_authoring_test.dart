import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'context supports a spatial start map without a legacy spawn and detects its changes',
      () async {
    final root = await fixture();
    addTearDown(() => root.delete(recursive: true));
    final project = ProjectManifest(
        name: 'Spatial profile',
        version: ProjectVersion.v9,
        maps: const [
          ProjectMapEntry(
              id: 'start', name: 'Start', relativePath: 'start.json')
        ],
        tilesets: const [],
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        newGame:
            const ProjectNewGameConfig(enabled: true, startMapId: 'start'));
    final map = MapData(
        id: 'start',
        name: 'Start',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        spatialScene: MapSpatialScene(width: 4, depth: 4));
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    final mapFile = File('${root.path}/start.json');
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    final store = GamePackageExportProfileStore(projectRoot: root);
    final checked = await store.validate(profile());
    await mapFile.writeAsString(
        jsonEncode(map.copyWith(name: 'Changed spatial start').toJson()));
    await expectLater(
        store.save(profile(),
            expectedProfileRevision: checked.profileRevision,
            expectedContextRevision: checked.contextRevision),
        throwsA(isA<GamePackageExportException>()
            .having((e) => e.code, 'code', 'exportProfileStale')));
    await store.save(profile());
    expect((await store.read()).profile, profile());
  });
  for (final lockKind in ['link', 'directory', 'fifo']) {
    test('rejects $lockKind at the exact profile lock before opening it',
        () async {
      final root = await fixture();
      addTearDown(() => root.delete(recursive: true));
      final outside = await fixture();
      addTearDown(() => outside.delete(recursive: true));
      await Directory('${root.path}/.pokemap').create();
      final path = '${root.path}/.pokemap/export-profile-v1.json.lock';
      final sentinel = File('${outside.path}/sentinel');
      await sentinel.writeAsString('Untouched');
      if (lockKind == 'link') {
        await Link(path).create(sentinel.path);
      } else if (lockKind == 'directory') {
        await Directory(path).create();
      } else {
        expect((await Process.run('mkfifo', [path])).exitCode, 0);
      }
      final store = GamePackageExportProfileStore(projectRoot: root);
      await expectLater(
          store.save(profile()).timeout(const Duration(seconds: 2)),
          throwsA(isA<GamePackageExportException>()
              .having((e) => e.code, 'code', 'exportProfilePathUnsafe')));
      expect(await sentinel.readAsString(), 'Untouched');
      expect(await store.profileFile.exists(), isFalse);
    }, skip: lockKind == 'fifo' && Platform.isWindows);
  }
  for (final transport in ['direct', 'jsonl']) {
    test(
        '$transport validates, persists, reloads and rejects stale profile bytes',
        () async {
      final root = await fixture();
      addTearDown(() => root.delete(recursive: true));
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path],
          fileReader: const LocalProjectFileReader());
      final api = LocalGamePackageExportProfileApi(policy: policy);
      final handles = WorkspaceHandleStore();
      final worker = JsonlWorker(
          api: AuthoringReadApi(
              openService: ProjectOpenService(
                  policy: policy,
                  fileReader: const LocalProjectFileReader(),
                  handles: handles),
              snapshotLoader: ProjectSnapshotLoader(handles: handles)),
          exportProfiles: api);
      addTearDown(worker.close);
      Future<AuthoringResult> wire(
              String command, Map<String, Object?> args) async =>
          AuthoringResult.fromJson(
              jsonDecode(await worker.processLine(jsonEncode({
            'id': command,
            'command': command,
            'args': {
              if (command != 'describe') 'projectRoot': root.path,
              ...args
            }
          }))));
      final validated = transport == 'direct'
          ? (await api.validate(projectRoot: root.path, profile: profile()))
              .toJson()
          : (await wire('game_export_profile_validate',
                  {'profile': profile().toJson()}))
              .data;
      expect(await Directory('${root.path}/.pokemap').exists(), isFalse);
      final expected = {
        'expectedProfileRevision': validated['profileRevision'],
        'expectedContextRevision': validated['contextRevision']
      };
      if (transport == 'direct') {
        await api.save(
            projectRoot: root.path,
            profile: profile(),
            expectedProfileRevision:
                expected['expectedProfileRevision']! as String,
            expectedContextRevision:
                expected['expectedContextRevision']! as String);
      } else {
        expect(
            (await wire('game_export_profile_save',
                    {'profile': profile().toJson(), ...expected}))
                .status,
            AuthoringResultStatus.success);
      }
      final store = GamePackageExportProfileStore(projectRoot: root);
      expect(await store.load(), profile());
      final bytes = await store.profileFile.readAsBytes();
      if (transport == 'direct') {
        await expectLater(
            api.save(
                projectRoot: root.path,
                profile: profile().copyWith(title: 'Stale'),
                expectedProfileRevision: 'absent',
                expectedContextRevision:
                    validated['contextRevision']! as String),
            throwsA(isA<GamePackageExportException>()
                .having((e) => e.code, 'code', 'exportProfileStale')));
      } else {
        final rejected = await wire('game_export_profile_save', {
          'profile': profile().copyWith(title: 'Stale').toJson(),
          ...expected
        });
        expect(rejected.status, AuthoringResultStatus.failure);
        expect(rejected.error?.details['domainCode'], 'exportProfileStale');
        final described = await wire('describe', {});
        expect(
            (described.data['commands'] as List).where((entry) =>
                (entry['id'] as String).startsWith('game_export_profile_')),
            hasLength(3));
      }
      expect(await store.profileFile.readAsBytes(), bytes);
      expect((await api.read(projectRoot: root.path)).profile, profile());
    });
  }

  for (final change in ['manifest', 'reference', 'unrelated']) {
    test('context revision detects $change changes with a bounded scope',
        () async {
      final root = await fixture();
      addTearDown(() => root.delete(recursive: true));
      final legal = File('${root.path}/license.txt');
      await legal.writeAsString('Before');
      final candidate = profile().copyWith(licensePath: 'license.txt');
      final store = GamePackageExportProfileStore(projectRoot: root);
      final before = await store.validate(candidate);
      if (change == 'manifest') {
        await File('${root.path}/project.json').writeAsString(jsonEncode(
            const ProjectManifest(name: 'Changed', maps: [], tilesets: [])
                .toJson()));
      } else {
        await File(
                '${root.path}/${change == 'reference' ? 'license.txt' : 'unrelated.bin'}')
            .writeAsString('Concurrent bytes');
      }
      final save = store.save(candidate,
          expectedProfileRevision: before.profileRevision,
          expectedContextRevision: before.contextRevision);
      if (change == 'unrelated') {
        await save;
        expect(await store.load(), candidate);
      } else {
        await expectLater(
            save,
            throwsA(isA<GamePackageExportException>()
                .having((e) => e.code, 'code', 'exportProfileStale')));
        expect(await store.profileFile.exists(), isFalse);
      }
    });
  }

  test('competing canonical writers preserve exactly one successful CAS',
      () async {
    final root = await fixture();
    addTearDown(() => root.delete(recursive: true));
    final store = GamePackageExportProfileStore(projectRoot: root);
    final before = await store.validate(profile());
    final results = await Future.wait([
      for (final title in ['One', 'Two'])
        store
            .save(profile().copyWith(title: title),
                expectedProfileRevision: before.profileRevision,
                expectedContextRevision: before.contextRevision)
            .then<Object>((saved) => saved, onError: (Object e) => e)
    ]);
    expect(results.whereType<GamePackageExportProfileSnapshot>(), hasLength(1));
    expect(results.whereType<GamePackageExportException>().single.code,
        'exportProfileStale');
    expect(
        (await store.load())!.title,
        results
            .whereType<GamePackageExportProfileSnapshot>()
            .single
            .profile!
            .title);
    expect(
        (await store.profileFile.parent.list().toList()).where((entry) =>
            entry.path.endsWith('.tmp') ||
            (entry is Directory &&
                entry.path.split('/').last.startsWith('export-profile-'))),
        isEmpty);
  });

  test('profile API refuses projects outside its configured root', () async {
    final root = await fixture();
    final outside = await fixture();
    addTearDown(() => root.delete(recursive: true));
    addTearDown(() => outside.delete(recursive: true));
    final api = await LocalGamePackageExportProfileApi.create(
        allowedProjectRoots: [root.path]);
    await expectLater(
        api.validate(projectRoot: outside.path, profile: profile()),
        throwsA(isA<WorkspaceAccessException>().having(
            (e) => e.code, 'code', 'workspace.path_outside_allowed_roots')));
    expect(await Directory('${outside.path}/.pokemap').exists(), isFalse);
  });

  test('profile API refuses a dangling or live symbolic sidecar file',
      () async {
    final root = await fixture();
    addTearDown(() => root.delete(recursive: true));
    final outside = await fixture();
    addTearDown(() => outside.delete(recursive: true));
    await Directory('${root.path}/.pokemap').create();
    final link = Link('${root.path}/.pokemap/export-profile-v1.json');
    final target = File('${outside.path}/profile.json');
    await link.create(target.path);
    final store = GamePackageExportProfileStore(projectRoot: root);
    await expectLater(
        store.save(profile()), throwsA(isA<GamePackageExportException>()));
    await target.writeAsString('Concurrent outside bytes');
    await expectLater(store.read(), throwsA(isA<GamePackageExportException>()));
    expect(await target.readAsString(), 'Concurrent outside bytes');
  });

  test('profile references cannot escape through a symbolic asset', () async {
    final root = await fixture();
    final outside = await fixture();
    addTearDown(() => root.delete(recursive: true));
    addTearDown(() => outside.delete(recursive: true));
    await Link('${root.path}/license.txt')
        .create('${outside.path}/project.json');
    await expectLater(
        GamePackageExportProfileStore(projectRoot: root)
            .save(profile().copyWith(licensePath: 'license.txt')),
        throwsA(isA<GamePackageExportException>()
            .having((e) => e.code, 'code', 'exportProfileReferenceInvalid')));
  });

  test('profile persistence rejects a missing declared reference', () async {
    final root = await fixture();
    addTearDown(() => root.delete(recursive: true));
    final store = GamePackageExportProfileStore(projectRoot: root);
    await expectLater(
      store.save(profile().copyWith(licensePath: 'legal/missing.txt')),
      throwsA(isA<GamePackageExportException>()),
    );
    expect(await store.profileFile.exists(), isFalse);
  });

  test('profile persistence refuses a symbolic sidecar directory', () async {
    final root = await fixture();
    final outside = await Directory.systemTemp.createTemp('profile-outside-');
    addTearDown(() => root.delete(recursive: true));
    addTearDown(() => outside.delete(recursive: true));
    await Link('${root.path}/.pokemap').create(outside.path);
    await expectLater(
      GamePackageExportProfileStore(projectRoot: root).save(profile()),
      throwsA(isA<GamePackageExportException>()),
    );
    expect(await outside.list().isEmpty, isTrue);
  });
}

Future<Directory> fixture() async {
  final root =
      await Directory.systemTemp.createTemp('export-profile-authoring-');
  await File('${root.path}/project.json').writeAsString(jsonEncode(
    const ProjectManifest(name: 'Profile fixture', maps: [], tilesets: [])
        .toJson(),
  ));
  return root;
}

GamePackageExportProfile profile() => GamePackageExportProfile(
      gameId: 'games.example.profile',
      gameVersion: '1.0.0',
      title: 'Profile',
      authorName: 'Yoahn',
      defaultLocale: 'fr',
      supportedLocales: ['fr'],
    );
