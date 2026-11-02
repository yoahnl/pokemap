import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'migration and GIF import preserve all unrelated media data with undo and redo',
      () async {
    final parent = Directory(Platform.environment['AVELUNE_QA_ROOT']!);
    final root = await parent.createTemp('legacy-gif-preservation-');
    addTearDown(() => root.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final project = await WorkingProjectCatalog.create(
      store: store,
      projectId: 'legacy-gif-preservation',
      project:
          const ProjectManifest(name: 'Legacy media', maps: [], tilesets: []),
    );
    await project.close();
    const path = 'data/pokemon/media/pidgey.json';
    final media = File('${root.path}/$path');
    await media.parent.create(recursive: true);
    final original = <String, dynamic>{
      'schemaVersion': 1,
      'speciesId': 'pidgey',
      'defaultFormId': 'base',
      'vendorExtension': {'keep': true},
      'variants': {
        'base': {'frontStatic': 'assets/chosen.png', 'cry': 'assets/cry.wav'},
        'alternative': {
          'frontStatic': 'assets/alternative.png',
          'custom': {'keep': 7}
        },
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
    final opened = await opener.openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        catalogFileReader: reader);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    addTearDown(() async {
      await api.detachWorkspace(opened.workspaceHandle);
      opener.closeWorkspace(opened.workspaceHandle);
    });
    await api.prepareWorkshopCatalog(opened.projectHandle);
    final gif = base64Decode(
        'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7');
    final gifPath = 'assets/pokemon/battle-gifs/${sha256.convert(gif)}.gif';
    final artifact =
        await api.artifacts.put(gif, declaredMediaType: 'image/gif');
    final migrated = {...original, 'schemaVersion': 2};
    final variants = Map<String, dynamic>.from(migrated['variants'] as Map);
    final base = Map<String, dynamic>.from(variants['base'] as Map);
    final desired = {
      ...migrated,
      'variants': {
        ...variants,
        'base': {...base, 'frontAnimated': gifPath}
      }
    };

    Future<AuthoringMutationPlanResult> plan(
        String id, Map<String, Object?> parameters,
        {Map<String, Object?> extensions = const {}}) async {
      final snapshot = await api.readWorkshopSnapshot(opened.projectHandle,
          actionId: 'pokemon.media.write', parameters: parameters);
      return api.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: id,
            actionId: 'pokemon.media.write',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: id,
            parameters: parameters,
            extensions: {'workshopScope': true, ...extensions},
          ));
    }

    final migration = await plan('migrate', {
      'relativePath': path,
      'document': migrated,
      'beforeBytesBase64': base64Encode(before),
      'migrateSchema': true,
    });
    final migrationReceipt = await api.applyMutation(opened.projectHandle,
        planId: migration.planId, operationId: 'migrate');
    final migratedBytes = await media.readAsBytes();
    expect(jsonDecode(utf8.decode(migratedBytes)), migrated);
    final selection = {
      'battleGifArtifacts': {'frontAnimated': artifact.reference.handle}
    };
    final tampered = {
      ...desired,
      'vendorExtension': {'keep': false}
    };
    await expectLater(
        plan(
            'tamper',
            {
              'relativePath': path,
              'document': tampered,
              'beforeBytesBase64': base64Encode(migratedBytes),
            },
            extensions: selection),
        throwsFormatException);
    expect(await media.readAsBytes(), migratedBytes);
    final gifPlan = await plan(
        'gif',
        {
          'relativePath': path,
          'document': desired,
          'beforeBytesBase64': base64Encode(migratedBytes),
        },
        extensions: selection);
    final gifReceipt = await api.applyMutation(opened.projectHandle,
        planId: gifPlan.planId, operationId: 'gif');
    final finalBytes = await media.readAsBytes();
    expect(jsonDecode(utf8.decode(finalBytes)), desired);
    expect(await File('${root.path}/$gifPath').readAsBytes(), gif);
    await api.undoMutation(opened.projectHandle,
        entryId: gifReceipt.receipt.receiptId, idempotencyKey: 'undo-gif');
    expect(await media.readAsBytes(), migratedBytes);
    await api.undoMutation(opened.projectHandle,
        entryId: migrationReceipt.receipt.receiptId,
        idempotencyKey: 'undo-migration');
    expect(await media.readAsBytes(), before);
    await api.redoMutation(opened.projectHandle,
        entryId: migrationReceipt.receipt.receiptId,
        idempotencyKey: 'redo-migration');
    expect(await media.readAsBytes(), migratedBytes);
    await api.redoMutation(opened.projectHandle,
        entryId: gifReceipt.receipt.receiptId, idempotencyKey: 'redo-gif');
    expect(await media.readAsBytes(), finalBytes);
  });
}
