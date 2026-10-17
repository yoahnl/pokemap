import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/native_mutation_batches.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';

const _limits = NativeWriteLimits(maxMutations: 2048);

NativeMutation _element(int index,
        {String owner = 'owner',
        String category = 'category',
        String name = 'Element'}) =>
    NativeMutation(
        operationId: ConverterId('element-$index'),
        actionId: 'element.upsert',
        sourceEntityIds: [ConverterId(owner)],
        targetEntityIds: [ConverterId('target-$index')],
        parameters: {
          'element': {
            'id': 'target-$index',
            'categoryId': category,
            'tilesetId': 'atlas',
            'name': name
          }
        },
        limits: _limits);

NativeMutation _asset(int index,
        {String? path, String? owner, String handle = 'artifact'}) =>
    NativeMutation(
        operationId: ConverterId('asset-$index'),
        actionId: 'asset.import',
        sourceEntityIds: [ConverterId(owner ?? 'owner-$index')],
        targetEntityIds: [ConverterId('target-$index')],
        parameters: {
          'artifactHandle': handle,
          'assetId': 'target-$index',
          'logicalPath': path ?? 'assets/$index.json',
          'tags': ['original'],
          'usages': ['provenance']
        },
        limits: _limits);

void main() {
  for (final count in [1, 200, 201]) {
    test('asset grouping preserves $count ordered complete components', () {
      final originals = List.generate(count, _asset);
      final grouped = batchNativeMutations(originals,
          actionId: 'asset.import', limits: _limits);
      expect(grouped.mutations.length, count == 201 ? 2 : 1);
      expect(nativeLogicalMutationCount(grouped.mutations), count);
      if (count == 1) {
        expect(grouped.evidence, isEmpty);
        expect(grouped.mutations.single.toJson(0), originals.single.toJson(0));
      } else {
        expect(
            grouped.mutations.first.parameters['entries'],
            originals
                .take(200)
                .map((mutation) => mutation.parameters)
                .toList());
        expect(
            grouped.evidence.single['components'],
            originals
                .take(200)
                .indexed
                .map((entry) => entry.$2.toJson(entry.$1))
                .toList());
      }
      expect(
          batchNativeMutations(originals,
                  actionId: 'asset.import', limits: _limits)
              .mutations
              .map((mutation) => mutation.toJson(0)),
          grouped.mutations.map((mutation) => mutation.toJson(0)));
    });
  }

  for (final count in [512, 513]) {
    test('element grouping retains canonical boundary $count', () {
      final originals = List.generate(count, _element);
      final grouped = batchNativeMutations(originals,
          actionId: 'element.upsert', limits: _limits);
      expect(grouped.mutations.length, count == 512 ? 1 : 2);
      expect(
          (grouped.mutations.first.parameters['elements'] as List).length, 512);
      expect(nativeLogicalMutationCount(grouped.mutations), count);
      expect(
          grouped.evidence.single['components'],
          originals
              .take(512)
              .indexed
              .map((entry) => entry.$2.toJson(entry.$1))
              .toList());
    });
  }

  test('element groups stop at provenance category and dependency boundaries',
      () {
    final divider = NativeMutation(
        operationId: ConverterId('category'),
        actionId: 'element_category.upsert',
        sourceEntityIds: [
          ConverterId('owner')
        ],
        targetEntityIds: [
          ConverterId('category')
        ],
        parameters: {
          'category': {'id': 'category'}
        });
    final originals = [
      _element(0),
      _element(1),
      _element(2, owner: 'other'),
      _element(3, category: 'other'),
      divider,
      _element(4),
      _element(5)
    ];
    final grouped = batchNativeMutations(originals,
        actionId: 'element.upsert', limits: _limits);
    expect(grouped.mutations.map((mutation) => mutation.actionId), [
      'element.batch_upsert',
      'element.upsert',
      'element.upsert',
      'element_category.upsert',
      'element.batch_upsert'
    ]);
    expect(
        grouped.evidence.map((row) => (row['components'] as List)
            .map((component) => component['ordinal'])
            .toList()),
        [
          [0, 1],
          [5, 6]
        ]);
  });

  test('batch partition respects owner and target reference budgets', () {
    final originals = List.generate(4, _asset);
    final grouped = batchNativeMutations(originals,
        actionId: 'asset.import',
        limits: const NativeWriteLimits(maxMutations: 2));
    expect(grouped.mutations, hasLength(2));
    expect(grouped.mutations.map((mutation) => mutation.sourceEntityIds.length),
        [2, 2]);
    expect(grouped.mutations.map((mutation) => mutation.targetEntityIds.length),
        [2, 2]);
  });

  test('batch partition respects the canonical request byte budget', () {
    final originals =
        List.generate(3, (index) => _element(index, name: 'x' * 400000));
    final grouped = batchNativeMutations(originals,
        actionId: 'element.upsert', limits: _limits);
    expect(grouped.mutations, hasLength(2));
    for (final mutation in grouped.mutations) {
      expect(utf8.encode(canonicalJsonOf(mutation.parameters)).length,
          lessThan(1048576 - 4096));
    }
    expect(nativeLogicalMutationCount(grouped.mutations), 3);
  });

  for (final duplicate in ['identity', 'path']) {
    test('duplicate $duplicate is refused during batch composition', () {
      final originals = [
        _asset(0),
        duplicate == 'identity' ? _asset(0) : _asset(1, path: 'assets/0.json')
      ];
      expect(
          () => batchNativeMutations(originals,
              actionId: 'asset.import', limits: _limits),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.batch.duplicate')));
    });
  }

  test(
      'canonical batches match single operations after real writes and cold reopen',
      () async {
    final root =
        await Directory.systemTemp.createTemp('native-batch-equivalence-');
    try {
      final fixture = await NativeWriterFixture.create(root.path);
      final receipts = <NativeWriteReceipt>[];
      for (final name in ['singles', 'batches']) {
        final draft = copyNativeFixtureDraft(fixture.draft, folderName: name);
        final approval = approveNativeFixtureDraft(draft);
        receipts.add(await const NativeProjectWriter()
            .write(approval.plan, approval.context, draft));
      }
      final atlas = fixture.draft.mutations
          .singleWhere(
              (mutation) => mutation.actionId == 'tileset.import_image')
          .parameters['tilesetId'] as String;
      final owner = fixture.draft.mutations.first.sourceEntityIds;
      final elements = [
        for (var index = 0; index < 3; index++)
          NativeMutation(
              operationId: ConverterId('native-element-$index'),
              actionId: 'element.upsert',
              sourceEntityIds: owner,
              targetEntityIds: [
                ConverterId('native-element-$index')
              ],
              parameters: {
                'element': ProjectElementEntry(
                    id: 'native-element-$index',
                    name: 'Original $index',
                    categoryId: 'native-category',
                    tilesetId: atlas,
                    frames: [
                      TilesetVisualFrame(
                          tilesetId: atlas,
                          source: TilesetSourceRect(
                              x: index % 2, y: 0, width: 1, height: 1))
                    ]).toJson()
              })
      ];
      final artifact = NativeArtifact(
          bytes: utf8.encode(
              canonicalJsonOf({'kind': 'original-native-batch-fixture'})),
          mediaType: 'application/json');
      final imports =
          List.generate(3, (index) => _asset(index, handle: artifact.handle));
      for (var index = 0; index < receipts.length; index++) {
        final session = await _MutationSession.open(receipts[index]);
        try {
          final stored = await session.api.artifacts.put(artifact.bytes,
              declaredMediaType: artifact.reference.mediaType);
          expect(stored.reference, artifact.reference);
          await session.apply(NativeMutation(
              operationId: ConverterId('native-category'),
              actionId: 'element_category.upsert',
              sourceEntityIds: owner,
              targetEntityIds: [
                ConverterId('native-category')
              ],
              parameters: {
                'category': const ProjectElementCategory(
                        id: 'native-category', name: 'Original')
                    .toJson()
              }));
          for (final mutation in index == 0
              ? elements
              : batchNativeMutations(elements,
                      actionId: 'element.upsert', limits: _limits)
                  .mutations) {
            await session.apply(mutation);
          }
          for (final mutation in index == 0
              ? imports
              : batchNativeMutations(imports,
                      actionId: 'asset.import', limits: _limits)
                  .mutations) {
            await session.apply(mutation);
          }
          final before = await session.load();
          final invalid = NativeMutation(
              operationId: ConverterId('duplicate-import'),
              actionId: 'asset.import_batch',
              sourceEntityIds: owner,
              targetEntityIds: [
                ConverterId('duplicate')
              ],
              parameters: {
                'entries': [
                  _asset(8, handle: artifact.handle).parameters,
                  _asset(9, path: 'assets/8.json', handle: artifact.handle)
                      .parameters
                ]
              });
          await expectLater(session.apply(invalid), throwsA(anything));
          expect((await session.load()).revision, before.revision);
          expect(
              await File('${receipts[index].projectPath}/assets/8.json')
                  .exists(),
              isFalse);
        } finally {
          await session.close();
        }
      }
      final first = await _MutationSession.open(receipts.first);
      final second = await _MutationSession.open(receipts.last);
      try {
        final a = await first.load();
        final b = await second.load();
        expect(a.loadDiagnostics, isEmpty);
        expect(b.loadDiagnostics, isEmpty);
        expect(b.manifest.toJson(), a.manifest.toJson());
        expect(b.maps.map((map) => map.toJson()),
            a.maps.map((map) => map.toJson()));
        expect(b.resourceFingerprints, a.resourceFingerprints);
        final catalog = AssetCatalog.fromJson(Map<String, dynamic>.from(
            jsonDecode(
                    utf8.decode(a.resourceBytes(assetCatalogResourceIdentity)))
                as Map));
        for (final record in catalog.records) {
          expect(
              await File('${receipts.last.projectPath}/${record.logicalPath}')
                  .readAsBytes(),
              await File('${receipts.first.projectPath}/${record.logicalPath}')
                  .readAsBytes());
          expect(
              await second.snapshots.readRetainedAssetBlob(
                  second.opened.projectHandle, record.artifact),
              await first.snapshots.readRetainedAssetBlob(
                  first.opened.projectHandle, record.artifact));
        }
      } finally {
        await first.close();
        await second.close();
      }
    } finally {
      await root.delete(recursive: true);
    }
  });

  test(
      'canonical API enforces 200 import and 512 element boundaries atomically',
      () async {
    final root =
        await Directory.systemTemp.createTemp('native-batch-api-limits-');
    try {
      final fixture = await NativeWriterFixture.create(root.path);
      final receipt = await const NativeProjectWriter()
          .write(fixture.plan, fixture.context, fixture.draft);
      final session = await _MutationSession.open(receipt);
      try {
        final owner = fixture.draft.mutations.first.sourceEntityIds;
        final atlas = fixture.draft.mutations
            .singleWhere(
                (mutation) => mutation.actionId == 'tileset.import_image')
            .parameters['tilesetId'] as String;
        await session.apply(NativeMutation(
            operationId: ConverterId('api-category'),
            actionId: 'element_category.upsert',
            sourceEntityIds: owner,
            targetEntityIds: [
              ConverterId('api-category')
            ],
            parameters: {
              'category': const ProjectElementCategory(
                      id: 'api-category', name: 'API boundary')
                  .toJson()
            }));
        final elements = [
          for (var index = 0; index < 513; index++)
            ProjectElementEntry(
                id: 'api-element-$index',
                name: 'Original $index',
                categoryId: 'api-category',
                tilesetId: atlas,
                frames: [
                  TilesetVisualFrame(
                      tilesetId: atlas,
                      source: const TilesetSourceRect(
                          x: 0, y: 0, width: 1, height: 1))
                ]).toJson()
        ];
        await session.apply(NativeMutation(
            operationId: ConverterId('api-elements-512'),
            actionId: 'element.batch_upsert',
            sourceEntityIds: owner,
            targetEntityIds: [ConverterId('api-elements')],
            parameters: {'elements': elements.take(512).toList()}));
        expect((await session.load()).manifest.elements, hasLength(512));
        final artifact = NativeArtifact(
            bytes: utf8.encode(canonicalJsonOf({'kind': 'native-boundary'})),
            mediaType: 'application/json');
        await session.api.artifacts.put(artifact.bytes,
            declaredMediaType: artifact.reference.mediaType);
        final entries = List.generate(
            201, (index) => _asset(index, handle: artifact.handle).parameters);
        await session.apply(NativeMutation(
            operationId: ConverterId('api-assets-200'),
            actionId: 'asset.import_batch',
            sourceEntityIds: owner,
            targetEntityIds: [ConverterId('api-assets')],
            parameters: {'entries': entries.take(200).toList()}));
        final before = await session.load();
        final catalog = AssetCatalog.fromJson(Map<String, dynamic>.from(
            jsonDecode(utf8.decode(
                before.resourceBytes(assetCatalogResourceIdentity))) as Map));
        expect(
            catalog.records
                .where((record) => record.usages.contains('provenance')),
            hasLength(200));
        for (final action in ['asset.import_batch', 'element.batch_upsert']) {
          final request = AuthoringRequest(
              requestId: 'over-$action',
              actionId: action,
              actionVersion: 1,
              workspaceHandle: session.opened.workspaceHandle.value,
              expectedRevision: before.revision,
              idempotencyKey: 'over-$action',
              parameters: action == 'asset.import_batch'
                  ? {'entries': entries}
                  : {'elements': elements});
          await expectLater(
              session.api.planMutation(session.opened.projectHandle, request),
              throwsA(isA<Exception>()));
          expect((await session.load()).revision, before.revision);
        }
      } finally {
        await session.close();
      }
    } finally {
      await root.delete(recursive: true);
    }
  });

  test('batch preflight charges every logical copy of a shared image',
      () async {
    final root = await Directory.systemTemp.createTemp('native-batch-budget-');
    try {
      final fixture = await NativeWriterFixture.create(root.path);
      final original = fixture.draft;
      final imports = List.generate(2,
          (index) => _asset(index, handle: original.artifacts.single.handle));
      final grouped = batchNativeMutations(imports,
          actionId: 'asset.import', limits: _limits);
      final draft =
          copyNativeFixtureDraft(original, mutations: grouped.mutations);
      expect(
          () => draft.validateResourceBudget(
              limits: NativeWriteLimits(
                  maxTotalArtifactBytes:
                      original.artifacts.single.bytes.length * 2 - 1)),
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'native.quota.artifact')));
      expect(
          () => draft.validateResourceBudget(
              limits: const NativeWriteLimits(maxTotalImagePixels: 4095)),
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'native.quota.image')));
      draft.validateResourceBudget(
          limits: NativeWriteLimits(
              maxTotalArtifactBytes: original.artifacts.single.bytes.length * 2,
              maxTotalImagePixels: 4096));
    } finally {
      await root.delete(recursive: true);
    }
  });
}

final class _MutationSession {
  _MutationSession(this.opener, this.opened, this.snapshots, this.api);
  final ProjectOpenService opener;
  final OpenedProject opened;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi api;

  static Future<_MutationSession> open(NativeWriteReceipt receipt) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    final api =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    await api.attachProject(
        projectRootPath: receipt.projectPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _MutationSession(opener, opened, snapshots, api);
  }

  Future<ProjectSnapshot> load() => snapshots.load(opened.projectHandle,
      policy: ProjectSnapshotLoadPolicy.strict);

  Future<void> apply(NativeMutation mutation) async {
    final before = await load();
    final request = AuthoringRequest(
        requestId: mutation.operationId.value,
        actionId: mutation.actionId,
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: before.revision,
        idempotencyKey: mutation.operationId.value,
        parameters: mutation.parameters);
    expect(utf8.encode(canonicalAuthoringJson(request.toJson())).length,
        lessThanOrEqualTo(1048576));
    final planned = await api.planMutation(opened.projectHandle, request);
    expect(planned.applicable, isTrue, reason: planned.nonApplicableReason);
    expect(planned.snapshotRevision, before.revision);
    expect(planned.plan.changeSet.changes.length, lessThanOrEqualTo(500));
    final applied = await api.applyMutation(opened.projectHandle,
        planId: planned.planId, operationId: mutation.operationId.value);
    expect(applied.receipt.status, AuthoringReceiptStatus.applied);
    expect(
        applied.receipt.beforeRevision, isNot(applied.receipt.afterRevision));
    expect(applied.snapshotRevision, (await load()).revision);
  }

  Future<void> close() async {
    await api.detachWorkspace(opened.workspaceHandle);
    opener.closeWorkspace(opened.workspaceHandle);
  }
}
