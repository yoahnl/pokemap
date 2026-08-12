import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../../ui/design_system/design_system.dart';
import '../../project_theme_token_dialog.dart';

class BattlePanelSection extends StatelessWidget {
  const BattlePanelSection({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.profile,
    required this.inheritedTheme,
    required this.onChanged,
  });

  final String id;
  final String title;
  final String description;
  final ProjectBattlePanelPresentationProfile profile;
  final ProjectSemanticThemeProfile inheritedTheme;
  final ValueChanged<ProjectBattlePanelPresentationProfile> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    key: ValueKey<String>('battle-$id-editor'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      PokeMapSectionHeader(title: title, description: description),
      const SizedBox(height: 8),
      PokeMapCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final layout in ProjectBattleCommandLayout.values)
                  PokeMapButton(
                    key: ValueKey<String>('battle-$id-layout-${layout.name}'),
                    size: PokeMapButtonSize.small,
                    variant: PokeMapButtonVariant.secondary,
                    isSelected: profile.layout == layout,
                    onPressed: () =>
                        onChanged(profile.copyWith(layout: layout)),
                    child: Text(_layoutLabel(layout)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            PokeMapGuidedSlider(
              key: ValueKey<String>('battle-$id-columns'),
              label: 'Colonnes',
              value: profile.columns,
              min: 1,
              max: 4,
              onChanged: (value) => onChanged(profile.copyWith(columns: value)),
            ),
            const SizedBox(height: 12),
            PokeMapDropdownField<ProjectWindowShape>(
              label: 'Forme du panneau',
              value: profile.shape,
              items: <PokeMapDropdownItem<ProjectWindowShape>>[
                for (final shape in ProjectWindowShape.values)
                  if (shape != ProjectWindowShape.speech)
                    PokeMapDropdownItem<ProjectWindowShape>(
                      value: shape,
                      label: _shapeLabel(shape),
                    ),
              ],
              onChanged: (value) => onChanged(profile.copyWith(shape: value)),
            ),
            const SizedBox(height: 12),
            PokeMapGuidedSlider(
              key: ValueKey<String>('battle-$id-padding'),
              label: 'Marge intérieure',
              value: profile.padding.round(),
              min: 4,
              max: 32,
              onChanged: (value) =>
                  onChanged(profile.copyWith(padding: value.toDouble())),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final color in _PanelColor.values)
            PokeMapButton(
              key: ValueKey<String>('battle-$id-color-${color.name}'),
              size: PokeMapButtonSize.small,
              variant: PokeMapButtonVariant.secondary,
              onPressed: () => _editColor(context, color),
              leading: const Icon(Icons.palette_outlined),
              child: Text(_colorLabel(color)),
            ),
        ],
      ),
    ],
  );

  Future<void> _editColor(BuildContext context, _PanelColor color) async {
    final current = _value(color) ?? _inherited(color);
    final value = await showProjectThemeTokenDialog(
      context: context,
      tokenLabel: _colorLabel(color).toLowerCase(),
      currentValue: current,
      impactDescription: 'Cette couleur affecte uniquement le panneau $title.',
    );
    if (value == null || value == current) return;
    onChanged(switch (color) {
      _PanelColor.surface => profile.copyWith(surfaceColor: value),
      _PanelColor.border => profile.copyWith(borderColor: value),
      _PanelColor.text => profile.copyWith(textColor: value),
      _PanelColor.selection => profile.copyWith(selectionColor: value),
    });
  }

  String? _value(_PanelColor color) => switch (color) {
    _PanelColor.surface => profile.surfaceColor,
    _PanelColor.border => profile.borderColor,
    _PanelColor.text => profile.textColor,
    _PanelColor.selection => profile.selectionColor,
  };

  String _inherited(_PanelColor color) => switch (color) {
    _PanelColor.surface => inheritedTheme.battleHudSurface,
    _PanelColor.border => inheritedTheme.outline,
    _PanelColor.text => inheritedTheme.textPrimary,
    _PanelColor.selection => inheritedTheme.primary,
  };
}

enum _PanelColor { surface, border, text, selection }

String _layoutLabel(ProjectBattleCommandLayout layout) => switch (layout) {
  ProjectBattleCommandLayout.grid => 'Grille',
  ProjectBattleCommandLayout.list => 'Liste',
  ProjectBattleCommandLayout.radial => 'Radial',
};

String _shapeLabel(ProjectWindowShape shape) => switch (shape) {
  ProjectWindowShape.rectangle => 'Rectangle',
  ProjectWindowShape.rounded => 'Arrondie',
  ProjectWindowShape.capsule => 'Capsule',
  ProjectWindowShape.cutCorner => 'Coins coupés',
  ProjectWindowShape.speech => 'Bulle',
};

String _colorLabel(_PanelColor color) => switch (color) {
  _PanelColor.surface => 'Fond',
  _PanelColor.border => 'Contour',
  _PanelColor.text => 'Texte',
  _PanelColor.selection => 'Sélection',
};
