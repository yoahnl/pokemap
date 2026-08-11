import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/personalization_preview_fixtures.dart';
import '../project_typography_editor.dart';
import '../project_window_studio.dart';

enum PersonalizationBattlePreset { classic, compact, cinematic }

class PersonalizationBattleInspector extends StatelessWidget {
  const PersonalizationBattleInspector({
    super.key,
    required this.profile,
    required this.previewState,
    required this.onPreviewStateChanged,
    required this.onWindowsChanged,
    required this.onLayoutsChanged,
    required this.onImportCombatFont,
    required this.onUseSystemCombatFont,
    this.onCombatMetricsChanged,
    this.previewFamilies = const <ProjectTypographyRole, String>{},
  });

  final ProjectPresentationProfile profile;
  final PersonalizationBattlePreviewState previewState;
  final ValueChanged<PersonalizationBattlePreviewState> onPreviewStateChanged;
  final ValueChanged<ProjectPresentationWindowsProfile?> onWindowsChanged;
  final ValueChanged<ProjectPresentationLayoutsProfile?> onLayoutsChanged;
  final VoidCallback onImportCombatFont;
  final VoidCallback onUseSystemCombatFont;
  final ValueChanged<ProjectTypographyMetricsProfile>? onCombatMetricsChanged;
  final Map<ProjectTypographyRole, String> previewFamilies;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('personalization-battle-inspector'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const PokeMapSectionHeader(
        title: 'État de l’aperçu',
        description:
            'Testez les commandes, les capacités, le choix d’une cible et les messages longs.',
      ),
      const SizedBox(height: 8),
      PokeMapCard(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final state in PersonalizationBattlePreviewState.values)
              PokeMapButton(
                key: ValueKey<String>('battle-preview-state-${state.name}'),
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                isSelected: previewState == state,
                onPressed: () => onPreviewStateChanged(state),
                child: Text(_previewStateLabel(state)),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const PokeMapSectionHeader(
        title: 'Composition du menu de combat',
        description:
            'Choisissez une disposition prête à jouer, puis sa largeur à l’écran.',
      ),
      const SizedBox(height: 8),
      PokeMapCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Disposition', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final preset in PersonalizationBattlePreset.values)
                  PokeMapButton(
                    key: ValueKey<String>('battle-preset-${preset.name}'),
                    size: PokeMapButtonSize.small,
                    variant: PokeMapButtonVariant.secondary,
                    isSelected: _matchesPreset(preset),
                    onPressed: () =>
                        onLayoutsChanged(_applyPreset(profile, preset)),
                    child: Text(_presetLabel(preset)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Largeur', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final width in ProjectPresentationContentWidth.values)
                  PokeMapButton(
                    key: ValueKey<String>('battle-size-${width.name}'),
                    size: PokeMapButtonSize.small,
                    variant: PokeMapButtonVariant.secondary,
                    isSelected: _battle.regular.width == width,
                    onPressed: () =>
                        onLayoutsChanged(_applyWidth(profile, width)),
                    child: Text(_widthLabel(width)),
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      ProjectWindowStudio(
        profile: _battleWindows(profile.windows),
        fixedRole: ProjectWindowRole.battle,
        onChanged: onWindowsChanged,
      ),
      const SizedBox(height: 18),
      ProjectTypographyEditor(
        profile: profile.typography ?? const ProjectTypographyProfile(),
        previewFamilies: previewFamilies,
        fixedRole: ProjectTypographyRole.combat,
        onImportRole: (_) => onImportCombatFont(),
        onUseSystemFont: (_) => onUseSystemCombatFont(),
        onMetricsChanged: onCombatMetricsChanged == null
            ? null
            : (_, metrics) => onCombatMetricsChanged!(metrics),
      ),
    ],
  );

  ProjectPresentationLayoutsProfile get _layouts =>
      profile.layouts ??
      suggestedProjectPresentationLayouts(profile.branding.layoutVariant);

  ProjectResponsiveSurfaceLayoutProfile get _battle =>
      _layouts.battle ??
      suggestedProjectPresentationLayouts(
        profile.branding.layoutVariant,
      ).battle!;

  bool _matchesPreset(PersonalizationBattlePreset preset) {
    final battle = _battle;
    return switch (preset) {
      PersonalizationBattlePreset.classic =>
        battle.compact.slot == ProjectPresentationLayoutSlot.bottomCenter &&
            battle.regular.slot == ProjectPresentationLayoutSlot.bottomCenter &&
            battle.expanded.slot == ProjectPresentationLayoutSlot.bottomCenter,
      PersonalizationBattlePreset.compact =>
        battle.compact.spacing == ProjectPresentationSpacing.compact &&
            battle.regular.spacing == ProjectPresentationSpacing.compact &&
            battle.expanded.spacing == ProjectPresentationSpacing.compact &&
            battle.regular.width == ProjectPresentationContentWidth.narrow,
      PersonalizationBattlePreset.cinematic =>
        battle.compact.slot == ProjectPresentationLayoutSlot.bottomCenter &&
            battle.regular.slot == ProjectPresentationLayoutSlot.right &&
            battle.expanded.slot == ProjectPresentationLayoutSlot.right,
    };
  }
}

ProjectPresentationLayoutsProfile _applyPreset(
  ProjectPresentationProfile profile,
  PersonalizationBattlePreset preset,
) {
  final layouts =
      profile.layouts ??
      suggestedProjectPresentationLayouts(profile.branding.layoutVariant);
  final current =
      layouts.battle ??
      suggestedProjectPresentationLayouts(
        profile.branding.layoutVariant,
      ).battle!;
  final battle = switch (preset) {
    PersonalizationBattlePreset.classic => _replaceBattleVariants(
      current,
      slot: ProjectPresentationLayoutSlot.bottomCenter,
      spacing: ProjectPresentationSpacing.normal,
      width: ProjectPresentationContentWidth.wide,
    ),
    PersonalizationBattlePreset.compact => _replaceBattleVariants(
      current,
      slot: ProjectPresentationLayoutSlot.bottomCenter,
      spacing: ProjectPresentationSpacing.compact,
      width: ProjectPresentationContentWidth.narrow,
    ),
    PersonalizationBattlePreset.cinematic =>
      ProjectResponsiveSurfaceLayoutProfile(
        compact: current.compact.copyWith(
          slot: ProjectPresentationLayoutSlot.bottomCenter,
          spacing: ProjectPresentationSpacing.normal,
        ),
        regular: current.regular.copyWith(
          slot: ProjectPresentationLayoutSlot.right,
          spacing: ProjectPresentationSpacing.normal,
        ),
        expanded: current.expanded.copyWith(
          slot: ProjectPresentationLayoutSlot.right,
          spacing: ProjectPresentationSpacing.airy,
        ),
      ),
  };
  return layouts.copyWith(battle: battle);
}

ProjectPresentationLayoutsProfile _applyWidth(
  ProjectPresentationProfile profile,
  ProjectPresentationContentWidth width,
) {
  final layouts =
      profile.layouts ??
      suggestedProjectPresentationLayouts(profile.branding.layoutVariant);
  final current =
      layouts.battle ??
      suggestedProjectPresentationLayouts(
        profile.branding.layoutVariant,
      ).battle!;
  return layouts.copyWith(
    battle: ProjectResponsiveSurfaceLayoutProfile(
      compact: current.compact.copyWith(width: width),
      regular: current.regular.copyWith(width: width),
      expanded: current.expanded.copyWith(width: width),
    ),
  );
}

ProjectResponsiveSurfaceLayoutProfile _replaceBattleVariants(
  ProjectResponsiveSurfaceLayoutProfile profile, {
  required ProjectPresentationLayoutSlot slot,
  required ProjectPresentationSpacing spacing,
  required ProjectPresentationContentWidth width,
}) => ProjectResponsiveSurfaceLayoutProfile(
  compact: profile.compact.copyWith(slot: slot, spacing: spacing, width: width),
  regular: profile.regular.copyWith(slot: slot, spacing: spacing, width: width),
  expanded: profile.expanded.copyWith(
    slot: slot,
    spacing: spacing,
    width: width,
  ),
);

ProjectPresentationWindowsProfile _battleWindows(
  ProjectPresentationWindowsProfile? authored,
) {
  final windows = authored ?? legacyProjectPresentationWindows;
  if (windows.battleStyleId != null) return windows;
  final ids = windows.styles.map((style) => style.id).toSet();
  var id = 'battle';
  var suffix = 2;
  while (ids.contains(id)) {
    id = 'battle-$suffix';
    suffix += 1;
  }
  final style = windows
      .resolve(ProjectWindowRole.standard)
      .copyWith(id: id, fillToken: 'battleHudSurface');
  return windows.copyWith(
    styles: <ProjectWindowStyleProfile>[...windows.styles, style],
    battleStyleId: id,
  );
}

String _previewStateLabel(PersonalizationBattlePreviewState state) =>
    switch (state) {
      PersonalizationBattlePreviewState.commands => 'Commandes',
      PersonalizationBattlePreviewState.moves => 'Capacités',
      PersonalizationBattlePreviewState.target => 'Cible',
      PersonalizationBattlePreviewState.message => 'Message',
    };

String _presetLabel(PersonalizationBattlePreset preset) => switch (preset) {
  PersonalizationBattlePreset.classic => 'Classique',
  PersonalizationBattlePreset.compact => 'Compact',
  PersonalizationBattlePreset.cinematic => 'Cinématique',
};

String _widthLabel(ProjectPresentationContentWidth width) => switch (width) {
  ProjectPresentationContentWidth.narrow => 'Étroite',
  ProjectPresentationContentWidth.comfortable => 'Confortable',
  ProjectPresentationContentWidth.wide => 'Large',
};
