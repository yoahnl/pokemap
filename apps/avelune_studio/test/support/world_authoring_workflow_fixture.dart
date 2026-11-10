import 'dart:io';

import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/stories/application/story_workspace_controller.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/world/application/world_draft_inputs.dart';
import 'package:avelune_studio/features/world/application/world_editor_workflow.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:map_core/map_core_domain.dart';

import 'ui12_world_harness.dart';

class WorldAuthoringWorkflowFixture {
  WorldAuthoringWorkflowFixture._(this.harness) {
    stories = StoryWorkspaceController(
      world.narrative,
      LocalStoryAdapter(session: harness.session, mapAdapter: harness.adapter),
      changed: () {},
    );
    workspace = WorkspaceWorkflow(
      controller: harness.maps,
      isActive: () => !harness.maps.isDisposed,
      changed: () {},
      resources: () => null,
      narrative: () => world.narrative,
      world: () => world,
      worldInputsValid: () => inputs.valid,
      confirmClose: () async {
        closeQuestions++;
        return closeChoice;
      },
      flushFocus: () {},
      launchMap: (_, _) async {},
    );
  }

  final Ui12WorldHarness harness;
  final inputs = WorldDraftInputs();
  late final StoryWorkspaceController stories;
  late final WorkspaceWorkflow workspace;
  WorkspaceCloseChoice? closeChoice = WorkspaceCloseChoice.save;
  bool approveDependency = true;
  int dependencyQuestions = 0;
  int closeQuestions = 0;
  WorldWorkspaceController get world => harness.world;

  static Future<WorldAuthoringWorkflowFixture> create({
    WorldPort Function(WorldPort)? wrap,
  }) async {
    final parent = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await parent.create(recursive: true);
    return WorldAuthoringWorkflowFixture._(
      await Ui12WorldHarness.create(wrap: wrap, parent: parent),
    );
  }

  WorldEditorWorkflow get editor => WorldEditorWorkflow(
    controller: world,
    inputs: inputs,
    flushFocus: () {},
    changed: () {},
    confirmDependency: (_) async {
      dependencyQuestions++;
      return approveDependency;
    },
  );

  Future<void> dispose() async {
    stories.dispose();
    await harness.dispose();
  }
}

String createWorldFact(WorldWorkspaceController world, String label) {
  final id = world.createFact();
  world.editFact(
    NarrativeFactDefinition(
      id: id,
      label: label,
      initialValue: const NarrativeValue.boolean(false),
    ),
  );
  return id;
}

String composeWorldRule(
  WorldWorkspaceController world,
  String factId, {
  bool complete = true,
}) {
  final map = world.maps.firstWhere((map) => map.entities.isNotEmpty);
  final id = world.createRule(factId: factId);
  world.editRule(id, (draft) {
    draft.label = 'Masquer le conducteur';
    if (!complete) return;
    draft.target = WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: map.id,
      entityId: map.entities.first.id,
      label: map.entities.first.id,
    );
    draft.effect = const WorldRuleEffect(
      kind: WorldRuleEffectKind.entityHidden,
    );
  });
  return id;
}
