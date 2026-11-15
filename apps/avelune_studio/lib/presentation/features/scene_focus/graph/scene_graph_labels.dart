import 'package:flutter/material.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_families.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';

Color sceneGraphFamilyColor(BuildContext context, SceneGraphFamily family) =>
    switch (family) {
      SceneGraphFamily.start => StudioAccent.firefly.color(context),
      SceneGraphFamily.dialogue => StudioAccent.water.color(context),
      SceneGraphFamily.condition => StudioAccent.halo.color(context),
      SceneGraphFamily.action => StudioAccent.fog.color(context),
      SceneGraphFamily.battle => StudioAccent.window.color(context),
      SceneGraphFamily.cinematic => StudioAccent.daylight.color(context),
      SceneGraphFamily.end ||
      SceneGraphFamily.flow => Theme.of(context).colorScheme.outline,
    };

String? sceneGraphCardDetail(
  AppLocalizations l10n,
  SceneNode node,
  SceneAsset scene,
  ProjectManifest? project,
  Map<String, String> dialogueNames,
) => switch (node.payload) {
  SceneYarnDialoguePayload(:final dialogueId) =>
    dialogueNames[dialogueId] ??
        project?.dialogues.where((d) => d.id == dialogueId).firstOrNull?.name ??
        l10n.sceneGraphMissing,
  SceneConditionPayload(:final conditionSource) =>
    conditionSource?.label ?? l10n.sceneGraphUnset,
  SceneEndPayload(:final sceneOutcomeId?) =>
    scene.declaredOutcomes
            .where((o) => o.id == sceneOutcomeId)
            .firstOrNull
            ?.label ??
        sceneOutcomeId,
  SceneCinematicPayload(:final cinematicId) =>
    project?.cinematics.where((c) => c.id == cinematicId).firstOrNull?.title ??
        l10n.sceneGraphMissing,
  SceneActionPayload() => switch (sceneStepFamilyOfNode(node)) {
    SceneStepFamily.other => sceneStepCommandIdOf(node),
    final family => l10n.storyStepFamily(family.name),
  },
  _ => node.description?.trim().isEmpty ?? true ? null : node.description,
};
