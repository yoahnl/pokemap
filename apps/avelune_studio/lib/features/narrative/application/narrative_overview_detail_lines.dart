import 'package:map_core/map_core_domain.dart';

import 'narrative_overview.dart';

String narrativeSceneLinkRoleLabel(StorylineSceneLinkRole role) =>
    switch (role) {
      StorylineSceneLinkRole.primary => 'Principal',
      StorylineSceneLinkRole.optional => 'Facultatif',
      StorylineSceneLinkRole.branch => 'Branche',
      StorylineSceneLinkRole.convergence => 'Convergence',
      StorylineSceneLinkRole.setup => 'Préparation',
      StorylineSceneLinkRole.payoff => 'Résolution',
    };

String narrativeRelationshipLabel(StorylineRelationshipKind kind) =>
    switch (kind) {
      StorylineRelationshipKind.sideQuestAvailableDuring =>
        'Disponible pendant',
      StorylineRelationshipKind.sideQuestUnlockedBy => 'Débloquée par',
      StorylineRelationshipKind.sideQuestAffectsMain => 'A un effet sur',
      StorylineRelationshipKind.convergesTo => 'Converge vers',
      StorylineRelationshipKind.requires => 'Nécessite',
      StorylineRelationshipKind.blocks => 'Bloque',
    };

List<String> narrativeFactDefinitionLines(NarrativeFactDefinition fact) => [
  'Type : ${switch (fact.valueKind) {
    NarrativeValueKind.boolean => 'Oui / non',
    NarrativeValueKind.integer => 'Nombre entier',
    NarrativeValueKind.string => 'Texte',
  }}',
  'Valeur initiale : ${fact.valueKind == NarrativeValueKind.boolean ? (fact.defaultValue ? 'Oui' : 'Non') : fact.initialValue.toJson()}',
];

List<String> narrativeStoryOrganizationLines(StorylineAsset story) => [
  '${story.chapters.length} chapitre(s)',
  '${story.chapters.expand((c) => c.steps).length} étape(s)',
  '${story.sceneLinks.length} lien(s) de scène',
];

List<String> narrativeStoryRelationLines(
  StorylineAsset story,
  List<StorylineAsset> stories,
) => [
  for (final relation in story.relationships)
    '${narrativeRelationshipLabel(relation.kind)} → ${stories.where((s) => s.id == relation.targetStorylineId).firstOrNull?.title ?? '${relation.targetStorylineId} (introuvable)'}',
];

List<StorylineSceneLink> narrativeStepSceneLinks(
  StorylineAsset story,
  StorylineStep step,
) => story.sceneLinks
    .where((l) => l.stepId == step.id || step.sceneLinkIds.contains(l.id))
    .toList();

List<String> narrativeSceneLinkLines(StorylineSceneLink link) => [
  link.label,
  'Rôle : ${narrativeSceneLinkRoleLabel(link.role)}',
  if (link.sceneRef == null) 'Scène non renseignée',
];

List<String> narrativeInteractionConditionLines(
  NarrativeOverviewInteraction item,
) => item.conditions.isEmpty
    ? [
        item.advanced
            ? 'Analyse détaillée indisponible'
            : 'Aucune condition déclarée',
      ]
    : item.conditions;

String? narrativeInteractionSceneId(NarrativeOverviewInteraction item) =>
    item.record?.definitionOrNull?.sceneId ?? item.record?.draftOrNull?.sceneId;
