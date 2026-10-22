import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;

import 'converter_workflow.dart';

final class NativeStudyVerification {
  const NativeStudyVerification(
      {required this.projectPath,
      required this.nativeRevision,
      required this.mapCount,
      required this.assetCount});
  final String projectPath;
  final String nativeRevision;
  final int mapCount;
  final int assetCount;
  bool get verified => true;
  bool get playableCertified => false;
  Map<String, Object?> toJson() => {
        'kind': 'nativeStudyVerification',
        'version': 1,
        'projectPath': projectPath,
        'nativeRevision': nativeRevision,
        'mapCount': mapCount,
        'assetCount': assetCount,
        'verified': verified,
        'playableCertified': playableCertified
      };
}

final class NativeStudyVerifier {
  const NativeStudyVerifier({this.snapshotLoadProfileSink});

  static const maxLogicalAssetRecords = 16384;
  static const maxLogicalAssetBytes = 536870912;
  static const maxRetainedBlobBytes = 536870912;

  static ({int logicalAssetBytes, int retainedBlobBytes}) validateAssetBudget(
      AssetCatalog catalog,
      {ScanCancellation? cancellation}) {
    cancellation?.check();
    validateInventory(logicalAssetCount: catalog.records.length, mapCount: 0);
    var logicalAssetBytes = 0;
    var retainedBlobBytes = 0;
    final blobs = <String>{};
    final paths = <String, ContentArtifactRef>{};
    for (final record in catalog.records) {
      cancellation?.check();
      if (record.artifact.byteLength > 67108864) {
        throw _failed(
            'Registered asset exceeds the 64 MiB verification budget.');
      }
      logicalAssetBytes += record.artifact.byteLength;
      if (logicalAssetBytes > maxLogicalAssetBytes) {
        throw _failed(
            'Registered logical assets exceed the 512 MiB verification budget.');
      }
      final blob = assetBlobStorageKey(record.artifact);
      if (blobs.add(blob)) retainedBlobBytes += record.artifact.byteLength;
      if (retainedBlobBytes > maxRetainedBlobBytes) {
        throw _failed(
            'Retained unique blobs exceed the 512 MiB verification budget.');
      }
      for (final key in {record.logicalPath, blob}) {
        final previous = paths[key];
        if (previous != null &&
            (previous.digest != record.artifact.digest ||
                previous.byteLength != record.artifact.byteLength)) {
          throw _failed(
              'Registered storage key $key has conflicting content identities.');
        }
        paths[key] = record.artifact;
      }
    }
    cancellation?.check();
    return (
      logicalAssetBytes: logicalAssetBytes,
      retainedBlobBytes: retainedBlobBytes
    );
  }

  static void validateInventory(
      {required int logicalAssetCount, required int mapCount}) {
    if (logicalAssetCount > maxLogicalAssetRecords) {
      throw _failed('Native study verification has $logicalAssetCount logical '
          'asset records, exceeding its $maxLogicalAssetRecords record scope.');
    }
    if (mapCount > 4096) {
      throw _failed('Native study verification has $mapCount maps, '
          'exceeding its 4096 map scope.');
    }
  }

  final ProjectSnapshotLoadProfileSink? snapshotLoadProfileSink;

  Future<NativeStudyVerification> verify(
      {required String projectPath,
      required String allowedParentPath,
      ScanCancellation? cancellation}) async {
    if (!path.isAbsolute(projectPath) ||
        !path.isAbsolute(allowedParentPath) ||
        projectPath.contains('\u0000') ||
        allowedParentPath.contains('\u0000') ||
        !path.isWithin(allowedParentPath, projectPath)) {
      throw const ConverterWorkflowFailure('native.verify.policy',
          'Read-only verification requires a project inside its explicit allowed parent.');
    }
    cancellation?.check();
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [allowedParentPath], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    WorkspaceHandle? workspace;
    try {
      final opened = await opener.openProject(projectPath);
      workspace = opened.workspaceHandle;
      final loader = ProjectSnapshotLoader(
          handles: handles, profileSink: snapshotLoadProfileSink);
      final snapshot = await loader.load(opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.strict);
      cancellation?.check();
      if (snapshot.loadDiagnostics.isNotEmpty) {
        throw _failed('Strict native load reported diagnostics.');
      }
      ProjectValidator.validate(snapshot.manifest,
          maps: snapshot.maps, itemCatalog: snapshot.itemCatalog);
      for (final map in snapshot.maps) {
        MapValidator.validate(map, projectDialogueContext: snapshot.manifest);
      }
      final catalog = AssetCatalog.fromJson(jsonDecode(
              utf8.decode(snapshot.resourceBytes(assetCatalogResourceIdentity)))
          as Map<String, dynamic>);
      validateInventory(
          logicalAssetCount: catalog.records.length,
          mapCount: snapshot.maps.length);
      validateAssetBudget(catalog, cancellation: cancellation);
      final access = handles.resolveProject(opened.projectHandle);
      final identities = <String, ProjectResourceIdentity>{};
      for (final record in catalog.records) {
        cancellation?.check();
        for (final key in {
          record.logicalPath,
          assetBlobStorageKey(record.artifact)
        }) {
          if (identities.containsKey(key)) continue;
          final before = await access.readResourceIdentity(key);
          if (before == null ||
              before.byteLength != record.artifact.byteLength) {
            throw _failed('Registered asset is missing or has changed length.');
          }
          final bytes = await access.readBytes(key);
          final after = await access.readResourceIdentity(key);
          if (before != after ||
              bytes.length != record.artifact.byteLength ||
              ContentArtifactRef.fromBytes(bytes,
                      mediaType: record.artifact.mediaType) !=
                  record.artifact) {
            throw _failed(
                'Registered logical asset or retained blob differs from its content identity.');
          }
          identities[key] = after!;
        }
      }
      final validation =
          await AuthoringReadApi(openService: opener, snapshotLoader: loader)
              .validateProject(opened.projectHandle);
      if (!validation.valid) {
        throw _failed(
            'Native project validation reported blocking diagnostics: ${jsonEncode(validation.toJson())}');
      }
      final fresh = await loader.load(opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.strict);
      if (fresh.revision != snapshot.revision ||
          fresh.loadDiagnostics.isNotEmpty) {
        throw _failed('Native revision changed during read-only verification.');
      }
      for (final entry in identities.entries) {
        cancellation?.check();
        if (await access.readResourceIdentity(entry.key) != entry.value) {
          throw _failed('Asset identity changed during verification.');
        }
      }
      cancellation?.check();
      return NativeStudyVerification(
          projectPath: projectPath,
          nativeRevision: snapshot.revision,
          mapCount: snapshot.maps.length,
          assetCount: catalog.records.length);
    } on ConverterWorkflowFailure {
      rethrow;
    } on ContractError catch (error) {
      if (error.code == 'source.cancelled') {
        throw const ConverterWorkflowFailure(
            'workflow.cancelled', 'Read-only verification was cancelled.');
      }
      throw _failed(error.toString());
    } on Object catch (error) {
      throw _failed(error.toString());
    } finally {
      if (workspace != null) opener.closeWorkspace(workspace);
    }
  }
}

ConverterWorkflowFailure _failed(String message) => ConverterWorkflowFailure(
    'native.verify.failed',
    message.length > 4096 ? message.substring(0, 4096) : message);
