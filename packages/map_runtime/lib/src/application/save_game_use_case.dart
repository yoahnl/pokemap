import 'package:map_core/map_core.dart';

import '../../../domain/repositories/game_save_repository.dart';

/// Use case pour sauvegarder l'état de la partie.
class SaveGameUseCase {
  const SaveGameUseCase(this._repo);

  final GameSaveRepository _repo;

  /// Sauvegarde l'état de la partie.
  ///
  /// Retourne `true` si la sauvegarde a réussi.
  Future<bool> execute(GameState state) async {
    try {
      await _repo.save(state);
      return true;
    } on GameSaveException {
      return false;
    }
  }
}
