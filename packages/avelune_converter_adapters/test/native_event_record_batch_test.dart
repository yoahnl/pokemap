import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/native_mutation_batches.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  NativeMutation record(int index) => NativeMutation(
          operationId: ConverterId('record-$index'),
          actionId: 'event_v2.record_upsert',
          sourceEntityIds: [
            ConverterId('source')
          ],
          targetEntityIds: [
            ConverterId('event-$index')
          ],
          parameters: {
            'record': {
              'state': 'draft',
              'draft': {'id': 'event-$index'}
            }
          });
  test(
      'record batches preserve ordered components, logical quotas and exact expansion',
      () async {
    final fixture = await LiteralTileFixture.create();
    final original = List.generate(300, record);
    final grouped = batchNativeMutations(original,
        actionId: 'event_v2.record_upsert',
        limits: const NativeWriteLimits(maxMutations: 512));
    expect(grouped.mutations.length, 3);
    expect(nativeLogicalMutationCount(grouped.mutations), 300);
    expect(
        grouped.mutations.map((m) => (m.parameters['records'] as List).length),
        [128, 128, 44]);
    NativeProjectDraft draft(List<Map<String, Object?>> evidence,
            List<NativeMutation> mutations) =>
        NativeProjectDraft(
            source: fixture.source,
            projectName: 'Batch',
            parentPath: '/tmp',
            folderName: 'batch',
            mapIds: {},
            artifacts: [],
            mutations: mutations,
            compositionEvidence: {
              'sourceEvents': {'mutationBatches': evidence}
            },
            limits: const NativeWriteLimits(maxMutations: 512));
    final expanded = expandNativeMutationBatches(
            draft(grouped.evidence, grouped.mutations),
            const NativeWriteLimits(maxMutations: 512))
        .toList();
    expect([for (final m in expanded) m.toJson(0)],
        [for (final m in original) m.toJson(0)]);
    final repeated = batchNativeMutations(original,
        actionId: 'event_v2.record_upsert',
        limits: const NativeWriteLimits(maxMutations: 512));
    expect([for (final m in repeated.mutations) m.toJson(0)],
        [for (final m in grouped.mutations) m.toJson(0)]);
    expect(repeated.evidence, grouped.evidence);
    final forged = [
      for (final row in grouped.evidence) Map<String, Object?>.from(row)
    ];
    forged[0]['components'] =
        (forged[0]['components'] as List).reversed.toList();
    expect(
        () => expandNativeMutationBatches(draft(forged, grouped.mutations),
                const NativeWriteLimits(maxMutations: 512))
            .toList(),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.batch.binding')));
    expect(
        () => expandNativeMutationBatches(draft([], grouped.mutations),
                const NativeWriteLimits(maxMutations: 512))
            .toList(),
        throwsA(isA<NativeWriteException>()));
    final changed = [...grouped.mutations];
    final m = changed[0];
    changed[0] = NativeMutation(
        operationId: m.operationId,
        actionId: m.actionId,
        sourceEntityIds: m.sourceEntityIds,
        targetEntityIds: [ConverterId('forged')],
        parameters: m.parameters);
    expect(
        () => expandNativeMutationBatches(draft(grouped.evidence, changed),
                const NativeWriteLimits(maxMutations: 512))
            .toList(),
        throwsA(isA<NativeWriteException>()));
    expect(
        () => draft(grouped.evidence, grouped.mutations).validateResourceBudget(
            limits: const NativeWriteLimits(maxMutations: 299)),
        throwsA(isA<NativeWriteException>()));
  });
  test('record batching keeps contiguity and respects source reference limits',
      () {
    final barrier = NativeMutation(
        operationId: ConverterId('barrier'),
        actionId: 'fact.create',
        sourceEntityIds: [ConverterId('source')],
        targetEntityIds: [],
        parameters: {});
    final source = [record(1), barrier, record(2), record(3)];
    final grouped = batchNativeMutations(source,
        actionId: 'event_v2.record_upsert',
        limits: const NativeWriteLimits(maxMutations: 512));
    expect(grouped.mutations.map((m) => m.actionId), [
      'event_v2.record_upsert',
      'fact.create',
      'event_v2.record_upsert_batch'
    ]);
    final bounded = batchNativeMutations(List.generate(3, record),
        actionId: 'event_v2.record_upsert',
        limits: const NativeWriteLimits(maxMutations: 2));
    expect(bounded.mutations.length, 2);
    expect(
        () => batchNativeMutations([record(1), record(1)],
            actionId: 'event_v2.record_upsert',
            limits: const NativeWriteLimits(maxMutations: 512)),
        throwsA(isA<NativeWriteException>()));
  });
  test(
      'record batches split at the byte envelope and preserve effective JSON quotas',
      () {
    NativeMutation large(int index, int size) => NativeMutation(
            operationId: ConverterId('large-$index'),
            actionId: 'event_v2.record_upsert',
            sourceEntityIds: [
              ConverterId('source')
            ],
            targetEntityIds: [
              ConverterId('event-$index')
            ],
            parameters: {
              'record': {
                'state': 'draft',
                'draft': {'id': 'event-$index', 'name': 'x' * size}
              }
            });
    final grouped = batchNativeMutations(
        [for (var i = 0; i < 4; i++) large(i, 400000)],
        actionId: 'event_v2.record_upsert', limits: const NativeWriteLimits());
    expect(grouped.mutations.length, 2);
    expect(nativeLogicalMutationCount(grouped.mutations), 4);
    for (final mutation in grouped.mutations) {
      expect(utf8.encode(canonicalJsonOf(mutation.parameters)).length,
          lessThanOrEqualTo(1048576 - 4096));
    }
    expect(
        () => batchNativeMutations([large(0, 1048576)],
            actionId: 'event_v2.record_upsert',
            limits: const NativeWriteLimits()),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.batch.quota')));
    expect(
        () => batchNativeMutations([large(0, 200)],
            actionId: 'event_v2.record_upsert',
            limits: const NativeWriteLimits(
                jsonLimits: ContractLimits(maxStringCodeUnits: 100))),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.batch.quota')));
    final malformed = NativeMutation(
        operationId: ConverterId('over-bound'),
        actionId: 'event_v2.record_upsert_batch',
        sourceEntityIds: [
          ConverterId('source')
        ],
        targetEntityIds: [],
        parameters: {
          'records': List.generate(129, (i) => {'id': 'event-$i'})
        });
    expect(
        () => nativeLogicalMutationCount([malformed]),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.batch.shape')));
  });
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  test(
      'strict writer rejects changed batch references and ordered provenance before staging',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('ac13-record-batch-');
    addTearDown(() => temporary.delete(recursive: true));
    const limits = NativeWriteLimits(maxArtifacts: 256, maxMutations: 1024);
    final fixture = await LiteralTileFixture.create(
        scriptsBytes: await File(scriptsPath!).readAsBytes(),
        includeEventSystem: true,
        extraFiles: {
          'PBS/metadata.txt':
              utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
          'Graphics/Characters/OriginalPlayer.png': image
              .encodePng(image.Image(width: 128, height: 192, numChannels: 4))
        },
        maps: [
          for (var mapId = 1; mapId <= 9; mapId++)
            LiteralFixtureMap(id: mapId, events: [
              LiteralFixtureEvent(id: 1, x: 0, y: 0, pages: const [
                LiteralFixtureEventPage(
                    characterName: 'MissingActor', commands: [])
              ])
            ])
        ]);
    final literal = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [for (var i = 1; i <= 9; i++) i],
        projectName: 'Batch provenance',
        parentPath: temporary.path,
        folderName: 'batch',
        limits: limits);
    final semantic = (await const SourceSemanticStudyComposer().compose(
        source: fixture.source,
        base: literal,
        files: fixture.files,
        limits: limits))!;
    final draft = (await const SourceEventStudyComposer().compose(
            source: fixture.source,
            base: semantic,
            files: fixture.files,
            limits: limits))!
        .draft;
    final batch = draft.mutations
        .singleWhere((m) => m.actionId == 'event_v2.record_upsert_batch');
    expect((batch.parameters['records'] as List).length, 9);
    final changedBatch = NativeMutation(
        operationId: batch.operationId,
        actionId: batch.actionId,
        sourceEntityIds: batch.sourceEntityIds,
        targetEntityIds: [ConverterId('forged-event')],
        parameters: batch.parameters,
        limits: limits);
    final evidence = Map<String, Object?>.from(draft.compositionEvidence);
    final eventEvidence =
        Map<String, Object?>.from(evidence['sourceEvents'] as Map);
    final rows = (eventEvidence['mutationBatches'] as List).cast<Map>();
    eventEvidence['mutationBatches'] = [
      for (final row in rows)
        {...row, 'components': (row['components'] as List).reversed.toList()}
    ];
    evidence['sourceEvents'] = eventEvidence;
    for (final changed in [
      (
        mutations: [
          for (final m in draft.mutations)
            m.operationId == batch.operationId ? changedBatch : m
        ],
        evidence: draft.compositionEvidence
      ),
      (mutations: draft.mutations, evidence: evidence),
    ]) {
      final forged = NativeProjectDraft(
          source: draft.source,
          projectName: draft.projectName,
          parentPath: draft.parentPath,
          folderName: draft.folderName,
          mapIds: draft.mapIds,
          artifacts: draft.artifacts,
          sourceArtifacts: draft.sourceArtifacts,
          mutations: changed.mutations,
          compositionEvidence: changed.evidence,
          limits: limits);
      final approval = approveNativeFixtureDraft(forged);
      final stages = <NativeWriteStage>[];
      await expectLater(
          NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
              .write(approval.plan, approval.context, forged, limits: limits),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'native.semantics.regeneration')));
      expect(stages, isEmpty);
    }
    expect(await temporary.list().toList(), isEmpty);
  },
      skip: scriptsPath == null || !Platform.isMacOS,
      timeout: const Timeout(Duration(minutes: 2)));
}
