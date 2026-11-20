import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

import '../../../../packages/map_authoring/test/support/create_model_replacement_fixture.dart';
import '../../../../packages/map_authoring/test/support/resource_index_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late ProjectSession session;
  late LocalMapWorkspaceAdapter maps;
  late LocalResourceAdapter adapter;
  late MapWorkspaceController workspace;
  var refuseRefresh = false;
  var draftAppeared = false;
  var guardLocked = false;

  setUp(() async {
    final base = Directory(
      '/Users/karim/Library/Caches/AveluneQA/model-replacement/studio',
    );
    await base.create(recursive: true);
    root = await base.createTemp('project-');
    final fixture = await createModelReplacementFixture(root, placed: true);
    await fixture.close();
    session = ProjectSession(
      sessionId: root.path,
      name: 'Remplacement 3D',
      directoryPath: root.path,
      storage: ProjectSessionStorage.workingCatalog,
    );
    maps = LocalMapWorkspaceAdapter();
    workspace = MapWorkspaceController(session, maps);
    await workspace.initialize();
    await workspace.activate(workspace.project!.maps.single);
    await maps.loadResourceKind(session, 'model3d');
    refuseRefresh = draftAppeared = guardLocked = false;
    adapter = LocalResourceAdapter(
      session: session,
      mapAdapter: maps,
      beforeTransactionPrecondition: () async {
        draftAppeared = guardLocked;
      },
      beforeReconciliation: () async {
        if (refuseRefresh) throw const ResourceFailure('Test de relecture.');
      },
    );
  });

  tearDown(() async {
    workspace.dispose();
    await adapter.dispose();
    await root.delete(recursive: true);
  });

  test(
    'a reviewed GLB is the committed bytes, independently of the picker',
    () async {
      final port = adapter.modelReplacement;
      final source = File('${root.path}/assets/models3d/tree.glb');
      final original = await source.readAsBytes();
      final input = File('${root.path}/candidate.glb');
      final candidate = await input.readAsBytes();
      final revision = await maps.resourceRevision(session);
      final file = PickedProjectLibraryFile(
        path: input.path,
        name: 'candidate',
        artifact: ContentArtifactRef.fromBytes(
          candidate,
          mediaType: 'model/gltf-binary',
        ),
      );
      final cancelled = await port.prepareSource(
        modelId: 'tree',
        file: file,
        expectedRevision: revision,
      );
      await port.release(cancelled);
      expect(await source.readAsBytes(), original);
      await expectLater(
        port.apply(cancelled, checkDrafts: () => null),
        throwsA(isA<ResourceFailure>()),
      );
      final plan = await port.prepareSource(
        modelId: 'tree',
        file: file,
        expectedRevision: revision,
      );
      expect(plan.inspectedBytes, candidate);
      expect(plan.after.id, plan.before.id);
      expect(
        plan.after.inspection.bounds.size.x,
        greaterThan(plan.before.inspection.bounds.size.x),
      );
      await input.writeAsBytes(original);
      final applied = await port.apply(plan, checkDrafts: () => null);
      expect(applied.entryId, isNot(applied.receipt.operationId));
      expect(await source.readAsBytes(), candidate);
      refuseRefresh = true;
      await expectLater(
        port.reconcile(applied),
        throwsA(isA<ResourceFailure>()),
      );
      expect(await source.readAsBytes(), candidate);
      refuseRefresh = false;
      await port.reconcile(applied);
      final restored = await port.undo(applied, checkDrafts: () => null);
      await port.reconcile(restored);
      expect(restored.restored, isTrue);
      expect(await source.readAsBytes(), original);
      expect((await adapter.readWorkshopModel('tree')).model, plan.before);
    },
  );

  test(
    'the reviewed usage plan refreshes the affected map and its undo',
    () async {
      final port = adapter.modelReplacement;
      final revision = await maps.resourceRevision(session);
      final map = File('${root.path}/maps/map.json');
      final original = await map.readAsBytes();
      final plan = await port.prepareUsages(
        modelId: 'tree',
        replacementId: 'alternate',
        expectedRevision: revision,
      );
      expect(plan.maps.single.id, 'map');
      expect(plan.borders, {'fence': 'Fence'});
      expect((plan.redirected, plan.recalculated), (3, 3));
      expect(await map.readAsBytes(), original);
      guardLocked = true;
      await expectLater(
        port.apply(
          plan,
          checkDrafts: () => draftAppeared ? 'Brouillon ouvert.' : null,
        ),
        throwsA(isA<ResourceFailure>()),
      );
      expect(await map.readAsBytes(), original);
      guardLocked = draftAppeared = false;
      final reviewed = await port.prepareUsages(
        modelId: 'tree',
        replacementId: 'alternate',
        expectedRevision: revision,
      );
      final applied = await port.apply(reviewed, checkDrafts: () => null);
      await port.reconcile(applied);
      await workspace.acceptExternalMutation(
        applied.resources,
        reportFailure: true,
      );
      expect(
        workspace.active!.current.spatialScene!.instances.map(
          (value) => value.modelId,
        ),
        everyElement('alternate'),
      );
      final external = await ResourceIndexFixture.openExisting(root);
      try {
        await external.api.undoMutation(
          external.opened.projectHandle,
          entryId: applied.entryId,
          idempotencyKey: applied.restorationOperationId,
        );
      } finally {
        await external.close();
      }
      expect(await map.readAsBytes(), original);
      final restored = await port.undo(
        applied,
        checkDrafts: () {
          fail('Retrying a completed restoration must reuse its receipt.');
        },
      );
      expect(restored.restored, isTrue);
      await port.reconcile(restored);
      await workspace.acceptExternalMutation(
        restored.resources,
        reportFailure: true,
      );
      expect(
        workspace.active!.current.spatialScene!.instances.map(
          (value) => value.modelId,
        ),
        everyElement('tree'),
      );
      expect(await map.readAsBytes(), original);
    },
  );
}
