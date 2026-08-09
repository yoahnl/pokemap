import '../contracts/json_contract_support.dart';

/// Resource kinds currently published by the canonical read API description.
///
/// This compatibility view is derived from the canonical registry so resource
/// descriptors and direct-query capabilities cannot drift independently.
final Set<String> canonicalQueryableResourceKindIds =
    AuthoringResourceKindRegistry.canonical().queryableResourceKindIds;

/// Public description of one resource kind accepted by authoring contracts.
final class AuthoringResourceKindDescriptor {
  AuthoringResourceKindDescriptor({
    required String id,
    required int version,
    required String displayName,
    required String summary,
    Map<String, Object?> extensions = const {},
  })  : id = _nonBlank(id, 'id'),
        version = _positiveVersion(version),
        displayName = _nonBlank(displayName, 'displayName'),
        summary = _nonBlank(summary, 'summary'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        );

  factory AuthoringResourceKindDescriptor.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    try {
      return AuthoringResourceKindDescriptor(
        id: requireContractString(json['id'], 'id'),
        version: requirePositiveContractVersion(json['version'], 'version'),
        displayName: requireContractString(json['displayName'], 'displayName'),
        summary: requireContractString(json['summary'], 'summary'),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _reservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'id',
    'version',
    'displayName',
    'summary',
    'extensions',
  };

  final String id;
  final int version;
  final String displayName;
  final String summary;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'version': version,
      'displayName': displayName,
      'summary': summary,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

final class DuplicateAuthoringResourceKindException implements Exception {
  const DuplicateAuthoringResourceKindException(this.kindId, this.version);

  final String kindId;
  final int version;

  @override
  String toString() => 'Duplicate authoring resource kind: $kindId v$version';
}

final class IncompatibleAuthoringResourceKindVersionException
    implements Exception {
  IncompatibleAuthoringResourceKindVersionException(
    this.kindId,
    Iterable<int> versions,
  ) : versions = List.unmodifiable(versions.toSet().toList()..sort());

  final String kindId;
  final List<int> versions;

  @override
  String toString() {
    return 'Incompatible resource kind versions for $kindId: '
        '${versions.join(', ')}';
  }
}

final class UnknownAuthoringResourceKindException implements Exception {
  const UnknownAuthoringResourceKindException(this.kindId);

  final String kindId;

  @override
  String toString() => 'Unknown authoring resource kind: $kindId';
}

/// Immutable registry of resource kinds, sorted by stable identifier.
final class AuthoringResourceKindRegistry {
  AuthoringResourceKindRegistry(
    Iterable<AuthoringResourceKindDescriptor> descriptors, {
    Iterable<String> queryableResourceKindIds = const [],
  }) : resourceKinds = _validateAndSort(descriptors) {
    _byId = Map.unmodifiable({
      for (final descriptor in resourceKinds) descriptor.id: descriptor,
    });
    final queryableIds = queryableResourceKindIds.toSet();
    final unknownQueryableIds = queryableIds.difference(_byId.keys.toSet());
    if (unknownQueryableIds.isNotEmpty) {
      throw ArgumentError.value(
        unknownQueryableIds,
        'queryableResourceKindIds',
        'must reference registered resource kinds',
      );
    }
    this.queryableResourceKindIds = Set.unmodifiable(queryableIds);
  }

  factory AuthoringResourceKindRegistry.canonical() {
    return AuthoringResourceKindRegistry([
      AuthoringResourceKindDescriptor(
        id: 'project',
        version: 1,
        displayName: 'Project',
        summary: 'PokeMap project manifest and project-owned content',
      ),
      AuthoringResourceKindDescriptor(
        id: 'projectPresentationProfile',
        version: 2,
        displayName: 'Project presentation profile',
        summary:
            'Responsive intro, title motion, branding, typography and theme',
      ),
      AuthoringResourceKindDescriptor(
        id: 'map',
        version: 1,
        displayName: 'Map',
        summary: 'Editable PokeMap map',
        extensions: const {
          'documentedFieldMasks': ['connections'],
        },
      ),
      AuthoringResourceKindDescriptor(
        id: 'mapConnection',
        version: 1,
        displayName: 'Map connection',
        summary: 'Directional physical adjacency between two maps',
        extensions: const {
          'idFormat': 'mapId:direction',
          'queryActions': [
            'connection.list',
            'connection.get',
            'connection.preview_alignment',
            'connection.validate',
          ],
        },
      ),
      AuthoringResourceKindDescriptor(
        id: 'layer',
        version: 1,
        displayName: 'Layer',
        summary: 'Ordered layer owned by a map',
      ),
      AuthoringResourceKindDescriptor(
        id: 'region',
        version: 1,
        displayName: 'Region',
        summary: 'Named or bounded spatial region in a map',
      ),
      AuthoringResourceKindDescriptor(
        id: 'asset',
        version: 1,
        displayName: 'Asset',
        summary: 'Content-addressed project asset',
      ),
      AuthoringResourceKindDescriptor(
        id: 'assetCatalog',
        version: 1,
        displayName: 'Asset catalog',
        summary: 'Project-owned asset identity and usage registry',
      ),
      AuthoringResourceKindDescriptor(
        id: 'assetBlob',
        version: 1,
        displayName: 'Asset blob',
        summary: 'Content-addressed immutable asset bytes',
      ),
      AuthoringResourceKindDescriptor(
        id: 'smartTileAtlas',
        version: 1,
        displayName: 'Smart Tile atlas',
        summary: 'Decoded-image-bounded atlas geometry for Smart Tiles',
      ),
      AuthoringResourceKindDescriptor(
        id: 'smartTileDraft',
        version: 1,
        displayName: 'Smart Tile draft',
        summary: 'Durable isolated Smart Tiles Studio authoring state',
      ),
      AuthoringResourceKindDescriptor(
        id: 'smartTileMaterial',
        version: 1,
        displayName: 'Smart Tile material',
        summary: 'Semantic terrain, path, or surface material',
      ),
      AuthoringResourceKindDescriptor(
        id: 'smartTilePattern',
        version: 1,
        displayName: 'Smart Tile pattern',
        summary:
            'Reusable anchored visual pattern painted on Smart Tile layers',
      ),
      AuthoringResourceKindDescriptor(
        id: 'smartTileAnimation',
        version: 1,
        displayName: 'Smart Tile animation',
        summary: 'Reusable ordered Smart Tile animation frames',
      ),
      AuthoringResourceKindDescriptor(
        id: 'smartTilePreset',
        version: 1,
        displayName: 'Smart Tile preset',
        summary: 'Topology, rules, candidates, and coverage contract',
      ),
      AuthoringResourceKindDescriptor(
        id: 'smartTileLayer',
        version: 1,
        displayName: 'Smart Tile layer',
        summary: 'Map-owned semantic field derived from a published preset',
      ),
      AuthoringResourceKindDescriptor(
        id: 'dialogue',
        version: 1,
        displayName: 'Dialogue',
        summary: 'Project dialogue metadata and external source',
      ),
      AuthoringResourceKindDescriptor(
        id: 'dialogueSource',
        version: 1,
        displayName: 'Dialogue source',
        summary: 'Revision-tracked external Yarn or legacy source',
      ),
      AuthoringResourceKindDescriptor(
        id: 'elementCategory',
        version: 1,
        displayName: 'Element category',
        summary: 'Hierarchical visual element category',
      ),
      AuthoringResourceKindDescriptor(
        id: 'script',
        version: 1,
        displayName: 'Script',
        summary: 'Embedded deterministic project script',
      ),
      AuthoringResourceKindDescriptor(
        id: 'scene',
        version: 1,
        displayName: 'Scene',
        summary: 'Project-owned executable narrative graph',
      ),
      AuthoringResourceKindDescriptor(
        id: 'eventV2',
        version: 1,
        displayName: 'Event V2',
        summary: 'Revision-gated narrative event record',
      ),
      AuthoringResourceKindDescriptor(
        id: 'fact',
        version: 1,
        displayName: 'Fact',
        summary: 'Typed narrative state definition',
      ),
      AuthoringResourceKindDescriptor(
        id: 'worldRule',
        version: 1,
        displayName: 'World Rule',
        summary: 'Runtime-consumed world projection rule',
      ),
      AuthoringResourceKindDescriptor(
        id: 'worldGraph',
        version: 1,
        displayName: 'World graph',
        summary: 'Bounded overview of authored map connectivity',
        extensions: const {
          'queryActions': ['world_graph.inspect', 'world_graph.render'],
          'childResourceKinds': [
            'worldGraphNode',
            'worldGraphEdge',
            'worldGraphIssue',
          ],
        },
      ),
      AuthoringResourceKindDescriptor(
        id: 'worldGraphNode',
        version: 1,
        displayName: 'World graph node',
        summary: 'One map in the paginated world graph',
        extensions: const {
          'queryActions': [
            'world_graph.list_connected',
            'world_graph.list_disconnected',
            'world_graph.find_path',
          ],
        },
      ),
      AuthoringResourceKindDescriptor(
        id: 'worldGraphEdge',
        version: 1,
        displayName: 'World graph edge',
        summary: 'One paginated connection or warp edge',
      ),
      AuthoringResourceKindDescriptor(
        id: 'worldGraphIssue',
        version: 1,
        displayName: 'World graph issue',
        summary: 'One paginated world graph consistency issue',
        extensions: const {
          'queryActions': ['world_graph.validate_consistency'],
        },
      ),
      AuthoringResourceKindDescriptor(
        id: 'storyline',
        version: 1,
        displayName: 'Storyline',
        summary: 'Chapter, Step and progression graph aggregate',
      ),
      AuthoringResourceKindDescriptor(
        id: 'scenario',
        version: 1,
        displayName: 'Scenario',
        summary: 'Legacy-readable local or global narrative flow',
      ),
      AuthoringResourceKindDescriptor(
        id: 'cinematic',
        version: 1,
        displayName: 'Cinematic',
        summary: 'Stage, actors and executable cinematic timeline',
      ),
      AuthoringResourceKindDescriptor(
        id: 'pokemonDocument',
        version: 1,
        displayName: 'Pokemon data document',
        summary: 'Catalog, species, learnset, evolution or media document',
      ),
      AuthoringResourceKindDescriptor(
        id: 'preset',
        version: 1,
        displayName: 'Preset',
        summary: 'Reusable authoring preset referenced by canonical mutations',
      ),
      AuthoringResourceKindDescriptor(
        id: 'campaignContent',
        version: 1,
        displayName: 'Campaign content',
        summary: 'Trainer, encounter, shop, badge, character or New Game data',
      ),
      AuthoringResourceKindDescriptor(
        id: 'sandboxPlayerState',
        version: 1,
        displayName: 'Sandbox player state',
        summary: 'Detached non-production party, PC, bag and save state',
      ),
      AuthoringResourceKindDescriptor(
        id: 'battleProgression',
        version: 1,
        displayName: 'Battle progression',
        summary: 'Deterministic battle, outcome and progression preview',
      ),
      AuthoringResourceKindDescriptor(
        id: 'tilesetFolder',
        version: 1,
        displayName: 'Tileset folder',
        summary: 'Hierarchical tileset library folder',
      ),
      AuthoringResourceKindDescriptor(
        id: 'tileLayer',
        version: 1,
        displayName: 'Tile layer',
        summary: 'Map-owned tile layer referenced by canonical mutations',
      ),
      AuthoringResourceKindDescriptor(
        id: 'tileset',
        version: 1,
        displayName: 'Tileset',
        summary: 'Project tileset referenced by canonical mutations',
      ),
    ], queryableResourceKindIds: const {
      'asset',
      'dialogue',
      'elementCategory',
      'eventV2',
      'fact',
      'map',
      'mapConnection',
      'project',
      'projectPresentationProfile',
      'scenario',
      'scene',
      'script',
      'smartTileAnimation',
      'smartTileAtlas',
      'smartTileDraft',
      'smartTileLayer',
      'smartTileMaterial',
      'smartTilePattern',
      'smartTilePreset',
      'storyline',
      'tilesetFolder',
      'worldGraph',
      'worldGraphEdge',
      'worldGraphIssue',
      'worldGraphNode',
      'worldRule',
    });
  }

  @Deprecated('Use AuthoringResourceKindRegistry.canonical() instead.')
  factory AuthoringResourceKindRegistry.canonicalMinimal() =>
      AuthoringResourceKindRegistry.canonical();

  factory AuthoringResourceKindRegistry.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(
      json,
      const {
        'formatVersion',
        'queryableResourceKindIds',
        'resourceKinds',
      },
    );
    if (json['formatVersion'] != 1) {
      throw FormatException(
        'Unsupported resource registry formatVersion: '
        '${json['formatVersion']}',
      );
    }
    final rawKinds = json['resourceKinds'];
    if (rawKinds is! List) {
      throw const FormatException('resourceKinds must be a JSON list');
    }
    return AuthoringResourceKindRegistry(
      rawKinds.map((rawKind) {
        if (rawKind is! Map) {
          throw const FormatException('resource kind must be a JSON object');
        }
        return AuthoringResourceKindDescriptor.fromJson(
          Map<String, dynamic>.from(rawKind),
        );
      }),
      queryableResourceKindIds: readContractStringList(
        json['queryableResourceKindIds'] ?? const <Object?>[],
        'queryableResourceKindIds',
      ),
    );
  }

  final List<AuthoringResourceKindDescriptor> resourceKinds;
  late final Set<String> queryableResourceKindIds;
  late final Map<String, AuthoringResourceKindDescriptor> _byId;

  AuthoringResourceKindDescriptor? find(String kindId) => _byId[kindId];

  AuthoringResourceKindDescriptor require(String kindId) {
    return find(kindId) ??
        (throw UnknownAuthoringResourceKindException(kindId));
  }

  Map<String, Object?> toJson() {
    return {
      'formatVersion': 1,
      'queryableResourceKindIds': queryableResourceKindIds.toList()..sort(),
      'resourceKinds': resourceKinds
          .map((descriptor) => descriptor.toJson())
          .toList(growable: false),
    };
  }

  static List<AuthoringResourceKindDescriptor> _validateAndSort(
    Iterable<AuthoringResourceKindDescriptor> descriptors,
  ) {
    final byId = <String, AuthoringResourceKindDescriptor>{};
    for (final descriptor in descriptors) {
      final existing = byId[descriptor.id];
      if (existing != null) {
        if (existing.version == descriptor.version) {
          throw DuplicateAuthoringResourceKindException(
            descriptor.id,
            descriptor.version,
          );
        }
        throw IncompatibleAuthoringResourceKindVersionException(
          descriptor.id,
          [existing.version, descriptor.version],
        );
      }
      byId[descriptor.id] = descriptor;
    }
    final sorted = byId.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return List.unmodifiable(sorted);
  }
}

String _nonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}

int _positiveVersion(int value) {
  try {
    return requirePositiveContractVersion(value, 'version');
  } on FormatException catch (error) {
    throw ArgumentError.value(value, 'version', error.message);
  }
}
