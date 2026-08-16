/// Machine-testable ownership rules for the canonical Authoring API package.
///
/// These declarations document where future phase work belongs. They are not
/// a dependency injector and must not be used to reach platform packages.
abstract final class MapAuthoringPackageBoundaries {
  static const String packageName = 'map_authoring';

  /// `map_core` owns PokeMap's serializable data and pure domain operations.
  static const Set<String> allowedPackageDependencies = {
    'crypto',
    'image',
    'map_core',
    'map_distribution',
    'path',
    'pub_semver',
  };

  static const Set<String> ownedResponsibilities = {
    'authoring contracts',
    'authoring orchestration',
    'action registry',
  };

  /// Adapters remain owned by consumers so Flutter, Flame, and MCP protocol
  /// types cannot leak into canonical contracts.
  static const Map<String, String> platformAdapterOwners = {
    'editor': 'map_editor',
    'runtime': 'map_runtime',
    'mcp': 'tools/pokemap_mcp',
  };
}
