import 'dart:async';

import 'package:avelune_studio/features/resources/application/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_pack_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_api.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('unknown publication blocks close until status-only reconciliation confirms publication', () async {
    final port = ExportPackTestPort();
    final sink = PendingExportTestSink();
    final c = ResourcePackTransferController(
      port: port,
      picker: () async => null,
      exportSink: sink,
      accept: (_) async {},
    );
    addTearDown(c.dispose);
    await c.beginExport();
    for (final e in {
      'name': 'Pack',
      'author': 'Publisher',
      'universeId': 'original',
      'provenance': 'Original',
    }.entries) {
      await c.setExportField(e.key, e.value);
    }
    await c.selectFiltered();
    await c.prepare();
    c.setOrganizationAcknowledgement(true);
    await c.export();
    expect(c.requiresPublicationReconciliation, isTrue);
    expect(c.outputPath, isNull);
    expect(await c.requestClose(), isFalse);
    final exports = port.verbs.where((verb) => verb == 'export').length;
    await c.retryPublication();
    expect(c.requiresPublicationReconciliation, isFalse);
    expect(c.outputPath, '/published.aveluneassets');
    expect(port.verbs.where((verb) => verb == 'export'), hasLength(exports));
    expect(sink.requeries, 1);
    expect(await c.requestClose(), isTrue);
  });

  for (final verb in ['stage_license', 'prepare', 'export']) {
    test(
      'late successful export $verb reply is owned and released while close waits',
      () async {
        final port = LateExportPackPort();
        final c = ResourcePackTransferController(
          port: port,
          picker: () async => null,
          pickLicenses: () async => ['/LICENSE'],
          exportSink: ExportTestSink(),
          accept: (_) async {},
        );
        addTearDown(c.dispose);
        await c.beginExport();
        for (final e in {
          'name': 'Pack',
          'author': 'Publisher',
          'universeId': 'original',
          'provenance': 'Original',
        }.entries) {
          await c.setExportField(e.key, e.value);
        }
        await c.selectFiltered();
        if (verb == 'export') {
          await c.prepare();
          c.setOrganizationAcknowledgement(true);
        }
        port.lateVerb = verb;
        final operation = verb == 'stage_license'
            ? c.addLicenseDocuments()
            : verb == 'prepare'
            ? c.prepare()
            : c.export();
        await port.entered.future;
        var done = false;
        final close = c.requestClose().then((v) {
          done = true;
          return v;
        });
        await Future<void>.delayed(Duration.zero);
        expect(done, isFalse);
        port.gate.complete();
        await operation;
        expect(await close, isTrue);
        final handle = verb == 'stage_license'
            ? 'license-1'
            : verb == 'prepare'
            ? 'native-prepared-1'
            : 'artifact';
        expect(port.released.where((h) => h == handle), hasLength(1));
        expect(port.released, isNot(contains('native-preview-1')));
        expect(c.outputPath, isNull);
      },
    );
  }
  test(
    'late failed native preview cannot report an error after the route closes',
    () async {
      final port = LatePreviewExportPort();
      final c = ResourcePackTransferController(
        port: port,
        picker: () async => null,
        exportSink: ExportTestSink(),
        accept: (_) async {},
      );
      addTearDown(c.dispose);
      await c.beginExport();
      for (final e in {
        'name': 'Pack',
        'author': 'Publisher',
        'universeId': 'original',
        'provenance': 'Original',
      }.entries) {
        await c.setExportField(e.key, e.value);
      }
      await c.selectFiltered();
      await c.prepare();
      port.delay = true;
      final reading = c.nextPreviewPage();
      await port.entered.future;
      final close = c.requestClose();
      port.gate.completeError(StateError('obsolete preview'));
      await reading;
      expect(await close, isTrue);
      expect(c.error, isNull);
    },
  );

  test('native owner release failure is observable and close retries the shared owner once', () async {
    final port = ExportPackTestPort();
    final c = ResourcePackTransferController(
      port: port,
      picker: () async => null,
      exportSink: ExportTestSink(),
      accept: (_) async {},
    );
    addTearDown(c.dispose);
    await c.beginExport();
    for (final e in {
      'name': 'Pack',
      'author': 'Publisher',
      'universeId': 'original',
      'provenance': 'Original',
    }.entries) {
      await c.setExportField(e.key, e.value);
    }
    await c.selectFiltered();
    await c.prepare();
    expect(c.error, isNull);
    port.failNativeRelease = true;
    await c.setExportField('name', 'Changed');
    expect(c.error, contains('cleanup'));
    expect(await c.requestClose(), isTrue);
    expect(port.released, isNot(contains('native-preview-1')));
  });
  test('repreparing retries a failed native owner cleanup before creating another owner', () async {
    final port = ExportPackTestPort();
    final c = ResourcePackTransferController(
      port: port,
      picker: () async => null,
      exportSink: ExportTestSink(),
      accept: (_) async {},
    );
    addTearDown(c.dispose);
    await c.beginExport();
    for (final e in {
      'name': 'Pack',
      'author': 'Publisher',
      'universeId': 'original',
      'provenance': 'Original',
    }.entries) {
      await c.setExportField(e.key, e.value);
    }
    await c.selectFiltered();
    await c.prepare();
    port.failNativeRelease = true;
    await c.setExportField('name', 'Changed');
    expect(c.error, contains('cleanup'));
    await c.prepare();
    expect(c.error, isNull);
    expect(
      port.released.where((handle) => handle == 'native-prepared-1'),
      hasLength(2),
    );
    expect(port.preparations, 2);
    expect(await c.requestClose(), isTrue);
    expect(port.released, isNot(contains('native-preview-1')));
  });
  test('a reached memory edit after preview resets acknowledgement before building', () async {
    final port = ExportPackTestPort();
    var signature = 'before';
    final c = ResourcePackTransferController(
      port: port,
      picker: () async => null,
      exportSink: ExportTestSink(),
      localDrafts: () => [
        ResourcePackLocalDraft(
          kind: 'borderBlueprint',
          id: 'late',
          label: 'Late border',
          signature: signature,
        ),
      ],
      accept: (_) async {},
    );
    addTearDown(c.dispose);
    await c.beginExport();
    for (final e in {
      'name': 'Pack',
      'author': 'Publisher',
      'universeId': 'original',
      'provenance': 'Original',
    }.entries) {
      await c.setExportField(e.key, e.value);
    }
    await c.selectFiltered();
    await c.prepare();
    c.setOrganizationAcknowledgement(true);
    signature = 'after';
    await c.export();
    expect(port.lastExport, isNull);
    expect(c.organizationAcknowledged, isFalse);
    expect(c.localNotices.single.signature, 'after');
    expect(c.notice, contains('ont changé'));
    c.setOrganizationAcknowledgement(true);
    await c.export();
    expect(c.outputPath, isNotNull);
    expect(port.applies, 0);
  });

  test('native export stages several licences, previews exact selection and completes only after publication', () async {
    final port = ExportPackTestPort();
    final sink = ExportTestSink();
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => null,
      pickLicenses: () async => ['/one.txt', '/two.txt'],
      exportSink: sink,
      localDrafts: () => [
        const ResourcePackLocalDraft(
          kind: 'borderBlueprint',
          id: 'late',
          label: 'Late border',
          signature: 'draft-1',
        ),
        const ResourcePackLocalDraft(
          kind: 'borderBlueprint',
          id: 'neighbour',
          label: 'Neighbour',
          signature: 'unrelated',
        ),
      ],
      accept: (_) async {
        fail('export cannot accept a mutation');
      },
    );
    addTearDown(controller.dispose);
    await controller.beginExport();
    for (final entry in {
      'name': 'My pack',
      'version': '1.2.3',
      'author': 'Publisher',
      'universeId': 'original',
      'provenance': 'Original work',
    }.entries) {
      await controller.setExportField(entry.key, entry.value);
    }
    await controller.selectFiltered();
    await controller.addLicenseDocuments();
    expect(controller.licenseDocuments, hasLength(2));
    expect(port.authorizedPaths, ['/one.txt', '/two.txt']);
    await controller.prepare();
    expect(controller.error, isNull);
    expect(controller.direction, ResourcePackTransferDirection.exporting);
    expect(controller.localNotices.map((row) => row.id), ['late']);
    expect(controller.preview, hasLength(1));
    expect(controller.requiresOrganizationAcknowledgement, isTrue);
    expect(controller.canExport, isFalse);
    controller.setOrganizationAcknowledgement(true);
    expect(controller.canExport, isTrue);
    await controller.export();
    expect(controller.phase, ResourcePackTransferPhase.complete);
    expect(controller.outputPath, '/published.aveluneassets');
    expect(sink.bytes, [1, 2, 3]);
    expect(port.lastExport, {
      'preparedExportHandle': 'native-prepared-1',
      'acknowledgeOrganizationRemoval': true,
    });
    expect(port.applies, 0);
    expect(
      port.verbs.where((verb) => verb == 'selection.create'),
      hasLength(1),
    );
    expect(
      port.inputs
          .firstWhere((input) => input['mode'] == 'native')
          .containsKey('mapId'),
      isFalse,
    );
  });
  test('export edits release one native owner, reset acknowledgement and retain chosen licences', () async {
    final port = ExportPackTestPort();
    final c = ResourcePackTransferController(
      port: port,
      picker: () async => null,
      pickLicenses: () async => ['/one.txt'],
      exportSink: ExportTestSink(),
      accept: (_) async {},
    );
    addTearDown(c.dispose);
    await c.beginExport();
    for (final e in {
      'name': 'Pack',
      'author': 'Publisher',
      'universeId': 'original',
      'provenance': 'Original',
    }.entries) {
      await c.setExportField(e.key, e.value);
    }
    await c.selectFiltered();
    await c.addLicenseDocuments();
    await c.prepare();
    c.setOrganizationAcknowledgement(true);
    await c.setExportField('name', 'Changed');
    expect(c.organizationAcknowledged, isFalse);
    expect(c.canExport, isFalse);
    expect(c.licenseDocuments, hasLength(1));
    expect(port.released.where((h) => h == 'native-prepared-1'), hasLength(1));
    expect(port.released, isNot(contains('native-preview-1')));
    await c.prepare();
    c.setOrganizationAcknowledgement(true);
    await c.removeLicenseDocument(c.licenseDocuments.single.handle);
    expect(c.organizationAcknowledged, isFalse);
    expect(c.licenseDocuments, isEmpty);
    expect(port.released, contains('license-1'));
  });
  test(
    'close waits for an export sink after its canonical job has finished',
    () async {
      final port = ExportPackTestPort();
      final sink = ExportTestSink(wait: true);
      final c = ResourcePackTransferController(
        port: port,
        picker: () async => null,
        exportSink: sink,
        accept: (_) async {},
      );
      addTearDown(c.dispose);
      await c.beginExport();
      for (final e in {
        'name': 'Pack',
        'author': 'Publisher',
        'universeId': 'original',
        'provenance': 'Original',
      }.entries) {
        await c.setExportField(e.key, e.value);
      }
      await c.selectFiltered();
      await c.prepare();
      expect(c.error, isNull);
      c.setOrganizationAcknowledgement(true);
      expect(c.canExport, isTrue);
      final writing = c.export();
      await sink.entered.future;
      var closed = false;
      final closing = c.requestClose().then((v) {
        closed = true;
        return v;
      });
      await Future<void>.delayed(Duration.zero);
      expect(c.operationActive, isTrue);
      expect(closed, isFalse);
      sink.gate.complete();
      await writing;
      expect(await closing, isTrue);
      expect(c.outputPath, isNull);
      expect(c.phase, ResourcePackTransferPhase.closed);
    },
  );

  test(
    'concurrent close shares cleanup and a later import closes again',
    () async {
      final port = StrictClosePackPort();
      final controller = ResourcePackTransferController(
        port: port,
        picker: () async => '/chosen.aveluneassets',
        accept: (_) async {},
      );
      await controller.beginImport();
      final first = controller.requestClose();
      await port.entered.future;
      final second = controller.requestClose();
      port.gate.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(port.released, ['selection', 'inspection', 'archive']);
      await controller.beginImport();
      expect(await controller.requestClose(), isTrue);
      expect(port.released, hasLength(6));
      controller.dispose();
    },
  );
  test('pack notification preserves busy ownership of an ordinary resource mutation', () async {
    final workspace = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    await workspace.initialize();
    final resource = WaitingResourcePort();
    final navigation = ResourceNavigation(
      workspace: workspace,
      port: resource,
      visuals: WorkspaceTestVisuals(),
      onUse: (_) {},
      packPort: PackTestPort(),
      packPicker: () async => '/chosen.aveluneassets',
    );
    await navigation.packTransfer!.beginImport();
    final mutation = navigation.mutate('test.wait', {});
    await navigation.packTransfer!.setFilter(context: 'interior');
    expect(navigation.busy, isTrue);
    resource.completion.complete(PackTestPort().receipt);
    await mutation;
    expect(navigation.busy, isFalse);
    navigation.dispose();
    workspace.dispose();
  });
  test(
    'obsolete filter failures and disposed picker failures are ignored',
    () async {
      final port = DelayedQueryPackPort();
      final controller = ResourcePackTransferController(
        port: port,
        picker: () async => '/chosen.aveluneassets',
        accept: (_) async {},
      );
      await controller.beginImport();
      final oldPage = controller.setFilter(context: 'exterior');
      await port.entered.future;
      await controller.setFilter(context: 'interior');
      port.result.completeError(StateError('obsolete page'));
      await oldPage;
      expect(controller.error, isNull);
      expect(controller.visibleCount, 1);
      controller.dispose();
      final picker = Completer<String?>();
      final disposed = ResourcePackTransferController(
        port: PackTestPort(),
        picker: () => picker.future,
        accept: (_) async {
          fail('old session cannot accept');
        },
      );
      final pending = disposed.beginImport();
      await Future<void>.delayed(Duration.zero);
      disposed.dispose();
      picker.completeError(StateError('old picker'));
      await pending;
    },
  );
  test(
    'picker cancellation and invalid inspection preserve the project',
    () async {
      final port = PackTestPort();
      final cancelled = ResourcePackTransferController(
        port: port,
        picker: () async => null,
        accept: (_) async {},
      );
      await cancelled.beginImport();
      expect(port.verbs, isEmpty);
      port.invalidInspection = true;
      final invalid = ResourcePackTransferController(
        port: port,
        picker: () async => '/chosen.aveluneassets',
        accept: (_) async {},
      );
      await invalid.beginImport();
      expect(invalid.error, isNotNull);
      expect(port.applies, 0);
      expect(port.authorized, '/chosen.aveluneassets');
      cancelled.dispose();
      invalid.dispose();
    },
  );

  test('select all is server side and hidden selection is retained', () async {
    final port = PackTestPort();
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/chosen.aveluneassets',
      accept: (_) async {},
    );
    await controller.beginImport();
    await controller.selectFiltered();
    expect(controller.selectedCount, 10000);
    await controller.setFilter(context: 'interior', familyId: 'forest');
    expect(controller.filter['familyId'], 'forest');
    expect(controller.families.single['label'], 'Forêt');
    await controller.selectFiltered();
    expect(
      (port.inputs.lastWhere((input) => input.containsKey('filter'))['filter']
          as Map)['familyId'],
      'forest',
    );
    expect(controller.selectedCount, 10000);
    expect(controller.visibleCount, 1);
    expect(controller.entries.length, 1);
    final request =
        port.inputs[port.verbs.indexOf('selection.select_filtered')];
    expect(
      request.keys,
      containsAll(['selectionHandle', 'revision', 'filter']),
    );
    expect(request.keys, isNot(contains('add')));
    controller.dispose();
  });

  test('successful commit with failed refresh retries reconciliation without apply', () async {
    final port = PackTestPort();
    var accepts = 0;
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/chosen.aveluneassets',
      accept: (_) async {
        if (++accepts == 1) throw const ResourceFailure('refresh failed');
      },
    );
    await controller.beginImport();
    await controller.selectFiltered();
    await controller.prepare();
    await controller.apply();
    expect(controller.requiresReconciliation, isTrue);
    expect(controller.notice, contains('Import terminé'));
    expect(await controller.requestClose(), isFalse);
    expect(await controller.retryReconciliation(), isTrue);
    expect(port.applies, 1);
    expect(accepts, 2);
    controller.dispose();
  });

  test('late failed job remains blocked until canonical recovery', () async {
    final port = PackTestPort()..lateFailure = true;
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/chosen.aveluneassets',
      accept: (_) async {},
    );
    await controller.beginImport();
    await controller.selectFiltered();
    await controller.prepare();
    await controller.apply();
    expect(controller.requiresRecovery, isTrue);
    expect(await controller.requestClose(), isFalse);
    await controller.recover();
    expect(controller.requiresRecovery, isFalse);
    expect(port.recoveredOperation, port.appliedOperation);
    expect(port.applies, 1);
    controller.dispose();
  });
}

class DelayedQueryPackPort extends PackTestPort {
  final entered = Completer<void>();
  final result = Completer<Map<String, Object?>>();
  @override
  Future<Map<String, Object?>> query(AuthoringQueryRequest request) {
    if (request.filters['context'] == 'exterior') {
      entered.complete();
      return result.future;
    }
    return super.query(request);
  }
}

class StrictClosePackPort extends PackTestPort {
  final entered = Completer<void>(), gate = Completer<void>();
  final live = <String>{};
  final released = <String>[];
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    if (verb == 'selection.create') {
      live.addAll(['selection', 'inspection', 'archive']);
    }
    if (verb == 'release') {
      final handle = input['handle']! as String;
      if (!live.remove(handle)) {
        throw StateError('resource_pack.handle_unknown');
      }
      released.add(handle);
      if (!entered.isCompleted) {
        entered.complete();
        await gate.future;
      }
      return {'released': true};
    }
    return super.transfer(verb, input);
  }
}

class WaitingResourcePort implements ResourcePort {
  final completion = Completer<ResourceMutationReceipt>();
  @override
  Future<ResourceMutationReceipt> mutate(
    String actionId,
    Map<String, Object?> parameters,
  ) => completion.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PackTestPort implements ResourcePackPort {
  final verbs = <String>[];
  final inputs = <Map<String, Object?>>[];
  String? authorized;
  bool invalidInspection = false, lateFailure = false;
  String? appliedOperation, recoveredOperation;
  int selected = 0, applies = 0;
  @override
  String get sessionId => 'test-session';
  @override
  Future<void> authorizeSource(String path) async {
    authorized = path;
  }

  @override
  Future<String> captureRevision() async => 'snapshot-revision';
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    verbs.add(verb);
    inputs.add(input);
    switch (verb) {
      case 'stage':
        return settled({'archiveHandle': 'archive'});
      case 'inspect':
        if (invalidInspection) throw const ResourceFailure('invalid archive');
        return settled({
          'inspectionHandle': 'inspection',
          'fileCount': 2,
          'pack': {
            'name': 'Pack de test',
            'version': '1.0.0',
            'universeId': 'original',
            'provenance': 'Original',
          },
          'archiveBytes': 100,
          'authorCount': 1,
          'sourceCount': 1,
          'requiredCapabilities': ['images.png'],
        });
      case 'entries':
        return {
          'items': input['section'] == 'families'
              ? [
                  {
                    'id': 'forest',
                    'kind': 'resourceFamily',
                    'label': 'Forêt',
                    'labelComplete': true,
                  },
                ]
              : [
                  {'label': 'Auteur original', 'labelComplete': true},
                ],
          'totalAvailable': 1,
        };
      case 'selection.create':
        return summary;
      case 'selection.select_filtered':
        selected = 10000;
        return summary;
      case 'selection.patch':
        selected++;
        return summary;
      case 'prepare':
        return settled({
          'status': 'ready',
          'preparedImportHandle': 'prepared',
          'previewHandle': 'preview',
          'resourceCount': 10001,
          'conflictCount': 0,
          'summary': {
            'selectedResourceCount': selected,
            'selectedPatternCount': 0,
            'resourceCount': 10000,
            'supportCount': 1,
            'definitionCount': 10001,
            'dependencyCount': 1,
            'createdDefinitionCount': 10001,
            'copiedDefinitionCount': 0,
            'reusedDefinitionCount': 0,
            'presentDefinitionCount': 0,
            'blockedDefinitionCount': 0,
            'localModifiedResourceCount': 0,
            'localDeletedResourceCount': 0,
            'sourceBytes': 75,
            'licenseBytes': 5,
            'outputBytes': 150,
            'metadataBytes': 50,
            'writeBytes': 200,
            'newBlobBytes': 75,
          },
        });
      case 'preview':
        return {
          'items': [
            {'kind': 'element', 'id': 'tree', 'targetId': 'native-tree'},
          ],
          'totalAvailable': 10001,
        };
      case 'events':
        return {'events': <Object?>[]};
      case 'recovery_status':
        return {'recoveryRequired': lateFailure};
      case 'start_recovery':
        recoveredOperation = input['operationId'] as String?;
        lateFailure = false;
        return settled({
          'receipt': {'receiptId': 'actual'},
        });
      case 'release':
        return {'released': true};
    }
    throw StateError(verb);
  }

  Map<String, Object?> get summary => {
    'selectionHandle': 'selection',
    'revision': 'selection-$selected',
    'selectedCount': selected,
    'totalAvailable': 10000,
  };
  Map<String, Object?> settled(Map<String, Object?> result) => {
    'snapshot': {'jobId': 'job', 'state': 'succeeded'},
    'phase': 'completed',
    'cancelAllowed': false,
    'result': result,
  };
  @override
  Future<Map<String, Object?>> query(AuthoringQueryRequest request) async => {
    'items': [
      {
        'kind': 'element',
        'id': 'tree',
        'label': 'Arbre',
        'selected': selected > 0,
      },
    ],
    'totalAvailable': request.filters['context'] == 'interior' ? 1 : 10000,
  };
  @override
  Future<List<int>> readExportPayloadChunk(
    String payloadRef,
    int offset,
    int length,
  ) async => const [];
  @override
  Future<ResourceMutationReceipt> applyImport({
    required String preparedHandle,
    required String expectedRevision,
    required String operationId,
    required ResourcePackJobMonitor monitor,
  }) async {
    applies++;
    appliedOperation = operationId;
    if (lateFailure) {
      await monitor({
        'snapshot': {'jobId': 'apply-job', 'state': 'failed'},
        'phase': 'recoveryRequired',
        'cancelAllowed': false,
      });
    }
    return receipt;
  }

  ResourceMutationReceipt get receipt => ResourceMutationReceipt(
    before: workspaceProject,
    manifest: workspaceProject,
    beforeRevision: 'manifest-before',
    revision: 'manifest-after',
    changedPaths: ['project.json'],
    actionId: 'resource_pack.import',
    operationId: 'actual',
  );
  @override
  Future<ResourceMutationReceipt> rereadApplied() async => receipt;
  @override
  Future<void> reconcile(ResourceMutationReceipt receipt) async {}
  @override
  Future<void> dispose() async {}
}

class ExportPackTestPort extends PackTestPort {
  final authorizedPaths = <String>[];
  final released = <String>[];
  Map<String, Object?>? lastExport;
  int preparations = 0, licenses = 0;
  bool failNativeRelease = false;
  @override
  Future<void> authorizeSource(String path) async {
    authorizedPaths.add(path);
  }

  @override
  Future<List<int>> readExportPayloadChunk(
    String payloadRef,
    int offset,
    int length,
  ) async => [1, 2, 3].skip(offset).take(length).toList();
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    if (verb == 'selection.create' && input['mode'] == 'native') {
      verbs.add(verb);
      inputs.add(input);
      return {...summary, 'sourceRevision': 'snapshot-revision'};
    }
    if (verb == 'stage_license') {
      verbs.add(verb);
      inputs.add(input);
      licenses++;
      return settled({
        'licenseHandle': 'license-$licenses',
        'rawSha256': 'document-$licenses',
        'byteLength': 12,
      });
    }
    if (verb == 'prepare' && input.containsKey('metadata')) {
      verbs.add(verb);
      inputs.add(input);
      preparations++;
      return settled({
        'preparedExportHandle': 'native-prepared-$preparations',
        'previewHandle': 'native-preview-$preparations',
        'projectionFingerprint': 'projection-$preparations',
        'requiresOrganizationAcknowledgement': true,
        'resourceCount': 2,
        'summary': {
          'selectedRootCount': selected,
          'resourceCount': 2,
          'supportCount': 0,
          'fileCount': 1,
          'promotionCount': 1,
          'neutralizationCount': 1,
          'sourceCount': 1,
          'globalCreditCount': 1,
          'licenseCount': licenses,
          'publicationNoticeCount': 1,
        },
      });
    }
    if (verb == 'preview' &&
        (input['previewHandle'] as String).startsWith('native-preview')) {
      verbs.add(verb);
      inputs.add(input);
      return {
        'scope': 'preparedNativeClosure',
        'items': input['cursor'] == null
            ? [
                {
                  'kind': 'resource',
                  'resourceKind': 'character',
                  'nativeId': 'hero',
                  'id': 'hero',
                  'label': 'Hero',
                  'selected': true,
                },
              ]
            : [
                {
                  'kind': 'resource',
                  'resourceKind': 'borderBlueprint',
                  'nativeId': 'late',
                  'id': 'late',
                  'label': 'Late border',
                  'selected': true,
                },
              ],
        if (input['cursor'] == null) 'nextCursor': 'later',
      };
    }
    if (verb == 'export') {
      verbs.add(verb);
      inputs.add(input);
      lastExport = Map.of(input);
      return settled({
        'artifactHandle': 'artifact',
        'payloadRef': 'payload',
        'rawSha256': 'hash',
        'byteLength': 3,
      });
    }
    if (verb == 'release') {
      released.add(input['handle']! as String);
      if (failNativeRelease &&
          (input['handle']! as String).startsWith('native-prepared')) {
        failNativeRelease = false;
        throw StateError('cleanup');
      }
      return {'released': true};
    }
    return super.transfer(verb, input);
  }
}

class ExportTestSink implements ResourcePackExportSink {
  @override
  Future<ResourcePackPublication> reconcilePublication(String token) async =>
      throw StateError('No pending publication');
  ExportTestSink({this.wait = false});
  final bool wait;
  final entered = Completer<void>(), gate = Completer<void>();
  List<int> bytes = [];
  @override
  Future<ResourcePackPublication> publish({
    required String suggestedName,
    required int byteLength,
    required String rawSha256,
    required Future<List<int>> Function(int, int) readChunk,
    required bool Function() isCancelled,
    required void Function() enterFinalization,
  }) async {
    entered.complete();
    if (wait) await gate.future;
    if (isCancelled()) return const ResourcePackPublication.cancelled();
    bytes = await readChunk(0, byteLength);
    enterFinalization();
    return const ResourcePackPublication.published('/published.aveluneassets');
  }
}

class LateExportPackPort extends ExportPackTestPort {
  String? lateVerb;
  final entered = Completer<void>(), gate = Completer<void>();
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    final result = await super.transfer(verb, input);
    if (verb == lateVerb) {
      entered.complete();
      await gate.future;
    }
    return result;
  }
}

class LatePreviewExportPort extends ExportPackTestPort {
  bool delay = false;
  final entered = Completer<void>();
  final gate = Completer<Map<String, Object?>>();
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    if (verb == 'preview' && delay) {
      entered.complete();
      return gate.future;
    }
    return super.transfer(verb, input);
  }
}

class PendingExportTestSink extends ExportTestSink {
  int requeries = 0;
  @override
  Future<ResourcePackPublication> publish({
    required String suggestedName,
    required int byteLength,
    required String rawSha256,
    required Future<List<int>> Function(int, int) readChunk,
    required bool Function() isCancelled,
    required void Function() enterFinalization,
  }) async {
    enterFinalization();
    return const ResourcePackPublication.pending('native-pending');
  }

  @override
  Future<ResourcePackPublication> reconcilePublication(String token) async {
    expect(token, 'native-pending');
    requeries++;
    return const ResourcePackPublication.published('/published.aveluneassets');
  }
}
