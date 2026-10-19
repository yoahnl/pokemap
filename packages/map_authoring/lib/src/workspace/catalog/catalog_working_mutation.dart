import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../catalog_storage/catalog_storage_store.dart';
import '../../domains/assets/asset_store.dart';
import '../../domains/assets/project_media_store.dart';
import '../../domains/narrative/dialogue_authoring_service.dart';
import '../../ports/project_file_reader.dart';
import '../../ports/transaction_file_gateway.dart';
import '../../references/resource_library_scope_guard.dart';
import '../../references/resource_usage_documents.dart';
import '../../transactions/authoring_payload.dart';
import '../../contracts/resource_ref.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../project_snapshot.dart';

final class CatalogWorkingMutation {
  CatalogWorkingMutation._(
      {required this.projectedProject,
      required this.upserts,
      required this.removals,
      required this.additionalChanges,
      required this.workspaceFingerprint,
      required this.diff});

  final ProjectManifest projectedProject;
  final List<CatalogDefinitionUnit> upserts;
  final List<CatalogDefinitionKey> removals;
  final List<AuthoringResourceChange> additionalChanges;
  final String workspaceFingerprint;
  final AuthoringDiff diff;

  static Future<String> validateProjection(
      {required CatalogSnapshot projected,
      required List<AuthoringResourceChange> changes,
      required CatalogStorageStore store,
      required ProjectSnapshot before}) async {
    final project = await (await PortableProjectCatalog.fromSnapshot(projected))
        .exportProject();
    ProjectValidator.validate(project);
    final files = _CatalogProjectionFiles(store, changes);
    final maps = <MapData>[];
    final occupied = <String>{};
    for (final entry in project.maps) {
      final path = validateProjectRelativePath(entry.relativePath).join('/');
      if (!occupied.add(path)) {
        throw const FormatException('catalog.revert: duplicate map path');
      }
      final raw =
          decodeNarrativeEventJsonStrict(utf8.decode(await files.read(path)));
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('catalog.revert: invalid map');
      }
      final map = MapData.fromJson(raw);
      if (map.id != entry.id ||
          (map.spatialScene != null) !=
              (project.settings.dimension == ProjectDimension.threeD)) {
        throw const FormatException(
            'catalog.revert: map identity or dimension mismatch');
      }
      MapValidator.validate(map, projectDialogueContext: project);
      maps.add(map);
    }
    final documents = resourceDefinitionUsageDocuments(project, maps);
    for (final entry in project.dialogues) {
      final path = validateProjectRelativePath(entry.relativePath).join('/');
      if (!occupied.add(path)) {
        throw const FormatException('catalog.revert: duplicate dialogue path');
      }
      final compiled = const DialogueAuthoringCompiler()
          .compile(entry: entry, source: utf8.decode(await files.read(path)));
      if (!compiled.canPublish || compiled.document == null) {
        throw const FormatException('catalog.revert: invalid dialogue source');
      }
      documents.add(ResourceUsageDocument('dialogueSource', entry.id,
          entry.name, path, compiled.document!.toJson()));
    }
    final media = await files.readOptional(projectMediaCatalogStorageKey);
    if (media != null) {
      for (final entry in decodeProjectMediaCatalogBytes(media).entries) {
        documents.add(ResourceUsageDocument(
            'media',
            entry.id,
            entry.label,
            projectMediaCatalogStorageKey,
            Map<String, dynamic>.from(entry.toJson())));
      }
    }
    if (project.pokemon.enabled) {
      for (final entry in project.pokemon.catalogFiles.entries) {
        final bytes = await files.readOptional(entry.value);
        if (bytes == null) continue;
        final raw =
            Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
        if (entry.key == 'items') {
          decodeProjectItemCatalog(raw);
        } else {
          PokemonCatalogFile.fromJson(raw);
        }
      }
      for (final (directory, kind) in [
        (project.pokemon.speciesDir, 'species'),
        (project.pokemon.mediaDir, 'media'),
        (project.pokemon.learnsetsDir, 'learnset'),
        (project.pokemon.evolutionsDir, 'evolution')
      ]) {
        for (final path in await files.listFiles(
            projectRoot: store.projectRoot, relativeDirectory: directory)) {
          if (!path.toLowerCase().endsWith('.json')) continue;
          final raw = Map<String, dynamic>.from(
              jsonDecode(utf8.decode(await files.read(path))) as Map);
          switch (kind) {
            case 'species':
              PokemonSpeciesFile.fromJson(raw);
            case 'media':
              final media = PokemonMediaFile.fromJson(raw);
              documents.add(ResourceUsageDocument(
                  'pokemonMedia', media.speciesId, media.speciesId, path, raw));
            case 'learnset':
              PokemonLearnsetFile.fromJson(raw);
            case 'evolution':
              PokemonEvolutionFile.fromJson(raw);
          }
        }
      }
    }
    validateResourceLibraryScopeIndex(
        project,
        ResourceLibraryUsageIndex.fromDocuments(
            maps: maps, documents: documents));
    final assets = await files.readOptional(assetCatalogStorageKey);
    if (assets != null) {
      final catalog = AssetCatalog.fromJson(
          Map<String, dynamic>.from(jsonDecode(utf8.decode(assets)) as Map));
      for (final asset in catalog.records) {
        for (final path in {
          asset.logicalPath,
          assetBlobStorageKey(asset.artifact)
        }) {
          await files.withPayload(path, (payload) async {
            final observed = await inspectAuthoringPayload(payload.openRead(),
                storageKey: path, byteLength: payload.byteLength);
            if (observed.contentDigest != asset.artifact.digest ||
                observed.byteLength != asset.artifact.byteLength) {
              throw const FormatException(
                  'catalog.revert: asset content mismatch');
            }
          });
        }
      }
    }
    final resources = <String, String>{
      for (final entry in before.resourceStorageKeys.entries)
        if (entry.key != 'project' && entry.key != 'catalogHead')
          entry.value: before.resourceFingerprints[entry.key]!
    };
    for (final change in changes) {
      if (change.afterRevision == null) {
        resources.remove(change.storageKey);
      } else {
        resources[change.storageKey] = change.afterRevision!;
      }
    }
    return computeAuthoringJsonFingerprint(
        {'project': project.toJson(), 'resources': resources},
        logicalName: 'catalog-workspace-state.json');
  }

  static Future<CatalogWorkingMutation> translate(
      {required PortableProjectCatalog catalog,
      required ProjectSnapshot snapshot,
      required AuthoringPlan publicPlan}) async {
    if (!snapshot.materializedCatalogProject) {
      throw StateError(
          'Catalog translation requires explicit project materialization.');
    }
    final additional = <AuthoringResourceChange>[];
    ProjectManifest next = snapshot.manifest;
    var projectChanged = false;
    for (final change in publicPlan.changeSet.changes) {
      if (change.storageKey == 'project.json') {
        if (change.resource.kind != 'project' || change.afterPayload == null) {
          throw const FormatException(
              'catalog.project: invalid projected project change');
        }
        final value =
            jsonDecode(utf8.decode(await change.afterPayload!.readBytes()));
        if (value is! Map<String, dynamic> || value.containsKey('format')) {
          throw const FormatException(
              'catalog.project: projected manifest required');
        }
        next = ProjectManifest.fromJson(value);
        projectChanged = true;
      } else {
        if (change.storageKey == 'catalog/HEAD.json' ||
            change.storageKey.startsWith('catalog/objects/') ||
            change.storageKey == 'catalog/IDENTITY.json') {
          throw const FormatException(
              'catalog.project: internal storage cannot be changed by a project action');
        }
        additional.add(change);
      }
    }
    final upserts = <CatalogDefinitionUnit>[];
    final removals = <CatalogDefinitionKey>[];
    if (projectChanged) {
      final built = PortableCatalogPublication.encodeProject(next);
      final previous = <CatalogDefinitionKey, String>{};
      String? cursor;
      do {
        final page = await catalog.snapshot
            .page(limit: catalog.snapshot.limits.indexPageSize, cursor: cursor);
        for (final entry in page.items) {
          if (entry.key.kind != CatalogDefinitionKind.workspaceState) {
            previous[entry.key] = entry.reference.sha256;
          }
        }
        cursor = page.nextCursor;
      } while (cursor != null);
      final keys = <CatalogDefinitionKey>{};
      for (final entry in built.storage.objects.entries) {
        final value = jsonDecode(utf8.decode(entry.value));
        if (value is! Map<String, dynamic> || value['type'] != 'unit') continue;
        final key = CatalogDefinitionKey.fromJson(
            Map<String, Object?>.from(value['key'] as Map));
        keys.add(key);
        if (previous[key] == entry.key) continue;
        upserts.add(CatalogDefinitionUnit(
            key: key,
            payload: Map<String, Object?>.from(value['payload'] as Map),
            references: [
              for (final reference in value['references'] as List)
                CatalogDefinitionKey.fromJson(
                    Map<String, Object?>.from(reference as Map))
            ]));
      }
      removals.addAll(previous.keys.where((key) => !keys.contains(key)));
    }
    final resources = <String, String>{
      for (final entry in snapshot.resourceStorageKeys.entries)
        if (entry.key != 'project' && entry.key != 'catalogHead')
          entry.value: snapshot.resourceFingerprints[entry.key]!,
    };
    for (final change in additional) {
      if (change.afterRevision == null) {
        resources.remove(change.storageKey);
      } else {
        resources[change.storageKey] = change.afterRevision!;
      }
    }
    final fingerprint = computeAuthoringJsonFingerprint(
        {'project': next.toJson(), 'resources': resources},
        logicalName: 'catalog-workspace-state.json');
    final entries = <AuthoringDiffEntry>[
      for (final entry in publicPlan.changeSet.diff.entries)
        if (entry.resource.kind == 'project')
          AuthoringDiffEntry.fromJson({
            ...entry.toJson(),
            'resource': {'kind': 'catalogHead', 'id': 'catalog'}
          })
        else
          entry,
    ];
    if (!entries.any((entry) => entry.resource.kind == 'catalogHead')) {
      final previous = await catalog.lookup(CatalogDefinitionKey(
          CatalogDefinitionKind.workspaceState, 'workspace'));
      entries.add(AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: AuthoringResourceRef(kind: 'catalogHead', id: 'catalog'),
          path: '/workspaceFingerprint',
          before: previous?.payload['fingerprint'],
          after: fingerprint));
    }
    return CatalogWorkingMutation._(
        projectedProject: next,
        upserts: List.unmodifiable(upserts),
        removals: List.unmodifiable(removals),
        additionalChanges: List.unmodifiable(additional),
        workspaceFingerprint: fingerprint,
        diff: AuthoringDiff(entries));
  }
}

final class _CatalogProjectionFiles
    implements
        ProjectFileReader,
        ProjectDirectoryReader,
        ProjectResourceProbeReader {
  _CatalogProjectionFiles(this.store, List<AuthoringResourceChange> changes)
      : changes = {for (final change in changes) change.storageKey: change};
  final CatalogStorageStore store;
  final Map<String, AuthoringResourceChange> changes;
  final local = const LocalProjectFileReader();

  Future<T> withPayload<T>(
      String path, Future<T> Function(AuthoringPayload) use) async {
    path = validateProjectRelativePath(path).join('/');
    final change = changes[path];
    if (change != null) {
      final payload = change.afterPayload;
      if (payload == null) {
        throw const FormatException(
            'catalog.revert: projected resource missing');
      }
      return use(payload);
    }
    final payload = await store.gateway.captureResourcePayload(path);
    if (payload == null) {
      throw const FormatException('catalog.revert: project resource missing');
    }
    try {
      return await use(payload);
    } finally {
      await payload.release();
    }
  }

  Future<List<int>> read(String path) =>
      withPayload(path, (payload) => payload.readBytes());
  Future<List<int>?> readOptional(String path) async {
    if (changes.containsKey(path)) {
      return changes[path]!.afterPayload?.readBytes();
    }
    if (await store.gateway.readResourceRevision(path) == null) return null;
    return read(path);
  }

  @override
  Future<String> canonicalizeDirectory(String path) =>
      local.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
          {required String projectRoot, required String relativePath}) =>
      read(relativePath);
  @override
  Future<List<String>> listFiles(
      {required String projectRoot, required String relativeDirectory}) async {
    final directory = validateProjectRelativePath(relativeDirectory).join('/');
    final paths = <String>{};
    try {
      paths.addAll(await local.listFiles(
          projectRoot: store.projectRoot, relativeDirectory: directory));
    } on WorkspaceAccessException catch (error) {
      if (error.code != 'workspace.directory_missing') rethrow;
    }
    for (final change in changes.values) {
      if (!change.storageKey.startsWith('$directory/')) continue;
      if (change.afterPayload == null) {
        paths.remove(change.storageKey);
      } else {
        paths.add(change.storageKey);
      }
    }
    return paths.toList()..sort();
  }

  @override
  Future<ProjectResourceProbe> probeResource(
      {required String projectRoot, required String relativePath}) async {
    final path = validateProjectRelativePath(relativePath).join('/');
    final change = changes[path];
    if (change != null) {
      final payload = change.afterPayload;
      return payload == null
          ? const ProjectResourceProbe.missing()
          : ProjectResourceProbe.exists(ProjectResourceIdentity(
              scope: store.projectRoot,
              relativePath: path,
              byteLength: payload.byteLength,
              modifiedAtMicros: 0));
    }
    return local.probeResource(
        projectRoot: store.projectRoot, relativePath: path);
  }
}
