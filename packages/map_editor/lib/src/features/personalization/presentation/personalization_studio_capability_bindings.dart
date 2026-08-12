import 'inspectors/personalization_battle_inspector.dart';
import 'inspectors/personalization_dialogue_inspector.dart';
import 'inspectors/personalization_global_style_inspector.dart';
import 'inspectors/personalization_intro_inspector.dart';
import 'inspectors/personalization_pause_inspector.dart';
import 'inspectors/personalization_title_inspector.dart';
import 'personalization_preview_controls.dart';
import 'personalization_preview_source_selector.dart';
import 'personalization_scene_inspector.dart';
import 'personalization_scene_navigation.dart';

const personalizationStudioVisibleCapabilityIds = <String>{
  ...PersonalizationPreviewControls.capabilityIds,
  ...PersonalizationPreviewSourceSelector.capabilityIds,
  ...PersonalizationSceneNavigation.capabilityIds,
  ...PersonalizationSceneInspector.capabilityIds,
  ...PersonalizationGlobalStyleInspector.capabilityIds,
  ...PersonalizationTitleInspector.capabilityIds,
  ...PersonalizationIntroInspector.capabilityIds,
  ...PersonalizationPauseInspector.capabilityIds,
  ...PersonalizationDialogueInspector.capabilityIds,
  ...PersonalizationBattleInspector.capabilityIds,
};
