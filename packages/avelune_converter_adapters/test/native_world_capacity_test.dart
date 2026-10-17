import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/native_mutation_batches.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';

void main() {
  late Directory root;
  late NativeWriterFixture fixture;
  const large = NativeWriteLimits(maxMutations: 16384);
  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('native-world-capacity-');
    fixture = await NativeWriterFixture.create(root.path);
  });
  tearDownAll(() => root.delete(recursive: true));

  test(
      'full world settings reserve bounded operations and bytes without changing small studies',
      () {
    expect(large.validate, returnsNormally);
    for (final count in [9, 383, 2048]) {
      final limits = sourceCatalogStudyWriteLimitsFor(count);
      expect(limits.maxMutations, 16384);
      expect(limits.maxTotalDraftJsonBytes, 268435456);
      expect(limits.maxTotalArtifactBytes, 268435456);
      expect(limits.maxArtifacts, 1024);
      expect(limits.maxImagePixels, 16777216);
      expect(limits.maxTotalImagePixels, 33554432);
      expect(limits.validate, returnsNormally);
    }
    expect(const NativeWriteLimits().maxMutations, 256);
    expect(sourceCatalogStudyWriteLimitsFor(1).maxMutations, 1024);
    expect(sourceCatalogStudyWriteLimitsFor(8).maxMutations, 2048);
    expect(
        const NativeWriteLimits(maxMutations: 16385).validate,
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.invalid_limits')));
  });

  NativeMutation mutation(int index,
          {List<ConverterId>? sourceIds,
          List<ConverterId>? targetIds,
          String action = 'map.save'}) =>
      NativeMutation(
          operationId: ConverterId('world-operation-$index'),
          actionId: action,
          sourceEntityIds: sourceIds ?? [ConverterId('source')],
          targetEntityIds: targetIds ?? [ConverterId('element-$index')],
          parameters: action == 'element.upsert'
              ? {
                  'element': {'id': 'element-$index'}
                }
              : {'row': index},
          limits: large);

  test(
      'full world logical operation ceiling is exact and every record remains bound',
      () {
    final records = List.generate(16384, mutation);
    final draft = copyNativeFixtureDraft(fixture.draft,
        mutations: records, limits: large);
    expect(draft.mutations.length, 16384);
    expect(
        copyNativeFixtureDraft(fixture.draft,
                mutations: records.reversed.toList(), limits: large)
            .canonicalHash,
        isNot(draft.canonicalHash));
    expect(
        () => copyNativeFixtureDraft(fixture.draft,
            mutations: [...records, mutation(16384)], limits: large),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.quota.draft')));
  });

  test('batch envelopes still consume the original logical operation count',
      () {
    final records = List.generate(
        2049, (index) => mutation(index, action: 'element.upsert'));
    final grouped = batchNativeMutations(records,
        actionId: 'element.upsert', limits: large);
    expect(grouped.mutations.length, lessThan(records.length));
    expect(nativeLogicalMutationCount(grouped.mutations), 2049);
    expect(
        () => copyNativeFixtureDraft(fixture.draft,
            mutations: grouped.mutations,
            limits: const NativeWriteLimits(maxMutations: 2048)),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.quota.draft')));
    expect(
        copyNativeFixtureDraft(fixture.draft,
                mutations: grouped.mutations, limits: large)
            .mutations,
        grouped.mutations);
  });

  test(
      'larger operation budget keeps map and per-operation reference ceilings at 2048',
      () {
    final refs =
        List.generate(2048, (index) => ConverterId('reference-$index'));
    expect(
        () => mutation(0, sourceIds: refs, targetIds: refs), returnsNormally);
    for (final source in [true, false]) {
      expect(
          () => mutation(1,
              sourceIds: source ? [...refs, ConverterId('extra')] : null,
              targetIds: source ? null : [...refs, ConverterId('extra')]),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'native.quota.references')));
    }
    expect(
        () => copyNativeFixtureDraft(fixture.draft,
            mapIds: {for (var i = 1; i <= 2048; i++) i: 'map-$i'},
            limits: large),
        returnsNormally);
    expect(
        () => copyNativeFixtureDraft(fixture.draft,
            mapIds: {for (var i = 1; i <= 2049; i++) i: 'map-$i'},
            limits: large),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.quota.draft')));
  });

  test('large operation batches retain the original shared reference ceiling',
      () {
    final records = [
      for (var index = 0; index < 3; index++)
        NativeMutation(
            operationId: ConverterId('asset-operation-$index'),
            actionId: 'asset.import',
            sourceEntityIds: [
              for (var row = 0; row < 1024; row++)
                ConverterId('source-${index * 1024 + row}')
            ],
            targetEntityIds: [ConverterId('asset-$index')],
            parameters: {
              'assetId': 'asset-$index',
              'logicalPath': 'assets/$index.png',
              'artifactHandle': 'artifact-$index'
            },
            limits: large)
    ];
    final grouped =
        batchNativeMutations(records, actionId: 'asset.import', limits: large);
    expect(grouped.mutations, hasLength(2));
    expect(nativeLogicalMutationCount(grouped.mutations), 3);
    expect(
        grouped.mutations
            .every((record) => record.sourceEntityIds.length <= 2048),
        isTrue);
  });

  test(
      'world workflow settings retain exact serialized limits and reject excess maps',
      () {
    ConverterStudySettings settings(int maps) => ConverterStudySettings(
        projectName: 'World capacity',
        parentPath: '/private/tmp/world-capacity',
        folderName: 'world',
        selectedSourceMapIds: [
          for (var index = 1; index <= maps; index++) index
        ],
        profileAcknowledgement: SourceStudyAcknowledgement(
            sourceSnapshotHash: Sha256Hash('0' * 64),
            profileEvidenceHash: Sha256Hash('1' * 64),
            humanConfirmed: true,
            reason: 'Bounded whole-world conversion capacity'));
    final world = settings(383);
    final json = world.toJson();
    expect((json['writeLimits'] as Map)['maxMutations'], 16384);
    expect((json['writeLimits'] as Map)['maxTotalDraftJsonBytes'], 268435456);
    expect(world.canonicalHash, settings(383).canonicalHash);
    expect(
        () => settings(2049),
        throwsA(isA<ConverterWorkflowFailure>().having(
            (error) => error.code, 'code', 'workflow.quota.selection')));
  });

  test(
      'effective smaller writer budget rejects before staging a large approved draft',
      () async {
    final draft = copyNativeFixtureDraft(fixture.draft,
        mutations: List.generate(2049, mutation), limits: large);
    final approval = approveNativeFixtureDraft(draft);
    var staged = false;
    final writer = NativeProjectWriter(stagingFactory: () async {
      staged = true;
      throw StateError('Quota must refuse before staging');
    });
    await expectLater(
        writer.write(approval.plan, approval.context, draft,
            limits: const NativeWriteLimits(maxMutations: 2048)),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.quota.draft')));
    expect(staged, isFalse);
  });
}
