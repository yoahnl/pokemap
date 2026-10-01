import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../api/local_map_authoring_mutation_api.dart';
import '../../contracts/authoring_request.dart';
import '../../ports/artifact_store.dart';
import '../../ports/project_file_reader.dart';
import '../../workspace/project_open_service.dart';
import '../../workspace/project_snapshot_loader.dart';
import '../../workspace/workspace_handle_store.dart';
import '../../workspace/workspace_policy.dart';
import '../assets/asset_store.dart';

final class ProjectItemIconPack {
  ProjectItemIconPack({
    required List<int> manifestBytes,
    required List<int> archiveBytes,
  })  : manifestBytes = Uint8List.fromList(manifestBytes).asUnmodifiableView(),
        archiveBytes = Uint8List.fromList(archiveBytes).asUnmodifiableView();

  final Uint8List manifestBytes;
  final Uint8List archiveBytes;
}

final class ProjectItemIconProvisioningCancelled implements Exception {
  const ProjectItemIconProvisioningCancelled();

  @override
  String toString() => 'Project item icon provisioning was cancelled.';
}

void _requireCurrent(bool Function()? shouldContinue) {
  if (shouldContinue?.call() == false) {
    throw const ProjectItemIconProvisioningCancelled();
  }
}

Future<Map<String, Object?>> provisionProjectItemIcons({
  required String projectPath,
  required Future<ProjectItemIconPack> Function() loadPack,
  List<String>? itemIds,
  bool Function()? shouldContinue,
}) async {
  _requireCurrent(shouldContinue);
  final root = await _directory(projectPath);
  await _projectFile(root, 'project.json');
  await _projectFile(root, assetCatalogStorageKey);
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root], fileReader: reader);
  final handles = WorkspaceHandleStore();
  final opener =
      ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
  final opened = await opener.openProject(root);
  final snapshots = ProjectSnapshotLoader(handles: handles);
  LocalMapAuthoringMutationApi? api;
  Directory? staging;
  try {
    final snapshot = await snapshots.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.editorReadProjection);
    _requireCurrent(shouldContinue);
    if (!snapshot.manifest.pokemon.enabled) {
      return {
        'importedItems': <String>[],
        'preservedItems': <String>[],
        'unavailableItems': <String>[],
        'receipts': <Object?>[],
        'skippedReason': 'pokemon-disabled',
      };
    }
    if (snapshot.manifest.pokemon.catalogFiles['items'] == null) {
      return {
        'importedItems': <String>[],
        'preservedItems': <String>[],
        'unavailableItems': <String>[],
        'receipts': <Object?>[],
        'skippedReason': 'item-catalog-not-configured',
      };
    }
    final itemCatalog = snapshot.itemCatalog;
    if (itemCatalog == null) {
      final catalogFile = await _projectFile(
          root, snapshot.manifest.pokemon.catalogFiles['items']!);
      if (!await catalogFile.exists() && itemIds == null) {
        return {
          'importedItems': <String>[],
          'preservedItems': <String>[],
          'unavailableItems': <String>[],
          'receipts': <Object?>[],
          'skippedReason': 'item-catalog-missing',
        };
      }
      throw const FormatException('A valid project item catalog is required.');
    }
    final definitions = _selectItems(itemCatalog, itemIds);
    final catalogBytes =
        snapshot.findResourceBytes(assetCatalogResourceIdentity);
    final assets = catalogBytes == null
        ? AssetCatalog()
        : AssetCatalog.fromJson(
            jsonDecode(utf8.decode(catalogBytes)) as Map<String, dynamic>);
    final preserved = <String>[];
    final missing = <({ProjectItemDefinition definition, String path})>[];
    for (final definition in definitions) {
      final path = 'data/pokemon/assets/items/${definition.id}.png';
      final file = await _projectFile(root, path);
      if (await file.exists() || assets.findByLogicalPath(path) != null) {
        preserved.add(definition.id);
      } else {
        missing.add((definition: definition, path: path));
      }
    }
    _requireCurrent(shouldContinue);
    if (missing.isEmpty) {
      return {
        'importedItems': <String>[],
        'preservedItems': preserved,
        'unavailableItems': <String>[],
        'receipts': <Object?>[],
      };
    }
    final source = await loadPack();
    _requireCurrent(shouldContinue);
    final pack = _readPack(source);
    final unavailable = <String>[];
    final pending = <({String id, String sourceId, String path})>[];
    for (final item in missing) {
      final definition = item.definition;
      final sourceId = _sourceId(definition, pack);
      if (sourceId == null) {
        unavailable.add(definition.id);
        continue;
      }
      if (assets.find('item-icon-${definition.id}') != null) {
        throw FormatException(
            'Asset identity already exists: ${definition.id}.');
      }
      pending.add((id: definition.id, sourceId: sourceId, path: item.path));
    }
    final receipts = <Map<String, Object?>>[];
    if (pending.isEmpty) {
      return {
        'importedItems': <String>[],
        'preservedItems': preserved,
        'unavailableItems': unavailable,
        'receipts': receipts,
      };
    }
    final provenanceText = const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'archiveSha256': pack.archiveSha256,
      for (final key in const [
        'repository',
        'revision',
        'sourceTree',
        'canonicalImageCopyright',
        'repositoryLicense',
        'licenseSha256',
      ])
        if (pack.manifest.containsKey(key)) key: pack.manifest[key],
      'licenseText': pack.licenseText,
      'icons': [for (final item in pending) _iconProvenance(item, pack)],
    });
    final provenanceHash =
        sha256.convert(utf8.encode(provenanceText)).toString();
    final provenancePath =
        'data/pokemon/assets/items/source-$provenanceHash.json';
    final provenanceFile = await _projectFile(root, provenancePath);
    final includeProvenance = !await provenanceFile.exists() &&
        assets.findByLogicalPath(provenancePath) == null;
    _requireCurrent(shouldContinue);
    staging = await Directory.systemTemp.createTemp('item-icon-staging-');
    final stagingRoot = await staging.resolveSymbolicLinks();
    final artifacts = LocalArtifactStore(
        allowedSourceRoots: [stagingRoot],
        maximumArtifactBytes: maximumAuthoringArtifactBytesV1);
    api = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: snapshots, artifactStore: artifacts);
    _requireCurrent(shouldContinue);
    await api.attachProject(
        projectRootPath: root,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final entries = <Map<String, Object?>>[];
    for (final item in pending) {
      final file = File(p.join(stagingRoot, '${item.id}.png'));
      _requireCurrent(shouldContinue);
      await file.writeAsBytes(pack.icons[item.sourceId]!);
      final artifact = await api.stageArtifactFile(
          sourcePath: file.path, declaredMediaType: 'image/png');
      entries.add({
        'assetId': 'item-icon-${item.id}',
        'logicalPath': item.path,
        'artifactHandle': artifact.reference.handle,
        'usages': ['item:${item.id}'],
        'tags': ['item-icon', 'source-sha256:${pack.archiveSha256}'],
      });
    }
    if (includeProvenance) {
      final file = File(p.join(stagingRoot, 'source.json'));
      _requireCurrent(shouldContinue);
      await file.writeAsString(provenanceText);
      final artifact = await api.stageArtifactFile(sourcePath: file.path);
      entries.add({
        'assetId': 'item-icons-source-$provenanceHash',
        'logicalPath': provenancePath,
        'artifactHandle': artifact.reference.handle,
        'tags': ['item-icon-provenance'],
      });
    }
    final appliedItems = <String>[];
    try {
      for (var offset = 0; offset < entries.length; offset += 200) {
        final chunk =
            entries.sublist(offset, math.min(offset + 200, entries.length));
        for (final entry in chunk) {
          final file =
              await _projectFile(root, entry['logicalPath']! as String);
          if (await file.exists()) {
            throw const FormatException(
                'An import destination changed. Retry.');
          }
        }
        final revision = (await snapshots.load(opened.projectHandle,
                policy: ProjectSnapshotLoadPolicy.editorReadProjection))
            .revision;
        final operationId =
            'item-icons-${DateTime.now().microsecondsSinceEpoch}-$offset';
        _requireCurrent(shouldContinue);
        final plan = await api.planMutation(
            opened.projectHandle,
            AuthoringRequest(
                requestId: operationId,
                actionId: 'asset.import_batch',
                actionVersion: 1,
                workspaceHandle: opened.workspaceHandle.value,
                parameters: {'entries': chunk},
                expectedRevision: revision,
                idempotencyKey: operationId));
        if (!plan.applicable) {
          throw FormatException(
              'Import is not applicable: ${plan.nonApplicableReason}.');
        }
        _requireCurrent(shouldContinue);
        final result = await api.applyMutation(opened.projectHandle,
            planId: plan.planId, operationId: operationId);
        receipts.add(result.toJson());
        appliedItems.addAll(
            pending.skip(offset).take(chunk.length).map((item) => item.id));
      }
    } on Object catch (error) {
      if (receipts.isEmpty) rethrow;
      throw ProjectItemIconProvisioningPartialFailure(
          error.toString(), appliedItems, receipts);
    }
    return {
      'importedItems': [for (final item in pending) item.id],
      'preservedItems': preserved,
      'unavailableItems': unavailable,
      'sourceArchiveSha256': pack.archiveSha256,
      'receipts': receipts,
    };
  } finally {
    await api?.detachWorkspace(opened.workspaceHandle);
    opener.closeWorkspace(opened.workspaceHandle);
    await staging?.delete(recursive: true);
  }
}

final class ProjectItemIconProvisioningPartialFailure implements Exception {
  const ProjectItemIconProvisioningPartialFailure(
      this.error, this.importedItems, this.receipts);

  final String error;
  final List<String> importedItems;
  final List<Map<String, Object?>> receipts;

  Map<String, Object?> toJson() => {
        'error': error,
        'appliedBatchCount': receipts.length,
        'atomicBatchLimit': 200,
        'importedItems': importedItems,
        'receipts': receipts,
        'rerunBehavior': 'Existing project icons will be preserved.',
      };
}

Map<String, Object?> _iconProvenance(
    ({String id, String sourceId, String path}) item, _ItemIconPack pack) {
  final metadata = (pack.manifest['items'] as Map)[item.sourceId] as Map;
  final generation = metadata['provenance'];
  return {
    'projectItemId': item.id,
    'sourceItemId': item.sourceId,
    for (final key in const [
      'sha256',
      'bytes',
      'width',
      'height',
      'gitBlob',
      'sampling',
    ])
      if (metadata.containsKey(key)) key: metadata[key],
    if (generation is Map)
      'generation': {
        for (final key in const [
          'generator',
          'generatedOn',
          'processing',
          'description',
          'sourceArtifact',
        ])
          if (generation.containsKey(key)) key: generation[key],
      },
  };
}

List<ProjectItemDefinition> _selectItems(
    ProjectItemCatalog catalog, List<String>? ids) {
  for (final entry in catalog.entries) {
    _requireItemId(entry.id);
  }
  if (ids == null) {
    return catalog.entries.toList()..sort((a, b) => a.id.compareTo(b.id));
  }
  final selected = <String, ProjectItemDefinition>{};
  for (final id in ids) {
    _requireItemId(id);
    final normalized = id.replaceAll('_', '-');
    final matches = catalog.entries
        .where((entry) => [entry.id, ...entry.aliases]
            .any((candidate) => candidate.replaceAll('_', '-') == normalized))
        .toList();
    if (matches.length != 1) {
      throw FormatException('Unknown or ambiguous project item: $id.');
    }
    selected[matches.single.id] = matches.single;
  }
  return selected.values.toList()..sort((a, b) => a.id.compareTo(b.id));
}

String? _sourceId(ProjectItemDefinition definition, _ItemIconPack pack) {
  for (final candidate in [definition.id, ...definition.aliases]) {
    final normalized = candidate.replaceAll('_', '-');
    final sourceId = pack.aliases[normalized] ?? normalized;
    if (pack.icons.containsKey(sourceId)) return sourceId;
  }
  return null;
}

void _requireItemId(String id) {
  if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(id)) {
    throw const FormatException('An item ID cannot form a safe filename.');
  }
}

Future<String> _directory(String path) async {
  if (!p.isAbsolute(path) ||
      path.contains('\u0000') ||
      path.split(RegExp(r'[\\/]')).contains('..') ||
      await FileSystemEntity.type(path, followLinks: false) !=
          FileSystemEntityType.directory) {
    throw const FormatException(
        'Expected an absolute directory without traversal or symlinks.');
  }
  return Directory(path).resolveSymbolicLinks();
}

Future<File> _projectFile(String root, String relative) async {
  var current = root;
  final segments = validateProjectRelativePath(relative);
  for (var index = 0; index < segments.length; index++) {
    current = p.join(current, segments[index]);
    final type = await FileSystemEntity.type(current, followLinks: false);
    if (type == FileSystemEntityType.link ||
        (type != FileSystemEntityType.notFound &&
            type !=
                (index == segments.length - 1
                    ? FileSystemEntityType.file
                    : FileSystemEntityType.directory))) {
      throw const FormatException('Unsafe project or source file path.');
    }
  }
  return File(current);
}

_ItemIconPack _readPack(ProjectItemIconPack source) {
  final manifest =
      jsonDecode(utf8.decode(source.manifestBytes)) as Map<String, dynamic>;
  final archiveBytes = source.archiveBytes;
  final archiveHash = sha256.convert(archiveBytes).toString();
  if (manifest['schemaVersion'] != 1 ||
      manifest['archiveSha256'] != archiveHash ||
      manifest['licensePath'] != 'LICENCE.txt') {
    throw const FormatException(
        'Item icon archive does not match its manifest.');
  }
  final itemMetadata = Map<String, dynamic>.from(manifest['items'] as Map);
  final archive = ZipDecoder().decodeBytes(archiveBytes, verify: true);
  final files = <String, Uint8List>{};
  for (final entry in archive.files) {
    if (!entry.isFile ||
        entry.isSymbolicLink ||
        files.containsKey(entry.name) ||
        (entry.name != 'LICENCE.txt' &&
            !RegExp(r'^[a-z0-9][a-z0-9-]*\.png$').hasMatch(entry.name))) {
      throw const FormatException('Unsafe or duplicate item archive entry.');
    }
    files[entry.name] = entry.content;
  }
  if (files.length != itemMetadata.length + 1 ||
      sha256.convert(files['LICENCE.txt'] ?? []).toString() !=
          manifest['licenseSha256']) {
    throw const FormatException('Item archive inventory or license differs.');
  }
  final icons = <String, Uint8List>{};
  for (final entry in itemMetadata.entries) {
    if (!RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(entry.key)) {
      throw const FormatException('Unsafe source item ID.');
    }
    final metadata = Map<String, dynamic>.from(entry.value as Map);
    final bytes = files['${entry.key}.png'];
    if (bytes == null ||
        bytes.length != metadata['bytes'] ||
        sha256.convert(bytes).toString() != metadata['sha256']) {
      throw FormatException(
          'Item image differs from its manifest: ${entry.key}.');
    }
    final decoded = image.decodePng(bytes);
    if (decoded == null ||
        decoded.width != metadata['width'] ||
        decoded.height != metadata['height']) {
      throw FormatException('Invalid item PNG: ${entry.key}.');
    }
    icons[entry.key] = bytes;
  }
  final aliases =
      Map<String, String>.from(manifest['aliases'] as Map? ?? const {});
  for (final entry in aliases.entries) {
    if (!RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(entry.key) ||
        !icons.containsKey(entry.value)) {
      throw const FormatException('Invalid source icon alias.');
    }
  }
  return _ItemIconPack(icons, aliases, archiveHash, manifest,
      utf8.decode(files['LICENCE.txt']!));
}

final class _ItemIconPack {
  const _ItemIconPack(this.icons, this.aliases, this.archiveSha256,
      this.manifest, this.licenseText);

  final Map<String, Uint8List> icons;
  final Map<String, String> aliases;
  final String archiveSha256;
  final Map<String, dynamic> manifest;
  final String licenseText;
}
