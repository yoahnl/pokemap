import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('GameLibraryCodec', () {
    const codec = GameLibraryCodec();

    test('round-trips a canonical multigame library', () {
      final library = GameLibrary(
        revision: 7,
        updatedAt: DateTime.utc(2026, 7, 25, 12),
        games: <InstalledGame>[
          _game(
            gameId: 'games.example.second',
            title: 'Same title',
            version: '2.0.0',
            tree: _hash('2'),
          ),
          _game(
            gameId: 'games.example.first',
            title: 'Same title',
            version: '1.0.0',
            tree: _hash('1'),
          ),
        ],
      );

      final bytes = codec.encodeCanonicalUtf8(library);
      final decoded = codec.decodeUtf8(bytes);

      expect(
        decoded.games.map((game) => game.gameId),
        <String>['games.example.first', 'games.example.second'],
      );
      expect(codec.encodeCanonicalUtf8(decoded), bytes);
      expect(decoded.revision, 7);
    });

    test('rejects unknown fields and inconsistent current pointers', () {
      final valid = _library().toJson();

      expect(
        () => codec.decodeJson(<String, Object?>{
          ...valid,
          'unexpected': true,
        }),
        throwsA(
          isA<GameLibraryFormatException>()
              .having((error) => error.code, 'code', 'unknownField'),
        ),
      );

      final game = Map<String, Object?>.from(
        (valid['games'] as List<Object?>).single! as Map,
      );
      game['current'] = <String, Object?>{
        'gameVersion': '9.9.9',
        'treeSha256': _hash('9'),
      };
      expect(
        () => codec.decodeJson(<String, Object?>{
          ...valid,
          'games': <Object?>[game],
        }),
        throwsA(
          isA<GameLibraryFormatException>()
              .having((error) => error.code, 'code', 'unknownCurrentVersion'),
        ),
      );
    });

    test('rejects duplicate game identities and duplicate installed versions',
        () {
      final game = _game(
        gameId: 'games.example.library',
        title: 'Library',
        version: '1.0.0',
        tree: _hash('1'),
      ).toJson();

      expect(
        () => codec.decodeJson(<String, Object?>{
          'schemaVersion': 1,
          'revision': 1,
          'updatedAt': '2026-07-25T12:00:00.000Z',
          'games': <Object?>[game, game],
        }),
        throwsA(
          isA<GameLibraryFormatException>()
              .having((error) => error.code, 'code', 'duplicateGame'),
        ),
      );

      final duplicateVersion = Map<String, Object?>.from(game);
      duplicateVersion['versions'] = <Object?>[
        ...(game['versions']! as List<Object?>),
        ...(game['versions']! as List<Object?>),
      ];
      expect(
        () => codec.decodeJson(<String, Object?>{
          'schemaVersion': 1,
          'revision': 1,
          'updatedAt': '2026-07-25T12:00:00.000Z',
          'games': <Object?>[duplicateVersion],
        }),
        throwsA(
          isA<GameLibraryFormatException>()
              .having((error) => error.code, 'code', 'duplicateVersion'),
        ),
      );
    });
  });
}

GameLibrary _library() => GameLibrary(
      revision: 1,
      updatedAt: DateTime.utc(2026, 7, 25, 12),
      games: <InstalledGame>[
        _game(
          gameId: 'games.example.library',
          title: 'Library',
          version: '1.0.0',
          tree: _hash('1'),
        ),
      ],
    );

InstalledGame _game({
  required String gameId,
  required String title,
  required String version,
  required String tree,
}) {
  final installed = InstalledGameVersion(
    gameVersion: Version.parse(version),
    treeSha256: tree,
    installedAt: DateTime.utc(2026, 7, 25, 11),
    receiptFileName: '$version-$tree.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return InstalledGame(
    gameId: gameId,
    title: title,
    description: 'Description',
    authorName: 'Example',
    defaultLocale: 'fr',
    supportedLocales: const <String>['fr'],
    current: InstalledGamePointer(
      gameVersion: installed.gameVersion,
      treeSha256: tree,
    ),
    versions: <InstalledGameVersion>[installed],
  );
}

String _hash(String character) => character * 64;
