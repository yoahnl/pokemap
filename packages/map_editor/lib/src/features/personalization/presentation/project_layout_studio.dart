import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';

class ProjectLayoutStudio extends StatefulWidget {
  const ProjectLayoutStudio({
    super.key,
    required this.profile,
    required this.brandingLayoutVariant,
    required this.onChanged,
  });

  final ProjectPresentationLayoutsProfile? profile;
  final String brandingLayoutVariant;
  final ValueChanged<ProjectPresentationLayoutsProfile?> onChanged;

  @override
  State<ProjectLayoutStudio> createState() => _ProjectLayoutStudioState();
}

class _ProjectLayoutStudioState extends State<ProjectLayoutStudio> {
  ProjectPresentationSurfaceRole _surface =
      ProjectPresentationSurfaceRole.title;
  ProjectPresentationBreakpoint _breakpoint =
      ProjectPresentationBreakpoint.regular;

  ProjectPresentationLayoutsProfile get _profile =>
      widget.profile ??
      suggestedProjectPresentationLayouts(widget.brandingLayoutVariant);

  @override
  Widget build(BuildContext context) {
    final responsive = _profile.resolve(_surface);
    final variant = responsive.resolve(_breakpoint);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Composition responsive',
          description:
              'Choisissez où placer les contenus selon l’espace disponible. Les actions essentielles restent toujours visibles et dans le même ordre.',
        ),
        const SizedBox(height: 8),
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Surface à organiser',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final surface in ProjectPresentationSurfaceRole.values)
                    PokeMapButton(
                      key: ValueKey<String>('layout-surface-${surface.name}'),
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.secondary,
                      isSelected: _surface == surface,
                      onPressed: () => setState(() => _surface = surface),
                      child: Text(_surfaceLabel(surface)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Compositions prêtes à jouer',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final preset in _presets(_surface))
                    PokeMapButton(
                      key: ValueKey<String>('layout-preset-${preset.$1}'),
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.secondary,
                      leading: const Icon(Icons.auto_awesome_outlined),
                      onPressed: () => _applyPreset(preset.$1),
                      child: Text(preset.$2),
                    ),
                  PokeMapButton(
                    key: const ValueKey<String>('layout-reset-project'),
                    size: PokeMapButtonSize.small,
                    variant: PokeMapButtonVariant.ghost,
                    leading: const Icon(Icons.restart_alt_rounded),
                    onPressed: () => widget.onChanged(null),
                    child: const Text('Réglages du lecteur'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Taille simulée',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final breakpoint in ProjectPresentationBreakpoint.values)
                    PokeMapButton(
                      key: ValueKey<String>(
                        'layout-breakpoint-${breakpoint.name}',
                      ),
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.secondary,
                      isSelected: _breakpoint == breakpoint,
                      onPressed: () => setState(() => _breakpoint = breakpoint),
                      child: Text(_breakpointLabel(breakpoint)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Position du bloc',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final slot in projectPresentationLayoutSlotsFor(
                    _surface,
                    _breakpoint,
                  ))
                    PokeMapButton(
                      key: ValueKey<String>('layout-slot-${slot.name}'),
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.secondary,
                      isSelected: variant.slot == slot,
                      onPressed: () => _replaceVariant(
                        responsive,
                        variant.copyWith(slot: slot),
                      ),
                      child: Text(_slotLabel(slot)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _choiceRow<ProjectPresentationContentWidth>(
                context: context,
                title: 'Largeur',
                keyPrefix: 'layout-width',
                values: ProjectPresentationContentWidth.values,
                selected: variant.width,
                label: _widthLabel,
                onSelected: (value) =>
                    _replaceVariant(responsive, variant.copyWith(width: value)),
              ),
              const SizedBox(height: 16),
              _choiceRow<ProjectPresentationSpacing>(
                context: context,
                title: 'Espacement entre les blocs',
                keyPrefix: 'layout-spacing',
                values: ProjectPresentationSpacing.values,
                selected: variant.spacing,
                label: _spacingLabel,
                onSelected: (value) => _replaceVariant(
                  responsive,
                  variant.copyWith(spacing: value),
                ),
              ),
              const SizedBox(height: 16),
              _choiceRow<ProjectPresentationScreenMargin>(
                context: context,
                title: 'Marge autour du contenu',
                keyPrefix: 'layout-margin',
                values: ProjectPresentationScreenMargin.values,
                selected: variant.screenMargin,
                label: _marginLabel,
                onSelected: (value) => _replaceVariant(
                  responsive,
                  variant.copyWith(screenMargin: value),
                ),
              ),
              if (projectPresentationSecondaryElementsFor(
                _surface,
              ).isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  'Éléments secondaires',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final element in projectPresentationSecondaryElementsFor(
                  _surface,
                ))
                  PokeMapToggleTile(
                    key: ValueKey<String>('layout-secondary-${element.name}'),
                    label: _secondaryLabel(element),
                    value: variant.visibleSecondaryElements.contains(element),
                    onChanged: (visible) => _replaceVariant(
                      responsive,
                      variant.copyWith(
                        visibleSecondaryElements:
                            <ProjectPresentationSecondaryElement>{
                                  ...variant.visibleSecondaryElements,
                                  if (visible) element,
                                }
                                .where(
                                  (candidate) =>
                                      visible || candidate != element,
                                )
                                .toList(growable: false),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _choiceRow<T extends Enum>({
    required BuildContext context,
    required String title,
    required String keyPrefix,
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onSelected,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final value in values)
            PokeMapButton(
              key: ValueKey<String>('$keyPrefix-${value.name}'),
              size: PokeMapButtonSize.small,
              variant: PokeMapButtonVariant.secondary,
              isSelected: selected == value,
              onPressed: () => onSelected(value),
              child: Text(label(value)),
            ),
        ],
      ),
    ],
  );

  void _replaceVariant(
    ProjectResponsiveSurfaceLayoutProfile responsive,
    ProjectSurfaceLayoutVariant variant,
  ) {
    final replacement = switch (_breakpoint) {
      ProjectPresentationBreakpoint.compact => responsive.copyWith(
        compact: variant,
      ),
      ProjectPresentationBreakpoint.regular => responsive.copyWith(
        regular: variant,
      ),
      ProjectPresentationBreakpoint.expanded => responsive.copyWith(
        expanded: variant,
      ),
    };
    widget.onChanged(_replaceSurface(_profile, _surface, replacement));
  }

  void _applyPreset(String id) {
    final base = suggestedProjectPresentationLayouts(
      id == 'cinematic' ? 'cinematic' : widget.brandingLayoutVariant,
    );
    final replacement = switch ((_surface, id)) {
      (ProjectPresentationSurfaceRole.title, 'cinematic') => base.title,
      (ProjectPresentationSurfaceRole.title, 'sidebar') => base.title.copyWith(
        regular: base.title.regular.copyWith(
          slot: ProjectPresentationLayoutSlot.leftPane,
        ),
        expanded: base.title.expanded.copyWith(
          slot: ProjectPresentationLayoutSlot.leftPane,
        ),
      ),
      (ProjectPresentationSurfaceRole.title, _) =>
        suggestedProjectPresentationLayouts('standard').title,
      (ProjectPresentationSurfaceRole.pauseMenu, 'centered') =>
        base.pauseMenu.copyWith(
          regular: base.pauseMenu.regular.copyWith(
            slot: ProjectPresentationLayoutSlot.center,
          ),
          expanded: base.pauseMenu.expanded.copyWith(
            slot: ProjectPresentationLayoutSlot.center,
          ),
        ),
      (ProjectPresentationSurfaceRole.pauseMenu, 'sidebar') =>
        base.pauseMenu.copyWith(
          regular: base.pauseMenu.regular.copyWith(
            slot: ProjectPresentationLayoutSlot.left,
          ),
          expanded: base.pauseMenu.expanded.copyWith(
            slot: ProjectPresentationLayoutSlot.right,
          ),
        ),
      (ProjectPresentationSurfaceRole.pauseMenu, _) => base.pauseMenu,
      (ProjectPresentationSurfaceRole.dialogue, 'top') =>
        base.dialogue.copyWith(
          compact: base.dialogue.compact.copyWith(
            slot: ProjectPresentationLayoutSlot.topCenter,
          ),
          regular: base.dialogue.regular.copyWith(
            slot: ProjectPresentationLayoutSlot.topCenter,
          ),
          expanded: base.dialogue.expanded.copyWith(
            slot: ProjectPresentationLayoutSlot.topCenter,
          ),
        ),
      (ProjectPresentationSurfaceRole.dialogue, 'wide') =>
        base.dialogue.copyWith(
          compact: base.dialogue.compact.copyWith(
            width: ProjectPresentationContentWidth.wide,
          ),
          regular: base.dialogue.regular.copyWith(
            width: ProjectPresentationContentWidth.wide,
          ),
          expanded: base.dialogue.expanded.copyWith(
            width: ProjectPresentationContentWidth.wide,
          ),
        ),
      (ProjectPresentationSurfaceRole.dialogue, _) => base.dialogue,
    };
    widget.onChanged(_replaceSurface(_profile, _surface, replacement));
  }
}

ProjectPresentationLayoutsProfile _replaceSurface(
  ProjectPresentationLayoutsProfile profile,
  ProjectPresentationSurfaceRole surface,
  ProjectResponsiveSurfaceLayoutProfile replacement,
) => switch (surface) {
  ProjectPresentationSurfaceRole.title => profile.copyWith(title: replacement),
  ProjectPresentationSurfaceRole.pauseMenu => profile.copyWith(
    pauseMenu: replacement,
  ),
  ProjectPresentationSurfaceRole.dialogue => profile.copyWith(
    dialogue: replacement,
  ),
};

List<(String, String)> _presets(ProjectPresentationSurfaceRole surface) =>
    switch (surface) {
      ProjectPresentationSurfaceRole.title => const <(String, String)>[
        ('classic', 'Classique centré'),
        ('cinematic', 'Cinématique en bas'),
        ('sidebar', 'Volet latéral'),
      ],
      ProjectPresentationSurfaceRole.pauseMenu => const <(String, String)>[
        ('adaptive', 'Adaptatif PokeMap'),
        ('centered', 'Panneau centré'),
        ('sidebar', 'Volet latéral'),
      ],
      ProjectPresentationSurfaceRole.dialogue => const <(String, String)>[
        ('bottom', 'Bas centré'),
        ('wide', 'Bas étendu'),
        ('top', 'Haut centré'),
      ],
    };

String _surfaceLabel(ProjectPresentationSurfaceRole surface) =>
    switch (surface) {
      ProjectPresentationSurfaceRole.title => 'Écran titre',
      ProjectPresentationSurfaceRole.pauseMenu => 'Menu Pause',
      ProjectPresentationSurfaceRole.dialogue => 'Dialogue',
    };

String _breakpointLabel(ProjectPresentationBreakpoint breakpoint) =>
    switch (breakpoint) {
      ProjectPresentationBreakpoint.compact => 'Compact',
      ProjectPresentationBreakpoint.regular => 'Standard',
      ProjectPresentationBreakpoint.expanded => 'Grand écran',
    };

String _slotLabel(ProjectPresentationLayoutSlot slot) => switch (slot) {
  ProjectPresentationLayoutSlot.center => 'Centré',
  ProjectPresentationLayoutSlot.bottomCenter => 'En bas',
  ProjectPresentationLayoutSlot.bottomLeft => 'En bas à gauche',
  ProjectPresentationLayoutSlot.leftPane => 'Volet gauche',
  ProjectPresentationLayoutSlot.fullScreen => 'Plein écran',
  ProjectPresentationLayoutSlot.left => 'À gauche',
  ProjectPresentationLayoutSlot.right => 'À droite',
  ProjectPresentationLayoutSlot.topCenter => 'En haut',
};

String _widthLabel(ProjectPresentationContentWidth width) => switch (width) {
  ProjectPresentationContentWidth.narrow => 'Étroite',
  ProjectPresentationContentWidth.comfortable => 'Confortable',
  ProjectPresentationContentWidth.wide => 'Large',
};

String _spacingLabel(ProjectPresentationSpacing spacing) => switch (spacing) {
  ProjectPresentationSpacing.compact => 'Compact',
  ProjectPresentationSpacing.normal => 'Normal',
  ProjectPresentationSpacing.airy => 'Aéré',
};

String _marginLabel(ProjectPresentationScreenMargin margin) => switch (margin) {
  ProjectPresentationScreenMargin.none => 'Aucune',
  ProjectPresentationScreenMargin.compact => 'Discrète',
  ProjectPresentationScreenMargin.comfortable => 'Confortable',
};

String _secondaryLabel(ProjectPresentationSecondaryElement element) =>
    switch (element) {
      ProjectPresentationSecondaryElement.titleLogo => 'Logo',
      ProjectPresentationSecondaryElement.titleAuthor => 'Auteur',
      ProjectPresentationSecondaryElement.titleDescription => 'Description',
      ProjectPresentationSecondaryElement.pauseGameTitle => 'Nom du jeu',
      ProjectPresentationSecondaryElement.dialoguePortrait => 'Portrait',
    };
