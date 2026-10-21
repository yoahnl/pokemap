import 'dart:io';
import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'source_routed_door_profile_test.dart' as doors;
import 'support/literal_tile_fixture.dart';

void main() {
  for (final scope in ConverterContentScope.values) {
    for (final includeMalformedMap in [
      false,
      if (scope == ConverterContentScope.full) true
    ]) {
      test(
          'public preparation restricts attested door derivation to selected maps malformedSelected=$includeMalformedMap scope=${scope.name}',
          () async {
        final root =
            await Directory('/private/tmp').createTemp('rc02-public-doors-');
        final workflow = ConverterWorkflow();
        try {
          final fixture =
              await doors.routedDoorFixture('CopperGate', declared: false);
          final source = Directory('${root.path}/source');
          final output = await Directory('${root.path}/output').create();
          for (final entry in {
            ...fixture.sourceBytes,
            'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Player\n'),
            'Graphics/Characters/Player.png': literalFixtureAtlas(),
            'Data/map_metadata.dat': literalFixtureMarshal({}),
            'Data/Map010.rxdata': <int>[4, 8, 255],
          }.entries) {
            final file = File('${source.path}/${entry.key}');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(entry.value);
          }
          final snapshot = await workflow.scanSource(ConverterSourceSelection(
            rootPath: source.path,
            logicalProjectNamespace: ConverterId('rc02-public-doors'),
          ));
          final profile = fixture.source.interpretationProfile!;
          expect(
              profile.presentationBindings?.routedDoorPatterns ?? [], isEmpty);
          workflow.updateSettings(ConverterStudySettings(
            projectName: 'Public door study',
            contentScope: scope,
            parentPath: output.path,
            folderName: 'public-doors',
            selectedSourceMapIds: [7, 9, if (includeMalformedMap) 10],
            interpretationProfile: profile,
            profileAcknowledgement: SourceStudyAcknowledgement(
              sourceSnapshotHash: snapshot.canonicalHash,
              profileEvidenceHash: snapshot.profile.evidenceHash,
              humanConfirmed: true,
              reason: 'Synthetic exact source door preparation.',
            ),
          ));
          if (includeMalformedMap) {
            await expectLater(workflow.prepareStudy(),
                throwsA(isA<ConverterWorkflowFailure>()));
            expect(workflow.state.prepared, isNull);
            expect(await output.list().toList(), isEmpty);
            return;
          }
          final prepared = await workflow.prepareStudy();
          final patterns = prepared.normalizedSource.interpretationProfile!
                  .presentationBindings?.routedDoorPatterns ??
              [];
          expect(
              patterns, hasLength(scope == ConverterContentScope.full ? 1 : 0));
          if (scope == ConverterContentScope.world) {
            expect(
                prepared.normalizedSource.interpretationProfile!.canonicalHash,
                profile.canonicalHash);
            return;
          }
          expect(patterns.single.charset, 'CopperGate');
          final analysis = SourceEventAnalyzer.forProject(
                  prepared.normalizedSource,
                  profile:
                      SourceEventProfile.forProject(prepared.normalizedSource))
              .analyze();
          expect(
              sourceRoutedDoorPrograms(
                  source: prepared.normalizedSource, analysis: analysis),
              hasLength(1));
          expect(prepared.settings.interpretationProfile!.canonicalHash,
              profile.canonicalHash);
          expect(prepared.canApprove, isTrue,
              reason: prepared.previewPlan?.findings
                  .map((finding) => finding.toJson())
                  .toString());
          final recipe = workflow.exportStudyPlanRecipe();
          final restored = ConverterWorkflow();
          try {
            final fresh = await restored.restoreStudyPlanRecipe(
                ConverterStudyPlanRecipe.decode(recipe.encode()));
            expect(fresh.normalizedSource.canonicalHash,
                prepared.normalizedSource.canonicalHash);
            expect(fresh.nativeDraft!.canonicalHash,
                prepared.nativeDraft!.canonicalHash);
            expect(fresh.preparationHash, prepared.preparationHash);
            expect(
                fresh.normalizedSource.interpretationProfile!
                    .presentationBindings!.routedDoorPatterns.single.charset,
                'CopperGate');
            expect(restored.state.approval, isNull);
          } finally {
            await restored.dispose();
          }
        } finally {
          await workflow.dispose();
          await root.delete(recursive: true);
        }
      }, skip: !Platform.isMacOS);
    }
  }
}
