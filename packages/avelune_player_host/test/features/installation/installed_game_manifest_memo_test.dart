import 'dart:async';
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:avelune_player_host/features/installation/data/repositories/installed_game_manifest_memo.dart';
import 'package:avelune_player_host/avelune_player_host.dart';
import 'package:test/test.dart';

import '../../support/game_package_fixture.dart';

void main() {
  late Directory root;
  late Directory supportRoot;
  late InstalledGame game;
  late File manifestFile;
  late GamePackageManifest manifest;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('installed-manifest-memo-');
    supportRoot = Directory(p.join(root.path, 'PokeMap'));
    final package = await writeTestPackage(
      Directory(p.join(root.path, 'pkg')),
      extraFiles: 3,
    );
    game = (await GamePackageInstaller(
      supportRoot: supportRoot,
      inspector: GamePackageInspector(
        hostCompatibility: testHostCompatibility(),
      ),
      availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
      loadSmoke: (_, _) async {},
      prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
    ).install(package, source: GamePackageInstallSource.localFile)).game;
    manifestFile = File(
      p.join(
        supportRoot.path,
        'games',
        game.gameId,
        'versions',
        game.current.gameVersion.toString(),
        'game-manifest.json',
      ),
    );
    manifest = const GamePackageManifestCodec().decodeUtf8(
      manifestFile.readAsBytesSync(),
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<GamePackageManifest> decodeCounting(
    List<String> decoded,
    String path,
  ) async {
    decoded.add(path);
    return const GamePackageManifestCodec().decodeUtf8(
      await File(path).readAsBytes(),
    );
  }

  void rewriteKeepingSizeAndModified(List<int> Function(List<int>) change) {
    final modified = manifestFile.lastModifiedSync();
    manifestFile.writeAsBytesSync(
      change(manifestFile.readAsBytesSync()),
      flush: true,
    );
    manifestFile.setLastModifiedSync(modified);
  }

  group('InstalledGameManifestMemo', () {
    test('decodes an unchanged manifest once', () async {
      final memo = InstalledGameManifestMemo();
      final decoded = <String>[];
      final first = await memo.read(
        manifestFile.path,
        (path) => decodeCounting(decoded, path),
      );
      final second = await memo.read(
        manifestFile.path,
        (path) => decodeCounting(decoded, path),
      );
      expect(decoded, [manifestFile.path]);
      expect(identical(first, second), isTrue);
      expect(second.toJson(), manifest.toJson());
    });

    test('decodes again once the manifest file is rewritten', () async {
      final memo = InstalledGameManifestMemo();
      final decoded = <String>[];
      await memo.read(
        manifestFile.path,
        (path) => decodeCounting(decoded, path),
      );
      rewriteKeepingSizeAndModified((bytes) => bytes);
      await memo.read(
        manifestFile.path,
        (path) => decodeCounting(decoded, path),
      );
      expect(decoded, hasLength(2));
    });

    test('shares one decode between concurrent readers', () async {
      final memo = InstalledGameManifestMemo();
      final release = Completer<void>();
      var decodes = 0;
      Future<GamePackageManifest> decode(String path) async {
        decodes++;
        await release.future;
        return manifest;
      }

      final first = memo.read(manifestFile.path, decode);
      final second = memo.read(manifestFile.path, decode);
      release.complete();
      expect(identical(await first, await second), isTrue);
      expect(decodes, 1);
    });

    test('does not remember a failed decode', () async {
      final memo = InstalledGameManifestMemo();
      await expectLater(
        memo.read(
          manifestFile.path,
          (_) async => throw const FormatException('broken'),
        ),
        throwsFormatException,
      );
      final decoded = <String>[];
      await memo.read(
        manifestFile.path,
        (path) => decodeCounting(decoded, path),
      );
      expect(decoded, hasLength(1));
      expect(memo.peek(manifestFile.path), isNotNull);
    });

    test('keeps only the most recent manifests', () async {
      final memo = InstalledGameManifestMemo(capacity: 1);
      final other = File(p.join(root.path, 'other-manifest.json'))
        ..writeAsBytesSync(manifestFile.readAsBytesSync());
      await memo.read(manifestFile.path, (_) async => manifest);
      await memo.read(other.path, (_) async => manifest);
      expect(memo.peek(manifestFile.path), isNull);
      expect(memo.peek(other.path), isNotNull);
    });

    test(
      'a known manifest is reused only while its file is unchanged',
      () async {
        final known = InstalledGameDecodedManifest(
          InstalledGameManifestStamp.of(manifestFile.path),
          manifest,
        );
        final decoded = <String>[];
        final reused = await readInstalledGameManifestOnce(
          manifestFile.path,
          known: known,
          decode: (path) => decodeCounting(decoded, path),
        );
        expect(identical(reused, known), isTrue);
        rewriteKeepingSizeAndModified((bytes) => bytes);
        final fresh = await readInstalledGameManifestOnce(
          manifestFile.path,
          known: known,
          decode: (path) => decodeCounting(decoded, path),
        );
        expect(identical(fresh, known), isFalse);
        expect(decoded, hasLength(1));
      },
    );
  });

  group('verification after a healthy read', () {
    Future<InstalledGameVerification> verify(
      InstalledGameVerificationDepth depth,
    ) => const InstalledGameVerifier().verify(
      supportRoot: supportRoot,
      gameId: game.gameId,
      pointer: game.current,
      receiptFileName: game.currentVersion.receiptFileName,
      depth: depth,
    );

    for (final depth in InstalledGameVerificationDepth.values) {
      test('${depth.name} depth rejects a manifest rewritten with the same '
          'size and modification time', () async {
        expect(
          (await verify(InstalledGameVerificationDepth.structure)).isHealthy,
          isTrue,
        );
        expect(
          (await verify(InstalledGameVerificationDepth.content)).isHealthy,
          isTrue,
        );
        rewriteKeepingSizeAndModified((bytes) {
          final changed = [...bytes];
          changed[0] = 0x20;
          return changed;
        });
        expect(
          (await verify(depth)).code,
          InstalledGameVerificationCode.manifestInvalid,
        );
      });
    }
  });
}
