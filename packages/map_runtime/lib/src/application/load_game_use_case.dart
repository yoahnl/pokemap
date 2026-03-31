import 'package:map_core/map_core.dart';

import '../../../domain/repositories/game_save_repository.dart';

/// Use case pour charger l'état de la partie.
class LoadGameUseCase {
  const LoadGameUseCase(this._repo);

  final GameSaveRepository _repo;

  /// Charge l'état de la partie.
  ///
  /// Retourne `null` si aucune sauvegarde n'existe ou en cas d'échec.
  Future<GameState?> execute() async {
    try {
      return await _repo.load();
    } on GameSaveException {
      return null;
    }
  }
}
