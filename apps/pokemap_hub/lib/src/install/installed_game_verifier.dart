import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import '../library/game_library.dart';

final class GameCurrentPointerCodec {
  const GameCurrentPointerCodec();

  List<int> encode({
    required String gameId,
    required InstalledGamePointer pointer,
  }) {
    GameIdentity.validateGameId(gameId);
    GameIdentity.validateSemver(
      pointer.gameVersion.toString(),
      path: r'$.gameVersion',
    );
    if (!_sha256.hasMatch(pointer.treeSha256)) {
      throw const FormatException('Invalid current pointer tree hash.');
    }
    return CanonicalJson.encodeUtf8(<String, Object?>{
      'schemaVersion': 1,
      'gameId': gameId,
      ...pointer.toJson(),
    });
  }

  InstalledGamePointer decode(
    List<int> bytes, {
    required String expectedGameId,
  }) {
    GameIdentity.validateGameId(expectedGameId);
    late final String source;
    late final Object? value;
    try {
      source = utf8.decode(bytes, allowMalformed: false);
      value = jsonDecode(source);
    } on FormatException {
      throw const FormatException('Invalid current pointer JSON.');
    }
    if (value is! Map ||
        value.length != 4 ||
        value['schemaVersion'] != 1 ||
        value['gameId'] != expectedGameId ||
        value['gameVersion'] is! String ||
        value['treeSha256'] is! String) {
      throw const FormatException('Invalid current pointer fields.');
    }
    final versionSource = value['gameVersion']! as String;
    final tree = value['treeSha256']! as String;
    if (!_strictSemVer.hasMatch(versionSource) || !_sha256.hasMatch(tree)) {
      throw const FormatException('Invalid current pointer identity.');
    }
    final pointer = InstalledGamePointer(
      gameVersion: Version.parse(versionSource),
      treeSha256: tree,
    );
    if (source !=
        utf8.decode(encode(gameId: expectedGameId, pointer: pointer))) {
      throw const FormatException('Current pointer is not canonical.');
    }
    return pointer;
  }

  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');
  static final RegExp _strictSemVer = RegExp(
    r'^(0|[1-9][0-9]*)\.'
    r'(0|[1-9][0-9]*)\.'
    r'(0|[1-9][0-9]*)'
    r'(?:-((?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)'
    r'(?:\.(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*))*))?'
    r'(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$',
  );
}

final class GameCurrentPointerStore {
  GameCurrentPointerStore({
    required this.supportRoot,
    this.codec = const GameCurrentPointerCodec(),
  });

  final Directory supportRoot;
  final GameCurrentPointerCodec codec;

  Future<InstalledGamePointer> read(String gameId) async {
    GameIdentity.validateGameId(gameId);
    final file =
        File(p.join(supportRoot.path, 'games', gameId, 'current.json'));
    try {
      return codec.decode(
        await file.readAsBytes(),
        expectedGameId: gameId,
      );
    } on Object {
      throw const FormatException('Current game pointer is unavailable.');
    }
  }

  Future<void> write(
    String gameId,
    InstalledGamePointer pointer,
  ) async {
    GameIdentity.validateGameId(gameId);
    final gameRoot = Directory(p.join(supportRoot.path, 'games', gameId));
    await gameRoot.create(recursive: true);
    final current = File(p.join(gameRoot.path, 'current.json'));
    final temporary = File(
      p.join(
        gameRoot.path,
        'current.json.tmp.${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    final bytes = codec.encode(gameId: gameId, pointer: pointer);
    final output = await temporary.open(mode: FileMode.writeOnly);
    try {
      await output.writeFrom(bytes);
      await output.flush();
    } finally {
      await output.close();
    }
    codec.decode(await temporary.readAsBytes(), expectedGameId: gameId);
    await temporary.rename(current.path);
    final confirmed = await read(gameId);
    if (confirmed != pointer) {
      throw const FileSystemException('Current pointer confirmation failed.');
    }
  }

  Future<void> delete(String gameId) async {
    GameIdentity.validateGameId(gameId);
    final file =
        File(p.join(supportRoot.path, 'games', gameId, 'current.json'));
    if (await file.exists()) await file.delete();
  }
}

enum InstalledGameVerificationCode {
  healthy,
  versionMissing,
  manifestInvalid,
  receiptMissing,
  receiptInvalid,
  receiptMismatch,
  unexpectedFile,
  missingFile,
  sizeMismatch,
  hashMismatch,
  unsafeEntry,
}

final class InstalledGameVerification {
  InstalledGameVerification({
    required this.code,
    this.manifest,
    this.receipt,
    List<String> affectedPaths = const <String>[],
  }) : affectedPaths = List.unmodifiable(affectedPaths);

  final InstalledGameVerificationCode code;
  final GamePackageManifest? manifest;
  final GamePackageInstallReceipt? receipt;
  final List<String> affectedPaths;

  bool get isHealthy => code == InstalledGameVerificationCode.healthy;
}

final class InstalledGameVerifier {
  const InstalledGameVerifier();

  Future<InstalledGameVerification> verify({
    required Directory supportRoot,
    required String gameId,
    required InstalledGamePointer pointer,
    required String receiptFileName,
  }) async {
    try {
      GameIdentity.validateGameId(gameId);
      GameIdentity.validateSemver(
        pointer.gameVersion.toString(),
        path: r'$.gameVersion',
      );
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(pointer.treeSha256) ||
          receiptFileName !=
              '${pointer.gameVersion}-${pointer.treeSha256}.json') {
        return InstalledGameVerification(
          code: InstalledGameVerificationCode.unsafeEntry,
        );
      }
    } on Object {
      return InstalledGameVerification(
        code: InstalledGameVerificationCode.unsafeEntry,
      );
    }
    final versionRoot = Directory(
      p.join(
        supportRoot.path,
        'games',
        gameId,
        'versions',
        pointer.gameVersion.toString(),
      ),
    );
    if (await FileSystemEntity.type(
          versionRoot.path,
          followLinks: false,
        ) !=
        FileSystemEntityType.directory) {
      return InstalledGameVerification(
        code: InstalledGameVerificationCode.versionMissing,
      );
    }
    late final GamePackageManifest manifest;
    try {
      manifest = const GamePackageManifestCodec().decodeUtf8(
        await File(p.join(versionRoot.path, 'game-manifest.json'))
            .readAsBytes(),
      );
    } on Object {
      return InstalledGameVerification(
        code: InstalledGameVerificationCode.manifestInvalid,
      );
    }
    final receiptFile = File(
      p.join(
        supportRoot.path,
        'games',
        gameId,
        'install-receipts',
        receiptFileName,
      ),
    );
    if (!await receiptFile.exists()) {
      return InstalledGameVerification(
        code: InstalledGameVerificationCode.receiptMissing,
        manifest: manifest,
      );
    }
    late final GamePackageInstallReceipt receipt;
    try {
      receipt = const GamePackageInstallReceiptCodec().decodeUtf8(
        await receiptFile.readAsBytes(),
      );
    } on Object {
      return InstalledGameVerification(
        code: InstalledGameVerificationCode.receiptInvalid,
        manifest: manifest,
      );
    }
    if (manifest.gameId != gameId ||
        manifest.gameVersion != pointer.gameVersion ||
        manifest.content.treeSha256 != pointer.treeSha256 ||
        receipt.gameId != gameId ||
        receipt.gameVersion != pointer.gameVersion ||
        receipt.treeSha256 != pointer.treeSha256) {
      return InstalledGameVerification(
        code: InstalledGameVerificationCode.receiptMismatch,
        manifest: manifest,
        receipt: receipt,
      );
    }
    final expected = <String>{
      'game-manifest.json',
      ...manifest.content.files.map((entry) => entry.path),
    };
    final actual = <String>{};
    await for (final entity
        in versionRoot.list(recursive: true, followLinks: false)) {
      final type = await FileSystemEntity.type(entity.path, followLinks: false);
      if (type == FileSystemEntityType.directory) continue;
      if (type != FileSystemEntityType.file) {
        return InstalledGameVerification(
          code: InstalledGameVerificationCode.unsafeEntry,
          manifest: manifest,
          receipt: receipt,
        );
      }
      final relative = p.posix.joinAll(
        p.split(p.relative(entity.path, from: versionRoot.path)),
      );
      actual.add(relative);
    }
    final extra = actual.difference(expected).toList()..sort();
    if (extra.isNotEmpty) {
      return InstalledGameVerification(
        code: InstalledGameVerificationCode.unexpectedFile,
        manifest: manifest,
        receipt: receipt,
        affectedPaths: extra,
      );
    }
    final missing = expected.difference(actual).toList()..sort();
    if (missing.isNotEmpty) {
      return InstalledGameVerification(
        code: InstalledGameVerificationCode.missingFile,
        manifest: manifest,
        receipt: receipt,
        affectedPaths: missing,
      );
    }
    for (final entry in manifest.content.files) {
      final file = File(p.joinAll(<String>[
        versionRoot.path,
        ...p.posix.split(entry.path),
      ]));
      if (await file.length() != entry.size) {
        return InstalledGameVerification(
          code: InstalledGameVerificationCode.sizeMismatch,
          manifest: manifest,
          receipt: receipt,
          affectedPaths: <String>[entry.path],
        );
      }
      final digest = await sha256.bind(file.openRead()).first;
      if (digest.toString() != entry.sha256) {
        return InstalledGameVerification(
          code: InstalledGameVerificationCode.hashMismatch,
          manifest: manifest,
          receipt: receipt,
          affectedPaths: <String>[entry.path],
        );
      }
    }
    return InstalledGameVerification(
      code: InstalledGameVerificationCode.healthy,
      manifest: manifest,
      receipt: receipt,
    );
  }
}
