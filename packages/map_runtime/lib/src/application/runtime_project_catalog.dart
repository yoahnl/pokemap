import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_character_refs.dart';
import 'runtime_catalog_map_cache.dart';
import 'runtime_manifest_tilesets.dart';

final class RuntimeCatalogDefinitionMissingException extends FormatException {
  RuntimeCatalogDefinitionMissingException(this.key)
    : super('catalog.runtime: missing definition $key');

  final CatalogDefinitionKey key;
}

final class RuntimeProjectCatalog {
  RuntimeProjectCatalog._({
    required this.projectFilePath,
    required this.identity,
    required this.projectMetadata,
    required this._sourceFingerprint,
    this._portable,
    this._native = const {},
    this._reader,
    this._working,
    required int maximumCachedMaps,
    required int maximumCachedMapBytes,
  }) : _mapCache = RuntimeCatalogMapCache(
         projectFilePath: projectFilePath,
         maximumMaps: maximumCachedMaps,
         maximumSourceBytes: maximumCachedMapBytes,
       ) {
    _owners[projectMetadata] = this;
  }

  static final _owners = Expando<RuntimeProjectCatalog>();

  static RuntimeProjectCatalog? ownerOf(ProjectManifest project) {
    final owner = _owners[project];
    return owner?._disposed == false ? owner : null;
  }

  final String projectFilePath;
  final String identity;
  final String _sourceFingerprint;
  final ProjectManifest projectMetadata;
  final PortableProjectCatalog? _portable;
  final Map<CatalogDefinitionKey, Object> _native;
  final _RuntimeCatalogObjectReader? _reader;
  final WorkingProjectCatalog? _working;
  final RuntimeCatalogMapCache _mapCache;
  Future<AssetCatalog?>? _assetCatalog;
  static const _maximumManifestProjections = 8;
  static const _maximumManifestSourceBytes = 8 * 1024 * 1024;
  final _manifestProjections =
      <String, Future<({ProjectManifest project, int sourceBytes})>>{};
  final _manifestProjectionBytes = <String, int>{};
  var _manifestSourceBytes = 0;
  bool _disposed = false;

  static Future<RuntimeProjectCatalog> open(
    String projectFilePath, {
    CatalogStorageLimits? limits,
    String? expectedSourceSha256,
    int maximumCatalogJsonValues = 8000000,
    int maximumCachedMaps = 8,
    int maximumCachedMapBytes = 32 * 1024 * 1024,
  }) async {
    if (expectedSourceSha256 != null &&
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(expectedSourceSha256)) {
      throw const FormatException(
        'Invalid expected project source fingerprint.',
      );
    }
    if (maximumCachedMaps < 0 ||
        maximumCachedMaps > 8 ||
        maximumCachedMapBytes < 0 ||
        maximumCachedMapBytes > 32 * 1024 * 1024) {
      throw ArgumentError('Runtime map cache ceilings can only be lowered.');
    }
    final effective =
        limits ?? CatalogStorageLimits(maxStoredBytes: 128 * 1024 * 1024);
    if (effective.maxStoredBytes > 128 * 1024 * 1024 ||
        maximumCatalogJsonValues < 1 ||
        maximumCatalogJsonValues > 8000000) {
      throw ArgumentError('Runtime catalog ceilings can only be lowered.');
    }
    final canonicalPath = await File(projectFilePath).resolveSymbolicLinks();
    final file = File(canonicalPath);
    if (await file.length() > 128 * 1024 * 1024) {
      throw const FormatException('Project document exceeds its byte limit.');
    }
    final bytes = await _readBoundedFile(file, 128 * 1024 * 1024);
    final sourceFingerprint = _runtimePublicationFingerprint(bytes);
    if (expectedSourceSha256 != null &&
        sourceFingerprint != 'sha256:$expectedSourceSha256') {
      throw const FormatException(
        'Project source fingerprint does not match the admitted bytes.',
      );
    }
    final source = utf8.decode(bytes);
    final raw = decodeNarrativeEventJsonStrict(source);
    if (raw is! Map<String, Object?>) {
      throw const FormatException('Expected a project JSON object.');
    }
    if (raw['format'] == 'avelune.working-catalog') {
      final descriptor = WorkingProjectCatalogDescriptor.fromJson(raw);
      final reader = _RuntimeCatalogObjectReader(
        file.parent.path,
        limits: effective,
        maximumJsonValues: maximumCatalogJsonValues,
      );
      WorkingProjectCatalog? working;
      try {
        working = await WorkingProjectCatalog.open(
          store: CatalogStorageStore(
            projectRoot: file.parent.path,
            reader: reader,
            gateway: await LocalTransactionFileGateway.open(
              projectRoot: file.parent.path,
            ),
            limits: effective,
          ),
          descriptor: descriptor,
        );
        return RuntimeProjectCatalog._(
          sourceFingerprint: sourceFingerprint,
          maximumCachedMaps: maximumCachedMaps,
          maximumCachedMapBytes: maximumCachedMapBytes,
          projectFilePath: canonicalPath,
          identity: '$canonicalPath:${working.root.sha256}',
          projectMetadata: working.catalog.projectMetadata,
          portable: working.catalog,
          reader: reader,
          working: working,
        );
      } on Object {
        await working?.close();
        reader.dispose();
        rethrow;
      }
    }
    if (raw.containsKey('format') ||
        raw.containsKey('kind') ||
        raw.containsKey('root')) {
      final reader = _RuntimeCatalogObjectReader(
        file.parent.path,
        limits: effective,
        maximumJsonValues: maximumCatalogJsonValues,
      );
      final portable = await PortableProjectCatalog.open(
        raw,
        limits: effective,
        readObject: reader.read,
      );
      return RuntimeProjectCatalog._(
        sourceFingerprint: sourceFingerprint,
        maximumCachedMaps: maximumCachedMaps,
        maximumCachedMapBytes: maximumCachedMapBytes,
        projectFilePath: canonicalPath,
        identity: '$canonicalPath:${portable.snapshot.root.sha256}',
        projectMetadata: portable.projectMetadata,
        portable: portable,
        reader: reader,
      );
    }
    final decoded = ProjectManifest.fromJson(raw);
    final project = decoded.copyWith(
      globalProperties: _immutableRuntimeProperty(
        decoded.globalProperties,
        0,
      ) as Map<String, dynamic>,
      elements: [
        for (final element in decoded.elements)
          element.collisionProfile == null
              ? element
              : element.copyWith(
                  collisionProfile: normalizeElementCollisionProfile(
                    element.collisionProfile!,
                    tileSize: decoded.settings.tileWidth,
                  ),
                ),
      ],
    );
    ProjectValidator.validate(project);
    return RuntimeProjectCatalog._(
      sourceFingerprint: sourceFingerprint,
      maximumCachedMaps: maximumCachedMaps,
      maximumCachedMapBytes: maximumCachedMapBytes,
      projectFilePath: canonicalPath,
      identity: '$canonicalPath:${narrativeEventCanonicalSha256(raw)}',
      projectMetadata: project.copyWith(
        tilesets: const [],
        elements: const [],
        models3d: const [],
        characters: const [],
        environmentPresets: const [],
        smartTileCatalog: const ProjectSmartTileCatalog.empty(),
        borderCatalog: ProjectBorderCatalog(
          formatVersion: project.borderCatalog.formatVersion,
        ),
        elementCategories: const [],
        tilesetFolders: const [],
        characterStudioCatalog: const ProjectCharacterStudioCatalog(),
        resourceLibraryCatalog: const ResourceLibraryCatalog.empty(),
      ),
      native: _nativeDefinitions(project),
    );
  }

  Future<MapData> loadMapData(String mapId) {
    _ensureOpen();
    final matches = projectMetadata.maps.where((entry) => entry.id == mapId);
    if (matches.length != 1) {
      throw MapLoadException('Map id not in project: $mapId');
    }
    return _mapCache.load(matches.single);
  }

  Future<List<MapData>> loadNarrativeMapData({
    Map<String, String>? expectedSha256ByMapId,
  }) {
    _ensureOpen();
    final expected = expectedSha256ByMapId == null
        ? null
        : Map<String, String>.unmodifiable(expectedSha256ByMapId);
    if (expected != null &&
        (expected.length != projectMetadata.maps.length ||
            !projectMetadata.maps.every(
              (entry) => expected.containsKey(entry.id),
            ) ||
            expected.values.any(
              (hash) => !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash),
            ))) {
      throw const FormatException(
        'Expected map source fingerprints do not match the project maps.',
      );
    }
    return _mapCache.loadNarrativeMaps(
      projectMetadata.maps,
      PixelSize(
        width: projectMetadata.settings.tileWidth,
        height: projectMetadata.settings.tileHeight,
      ),
      expectedSha256ByMapId: expected,
    );
  }

  Future<AssetCatalog?> loadAssetCatalog() {
    _ensureOpen();
    return _assetCatalog ??= () async {
      final file = File(
        p.join(p.dirname(projectFilePath), assetCatalogStorageKey),
      );
      if (!await file.exists()) return null;
      if (await file.length() > 32 * 1024 * 1024) {
        throw const FormatException('Asset catalog exceeds its byte limit.');
      }
      final json = decodeNarrativeEventJsonStrict(
        utf8.decode(await _readBoundedFile(file, 32 * 1024 * 1024)),
      );
      _ensureOpen();
      if (json is! Map<String, Object?>) {
        throw const FormatException('Expected an asset catalog JSON object.');
      }
      return AssetCatalog.fromJson(json);
    }();
  }

  Future<bool> isCurrentPublication() async {
    if (_disposed) return false;
    try {
      final file = File(projectFilePath);
      if (await file.resolveSymbolicLinks() != projectFilePath) return false;
      final maximum = _portable == null ? 128 * 1024 * 1024 : 64 * 1024;
      final bytes = await _readBoundedFile(file, maximum);
      if (_disposed) return false;
      final working = _working;
      if (working != null) {
        final raw = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
        if (raw is! Map<String, Object?> ||
            WorkingProjectCatalogDescriptor.fromJson(raw).projectId !=
                working.descriptor.projectId) {
          return false;
        }
        return await working.readCatalog((_) async => !_disposed);
      }
      if (_runtimePublicationFingerprint(bytes) == _sourceFingerprint) {
        return true;
      }
      final source = utf8.decode(bytes);
      if (_portable != null) {
        PortableCatalogPublication.validateProjectMetadataJson(source);
      }
      final raw = decodeNarrativeEventJsonStrict(source);
      if (_disposed || raw is! Map<String, Object?>) return false;
      final portable = _portable;
      if (portable != null) {
        return raw.length == 4 &&
            raw['format'] == 'avelune.portable-catalog' &&
            raw['kind'] == 'project' &&
            raw['version'] is int &&
            raw['version'] == 2 &&
            CatalogObjectReference.fromJson(
                  Map<String, Object?>.from(raw['root']! as Map),
                ) ==
                portable.snapshot.root;
      }
      return !raw.containsKey('format') &&
          !raw.containsKey('kind') &&
          !raw.containsKey('root') &&
          identity == '$projectFilePath:${narrativeEventCanonicalSha256(raw)}';
    } on Object {
      return false;
    }
  }

  Future<ProjectManifest> manifestForMap(
    MapData map, {
    Iterable<String> extraCharacterIds = const [],
    Iterable<String> extraSceneIds = const [],
  }) => manifestForMaps(
    [map],
    extraCharacterIds: extraCharacterIds,
    extraSceneIds: extraSceneIds,
  );

  Future<ProjectManifest> manifestForMaps(
    Iterable<MapData> maps, {
    Iterable<String> extraCharacterIds = const [],
    Iterable<String> extraSceneIds = const [],
    Iterable<CatalogDefinitionKey> extraDefinitionKeys = const [],
  }) => _manifestForMaps(
    maps,
    extraCharacterIds: extraCharacterIds,
    extraSceneIds: extraSceneIds,
    includeMapVisuals: true,
    extraDefinitionKeys: extraDefinitionKeys,
  );

  Future<ProjectManifest> manifestForNarrativeMaps(
    Iterable<NarrativeMapView> maps,
  ) => _manifestForMaps(
    maps,
    extraSceneIds: projectMetadata.scenes.map((scene) => scene.id),
    includeMapVisuals: false,
  );

  Future<ProjectManifest> _manifestForMaps(
    Iterable<NarrativeMapView> maps, {
    Iterable<String> extraCharacterIds = const [],
    Iterable<String> extraSceneIds = const [],
    required bool includeMapVisuals,
    Iterable<CatalogDefinitionKey> extraDefinitionKeys = const [],
  }) async {
    _ensureOpen();
    final roots = <CatalogDefinitionKey>{...extraDefinitionKeys};
    final additionalCharacters = extraCharacterIds.toSet();
    final additionalScenes = extraSceneIds.toSet();
    for (final map in maps) {
      final characterIds = collectRuntimeMapCharacterIds(
        map,
        projectMetadata,
        additionalCharacterIds: additionalCharacters,
        additionalSceneIds: additionalScenes,
      );
      for (final event in map.events) {
        for (final page in event.pages) {
          final id = page.spriteId;
          if (id == null || id.isEmpty) continue;
          final key = CatalogDefinitionKey(CatalogDefinitionKind.character, id);
          if (_native.containsKey(key) ||
              await _portable?.snapshot.indexEntry(key) != null) {
            characterIds.add(id);
          }
        }
      }
      for (final root in _mapRoots(
        map,
        projectMetadata,
        characterIds,
        additionalScenes,
        includeMapVisuals: includeMapVisuals,
      )) {
        roots.add(root);
      }
      final sceneIds = collectRuntimeMapSceneIds(
        map,
        projectMetadata,
        additionalSceneIds: additionalScenes,
      );
      for (final scene in projectMetadata.scenes) {
        if (!sceneIds.contains(scene.id)) continue;
        for (final node in scene.graph.nodes) {
          final payload = node.payload;
          if (payload is! SceneYarnDialoguePayload) continue;
          for (final policy in payload.linePolicies) {
            for (final icon
                in policy.feedback.segments.whereType<DialogueIconSegment>()) {
              final key = CatalogDefinitionKey(
                CatalogDefinitionKind.tileset,
                icon.assetId,
              );
              if (_native.containsKey(key) ||
                  await _portable?.snapshot.indexEntry(key) != null) {
                roots.add(key);
              }
            }
          }
        }
      }
    }
    return _manifestForRoots(roots);
  }

  Future<ProjectManifest> manifestForCharacter(String characterId) =>
      _manifestForRoots([
        CatalogDefinitionKey(CatalogDefinitionKind.character, characterId),
      ]);

  ProjectManifest mergeNarrativeVisualDefinitions(
    ProjectManifest project,
    Iterable<ProjectManifest> views,
  ) {
    _ensureOpen();
    final sources = [project, ...views];
    if (sources.any((view) => !identical(ownerOf(view), this))) {
      throw StateError(
        'Narrative views must belong to the same runtime catalog.',
      );
    }
    final merged = project.copyWith(
      models3d: _mergeNarrativeVisualDefinitions(
        sources.expand((view) => view.models3d),
        (entry) => entry.id,
        (entry) => entry.toJson(),
      ),
      elements: _mergeNarrativeVisualDefinitions(
        sources.expand((view) => view.elements),
        (entry) => entry.id,
        (entry) => entry.toJson(),
      ),
      characters: _mergeNarrativeVisualDefinitions(
        sources.expand((view) => view.characters),
        (entry) => entry.id,
        (entry) => entry.toJson(),
      ),
      tilesets: _mergeNarrativeVisualDefinitions(
        sources.expand((view) => view.tilesets),
        (entry) => entry.id,
        (entry) => entry.toJson(),
      ),
      elementCategories: _mergeNarrativeVisualDefinitions(
        sources.expand((view) => view.elementCategories),
        (entry) => entry.id,
        (entry) => entry.toJson(),
      ),
    );
    _owners[merged] = this;
    return merged;
  }

  Future<ProjectManifest> _manifestForRoots(
    Iterable<CatalogDefinitionKey> roots,
  ) async {
    _ensureOpen();
    if (_portable == null) {
      final result = await _buildManifestForRoots(roots);
      _ensureOpen();
      return result.project;
    }
    final ordered = roots.toSet().toList()..sort();
    final key = jsonEncode([
      for (final root in ordered) [root.kind.name, root.id],
    ]);
    var future = _manifestProjections.remove(key);
    if (future != null) {
      _manifestProjections[key] = future;
    } else {
      future = _buildManifestForRoots(ordered);
      if (ordered.length <= 256) {
        final pending = future;
        _manifestProjections[key] = pending;
        _trimManifestProjections();
        pending.then<void>(
          (result) {
            if (!identical(_manifestProjections[key], pending)) return;
            if (result.sourceBytes > _maximumManifestSourceBytes) {
              _removeManifestProjection(key);
              return;
            }
            _manifestProjectionBytes[key] = result.sourceBytes;
            _manifestSourceBytes += result.sourceBytes;
            _trimManifestProjections();
          },
          onError: (Object error, StackTrace stack) {
            if (identical(_manifestProjections[key], pending)) {
              _removeManifestProjection(key);
            }
          },
        );
      }
    }
    final result = await future;
    _ensureOpen();
    return result.project;
  }

  void _removeManifestProjection(String key) {
    _manifestProjections.remove(key);
    _manifestSourceBytes -= _manifestProjectionBytes.remove(key) ?? 0;
  }

  void _trimManifestProjections() {
    while (_manifestProjections.length > _maximumManifestProjections ||
        _manifestSourceBytes > _maximumManifestSourceBytes) {
      _removeManifestProjection(_manifestProjections.keys.first);
    }
  }

  Future<({ProjectManifest project, int sourceBytes})> _buildManifestForRoots(
    Iterable<CatalogDefinitionKey> roots,
  ) async {
    _ensureOpen();
    final units = <CatalogDefinitionKey, CatalogDefinitionUnit>{};
    final selected = <CatalogDefinitionKey, Object>{};
    final active = <CatalogDefinitionKey>{};
    final dynamic = {
      for (final declaration
          in PortableCatalogPublication.projectDynamicDependencies(
            projectMetadata,
          ))
        declaration.owner: declaration.targets,
    };
    Future<void> visit(CatalogDefinitionKey key, int depth) async {
      _ensureOpen();
      if (active.contains(key)) {
        throw FormatException('catalog.runtime: dependency cycle at $key');
      }
      if (selected.containsKey(key)) return;
      if (depth > (_portable?.snapshot.limits.maxClosureDepth ?? 128) ||
          selected.length >=
              (_portable?.snapshot.limits.maxClosureNodes ?? 100000)) {
        throw const FormatException('catalog.runtime: closure budget exceeded');
      }
      active.add(key);
      ProjectManifest? view;
      Object? libraryValue;
      final portable = _portable;
      if (portable != null) {
        final unit = await portable.lookup(key);
        _ensureOpen();
        if (unit == null) {
          throw RuntimeCatalogDefinitionMissingException(key);
        }
        units[key] = unit;
        selected[key] = unit;
        final value = portable.definitionValue(unit);
        if (value is ResourceLibraryEntry || value is ResourceFamily) {
          libraryValue = value;
        } else {
          view = _nativeProjection(projectMetadata, {key: value});
        }
      } else {
        final value = _native[key];
        if (value == null) {
          throw RuntimeCatalogDefinitionMissingException(key);
        }
        selected[key] = value;
        if (value is ResourceLibraryEntry || value is ResourceFamily) {
          libraryValue = value;
        } else {
          view = _nativeProjection(projectMetadata, {key: value});
        }
      }
      final familyId = switch (libraryValue) {
        ResourceLibraryEntry(:final familyId) => familyId,
        ResourceFamily(:final parentId) => parentId,
        _ => null,
      };
      for (final dependency in {
        if (view != null) ..._definitionDependencies(view),
        if (familyId != null &&
            !ResourceLibraryCatalog.predefinedFamilies.any(
              (family) => family.id == familyId,
            ))
          CatalogDefinitionKey(CatalogDefinitionKind.resourceFamily, familyId),
        ...?units[key]?.references,
        ...?dynamic[key],
      }) {
        await visit(dependency, depth + 1);
      }
      final resourceKind = key.kind == CatalogDefinitionKind.borderRecord
          ? 'borderBlueprint'
          : key.kind.name;
      if (ResourceLibraryCatalog.resourceKinds.contains(resourceKind)) {
        final classificationKey = CatalogDefinitionKey(
          CatalogDefinitionKind.resourceLibraryEntry,
          '$resourceKind:${key.id}',
        );
        if (_native.containsKey(classificationKey) ||
            await _portable?.snapshot.indexEntry(classificationKey) != null) {
          await visit(classificationKey, depth + 1);
        }
      }
      active.remove(key);
    }

    for (final root in roots) {
      await visit(root, 0);
    }
    _ensureOpen();
    final selectedProject =
        _portable?.projectWithDefinitions(units.values) ??
        _nativeProjection(projectMetadata, selected);
    final project = selectedProject.copyWith(
      elements: [
        for (final element in selectedProject.elements)
          element.collisionProfile == null
              ? element
              : element.copyWith(
                  collisionProfile: normalizeElementCollisionProfile(
                    element.collisionProfile!,
                    tileSize: selectedProject.settings.tileWidth,
                  ),
                ),
      ],
    );
    var sourceBytes = 0;
    final portable = _portable;
    if (portable != null) {
      if (units.length > 256) {
        sourceBytes = _maximumManifestSourceBytes + 1;
      } else {
        for (final key in units.keys) {
          final entry = await portable.snapshot.indexEntry(key);
          _ensureOpen();
          if (entry == null) {
            throw RuntimeCatalogDefinitionMissingException(key);
          }
          sourceBytes += entry.reference.byteLength;
          if (sourceBytes > _maximumManifestSourceBytes) break;
        }
      }
    }
    _owners[project] = this;
    return (project: project, sourceBytes: sourceBytes);
  }

  void dispose() {
    _disposed = true;
    _assetCatalog = null;
    _manifestProjections.clear();
    _manifestProjectionBytes.clear();
    _manifestSourceBytes = 0;
    _mapCache.dispose();
    if (_native.isNotEmpty) _native.clear();
    _reader?.dispose();
    final working = _working;
    if (working != null) unawaited(working.close());
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('Runtime project catalog is disposed.');
  }
}

List<T> _mergeNarrativeVisualDefinitions<T>(
  Iterable<T> entries,
  String Function(T) identityOf,
  Map<String, dynamic> Function(T) jsonOf,
) {
  final definitions = <String, T>{};
  for (final entry in entries) {
    final id = identityOf(entry);
    final existing = definitions[id];
    if (existing != null &&
        !identical(existing, entry) &&
        canonicalizeNarrativeEventJson(jsonOf(existing)) !=
            canonicalizeNarrativeEventJson(jsonOf(entry))) {
      throw StateError(
        'Event V2 runtime snapshot has conflicting visual definition "$id".',
      );
    }
    definitions[id] = entry;
  }
  return List.unmodifiable(definitions.values);
}

Object? _immutableRuntimeProperty(Object? value, int depth) {
  if (depth > 128) {
    throw const FormatException('catalog.runtime: property depth limit');
  }
  if (value is Map) {
    return Map<String, Object?>.unmodifiable({
      for (final entry in value.entries)
        entry.key as String: _immutableRuntimeProperty(entry.value, depth + 1),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable([
      for (final child in value) _immutableRuntimeProperty(child, depth + 1),
    ]);
  }
  return value;
}

final class _RuntimeCatalogObjectReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  _RuntimeCatalogObjectReader(
    this.root, {
    required this.limits,
    required this.maximumJsonValues,
  });
  final String root;
  final CatalogStorageLimits limits;
  final int maximumJsonValues;
  final Map<String, Future<Uint8List>> _cache = {};
  final _seen = <String>{};
  final _measured = <String>{};
  final _sizes = <String, int>{};
  var _bytes = 0;
  var _values = 0;
  var _cachedBytes = 0;
  var _disposed = false;

  @override
  bool get supportsStreamingResources => true;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      const LocalProjectFileReader().canonicalizeDirectory(path);

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => const LocalProjectFileReader().probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    if (projectRoot != root) {
      throw const FormatException('Catalog reader root mismatch.');
    }
    final match = RegExp(r'^catalog/objects/([0-9a-f]{64})\.json$')
        .firstMatch(relativePath);
    if (match == null) {
      return const LocalProjectFileReader().readBytes(
        projectRoot: projectRoot,
        relativePath: relativePath,
      );
    }
    final file = File(p.join(root, relativePath));
    final resolved = await file.resolveSymbolicLinks();
    if (!p.isWithin(root, resolved)) {
      throw const FormatException('Invalid catalog object path.');
    }
    return read(
      CatalogObjectReference(
        sha256: match.group(1)!,
        byteLength: await file.length(),
      ),
    );
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) async* {
    if (projectRoot != root) {
      throw const FormatException('Catalog reader root mismatch.');
    }
    if (relativePath.startsWith('catalog/objects/')) {
      yield await readBytes(
        projectRoot: projectRoot,
        relativePath: relativePath,
      );
    } else {
      yield* const LocalProjectFileReader().openRead(
        projectRoot: projectRoot,
        relativePath: relativePath,
      );
    }
  }

  void dispose() {
    _disposed = true;
    _cache.clear();
    _sizes.clear();
    _seen.clear();
    _measured.clear();
    _cachedBytes = 0;
  }

  Future<Uint8List> read(CatalogObjectReference reference) {
    if (_disposed) {
      throw StateError('Runtime catalog object reader is disposed.');
    }
    final existing = _cache.remove(reference.sha256);
    if (existing != null) {
      _cache[reference.sha256] = existing;
      return existing;
    }
    if (!_seen.contains(reference.sha256)) {
      final admitted = _bytes + reference.byteLength;
      if (admitted > limits.maxStoredBytes) {
        throw const FormatException('Global catalog byte quota exceeded.');
      }
      _bytes = admitted;
      _seen.add(reference.sha256);
    }
    final future = () async {
      final file = File(
        p.join(root, PortableCatalogPublication.objectPath(reference)),
      );
      final resolved = await file.resolveSymbolicLinks();
      if (!p.isWithin(root, resolved) ||
          !await FileSystemEntity.isFile(resolved) ||
          await file.length() != reference.byteLength) {
        throw const FormatException('Invalid catalog object path or size.');
      }
      final bytes = await _readBoundedFile(file, reference.byteLength);
      if (_disposed) {
        throw StateError('Runtime catalog object reader is disposed.');
      }
      final values = PortableCatalogPublication.validateCatalogObjectBytes(
        reference,
        bytes,
        limits: limits,
      );
      if (!_measured.contains(reference.sha256)) {
        final admitted = _values + values;
        if (admitted > maximumJsonValues) {
          throw const FormatException('Global catalog value quota exceeded.');
        }
        _values = admitted;
        _measured.add(reference.sha256);
      }
      return bytes;
    }();
    _cache[reference.sha256] = future;
    _sizes[reference.sha256] = reference.byteLength;
    _cachedBytes += reference.byteLength;
    while (_cachedBytes > 4 * 1024 * 1024 && _cache.length > 1) {
      final first = _cache.keys.first;
      _cache.remove(first);
      _cachedBytes -= _sizes.remove(first)!;
    }
    future.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        if (identical(_cache[reference.sha256], future)) {
          _cache.remove(reference.sha256);
          _cachedBytes -= _sizes.remove(reference.sha256) ?? 0;
        }
      },
    );
    return future;
  }
}

Future<ProjectManifest> loadWorkingRuntimeProjectManifest(
  String projectFilePath, {
  required String expectedSourceSha256,
}) async {
  final catalog = await RuntimeProjectCatalog.open(
    projectFilePath,
    expectedSourceSha256: expectedSourceSha256,
  );
  try {
    final working = catalog._working;
    if (working == null) {
      throw const FormatException('Expected a working project catalog.');
    }
    return await working.exportProject();
  } finally {
    catalog.dispose();
  }
}

Future<Uint8List> _readBoundedFile(File file, int maximumBytes) async {
  final builder = await file
      .openRead(0, maximumBytes + 1)
      .fold<BytesBuilder>(
        BytesBuilder(copy: false),
        (builder, bytes) => builder..add(bytes),
      );
  if (builder.length > maximumBytes) {
    throw const FormatException('File exceeds its byte limit.');
  }
  return builder.takeBytes();
}

Iterable<CatalogDefinitionKey> _mapRoots(
  NarrativeMapView map,
  ProjectManifest metadata,
  Iterable<String> extraCharacterIds,
  Iterable<String> extraSceneIds, {
  required bool includeMapVisuals,
}) sync* {
  CatalogDefinitionKey key(CatalogDefinitionKind kind, String id) =>
      CatalogDefinitionKey(kind, id);
  if (includeMapVisuals) {
    final renderMap = map as MapData;
    if (renderMap.tilesetId.isNotEmpty) {
      yield key(CatalogDefinitionKind.tileset, renderMap.tilesetId);
    }
    for (final layer in renderMap.layers) {
      switch (layer) {
        case TileLayer(:final palette):
          for (final tile in palette) {
            yield key(CatalogDefinitionKind.tileset, tile.tilesetId);
          }
        case ObjectLayer(:final tileObjects):
          for (final tile in tileObjects) {
            yield key(CatalogDefinitionKind.tileset, tile.tile.tilesetId);
          }
        case SmartTileLayer(
          :final presetId,
          :final patternStrokes,
          :final materialPalette,
        ):
          yield key(CatalogDefinitionKind.smartTilePreset, presetId);
          for (final material in materialPalette.where((id) => id.isNotEmpty)) {
            yield key(CatalogDefinitionKind.smartTileMaterial, material);
          }
          for (final stroke in patternStrokes) {
            yield key(CatalogDefinitionKind.smartTilePattern, stroke.patternId);
          }
        case EnvironmentLayer(:final content):
          for (final area in content.areas) {
            yield key(CatalogDefinitionKind.environmentPreset, area.presetId);
          }
        case BorderLayer(:final content):
          for (final feature in content.features) {
            yield key(CatalogDefinitionKind.borderRecord, feature.blueprintId);
            for (final placement
                in feature.materialization?.placements ??
                    const <BorderResolvedPlacement>[]) {
              yield key(
                CatalogDefinitionKind.borderVisualSnapshot,
                placement.visualSnapshotId,
              );
            }
            for (final ground
                in feature.materialization?.ground ??
                    const <BorderResolvedGroundCell>[]) {
              yield key(
                CatalogDefinitionKind.borderVisualSnapshot,
                ground.visualSnapshotId,
              );
            }
          }
        default:
          break;
      }
    }
    for (final element in renderMap.placedElements) {
      yield key(CatalogDefinitionKind.element, element.elementId);
    }
    for (final platform in renderMap.movingPlatforms) {
      for (final variant in platform.variants) {
        yield key(CatalogDefinitionKind.element, variant.elementId);
      }
    }
  }
  for (final trainer in metadata.trainers) {
    final character = trainer.characterId?.trim();
    if (character != null && character.isNotEmpty) {
      yield key(CatalogDefinitionKind.character, character);
    }
    final portrait = trainer.portraitElementId?.trim();
    if (portrait != null && portrait.isNotEmpty) {
      yield key(CatalogDefinitionKind.element, portrait);
    }
  }
  final player = metadata.settings.defaultPlayerCharacterId;
  for (final id in {
    if (player != null && player.isNotEmpty) player,
    ...extraCharacterIds,
  }) {
    yield key(CatalogDefinitionKind.character, id);
  }
  for (final entity in map.entities) {
    final visual = entity.resolvedProjectElementIdForEditor;
    if (visual != null && visual.isNotEmpty) {
      yield key(CatalogDefinitionKind.element, visual);
    }
    for (final id
        in entity.healingDisplay?.variantElementIds ?? const <String>[]) {
      yield key(CatalogDefinitionKind.element, id);
    }
    final character = resolveNpcCharacterId(entity, metadata);
    if (character != null) {
      yield key(CatalogDefinitionKind.character, character);
    }
  }
  for (final instance
      in map.spatialScene?.instances ?? const <SpatialModelInstance>[]) {
    yield key(CatalogDefinitionKind.model3d, instance.modelId);
  }
  if (includeMapVisuals && map.spatialScene?.cliffFrame != null) {
    final frame = map.spatialScene!.cliffFrame!;
    yield key(CatalogDefinitionKind.smartTileAtlas, frame.atlasId);
  }
  final sceneIds = collectRuntimeMapSceneIds(
    map,
    metadata,
    additionalSceneIds: extraSceneIds.toSet(),
  );
  for (final scene in metadata.scenes.where(
    (scene) => sceneIds.contains(scene.id),
  )) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is SceneActionPayload) {
        if (payload.interactiveCommand case SceneActorRouteInteractiveCommand(
          :final steps,
        )) {
          for (final step in steps) {
            if (step is SceneActorAppearanceStep)
              yield key(CatalogDefinitionKind.character, step.characterId);
          }
        }
        if (payload.interactiveCommand case SceneWarpInteractiveCommand(
          :final presentation,
        )) {
          if (presentation?.illustrationElementId case final id?) {
            yield key(CatalogDefinitionKind.element, id);
          }
        }
      }
    }
  }
}

Iterable<CatalogDefinitionKey> _definitionDependencies(
  ProjectManifest view,
) sync* {
  CatalogDefinitionKey key(CatalogDefinitionKind kind, String id) =>
      CatalogDefinitionKey(kind, id);
  for (final tileset in view.tilesets) {
    if (tileset.folderId case final id?) {
      yield key(CatalogDefinitionKind.tilesetFolder, id);
    }
    for (final entry in tileset.paletteEntries) {
      for (final frame in entry.frames) {
        if (frame.tilesetId.isNotEmpty && frame.tilesetId != tileset.id) {
          yield key(CatalogDefinitionKind.tileset, frame.tilesetId);
        }
      }
    }
  }
  for (final element in view.elements) {
    yield key(CatalogDefinitionKind.tileset, element.tilesetId);
    if (element.categoryId.isNotEmpty) {
      yield key(CatalogDefinitionKind.elementCategory, element.categoryId);
    }
    for (final frame in element.frames) {
      if (frame.tilesetId.isNotEmpty) {
        yield key(CatalogDefinitionKind.tileset, frame.tilesetId);
      }
    }
  }
  for (final category in view.elementCategories) {
    if (category.parentCategoryId case final id?) {
      yield key(CatalogDefinitionKind.elementCategory, id);
    }
  }
  for (final folder in view.tilesetFolders) {
    if (folder.parentFolderId case final id?) {
      yield key(CatalogDefinitionKind.tilesetFolder, id);
    }
  }
  for (final character in view.characters) {
    if (character.tilesetId.isNotEmpty) {
      yield key(CatalogDefinitionKind.tileset, character.tilesetId);
    }
    for (final portrait in character.portraits) {
      yield key(
        CatalogDefinitionKind.characterStudioDefinition,
        jsonEncode(['characterPortraitState', portrait.portraitStateId]),
      );
    }
    for (final animation in character.customAnimations) {
      yield key(
        CatalogDefinitionKind.characterStudioDefinition,
        jsonEncode(['characterAnimationDefinition', animation.definitionId]),
      );
    }
  }
  for (final environment in view.environmentPresets) {
    if (environment.categoryId case final id?) {
      yield key(CatalogDefinitionKind.elementCategory, id);
    }
    for (final item in environment.palette) {
      if (item.visualKind == EnvironmentVisualKind.element) {
        yield key(CatalogDefinitionKind.element, item.elementId!);
      } else {
        yield key(CatalogDefinitionKind.model3d, item.modelId!);
      }
    }
  }
  final smart = view.smartTileCatalog;
  for (final atlas in smart.atlases) {
    yield key(CatalogDefinitionKind.tileset, atlas.tilesetId);
  }
  for (final material in smart.materials) {
    if (material.categoryId.isNotEmpty) {
      yield key(CatalogDefinitionKind.smartTileCategory, material.categoryId);
    }
  }
  for (final animation in smart.animations) {
    for (final frame in animation.frames) {
      yield key(CatalogDefinitionKind.smartTileAtlas, frame.frame.atlasId);
    }
  }
  Iterable<CatalogDefinitionKey> parts(
    Iterable<SmartTileVisualPart> values,
  ) sync* {
    for (final part in values) {
      yield switch (part.source) {
        SmartTileFrameSource(:final frame) => key(
          CatalogDefinitionKind.smartTileAtlas,
          frame.atlasId,
        ),
        SmartTileAnimationSource(:final animationId) => key(
          CatalogDefinitionKind.smartTileAnimation,
          animationId,
        ),
        SmartTileModel3dSource(:final modelId) => key(
          CatalogDefinitionKind.model3d,
          modelId,
        ),
      };
    }
  }

  for (final preset in smart.presets) {
    if (preset.categoryId.isNotEmpty) {
      yield key(CatalogDefinitionKind.smartTileCategory, preset.categoryId);
    }
    for (final material in smartTilePresetMaterialIds(
      preset,
    ).where((id) => id.isNotEmpty)) {
      yield key(CatalogDefinitionKind.smartTileMaterial, material);
    }
    for (final rule in preset.rules) {
      for (final candidate in rule.candidates) {
        yield* parts(candidate.parts);
      }
    }
  }
  for (final pattern in smart.patterns) {
    if (pattern.categoryId.isNotEmpty) {
      yield key(CatalogDefinitionKind.smartTileCategory, pattern.categoryId);
    }
    for (final cell in pattern.cells) {
      yield* parts(cell.parts);
    }
  }
  for (final record in view.borderCatalog.records) {
    final definition = record.latestPublished?.definition;
    if (definition == null) {
      throw const FormatException('Unpublished runtime Border.');
    }
    for (final primitive in definition.primitives) {
      if (primitive.isSpatial) {
        yield key(CatalogDefinitionKind.model3d, primitive.sourceModelId!);
      } else {
        yield key(CatalogDefinitionKind.element, primitive.sourceElementId!);
        yield key(
          CatalogDefinitionKind.borderVisualSnapshot,
          primitive.visualSnapshotId,
        );
      }
      for (final surface in primitive.groundSurfaces) {
        yield key(CatalogDefinitionKind.smartTilePreset, surface.sourceSmartTilePresetId);
        yield key(CatalogDefinitionKind.smartTileMaterial, surface.materialId);
      }
    }
    if (definition.ground case final ground?) {
      yield key(CatalogDefinitionKind.smartTilePreset, ground.sourceSmartTilePresetId);
      for (final id in ground.visualSnapshotIdsByRole.values) {
        yield key(CatalogDefinitionKind.borderVisualSnapshot, id);
      }
    }
  }
}

Map<CatalogDefinitionKey, Object> _nativeDefinitions(ProjectManifest project) {
  final entries = <CatalogDefinitionKey, Object>{};
  void add(
    CatalogDefinitionKind kind,
    Iterable<Object> values,
    String Function(Object) id,
  ) {
    for (final value in values) {
      final key = CatalogDefinitionKey(kind, id(value));
      if (entries.containsKey(key)) {
        throw FormatException('Duplicate runtime definition $key');
      }
      entries[key] = value;
    }
  }

  add(
    CatalogDefinitionKind.tileset,
    project.tilesets,
    (v) => (v as ProjectTilesetEntry).id,
  );
  add(
    CatalogDefinitionKind.element,
    project.elements,
    (v) => (v as ProjectElementEntry).id,
  );
  add(
    CatalogDefinitionKind.model3d,
    project.models3d,
    (v) => (v as ProjectModel3dEntry).id,
  );
  add(
    CatalogDefinitionKind.character,
    project.characters,
    (v) => (v as ProjectCharacterEntry).id,
  );
  add(
    CatalogDefinitionKind.environmentPreset,
    project.environmentPresets,
    (v) => (v as EnvironmentPreset).id,
  );
  add(
    CatalogDefinitionKind.elementCategory,
    project.elementCategories,
    (v) => (v as ProjectElementCategory).id,
  );
  add(
    CatalogDefinitionKind.tilesetFolder,
    project.tilesetFolders,
    (v) => (v as ProjectTilesetFolder).id,
  );
  add(
    CatalogDefinitionKind.resourceLibraryEntry,
    project.resourceLibraryCatalog.entries,
    (v) => (v as ResourceLibraryEntry).identity,
  );
  add(
    CatalogDefinitionKind.resourceFamily,
    project.resourceLibraryCatalog.families,
    (v) => (v as ResourceFamily).id,
  );
  final smart = project.smartTileCatalog;
  add(
    CatalogDefinitionKind.smartTileCategory,
    smart.categories,
    (v) => (v as ProjectSmartTileCategory).id,
  );
  add(
    CatalogDefinitionKind.smartTileAtlas,
    smart.atlases,
    (v) => (v as ProjectSmartTileAtlas).id,
  );
  add(
    CatalogDefinitionKind.smartTileMaterial,
    smart.materials,
    (v) => (v as ProjectSmartTileMaterial).id,
  );
  add(
    CatalogDefinitionKind.smartTileAnimation,
    smart.animations,
    (v) => (v as ProjectSmartTileAnimation).id,
  );
  add(
    CatalogDefinitionKind.smartTilePreset,
    smart.presets,
    (v) => (v as ProjectSmartTilePreset).id,
  );
  add(
    CatalogDefinitionKind.smartTilePattern,
    smart.patterns,
    (v) => (v as ProjectSmartTilePattern).id,
  );
  add(
    CatalogDefinitionKind.borderRecord,
    project.borderCatalog.records,
    (v) => (v as BorderBlueprintRecord).id,
  );
  add(
    CatalogDefinitionKind.borderVisualSnapshot,
    project.borderCatalog.visualSnapshots,
    (v) => (v as BorderVisualSnapshot).id,
  );
  add(
    CatalogDefinitionKind.characterStudioDefinition,
    project.characterStudioCatalog.portraitStates,
    (v) => jsonEncode([
      'characterPortraitState',
      (v as CharacterPortraitStateDefinition).id,
    ]),
  );
  add(
    CatalogDefinitionKind.characterStudioDefinition,
    project.characterStudioCatalog.customAnimationDefinitions,
    (v) => jsonEncode([
      'characterAnimationDefinition',
      (v as CharacterCustomAnimationDefinition).id,
    ]),
  );
  return entries;
}

ProjectManifest _nativeProjection(
  ProjectManifest metadata,
  Map<CatalogDefinitionKey, Object> values,
) {
  List<T> of<T>() => values.values.whereType<T>().toList(growable: false);
  return metadata.copyWith(
    tilesets: of<ProjectTilesetEntry>(),
    elements: of<ProjectElementEntry>(),
    models3d: of<ProjectModel3dEntry>(),
    characters: of<ProjectCharacterEntry>(),
    environmentPresets: of<EnvironmentPreset>(),
    elementCategories: of<ProjectElementCategory>(),
    tilesetFolders: of<ProjectTilesetFolder>(),
    smartTileCatalog: ProjectSmartTileCatalog(
      categories: of<ProjectSmartTileCategory>(),
      atlases: of<ProjectSmartTileAtlas>(),
      materials: of<ProjectSmartTileMaterial>(),
      animations: of<ProjectSmartTileAnimation>(),
      presets: of<ProjectSmartTilePreset>(),
      patterns: of<ProjectSmartTilePattern>(),
    ),
    borderCatalog: ProjectBorderCatalog(
      formatVersion: metadata.borderCatalog.formatVersion,
      records: of<BorderBlueprintRecord>(),
      visualSnapshots: of<BorderVisualSnapshot>(),
    ),
    characterStudioCatalog: ProjectCharacterStudioCatalog(
      portraitStates: of<CharacterPortraitStateDefinition>(),
      customAnimationDefinitions: of<CharacterCustomAnimationDefinition>(),
    ),
    resourceLibraryCatalog: ResourceLibraryCatalog(
      families: of<ResourceFamily>(),
      entries: of<ResourceLibraryEntry>(),
    ),
  );
}

String _runtimePublicationFingerprint(List<int> bytes) =>
    narrativeEventBytesFingerprint(bytes);
