import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/narrative/application/narrative_overview.dart';
import '../../../features/narrative/domain/narrative_port.dart';
import '../../../features/verification/application/verification_workspace_controller.dart';
import 'narrative_artwork_image.dart';
import '../../shared/widgets/buttons/studio_action_card.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/feedback/studio_icon_tile.dart';
import '../../shared/widgets/inputs/studio_resource_card.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../theme/studio_tokens.dart';

part 'narrative_overview_landing_content.dart';
part 'narrative_overview_landing_desktop.dart';
part 'narrative_overview_landing_side.dart';
part 'narrative_overview_landing_search.dart';

class NarrativeOverviewLanding extends StatelessWidget {
  const NarrativeOverviewLanding({
    super.key,
    required this.overview,
    required this.project,
    required this.scenes,
    required this.dialogues,
    required this.events,
    this.verification,
    required this.search,
    required this.onSearch,
    required this.resultsScroll,
    required this.onLibrary,
    required this.onCreateStory,
    required this.onCreateScene,
    required this.onCreateEvent,
    required this.onProgression,
    required this.onScenes,
    required this.onEvents,
    required this.onVerification,
    required this.onOpenStory,
    required this.onOpenStep,
    required this.onOpenScene,
    required this.onOpenInteraction,
    required this.onOpenDialogue,
    required this.onOpenEvent,
    required this.onOpenMap,
    this.artworkPort,
    this.activeSceneId,
    this.activeStoryId,
    this.activeDialogueId,
    this.activeEventId,
    this.dirtyStoryIds = const {},
    this.dirtySceneIds = const {},
    this.dirtyDialogueIds = const {},
    this.dirtyEventIds = const {},
  });

  final NarrativeOverview overview;
  final NarrativeArtworkPort? artworkPort;
  final ProjectManifest project;
  final List<SceneAsset> scenes;
  final List<ProjectDialogueEntry> dialogues;
  final List<NarrativeEventRecord> events;
  final VerificationWorkspaceController? verification;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final ScrollController resultsScroll;
  final VoidCallback onLibrary;
  final VoidCallback? onCreateStory;
  final VoidCallback? onCreateScene, onCreateEvent;
  final VoidCallback? onProgression, onScenes, onEvents, onVerification;
  final ValueChanged<String> onOpenStory;
  final void Function(String storyId, String stepId) onOpenStep;
  final ValueChanged<String>? onOpenScene,
      onOpenDialogue,
      onOpenEvent,
      onOpenMap;
  final ValueChanged<String> onOpenInteraction;
  final String? activeStoryId, activeSceneId, activeDialogueId, activeEventId;
  final Set<String> dirtyStoryIds,
      dirtySceneIds,
      dirtyDialogueIds,
      dirtyEventIds;

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - 32;
        final wide =
            contentWidth >= 1060 &&
            MediaQuery.textScalerOf(context).scale(14) <= 20;
        final sideWidth = wide ? 282.0 : contentWidth;
        final mainWidth = wide ? contentWidth - sideWidth - 12 : contentWidth;
        if (wide) {
          return _desktop(context, mainWidth, sideWidth, query);
        }
        final main = _main(context, mainWidth, query);
        final side = SizedBox(width: sideWidth, child: _side(context));
        return SingleChildScrollView(
          key: const ValueKey('narrative-overview-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [main, const SizedBox(height: 12), side],
          ),
        );
      },
    );
  }

  Widget _main(BuildContext context, double width, String query) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _hero(context, width),
      const SizedBox(height: 12),
      StudioSearchField(
        controller: search,
        label: 'Rechercher dans Histoire',
        hint: 'Histoires, étapes, scènes, dialogues, événements et cartes',
        onChanged: onSearch,
      ),
      const SizedBox(height: 12),
      if (query.isNotEmpty)
        _searchResults(context, query)
      else ...[
        _stories(context, width),
        const SizedBox(height: 12),
        _lower(context, width),
      ],
    ],
  );

  Widget _hero(BuildContext context, double width) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
      child: Stack(
        children: [
          Positioned.fill(
            child: NarrativeArtworkImage(
              key: const ValueKey('narrative-hero-artwork'),
              port: artworkPort,
              kind: NarrativeArtworkKind.hero,
              fallback: Image.asset(
                'assets/home/hero_landscape.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 234),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.surfaceContainerLowest,
                    colors.surfaceContainerLowest.withValues(alpha: .85),
                    colors.surfaceContainerLowest.withValues(alpha: .08),
                  ],
                  stops: const [0, .47, 1],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NARRATIVE STUDIO',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  letterSpacing: 2,
                                  color: colors.primary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Donnez vie à votre histoire',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Organisez vos histoires, retrouvez vos scènes et reliez votre aventure.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            project.name,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _actions(context, width - 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, double width) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final columns = !largeText && width >= 880
        ? 4
        : width >= 530
        ? 2
        : 1;
    final itemWidth = (width - (columns - 1) * 10) / columns;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: itemWidth,
          child: StudioActionCard(
            title: 'Nouvelle histoire',
            subtitle: 'Créer un parcours',
            icon: Icons.auto_stories_outlined,
            tone: StudioTone.info,
            onPressed: onCreateStory,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: StudioActionCard(
            title: 'Nouvelle scène',
            subtitle: 'Assembler un scénario',
            icon: Icons.account_tree_outlined,
            tone: StudioTone.feature,
            onPressed: onCreateScene,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: StudioActionCard(
            title: 'Nouvel événement',
            subtitle: 'Déclencher une scène',
            icon: Icons.bolt_outlined,
            tone: StudioTone.warning,
            onPressed: onCreateEvent,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: StudioActionCard(
            title: 'Vérification narrative',
            subtitle: 'Contrôler la cohérence',
            icon: Icons.fact_check_outlined,
            tone: StudioTone.success,
            onPressed: onVerification,
          ),
        ),
      ],
    );
  }
}
