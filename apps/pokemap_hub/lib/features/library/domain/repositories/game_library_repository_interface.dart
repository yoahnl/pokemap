import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library_read.dart';

/// Reads and writes the installed-game catalogue.
abstract interface class GameLibraryRepositoryInterface {
  Future<GameLibraryRead> load();

  Future<void> save(GameLibrary library);
}
