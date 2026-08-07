import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';

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

typedef InstalledGameFileIntegrityCheck = Future<InstalledGameVerificationCode?>
    Function(
  File file,
  GamePackageFileEntry entry,
);

final class InstalledGameVerifier {
  const InstalledGameVerifier({
    this.maxConcurrentFileChecks = 8,
    InstalledGameFileIntegrityCheck? fileIntegrityCheck,
  })  : fileIntegrityCheck =
            fileIntegrityCheck ?? _checkInstalledGameFileIntegrity,
        _usesDefaultIntegrityCheck = fileIntegrityCheck == null,
        assert(maxConcurrentFileChecks > 0);

  final int maxConcurrentFileChecks;
  final InstalledGameFileIntegrityCheck fileIntegrityCheck;
  final bool _usesDefaultIntegrityCheck;

  int get _effectiveMaxConcurrentFileChecks {
    if (maxConcurrentFileChecks < 1) return 1;
    if (maxConcurrentFileChecks > _maxConcurrentIntegrityWorkers) {
      return _maxConcurrentIntegrityWorkers;
    }
    return maxConcurrentFileChecks;
  }

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
      if (entity is Directory) continue;
      if (entity is! File) {
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
    final entries = manifest.content.files;
    final failureByIndex =
        List<InstalledGameVerificationCode?>.filled(entries.length, null);
    if (_usesDefaultIntegrityCheck) {
      await _checkDefaultFileIntegrity(
        versionRoot: versionRoot,
        entries: entries,
        failureByIndex: failureByIndex,
      );
    } else {
      await _checkFileIntegrityWithCallback(
        versionRoot: versionRoot,
        entries: entries,
        indexes: List<int>.generate(entries.length, (index) => index),
        failureByIndex: failureByIndex,
      );
    }
    for (var index = 0; index < failureByIndex.length; index++) {
      final failure = failureByIndex[index];
      if (failure != null) {
        return InstalledGameVerification(
          code: failure,
          manifest: manifest,
          receipt: receipt,
          affectedPaths: <String>[entries[index].path],
        );
      }
    }
    return InstalledGameVerification(
      code: InstalledGameVerificationCode.healthy,
      manifest: manifest,
      receipt: receipt,
    );
  }

  Future<void> _checkDefaultFileIntegrity({
    required Directory versionRoot,
    required List<GamePackageFileEntry> entries,
    required List<InstalledGameVerificationCode?> failureByIndex,
  }) async {
    final bufferedBatches = List<List<List<Object>>>.generate(
      _effectiveMaxConcurrentFileChecks,
      (_) => <List<Object>>[],
    );
    var bufferedIndex = 0;
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      bufferedBatches[bufferedIndex++ % bufferedBatches.length].add(
        <Object>[
          index,
          p.joinAll(<String>[
            versionRoot.path,
            ...p.posix.split(entry.path),
          ]),
          entry.size,
          entry.sha256,
        ],
      );
    }

    Future<void> checkBufferedBatch(List<List<Object>> batch) async {
      final failure = await _installedGameIntegrityIsolates.run(
        () => Isolate.run(
          () => _checkBufferedInstalledGameFiles(batch),
        ),
      );
      if (failure == null) return;
      final index = failure[0] as int;
      failureByIndex[index] =
          InstalledGameVerificationCode.values[failure[1] as int];
    }

    await Future.wait<void>(<Future<void>>[
      for (final batch in bufferedBatches)
        if (batch.isNotEmpty) checkBufferedBatch(batch),
    ]);
  }

  Future<void> _checkFileIntegrityWithCallback({
    required Directory versionRoot,
    required List<GamePackageFileEntry> entries,
    required List<int> indexes,
    required List<InstalledGameVerificationCode?> failureByIndex,
  }) async {
    var nextIndex = 0;

    Future<void> checkNextFiles() async {
      while (nextIndex < indexes.length) {
        final index = indexes[nextIndex++];
        final entry = entries[index];
        final file = File(p.joinAll(<String>[
          versionRoot.path,
          ...p.posix.split(entry.path),
        ]));
        failureByIndex[index] = await fileIntegrityCheck(file, entry);
      }
    }

    final workerCount = indexes.length < _effectiveMaxConcurrentFileChecks
        ? indexes.length
        : _effectiveMaxConcurrentFileChecks;
    await Future.wait<void>(
      List<Future<void>>.generate(workerCount, (_) => checkNextFiles()),
    );
  }
}

Future<InstalledGameVerificationCode?> _checkInstalledGameFileIntegrity(
  File file,
  GamePackageFileEntry entry,
) async {
  try {
    if (entry.size <= _maxBufferedIntegrityFileBytes) {
      final bytes = await file.readAsBytes();
      if (bytes.length != entry.size) {
        return InstalledGameVerificationCode.sizeMismatch;
      }
      return sha256.convert(bytes).toString() == entry.sha256
          ? null
          : InstalledGameVerificationCode.hashMismatch;
    }
    if (await file.length() != entry.size) {
      return InstalledGameVerificationCode.sizeMismatch;
    }
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == entry.sha256
        ? null
        : InstalledGameVerificationCode.hashMismatch;
  } on FileSystemException {
    return InstalledGameVerificationCode.missingFile;
  }
}

const int _maxBufferedIntegrityFileBytes = 4 * 1024 * 1024;
const int _maxConcurrentIntegrityWorkers = 8;
final _installedGameIntegrityIsolates = _InstalledGameIntegrityIsolateLimiter(
  maxConcurrent: _maxConcurrentIntegrityWorkers,
);

List<Object>? _checkBufferedInstalledGameFiles(List<List<Object>> entries) {
  for (final entry in entries) {
    final index = entry[0] as int;
    try {
      final file = File(entry[1] as String);
      final expectedSize = entry[2] as int;
      final digest = expectedSize <= _maxBufferedIntegrityFileBytes
          ? _digestBufferedFile(file, expectedSize)
          : _digestStreamedFile(file, expectedSize);
      if (digest == null) {
        return <Object>[
          index,
          InstalledGameVerificationCode.sizeMismatch.index,
        ];
      }
      if (digest != entry[3]) {
        return <Object>[
          index,
          InstalledGameVerificationCode.hashMismatch.index,
        ];
      }
    } on FileSystemException {
      return <Object>[
        index,
        InstalledGameVerificationCode.missingFile.index,
      ];
    }
  }
  return null;
}

String? _digestBufferedFile(File file, int expectedSize) {
  final bytes = file.readAsBytesSync();
  if (bytes.length != expectedSize) return null;
  return sha256.convert(bytes).toString();
}

String? _digestStreamedFile(File file, int expectedSize) {
  final input = file.openSync();
  final digestSink = _InstalledGameDigestSink();
  final conversion = sha256.startChunkedConversion(digestSink);
  var totalBytes = 0;
  try {
    final buffer = Uint8List(256 * 1024);
    while (true) {
      final count = input.readIntoSync(buffer);
      if (count == 0) break;
      totalBytes += count;
      conversion.add(
        count == buffer.length
            ? buffer
            : Uint8List.sublistView(buffer, 0, count),
      );
    }
    conversion.close();
  } finally {
    input.closeSync();
  }
  if (totalBytes != expectedSize) return null;
  return digestSink.digest.toString();
}

final class _InstalledGameDigestSink implements Sink<Digest> {
  Digest? _digest;

  Digest get digest => _digest!;

  @override
  void add(Digest data) {
    _digest = data;
  }

  @override
  void close() {}
}

final class _InstalledGameIntegrityIsolateLimiter {
  _InstalledGameIntegrityIsolateLimiter({required this.maxConcurrent});

  final int maxConcurrent;
  final List<Completer<void>> _waiters = <Completer<void>>[];
  int _active = 0;

  Future<T> run<T>(Future<T> Function() action) async {
    if (_active < maxConcurrent) {
      _active++;
    } else {
      final waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
    }
    try {
      return await action();
    } finally {
      if (_waiters.isNotEmpty) {
        _waiters.removeAt(0).complete();
      } else {
        _active--;
      }
    }
  }
}
