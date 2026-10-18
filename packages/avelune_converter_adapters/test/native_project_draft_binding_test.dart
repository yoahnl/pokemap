import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';

void main() {
  late Directory root;
  late NativeWriterFixture fixture;

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('ac15-draft-binding-');
    final output = await Directory('${root.path}/output').create();
    fixture = await NativeWriterFixture.create(output.path);
  });

  tearDownAll(() => root.delete(recursive: true));

  NativeMutation record(int index, Object? value,
          {NativeWriteLimits limits = const NativeWriteLimits(),
          int actionVersion = 1,
          List<ConverterId>? sourceIds,
          List<ConverterId>? targetIds}) =>
      NativeMutation(
          operationId: ConverterId('original-record-$index'),
          actionId: 'map.save',
          actionVersion: actionVersion,
          sourceEntityIds:
              sourceIds ?? fixture.draft.mutations.last.sourceEntityIds,
          targetEntityIds:
              targetIds ?? fixture.draft.mutations.last.targetEntityIds,
          parameters: {'record': value},
          limits: limits);

  NativeProjectDraft draft(List<NativeMutation> mutations,
          {Map<String, Object?> evidence = const {},
          NativeWriteLimits limits = const NativeWriteLimits()}) =>
      copyNativeFixtureDraft(fixture.draft,
          mutations: mutations, compositionEvidence: evidence, limits: limits);

  test('individually bounded records bind beyond one JSON document', () {
    final mutations = [
      for (var index = 0; index < 7; index++) record(index, 'p' * 700000),
    ];
    expect(
        () => canonicalJsonOf([
              for (var index = 0; index < mutations.length; index++)
                mutations[index].toJson(index),
            ]),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'json.textQuota')));
    final original = draft(mutations);
    expect(original.mutations, hasLength(7));
    for (var index = 0; index < mutations.length; index++) {
      expect(original.mutations[index].parameters, mutations[index].parameters);
    }
    expect(draft(mutations).canonicalHash, original.canonicalHash);
    expect(draft(mutations.reversed.toList()).canonicalHash,
        isNot(original.canonicalHash));
    expect(draft([...mutations.take(6), record(6, 'q' * 700000)]).canonicalHash,
        isNot(original.canonicalHash));
  });

  test('aggregate composition evidence binds beyond record text quotas', () {
    final evidence = <String, Object?>{
      'rows': List.filled(10, 'é🌲\n"' * 100000)
    };
    expect(() => canonicalJsonOf(evidence), throwsA(isA<ContractError>()));
    final original = draft([], evidence: evidence);
    original.validateResourceBudget();
    expect(draft([], evidence: evidence).canonicalHash, original.canonicalHash);
    (evidence['rows'] as List)[0] = 'altered';
    expect(draft([], evidence: evidence).canonicalHash,
        isNot(original.canonicalHash));
    expect(
        (original.compositionEvidence['rows'] as List).first, isNot('altered'));
    expect(() => (original.compositionEvidence['rows'] as List)[0] = 'altered',
        throwsUnsupportedError);
    expect(
        () => original.validateResourceBudget(
            limits: NativeWriteLimits(
                maxTotalDraftJsonBytes: original.validatedJsonByteLength - 1)),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.quota.draft_json')));
  });

  test(
      'aggregate evidence retains caller structural and individual string limits',
      () {
    for (final entry in [
      (
        {
          'rows': ['x' * 1025]
        },
        const ContractLimits(maxStringCodeUnits: 1024),
        'json.textQuota'
      ),
      (
        {
          'rows': [
            [
              ['x']
            ]
          ]
        },
        const ContractLimits(maxDepth: 2),
        'json.quota'
      ),
      (
        {'rows': List.filled(10, 'x')},
        const ContractLimits(maxNodes: 5),
        'json.quota'
      ),
    ]) {
      expect(
          () => draft([],
              evidence: entry.$1,
              limits: NativeWriteLimits(jsonLimits: entry.$2)),
          throwsA(
              isA<ContractError>().having((e) => e.code, 'code', entry.$3)));
    }
  });

  test('large aggregate evidence rechecks caller bytes before staging',
      () async {
    final original = draft(fixture.draft.mutations,
        evidence: {'rows': List.filled(7, 'p' * 700000)});
    final approval = approveNativeFixtureDraft(original);
    final stages = <NativeWriteStage>[];
    var allocated = false;
    await expectLater(
        NativeProjectWriter(
          checkpoint: (stage, _, __) => stages.add(stage),
          stagingFactory: () async {
            allocated = true;
            throw StateError(
                'Aggregate evidence must be checked before staging');
          },
        ).write(approval.plan, approval.context, original,
            limits: NativeWriteLimits(
                maxTotalDraftJsonBytes: original.validatedJsonByteLength - 1)),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.quota.draft_json')));
    expect(stages, isEmpty);
    expect(allocated, isFalse);
  });

  test('ordered record bindings retain all action metadata and evidence', () {
    final original = draft([
      record(0, {'value': 'original'})
    ], evidence: {
      'source': 'exact'
    });
    final alternatives = [
      draft([
        record(0, {'value': 'changed'})
      ], evidence: {
        'source': 'exact'
      }),
      draft([
        record(1, {'value': 'original'})
      ], evidence: {
        'source': 'exact'
      }),
      draft([
        record(0, {'value': 'original'}, actionVersion: 2)
      ], evidence: {
        'source': 'exact'
      }),
      draft([
        record(0, {'value': 'original'},
            sourceIds: [ConverterId('other-source')])
      ], evidence: {
        'source': 'exact'
      }),
      draft([
        record(0, {'value': 'original'},
            targetIds: [ConverterId('other-target')])
      ], evidence: {
        'source': 'exact'
      }),
      draft([
        record(0, {'value': 'original'})
      ], evidence: {
        'source': 'changed'
      }),
    ];
    expect(
        alternatives
            .every((value) => value.canonicalHash != original.canonicalHash),
        isTrue);
    expect(alternatives.map((value) => value.canonicalHash).toSet(),
        hasLength(alternatives.length));
  });

  test('draft admission rechecks every record against caller limits', () {
    final mutation = record(
        0, [for (var index = 0; index < 6; index++) 'p' * 800000],
        limits: const NativeWriteLimits(
            jsonLimits: ContractLimits(maxTextCodeUnits: 8388608)));
    expect(
        () => draft([mutation]),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'json.textQuota')));
  });

  test('binding snapshots retain immutable records and nested evidence', () {
    final parameters = <String, Object?>{
      'values': [1, 2, 3]
    };
    final evidence = <String, Object?>{
      'proof': {'value': 'exact'}
    };
    final mutations = [record(0, parameters)];
    final original = draft(mutations, evidence: evidence);
    final hash = original.canonicalHash;
    (parameters['values'] as List)[0] = 99;
    (evidence['proof'] as Map)['value'] = 'changed';
    mutations.clear();
    expect(original.canonicalHash, hash);
    expect(original.mutations.single.parameters['record'], {
      'values': [1, 2, 3]
    });
    expect(original.compositionEvidence, {
      'proof': {'value': 'exact'}
    });
    expect(() => original.mutations.clear(), throwsUnsupportedError);
    expect(
        () => (original.compositionEvidence['proof'] as Map)['value'] = 'bad',
        throwsUnsupportedError);
    expect(
        jsonEncode(original.mutations.single.parameters), contains('[1,2,3]'));
  });

  test(
      'aggregate JSON budget counts UTF-8 records and accepts its exact boundary',
      () {
    final mutations = [record(0, '🌲\né' * 10000)];
    final evidence = <String, Object?>{'proof': '🌲\t' * 1000};
    final original = draft(mutations, evidence: evidence);
    final payloadBytes = utf8.encode(canonicalJsonOf(evidence)).length +
        utf8.encode(canonicalJsonOf(mutations.single.toJson(0))).length;
    expect(original.validatedJsonByteLength, greaterThan(payloadBytes));
    final exact = draft(mutations,
        evidence: evidence,
        limits: NativeWriteLimits(
            maxTotalDraftJsonBytes: original.validatedJsonByteLength));
    expect(exact.canonicalHash, original.canonicalHash);
    expect(exact.validatedJsonByteLength, original.validatedJsonByteLength);
    for (final limit in [
      payloadBytes - 1,
      original.validatedJsonByteLength - 1
    ]) {
      expect(
          () => draft(mutations,
              evidence: evidence,
              limits: NativeWriteLimits(maxTotalDraftJsonBytes: limit)),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.quota.draft_json')));
    }
  });

  test('aggregate JSON limits are positive and bounded', () {
    for (final value in [1, 67108864, 268435456]) {
      expect(() => NativeWriteLimits(maxTotalDraftJsonBytes: value).validate(),
          returnsNormally);
    }
    for (final value in [-1, 0, 268435457]) {
      expect(
          () => NativeWriteLimits(maxTotalDraftJsonBytes: value).validate(),
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'native.invalid_limits')));
    }
  });

  test('effective aggregate quota refuses the writer before any stage',
      () async {
    final stages = <NativeWriteStage>[];
    var allocated = false;
    final before =
        root.listSync(recursive: true).map((entry) => entry.path).toSet();
    final writer = NativeProjectWriter(
        checkpoint: (stage, _, __) => stages.add(stage),
        stagingFactory: () async {
          allocated = true;
          throw StateError('The caller quota must precede stage allocation');
        });
    await expectLater(
        writer.write(fixture.plan, fixture.context, fixture.draft,
            limits: NativeWriteLimits(
                maxTotalDraftJsonBytes:
                    fixture.draft.validatedJsonByteLength - 1)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.quota.draft_json')));
    expect(stages, isEmpty);
    expect(allocated, isFalse);
    expect(root.listSync(recursive: true).map((entry) => entry.path).toSet(),
        before);
  });

  test('stricter caller JSON limits recheck contents before stage', () async {
    final original = draft([
      record(0, [for (var index = 0; index < 6; index++) 'p' * 800000],
          limits: const NativeWriteLimits(
              jsonLimits: ContractLimits(maxTextCodeUnits: 8388608)))
    ],
        limits: const NativeWriteLimits(
            jsonLimits: ContractLimits(maxTextCodeUnits: 8388608)));
    final approval = approveNativeFixtureDraft(original);
    final stages = <NativeWriteStage>[];
    final before =
        root.listSync(recursive: true).map((entry) => entry.path).toSet();
    await expectLater(
        NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
            .write(approval.plan, approval.context, original),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'native.admission.json.textQuota')));
    expect(
        () => original.validateResourceBudget(),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'json.textQuota')));
    expect(stages, isEmpty);
    expect(root.listSync(recursive: true).map((entry) => entry.path).toSet(),
        before);
  });

  test(
      'publication reservation estimates complete individually bounded records',
      () async {
    final original = draft(
        [for (var index = 0; index < 20; index++) record(index, 'p' * 900000)]);
    expect(original.validatedJsonByteLength, greaterThan(16777216));
    final approval = approveNativeFixtureDraft(original);
    final job = await const NativeProjectPublication().begin(
        approval.plan, approval.context, original,
        policy: NativePublicationPolicy(
            allowedParentRoots: [original.parentPath],
            sourceRoots: [fixture.sourceRootPath]));
    try {
      final first =
          jsonDecode((await File(job.journalPath).readAsLines()).first)
              as Map<String, Object?>;
      final header = first['payload'] as Map<String, Object?>;
      expect(header['estimatedBytes'],
          greaterThanOrEqualTo(original.validatedJsonByteLength * 2));
      expect(await Directory(job.destinationPath).exists(), isFalse);
      expect(
          root.listSync(recursive: true).any((entry) =>
              entry is Directory &&
              entry.path.contains('.avelune-converter-stage-')),
          isFalse);
    } finally {
      await job.close();
    }
  }, skip: !Platform.isMacOS);
}
