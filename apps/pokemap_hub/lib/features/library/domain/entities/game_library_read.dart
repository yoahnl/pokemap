import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';

enum GameLibrarySource { current, backup, empty }

enum GameLibraryDiagnosticCode { currentCorrupt, backupCorrupt }

final class GameLibraryDiagnostic {
  const GameLibraryDiagnostic({required this.code});

  final GameLibraryDiagnosticCode code;
}

final class GameLibraryRead {
  GameLibraryRead({
    required this.library,
    required this.source,
    required List<GameLibraryDiagnostic> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  final GameLibrary library;
  final GameLibrarySource source;
  final List<GameLibraryDiagnostic> diagnostics;
}

enum GameLibraryStorageErrorCode { unsafePath, writeFailed }

final class GameLibraryStorageException implements Exception {
  const GameLibraryStorageException({
    required this.code,
    required this.message,
  });

  final GameLibraryStorageErrorCode code;
  final String message;

  @override
  String toString() => 'GameLibraryStorageException(${code.name}): $message';
}
