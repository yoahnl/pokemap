import 'dart:async';

import 'package:avelune_studio/features/resources/application/working_catalog_controller.dart';
import 'package:avelune_studio/features/resources/coordination/working_catalog_workflow.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

Future<WorkingCatalogController> _open(_Port port) async {
  final controller = WorkingCatalogController(port);
  addTearDown(controller.dispose);
  await controller.search('');
  await controller.select(port.entry);
  return controller;
}

WorkingCatalogWorkflow _workflow(
  WorkingCatalogController controller, {
  Future<void> Function()? synchronize,
  Future<WorkingCatalogExitDecision> Function()? confirm,
  bool readOnly = false,
}) {
  final workflow = WorkingCatalogWorkflow(
    catalog: controller,
    isActive: () => true,
    confirmExit: confirm ?? () async => WorkingCatalogExitDecision.stay,
    changed: () {},
    onSaved: synchronize,
    readOnly: readOnly,
  );
  addTearDown(workflow.dispose);
  return workflow;
}

void main() {
  test(
    'library searches globally and saves typed metadata through its port',
    () async {
      final port = _Port();
      final controller = await _open(port);
      final workflow = _workflow(controller);
      expect(controller.items, hasLength(50));
      expect(controller.total, 125);
      await controller.search('Décor 124');
      expect(port.lastQuery, 'Décor 124');
      await controller.select(port.entry);
      workflow.edit(
        name: 'Bosquet modifié',
        description: 'Description visible',
      );
      workflow.editTags(' forêt, ombre, forêt, ');
      expect(await workflow.save(), isTrue);
      expect(port.saved!.name, 'Bosquet modifié');
      expect(port.saved!.description, 'Description visible');
      expect(port.saved!.tags, ['forêt', 'ombre']);
      expect(controller.dirty, isFalse);
      expect(workflow.saved, 'Ressource enregistrée.');
    },
  );

  test('model light save preserves native preview identity and avoids a catalog query', () async {
    final port = _LightPort();
    final controller = await _open(port);
    var synchronized = 0;
    final workflow = WorkingCatalogWorkflow(
      catalog: controller,
      isActive: () => true,
      confirmExit: () async => WorkingCatalogExitDecision.stay,
      changed: () {},
      onModelLightSaved: (model, before, after) async {
        synchronized++;
        expect(model.light, isNull);
        expect(before, 'r0');
        expect(after, 'r1');
      },
    );
    final identity = controller.detail!.visualIdentity;
    final queries = port.queries;
    await workflow.configureLight(null);
    expect(port.light, isNull);
    expect(synchronized, 1);
    expect(port.queries, queries);
    expect(controller.detail!.visualIdentity, same(identity));
  });

  test('character shadow draft publishes and returns to inheritance through the catalogue controller', () async {
    final port = _Port()
      ..entry = const WorkingCatalogEntry(
        id: 'guide',
        kind: 'character',
        name: 'Guide',
      );
    final controller = await _open(port);
    controller.edit(contactShadow: true);
    expect(await controller.save(), isTrue);
    expect(port.saved!.contactShadow, isTrue);
    controller.edit(contactShadow: null);
    expect(await controller.save(), isTrue);
    expect(port.saved!.contactShadow, isNull);
  });

  test(
    'library keeps edits made while synchronizing a saved resource',
    () async {
      final port = _Port();
      final controller = await _open(port);
      final started = Completer<void>(), synchronization = Completer<void>();
      final workflow = _workflow(
        controller,
        synchronize: () {
          started.complete();
          return synchronization.future;
        },
        confirm: () async => WorkingCatalogExitDecision.save,
      );
      controller.edit(name: 'Première modification');
      final leaving = workflow.allowExit(closing: true);
      await started.future;
      controller.edit(name: 'Nouvelle saisie conservée');
      synchronization.complete();
      expect(await leaving, isFalse);
      expect(controller.dirty, isTrue);
      expect(controller.draft!.name, 'Nouvelle saisie conservée');
      expect(port.saved!.name, 'Première modification');
      expect(workflow.saved, isNull);
    },
  );

  test('interrupted catalogue recovers before performing its search', () async {
    final port = _Port();
    final controller = WorkingCatalogController(
      port,
      recoveryOperationIds: ['interrupted'],
    );
    addTearDown(controller.dispose);
    final workflow = _workflow(controller);
    await controller.search('');
    expect(port.lastQuery, isNull);
    await workflow.recover();
    expect(controller.recoveryOperationIds, isEmpty);
    expect(port.lastQuery, '');
    expect(controller.error, isNull);
  });

  test(
    'published catalogue metadata remains read-only through the workflow',
    () async {
      final port = _Port();
      final controller = await _open(port);
      final workflow = _workflow(controller, readOnly: true);
      final before = controller.draft;
      workflow.edit(name: 'Interdit');
      workflow.editTags('interdit');
      expect(await workflow.save(), isFalse);
      expect(controller.draft, same(before));
      expect(port.metadataSaves, 0);
      expect(workflow.editable, isFalse);
    },
  );

  for (final decision in WorkingCatalogExitDecision.values) {
    test(
      'dirty catalogue exit applies the explicit ${decision.name} choice',
      () async {
        final port = _Port();
        final controller = await _open(port);
        final workflow = _workflow(controller, confirm: () async => decision);
        controller.edit(name: 'Modification');
        final accepted = await workflow.allowExit(closing: true);
        expect(accepted, decision != WorkingCatalogExitDecision.stay);
        expect(controller.dirty, decision == WorkingCatalogExitDecision.stay);
        expect(
          port.metadataSaves,
          decision == WorkingCatalogExitDecision.save ? 1 : 0,
        );
      },
    );
  }

  test(
    'a late discard consent preserves input edited during the decision',
    () async {
      final port = _Port();
      final controller = await _open(port);
      final consent = Completer<WorkingCatalogExitDecision>();
      final workflow = _workflow(controller, confirm: () => consent.future);
      controller.edit(name: 'Première modification');
      final leaving = workflow.allowExit(closing: true);
      controller.edit(name: 'Saisie plus récente');
      consent.complete(WorkingCatalogExitDecision.discard);
      expect(await leaving, isFalse);
      expect(controller.draft!.name, 'Saisie plus récente');
      expect(port.metadataSaves, 0);
    },
  );

  test(
    'failed synchronization retries refresh without publishing metadata twice',
    () async {
      final port = _Port();
      final controller = await _open(port);
      var synchronizations = 0;
      final workflow = _workflow(
        controller,
        synchronize: () async {
          if (++synchronizations == 1) throw StateError('refresh unavailable');
        },
      );
      controller.edit(name: 'Modification enregistrée');
      expect(await workflow.save(), isFalse);
      expect(workflow.synchronizationPending, isTrue);
      expect(workflow.navigationNotice, contains('refresh unavailable'));
      expect(await workflow.allowExit(closing: true), isTrue);
      expect(synchronizations, 2);
      expect(port.metadataSaves, 1);
      expect(workflow.synchronizationPending, isFalse);
    },
  );
}

class _Port implements WorkingCatalogPort {
  String? lastQuery;
  int metadataSaves = 0;
  WorkingCatalogDraft? saved;
  WorkingCatalogEntry entry = const WorkingCatalogEntry(
    id: 'decor_124',
    kind: 'element',
    name: 'Décor 124',
  );

  @override
  Future<WorkingCatalogPage> query({
    required String kind,
    required String text,
    String? cursor,
    String? placementContext,
  }) async {
    lastQuery = text;
    return WorkingCatalogPage(
      revision: 'test',
      items: text.isEmpty
          ? [
              for (var index = 0; index < 50; index++)
                WorkingCatalogEntry(
                  id: 'decor_$index',
                  kind: 'element',
                  name: 'Décor $index',
                ),
            ]
          : [entry],
      total: text.isEmpty ? 125 : 1,
      nextCursor: text.isEmpty ? 'next' : null,
    );
  }

  @override
  Future<WorkingCatalogDetail> open(WorkingCatalogEntry selected) async =>
      WorkingCatalogDetail(
        entry: entry,
        revision: 'test',
        definitions: const ProjectManifest(
          name: 'Projection',
          maps: [],
          tilesets: [],
        ),
      );

  @override
  Future<WorkingCatalogDetail> save(
    WorkingCatalogEntry selected,
    WorkingCatalogDraft draft, {
    required String revision,
  }) async {
    metadataSaves++;
    saved = draft;
    entry = WorkingCatalogEntry(
      id: selected.id,
      kind: selected.kind,
      name: draft.name,
      description: draft.description,
      tags: draft.tags,
      placementContext: draft.placementContext,
      contactShadow: draft.contactShadow,
    );
    return open(entry);
  }

  @override
  Future<void> close() async {}
  @override
  Future<void> recover(String operationId) async {}
}

class _LightPort extends _Port implements WorkingCatalogModelLightPort {
  _LightPort() {
    entry = const WorkingCatalogEntry(
      id: 'lamp',
      kind: 'model3d',
      name: 'Lampe',
    );
  }
  final identity = Object();
  int queries = 0, saves = 0;
  Model3dPointLight? light = Model3dPointLight(
    localPosition: Model3dVector3(x: 0, y: 2, z: 0),
  );
  @override
  Future<WorkingCatalogPage> query({
    required String kind,
    required String text,
    String? cursor,
    String? placementContext,
  }) async {
    queries++;
    return WorkingCatalogPage(revision: 'r$saves', items: [entry], total: 1);
  }

  @override
  Future<WorkingCatalogDetail> open(WorkingCatalogEntry selected) async =>
      WorkingCatalogDetail(
        entry: entry,
        revision: 'r$saves',
        previewIdentity: identity,
        definitions: ProjectManifest(
          name: 'Projection',
          maps: const [],
          tilesets: const [],
          models3d: [
            ProjectModel3dEntry(
              id: 'lamp',
              name: 'Lampe',
              sourceAssetId: 'model3d_lamp',
              relativePath: 'assets/models3d/lamp.glb',
              light: light,
              inspection: Model3dInspection(
                bounds: Model3dBounds(
                  min: Model3dVector3.zero,
                  max: Model3dVector3(x: 1, y: 3, z: 1),
                ),
                meshCount: 1,
                triangleCount: 4,
              ),
            ),
          ],
        ),
      );
  @override
  Future<WorkingCatalogDetail> configureLight(
    WorkingCatalogEntry selected,
    Model3dPointLight? value, {
    required String revision,
  }) async {
    light = value;
    saves++;
    return open(selected);
  }
}
