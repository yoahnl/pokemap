import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/steps/scene_step_families.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';

final _commands = NarrativeCommandCatalog.canonical();

String sceneGraphNodeTitle(AppLocalizations l10n, SceneNode node) {
  final title = node.title?.trim();
  if (title != null && title.isNotEmpty) return title;
  if (node.kind != SceneNodeKind.action) {
    return l10n.sceneGraphKind(node.kind.name);
  }
  final command = sceneStepCommandIdOf(node);
  final family = switch (command) {
    NarrativeCommandIds.setFact => SceneStepFamily.rememberFact,
    NarrativeCommandIds.giveItem ||
    NarrativeCommandIds.giveItemGift => SceneStepFamily.giveItem,
    NarrativeCommandIds.setNpcPresence => SceneStepFamily.showOrHide,
    _ => null,
  };
  return switch ((family, command)) {
    (final family?, _) => l10n.storyStepFamily(family.name),
    (_, final command?) => l10n.sceneGraphActionTitle(
      command,
      _commands.byId(command)?.label ?? l10n.storyStepAdvanced,
    ),
    _ => l10n.sceneGraphKind(node.kind.name),
  };
}

String sceneGraphPortLabel(
  AppLocalizations l10n,
  String id,
  ProjectDialogueEntry? dialogue, {
  Map<String, String> choiceLabels = const {},
}) =>
    choiceLabels[id] ??
    dialogue?.declaredOutcomes
        .where((outcome) => outcome.id == id)
        .firstOrNull
        ?.label ??
    l10n.sceneGraphPort(id);

String? sceneGraphCardDetail(
  AppLocalizations l10n,
  SceneNode node,
  SceneAsset scene,
  ProjectManifest? project,
  String? dialogueName, {
  MapData? map,
  Map<String, String> factNames = const {},
}) => switch (node.payload) {
  SceneYarnDialoguePayload() => dialogueName ?? l10n.sceneGraphMissing,
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
  SceneBattlePayload(:final trainerId?) =>
    project?.trainers
        .where((trainer) => trainer.id == trainerId)
        .firstOrNull
        ?.name,
  SceneActionPayload(consequence: SceneSetFactConsequence(:final factId)) =>
    factNames[factId] ??
        project?.facts.where((fact) => fact.id == factId).firstOrNull?.label,
  SceneActionPayload(
    consequence: SceneSetNpcPresenceConsequence(:final mapId, :final entityId),
  )
      when map?.id == mapId =>
    map?.entities.where((entity) => entity.id == entityId).firstOrNull?.name,
  SceneActionPayload(
    interactiveCommand: SceneWarpInteractiveCommand(:final destinationMapId),
  ) =>
    project?.maps
        .where((entry) => entry.id == destinationMapId)
        .firstOrNull
        ?.name,
  SceneActionPayload(
    interactiveCommand: SceneWaitInteractiveCommand(:final durationMs),
  ) =>
    l10n.sceneGraphWaitDuration(durationMs),
  _ => node.description?.trim().isEmpty ?? true ? null : node.description,
};
