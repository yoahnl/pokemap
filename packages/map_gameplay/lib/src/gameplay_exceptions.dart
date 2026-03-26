class GameplaySpawnResolutionException implements Exception {
  const GameplaySpawnResolutionException(this.message);

  final String message;

  @override
  String toString() => 'GameplaySpawnResolutionException: $message';
}
