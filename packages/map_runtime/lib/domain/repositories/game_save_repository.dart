import 'package:map_core/map_core.dart';

/// Exception levée en cas d'échec de sauvegarde/chargement.
class GameSaveException implements Exception {
  const GameSaveException(this.message);

  final String message;

  @override
  String toString() => 'GameSaveException: $message';
}

/// Repository pour la persistance des états de jeu.
abstract class GameSaveRepository {
  /// Sauvegarde l'état de la partie.
  ///
  /// Lance [GameSaveException] en cas d'échec.
  Future<void> save(GameState state);

  /// Charge l'état de la partie.
  ///
  /// Retourne `null` si aucune sauvegarde n'existe.
  /// Lance [GameSaveException] en cas d'échec.
  Future<GameState?> load();

  /// Vérifie si une sauvegarde existe.
  Future<bool> exists();

  /// Supprime la sauvegarde.
  ///
  /// Ne fait rien si aucune sauvegarde n'existe.
  Future<void> delete();
}
