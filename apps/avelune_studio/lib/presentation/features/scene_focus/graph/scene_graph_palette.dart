import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/steps/scene_step_families.dart';

enum SceneGraphCategory {
  flow,
  dialogue,
  facts,
  world,
  travel,
  inventory,
  battle,
  presentation,
  services;

  IconData get icon => switch (this) {
    flow => Icons.account_tree_outlined,
    dialogue => Icons.chat_bubble_outline,
    facts => Icons.flag_outlined,
    world => Icons.person_outline,
    travel => Icons.route_outlined,
    inventory => Icons.inventory_2_outlined,
    battle => Icons.flash_on_outlined,
    presentation => Icons.movie_outlined,
    services => Icons.space_dashboard_outlined,
  };

  Color accent(BuildContext context) => switch (this) {
    flow => Theme.of(context).colorScheme.secondary,
    dialogue => Theme.of(context).colorScheme.primary,
    facts => StudioAccent.fog.color(context),
    world => StudioAccent.firefly.color(context),
    travel => StudioColors.of(context).success,
    inventory => StudioAccent.halo.color(context),
    battle => StudioAccent.window.color(context),
    presentation => StudioColors.of(context).featureAccent,
    services => StudioAccent.water.color(context),
  };
}

SceneGraphCategory sceneGraphCategory(SceneNode node) => switch (node.kind) {
  SceneNodeKind.yarnDialogue => SceneGraphCategory.dialogue,
  SceneNodeKind.battle => SceneGraphCategory.battle,
  SceneNodeKind.cinematic ||
  SceneNodeKind.presentationCinematic => SceneGraphCategory.presentation,
  SceneNodeKind.action => _actionCategory(node),
  _ => SceneGraphCategory.flow,
};

SceneGraphCategory sceneGraphTemplateCategory(SceneStepFamily family) =>
    switch (family) {
      SceneStepFamily.talk => SceneGraphCategory.dialogue,
      SceneStepFamily.rememberFact => SceneGraphCategory.facts,
      SceneStepFamily.showOrHide => SceneGraphCategory.world,
      SceneStepFamily.giveItem => SceneGraphCategory.inventory,
      SceneStepFamily.battle => SceneGraphCategory.battle,
      SceneStepFamily.musicAndSound => SceneGraphCategory.presentation,
      SceneStepFamily.conditions => SceneGraphCategory.flow,
      SceneStepFamily.other => SceneGraphCategory.services,
    };

SceneGraphCategory _actionCategory(SceneNode node) =>
    switch (sceneStepCommandIdOf(node)) {
      NarrativeCommandIds.warp ||
      NarrativeCommandIds.movePlatform ||
      NarrativeCommandIds.waitForActorRoutes ||
      NarrativeCommandIds.railJourney => SceneGraphCategory.travel,
      NarrativeCommandIds.moveNpc ||
      NarrativeCommandIds.actorRoute ||
      NarrativeCommandIds.setNpcPose ||
      NarrativeCommandIds.setPropState ||
      NarrativeCommandIds.setPlayerAvatar => SceneGraphCategory.world,
      NarrativeCommandIds.givePokemon ||
      NarrativeCommandIds.giveConfiguredStarter ||
      NarrativeCommandIds.givePokemonFromCatalog ||
      NarrativeCommandIds.receivePokemonFromCatalog ||
      NarrativeCommandIds.markPokemonSeen ||
      NarrativeCommandIds.healParty ||
      NarrativeCommandIds.awardBadge ||
      NarrativeCommandIds.unlockFieldAbility => SceneGraphCategory.battle,
      NarrativeCommandIds.worldTone ||
      NarrativeCommandIds.worldPresentation ||
      NarrativeCommandIds.playCharacterAnimation ||
      NarrativeCommandIds.playModelAnimation ||
      NarrativeCommandIds.cinematic => SceneGraphCategory.presentation,
      NarrativeCommandIds.wait ||
      NarrativeCommandIds.finishGame => SceneGraphCategory.flow,
      _ => sceneGraphTemplateCategory(sceneStepFamilyOfNode(node)),
    };

IconData sceneGraphNodeIcon(SceneNode node) => switch (node.kind) {
  SceneNodeKind.start => Icons.play_arrow_outlined,
  SceneNodeKind.end => Icons.stop_circle_outlined,
  SceneNodeKind.condition => Icons.call_split,
  _ => sceneGraphCategory(node).icon,
};

Color sceneGraphNodeAccent(BuildContext context, SceneNode node) =>
    switch (node.kind) {
      SceneNodeKind.start => Theme.of(context).colorScheme.error,
      SceneNodeKind.condition => StudioAccent.fog.color(context),
      _ => sceneGraphCategory(node).accent(context),
    };
