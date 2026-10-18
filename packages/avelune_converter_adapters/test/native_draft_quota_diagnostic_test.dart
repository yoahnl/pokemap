import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';

void main() {
  late Directory temporary;
  late NativeWriterFixture fixture;
  late List<NativeMutation> mixed;

  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp('draft-quota-diagnostic-');
    fixture = await NativeWriterFixture.create(temporary.path);
    mixed = [
      NativeMutation(
        operationId: ConverterId('quota-assets'),
        actionId: 'asset.import_batch',
        sourceEntityIds: [fixture.source.mapIdentity(1)],
        targetEntityIds: [ConverterId('quota-a'), ConverterId('quota-b')],
        parameters: {
          'entries': [
            for (final id in ['quota-a', 'quota-b'])
              {
                'assetId': id,
                'artifactHandle': fixture.draft.artifacts.single.handle,
                'logicalPath': 'assets/$id.png',
                'tags': <String>[],
                'usages': <String>[],
              },
          ],
        },
      ),
      fixture.draft.mutations[1],
    ];
  });

  tearDownAll(() async {
    await temporary.delete(recursive: true);
  });

  NativeProjectDraft draft({
    NativeWriteLimits limits = const NativeWriteLimits(maxMutations: 3),
    Map<int, String>? maps,
    List<NativeMutation>? mutations,
    Map<String, Object?> evidence = const {},
  }) => NativeProjectDraft(
    source: fixture.source,
    projectName: fixture.draft.projectName,
    parentPath: fixture.draft.parentPath,
    folderName: fixture.draft.folderName,
    sourceRootPath: fixture.draft.sourceRootPath,
    mapIds: maps ?? fixture.draft.mapIds,
    artifacts: fixture.draft.artifacts,
    mutations: mutations ?? mixed,
    compositionEvidence: evidence,
    limits: limits,
  );

  Matcher failure(String stage, {String maps = '1/2', String logical = '3/2',
      int envelopes = 2}) => isA<NativeWriteException>()
      .having((error) => error.code, 'code', 'native.quota.draft')
      .having((error) => error.message, 'message',
          'Draft map or mutation budget exceeded: inferredStage=$stage, '
          'maps=$maps, logicalMutations=$logical, mutationEnvelopes=$envelopes');

  test('mixed batch and single mutation accept the exact logical budget', () {
    final accepted = draft();
    expect(accepted.mutations, hasLength(2));
    expect(() => accepted.validateResourceBudget(
        limits: const NativeWriteLimits(maxMutations: 3)), returnsNormally);
  });

  test('logical budget plus one reports exact counts without counting the batch envelope', () {
    expect(() => draft(limits: const NativeWriteLimits(maxMutations: 2)),
        throwsA(failure('unspecified')));
  });

  test('map budget reports maps independently of the mutation count', () {
    expect(() => draft(limits: const NativeWriteLimits(maxMutations: 1),
        maps: {1: 'map-a', 2: 'map-b'}, mutations: [mixed.last]),
        throwsA(failure('unspecified', maps: '2/1', logical: '1/1', envelopes: 1)));
  });

  const stages = ['assetLibrary', 'sourceCatalogs', 'sourceEvents',
    'sourceSemantics', 'composition'];
  for (var index = 0; index < stages.length; index++) {
    final stage = stages[index];
    test('stage priority infers $stage from evidence keys without exposing values', () {
      final evidence = {
        for (final key in stages.skip(index).toList().reversed)
          key: {'privateValue': '/private/source/secret-content.rb'},
      };
      expect(() => draft(limits: const NativeWriteLimits(maxMutations: 2),
          evidence: evidence), throwsA(failure(stage)));
    });
  }

  test('resource revalidation uses the same diagnostic as construction', () {
    final accepted = draft(evidence: {'sourceEvents': <String, Object?>{}});
    expect(() => accepted.validateResourceBudget(
        limits: const NativeWriteLimits(maxMutations: 2)),
        throwsA(failure('sourceEvents')));
  });

  test('writer reports exact collection counts before creating a staging directory', () async {
    final approval = approveNativeFixtureDraft(fixture.draft);
    final stages = <NativeWriteStage>[];
    await expectLater(NativeProjectWriter(
        checkpoint: (stage, _, __) => stages.add(stage)).write(
        approval.plan, approval.context, fixture.draft,
        limits: const NativeWriteLimits(maxMutations: 2)),
        throwsA(failure('unspecified', envelopes: 3)));
    expect(stages, isEmpty);
  });
}
