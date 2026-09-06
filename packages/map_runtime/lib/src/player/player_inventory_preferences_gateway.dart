abstract interface class PlayerInventoryPreferencesGateway {
  Future<Set<String>> load(String gameId);

  Future<void> save(String gameId, Set<String> favoriteItemIds);
}
