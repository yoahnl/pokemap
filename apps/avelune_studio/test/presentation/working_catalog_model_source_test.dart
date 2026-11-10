import 'dart:async';

import 'package:avelune_studio/features/resources/application/working_catalog_controller.dart';
import 'package:avelune_studio/features/resources/coordination/working_catalog_workflow.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

Future<(WorkingCatalogController, WorkingCatalogWorkflow)> _open(
  _Port port,
  Future<bool> Function(String) replace, {
  Future<void> Function()? synchronize,
}) async {
  final catalog = WorkingCatalogController(port);
  addTearDown(catalog.dispose);
  await catalog.search('');
  await catalog.select(_entry);
  final workflow = WorkingCatalogWorkflow(
    catalog: catalog,
    isActive: () => true,
    confirmExit: () async => WorkingCatalogExitDecision.stay,
    changed: () {},
    onSaved: synchronize,
    onReplaceModelSource: replace,
  );
  addTearDown(workflow.dispose);
  return (catalog, workflow);
}

void main() {
  test('source replacement refreshes only selected detail and invalidates the unchanged preview identity', () async {
    final port = _Port();
    final gate = Completer<bool>();
    var calls = 0, globalRefreshes = 0;
    final (catalog, workflow) = await _open(
      port,
      (_) {
        calls++;
        return gate.future;
      },
      synchronize: () async {
        globalRefreshes++;
      },
    );
    final replacing = workflow.replaceModelSource();
    expect(calls, 1);
    expect(workflow.sourceReplacementActive, isTrue);
    expect(await workflow.allowExit(closing: true), isFalse);
    final identity = catalog.detail!.visualIdentity;
    gate.complete(true);
    await replacing;
    expect(port.opens, 2);
    expect(port.queries, 1);
    expect(globalRefreshes, 0);
    expect(catalog.detail!.visualIdentity, same(identity));
    expect(workflow.sourcePreviewRevision, 1);
    expect(workflow.saved, 'Modèle remplacé.');
    expect(await workflow.allowExit(closing: true), isTrue);
  });

  test(
    'dirty model metadata blocks replacement without dropping its draft',
    () async {
      final port = _Port();
      var calls = 0;
      final (catalog, workflow) = await _open(port, (_) async {
        calls++;
        return true;
      });
      catalog.edit(name: 'Mon brouillon');
      await workflow.replaceModelSource();
      expect(calls, 0);
      expect(catalog.draft!.name, 'Mon brouillon');
      expect(port.opens, 1);
    },
  );

  for (final refused in [false, true]) {
    test(
      'source ${refused ? 'refusal' : 'picker cancellation'} keeps selected detail and preview identity',
      () async {
        final port = _Port();
        final (catalog, workflow) = await _open(port, (_) async {
          if (refused) {
            throw const ResourceFailure(
              'Conservez les deux animations de porte.',
            );
          }
          return false;
        });
        final detail = catalog.detail;
        await workflow.replaceModelSource();
        expect(port.opens, 1);
        expect(port.queries, 1);
        expect(catalog.detail, same(detail));
        expect(workflow.sourcePreviewRevision, 0);
        expect(workflow.saved, isNull);
        if (refused) {
          expect(
            workflow.navigationNotice,
            'Conservez les deux animations de porte.',
          );
        }
      },
    );
  }

  test(
    'published source reconciliation retries without publishing another source',
    () async {
      final port = _Port();
      var publications = 0, callbacks = 0;
      final (_, workflow) = await _open(port, (_) async {
        callbacks++;
        if (callbacks == 1) {
          publications++;
          throw ResourceFailure(
            'Publication conservée : actualisez le modèle.',
            partialReceipt: ResourceMutationReceipt(
              before: _project,
              manifest: _project,
              beforeRevision: 'a',
              revision: 'b',
              changedPaths: const ['assets/models3d/door.glb'],
            ),
          );
        }
        return true;
      });
      await workflow.replaceModelSource();
      expect(workflow.sourceReconciliationPending, isTrue);
      expect(workflow.editable, isFalse);
      expect(await workflow.allowExit(closing: true), isTrue);
      expect(await workflow.allowExit(), isFalse);
      await workflow.replaceModelSource();
      expect(callbacks, 2);
      expect(publications, 1);
      expect(workflow.sourceReplacementPending, isFalse);
      expect(port.opens, 2);
      expect(port.queries, 1);
    },
  );

  test('failed detail refresh retries the read without reopening the source picker', () async {
    final port = _Port();
    var replacements = 0;
    final (_, workflow) = await _open(port, (_) async {
      replacements++;
      port.failOpen = true;
      return true;
    });
    await workflow.replaceModelSource();
    expect(workflow.sourceReloadPending, isTrue);
    expect(workflow.editable, isFalse);
    expect(await workflow.allowExit(closing: true), isTrue);
    await workflow.replaceModelSource();
    expect(replacements, 1);
    expect(port.opens, 3);
    expect(port.queries, 1);
    expect(workflow.sourceReplacementPending, isFalse);
    expect(await workflow.allowExit(closing: true), isTrue);
  });
  test(
    'a newer selected detail cannot acknowledge the previous model reload',
    () async {
      final port = _Port();
      final (catalog, workflow) = await _open(port, (_) async => true);
      final gate = Completer<WorkingCatalogDetail>();
      final started = Completer<void>();
      port.doorGate = gate;
      port.doorStarted = started;
      final replacing = workflow.replaceModelSource();
      await started.future;
      const other = WorkingCatalogEntry(
        id: 'other',
        kind: 'model3d',
        name: 'Autre modèle',
      );
      await catalog.select(other);
      gate.complete(
        WorkingCatalogDetail(
          entry: _entry,
          revision: 'r',
          definitions: _project,
        ),
      );
      await replacing;
      expect(catalog.selected?.identity, other.identity);
      expect(catalog.detail?.entry.identity, other.identity);
      expect(workflow.sourceReloadPending, isTrue);
      expect(workflow.saved, isNull);
    },
  );
}

const _entry = WorkingCatalogEntry(id: 'door', kind: 'model3d', name: 'Porte');
final _project = ProjectManifest(
  name: 'Projection',
  maps: const [],
  tilesets: const [],
  models3d: [
    ProjectModel3dEntry(
      id: 'door',
      name: 'Porte',
      sourceAssetId: 'door-source',
      relativePath: 'assets/models3d/door.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 2, z: 1),
        ),
        meshCount: 1,
        triangleCount: 12,
      ),
    ),
  ],
);

final class _Port implements WorkingCatalogPort {
  final identity = Object();
  int queries = 0, opens = 0;
  String color = 'couleur initiale';
  bool failOpen = false;
  Completer<WorkingCatalogDetail>? doorGate;
  Completer<void>? doorStarted;
  @override
  Future<WorkingCatalogPage> query({
    required String kind,
    required String text,
    String? cursor,
    String? placementContext,
  }) async {
    queries++;
    return WorkingCatalogPage(revision: 'r', items: const [_entry], total: 1);
  }

  @override
  Future<WorkingCatalogDetail> open(WorkingCatalogEntry entry) async {
    opens++;
    if (entry.id == 'door' && doorGate != null) {
      doorStarted?.complete();
      return await doorGate!.future;
    }
    if (failOpen) {
      failOpen = false;
      throw StateError('Lecture momentanément indisponible');
    }
    return WorkingCatalogDetail(
      entry: entry,
      revision: 'r',
      definitions: _project,
      previewIdentity: identity,
    );
  }

  @override
  Future<void> close() async {}
  @override
  Future<void> recover(String operationId) async {}
  @override
  Future<WorkingCatalogDetail> save(
    WorkingCatalogEntry entry,
    WorkingCatalogDraft draft, {
    required String revision,
  }) => throw StateError('Unexpected metadata save');
}
