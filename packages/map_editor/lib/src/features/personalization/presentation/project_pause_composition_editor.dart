import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';

class ProjectPauseCompositionEditor extends StatelessWidget {
  const ProjectPauseCompositionEditor({
    super.key,
    required this.profile,
    required this.onChanged,
  });

  final ProjectResponsivePauseCompositionProfile profile;
  final ValueChanged<ProjectResponsivePauseCompositionProfile?> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const PokeMapSectionHeader(
        title: 'Composition responsive',
        description:
            'Adaptez la densité, les repères et le panneau de détail à chaque format d’écran.',
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          PokeMapButton(
            key: const ValueKey<String>('pause-composition-preset-dense'),
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            onPressed: () => onChanged(_denseComposition),
            child: const Text('Compact'),
          ),
          PokeMapButton(
            key: const ValueKey<String>('pause-composition-preset-balanced'),
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            onPressed: () => onChanged(_balancedComposition),
            child: const Text('Confortable'),
          ),
          PokeMapButton(
            key: const ValueKey<String>('pause-composition-preset-showcase'),
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            onPressed: () => onChanged(_showcaseComposition),
            child: const Text('Mise en scène'),
          ),
          PokeMapButton(
            key: const ValueKey<String>('pause-composition-reset'),
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.ghost,
            onPressed: () => onChanged(null),
            child: const Text('Réglages du jeu'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _variant(
        context,
        id: 'compactPortrait',
        title: 'Portrait compact',
        description: 'Téléphone vertical et fenêtre étroite.',
        value: profile.compactPortrait,
      ),
      const SizedBox(height: 8),
      _variant(
        context,
        id: 'compactLandscape',
        title: 'Paysage compact',
        description: 'Téléphone horizontal et petite fenêtre.',
        value: profile.compactLandscape,
      ),
      const SizedBox(height: 8),
      _variant(
        context,
        id: 'expanded',
        title: 'Grand écran',
        description: 'Tablette, ordinateur et téléviseur.',
        value: profile.expanded,
      ),
    ],
  );

  Widget _variant(
    BuildContext context, {
    required String id,
    required String title,
    required String description,
    required ProjectPauseCompositionVariantProfile value,
  }) => PokeMapCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 2),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final fields = <Widget>[
              PokeMapDropdownField<ProjectPauseEntrySize>(
                key: ValueKey<String>('pause-composition-$id-entry-size'),
                label: 'Taille des entrées',
                value: value.entrySize,
                items: _entrySizes,
                onChanged: (next) =>
                    _replace(id, value.copyWith(entrySize: next)),
              ),
              PokeMapDropdownField<ProjectPauseEntrySpacing>(
                key: ValueKey<String>('pause-composition-$id-entry-spacing'),
                label: 'Espacement',
                value: value.entrySpacing,
                items: _entrySpacings,
                onChanged: (next) =>
                    _replace(id, value.copyWith(entrySpacing: next)),
              ),
            ];
            if (constraints.maxWidth < 430) {
              return Column(
                children: <Widget>[
                  fields.first,
                  const SizedBox(height: 10),
                  fields.last,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: fields.first),
                const SizedBox(width: 12),
                Expanded(child: fields.last),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        PokeMapToggleTile(
          key: ValueKey<String>('pause-composition-$id-show-title'),
          label: 'Afficher le titre du menu',
          value: value.showTitle,
          onChanged: (next) => _replace(id, value.copyWith(showTitle: next)),
        ),
        const SizedBox(height: 8),
        PokeMapToggleTile(
          key: ValueKey<String>('pause-composition-$id-show-hint'),
          label: 'Afficher l’aide de commande',
          value: value.showHint,
          onChanged: (next) => _replace(id, value.copyWith(showHint: next)),
        ),
        const SizedBox(height: 8),
        PokeMapToggleTile(
          key: ValueKey<String>('pause-composition-$id-show-detail'),
          label: 'Afficher le panneau de détail à la racine',
          value: value.showRootDetailPanel,
          onChanged: (next) =>
              _replace(id, value.copyWith(showRootDetailPanel: next)),
        ),
      ],
    ),
  );

  void _replace(String id, ProjectPauseCompositionVariantProfile value) {
    onChanged(switch (id) {
      'compactPortrait' => profile.copyWith(compactPortrait: value),
      'compactLandscape' => profile.copyWith(compactLandscape: value),
      'expanded' => profile.copyWith(expanded: value),
      _ => profile,
    });
  }
}

const _entrySizes = <PokeMapDropdownItem<ProjectPauseEntrySize>>[
  PokeMapDropdownItem(value: ProjectPauseEntrySize.compact, label: 'Compacte'),
  PokeMapDropdownItem(value: ProjectPauseEntrySize.regular, label: 'Normale'),
  PokeMapDropdownItem(value: ProjectPauseEntrySize.large, label: 'Grande'),
];

const _entrySpacings = <PokeMapDropdownItem<ProjectPauseEntrySpacing>>[
  PokeMapDropdownItem(value: ProjectPauseEntrySpacing.tight, label: 'Serré'),
  PokeMapDropdownItem(value: ProjectPauseEntrySpacing.regular, label: 'Normal'),
  PokeMapDropdownItem(value: ProjectPauseEntrySpacing.airy, label: 'Aéré'),
];

const _denseComposition = ProjectResponsivePauseCompositionProfile(
  compactPortrait: ProjectPauseCompositionVariantProfile(
    entrySize: ProjectPauseEntrySize.compact,
    entrySpacing: ProjectPauseEntrySpacing.tight,
    showHint: false,
    showRootDetailPanel: false,
  ),
  compactLandscape: ProjectPauseCompositionVariantProfile(
    entrySize: ProjectPauseEntrySize.compact,
    entrySpacing: ProjectPauseEntrySpacing.tight,
    showHint: false,
    showRootDetailPanel: false,
  ),
  expanded: ProjectPauseCompositionVariantProfile(
    entrySize: ProjectPauseEntrySize.compact,
    entrySpacing: ProjectPauseEntrySpacing.tight,
  ),
);

const _balancedComposition = ProjectResponsivePauseCompositionProfile();

const _showcaseComposition = ProjectResponsivePauseCompositionProfile(
  compactPortrait: ProjectPauseCompositionVariantProfile(
    entrySize: ProjectPauseEntrySize.large,
    entrySpacing: ProjectPauseEntrySpacing.airy,
    showRootDetailPanel: false,
  ),
  compactLandscape: ProjectPauseCompositionVariantProfile(
    entrySize: ProjectPauseEntrySize.regular,
    entrySpacing: ProjectPauseEntrySpacing.airy,
  ),
  expanded: ProjectPauseCompositionVariantProfile(
    entrySize: ProjectPauseEntrySize.large,
    entrySpacing: ProjectPauseEntrySpacing.airy,
  ),
);
