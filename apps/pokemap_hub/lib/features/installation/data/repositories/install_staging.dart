import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
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
    Random? random,
  }) : _random = random ?? Random.secure();

  final Directory supportRoot;
  final GamePackageInspector inspector;
  final Random _random;

  Future<GamePackageInspectionResult> inspect(File file) async {
    final source = await FilePackageSource.open(file);
    try {
      return inspector.inspectSourceSync(source);
    } finally {
      await source.close();
    }
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

  Future<void> copyPackageSnapshot(
    File source,
    File target, {
    required GameInstallCancellationToken cancellationToken,
    required String gameId,
    required String gameVersion,
    required GameInstallProgressListener? onProgress,
    required int totalBytes,
  }) async {
    final input = await source.open(mode: FileMode.read);
    final output = await target.open(mode: FileMode.writeOnly);
    var copied = 0;
    try {
      while (true) {
        throwIfCancelled(
          cancellationToken,
          GameInstallStage.snapshotting,
          gameId,
          gameVersion,
        );
        final bytes = await input.read(1024 * 1024);
        if (bytes.isEmpty) break;
        await output.writeFrom(bytes);
        copied += bytes.length;
        emitInstallProgress(
          onProgress,
          stage: GameInstallStage.snapshotting,
          gameId: gameId,
          gameVersion: gameVersion,
          completedBytes: copied,
          totalBytes: totalBytes,
        );
      }
      await output.flush();
    } finally {
      await input.close();
      await output.close();
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
    final input = InputFileStream(snapshot.path);
    final archive = ZipDecoder().decodeStream(input);
    final expected = <String>{
      'game-manifest.json',
      ...inspection.payloadPaths,
    };
    var completedFiles = 0;
    var completedBytes = 0;
    final totalBytes =
        archive.files.fold<int>(0, (total, file) => total + file.size);
    try {
      for (final entry in archive.files) {
        throwIfCancelled(
          cancellationToken,
          GameInstallStage.extracting,
          inspection.manifest.gameId,
          inspection.manifest.gameVersion.toString(),
        );
        if (!expected.remove(entry.name) ||
            !entry.isFile ||
            entry.isSymbolicLink) {
          throw const FormatException('Unexpected archive entry.');
        }
        final outputPath = p.joinAll(<String>[
          target.path,
          ...p.posix.split(entry.name),
        ]);
        if (!p.isWithin(target.path, outputPath)) {
          throw const FormatException('Archive entry escaped staging.');
        }
        final outputFile = File(outputPath);
        await outputFile.parent.create(recursive: true);
        final output = await outputFile.open(mode: FileMode.writeOnly);
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
            await output.writeFrom(bytes);
            remaining -= bytes.length;
            completedBytes += bytes.length;
          }
          await output.flush();
        } finally {
          await output.close();
        }
        completedFiles++;
        emitInstallProgress(
          onProgress,
          stage: GameInstallStage.extracting,
          gameId: inspection.manifest.gameId,
          gameVersion: inspection.manifest.gameVersion.toString(),
          completedFiles: completedFiles,
          totalFiles: archive.files.length,
          completedBytes: completedBytes,
          totalBytes: totalBytes,
        );
      }
      if (expected.isNotEmpty) {
        throw const FormatException('Archive entries are missing.');
      }
    } finally {
      await archive.clear();
      await input.close();
    }
  }
}
