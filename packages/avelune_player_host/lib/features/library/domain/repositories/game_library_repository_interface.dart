import 'package:avelune_player_host/features/library/domain/entities/game_library.dart';
import 'package:avelune_player_host/features/library/domain/entities/game_library_read.dart';

/// Reads and writes the installed-game catalogue.
abstract interface class GameLibraryRepositoryInterface {
  Future<GameLibraryRead> load();

  Future<void> save(GameLibrary library);
}
