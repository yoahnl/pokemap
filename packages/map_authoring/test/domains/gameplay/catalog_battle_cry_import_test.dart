import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Uint8List _wav() {
  final bytes = Uint8List(108);
  bytes.setRange(0, 4, ascii.encode('RIFF'));
  bytes.setRange(8, 16, ascii.encode('WAVEfmt '));
  bytes.setRange(36, 40, ascii.encode('data'));
  ByteData.sublistView(bytes)
    ..setUint32(4, bytes.length - 8, Endian.little)
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, 8000, Endian.little)
    ..setUint32(28, 16000, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(40, 64, Endian.little);
  bytes[44] = 1;
  return bytes;
}

void main() {
  for (final scenario in [
    'normal',
    'staged-file',
    'existing',
    'collision',
    'changed',
    'invalid',
    'raw-replace',
    'interrupted'
  ]) {
    test('canonical cry import: $scenario', () async {
      final parent = Directory(Platform.environment['AVELUNE_QA_ROOT']!);
      final root = await parent.createTemp('catalog-cry-');
      addTearDown(() => root.delete(recursive: true));
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      await WorkingProjectCatalog.create(
        store: store,
        projectId: 'cry-import',
        project:
            const ProjectManifest(name: 'Cry import', maps: [], tilesets: []),
      );
      final bytes =
          scenario == 'invalid' ? Uint8List.fromList([1, 2, 3]) : _wav();
      final cryPath =
          'assets/pokemon/battle-cries/${sha256.convert(bytes)}.wav';
      const mediaPath = 'data/pokemon/media/oshawott.json';
      final media = File('${root.path}/$mediaPath');
      await media.parent.create(recursive: true);
      final original = {
        'schemaVersion': 1,
        'speciesId': 'oshawott',
        'defaultFormId': 'base',
        'variants': {
          'base': {
            'frontStatic': 'assets/front.png',
            if (scenario == 'existing') 'cry': 'assets/chosen.wav'
          }
        },
      };
      final before = utf8.encode(jsonEncode(original));
      await media.writeAsBytes(before);
      final reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final opener = ProjectOpenService(
          policy: policy,
          fileReader: reader,
          handles: handles,
          catalogMetadataFields: {},
          workshopScope: true,
          initializeSceneOwners: false);
      var opened = await opener.openProject(root.path);
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final artifactStore = LocalArtifactStore(
          allowedSourceRoots: [root.path],
          maximumArtifactBytes: maximumAuthoringArtifactBytesV1);
      var interrupt = false;
      String? interruptedOperation;
      final api = LocalMapAuthoringMutationApi(
          policy: policy,
          snapshotLoader: snapshots,
          catalogFileReader: reader,
          artifactStore: artifactStore,
          faultInjector: (context) {
            if (interrupt &&
                context.checkpoint ==
                    AuthoringTransactionCheckpoint.afterReservation) {
              interrupt = false;
              interruptedOperation = context.operationId;
              throw const AuthoringTransactionSimulatedCrash();
            }
          });
      await api.attachProject(
          projectRootPath: root.path,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle);
      addTearDown(() async {
        await api.detachWorkspace(opened.workspaceHandle);
        opener.closeWorkspace(opened.workspaceHandle);
      });
      await api.prepareWorkshopCatalog(opened.projectHandle);
      final artifact = scenario == 'staged-file'
          ? await (() async {
              final source = File('${root.path}/source.wav');
              await source.writeAsBytes(bytes);
              return artifactStore.importFile(source.path,
                  declaredMediaType: 'audio/wav');
            })()
          : await api.artifacts.put(bytes, declaredMediaType: 'audio/wav');
      final params = {
        'relativePath': mediaPath,
        'document': {
          ...original,
          'variants': {
            'base': {'frontStatic': 'assets/front.png', 'cry': cryPath}
          }
        },
        'beforeBytesBase64': base64Encode(before),
      };
      final snapshot = await api.readWorkshopSnapshot(opened.projectHandle,
          actionId: 'pokemon.media.write', parameters: params);
      final request = AuthoringRequest.fromJson({
        'requestId': 'import-cry',
        'actionId': 'pokemon.media.write',
        'actionVersion': 1,
        'workspaceHandle': opened.workspaceHandle.value,
        'expectedRevision': snapshot.revision,
        'idempotencyKey': 'import-cry',
        'parameters': params,
        'dryRun': false,
        'extensions': {
          'workshopScope': true,
          'battleCryArtifact': artifact.reference.handle
        },
      });
      if (scenario == 'existing' || scenario == 'invalid') {
        await expectLater(
            api.planMutation(opened.projectHandle, request), throwsA(anything));
        expect(await media.readAsBytes(), before);
        expect(await File('${root.path}/$cryPath').exists(), isFalse);
        return;
      }
      final plan = await api.planMutation(opened.projectHandle, request);
      final cry = File('${root.path}/$cryPath');
      expect(await cry.exists(), isFalse);
      if (scenario == 'collision') {
        await cry.parent.create(recursive: true);
        await cry.writeAsBytes(bytes);
        await expectLater(
            api.applyMutation(opened.projectHandle,
                planId: plan.planId, operationId: 'import-cry'),
            throwsA(anything));
        expect(await media.readAsBytes(), before);
        expect(await cry.readAsBytes(), bytes);
        return;
      }
      if (scenario == 'interrupted') {
        interrupt = true;
        await expectLater(
            api.applyMutation(opened.projectHandle,
                planId: plan.planId, operationId: 'import-cry'),
            throwsA(isA<AuthoringTransactionSimulatedCrash>()));
        expect(interruptedOperation, isNotNull);
        await cry.delete();
        await api.detachWorkspace(opened.workspaceHandle);
        opener.closeWorkspace(opened.workspaceHandle);
        opened = await opener.openProject(root.path);
        await api.attachProject(
            projectRootPath: root.path,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle);
        await expectLater(
            api.recoverMutation(opened.projectHandle,
                operationId: interruptedOperation!),
            throwsA(isA<AuthoringHistoryException>()));
        expect(await media.readAsBytes(), before);
        return;
      }
      final applied = await api.applyMutation(opened.projectHandle,
          planId: plan.planId, operationId: 'import-cry');
      expect(await cry.readAsBytes(), bytes);
      expect(jsonDecode(await media.readAsString())['variants']['base']['cry'],
          cryPath);
      if (scenario == 'raw-replace') {
        final replacementBytes = Uint8List.fromList(bytes)..[44] = 42;
        final replacement = await api.artifacts
            .put(replacementBytes, declaredMediaType: 'audio/wav');
        final project = await snapshots.load(opened.projectHandle);
        final raw = await api.planMutation(
            opened.projectHandle,
            AuthoringRequest(
              requestId: 'raw-replace',
              actionId: 'asset.raw.replace',
              actionVersion: 1,
              workspaceHandle: opened.workspaceHandle.value,
              expectedRevision: project.revision,
              idempotencyKey: 'raw-replace',
              parameters: {
                'logicalPath': cryPath,
                'expectedArtifactHandle': artifact.reference.handle,
                'replacementArtifactHandle': replacement.reference.handle,
              },
            ));
        await expectLater(
            api.applyMutation(opened.projectHandle,
                planId: raw.planId, operationId: 'raw-replace'),
            throwsA(anything));
        expect(await cry.readAsBytes(), bytes);
        return;
      }
      await api.undoMutation(opened.projectHandle,
          entryId: applied.receipt.receiptId, idempotencyKey: 'undo-cry');
      expect(await cry.readAsBytes(), bytes);
      if (scenario == 'changed') {
        await cry.writeAsBytes([3, 4, 5]);
        await expectLater(
            api.redoMutation(opened.projectHandle,
                entryId: applied.receipt.receiptId, idempotencyKey: 'redo-cry'),
            throwsA(anything));
        expect(await media.readAsBytes(), before);
      } else {
        await api.redoMutation(opened.projectHandle,
            entryId: applied.receipt.receiptId, idempotencyKey: 'redo-cry');
        expect(
            jsonDecode(await media.readAsString())['variants']['base']['cry'],
            cryPath);
      }
    });
  }
}
