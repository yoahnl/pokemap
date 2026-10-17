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
