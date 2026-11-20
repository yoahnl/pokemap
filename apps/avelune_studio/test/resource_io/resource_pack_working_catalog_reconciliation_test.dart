import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/coordination/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_pack_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/domains/assets/resource_pack_import_fixture.dart';
import 'resource_pack_import_host_fixture.dart' show RecordingPackPort;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'an imported pack reconciles the working catalog after writing',
    () async {
      final source = await ResourcePackImportFixture.create(
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.element, id: 'decor'),
        ],
      );
      addTearDown(source.dispose);
      final root = await Directory('${source.directory.path}/target').create();
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final catalog = await WorkingProjectCatalog.create(
        store: store,
        projectId: 'working-pack-reconciliation',
        project: source.snapshot.manifest,
      );
      await catalog.close();
      final archive = File('${source.directory.path}/source.aveluneassets');
      final sink = archive.openWrite();
      try {
        await source.archive.withSource(
          (payload) => sink.addStream(sourceChunks(payload)),
        );
      } finally {
        await sink.close();
      }
      final session = ProjectSession(
        sessionId: root.path,
        name: 'Catalogue de recette',
        directoryPath: await root.resolveSymbolicLinks(),
        storage: ProjectSessionStorage.workingCatalog,
      );
      final maps = LocalMapWorkspaceAdapter();
      final workspace = MapWorkspaceController(session, maps);
      addTearDown(workspace.dispose);
      await workspace.initialize();
      expect(workspace.error, isNull);

      final resources = LocalResourceAdapter(
        session: session,
        mapAdapter: maps,
      );
      addTearDown(resources.dispose);
      final pack = LocalResourcePackAdapter(
        session: session,
        mapAdapter: maps,
        resources: resources,
      );
      addTearDown(pack.dispose);
      final recording = RecordingPackPort(pack);
      var publications = 0;
      final transfer = ResourcePackTransferController(
        port: recording,
        picker: () async => archive.path,
        accept: (_) async {
          publications++;
        },
      );
      addTearDown(transfer.dispose);

      final head = File('${root.path}/${CatalogStorageStore.headStorageKey}');
      final before = await head.readAsBytes();
      await transfer.beginImport();
      expect(transfer.error, isNull);
      await transfer.selectFiltered();
      await transfer.prepare();
      expect(transfer.canApply, isTrue, reason: transfer.error);

      await transfer.apply();
      final applyError = transfer.error;
      final after = await head.readAsBytes();
      expect(after, isNot(before), reason: 'Erreur du transfert: $applyError');
      final receipt = recording.projection!['receipt']! as Map;
      expect(receipt['status'], 'applied');
      final diff = receipt['diff']! as Map;
      final headDiff = (diff['entries']! as List).whereType<Map>().where(
        (entry) => (entry['resource'] as Map?)?['kind'] == 'catalogHead',
      );
      final headRevision = computeAuthoringBytesFingerprint(
        after,
        logicalName: CatalogStorageStore.headStorageKey,
      );

      final retried = transfer.requiresReconciliation;
      if (retried) await transfer.retryReconciliation();
      expect(await head.readAsBytes(), after);
      expect(
        transfer.error,
        isNull,
        reason:
            'Erreur après écriture: $applyError. '
            'Nouvelle lecture lancée: $retried. Publications: $publications. '
            'Révision du HEAD sur disque: $headRevision. '
            'Entrée catalogue du reçu: ${headDiff.toList()}.',
      );
      expect(transfer.phase, ResourcePackTransferPhase.complete);
      expect(publications, 1);
      final accepted = recording.receipt!;
      expect(
        accepted.pathRevisions[CatalogStorageStore.headStorageKey],
        headRevision,
      );
      final imported = transfer.firstImported!;
      final item = await maps.readResourceLibraryItem(
        session,
        imported.kind,
        imported.id,
        expectedRevision: accepted.revision,
      );
      expect(item.id, imported.id);
    },
  );
}
