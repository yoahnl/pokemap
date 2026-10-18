import 'dart:convert';
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

  NativeProjectDraft artifactDraft(int nativeCount, int sourceCount,
      {NativeWriteLimits? limits}) {
    final blobs = List.generate(nativeCount + sourceCount,
        (index) => NativeArtifact(bytes: utf8.encode('{"id":$index}'),
            mediaType: 'application/json'));
    return NativeProjectDraft(
        source: fixture.source,
        projectName: fixture.draft.projectName,
        parentPath: fixture.draft.parentPath,
        folderName: fixture.draft.folderName,
        sourceRootPath: fixture.draft.sourceRootPath,
        mapIds: fixture.draft.mapIds,
        artifacts: blobs.take(nativeCount).toList(),
        sourceArtifacts: blobs.skip(nativeCount).toList(),
        mutations: fixture.draft.mutations,
        limits: limits ?? sourceCatalogStudyWriteLimitsFor(383));
  }

  test('world artifact ceiling counts every native and source entry exactly',
      () {
    for (final split in [(4096, 0), (0, 4096), (2048, 2048), (593, 596)]) {
      final draft = artifactDraft(split.$1, split.$2);
      expect(draft.artifacts.length, split.$1);
      expect(draft.sourceArtifacts.length, split.$2);
    }
    for (final split in [(4097, 0), (0, 4097), (2048, 2049)]) {
      expect(
          () => artifactDraft(split.$1, split.$2),
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'native.quota.draft')));
    }
    expect(
        () => artifactDraft(593, 596,
            limits: const NativeWriteLimits(maxArtifacts: 1024)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.quota.draft')));
  });

  test('larger artifact count retains the aggregate byte budget', () {
    expect(
        () => artifactDraft(593, 596,
            limits: const NativeWriteLimits(
                maxArtifacts: 2048, maxTotalArtifactBytes: 3566)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.quota.artifact')));
  });

  test('draft plan counts union handles separately from source witnesses', () {
    final output = NativeArtifact(bytes: [1]);
    final witness = NativeArtifact(bytes: [2]);
    final draft = NativeProjectDraft(
        source: fixture.source,
        projectName: fixture.draft.projectName,
        parentPath: fixture.draft.parentPath,
        folderName: fixture.draft.folderName,
        mapIds: fixture.draft.mapIds,
        artifacts: [output],
        sourceArtifacts: [output, witness],
        mutations: fixture.draft.mutations);
    expect(draft.uniqueArtifactCount, 2);
    expect(draft.sourceArtifacts.length, 2);
  });

  test('smaller artifact writer budget rejects before staging', () async {
    final draft = artifactDraft(593, 596);
    final approval = approveNativeFixtureDraft(draft);
    var staged = false;
    final writer = NativeProjectWriter(stagingFactory: () async {
      staged = true;
      throw StateError('Quota must refuse before staging');
    });
    await expectLater(
        writer.write(approval.plan, approval.context, draft,
            limits: const NativeWriteLimits(maxArtifacts: 1024)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.quota.draft')));
    expect(staged, isFalse);
  });

  test(
      'full world settings reserve bounded operations and bytes without changing small studies',
      () {
    expect(large.validate, returnsNormally);
    for (final count in [9, 383, 2048]) {
      final limits = sourceCatalogStudyWriteLimitsFor(count);
      expect(limits.maxMutations, 32768);
      expect(limits.maxTotalDraftJsonBytes, 268435456);
      expect(limits.maxTotalArtifactBytes, 268435456);
      expect(limits.maxArtifacts, 4096);
      expect(limits.maxImagePixels, 16777216);
      expect(limits.maxTotalImagePixels, 41943040);
      expect(limits.validate, returnsNormally);
    }
    expect(const NativeWriteLimits().maxMutations, 256);
    expect(sourceCatalogStudyWriteLimitsFor(1).maxMutations, 1024);
    expect(sourceCatalogStudyWriteLimitsFor(8).maxMutations, 2048);
    expect(sourceCatalogStudyWriteLimitsFor(1).maxArtifacts, 512);
    for (var count = 2; count <= 8; count++) {
      expect(sourceCatalogStudyWriteLimitsFor(count).maxArtifacts, 1024);
    }
    expect(
        const NativeWriteLimits(maxMutations: 32769).validate,
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.invalid_limits')));
  });

  test('world image hard ceiling is exact and small studies keep their budget',
      () {
    expect(const NativeWriteLimits().maxTotalImagePixels, 16777216);
    for (final count in [1, 2, 8]) {
      expect(sourceCatalogStudyWriteLimitsFor(count).maxTotalImagePixels,
          33554432);
    }
    expect(
        sourceCatalogStudyWriteLimitsFor(1, includeNativeCatalog: true)
            .maxTotalImagePixels,
        41943040);
    expect(const NativeWriteLimits(maxTotalImagePixels: 41943040).validate,
        returnsNormally);
    for (final total in [0, -1, 41943041]) {
      expect(
          NativeWriteLimits(maxTotalImagePixels: total).validate,
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'native.invalid_limits')));
    }
  });

  test('plan budget inherits custom record limits unless explicitly selected',
      () {
    const custom = ContractLimits(
        maxDepth: 7,
        maxNodes: 100,
        maxStringCodeUnits: 40,
        maxTextCodeUnits: 400);
    const limits = NativeWriteLimits(jsonLimits: custom);
    expect(identical(limits.planJsonLimits, custom), isTrue);
    expect(
        () => canonicalJsonOf({'value': 'x' * 400},
            limits: limits.planJsonLimits),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'json.textQuota')));
    expect(
        identical(const NativeWriteLimits().planJsonLimits,
            const NativeWriteLimits().jsonLimits),
        isTrue);
    for (final count in [1, 2, 8]) {
      final small = sourceCatalogStudyWriteLimitsFor(count);
      expect(identical(small.planJsonLimits, small.jsonLimits), isTrue);
    }
    final world = sourceCatalogStudyWriteLimitsFor(383);
    expect(world.planJsonLimits.maxTextCodeUnits, 25165824);
    expect(world.jsonLimits.maxTextCodeUnits, 16777216);
    expect(world.maxImagePixels, 16777216);
    expect(world.maxTotalDraftJsonBytes, 268435456);
    expect(world.maxTotalArtifactBytes, 268435456);
    for (final contract in [
      const ContractLimits(maxTextCodeUnits: 0),
      const ContractLimits(maxTextCodeUnits: -1),
      const ContractLimits(maxTextCodeUnits: 25165825),
      const ContractLimits(maxDepth: 0),
      const ContractLimits(maxDepth: 65),
      const ContractLimits(maxNodes: 0),
      const ContractLimits(maxNodes: 4000001),
      const ContractLimits(maxStringCodeUnits: 0),
      const ContractLimits(maxStringCodeUnits: 1048577),
    ]) {
      expect(
          NativeWriteLimits(planJsonLimits: contract).validate,
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'native.invalid_limits')));
    }
    expect(
        const NativeWriteLimits(
                jsonLimits: ContractLimits(maxTextCodeUnits: 16777217))
            .validate,
        throwsA(isA<NativeWriteException>()));
  });

  int jsonTextSize(Object? value) => value is String
      ? value.length
      : value is Map
          ? value.entries.fold(
              0,
              (size, entry) =>
                  size + jsonTextSize(entry.key) + jsonTextSize(entry.value))
          : value is List
              ? value.fold(0, (size, entry) => size + jsonTextSize(entry))
              : 0;

  Map<String, Object?> aggregatePlan(int operationCount,
      {required bool ready}) {
    final seed = approveNativeFixtureDraft(fixture.draft).plan.toJson();
    final operation = (seed['operations'] as List).first as Map;
    final refs = [
      for (var index = 0; index < 32; index++)
        'original-reference-$index-${'x' * 1000}'
    ];
    return {
      ...seed,
      'state': ready ? 'ready' : 'draft',
      'approvedByHuman': ready,
      'operations': [
        for (var index = 0; index < operationCount; index++)
          {
            ...operation,
            'operationId': 'aggregate-operation-$index',
            'evidenceRefs': refs
          }
      ],
    };
  }

  for (final ready in [false, true]) {
    test('aggregate plan admits 19Mi and refuses over 24Mi ready=$ready', () {
      final world = sourceCatalogStudyWriteLimitsFor(383);
      final input = aggregatePlan(600, ready: ready);
      expect(jsonTextSize(input), greaterThan(16777216));
      expect(jsonTextSize(input), lessThanOrEqualTo(25165824));
      expect(jsonTextSize(aggregatePlan(800, ready: ready)),
          greaterThan(25165824));
      final plan = ConversionPlan.fromJson(input, limits: world.planJsonLimits);
      expect(plan.state, ready ? PlanState.ready : PlanState.draft);
      expect(plan.operations, hasLength(600));
      expect(
          plan.canonicalHash,
          ConversionPlan.fromJson(plan.toJson(), limits: world.planJsonLimits)
              .canonicalHash);
      expect(
          () => ConversionPlan.fromJson(input, limits: world.jsonLimits),
          throwsA(isA<ContractError>()
              .having((error) => error.code, 'code', 'json.textQuota')));
      expect(
          () => ConversionPlan.fromJson(aggregatePlan(800, ready: ready),
              limits: world.planJsonLimits),
          throwsA(isA<ContractError>()
              .having((error) => error.code, 'code', 'json.textQuota')));
      expect(
          () => NativeMutation(
              operationId: ConverterId('too-large-record'),
              actionId: 'map.save',
              sourceEntityIds: [],
              targetEntityIds: [],
              parameters: {'records': List.filled(20, 'x' * 1000000)},
              limits: world),
          throwsA(isA<ContractError>()
              .having((error) => error.code, 'code', 'json.textQuota')));
    });
  }

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
    ConverterStudySettings settings(int maps, {NativeWriteLimits? limits}) =>
        ConverterStudySettings(
        projectName: 'World capacity',
        parentPath: '/private/tmp/world-capacity',
        folderName: 'world',
        selectedSourceMapIds: [
          for (var index = 1; index <= maps; index++) index
        ],
        writeLimits: limits,
        profileAcknowledgement: SourceStudyAcknowledgement(
            sourceSnapshotHash: Sha256Hash('0' * 64),
            profileEvidenceHash: Sha256Hash('1' * 64),
            humanConfirmed: true,
            reason: 'Bounded whole-world conversion capacity'));
    final world = settings(383);
    final json = world.toJson();
    expect((json['writeLimits'] as Map)['maxMutations'], 32768);
    expect((json['writeLimits'] as Map)['maxArtifacts'], 4096);
    expect((json['writeLimits'] as Map)['maxTotalDraftJsonBytes'], 268435456);
    expect(world.canonicalHash, settings(383).canonicalHash);
    final resume = LocalReviewResumeSettings(
        sourceRootPath: fixture.sourceRootPath,
        destinationParentPath: world.parentPath,
        projectName: world.projectName,
        folderName: world.folderName,
        writeLimits: world.writeLimits);
    final restoredResume = LocalReviewResumeSettings.fromJson(resume.toJson());
    expect(restoredResume.toJson(), resume.toJson());
    expect(restoredResume.writeLimits.maxArtifacts, 4096);
    final recipe = ConverterStudyPlanRecipe(
        sessionId: ConverterId('world-capacity-session'),
        sessionRevision: 3,
        sourceSelection: ConverterSourceSelection(
            rootPath: fixture.sourceRootPath,
            logicalProjectNamespace: ConverterId('world-capacity')),
        settings: world,
        sourceSnapshotHash: world.profileAcknowledgement.sourceSnapshotHash,
        profileEvidenceHash: world.profileAcknowledgement.profileEvidenceHash,
        settingsHash: world.canonicalHash,
        nativeDraftHash: Sha256Hash('2' * 64),
        preparationHash: Sha256Hash('3' * 64),
        previewPlanHash: Sha256Hash('4' * 64),
        approvedPlanHash: Sha256Hash('5' * 64),
        targetCapabilitiesHash: Sha256Hash('6' * 64),
        rulesHash: Sha256Hash('7' * 64),
        converterVersion: 'world-capacity-test');
    final restoredRecipe = ConverterStudyPlanRecipe.fromJson(recipe.toJson());
    expect(restoredRecipe.toJson(), recipe.toJson());
    expect(restoredRecipe.settings.writeLimits.maxArtifacts, 4096);
    for (final count in [32, 512, 1024, 2048]) {
      final explicit = settings(383,
          limits: NativeWriteLimits(maxArtifacts: count, maxMutations: 16384));
      expect(explicit.writeLimits.maxArtifacts, count);
      final body = recipe.toJson()
        ..remove('canonicalHash')
        ..['settings'] = explicit.toJson()
        ..['settingsHash'] = explicit.canonicalHash.value;
      final explicitRecipe = ConverterStudyPlanRecipe.fromJson({
        ...body,
        'canonicalHash': canonicalHashOf(body,
                limits: ConverterStudyPlanRecipe.jsonLimits)
            .value,
      });
      expect(explicitRecipe.settings.writeLimits.maxArtifacts, count);
      expect(
          LocalReviewResumeSettings.fromJson(LocalReviewResumeSettings(
                  sourceRootPath: fixture.sourceRootPath,
                  destinationParentPath: explicit.parentPath,
                  projectName: explicit.projectName,
                  folderName: explicit.folderName,
                  writeLimits: explicit.writeLimits)
              .toJson()).writeLimits.maxArtifacts,
          count);
    }
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
