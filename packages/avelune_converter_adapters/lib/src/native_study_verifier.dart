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
      ProjectValidator.validate(snapshot.manifest, maps: snapshot.maps);
      for (final map in snapshot.maps) {
        MapValidator.validate(map, projectDialogueContext: snapshot.manifest);
      }
      final catalog = AssetCatalog.fromJson(jsonDecode(
              utf8.decode(snapshot.resourceBytes(assetCatalogResourceIdentity)))
          as Map<String, dynamic>);
      if (catalog.records.length > 512 || snapshot.maps.length > 4096) {
        throw _failed(
            'Native study verification inventory exceeds its bounded scope.');
      }
      final access = handles.resolveProject(opened.projectHandle);
      var total = 0;
      final identities = <String, ProjectResourceIdentity>{};
      for (final record in catalog.records) {
        cancellation?.check();
        if (record.artifact.byteLength > 67108864) {
          throw _failed(
              'Registered asset exceeds the 64 MiB verification budget.');
        }
        for (final key in {
          record.logicalPath,
          assetBlobStorageKey(record.artifact)
        }) {
          if (identities.containsKey(key)) continue;
          total += record.artifact.byteLength;
          if (total > 536870912) {
            throw _failed(
                'Registered assets and blobs exceed the 512 MiB verification budget.');
          }
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
