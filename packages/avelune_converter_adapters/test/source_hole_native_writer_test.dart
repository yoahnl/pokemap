import 'dart:convert';
import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';
import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_HOLE_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_HOLE_SOURCE_SNAPSHOT'];
  final enabled = Platform.environment['AVELUNE_HOLE_RUN_WRITER'] == '1';
  final supplemental =
      (Platform.environment['AVELUNE_HOLE_SUPPLEMENTAL_ROOTS'] ?? '')
          .split('|')
          .where((path) => path.isNotEmpty)
          .toList();
  test(
      'original two-map holes survive native composer writer and strict reopen',
      () async {
    const selection = {361, 362};
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: selection, supplementalRoots: supplemental);
    final source = fixture.source;
    final temporary =
        await Directory.systemTemp.createTemp('hole-native-writer-');
    addTearDown(() => temporary.delete(recursive: true));
    const limits = NativeWriteLimits(maxArtifacts: 96);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: source,
            files: fixture.files,
            selectedSourceMapIds: selection.toList()..sort(),
            projectName: 'Original Kanto holes',
            parentPath: temporary.path,
            folderName: 'holes',
            dependencyDecisions: decisions,
            limits: limits);
    final probe = await literal([]);
    final composed = await literal([
      for (final dependency in probe.dependencies)
        if (!selection.contains(dependency.targetSourceMapId))
          LiteralDependencyDecision(
              sourceSnapshotHash: source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy),
    ]);
    expect(composed.draft, isNotNull, reason: composed.diagnostics.toString());
    final semantic = await const SourceSemanticStudyComposer().compose(
        source: source, base: composed, files: fixture.files, limits: limits);
    final events = (await const SourceEventStudyComposer().compose(
        source: source,
        base: semantic!,
        files: fixture.files,
        limits: limits))!;
    stdout.writeln('hole writer: complete two-map composition ready');
    final analysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
        .analyze();
    final expected = [
      analysis.eventAt(361, 2)!,
      analysis.eventAt(362, 1)!,
      analysis.eventAt(362, 2)!,
      analysis.eventAt(362, 4)!
    ];
    for (final event in expected) {
      final row = (events.projection.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['sourceIdentity'] == event.identity.value);
      expect(
          events.projection.scenes.where((scene) =>
              scene.metadata['sourceEventIdentity'] == event.identity.value),
          hasLength(1),
          reason: row.toString());
    }
    final evidence =
        (jsonDecode(jsonEncode(events.draft.compositionEvidence)) as Map)
            .cast<String, Object?>();
    final sourceEvents = evidence['sourceEvents'] as Map;
    final projection = sourceEvents['projection'] as Map;
    final qualification = projection['doorExecutionQualification'] as Map;
    final holes = qualification['holePrograms'] as List;
    (holes.first as Map)['policy'] = {
      'presentation': 'unattestedSourceOpacity'
    };
    final original = events.draft;
    final forged = NativeProjectDraft(
        source: original.source,
        projectName: original.projectName,
        parentPath: original.parentPath,
        folderName: original.folderName,
        sourceRootPath: original.sourceRootPath,
        mapIds: original.mapIds,
        artifacts: original.artifacts,
        sourceArtifacts: original.sourceArtifacts,
        mutations: original.mutations,
        compositionEvidence: evidence,
        defaultMapWidth: original.defaultMapWidth,
        defaultMapHeight: original.defaultMapHeight,
        limits: limits);
    final forgedApproval = approveNativeFixtureDraft(forged);
    final stages = <NativeWriteStage>[];
    await expectLater(
        NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
            .write(forgedApproval.plan, forgedApproval.context, forged,
                limits: limits),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'native.semantics.regeneration')));
    expect(stages, isEmpty);
    stdout.writeln('hole writer: forged policy rejected before staging');
    final approval = approveNativeFixtureDraft(events.draft);
    var appliedMutations = 0;
    final receipt = await NativeProjectWriter(checkpoint: (stage, _, __) {
      if (stage == NativeWriteStage.afterMutation) appliedMutations++;
      if (stage != NativeWriteStage.afterMutation || appliedMutations % 25 == 0) {
        stdout.writeln('hole writer checkpoint: $stage / $appliedMutations');
      }
    })
        .write(approval.plan, approval.context, events.draft, limits: limits);
    expect(receipt.verified, true);
    final handles = WorkspaceHandleStore();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    try {
      final loaded = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(loaded.loadDiagnostics, isEmpty);
      expect(
          loaded.manifest.eventRegistry!.records
              .where((record) => record.enabledOrNull == true),
          isNotEmpty);
      for (final scene in events.projection.scenes.where((scene) =>
          expected.any((event) =>
              scene.metadata['sourceEventIdentity'] == event.identity.value))) {
        expect(
            loaded.manifest.scenes
                .singleWhere((candidate) => candidate.id == scene.id)
                .toJson(),
            scene.toJson());
      }
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  },
      timeout: const Timeout(Duration(minutes: 15)),
      skip: !enabled || root == null || snapshot == null
          ? 'Opt-in original source writer qualification required.'
          : false);
}
