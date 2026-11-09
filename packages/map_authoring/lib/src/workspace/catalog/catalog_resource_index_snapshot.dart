import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../catalog_storage/catalog_storage_store.dart';
import '../../domains/assets/project_media_store.dart';
import '../../ports/project_file_reader.dart';
import '../../ports/transaction_file_gateway.dart';
import '../../support/authoring_fingerprint.dart';
import '../project_snapshot.dart';
import '../workspace_handle_store.dart';

abstract final class CatalogResourceIndexSnapshot {
  static Future<
      ({
        ProjectSnapshot snapshot,
        Future<String> Function() currentRevision
      })> read({
    required CatalogSnapshot catalog,
    required CatalogStorageStore store,
    required ProjectHandle projectHandle,
  }) async {
    const fields = {'settings', 'maps', 'dialogues', 'pokemon'};
    final portable = await PortableProjectCatalog.fromSnapshot(catalog,
        metadataFields: fields);
    final project = portable.projectMetadata;
    final maps = <MapData>[];
    final revisions = <String, String>{};
    final observed = <String, String?>{};
    final paths = <String, String>{};
    final values = <String, List<int>>{};
    final directories = <String, List<String>>{};
    const reader = LocalProjectFileReader();
    Future<List<int>?> read(String identity, String path,
        {bool required = true}) async {
      validateProjectRelativePath(path);
      final payload = await store.gateway.captureResourcePayload(path);
      observed[path] = payload?.resourceRevision;
      if (payload == null) {
        if (required) {
          throw ProjectSnapshotException('resource_library.usage_incomplete',
              'A required reference document is missing: $identity.');
        }
        return null;
      }
      try {
        if (paths.values.contains(path)) {
          throw const FormatException(
              'catalog.resource_usage.duplicate_document_path');
        }
        final bytes = await payload.readBytes();
        values[identity] = bytes;
        paths[identity] = path;
        revisions[identity] = payload.resourceRevision;
        return bytes;
      } finally {
        await payload.release();
      }
    }

    for (final entry in project.maps) {
      final bytes = (await read('map:${entry.id}', entry.relativePath))!;
      final value = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
      if (value is! Map<String, dynamic>) {
        throw const FormatException('catalog.resource_usage.map_invalid');
      }
      final map = MapData.fromJson(value);
      if (map.id != entry.id) {
        throw const FormatException('catalog.resource_usage.map_identity');
      }
      maps.add(map);
    }
    for (final entry in project.dialogues) {
      await read('dialogueSource:${entry.id}', entry.relativePath);
    }
    await read(
        projectMediaCatalogResourceIdentity, projectMediaCatalogStorageKey,
        required: false);
    if (project.pokemon.enabled) {
      final directory = project.pokemon.mediaDir;
      List<String> files;
      try {
        files = await reader.listFiles(
            projectRoot: store.projectRoot, relativeDirectory: directory);
      } on WorkspaceAccessException catch (error) {
        if (error.code != 'workspace.directory_missing') rethrow;
        files = [];
      }
      directories[directory] = files;
      for (final path
          in files.where((path) => path.toLowerCase().endsWith('.json'))) {
        final payload = await store.gateway.captureResourcePayload(path);
        if (payload == null) {
          throw const FormatException(
              'catalog.resource_usage.media_disappeared');
        }
        try {
          final bytes = await payload.readBytes();
          final value =
              Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
          final media = PokemonMediaFile.fromJson(value);
          final identity = pokemonMediaResourceIdentity(media.speciesId);
          if (paths.containsKey(identity)) {
            throw const FormatException(
                'catalog.resource_usage.duplicate_media');
          }
          paths[identity] = path;
          values[identity] = bytes;
          revisions[identity] = payload.resourceRevision;
          observed[path] = payload.resourceRevision;
        } finally {
          await payload.release();
        }
      }
    }
    for (final entry in observed.entries) {
      if (await store.gateway.readResourceRevision(entry.key) != entry.value) {
        throw const ProjectSnapshotException('project.changed_during_snapshot',
            'A reference document changed during explicit resource index preparation.');
      }
    }
    for (final entry in directories.entries) {
      List<String> current;
      try {
        current = await reader.listFiles(
            projectRoot: store.projectRoot, relativeDirectory: entry.key);
      } on WorkspaceAccessException catch (error) {
        if (error.code != 'workspace.directory_missing') rethrow;
        current = [];
      }
      if (jsonEncode(current) != jsonEncode(entry.value)) {
        throw const ProjectSnapshotException('project.changed_during_snapshot',
            'The Pokemon media inventory changed during index preparation.');
      }
    }
    if (await store.readHead() != catalog.root) {
      throw const CatalogStorageException('catalog.revision_conflict',
          'The catalog changed during resource index preparation.');
    }
    final bytes = utf8.encode(jsonEncode(project.toJson()));
    Future<Map<String, List<String>>> currentDirectories() async {
      final result = <String, List<String>>{};
      for (final directory in directories.keys) {
        try {
          result[directory] = await reader.listFiles(
              projectRoot: store.projectRoot, relativeDirectory: directory);
        } on WorkspaceAccessException catch (error) {
          if (error.code != 'workspace.directory_missing') rethrow;
          result[directory] = [];
        }
      }
      return result;
    }

    Future<String> currentRevision() async => computeAuthoringJsonFingerprint({
          'catalog': (await store.readHead())?.toJson(),
          'resources': {
            for (final path in observed.keys)
              path: await store.gateway.readResourceRevision(path),
          },
          'directories': await currentDirectories(),
        }, logicalName: 'resource-usage-index');
    final snapshot = ProjectSnapshot(
        projectHandle: projectHandle,
        revision: computeAuthoringJsonFingerprint({
          'catalog': catalog.root.toJson(),
          'resources': observed,
          'directories': directories
        }, logicalName: 'resource-usage-index'),
        manifest: project,
        maps: maps,
        pokemonInventoryComplete: true,
        materializedCatalogProject: true,
        availableProjectSections: fields,
        scopedStorageRevisions: observed,
        resourceFingerprints: {
          'project': computeAuthoringBytesFingerprint(bytes,
              logicalName: 'project.json'),
          ...revisions
        },
        resourceBytes: {
          'project': bytes,
          ...values
        },
        resourceStorageKeys: {
          'project': 'project.json',
          ...paths
        });
    return (snapshot: snapshot, currentRevision: currentRevision);
  }
}
