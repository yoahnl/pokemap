import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final scenario in [
    'import',
    'existing',
    'invalid',
    'animated',
    'collision',
    'changed'
  ]) {
    test('scoped PNG import preserves project data: $scenario', () async {
      final parent = Directory(
          Platform.environment['AVELUNE_QA_ROOT'] ?? Directory.systemTemp.path);
      await parent.create(recursive: true);
      final root = await parent.createTemp('pokemon-png-');
      addTearDown(() => root.delete(recursive: true));
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final working = await WorkingProjectCatalog.create(
        store: store,
        projectId: 'pokemon-png',
        project: const ProjectManifest(name: 'PNG', maps: [], tilesets: []),
      );
      await working.close();
      final png = image.Image(width: 2, height: 2);
      if (scenario == 'animated') {
        png.addFrame(image.Image(width: 2, height: 2));
      }
      final bytes =
          scenario == 'invalid' ? <int>[1, 2, 3] : image.encodePng(png);
      final imagePath = 'assets/pokemon/images/${sha256.convert(bytes)}.png';
      final mediaPath = 'data/pokemon/media/bulbasaur.json';
      final media = File('${root.path}/$mediaPath');
      await media.parent.create(recursive: true);
      final original = {
        'schemaVersion': 2,
        'speciesId': 'bulbasaur',
        'defaultFormId': 'base',
        'vendorExtension': {'keep': true},
        'variants': {
          'base': {
            'frontStatic': 'assets/custom.png',
            if (scenario == 'existing') 'icon': 'assets/chosen.png',
          },
          'alternate': {'icon': 'assets/alternate.png'},
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
        initializeSceneOwners: false,
      );
      final opened = await opener.openProject(root.path);
      final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        catalogFileReader: reader,
      );
      await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      addTearDown(() async {
        await api.detachWorkspace(opened.workspaceHandle);
        opener.closeWorkspace(opened.workspaceHandle);
      });
      await api.prepareWorkshopCatalog(opened.projectHandle);
      final artifact =
          await api.artifacts.put(bytes, declaredMediaType: 'image/png');
      final params = {
        'relativePath': mediaPath,
        'document': {
          ...original,
          'variants': {
            ...original['variants'] as Map,
            'base': {
              'frontStatic': 'assets/custom.png',
              'icon': imagePath,
              'backStatic': imagePath
            },
          },
        },
        'beforeBytesBase64': base64Encode(before),
      };
      final snapshot = await api.readWorkshopSnapshot(
        opened.projectHandle,
        actionId: 'pokemon.media.write',
        parameters: params,
      );
      final request = AuthoringRequest(
        requestId: 'import-png',
        actionId: 'pokemon.media.write',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'import-png',
        parameters: params,
        extensions: {
          'workshopScope': true,
          'pokemonPngArtifacts': {
            'icon': artifact.reference.handle,
            'backStatic': artifact.reference.handle,
          },
        },
      );
      if (scenario == 'invalid' ||
          scenario == 'animated' ||
          scenario == 'existing') {
        await expectLater(api.planMutation(opened.projectHandle, request),
            throwsFormatException);
        expect(await media.readAsBytes(), before);
        return;
      }
      final plan = await api.planMutation(opened.projectHandle, request);
      expect(await File('${root.path}/$imagePath').exists(), isFalse);
      if (scenario == 'collision') {
        final file = File('${root.path}/$imagePath');
        await file.parent.create(recursive: true);
        await file.writeAsBytes([3, 4, 5]);
        await expectLater(
            api.applyMutation(opened.projectHandle,
                planId: plan.planId, operationId: 'import-png'),
            throwsFormatException);
        expect(await media.readAsBytes(), before);
        expect(await file.readAsBytes(), [3, 4, 5]);
        return;
      }
      final applied = await api.applyMutation(opened.projectHandle,
          planId: plan.planId, operationId: 'import-png');
      expect(await File('${root.path}/$imagePath').exists(), isTrue);
      expect(await File('${root.path}/$imagePath').readAsBytes(), bytes);
      final saved = jsonDecode(await media.readAsString()) as Map;
      expect(saved['vendorExtension'], {'keep': true});
      expect(saved['variants']['base']['frontStatic'], 'assets/custom.png');
      expect(saved['variants']['base']['icon'], imagePath);
      expect(saved['variants']['alternate'], {'icon': 'assets/alternate.png'});
      await api.undoMutation(opened.projectHandle,
          entryId: applied.receipt.receiptId, idempotencyKey: 'undo-png');
      expect(await File('${root.path}/$imagePath').readAsBytes(), bytes);
      if (scenario == 'changed') {
        await File('${root.path}/$imagePath').writeAsBytes([0, 1, 2]);
        await expectLater(
            api.redoMutation(opened.projectHandle,
                entryId: applied.receipt.receiptId, idempotencyKey: 'redo-png'),
            throwsA(isA<AuthoringHistoryException>()));
      } else {
        await api.redoMutation(opened.projectHandle,
            entryId: applied.receipt.receiptId, idempotencyKey: 'redo-png');
        expect(
            jsonDecode(await media.readAsString())['variants']['base']['icon'],
            imagePath);
      }
    });
  }
}
