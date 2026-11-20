import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:avelune_studio/presentation/shell/studio_rail.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

class ProjectHomePage extends StatelessWidget {
  const ProjectHomePage({
    super.key,
    required this.projectName,
    required this.maps,
    required this.activeMap,
    required this.onOpenMap,
    required this.onSection,
    required this.onClose,
  });

  final String projectName;
  final List<ProjectMapEntry> maps;
  final ProjectMapEntry? activeMap;
  final ValueChanged<ProjectMapEntry>? onOpenMap;
  final ValueChanged<StudioRailSection> onSection;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = activeMap;
    return Center(
      key: const ValueKey('studio-project-home'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudioPageHeader(
              title: projectName,
              description: l10n.railHome,
              prominent: true,
              compact: true,
              alignActionsToEnd: true,
              actions: [
                StudioButton(
                  key: const ValueKey('studio-project-home-close'),
                  label: l10n.homeCloseProject,
                  icon: Icons.logout,
                  variant: StudioButtonVariant.secondary,
                  onPressed: onClose,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.l),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  spacing: StudioSpacing.m,
                  runSpacing: StudioSpacing.s,
                  children: [
                    StudioButton(
                      label: active == null
                          ? l10n.railMapBuilder
                          : l10n.homeResumeMap,
                      icon: Icons.map_outlined,
                      onPressed: () => onSection(StudioRailSection.map),
                    ),
                    _shortcut(
                      l10n.railResources,
                      Icons.view_in_ar_outlined,
                      StudioRailSection.resources,
                    ),
                    _shortcut(
                      l10n.railStory,
                      Icons.menu_book_outlined,
                      StudioRailSection.story,
                    ),
                    _shortcut(
                      l10n.railPokemon,
                      Icons.catching_pokemon,
                      StudioRailSection.pokemon,
                    ),
                  ],
                ),
              ),
            ),
            StudioPageHeader.section(title: l10n.homeProjectMaps),
            Expanded(
              child: maps.isEmpty
                  ? StudioEmptyState(
                      title: l10n.homeNoMaps,
                      icon: Icons.map_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(StudioSpacing.l),
                      itemCount: maps.length,
                      itemBuilder: (context, index) {
                        final map = maps[index];
                        return StudioNavigationEntry(
                          label: map.name,
                          icon: Icons.map_outlined,
                          selected: map.id == active?.id,
                          onTap: onOpenMap == null
                              ? null
                              : () => onOpenMap!(map),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shortcut(String label, IconData icon, StudioRailSection section) =>
      StudioButton(
        label: label,
        icon: icon,
        variant: StudioButtonVariant.secondary,
        onPressed: () => onSection(section),
      );
}
