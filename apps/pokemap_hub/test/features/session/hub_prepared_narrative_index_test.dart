import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/features/session/data/repositories/hub_prepared_narrative_index.dart';
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../../support/game_package_fixture.dart';

void main() {
  late Directory root;
  late Directory version;
  late GamePackageManifest manifest;
  late HubPreparedNarrativeIndex store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('prepared-narrative-');
    version = await Directory('${root.path}/version').create();
    final project = ProjectManifest(
      name: 'Prepared',
      maps: const [
        ProjectMapEntry(
          id: 'field',
          name: 'Field',
          relativePath: 'maps/field.json',
        ),
      ],
      tilesets: const [],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.dualRead,
        records: const [],
        legacyClaims: const [],
      ),
    );
    final map = const MapData(
      id: 'field',
      name: 'Field',
      size: GridSize(width: 4, height: 4),
    );
    final payload = <String, List<int>>{
      'project/project.json': utf8.encode(jsonEncode(project.toJson())),
      'project/maps/field.json': utf8.encode(jsonEncode(map.toJson())),
    };
    for (final entry in payload.entries) {
      final file = File('${version.path}/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    manifest = GamePackageManifest(
      packageFormat: 1,
      gameId: 'games.example.prepared',
      gameVersion: Version.parse('1.0.0'),
      title: 'Prepared',
      author: const GamePackageParty(name: 'Test'),
      compatibility: GamePackageCompatibility(
        minHubVersion: Version.parse('1.0.0'),
        runtimeApiExpression: '>=1.0.0 <2.0.0',
        projectFormat: 'v8',
        saveFormat: 1,
        compatibilityId: 'main',
        requiredCapabilities: const ['map@1'],
      ),
      locales: GamePackageLocales(defaultLocale: 'fr', supported: const ['fr']),
      content: const GamePackageInventoryBuilder().build(payload),
    );
    store = HubPreparedNarrativeIndex(
      supportRoot: Directory('${root.path}/support'),
    );
  });

  tearDown(() => root.delete(recursive: true));

  test('installation prepares a reusable narrative corpus outside the immutable version', () async {
    expect(await store.load(manifest), isNull);
    await store.prepare(versionRoot: version, manifest: manifest);
    final maps = (await store.load(manifest))!;
    expect(maps.map((map) => map.id), ['field']);
    expect(
      maps.single.sourceMapFingerprint,
      'sha256:${narrativeEventCanonicalSha256(const MapData(id: 'field', name: 'Field', size: GridSize(width: 4, height: 4)).toJson())}',
    );
    expect(
      await version
          .list(recursive: true)
          .where((entity) => entity is File)
          .length,
      2,
    );
  });

  test('corrupted prepared data is rejected before decoding', () async {
    await store.prepare(versionRoot: version, manifest: manifest);
    final file = store.fileFor(manifest);
    final bytes = await file.readAsBytes();
    bytes[bytes.length - 1] ^= 1;
    await file.writeAsBytes(bytes);
    expect(await store.load(manifest), isNull);
  });

  test('an artifact from another installation key cannot be used', () async {
    await store.prepare(versionRoot: version, manifest: manifest);
    final other = HubPreparedNarrativeIndex(
      supportRoot: Directory('${root.path}/other'),
    );
    await other.prepare(versionRoot: version, manifest: manifest);
    final target = other.fileFor(manifest);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(await store.fileFor(manifest).readAsBytes());
    expect(await other.load(manifest), isNull);
  });

  test(
    'changed source bytes cannot be compiled under the verified inventory',
    () async {
      final file = File('${version.path}/project/maps/field.json');
      await file.writeAsString(
        (await file.readAsString()).replaceFirst('Field', 'Other'),
      );
      await expectLater(
        store.prepare(versionRoot: version, manifest: manifest),
        throwsFormatException,
      );
      expect(await store.load(manifest), isNull);
    },
  );

  test('a symbolic link cannot replace the prepared artifact', () async {
    await store.prepare(versionRoot: version, manifest: manifest);
    final file = store.fileFor(manifest);
    final bytes = await file.readAsBytes();
    final outside = File('${root.path}/outside');
    await outside.writeAsBytes(bytes);
    await file.delete();
    await Link(file.path).create(outside.path);
    expect(await store.load(manifest), isNull);
  });

  test(
    'a truncated cache key can be regenerated from verified sources',
    () async {
      await store.prepare(versionRoot: version, manifest: manifest);
      await File('${store.fileFor(manifest).parent.path}/.key')
          .writeAsBytes([1]);
      expect(await store.load(manifest), isNull);
      await store.prepare(versionRoot: version, manifest: manifest);
      expect((await store.load(manifest))!.single.id, 'field');
    },
  );

  test(
    'an unavailable derived cache does not block installation of a valid game',
    () async {
      final built = const GamePackageBuilder().build(
        manifest: manifest,
        payloadFiles: {
          'project/project.json': await File(
            '${version.path}/project/project.json',
          ).readAsBytes(),
          'project/maps/field.json': await File(
            '${version.path}/project/maps/field.json',
          ).readAsBytes(),
        },
      );
      final package = File('${root.path}/prepared.avelunegame');
      await package.writeAsBytes(built.packageBytes);
      final support = Directory('${root.path}/blocked-support');
      await support.create();
      await File('${support.path}/runtime-narrative').writeAsString('blocked');
      final installer = GamePackageInstaller(
        supportRoot: support,
        inspector: GamePackageInspector(
          hostCompatibility: testHostCompatibility(),
        ),
        availableDiskBytes: (_) async => 1 << 40,
        loadSmoke: (_, _) async {},
        prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
      );
      final result = await installer.install(
        package,
        source: GamePackageInstallSource.localFile,
      );
      expect(result.receipt.gameId, manifest.gameId);
      expect(
        await File('${support.path}/games/${manifest.gameId}/current.json')
            .exists(),
        isTrue,
      );
    },
  );
  test('cancellation after smoke keeps its diagnostic and rolls back after index preparation', () async {
    final built = const GamePackageBuilder().build(
      manifest: manifest,
      payloadFiles: {
        'project/project.json': await File(
          '${version.path}/project/project.json',
        ).readAsBytes(),
        'project/maps/field.json': await File(
          '${version.path}/project/maps/field.json',
        ).readAsBytes(),
      },
    );
    final package = File('${root.path}/cancelled.avelunegame');
    await package.writeAsBytes(built.packageBytes);
    final cancellation = GameInstallCancellationToken();
    final progress = <GameInstallProgress>[];
    final installer = GamePackageInstaller(
      supportRoot: store.supportRoot,
      inspector: GamePackageInspector(
        hostCompatibility: testHostCompatibility(),
      ),
      availableDiskBytes: (_) async => 1 << 40,
      loadSmoke: (_, _) async => cancellation.cancel(),
      prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
    );
    await expectLater(
      installer.install(
        package,
        source: GamePackageInstallSource.localFile,
        cancellationToken: cancellation,
        onProgress: progress.add,
      ),
      throwsA(
        isA<GameInstallationException>()
            .having(
              (error) => error.diagnostic.code,
              'code',
              GameInstallationErrorCode.cancelled,
            )
            .having(
              (error) => error.diagnostic.stage,
              'stage',
              GameInstallStage.smokeLoading,
            ),
      ),
    );
    expect(await store.fileFor(built.manifest).exists(), isTrue);
    expect(progress.last.stage, GameInstallStage.cancelled);
    expect(progress.last.cancellable, isFalse);
    final gameRoot = '${store.supportRoot.path}/games/${manifest.gameId}';
    expect(await File('$gameRoot/current.json').exists(), isFalse);
    expect(await Directory('$gameRoot/versions').exists(), isFalse);
    expect(
      (await GameLibraryStore(
        supportRoot: store.supportRoot,
      ).load()).library.games,
      isEmpty,
    );
  });
}
