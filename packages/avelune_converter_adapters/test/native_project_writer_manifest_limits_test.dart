import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';

int _textUnits(Object? value) => switch (value) {
      String value => value.length,
      List value => value.fold<int>(0, (sum, item) => sum + _textUnits(item)),
      Map value => value.entries.fold<int>(
          0,
          (sum, item) =>
              sum + (item.key as String).length + _textUnits(item.value)),
      _ => 0,
    };

const _approvedLimits = NativeWriteLimits(
    maxTotalDraftJsonBytes: 8388608,
    jsonLimits: ContractLimits(maxTextCodeUnits: 1048576));

NativeProjectDraft _largeManifestDraft(NativeWriterFixture fixture) {
  final image = fixture.draft.mutations.first;
  final largeLabel = 'x' * 900000;
  final imports = [
    for (var index = 0; index < 5; index++)
      NativeMutation(
          operationId: ConverterId('large-manifest-image-$index'),
          actionId: image.actionId,
          sourceEntityIds: image.sourceEntityIds,
          targetEntityIds: [
            ConverterId(index == 0 ? 'fixture_atlas' : 'extra_atlas_$index'),
            ConverterId(index == 0
                ? 'image_fixture_atlas'
                : 'image_extra_atlas_$index'),
          ],
          parameters: {
            ...image.parameters,
            'tilesetId': index == 0 ? 'fixture_atlas' : 'extra_atlas_$index',
            'name': '$index$largeLabel',
          },
          limits: _approvedLimits),
  ];
  final create = fixture.draft.mutations[1];
  return copyNativeFixtureDraft(fixture.draft,
      mutations: [
        ...imports,
        copyNativeFixtureMutation(create,
            parameters: {...create.parameters, 'tilesetId': 'fixture_atlas'}),
        fixture.draft.mutations[2],
      ],
      limits: _approvedLimits);
}

void main() {
  test(
      'writer preserves approved manifest limits through creation and cold verification',
      () async {
    final root =
        await Directory.systemTemp.createTemp('native-manifest-limits-');
    try {
      final fixture = await NativeWriterFixture.create(root.path);
      const limits = _approvedLimits;
      final draft = _largeManifestDraft(fixture);
      final approved = approveNativeFixtureDraft(draft);
      final nativeCheckpoints = <NativeWriteStage>[];
      var nativeManifestValidated = false;
      final creation =
          NativeProjectCreationService(checkpoint: (stage, projectPath) async {
        if (stage != ProjectCreationCheckpoint.afterApply) return;
        final manifest = ProjectManifest.fromJson(
            jsonDecode(await File('$projectPath/project.json').readAsString())
                as Map<String, dynamic>);
        ProjectValidator.validate(manifest, maps: [fixture.expectedMap]);
        final units = _textUnits(manifest.toJson());
        expect(units, greaterThan(const ContractLimits().maxTextCodeUnits));
        expect(units, greaterThan(limits.jsonLimits.maxTextCodeUnits));
        expect(
            units, lessThan(limits.draftEvidenceJsonLimits.maxTextCodeUnits));
        expect(
            () => canonicalJsonOf(manifest.toJson(),
                limits: limits.draftEvidenceJsonLimits),
            returnsNormally);
        expect(
            () => canonicalJsonOf(manifest.toJson(), limits: limits.jsonLimits),
            throwsA(isA<ContractError>()
                .having((error) => error.code, 'code', 'json.textQuota')));
        stdout.writeln(
            'valid native manifest textCodeUnits=$units singleDocumentMax=${limits.jsonLimits.maxTextCodeUnits} approvedAggregateMax=${limits.draftEvidenceJsonLimits.maxTextCodeUnits}');
        nativeManifestValidated = true;
      });
      final receipt = await NativeProjectWriter(
              creation: creation,
              checkpoint: (stage, _, __) => nativeCheckpoints.add(stage))
          .write(approved.plan, approved.context, draft, limits: limits);
      expect(nativeManifestValidated, isTrue);
      expect(receipt.verified, isTrue);
      expect(
          nativeCheckpoints,
          containsAllInOrder([
            NativeWriteStage.afterCreation,
            NativeWriteStage.beforeNativeVerify,
            NativeWriteStage.afterNativeVerify,
          ]));
      for (final entry in fixture.sourceBytes.entries) {
        expect(
            await File('${fixture.sourceRootPath}/${entry.key}').readAsBytes(),
            entry.value);
      }
    } finally {
      await root.delete(recursive: true);
    }
  });

  test(
      'writer refuses the same draft above its aggregate budget before creation',
      () async {
    final root =
        await Directory.systemTemp.createTemp('native-manifest-budget-');
    try {
      final fixture = await NativeWriterFixture.create(root.path);
      final draft = _largeManifestDraft(fixture);
      final approved = approveNativeFixtureDraft(draft);
      const limits = NativeWriteLimits(
          maxTotalDraftJsonBytes: 4194304,
          jsonLimits: ContractLimits(maxTextCodeUnits: 1048576));
      final stages = <NativeWriteStage>[];
      final creationStages = <ProjectCreationCheckpoint>[];
      final writer = NativeProjectWriter(
          creation: NativeProjectCreationService(checkpoint: (stage, _) async {
            creationStages.add(stage);
          }),
          checkpoint: (stage, _, __) => stages.add(stage));
      await expectLater(
          writer.write(approved.plan, approved.context, draft, limits: limits),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.quota.draft_json')));
      expect(stages, isEmpty);
      expect(creationStages, isEmpty);
      expect(await Directory('${root.path}/${draft.folderName}').exists(),
          isFalse);
      for (final entry in fixture.sourceBytes.entries) {
        expect(
            await File('${fixture.sourceRootPath}/${entry.key}').readAsBytes(),
            entry.value);
      }
    } finally {
      await root.delete(recursive: true);
    }
  });
}
