import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  late Directory temporary;
  late Directory versionRoot;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('package-assets-');
    versionRoot = Directory(p.join(temporary.path, 'version'));
    await Directory(p.join(versionRoot.path, 'project'))
        .create(recursive: true);
    await Directory(p.join(versionRoot.path, 'presentation'))
        .create(recursive: true);
    await File(p.join(versionRoot.path, 'project', 'project.json'))
        .writeAsString('{}');
    await File(p.join(versionRoot.path, 'presentation', 'cover.png'))
        .writeAsBytes(<int>[1, 2, 3]);
  });

  tearDown(() async {
    if (await temporary.exists()) {
      await temporary.delete(recursive: true);
    }
  });

  test('resolves only regular inventoried files below the version root',
      () async {
    final resolver = await PackageAssetResolver.create(
      versionRoot: versionRoot,
      manifest: _manifest(),
    );

    final project = await resolver.resolveFile('project/project.json');
    final cover = await resolver.resolveFile('presentation/cover.png');

    final canonicalRoot = await versionRoot.resolveSymbolicLinks();
    expect(await project.resolveSymbolicLinks(), startsWith(canonicalRoot));
    expect(await cover.readAsBytes(), <int>[1, 2, 3]);
    expect(resolver.reference('project/project.json').packagePath,
        'project/project.json');
  });

  test('rejects traversal, absolute, Windows and non-inventoried paths',
      () async {
    final resolver = await PackageAssetResolver.create(
      versionRoot: versionRoot,
      manifest: _manifest(),
    );

    for (final hostile in <String>[
      '../outside.txt',
      '/etc/passwd',
      r'C:\Windows\win.ini',
      r'project\project.json',
      'project/../project/project.json',
      'project/not-in-manifest.json',
    ]) {
      await expectLater(
        Future<File>.sync(() => resolver.resolveFile(hostile)),
        throwsA(isA<PackageAssetResolutionException>()),
        reason: hostile,
      );
    }
  });

  test('rejects final and intermediate symlinks', () async {
    if (Platform.isWindows) return;
    final outside = File(p.join(temporary.path, 'outside.txt'));
    await outside.writeAsString('secret');
    final finalLink =
        Link(p.join(versionRoot.path, 'presentation', 'cover.png'));
    await File(finalLink.path).delete();
    await finalLink.create(outside.path);

    final resolver = await PackageAssetResolver.create(
      versionRoot: versionRoot,
      manifest: _manifest(),
    );
    await expectLater(
      resolver.resolveFile('presentation/cover.png'),
      throwsA(
        isA<PackageAssetResolutionException>().having(
          (error) => error.code,
          'code',
          PackageAssetResolutionCode.symbolicLink,
        ),
      ),
    );

    await finalLink.delete();
    await Directory(p.join(versionRoot.path, 'presentation'))
        .delete(recursive: true);
    await Link(p.join(versionRoot.path, 'presentation')).create(temporary.path);
    await expectLater(
      resolver.resolveFile('presentation/cover.png'),
      throwsA(isA<PackageAssetResolutionException>()),
    );
  });

  test('rejects a version root that is itself a symlink', () async {
    if (Platform.isWindows) return;
    final link = Link(p.join(temporary.path, 'linked-version'));
    await link.create(versionRoot.path);

    await expectLater(
      PackageAssetResolver.create(
        versionRoot: Directory(link.path),
        manifest: _manifest(),
      ),
      throwsA(
        isA<PackageAssetResolutionException>().having(
          (error) => error.code,
          'code',
          PackageAssetResolutionCode.unsafeRoot,
        ),
      ),
    );
  });
}

GamePackageManifest _manifest() => GamePackageManifest(
      packageFormat: 1,
      gameId: 'org.example.adventure',
      gameVersion: Version.parse('1.0.0'),
      title: 'Adventure',
      author: const GamePackageParty(name: 'Example'),
      compatibility: GamePackageCompatibility(
        minHubVersion: Version.parse('1.0.0'),
        runtimeApiExpression: '^1.0.0',
        projectFormat: 'v2',
        saveFormat: 1,
        compatibilityId: 'story-v1',
        requiredCapabilities: const <String>[],
      ),
      locales: GamePackageLocales(
        defaultLocale: 'fr-FR',
        supported: const <String>['fr-FR'],
      ),
      content: GamePackageContent(
        fileCount: 2,
        totalBytes: 5,
        treeSha256:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        files: <GamePackageFileEntry>[
          GamePackageFileEntry(
            path: 'project/project.json',
            size: 2,
            sha256:
                'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          ),
          GamePackageFileEntry(
            path: 'presentation/cover.png',
            size: 3,
            sha256:
                'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
          ),
        ],
      ),
    );
