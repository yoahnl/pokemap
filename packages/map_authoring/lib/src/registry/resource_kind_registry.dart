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
        version: 10,
        displayName: 'Project presentation profile',
        summary:
            'Authored title and pause actions, responsive intro and motion, branding, typography metrics, contextual palettes, window shapes, surface layouts and combat presentation',
      ),
      AuthoringResourceKindDescriptor(
        id: 'projectPresentationPreset',
        version: 2,
        displayName: 'Project presentation preset',
        summary:
            'Versioned shareable presentation profile with explicit scope, replaced sections and licensed assets',
      ),
      AuthoringResourceKindDescriptor(
        id: 'presentationPreviewContext',
        version: 2,
        displayName: 'Presentation preview context',
        summary:
            'Read-only project maps, dialogue scenarios, portraits and encounters available to presentation previews',
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
        id: 'presentationMedia',
        version: 1,
        displayName: 'Presentation media',
        summary:
            'Stable logical media identity linked to project-owned source assets',
      ),
      AuthoringResourceKindDescriptor(
        id: 'cinematicLibraryCatalog',
        version: 1,
        displayName: 'Cinematic library catalog',
        summary:
            'Persistent folder and placement catalog for both cinematic families',
        extensions: const <String, Object?>{
          'childResourceKinds': <String>[
            'cinematicLibraryFolder',
            'cinematicLibraryEntry',
          ],
        },
      ),
      AuthoringResourceKindDescriptor(
        id: 'cinematicLibraryFolder',
        version: 1,
        displayName: 'Cinematic library folder',
        summary: 'Recursive stable folder scoped to one cinematic family',
      ),
      AuthoringResourceKindDescriptor(
        id: 'cinematicLibraryEntry',
        version: 1,
        displayName: 'Cinematic library entry',
        summary: 'Folder placement and archive state for one cinematic',
        extensions: const <String, Object?>{
          'idFormat': 'uriComponent(family):uriComponent(cinematicId)',
        },
      ),
      AuthoringResourceKindDescriptor(
        id: 'presentationCinematicTemplate',
        version: 1,
        displayName: 'Presentation cinematic template',
        summary:
            'Versioned canonical recipe for a responsive Presentation cinematic',
      ),
      AuthoringResourceKindDescriptor(
        id: 'presentationCinematic',
        version: 1,
        displayName: 'Presentation cinematic',
        summary: 'Project-owned out-of-engine cinematic timeline',
        extensions: const <String, Object?>{
          'childResourceKinds': <String>[
            'presentationTrack',
            'presentationClip',
            'presentationLayer',
            'presentationVisualFolder',
          ],
        },
      ),
      AuthoringResourceKindDescriptor(
        id: 'presentationTrack',
        version: 1,
        displayName: 'Presentation track',
        summary: 'Typed ordered track inside a Presentation cinematic',
        extensions: const <String, Object?>{
          'idFormat': 'uriComponent(cinematicId):uriComponent(trackId)',
        },
      ),
      AuthoringResourceKindDescriptor(
        id: 'presentationClip',
        version: 1,
        displayName: 'Presentation clip',
        summary: 'Temporal clip inside a Presentation cinematic track',
        extensions: const <String, Object?>{
          'idFormat': 'uriComponent(cinematicId):uriComponent(trackId):'
              'uriComponent(clipId)',
        },
      ),
      AuthoringResourceKindDescriptor(
        id: 'presentationLayer',
        version: 1,
        displayName: 'Presentation layer',
        summary: 'Visual stacking layer inside a Presentation cinematic',
        extensions: const <String, Object?>{
          'idFormat': 'uriComponent(cinematicId):uriComponent(layerId)',
        },
      ),
      AuthoringResourceKindDescriptor(
        id: 'presentationVisualFolder',
        version: 1,
        displayName: 'Presentation visual folder',
        summary:
            'One-level visual organization folder inside a Presentation cinematic',
        extensions: const <String, Object?>{
          'idFormat': 'uriComponent(cinematicId):uriComponent(folderId)',
        },
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
        id: 'characterStudioCatalog',
        version: 1,
        displayName: 'Character Studio catalog',
        summary: 'Global portrait states and animation definitions',
      ),
      AuthoringResourceKindDescriptor(
        id: 'characterStudioCharacter',
        version: 1,
        displayName: 'Character Studio character',
        summary: 'Character identity, media coverage and selection status',
      ),
      AuthoringResourceKindDescriptor(
        id: 'characterStudioDependency',
        version: 1,
        displayName: 'Character Studio dependency',
        summary: 'Stable reference targeting Character Studio content',
      ),
      AuthoringResourceKindDescriptor(
        id: 'characterStudioReadiness',
        version: 1,
        displayName: 'Character Studio readiness',
        summary: 'Per-character media coverage and readiness diagnostics',
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
        id: 'itemCatalog',
        version: 1,
        displayName: 'Item catalog',
        summary: 'Canonical project-owned item catalog',
      ),
      AuthoringResourceKindDescriptor(
        id: 'itemDefinition',
        version: 1,
        displayName: 'Item definition',
        summary: 'One canonical item definition and its capabilities',
        extensions: const <String, Object?>{
          'queryActions': <String>[
            'item.delete_plan',
            'item.simulate',
            'item.validate',
          ],
        },
      ),
      AuthoringResourceKindDescriptor(
        id: 'itemUsage',
        version: 1,
        displayName: 'Item usage',
        summary: 'One editable project dependency on an item',
      ),
      AuthoringResourceKindDescriptor(
        id: 'itemReadiness',
        version: 1,
        displayName: 'Item readiness',
        summary: 'Validation and dependency readiness for one item',
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
      'characterStudioCatalog',
      'characterStudioCharacter',
      'characterStudioDependency',
      'characterStudioReadiness',
      'cinematicLibraryCatalog',
      'cinematicLibraryEntry',
      'cinematicLibraryFolder',
      'dialogue',
      'elementCategory',
      'eventV2',
      'fact',
      'itemCatalog',
      'itemDefinition',
      'itemReadiness',
      'itemUsage',
      'map',
      'mapConnection',
      'project',
      'projectPresentationProfile',
      'projectPresentationPreset',
      'presentationPreviewContext',
      'presentationCinematicTemplate',
      'presentationCinematic',
      'presentationTrack',
      'presentationClip',
      'presentationLayer',
      'presentationVisualFolder',
      'presentationMedia',
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
