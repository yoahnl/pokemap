import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/library/data/codecs/game_library_codec.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library_read.dart';
import 'package:pokemap_hub/features/library/domain/repositories/game_library_repository_interface.dart';

final class GameLibraryStore
    implements GameLibraryRepositoryInterface {
  GameLibraryStore({
    required this.supportRoot,
    this.codec = const GameLibraryCodec(),
  });

  final Directory supportRoot;
  final GameLibraryCodec codec;
  final Random _random = Random.secure();

  @override
  Future<GameLibraryRead> load() async {
    await _assertSafeRoot(create: false);
    final diagnostics = <GameLibraryDiagnostic>[];
    final current = File(p.join(supportRoot.path, 'library.json'));
    final backup = File(p.join(supportRoot.path, 'library.backup.json'));
    if (await current.exists()) {
      try {
        return GameLibraryRead(
          library: codec.decodeUtf8(await current.readAsBytes()),
          source: GameLibrarySource.current,
          diagnostics: diagnostics,
        );
      } on Object {
        diagnostics.add(
          const GameLibraryDiagnostic(
            code: GameLibraryDiagnosticCode.currentCorrupt,
          ),
        );
      }
    }
    if (await backup.exists()) {
      try {
        return GameLibraryRead(
          library: codec.decodeUtf8(await backup.readAsBytes()),
          source: GameLibrarySource.backup,
          diagnostics: diagnostics,
        );
      } on Object {
        diagnostics.add(
          const GameLibraryDiagnostic(
            code: GameLibraryDiagnosticCode.backupCorrupt,
          ),
        );
      }
    }
    return GameLibraryRead(
      library: GameLibrary.empty(),
      source: GameLibrarySource.empty,
      diagnostics: diagnostics,
    );
  }

  @override
  Future<void> save(GameLibrary library) async {
    await _assertSafeRoot(create: true);
    final bytes = codec.encodeCanonicalUtf8(library);
    final nonce =
        '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
    final current = File(p.join(supportRoot.path, 'library.json'));
    final backup = File(p.join(supportRoot.path, 'library.backup.json'));
    final temporary = File(p.join(supportRoot.path, 'library.json.tmp.$nonce'));
    final backupNext =
        File(p.join(supportRoot.path, 'library.backup.json.next.$nonce'));
    try {
      final sink = await temporary.open(mode: FileMode.writeOnly);
      try {
        await sink.writeFrom(bytes);
        await sink.flush();
      } finally {
        await sink.close();
      }
      codec.decodeUtf8(await temporary.readAsBytes());
      if (await current.exists()) {
        try {
          codec.decodeUtf8(await current.readAsBytes());
          await current.copy(backupNext.path);
          final backupSink = await backupNext.open(mode: FileMode.append);
          try {
            await backupSink.flush();
          } finally {
            await backupSink.close();
          }
          if (await backup.exists()) await backup.delete();
          await backupNext.rename(backup.path);
        } on GameLibraryFormatException {
          if (await backupNext.exists()) await backupNext.delete();
        }
      }
      await temporary.rename(current.path);
      final confirmed = codec.decodeUtf8(await current.readAsBytes());
      if (confirmed.revision != library.revision) {
        throw const FormatException('Library confirmation mismatch.');
      }
    } on GameLibraryStorageException {
      rethrow;
    } on Object catch (error) {
      throw GameLibraryStorageException(
        code: GameLibraryStorageErrorCode.writeFailed,
        message: 'Atomic library write failed: ${error.runtimeType}.',
      );
    } finally {
      if (await temporary.exists()) await temporary.delete();
      if (await backupNext.exists()) await backupNext.delete();
    }
  }

  Future<void> _assertSafeRoot({required bool create}) async {
    final type = await FileSystemEntity.type(
      supportRoot.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.link ||
        (type != FileSystemEntityType.notFound &&
            type != FileSystemEntityType.directory)) {
      throw const GameLibraryStorageException(
        code: GameLibraryStorageErrorCode.unsafePath,
        message: 'Application support root is not a regular directory.',
      );
    }
    if (type == FileSystemEntityType.notFound && create) {
      await supportRoot.create(recursive: true);
      final createdType = await FileSystemEntity.type(
        supportRoot.path,
        followLinks: false,
      );
      if (createdType != FileSystemEntityType.directory) {
        throw const GameLibraryStorageException(
          code: GameLibraryStorageErrorCode.unsafePath,
          message: 'Application support root could not be created safely.',
        );
      }
    }
  }
}
