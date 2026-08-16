import 'package:map_core/map_core.dart';

import '../../../domain/repositories/game_save_repository.dart';

/// Use case pour charger l'état de la partie.
class LoadGameUseCase {
  const LoadGameUseCase(this._repo);

  final GameSaveRepository _repo;

  /// Charge l'état de la partie.
  ///
  /// Retourne `null` uniquement si aucune sauvegarde n'existe. Une sauvegarde
  /// illisible lève [GameSaveException] : la confondre avec une absence
  /// reviendrait à proposer une réinitialisation silencieuse.
  Future<GameState?> execute() => _repo.load();
}
