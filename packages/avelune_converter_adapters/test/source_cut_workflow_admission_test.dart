import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'canonical badge API preserves a Cut definition without granting progress',
      () {
    const badge = BadgeDefinition(
        id: 'cut-capability-badge',
        label: 'Cascade Badge',
        fieldAbilityUnlock: FieldAbility.cut);
    final project = ProjectManifest(
        name: 'Cut definition API', maps: const [], tilesets: const []);
    final result = const CampaignContentActions()
        .upsert(project, CampaignContentKind.badge, badge);
    expect(result.badges.single.toJson(), badge.toJson());
    expect(result.newGame.enabled, isFalse);
    expect(result.newGame.initialParty, isEmpty);
    expect(result.newGame.resolvedInitialFactValues, isEmpty);
    expect(
        AuthoringMutationDispatcher.canonical()
            .descriptors
            .map((entry) => entry.id),
        contains('campaign.badge.upsert'));
    final replaced = const CampaignContentActions()
        .upsert(result, CampaignContentKind.badge, badge);
    expect(replaced.badges, hasLength(1));
  });

  final sourceRoot = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  test(
      'original Route 10 Cut workflow admits campaign badge before strict approval',
      () async {
    final output =
        await Directory.systemTemp.createTemp('original-cut-approval-');
    final workflow = ConverterWorkflow();
    final timer = Stopwatch()..start();
    try {
      final snapshot = await workflow.scanSource(ConverterSourceSelection(
          rootPath: sourceRoot!,
          logicalProjectNamespace: ConverterId('source-semantic-study')));
      expect(snapshot.state, SourceScanState.complete);
      stdout
          .writeln('Cut approval source scan ${timer.elapsedMilliseconds} ms');
      final tree = await MacOsSourceTree.open(sourceRoot);
      late List<LiteralDependencyDecision> decisions;
      try {
        final files =
            await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
        final normalized = await const RmxpSourceNormalizer().normalize(
            snapshot: snapshot,
            files: files,
            selectedMapIds: {100},
            includeEventSystem: true,
            includeConnections: snapshot.entries.any(
                (entry) => entry.relativePath == 'Data/map_connections.dat'));
        expect(normalized.canPlan, isTrue);
        final selection = literalSelectionHash(normalized, [100]);
        decisions = [
          for (final map in normalized.maps)
            for (final event in map.map.events)
              for (final page in event.pages)
                for (final command in page.commands)
                  if (command.code == 201 &&
                      command.parameters.length >= 2 &&
                      command.parameters[0] == 0 &&
                      command.parameters[1] is int &&
                      command.parameters[1] != 100)
                    LiteralDependencyDecision(
                        sourceSnapshotHash: snapshot.canonicalHash,
                        selectionHash: selection,
                        locator: command.sourceLocator,
                        targetSourceMapId: command.parameters[1] as int,
                        decision: LiteralDependencyDisposition.excludeStudy),
        ];
        await files.verifyUnchanged();
      } finally {
        await tree.close();
      }
      stdout.writeln(
          'Cut approval dependency decisions ${timer.elapsedMilliseconds} ms');
      workflow.updateSettings(ConverterStudySettings(
        projectName: 'Original Cut approval qualification',
        parentPath: output.path,
        folderName: 'original-cut-approval',
        selectedSourceMapIds: [100],
        allowFirstFrameAutotiles: true,
        dependencyDecisions: decisions,
        writeLimits: sourceCatalogStudyWriteLimitsFor(1),
        profileAcknowledgement: SourceStudyAcknowledgement(
            sourceSnapshotHash: snapshot.canonicalHash,
            profileEvidenceHash: snapshot.profile.evidenceHash,
            humanConfirmed: true,
            reason:
                'Exact original Route 10 Cut definitions; no initial party, badge or field unlock granted.'),
      ));
      final prepared = await workflow.prepareStudy();
      stdout.writeln('Cut approval prepared ${timer.elapsedMilliseconds} ms');
      expect(prepared.canApprove, isTrue,
          reason: jsonEncode(prepared.previewPlan?.toJson()['findings']));
      final draft = prepared.nativeDraft!;
      expect(draft.mapIds.keys.toSet(), {100});
      final badgeMutation = draft.mutations.singleWhere(
          (mutation) => mutation.actionId == 'campaign.badge.upsert');
      final badge = BadgeDefinition.fromJson(
          Map<String, dynamic>.from(badgeMutation.parameters['value'] as Map));
      expect(badge.label, 'Cascade Badge');
      expect(badge.fieldAbilityUnlock, FieldAbility.cut);
      expect(
          draft.mutations.where((mutation) =>
              mutation.actionId == 'entity.upsert' &&
              (mutation.parameters['entity'] as Map)['fieldObstacle'] != null),
          hasLength(4));
      final sourceEvents = draft.compositionEvidence['sourceEvents'] as Map;
      expect((sourceEvents['cutObstacles'] as Map)['initialPlayerStateMutated'],
          isFalse);
      late StudyApproval approval;
      expect(() {
        approval = workflow.approvePrepared(
            sessionRevision: prepared.sessionRevision,
            preparationHash: prepared.preparationHash,
            humanConfirmed: true);
      }, returnsNormally);
      expect(approval.approvedPlan.approvedByHuman, isTrue);
      expect(
          approval.approvedPlan.operations
              .singleWhere((operation) =>
                  operation.targetActionId == 'campaign.badge.upsert')
              .operationId,
          badgeMutation.operationId);
      final capability = prepared.targetCapabilities.capabilities.singleWhere(
          (entry) =>
              entry.capabilityId.value == 'native.study.campaign.badge.upsert');
      expect(capability.status, CapabilityStatus.supported);
      expect(
          capability.evidence.any((entry) =>
              entry.reference
                  .contains('source_cut_workflow_admission_test.dart') &&
              entry.summary.contains('campaign.badge.upsert')),
          isTrue);
      expect(
          draft.mutations.where(
              (mutation) => mutation.actionId.startsWith('campaign.new_game')),
          isEmpty);
      expect(await output.list().toList(), isEmpty);
      expect(workflow.state.result, isNull);
    } finally {
      await workflow.dispose();
      await output.delete(recursive: true);
    }
  },
      skip: sourceRoot == null
          ? 'Requires the exact immutable original Kanto source.'
          : false,
      timeout: const Timeout(Duration(seconds: 160)));
}
