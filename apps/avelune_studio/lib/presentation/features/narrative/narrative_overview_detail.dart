import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/narrative/application/narrative_overview.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'narrative_overview_view_state.dart';

class NarrativeOverviewDetail extends StatelessWidget {
  const NarrativeOverviewDetail({
    super.key,
    required this.overview,
    required this.state,
    required this.story,
    required this.onChanged,
    required this.onOpen,
    required this.onLocate,
    required this.busy,
    this.onOpenScene,
  });
  final NarrativeOverview overview;
  final NarrativeOverviewViewState state;
  final StorylineAsset? story;
  final VoidCallback onChanged;
  final ValueChanged<String> onOpen, onLocate;
  final bool busy;
  final ValueChanged<String>? onOpenScene;

  @override
  Widget build(BuildContext context) {
    final interaction = overview.interactionsById[state.interactionId];
    final step = story?.chapters
        .expand((chapter) => chapter.steps)
        .where((item) => item.id == state.stepId)
        .firstOrNull;
    final fact = overview.facts.where((f) => f.id == state.factId).firstOrNull;
    return StudioPanel(
      title: 'Détail',
      compact: true,
      children: [
        Expanded(
          child: ListView(
            key: ValueKey(
              'detail-${state.interactionId ?? state.stepId ?? state.factId ?? state.storyId}',
            ),
            children: [
              if (interaction != null)
                ..._interaction(context, interaction)
              else if (step != null)
                ..._step(context, step)
              else if (fact != null)
                ..._fact(context, fact)
              else if (state.tab == NarrativeOverviewTab.stories &&
                  story != null)
                ..._story(context, story!)
              else
                const StudioNotice(
                  'Sélectionnez un élément pour consulter son contexte et ses liens.',
                ),
              if (state.notice case final notice?) ...[
                const SizedBox(height: 16),
                StudioNotice(notice, isError: true),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _interaction(
    BuildContext context,
    NarrativeOverviewInteraction item,
  ) => [
    _heading(context, item.name),
    Text(item.mapLabel),
    Text(item.sourceLabel, style: Theme.of(context).textTheme.bodySmall),
    const SizedBox(height: 12),
    if (item.dirty) const StudioNotice('Brouillon local · non enregistré'),
    if (item.advanced)
      const StudioNotice(
        'Interaction avancée · consultation seule. Son contenu est conservé.',
      ),
    ..._section(context, 'Quand', [item.whenText]),
    ..._section(
      context,
      'Si',
      item.conditions.isEmpty
          ? [
              item.advanced
                  ? 'Analyse détaillée indisponible'
                  : 'Aucune condition déclarée',
            ]
          : item.conditions,
    ),
    ..._section(context, 'Alors', item.consequences),
    if (item.missingReferences.isNotEmpty)
      ..._section(context, 'Références introuvables', item.missingReferences),
    if (item.references.isNotEmpty) ...[
      const SizedBox(height: 16),
      Text('Liens connus', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      for (final reference in item.references)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '${reference.label}${reference.missing ? ' · introuvable' : ''}',
          ),
        ),
    ],
    const SizedBox(height: 20),
    if (onOpenScene != null &&
        (item.record?.definitionOrNull?.sceneId ??
                item.record?.draftOrNull?.sceneId) !=
            null)
      StudioButton(
        label: 'Ouvrir la scène',
        icon: Icons.account_tree_outlined,
        onPressed: busy
            ? null
            : () => onOpenScene!(
                (item.record?.definitionOrNull?.sceneId ??
                    item.record!.draftOrNull!.sceneId!),
              ),
      ),
    if (!item.advanced)
      StudioButton(
        label: item.session != null
            ? 'Reprendre le brouillon'
            : 'Ouvrir l’éditeur',
        icon: Icons.edit_outlined,
        onPressed: busy || !item.canEdit ? null : () => onOpen(item.id),
      ),
    const SizedBox(height: 8),
    StudioButton(
      label: 'Voir sur la carte',
      icon: Icons.map_outlined,
      secondary: true,
      onPressed: busy || item.source == null ? null : () => onLocate(item.id),
    ),
    const SizedBox(height: 16),
    SelectableText(
      'Identifiant : ${item.id}',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  ];

  List<Widget> _step(BuildContext context, StorylineStep step) => [
    _heading(context, step.title),
    if (step.description case final description?) Text(description),
    if (step.entryCondition != null || step.completionCondition != null)
      const StudioNotice(
        'Cette étape comporte des conditions avancées. Leur analyse détaillée n’est pas disponible ici.',
      ),
    ..._links(context, overview.stepLinks[step.id] ?? []),
    if (story case final current?)
      for (final link in current.sceneLinks.where(
        (l) => l.stepId == step.id || step.sceneLinkIds.contains(l.id),
      ))
        ..._section(context, 'Lien de scène', [
          link.label,
          'Rôle : ${_role(link.role)}',
          if (link.sceneRef == null) 'Scène non renseignée',
        ]),
    for (final reference
        in overview.stepReferences[step.id] ?? <NarrativeOverviewReference>[])
      StudioNotice(
        '${reference.label}${reference.missing ? ' · référence introuvable' : ''}',
        isError: reference.missing,
      ),
    const SizedBox(height: 16),
    Text(
      'Les liens affichés proviennent des données du projet et des brouillons ouverts. Les scripts avancés ne sont pas interprétés.',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  ];

  List<Widget> _fact(BuildContext context, NarrativeFactDefinition fact) => [
    _heading(context, fact.label),
    if (fact.description.isNotEmpty) Text(fact.description),
    ..._section(context, 'Définition', [
      'Type : ${switch (fact.valueKind) {
        NarrativeValueKind.boolean => 'Oui / non',
        NarrativeValueKind.integer => 'Nombre entier',
        NarrativeValueKind.string => 'Texte',
      }}',
      'Valeur initiale : ${fact.valueKind == NarrativeValueKind.boolean ? (fact.defaultValue ? 'Oui' : 'Non') : fact.initialValue.toJson()}',
    ]),
    const StudioNotice(
      'Valeur initiale du projet. Les valeurs des parties jouées ne sont pas affichées ici.',
    ),
    ..._links(context, overview.factLinks[fact.id] ?? []),
  ];

  List<Widget> _story(BuildContext context, StorylineAsset value) => [
    _heading(context, value.title),
    if (value.description case final description?) Text(description),
    ..._section(context, 'Organisation', [
      '${value.chapters.length} chapitre(s)',
      '${value.chapters.expand((c) => c.steps).length} étape(s)',
      '${value.sceneLinks.length} lien(s) de scène',
    ]),
    if (value.relationships.isNotEmpty)
      ..._section(context, 'Relations entre histoires', [
        for (final relation in value.relationships)
          '${_relationship(relation.kind)} → ${overview.stories.where((s) => s.id == relation.targetStorylineId).firstOrNull?.title ?? '${relation.targetStorylineId} (introuvable)'}',
      ]),
    const StudioNotice(
      'Choisissez une étape pour retrouver les interactions qui y font référence.',
    ),
  ];

  List<Widget> _links(
    BuildContext context,
    List<NarrativeOverviewInteraction> links,
  ) => [
    const SizedBox(height: 16),
    Text('Interactions liées', style: Theme.of(context).textTheme.titleSmall),
    const SizedBox(height: 8),
    if (links.isEmpty)
      const StudioNotice(
        'Aucun lien trouvé dans les données consultées. Ajoutez cette étape ou cet état depuis une interaction existante.',
      ),
    for (final item in links) ...[
      StudioChoice(
        label: item.name,
        subtitle: '${item.mapLabel} · ${item.sourceLabel}',
        leading: const Icon(Icons.chat_bubble_outline, size: 18),
        onTap: () {
          state.select(interaction: item.id);
          onChanged();
        },
      ),
      const SizedBox(height: 8),
    ],
  ];

  Widget _heading(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );

  List<Widget> _section(
    BuildContext context,
    String title,
    List<String> lines,
  ) => [
    const SizedBox(height: 16),
    Text(title, style: Theme.of(context).textTheme.titleSmall),
    const SizedBox(height: 6),
    for (final line in lines)
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(line)),
  ];

  String _role(StorylineSceneLinkRole role) => switch (role) {
    StorylineSceneLinkRole.primary => 'Principal',
    StorylineSceneLinkRole.optional => 'Facultatif',
    StorylineSceneLinkRole.branch => 'Branche',
    StorylineSceneLinkRole.convergence => 'Convergence',
    StorylineSceneLinkRole.setup => 'Préparation',
    StorylineSceneLinkRole.payoff => 'Résolution',
  };

  String _relationship(StorylineRelationshipKind kind) => switch (kind) {
    StorylineRelationshipKind.sideQuestAvailableDuring => 'Disponible pendant',
    StorylineRelationshipKind.sideQuestUnlockedBy => 'Débloquée par',
    StorylineRelationshipKind.sideQuestAffectsMain => 'A un effet sur',
    StorylineRelationshipKind.convergesTo => 'Converge vers',
    StorylineRelationshipKind.requires => 'Nécessite',
    StorylineRelationshipKind.blocks => 'Bloque',
  };
}
