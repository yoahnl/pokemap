import 'dart:async';

import 'package:avelune_studio/features/resources/domain/resource_pack_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:map_authoring/map_authoring_api.dart';

import '../support/map_workspace_fixture.dart';

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
