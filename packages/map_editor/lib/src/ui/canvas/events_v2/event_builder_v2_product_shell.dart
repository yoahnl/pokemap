import 'package:flutter/cupertino.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

/// Geometry keys shared by the production route and its pixel-contract tests.
///
/// Keeping them here prevents the visual harness from proving a shell that the
/// shipped route never mounts — the exact regression K2-R is meant to avoid.
const eventBuilderV2ProductShellKey =
    ValueKey<String>('event-builder-v2-product-shell');
const eventBuilderV2ProductShellHeaderKey =
    ValueKey<String>('event-builder-v2-product-shell-header');
const eventBuilderV2ProductShellContextBarKey =
    ValueKey<String>('event-builder-v2-product-shell-context-bar');
const eventBuilderV2ProductShellProjectKey =
    ValueKey<String>('event-builder-v2-product-shell-project');
const eventBuilderV2ProductShellNavigationKey =
    ValueKey<String>('event-builder-v2-product-shell-navigation');
const eventBuilderV2ProductShellWorkspaceKey =
    ValueKey<String>('event-builder-v2-product-shell-workspace');

/// Reference-aligned desktop shell used only by Event Builder V2.
///
/// The generic map-authoring chrome remains the correct home for every other
/// workspace. Event V2 needs a project-wide canvas, however, so nesting it in
/// the map toolbar, collapsed explorer and a second Narrative sidebar both
/// misrepresents ownership and removes roughly 400 px from its graph. This
/// shell restores the single navigation hierarchy visible in the north-star
/// while leaving Event data, Map-owned sources and Scene-owned projections to
/// the existing product route below it.
class EventBuilderV2ProductShell extends StatelessWidget {
  const EventBuilderV2ProductShell({
    super.key,
    required this.projectName,
    required this.workspace,
    required this.onOpenOverview,
    required this.onOpenStorylines,
    required this.onOpenMaps,
    required this.onOpenScenes,
    required this.onOpenEvents,
    required this.onOpenCinematics,
    required this.onOpenDialogues,
    required this.onOpenFacts,
    required this.onOpenWorldRules,
    required this.onValidate,
    this.onPreview,
    this.appMark,
    this.projectIsDirty = false,
  });

  final String projectName;
  final Widget workspace;
  final VoidCallback onOpenOverview;
  final VoidCallback onOpenStorylines;
  final VoidCallback onOpenMaps;
  final VoidCallback onOpenScenes;
  final VoidCallback onOpenEvents;
  final VoidCallback onOpenCinematics;
  final VoidCallback onOpenDialogues;
  final VoidCallback onOpenFacts;
  final VoidCallback onOpenWorldRules;
  final VoidCallback onValidate;
  final VoidCallback? onPreview;
  final Widget? appMark;
  final bool projectIsDirty;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final navigationWidth = _navigationWidth(viewportWidth);
        final businessStart = 8 + navigationWidth + 8;
        final rightMargin = viewportWidth == 1672 ? 9.0 : 8.0;

        return Semantics(
          key: eventBuilderV2ProductShellKey,
          container: true,
          label: 'PokeMap, Narrative Studio, Event Builder',
          child: ColoredBox(
            color: colors.chromeBackground,
            child: Column(
              children: [
                _ProductHeader(appMark: appMark),
                SizedBox(
                  height: 52,
                  child: ColoredBox(
                    color: colors.chromeBackground,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: businessStart,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 9, 8),
                            child: PokeMapCard(
                              key: eventBuilderV2ProductShellProjectKey,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 7),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      'assets/branding/'
                                      'pokemap_event_builder_project_thumb.png',
                                      width: 26,
                                      height: 26,
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      projectName.trim().isEmpty
                                          ? 'Projet PokeMap'
                                          : projectName.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    CupertinoIcons.chevron_down,
                                    size: 11,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            key: eventBuilderV2ProductShellContextBarKey,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: colors.topBarBackground,
                              border: Border(
                                bottom: BorderSide(color: colors.divider),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.house,
                                  size: 14,
                                  color: colors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Narrative Studio  /  Event Builder',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.brandPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (viewportWidth >= 1480) ...[
                                  PokeMapButton(
                                    key: const ValueKey(
                                      'event-builder-v2-new-storyline',
                                    ),
                                    onPressed: onOpenStorylines,
                                    // Match the reference toolbar's quiet
                                    // success treatment. A solid fill here
                                    // made the primary navigation compete with
                                    // the editor's actual save/validation cues.
                                    size: PokeMapButtonSize.compact,
                                    variant:
                                        PokeMapButtonVariant.successOutline,
                                    leading: const Icon(CupertinoIcons.add),
                                    child: const Text('Nouvelle storyline'),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                PokeMapButton(
                                  key: const ValueKey(
                                    'event-builder-v2-preview-project',
                                  ),
                                  onPressed: onPreview,
                                  size: PokeMapButtonSize.compact,
                                  variant: PokeMapButtonVariant.secondary,
                                  leading: const Icon(CupertinoIcons.eye),
                                  child: const Text('Aperçu'),
                                ),
                                const SizedBox(width: 8),
                                PokeMapButton(
                                  key: const ValueKey(
                                    'event-builder-v2-validate-project',
                                  ),
                                  onPressed: onValidate,
                                  size: PokeMapButtonSize.compact,
                                  variant: PokeMapButtonVariant.successOutline,
                                  leading: const Icon(
                                    CupertinoIcons.checkmark_shield,
                                  ),
                                  child: const Text('Valider'),
                                ),
                                const SizedBox(width: 8),
                                const PokeMapIconButton(
                                  key: ValueKey(
                                    'event-builder-v2-search-project',
                                  ),
                                  onPressed: null,
                                  tooltip: 'Recherche bientôt disponible',
                                  icon: Icon(CupertinoIcons.search),
                                  variant: PokeMapIconButtonVariant.soft,
                                  size: 36,
                                ),
                                const SizedBox(width: 5),
                                const PokeMapIconButton(
                                  key: ValueKey(
                                    'event-builder-v2-project-notifications',
                                  ),
                                  onPressed: null,
                                  tooltip: 'Notifications bientôt disponibles',
                                  icon: Icon(CupertinoIcons.bell),
                                  variant: PokeMapIconButtonVariant.soft,
                                  size: 36,
                                ),
                                const SizedBox(width: 5),
                                const PokeMapIconButton(
                                  key: ValueKey(
                                    'event-builder-v2-project-settings',
                                  ),
                                  onPressed: null,
                                  tooltip: 'Réglages bientôt disponibles',
                                  icon: Icon(CupertinoIcons.gear),
                                  variant: PokeMapIconButtonVariant.soft,
                                  size: 36,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 8,
                      right: rightMargin,
                      bottom: 22,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          key: eventBuilderV2ProductShellNavigationKey,
                          width: navigationWidth,
                          child: _ProductNavigation(
                            onOpenOverview: onOpenOverview,
                            onOpenStorylines: onOpenStorylines,
                            onOpenMaps: onOpenMaps,
                            onOpenScenes: onOpenScenes,
                            onOpenEvents: onOpenEvents,
                            onOpenCinematics: onOpenCinematics,
                            onOpenDialogues: onOpenDialogues,
                            onOpenFacts: onOpenFacts,
                            onOpenWorldRules: onOpenWorldRules,
                            onValidate: onValidate,
                            projectIsDirty: projectIsDirty,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            key: eventBuilderV2ProductShellWorkspaceKey,
                            child: workspace,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({this.appMark});

  final Widget? appMark;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Container(
      key: eventBuilderV2ProductShellHeaderKey,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.topBarBackground,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: appMark ??
                Image.asset(
                  'assets/branding/pokemap_event_builder_mark.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
          ),
          const SizedBox(width: 10),
          Text(
            'PokeMap',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          const PokeMapBadge(
            label: 'beta',
            variant: PokeMapBadgeVariant.info,
          ),
        ],
      ),
    );
  }
}

class _ProductNavigation extends StatelessWidget {
  const _ProductNavigation({
    required this.onOpenOverview,
    required this.onOpenStorylines,
    required this.onOpenMaps,
    required this.onOpenScenes,
    required this.onOpenEvents,
    required this.onOpenCinematics,
    required this.onOpenDialogues,
    required this.onOpenFacts,
    required this.onOpenWorldRules,
    required this.onValidate,
    required this.projectIsDirty,
  });

  final VoidCallback onOpenOverview;
  final VoidCallback onOpenStorylines;
  final VoidCallback onOpenMaps;
  final VoidCallback onOpenScenes;
  final VoidCallback onOpenEvents;
  final VoidCallback onOpenCinematics;
  final VoidCallback onOpenDialogues;
  final VoidCallback onOpenFacts;
  final VoidCallback onOpenWorldRules;
  final VoidCallback onValidate;
  final bool projectIsDirty;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-overview'),
            icon: CupertinoIcons.house,
            label: 'Aperçu',
            onTap: onOpenOverview,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-storylines'),
            icon: CupertinoIcons.rectangle_grid_1x2,
            label: 'Storylines',
            onTap: onOpenStorylines,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-maps'),
            icon: CupertinoIcons.map,
            label: 'Maps',
            onTap: onOpenMaps,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-scenes'),
            icon: CupertinoIcons.photo,
            label: 'Scenes',
            onTap: onOpenScenes,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-events'),
            icon: CupertinoIcons.bolt_horizontal_circle,
            label: 'Événements',
            selected: true,
            onTap: onOpenEvents,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-cinematics'),
            icon: CupertinoIcons.film,
            label: 'Cinématiques',
            onTap: onOpenCinematics,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-dialogues'),
            icon: CupertinoIcons.text_bubble,
            label: 'Dialogues',
            onTap: onOpenDialogues,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-facts'),
            icon: CupertinoIcons.doc_text,
            label: 'Facts',
            onTap: onOpenFacts,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-world-rules'),
            icon: CupertinoIcons.checkmark_shield,
            label: 'World Rules',
            onTap: onOpenWorldRules,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-validator'),
            icon: CupertinoIcons.shield,
            label: 'Validateur',
            onTap: onValidate,
            trailing: const PokeMapBadge(
              label: '3',
              variant: PokeMapBadgeVariant.success,
            ),
          ),
          const Spacer(),
          const PokeMapCard(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                Icon(CupertinoIcons.chart_bar, size: 12),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Project Health',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
                PokeMapStatusLabel(
                  label: 'Bon',
                  tone: PokeMapTone.success,
                  icon: CupertinoIcons.circle_fill,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                CupertinoIcons.circle_fill,
                size: 7,
                color: projectIsDirty ? colors.warning : colors.success,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  projectIsDirty
                      ? 'Modifications non enregistrées'
                      : 'Tous les changements enregistrés',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: PokeMapSidebarItem(
        icon: Icon(icon),
        label: label,
        compact: true,
        trailing: trailing,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}

double _navigationWidth(double viewportWidth) {
  if (viewportWidth >= 1672) return 191;
  if (viewportWidth >= 1480) return 176;
  return 168;
}
