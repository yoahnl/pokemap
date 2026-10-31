import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import 'package:pokemap_hub/features/installation/data/repositories/install_failures.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';
import 'package:pokemap_hub/features/installation/data/sources/file_package_source.dart';

/// Everything the installer does *before* anything becomes visible to the
/// player: inspection, transaction root creation, byte-for-byte snapshotting
/// and archive extraction into staging.
///
/// Extracted from [GamePackageInstaller] without a single rule change. Every
/// path guard here — the `isWithin` escape check, the symlink refusal, the
/// exact-entry-set check — is load bearing.
final class InstallStaging {
  InstallStaging({
    required this.supportRoot,
    required this.inspector,
    this.inspectionObserver,
    Random? random,
  }) : _random = random ?? Random.secure();

  final Directory supportRoot;
  final GamePackageInspector inspector;
  final GamePackageInspectionObserver? inspectionObserver;
  final Random _random;

  Future<GamePackageManifestInspection> inspectManifest(File file) {
    final path = file.path;
    final packageInspector = inspector;
    inspectionObserver?.call(
      GamePackageInspectionScope.manifest,
      path,
      hasKnownDigest: false,
    );
    return Isolate.run(() => _inspectPackageManifest(path, packageInspector));
  }

  Future<GamePackageInspectionResult> inspect(
    File file, {
    String? knownPackageSha256,
  }) {
    final path = file.path;
    final packageInspector = inspector;
    inspectionObserver?.call(
      GamePackageInspectionScope.full,
      path,
      hasKnownDigest: knownPackageSha256 != null,
    );
    return Isolate.run(
      () => _inspectPackageFile(path, packageInspector, knownPackageSha256),
    );
  }

  Future<void> validateProject(
    Directory stagedVersion,
    GamePackageManifest manifest,
  ) {
    final path = stagedVersion.path;
    final policy = inspector.policy;
    return Isolate.run(() => _validateStagedProject(path, manifest, policy));
  }

  Future<Directory> createTransactionRoot() async {
    final transactions = Directory(
      p.join(supportRoot.path, 'games', '.transactions'),
    );
    await transactions.create(recursive: true);
    final id =
        '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
    final root = Directory(p.join(transactions.path, id));
    await root.create();
    return root;
  }

  Future<String> copyPackageSnapshot(
    File source,
    File target, {
    required GameInstallCancellationToken cancellationToken,
    required String gameId,
    required String gameVersion,
    required GameInstallProgressListener? onProgress,
    required int totalBytes,
  }) async {
    throwIfCancelled(
      cancellationToken,
      GameInstallStage.snapshotting,
      gameId,
      gameVersion,
    );
    final events = ReceivePort();
    final drained = Completer<void>();
    SendPort? control;
    events.listen((message) {
      switch (message) {
        case final SendPort port:
          control = port;
          if (cancellationToken.isCancelled) port.send(null);
        case final int copied:
          if (cancellationToken.isCancelled) {
            control?.send(null);
            return;
          }
          emitInstallProgress(
            onProgress,
            stage: GameInstallStage.snapshotting,
            gameId: gameId,
            gameVersion: gameVersion,
            completedBytes: copied,
            totalBytes: totalBytes,
          );
        case null:
          drained.complete();
      }
    });
    try {
      final digest = await _runSnapshotCopy(
        source.path,
        target.path,
        events.sendPort,
      );
      if (digest != null) await drained.future;
      throwIfCancelled(
        cancellationToken,
        GameInstallStage.snapshotting,
        gameId,
        gameVersion,
      );
      return digest!;
    } finally {
      events.close();
    }
  }

  Future<void> extractSnapshot(
    File snapshot,
    Directory target,
    GamePackageInspectionResult inspection, {
    required GameInstallCancellationToken cancellationToken,
    required GameInstallProgressListener? onProgress,
  }) async {
    await target.create();
    final gameId = inspection.manifest.gameId;
    final gameVersion = inspection.manifest.gameVersion.toString();
    throwIfCancelled(
      cancellationToken,
      GameInstallStage.extracting,
      gameId,
      gameVersion,
    );
    final expected = <String, _StagedEntryDigest>{
      'game-manifest.json': _StagedEntryDigest(
        null,
        inspection.receipt.manifestSha256,
      ),
      for (final entry in inspection.manifest.content.files)
        entry.path: _StagedEntryDigest(entry.size, entry.sha256),
    };
    final events = ReceivePort();
    final drained = Completer<void>();
    SendPort? control;
    events.listen((message) {
      switch (message) {
        case final SendPort port:
          control = port;
          if (cancellationToken.isCancelled) port.send(null);
        case (
          final int completedFiles,
          final int totalFiles,
          final int completedBytes,
          final int totalBytes,
        ):
          if (cancellationToken.isCancelled) {
            control?.send(null);
            return;
          }
          emitInstallProgress(
            onProgress,
            stage: GameInstallStage.extracting,
            gameId: gameId,
            gameVersion: gameVersion,
            completedFiles: completedFiles,
            totalFiles: totalFiles,
            completedBytes: completedBytes,
            totalBytes: totalBytes,
          );
        case null:
          drained.complete();
      }
    });
    try {
      final completed = await _runSnapshotExtraction(
        snapshot.path,
        target.path,
        <String>{'game-manifest.json', ...inspection.payloadPaths},
        expected,
        events.sendPort,
      );
      if (completed) await drained.future;
      throwIfCancelled(
        cancellationToken,
        GameInstallStage.extracting,
        gameId,
        gameVersion,
      );
    } finally {
      events.close();
    }
  }
}

final class _StagedEntryDigest {
  const _StagedEntryDigest(this.size, this.sha256);

  final int? size;
  final String sha256;
}

Future<bool> _runSnapshotExtraction(
  String snapshotPath,
  String targetPath,
  Set<String> expectedNames,
  Map<String, _StagedEntryDigest> digests,
  SendPort events,
) => Isolate.run(
  () => _extractAndHashSnapshot(
    snapshotPath,
    targetPath,
    expectedNames,
    digests,
    events,
  ),
  debugName: 'install-snapshot-extract',
);

Future<bool> _extractAndHashSnapshot(
  String snapshotPath,
  String targetPath,
  Set<String> expectedNames,
  Map<String, _StagedEntryDigest> digests,
  SendPort events,
) async {
  final control = ReceivePort();
  var cancelled = false;
  control.listen((_) => cancelled = true);
  events.send(control.sendPort);
  final input = InputFileStream(snapshotPath);
  final archive = ZipDecoder().decodeStream(input);
  final expected = {...expectedNames};
  var completedFiles = 0;
  var completedBytes = 0;
  final totalFiles = archive.files.length;
  final totalBytes = archive.files.fold<int>(
    0,
    (total, file) => total + file.size,
  );
  try {
    for (final entry in archive.files) {
      if (cancelled) return false;
      if (!expected.remove(entry.name) ||
          !entry.isFile ||
          entry.isSymbolicLink) {
        throw const FormatException('Unexpected archive entry.');
      }
      final outputPath = p.joinAll(<String>[
        targetPath,
        ...p.posix.split(entry.name),
      ]);
      if (!p.isWithin(targetPath, outputPath)) {
        throw const FormatException('Archive entry escaped staging.');
      }
      final digest = digests[entry.name];
      if (digest == null) {
        throw const FormatException('Staged payload digest differs.');
      }
      final outputFile = File(outputPath);
      await outputFile.parent.create(recursive: true);
      final output = await outputFile.open(mode: FileMode.writeOnly);
      final digestSink = _DigestSink();
      final hashInput = sha256.startChunkedConversion(digestSink);
      var written = 0;
      try {
        final content = entry.getContent();
        if (content == null) {
          throw const FormatException('Archive entry has no content.');
        }
        var remaining = content.length;
        while (remaining > 0) {
          final count = min(remaining, 1024 * 1024);
          final bytes = content.readBytes(count).toUint8List();
          if (bytes.length != count) {
            throw const FormatException('Archive entry was truncated.');
          }
          hashInput.add(bytes);
          await output.writeFrom(bytes);
          remaining -= bytes.length;
          written += bytes.length;
          completedBytes += bytes.length;
        }
        await output.flush();
      } finally {
        await output.close();
      }
      hashInput.close();
      if ((digest.size != null && written != digest.size) ||
          digestSink.value.toString() != digest.sha256) {
        throw const FormatException('Staged payload digest differs.');
      }
      completedFiles++;
      events.send((completedFiles, totalFiles, completedBytes, totalBytes));
    }
    if (expected.isNotEmpty) {
      throw const FormatException('Archive entries are missing.');
    }
  } finally {
    control.close();
    await archive.clear();
    await input.close();
  }
  events.send(null);
  return true;
}

Future<String?> _runSnapshotCopy(
  String sourcePath,
  String targetPath,
  SendPort events,
) => Isolate.run(
  () => _copyAndHashSnapshot(sourcePath, targetPath, events),
  debugName: 'install-snapshot-copy',
);

Future<String?> _copyAndHashSnapshot(
  String sourcePath,
  String targetPath,
  SendPort events,
) async {
  final control = ReceivePort();
  var cancelled = false;
  control.listen((_) => cancelled = true);
  events.send(control.sendPort);
  final input = await File(sourcePath).open(mode: FileMode.read);
  final output = await File(targetPath).open(mode: FileMode.writeOnly);
  final digestSink = _DigestSink();
  final hashInput = sha256.startChunkedConversion(digestSink);
  var copied = 0;
  try {
    while (true) {
      if (cancelled) return null;
      final bytes = await input.read(1024 * 1024);
      if (bytes.isEmpty) break;
      hashInput.add(bytes);
      await output.writeFrom(bytes);
      copied += bytes.length;
      events.send(copied);
    }
    await output.flush();
  } finally {
    control.close();
    await input.close();
    await output.close();
  }
  hashInput.close();
  events.send(null);
  return digestSink.value.toString();
}

Future<GamePackageManifestInspection> _inspectPackageManifest(
  String path,
  GamePackageInspector inspector,
) async {
  final source = await FilePackageSource.open(File(path));
  try {
    return inspector.inspectManifestSync(source);
  } finally {
    await source.close();
  }
}

Future<GamePackageInspectionResult> _inspectPackageFile(
  String path,
  GamePackageInspector inspector,
  String? knownPackageSha256,
) async {
  final source = await FilePackageSource.open(File(path));
  try {
    return inspector.inspectSourceSync(
      source,
      knownPackageSha256: knownPackageSha256,
    );
  } finally {
    await source.close();
  }
}

final class _DigestSink implements Sink<Digest> {
  Digest? _digest;

  Digest get value => _digest ?? (throw StateError('Digest is not complete.'));

  @override
  void add(Digest data) => _digest = data;

  @override
  void close() {}
}

void _validateStagedProject(
  String stagedPath,
  GamePackageManifest manifest,
  GamePackageSecurityPolicy policy,
) {
  final inventory = {
    for (final entry in manifest.content.files) entry.path: entry,
  };
  List<int>? readPayload(String path) {
    PackagePathPolicy.validate(path, errorPath: path);
    final entry = inventory[path];
    if (entry == null) return null;
    var current = stagedPath;
    final segments = p.posix.split(path);
    for (var index = 0; index < segments.length; index++) {
      current = p.join(current, segments[index]);
      final type = FileSystemEntity.typeSync(current, followLinks: false);
      final expected = index == segments.length - 1
          ? FileSystemEntityType.file
          : FileSystemEntityType.directory;
      if (type != expected) {
        throw GamePackageFormatException(
          code: 'unsafeEntry',
          path: path,
          message: 'Staged payload must use regular files and directories.',
        );
      }
    }
    final file = File(current);
    if (entry.size > policy.maxFileBytes || file.lengthSync() != entry.size) {
      throw GamePackageFormatException(
        code: 'sizeMismatch',
        path: path,
        message: 'Staged payload size differs from its inventory.',
      );
    }
    final handle = file.openSync();
    try {
      final bytes = handle.readSync(entry.size);
      if (bytes.length != entry.size ||
          handle.lengthSync() != entry.size ||
          sha256.convert(bytes).toString() != entry.sha256) {
        throw GamePackageFormatException(
          code: 'hashMismatch',
          path: path,
          message: 'Staged payload changed during project validation.',
        );
      }
      return bytes;
    } finally {
      handle.closeSync();
    }
  }

  GamePackageProjectValidator(policy).validate(
    manifest,
    Uint8List.fromList(readPayload('project/project.json')!),
    payloadPaths: inventory.keys.toSet(),
    readPayload: readPayload,
  );
}
