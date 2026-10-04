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
import '../../contracts/artifact_ref.dart';
import '../../ports/artifact_store.dart';
import '../../ports/project_file_reader.dart';
import '../../workspace/project_open_service.dart';
import '../../workspace/project_snapshot_loader.dart';
import '../../workspace/workspace_handle_store.dart';
import '../../workspace/workspace_policy.dart';
import '../assets/asset_store.dart';

final class ProjectCaptureSpritePack {
  ProjectCaptureSpritePack(
      {required List<int> manifestBytes, required List<int> archiveBytes})
      : manifestBytes = Uint8List.fromList(manifestBytes).asUnmodifiableView(),
        archiveBytes = Uint8List.fromList(archiveBytes).asUnmodifiableView();

  final Uint8List manifestBytes;
  final Uint8List archiveBytes;
}

Future<Map<String, Object?>> provisionProjectCaptureSprites({
  required String projectPath,
  required Future<ProjectCaptureSpritePack> Function() loadPack,
  bool Function()? shouldContinue,
}) async {
  _requireCurrent(shouldContinue);
  if (!p.isAbsolute(projectPath) ||
      projectPath.contains('\u0000') ||
      projectPath.split(RegExp(r'[\\/]')).contains('..') ||
      await FileSystemEntity.type(projectPath, followLinks: false) !=
          FileSystemEntityType.directory) {
    throw const FormatException(
        'Expected an absolute project directory without traversal or symlinks.');
  }
  final root = await Directory(projectPath).resolveSymbolicLinks();
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
  final imported = <String>[];
  final updated = <String>[];
  final preserved = <String>[];
  final unavailable = <String>[];
  final receipts = <Map<String, Object?>>[];
  Map<String, Object?> result([String? reason]) => {
        'importedItems': imported,
        'updatedItems': updated,
        'preservedItems': preserved,
        'unavailableItems': unavailable,
        'receipts': receipts,
        if (reason != null) 'skippedReason': reason,
      };
  try {
    final snapshot = await snapshots.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.editorReadProjection);
    _requireCurrent(shouldContinue);
    if (!snapshot.manifest.pokemon.enabled) return result('pokemon-disabled');
    final catalogPath = snapshot.manifest.pokemon.catalogFiles['items'];
    if (catalogPath == null) return result('item-catalog-not-configured');
    final catalog = snapshot.itemCatalog;
    if (catalog == null) {
      if (!await (await _projectFile(root, catalogPath)).exists()) {
        return result('item-catalog-missing');
      }
      throw const FormatException('A valid project item catalog is required.');
    }
    final assetBytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
    final assets = assetBytes == null
        ? AssetCatalog()
        : AssetCatalog.fromJson(
            jsonDecode(utf8.decode(assetBytes)) as Map<String, dynamic>);
    final missing = <ProjectItemDefinition>[];
    final assignments = <({String id, String path})>[];
    for (final definition in catalog.entries) {
      if (definition.capture == null) continue;
      _requireItemId(definition.id);
      if (definition.capture!.animationSpritePath != null) {
        preserved.add(definition.id);
        continue;
      }
      final path = 'data/pokemon/assets/items/${definition.id}/animation.png';
      final file = await _projectFile(root, path);
      final record = assets.findByLogicalPath(path);
      if (await file.exists() || record != null) {
        final bytes = record == null
            ? await file.readAsBytes()
            : await (await _projectFile(
                    root, assetBlobStorageKey(record.artifact)))
                .readAsBytes();
        _requireSprite(bytes);
        if (record != null &&
            ContentArtifactRef.fromBytes(bytes,
                        mediaType: record.artifact.mediaType)
                    .digest !=
                record.artifact.digest) {
          throw const FormatException(
              'The managed capture sprite does not match its record.');
        }
        if (record != null &&
            await file.exists() &&
            ContentArtifactRef.fromBytes(await file.readAsBytes(),
                        mediaType: record.artifact.mediaType)
                    .digest !=
                record.artifact.digest) {
          throw const FormatException(
              'The capture sprite differs from its managed record.');
        }
        preserved.add(definition.id);
        assignments.add((id: definition.id, path: path));
      } else {
        missing.add(definition);
      }
    }
    _requireCurrent(shouldContinue);
    final imports = <({String id, String sourceId, String path})>[];
    _CapturePack? pack;
    if (missing.isNotEmpty) {
      final source = await loadPack();
      _requireCurrent(shouldContinue);
      pack = _readPack(source);
      for (final definition in missing) {
        String? sourceId;
        for (final candidate in [definition.id, ...definition.aliases]) {
          final matched = pack.itemMappings[candidate.replaceAll('-', '_')];
          if (matched != null) {
            sourceId = matched;
            break;
          }
        }
        if (sourceId == null) {
          unavailable.add(definition.id);
          continue;
        }
        if (assets.find('item-capture-sprite-${definition.id}') != null) {
          throw FormatException(
              'Asset identity already exists: ${definition.id}.');
        }
        final path = 'data/pokemon/assets/items/${definition.id}/animation.png';
        imports.add((id: definition.id, sourceId: sourceId, path: path));
        assignments.add((id: definition.id, path: path));
      }
    }
    if (assignments.isEmpty) return result();
    staging = await Directory.systemTemp.createTemp('capture-sprite-staging-');
    final artifacts = LocalArtifactStore(
        allowedSourceRoots: [staging.path],
        maximumArtifactBytes: maximumAuthoringArtifactBytesV1);
    api = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: snapshots, artifactStore: artifacts);
    await api.attachProject(
        projectRootPath: root,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final entries = <Map<String, Object?>>[];
    for (final item in imports) {
      _requireCurrent(shouldContinue);
      final file = File(p.join(staging.path, '${item.id}.png'));
      await file.writeAsBytes(pack!.files[item.sourceId]!);
      final staged = await api.stageArtifactFile(
          sourcePath: file.path, declaredMediaType: 'image/png');
      entries.add({
        'assetId': 'item-capture-sprite-${item.id}',
        'logicalPath': item.path,
        'artifactHandle': staged.reference.handle,
        'usages': ['item:${item.id}'],
        'tags': ['item-capture-sprite', 'source-sha256:${pack.archiveSha256}']
      });
    }
    if (imports.isNotEmpty) {
      final provenance = jsonEncode({
        'schemaVersion': 1,
        for (final key in const [
          'source',
          'sourceDirectory',
          'licenseStatus',
          'copyrightNotice',
          'importer'
        ])
          if (pack!.manifest.containsKey(key)) key: pack.manifest[key],
        'archiveSha256': pack!.archiveSha256,
        'sprites': [
          for (final item in imports)
            {
              'projectItemId': item.id,
              'sourceSheetId': item.sourceId,
              'sourceItem': pack.manifest['mappingSources'] is Map
                  ? (pack.manifest['mappingSources'] as Map)[pack
                      .itemMappings.entries
                      .firstWhere((entry) => entry.value == item.sourceId)
                      .key]
                  : null,
              'image': (pack.manifest['files'] as Map)[item.sourceId],
            }
        ],
      });
      final hash = sha256.convert(utf8.encode(provenance)).toString();
      final path = 'data/pokemon/assets/items/capture-source-$hash.json';
      if (!await (await _projectFile(root, path)).exists() &&
          assets.findByLogicalPath(path) == null) {
        final file = File(p.join(staging.path, 'source.json'));
        await file.writeAsString(provenance);
        final staged = await api.stageArtifactFile(sourcePath: file.path);
        entries.add({
          'assetId': 'item-capture-source-$hash',
          'logicalPath': path,
          'artifactHandle': staged.reference.handle,
          'tags': ['item-capture-provenance']
        });
      }
    }
    Future<void> apply(String action, Map<String, Object?> parameters,
        {String? expectedRevision}) async {
      final fresh = await snapshots.load(opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.editorReadProjection);
      final operation =
          'capture-sprites-${DateTime.now().microsecondsSinceEpoch}-${receipts.length}';
      _requireCurrent(shouldContinue);
      final plan = await api!.planMutation(
          opened.projectHandle,
          AuthoringRequest(
              requestId: operation,
              actionId: action,
              actionVersion: 1,
              workspaceHandle: opened.workspaceHandle.value,
              expectedRevision: expectedRevision ?? fresh.revision,
              idempotencyKey: operation,
              parameters: parameters));
      if (!plan.applicable) {
        throw FormatException(
            'Capture sprite mutation is not applicable: ${plan.nonApplicableReason}.');
      }
      _requireCurrent(shouldContinue);
      final applied = await api!.applyMutation(opened.projectHandle,
          planId: plan.planId, operationId: operation);
      receipts.add(applied.receipt.toJson());
    }

    for (var offset = 0; offset < entries.length; offset += 200) {
      final chunk =
          entries.sublist(offset, math.min(offset + 200, entries.length));
      for (final entry in chunk) {
        if (await (await _projectFile(root, entry['logicalPath']! as String))
            .exists()) {
          throw const FormatException('An import destination changed. Retry.');
        }
      }
      await apply('asset.import_batch', {'entries': chunk});
      imported.addAll(
          imports.skip(offset).take(chunk.length).map((item) => item.id));
    }
    for (final assignment in assignments) {
      _requireCurrent(shouldContinue);
      final fresh = await snapshots.load(opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.editorReadProjection);
      final definitions =
          fresh.itemCatalog!.entries.where((item) => item.id == assignment.id);
      if (definitions.isEmpty || definitions.single.capture == null) {
        throw const FormatException('The capture item changed. Retry.');
      }
      final definition = definitions.single;
      if (definition.capture!.animationSpritePath != null) continue;
      await apply(
          'item.update',
          {
            'itemId': definition.id,
            'definition': definition
                .copyWith(
                    capture: definition.capture!
                        .copyWith(animationSpritePath: assignment.path))
                .toJson()
          },
          expectedRevision: fresh.revision);
      updated.add(definition.id);
    }
    return {
      ...result(),
      if (pack != null) 'sourceArchiveSha256': pack.archiveSha256
    };
  } on Object catch (error) {
    if (receipts.isEmpty) rethrow;
    throw ProjectCaptureSpriteProvisioningPartialFailure(
        error.toString(), imported, updated, receipts);
  } finally {
    await api?.detachWorkspace(opened.workspaceHandle);
    opener.closeWorkspace(opened.workspaceHandle);
    await staging?.delete(recursive: true);
  }
}

final class ProjectCaptureSpriteProvisioningCancelled implements Exception {
  const ProjectCaptureSpriteProvisioningCancelled();
}

final class ProjectCaptureSpriteProvisioningPartialFailure
    implements Exception {
  const ProjectCaptureSpriteProvisioningPartialFailure(
      this.error, this.importedItems, this.updatedItems, this.receipts);
  final String error;
  final List<String> importedItems;
  final List<String> updatedItems;
  final List<Map<String, Object?>> receipts;
  Map<String, Object?> toJson() => {
        'error': error,
        'importedItems': importedItems,
        'updatedItems': updatedItems,
        'receipts': receipts,
        'atomicAssetBatchLimit': 200,
        'catalogUpdatesAreSeparate': true
      };
}

void _requireCurrent(bool Function()? shouldContinue) {
  if (shouldContinue?.call() == false) {
    throw const ProjectCaptureSpriteProvisioningCancelled();
  }
}

void _requireItemId(String id) {
  if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(id)) {
    throw const FormatException(
        'A capture item ID cannot form a safe filename.');
  }
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
      throw const FormatException('Unsafe capture sprite project path.');
    }
  }
  return File(current);
}

void _requireSprite(List<int> bytes) {
  final decoded = image.decodePng(Uint8List.fromList(bytes));
  if (decoded == null || decoded.width != 64 || decoded.height != 2048) {
    throw const FormatException(
        'A capture sprite must be a 64x2048 PNG with 32 vertical cells.');
  }
}

_CapturePack _readPack(ProjectCaptureSpritePack source) {
  final manifest =
      jsonDecode(utf8.decode(source.manifestBytes)) as Map<String, dynamic>;
  final hash = sha256.convert(source.archiveBytes).toString();
  if (manifest['schemaVersion'] != 1 || manifest['archiveSha256'] != hash) {
    throw const FormatException(
        'Capture sprite archive does not match its manifest.');
  }
  final metadata = Map<String, dynamic>.from(manifest['files'] as Map);
  final files = <String, Uint8List>{};
  for (final file
      in ZipDecoder().decodeBytes(source.archiveBytes, verify: true).files) {
    if (!file.isFile ||
        file.isSymbolicLink ||
        !RegExp(r'^[a-z][a-z0-9_-]*\.png$').hasMatch(file.name)) {
      throw const FormatException('Unsafe capture sprite archive entry.');
    }
    final id = file.name.substring(0, file.name.length - 4);
    final info = metadata[id];
    final bytes = file.content;
    if (files.containsKey(id) ||
        info is! Map ||
        info['bytes'] != bytes.length ||
        info['sha256'] != sha256.convert(bytes).toString()) {
      throw const FormatException('Capture sprite differs from its manifest.');
    }
    if (RegExp(r'^ball_(?:[1-9]|1[0-9]|2[0-8])$').hasMatch(id)) {
      _requireSprite(bytes);
      if (info['width'] != 64 || info['height'] != 2048) {
        throw const FormatException('Invalid capture sprite dimensions.');
      }
    }
    files[id] = bytes;
  }
  if (files.length != metadata.length) {
    throw const FormatException('Capture sprite archive inventory differs.');
  }
  final mappings = Map<String, String>.from(manifest['itemMappings'] as Map);
  for (final entry in mappings.entries) {
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(entry.key) ||
        !files.containsKey(entry.value) ||
        !RegExp(r'^ball_(?:[1-9]|1[0-9]|2[0-8])$').hasMatch(entry.value)) {
      throw const FormatException('Invalid capture item to sprite mapping.');
    }
  }
  return _CapturePack(files, mappings, hash, manifest);
}

final class _CapturePack {
  const _CapturePack(
      this.files, this.itemMappings, this.archiveSha256, this.manifest);
  final Map<String, Uint8List> files;
  final Map<String, String> itemMappings;
  final String archiveSha256;
  final Map<String, dynamic> manifest;
}
