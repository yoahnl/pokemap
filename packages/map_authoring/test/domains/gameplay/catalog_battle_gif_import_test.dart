import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final scenario in [
    'changed',
    'deleted',
    'interrupted',
    'after-promotion',
    'interrupted-write',
    'collision',
    'existing-file',
    'existing',
    'unavailable',
    'raw-replace',
    'raw-replace-case',
    'legacy-replace',
    'raw-history',
    'reuse'
  ]) {
    test('imports a shared GIF and rejects $scenario redo', () async {
      final parent = Directory(Platform.environment['AVELUNE_QA_ROOT'] ??
          (Platform.isMacOS
              ? '${Platform.environment['HOME']}/Library/Caches/AveluneQA'
              : Directory.systemTemp.path));
      await parent.create(recursive: true);
      final root = await parent.createTemp('catalog-battle-gif-import-');
      addTearDown(() async {
        await root.delete(recursive: true);
      });
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      await WorkingProjectCatalog.create(
          store: store,
          projectId: 'gif-import',
          project: const ProjectManifest(
              name: 'GIF import', maps: [], tilesets: []));
      final bytes = base64Decode(
          'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7');
      final gifPath = 'assets/pokemon/battle-gifs/${sha256.convert(bytes)}.gif';
      final mediaPath = 'data/pokemon/media/oshawott.json';
      final media = File('${root.path}/$mediaPath');
      final second = File('${root.path}/data/pokemon/media/seedot.json');
      await media.parent.create(recursive: true);
      final original = {
        'schemaVersion': 2,
        'speciesId': 'oshawott',
        'defaultFormId': 'base',
        'variants': {
          'base': {
            'frontStatic': 'assets/front.png',
            if (scenario == 'existing') 'frontAnimated': 'assets/chosen.gif'
          }
        }
      };
      final before = utf8.encode(jsonEncode(original));
      await media.writeAsBytes(before);
      final secondBefore = utf8.encode(jsonEncode({
        'schemaVersion': 2,
        'speciesId': 'seedot',
        'defaultFormId': 'base',
        'variants': {
          'base': {if (scenario != 'reuse') 'frontAnimated': gifPath}
        }
      }));
      await second.writeAsBytes(secondBefore);
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
      var interrupt = false;
      String? interruptedOperation;
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final api = LocalMapAuthoringMutationApi(
          policy: policy,
          snapshotLoader: snapshots,
          catalogFileReader: reader,
          faultInjector: (context) {
            if (interrupt &&
                (scenario == 'after-promotion'
                    ? context.checkpoint ==
                            AuthoringTransactionCheckpoint
                                .afterResourcePromoted &&
                        context.storageKey == mediaPath
                    : context.checkpoint ==
                        AuthoringTransactionCheckpoint.afterReservation)) {
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
      final artifact =
          await api.artifacts.put(bytes, declaredMediaType: 'image/gif');
      String? rawHistoryEntry;
      if (scenario == 'legacy-replace' || scenario == 'raw-history') {
        final gif = File('${root.path}/$gifPath');
        await gif.parent.create(recursive: true);
        final oldBytes =
            scenario == 'raw-history' ? [...bytes, 0, 0, 0, 0] : bytes;
        final newBytes =
            scenario == 'raw-history' ? bytes : [...bytes, 0, 0, 0, 0];
        await gif.writeAsBytes(oldBytes);
        final oldArtifact =
            await api.artifacts.put(oldBytes, declaredMediaType: 'image/gif');
        final newArtifact =
            await api.artifacts.put(newBytes, declaredMediaType: 'image/gif');
        final project = await snapshots.load(opened.projectHandle);
        final rawPlan = await api.planMutation(
            opened.projectHandle,
            AuthoringRequest(
                requestId: 'legacy-raw',
                actionId: 'asset.raw.replace',
                actionVersion: 1,
                workspaceHandle: opened.workspaceHandle.value,
                expectedRevision: project.revision,
                idempotencyKey: 'legacy-raw',
                parameters: {
                  'logicalPath': gifPath,
                  'expectedArtifactHandle': oldArtifact.reference.handle,
                  'replacementArtifactHandle': newArtifact.reference.handle
                }));
        final rawResult = await api.applyMutation(opened.projectHandle,
            planId: rawPlan.planId, operationId: 'legacy-raw');
        expect(await gif.readAsBytes(), newBytes);
        if (scenario == 'legacy-replace') return;
        rawHistoryEntry = rawResult.receipt.receiptId;
        await gif.delete();
      }
      final roleArtifacts = <String, String>{
        'frontAnimated': artifact.reference.handle
      };
      final variant = <String, Object?>{
        'frontStatic': 'assets/front.png',
        'frontAnimated': gifPath
      };
      var padding = 1;
      for (final role in [
        'backAnimated',
        'frontShinyAnimated',
        'backShinyAnimated'
      ]) {
        final data = [...bytes, ...List<int>.filled(padding++, 0)];
        final extra =
            await api.artifacts.put(data, declaredMediaType: 'image/gif');
        roleArtifacts[role] = extra.reference.handle;
        variant[role] =
            'assets/pokemon/battle-gifs/${sha256.convert(data)}.gif';
      }
      final params = {
        'relativePath': mediaPath,
        'document': {
          ...original,
          'variants': {'base': variant}
        },
        'beforeBytesBase64': base64Encode(before)
      };
      final snapshot = await api.readWorkshopSnapshot(opened.projectHandle,
          actionId: 'pokemon.media.write', parameters: params);
      if (scenario == 'unavailable') {
        await api.artifacts.release(artifact.reference.handle);
      }
      final request = AuthoringRequest(
          requestId: 'import-gif',
          actionId: 'pokemon.media.write',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'import-gif',
          parameters: params,
          extensions: {
            'workshopScope': true,
            'battleGifArtifacts': roleArtifacts
          });
      if (scenario == 'existing' || scenario == 'unavailable') {
        await expectLater(api.planMutation(opened.projectHandle, request),
            throwsFormatException);
        expect(await media.readAsBytes(), before);
        expect(await File('${root.path}/$gifPath').exists(), isFalse);
        return;
      }
      final plan = await api.planMutation(opened.projectHandle, request);
      expect(await File('${root.path}/$gifPath').exists(), isFalse);
      if (scenario == 'collision' || scenario == 'existing-file') {
        final collision = File('${root.path}/$gifPath');
        await collision.parent.create(recursive: true);
        final existingBytes = scenario == 'collision' ? [3, 4, 5] : bytes;
        await collision.writeAsBytes(existingBytes);
        await expectLater(
            api.applyMutation(opened.projectHandle,
                planId: plan.planId, operationId: 'import-gif'),
            throwsFormatException);
        expect(await collision.readAsBytes(), existingBytes);
        expect(await media.readAsBytes(), before);
        expect(await second.readAsBytes(), secondBefore);
        return;
      }
      if (scenario == 'interrupted-write') {
        interrupt = true;
        await expectLater(
            api.applyMutation(opened.projectHandle,
                planId: plan.planId, operationId: 'import-gif'),
            throwsA(isA<AuthoringTransactionSimulatedCrash>()));
        await File('${root.path}/$gifPath').delete();
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
            throwsA(isA<AuthoringHistoryException>().having(
                (error) => error.code, 'code', 'history.pokemon_gif_changed')));
        expect(await media.readAsBytes(), before);
        expect(await second.readAsBytes(), secondBefore);
        return;
      }
      final applied = await api.applyMutation(opened.projectHandle,
          planId: plan.planId, operationId: 'import-gif');
      expect(await File('${root.path}/$gifPath').readAsBytes(), bytes);
      if (scenario == 'raw-replace' || scenario == 'raw-replace-case') {
        final replacement = await api.artifacts
            .put([...bytes, 0, 0, 0, 0], declaredMediaType: 'image/gif');
        final targetPath = scenario == 'raw-replace-case'
            ? gifPath.replaceFirst('pokemon/battle-gifs', 'POKEMON/BATTLE-GIFS')
            : gifPath;
        if (!await File('${root.path}/$targetPath').exists()) return;
        final project = await snapshots.load(opened.projectHandle);
        final rawRequest = AuthoringRequest(
            requestId: 'replace-shared',
            actionId: 'asset.raw.replace',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: project.revision,
            idempotencyKey: 'replace-shared',
            parameters: {
              'logicalPath': targetPath,
              'expectedArtifactHandle': artifact.reference.handle,
              'replacementArtifactHandle': replacement.reference.handle
            });
        final rawPlan =
            await api.planMutation(opened.projectHandle, rawRequest);
        await expectLater(
            api.applyMutation(opened.projectHandle,
                planId: rawPlan.planId, operationId: 'replace-shared'),
            throwsA(anything));
        expect(await File('${root.path}/$gifPath').readAsBytes(), bytes);
        return;
      }
      for (final path in variant.values
          .whereType<String>()
          .where((value) => value.endsWith('.gif'))) {
        expect(await File('${root.path}/$path').exists(), isTrue);
      }
      expect(
          jsonDecode(await media.readAsString())['variants']['base']
              ['frontStatic'],
          'assets/front.png');
      if (scenario == 'reuse') {
        final secondParams = {
          'relativePath': 'data/pokemon/media/seedot.json',
          'document': {
            'schemaVersion': 2,
            'speciesId': 'seedot',
            'defaultFormId': 'base',
            'variants': {'base': {'frontAnimated': gifPath}}
          },
          'beforeBytesBase64': base64Encode(secondBefore),
        };
        final selected = await api.readWorkshopSnapshot(opened.projectHandle,
            actionId: 'pokemon.media.write', parameters: secondParams);
        final secondPlan = await api.planMutation(opened.projectHandle,
            AuthoringRequest(requestId: 'second-import', actionId: 'pokemon.media.write',
                actionVersion: 1, workspaceHandle: opened.workspaceHandle.value,
                expectedRevision: selected.revision, idempotencyKey: 'second-import',
                parameters: secondParams, extensions: {'workshopScope': true,
                  'battleGifArtifacts': {'frontAnimated': artifact.reference.handle}}));
        final secondApplied = await api.applyMutation(opened.projectHandle,
            planId: secondPlan.planId, operationId: 'second-import');
        await api.undoMutation(opened.projectHandle,
            entryId: secondApplied.receipt.receiptId, idempotencyKey: 'second-undo');
        expect(await File('${root.path}/$gifPath').readAsBytes(), bytes);
        expect(jsonDecode(await media.readAsString())['variants']['base']['frontAnimated'], gifPath);
        return;
      }
      await api.undoMutation(opened.projectHandle,
          entryId: applied.receipt.receiptId, idempotencyKey: 'undo-gif');
      expect(await File('${root.path}/$gifPath').readAsBytes(), bytes);
      expect(await second.readAsBytes(), secondBefore);
      if (scenario == 'raw-history') {
        await expectLater(
            api.undoMutation(opened.projectHandle,
                entryId: rawHistoryEntry!, idempotencyKey: 'undo-raw'),
            throwsFormatException);
        expect(await File('${root.path}/$gifPath').readAsBytes(), bytes);
        return;
      }
      await api.redoMutation(opened.projectHandle,
          entryId: applied.receipt.receiptId, idempotencyKey: 'redo-gif');
      await api.undoMutation(opened.projectHandle,
          entryId: applied.receipt.receiptId, idempotencyKey: 'undo-gif-again');
      if (scenario == 'interrupted' || scenario == 'after-promotion') {
        interrupt = true;
        await expectLater(
            api.redoMutation(opened.projectHandle,
                entryId: applied.receipt.receiptId,
                idempotencyKey: 'redo-gif-crash'),
            throwsA(isA<AuthoringTransactionSimulatedCrash>()));
        expect(interruptedOperation, isNotNull);
        await api.detachWorkspace(opened.workspaceHandle);
        opener.closeWorkspace(opened.workspaceHandle);
        opened = await opener.openProject(root.path);
        await api.attachProject(
            projectRootPath: root.path,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle);
      }
      if (scenario == 'deleted') {
        await File('${root.path}/$gifPath').delete();
      } else {
        await File('${root.path}/$gifPath')
            .writeAsBytes([0, 1, 2], flush: true);
      }
      await expectLater(
          scenario == 'interrupted' || scenario == 'after-promotion'
              ? api.recoverMutation(opened.projectHandle,
                  operationId: interruptedOperation!)
              : api.redoMutation(opened.projectHandle,
                  entryId: applied.receipt.receiptId,
                  idempotencyKey: 'redo-gif-corrupt'),
          throwsA(isA<AuthoringHistoryException>().having(
              (error) => error.code, 'code', 'history.pokemon_gif_changed')));
      expect(await second.readAsBytes(), secondBefore);
    });
  }
}
