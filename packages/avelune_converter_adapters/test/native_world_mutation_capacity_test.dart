import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/native_mutation_batches.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';

void main() {
  late Directory root;
  late NativeWriterFixture fixture;
  const capacity = NativeWriteLimits(maxMutations: 32768);

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('world-mutation-capacity-');
    fixture = await NativeWriterFixture.create(root.path);
  });
  tearDownAll(() => root.delete(recursive: true));

  TypeMatcher<NativeWriteException> failure(String code) =>
      isA<NativeWriteException>().having((error) => error.code, 'code', code);

  Matcher draftFailure(int logical, int limit, int envelopes,
          {int maps = 383}) =>
      failure('native.quota.draft').having(
          (error) => error.message,
          'message',
          'Draft map or mutation budget exceeded: inferredStage=sourceCatalogs, '
              'maps=$maps/2048, logicalMutations=$logical/$limit, '
              'mutationEnvelopes=$envelopes');

  NativeMutation record(int index,
          {List<ConverterId>? sources, List<ConverterId>? targets}) =>
      NativeMutation(
          operationId: ConverterId('world-record-$index'),
          actionId: 'element.upsert',
          sourceEntityIds: sources ?? [fixture.source.mapIdentity(1)],
          targetEntityIds: targets ?? [ConverterId('world-element-$index')],
          parameters: {
            'element': {'id': 'world-element-$index'}
          },
          limits: sourceCatalogStudyWriteLimitsFor(383));

  NativeMutation batch(int start, int count) => NativeMutation(
      operationId: ConverterId('world-batch-$start'),
      actionId: 'element.batch_upsert',
      sourceEntityIds: [fixture.source.mapIdentity(1)],
      targetEntityIds: [
        for (var i = start; i < start + count; i++)
          ConverterId('world-element-$i')
      ],
      parameters: {
        'elements': [
          for (var i = start; i < start + count; i++) {'id': 'world-element-$i'}
        ]
      },
      limits: sourceCatalogStudyWriteLimitsFor(383));

  List<NativeMutation> boundedBatches(int count) => [
        for (var start = 0; start < count; start += 512)
          batch(start, (count - start).clamp(1, 512))
      ];

  NativeProjectDraft draft(List<NativeMutation> records,
          {NativeWriteLimits? limits, int maps = 383}) =>
      copyNativeFixtureDraft(fixture.draft,
          mapIds: {for (var i = 1; i <= maps; i++) i: 'world-map-$i'},
          mutations: records,
          compositionEvidence: {'sourceCatalogs': <String, Object?>{}},
          limits: limits ?? sourceCatalogStudyWriteLimitsFor(383));

  test('global logical mutation capacity accepts 32768 and rejects 32769', () {
    expect(capacity.validate, returnsNormally);
    expect(const NativeWriteLimits(maxMutations: 32769).validate,
        throwsA(failure('native.invalid_limits')));
    expect(
        const NativeWriteLimits(maxMutations: 16384).validate, returnsNormally);
  });

  test('world selection and native catalog policy use the bounded world tier',
      () {
    for (final maps in [9, 383, 2048]) {
      final limits = sourceCatalogStudyWriteLimitsFor(maps);
      expect(limits.maxMutations, 32768);
      expect(limits.validate, returnsNormally);
    }
    for (final maps in [0, 1, 2, 8, 9, 383]) {
      expect(
          sourceCatalogStudyWriteLimitsFor(maps, includeNativeCatalog: true)
              .maxMutations,
          32768);
    }
  });

  test('default and small study logical mutation tiers remain unchanged', () {
    expect(const NativeWriteLimits().maxMutations, 256);
    expect(sourceCatalogStudyWriteLimits.maxMutations, 1024);
    for (final maps in [0, 1]) {
      expect(sourceCatalogStudyWriteLimitsFor(maps).maxMutations, 1024);
    }
    for (var maps = 2; maps <= 8; maps++) {
      expect(sourceCatalogStudyWriteLimitsFor(maps).maxMutations, 2048);
    }
  });

  test(
      'synthetic measured size admits 18344 logical mutations in 12394 envelopes',
      () {
    final records = [
      for (var i = 0; i < 11; i++) batch(i * 512, 512),
      batch(5632, 330),
      for (var i = 5962; i < 18344; i++) record(i),
    ];
    expect(records, hasLength(12394));
    expect(nativeLogicalMutationCount(records), 18344);
    final accepted = draft(records);
    expect(accepted.mutations, hasLength(12394));
    expect(
        () => draft(records,
            limits: const NativeWriteLimits(maxMutations: 16384)),
        throwsA(draftFailure(18344, 16384, 12394)));
    expect(
        () => accepted.validateResourceBudget(
            limits: const NativeWriteLimits(maxMutations: 16384)),
        throwsA(draftFailure(18344, 16384, 12394)));
  });

  test('world draft accepts exactly 32768 logical entries in bounded batches',
      () {
    final records = boundedBatches(32768);
    expect(records, hasLength(64));
    expect(nativeLogicalMutationCount(records), 32768);
    expect(records.every((row) => row.targetEntityIds.length <= 512), isTrue);
    expect(draft(records).mutations, hasLength(64));
    expect(
        () => draft(records,
            limits: const NativeWriteLimits(maxMutations: 16384)),
        throwsA(draftFailure(32768, 16384, 64)));
  });

  test('world draft rejects 32769 logical entries with the exact diagnostic',
      () {
    final records = boundedBatches(32769);
    expect(records, hasLength(65));
    expect(nativeLogicalMutationCount(records), 32769);
    expect(() => draft(records), throwsA(draftFailure(32769, 32768, 65)));
  });

  test('batch shape still refuses more than 512 element entries', () {
    expect(
        () => draft([batch(0, 513)]), throwsA(failure('native.batch.shape')));
  });

  test('world map and source or target reference ceilings remain 2048', () {
    final limits = sourceCatalogStudyWriteLimitsFor(383);
    expect(limits.maxMaps, 2048);
    expect(limits.maxEntityReferences, 2048);
    final references = [
      for (var i = 0; i < 2048; i++) ConverterId('world-reference-$i')
    ];
    expect(() => record(0, sources: references, targets: references),
        returnsNormally);
    for (final sources in [true, false]) {
      final excess = [...references, ConverterId('world-reference-extra')];
      expect(
          () => record(0,
              sources: sources ? excess : null,
              targets: sources ? null : excess),
          throwsA(failure('native.quota.references')));
    }
    expect(() => draft([record(0)], maps: 2048), returnsNormally);
    expect(() => draft([record(0)], maps: 2049),
        throwsA(draftFailure(1, 32768, 1, maps: 2049)));
  });

  test(
      'world artifact image JSON byte and map budgets keep their exact ceilings',
      () {
    final limits = sourceCatalogStudyWriteLimitsFor(383);
    expect([
      limits.maxArtifacts,
      limits.maxArtifactBytes,
      limits.maxTotalArtifactBytes,
      limits.maxTotalDraftJsonBytes,
      limits.maxImagePixels,
      limits.maxTotalImagePixels,
      limits.maxMapCells,
      limits.jsonLimits.maxDepth,
      limits.jsonLimits.maxNodes,
      limits.jsonLimits.maxStringCodeUnits,
      limits.jsonLimits.maxTextCodeUnits,
    ], [
      4096,
      67108864,
      268435456,
      268435456,
      16777216,
      134217728,
      4194304,
      64,
      4000000,
      1048576,
      16777216,
    ]);
    for (final excessive in [
      const NativeWriteLimits(maxArtifacts: 4097),
      const NativeWriteLimits(maxArtifactBytes: 67108865),
      const NativeWriteLimits(maxTotalArtifactBytes: 536870913),
      const NativeWriteLimits(maxTotalDraftJsonBytes: 268435457),
      const NativeWriteLimits(maxImagePixels: 16777217),
      const NativeWriteLimits(maxTotalImagePixels: 134217729),
      const NativeWriteLimits(maxMapCells: 4194305),
      const NativeWriteLimits(jsonLimits: ContractLimits(maxDepth: 65)),
      const NativeWriteLimits(jsonLimits: ContractLimits(maxNodes: 4000001)),
      const NativeWriteLimits(
          jsonLimits: ContractLimits(maxStringCodeUnits: 1048577)),
      const NativeWriteLimits(
          jsonLimits: ContractLimits(maxTextCodeUnits: 16777217)),
    ]) {
      expect(excessive.validate, throwsA(failure('native.invalid_limits')));
    }
  });
}
