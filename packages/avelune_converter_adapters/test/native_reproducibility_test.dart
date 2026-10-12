import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../tool/compare_native_studies.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_reproducibility.dart';

void main() {
  test('comparison refuses a filesystem root as its authorization scope',
      () async {
    await expectLater(
        compareNativeStudyDirectories(
            leftProjectPath: '/absent-left',
            rightProjectPath: '/absent-right',
            allowedParentPath: '/',
            expectedOperationIds: ['original']),
        throwsFormatException);
  });
  test('retained bootstrap cannot be invented from absent logs', () {
    expect(() => recoverNativeBootstrapBytes({}, ['original']),
        throwsFormatException);
    expect(() => recoverNativeBootstrapBytes({}, ['original', 'original']),
        throwsFormatException);
  });
  test('comparison tool requires two outputs and an explicit narrow parent',
      () async {
    final output = StringBuffer();
    final errors = StringBuffer();
    expect(
        await runNativeStudyComparison([], output: output, errors: errors), 64);
    expect(output.toString(), isEmpty);
    expect(errors.toString(), contains('--parent'));
  });

  group('captured expectations bind the exact original saved recipe', () {
    late Directory root;
    late ConverterWorkflow workflow;
    late ConverterStudyPlanRecipe recipe;
    late List<String> operations;
    late Map<String, List<int>> sourceBefore;
    late String sourcePath;
    setUpAll(() async {
      root = await Directory.systemTemp
          .createTemp('ac16-reproducibility-capture-');
      final output = await Directory('${root.path}/output').create();
      final fixture = await LiteralTileFixture.create(
          sourceRootPath: '${root.path}/source');
      sourcePath = fixture.sourceRootPath!;
      sourceBefore = await readNativeStudyTree(sourcePath);
      workflow = ConverterWorkflow();
      final snapshot = await workflow.scanSource(ConverterSourceSelection(
          rootPath: sourcePath,
          logicalProjectNamespace: ConverterId('original-comparison')));
      workflow.updateSettings(ConverterStudySettings(
          projectName: 'Original comparison fixture',
          parentPath: output.path,
          folderName: 'native-study',
          selectedSourceMapIds: [1],
          profileAcknowledgement: SourceStudyAcknowledgement(
              sourceSnapshotHash: snapshot.canonicalHash,
              profileEvidenceHash: snapshot.profile.evidenceHash,
              humanConfirmed: true,
              reason: 'Original no-script offline fixture.')));
      final prepared = await workflow.prepareStudy();
      recipe = workflow.exportStudyPlanRecipe();
      operations = prepared.nativeDraft!.mutations
          .map((m) => m.operationId.value)
          .toList();
      await const LocalStudyPlanStore()
          .writeNew(recipe, '${root.path}/plan.json');
    });
    tearDownAll(() async {
      await workflow.dispose();
      expect(await readNativeStudyTree(sourcePath), sourceBefore);
      await root.delete(recursive: true);
    });
    Future<void> reject(Map<String, Object?> changes) async {
      final capture = {
        'kind': 'nativeReproducibilityExpectations',
        'version': 1,
        'recipeHash': recipe.canonicalHash.value,
        'nativeDraftHash': recipe.nativeDraftHash.value,
        'approvedPlanHash': recipe.approvedPlanHash.value,
        'operationIds': operations,
        ...changes
      };
      await File('${root.path}/expectations.json')
          .writeAsString(jsonEncode(capture));
      final output = StringBuffer();
      final errors = StringBuffer();
      expect(
          await runNativeStudyComparison([
            '--parent',
            '${root.path}/output',
            '--plan',
            '${root.path}/plan.json',
            '--expectations',
            '${root.path}/expectations.json',
            '${root.path}/output/nonexistent-left',
            '${root.path}/output/nonexistent-right'
          ], output: output, errors: errors),
          1);
      expect(output.toString(), isEmpty);
      expect(jsonDecode(errors.toString())['message'], contains('Captured'));
      expect(await Directory('${root.path}/output').list().toList(), isEmpty);
    }

    test('a stale native draft hash is refused before reading outputs',
        () async {
      await reject({'nativeDraftHash': '0' * 64});
    });
    test('unknown capture fields cannot widen volatile normalization',
        () async {
      await reject({'ignoreMetadata': true});
    });
    test('duplicate operation IDs are refused', () async {
      await reject({
        'operationIds': [operations.first, operations.first]
      });
    });
  }, skip: !Platform.isMacOS);
}
