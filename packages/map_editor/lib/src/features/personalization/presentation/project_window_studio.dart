import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/project_window_style_presets.dart';

class ProjectWindowStudio extends StatefulWidget {
  const ProjectWindowStudio({
    super.key,
    required this.profile,
    required this.onChanged,
    this.simplePresetsOnly = false,
    this.fixedRole,
  });

  final ProjectPresentationWindowsProfile profile;
  final ValueChanged<ProjectPresentationWindowsProfile?> onChanged;
  final bool simplePresetsOnly;
  final ProjectWindowRole? fixedRole;

  @override
  State<ProjectWindowStudio> createState() => _ProjectWindowStudioState();
}

class _ProjectWindowStudioState extends State<ProjectWindowStudio> {
  _WindowTarget _target = _WindowTarget.pause;

  @override
  Widget build(BuildContext context) {
    if (widget.simplePresetsOnly) {
      return _SimpleWindowShapePresets(
        profile: widget.profile,
        onChanged: widget.onChanged,
      );
    }
    final role = widget.fixedRole ?? _target.role;
    final style = widget.profile.resolve(role);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: switch (widget.fixedRole) {
            ProjectWindowRole.pauseMenu => 'Apparence du menu Pause',
            ProjectWindowRole.dialogue => 'Apparence de la bulle',
            ProjectWindowRole.battle => 'Apparence du menu de combat',
            _ => 'Fenêtres du jeu',
          },
          description: switch (widget.fixedRole) {
            ProjectWindowRole.pauseMenu =>
              'Réglez la forme, les couleurs, les contours et la profondeur du menu.',
            ProjectWindowRole.dialogue =>
              'Réglez la forme, les couleurs, le contour et la profondeur de la bulle.',
            ProjectWindowRole.battle =>
              'Réglez la forme, les couleurs, le contour et la profondeur des commandes de combat.',
            _ =>
              'Façonnez les cadres du menu Pause et des dialogues. Le grand aperçu reflète chaque changement immédiatement.',
          },
        ),
        const SizedBox(height: 8),
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Styles prêts à jouer',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Choisissez une base, puis ajustez-la sans manipuler de valeurs techniques.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final preset in projectWindowStylePresets)
                    PokeMapButton(
                      key: ValueKey<String>('window-preset-${preset.id}'),
                      onPressed: () => _applyPreset(preset.profile),
                      variant: PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.small,
                      leading: const Icon(Icons.auto_awesome_outlined),
                      child: Text(preset.label),
                    ),
                  PokeMapButton(
                    key: const ValueKey<String>('window-reset-project'),
                    onPressed: _reset,
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    leading: const Icon(Icons.restart_alt_rounded),
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
              if (widget.fixedRole == null) ...<Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: PokeMapSegmentedTabs(
                    tabs: <PokeMapSegmentedTab>[
                      for (final target in _WindowTarget.values)
                        PokeMapSegmentedTab(
                          key: ValueKey<String>('window-target-${target.name}'),
                          label: target.label,
                          icon: target.icon,
                          selected: _target == target,
                          onTap: () => setState(() => _target = target),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 620 ? 2 : 1;
                  final width = columns == 2
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      _field<String>(
                        width: width,
                        key: 'fill',
                        label: 'Surface',
                        value: style.fillToken,
                        items: _fillItems,
                        onChanged: (value) =>
                            _replace(style.copyWith(fillToken: value)),
                      ),
                      _field<double>(
                        width: width,
                        key: 'fill-opacity',
                        label: 'Opacité de la fenêtre',
                        value: style.fillOpacity,
                        items: const <PokeMapDropdownItem<double>>[
                          PokeMapDropdownItem(value: 1, label: 'Opaque'),
                          PokeMapDropdownItem(value: .9, label: 'Très légère'),
                          PokeMapDropdownItem(value: .8, label: 'Légère'),
                          PokeMapDropdownItem(value: .65, label: 'Équilibrée'),
                          PokeMapDropdownItem(value: .5, label: 'Transparente'),
                          PokeMapDropdownItem(
                            value: .35,
                            label: 'Très transparente',
                          ),
                        ],
                        onChanged: (value) =>
                            _replace(style.copyWith(fillOpacity: value)),
                      ),
                      _field<String>(
                        width: width,
                        key: 'border-color',
                        label: 'Couleur du contour',
                        value: style.borderToken,
                        items: _borderItems,
                        onChanged: (value) =>
                            _replace(style.copyWith(borderToken: value)),
                      ),
                      _field<int>(
                        width: width,
                        key: 'border-width',
                        label: 'Épaisseur du contour',
                        value: style.borderWidth,
                        items: _intItems(<int>[0, 1, 2, 3, 4], suffix: ' px'),
                        onChanged: (value) =>
                            _replace(style.copyWith(borderWidth: value)),
                      ),
                      _field<ProjectWindowShape>(
                        width: width,
                        key: 'shape',
                        label: 'Silhouette',
                        value: style.shape,
                        items: _shapeItems(role),
                        onChanged: (value) =>
                            _replace(style.copyWith(shape: value)),
                      ),
                      _field<int>(
                        width: width,
                        key: 'corner-radius',
                        label: 'Forme des angles',
                        value: style.cornerRadius,
                        items: const <PokeMapDropdownItem<int>>[
                          PokeMapDropdownItem(value: 0, label: 'Carrés'),
                          PokeMapDropdownItem(value: 8, label: 'Discrets'),
                          PokeMapDropdownItem(value: 12, label: 'Adoucis'),
                          PokeMapDropdownItem(value: 16, label: 'Arrondis'),
                          PokeMapDropdownItem(
                            value: 24,
                            label: 'Très arrondis',
                          ),
                          PokeMapDropdownItem(value: 32, label: 'Maximaux'),
                        ],
                        onChanged: (value) =>
                            _replace(style.copyWith(cornerRadius: value)),
                      ),
                      _field<int>(
                        width: width,
                        key: 'content-padding',
                        label: 'Espace intérieur',
                        value: style.contentPadding,
                        items: const <PokeMapDropdownItem<int>>[
                          PokeMapDropdownItem(value: 8, label: 'Minimal'),
                          PokeMapDropdownItem(value: 12, label: 'Compact'),
                          PokeMapDropdownItem(value: 16, label: 'Confortable'),
                          PokeMapDropdownItem(value: 20, label: 'Aéré'),
                          PokeMapDropdownItem(value: 24, label: 'Généreux'),
                          PokeMapDropdownItem(
                            value: 32,
                            label: 'Très généreux',
                          ),
                        ],
                        onChanged: (value) =>
                            _replace(style.copyWith(contentPadding: value)),
                      ),
                      _field<int>(
                        width: width,
                        key: 'shadow',
                        label: 'Profondeur',
                        value: style.shadowElevation,
                        items: const <PokeMapDropdownItem<int>>[
                          PokeMapDropdownItem(value: 0, label: 'Plate'),
                          PokeMapDropdownItem(value: 2, label: 'Légère'),
                          PokeMapDropdownItem(value: 4, label: 'Douce'),
                          PokeMapDropdownItem(value: 8, label: 'Marquée'),
                          PokeMapDropdownItem(value: 12, label: 'Profonde'),
                          PokeMapDropdownItem(
                            value: 16,
                            label: 'Très profonde',
                          ),
                        ],
                        onChanged: (value) =>
                            _replace(style.copyWith(shadowElevation: value)),
                      ),
                      if (role == ProjectWindowRole.pauseMenu)
                        _field<double>(
                          width: width,
                          key: 'backdrop',
                          label: 'Visibilité du jeu derrière Pause',
                          value: widget.profile.pauseBackdropOpacity,
                          items: const <PokeMapDropdownItem<double>>[
                            PokeMapDropdownItem(
                              value: .35,
                              label: 'Très visible',
                            ),
                            PokeMapDropdownItem(value: .5, label: 'Visible'),
                            PokeMapDropdownItem(
                              value: .65,
                              label: 'Équilibrée',
                            ),
                            PokeMapDropdownItem(value: .7, label: 'Classique'),
                            PokeMapDropdownItem(value: .8, label: 'Atténuée'),
                            PokeMapDropdownItem(
                              value: .9,
                              label: 'Très atténuée',
                            ),
                          ],
                          onChanged: (value) => widget.onChanged(
                            widget.profile.copyWith(
                              pauseBackdropOpacity: value,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field<T>({
    required double width,
    required String key,
    required String label,
    required T value,
    required List<PokeMapDropdownItem<T>> items,
    required ValueChanged<T> onChanged,
  }) => SizedBox(
    key: ValueKey<String>('window-field-$key'),
    width: width,
    child: PokeMapDropdownField<T>(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
    ),
  );

  void _replace(ProjectWindowStyleProfile style) {
    final role = widget.fixedRole ?? _target.role;
    final currentStyle = widget.profile.resolve(role);
    widget.onChanged(
      widget.profile.copyWith(
        styles: widget.profile.styles
            .map(
              (current) => current.id == currentStyle.id
                  ? style.copyWith(id: currentStyle.id)
                  : current,
            )
            .toList(growable: false),
      ),
    );
  }

  void _applyPreset(ProjectPresentationWindowsProfile preset) {
    final role = widget.fixedRole;
    if (role == null) {
      widget.onChanged(preset);
      return;
    }
    final style = preset.resolve(role);
    final currentStyle = widget.profile.resolve(role);
    widget.onChanged(
      widget.profile.copyWith(
        styles: widget.profile.styles
            .map(
              (current) => current.id == currentStyle.id
                  ? style.copyWith(id: currentStyle.id)
                  : current,
            )
            .toList(growable: false),
        pauseBackdropOpacity: role == ProjectWindowRole.pauseMenu
            ? preset.pauseBackdropOpacity
            : widget.profile.pauseBackdropOpacity,
      ),
    );
  }

  void _reset() {
    if (widget.fixedRole == null) {
      widget.onChanged(null);
      return;
    }
    _applyPreset(legacyProjectPresentationWindows);
  }
}

enum ProjectWindowShapePreset {
  square('square', 'Carrée', ProjectWindowShape.rectangle, 0, 0),
  rounded('rounded', 'Arrondie', ProjectWindowShape.rounded, 16, 4),
  soft('soft', 'Douce', ProjectWindowShape.rounded, 24, 8);

  const ProjectWindowShapePreset(
    this.id,
    this.label,
    this.shape,
    this.cornerRadius,
    this.shadowElevation,
  );

  final String id;
  final String label;
  final ProjectWindowShape shape;
  final int cornerRadius;
  final int shadowElevation;
}

ProjectPresentationWindowsProfile applyProjectWindowShapePreset(
  ProjectPresentationWindowsProfile profile,
  ProjectWindowShapePreset preset,
) => profile.copyWith(
  styles: profile.styles
      .map(
        (style) => style.copyWith(
          shape: preset.shape,
          cornerRadius: preset.cornerRadius,
          shadowElevation: preset.shadowElevation,
        ),
      )
      .toList(growable: false),
);

class _SimpleWindowShapePresets extends StatelessWidget {
  const _SimpleWindowShapePresets({
    required this.profile,
    required this.onChanged,
  });

  final ProjectPresentationWindowsProfile profile;
  final ValueChanged<ProjectPresentationWindowsProfile?> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const PokeMapSectionHeader(
        title: 'Forme des fenêtres',
        description:
            'Appliquez la même silhouette au titre, aux menus et aux dialogues.',
      ),
      const SizedBox(height: 8),
      PokeMapCard(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final preset in ProjectWindowShapePreset.values)
              PokeMapButton(
                key: ValueKey<String>('global-shape-${preset.id}'),
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                isSelected: profile.styles.every(
                  (style) =>
                      style.shape == preset.shape &&
                      style.cornerRadius == preset.cornerRadius,
                ),
                onPressed: () =>
                    onChanged(applyProjectWindowShapePreset(profile, preset)),
                child: Text(preset.label),
              ),
          ],
        ),
      ),
    ],
  );
}

enum _WindowTarget {
  pause('Menu Pause', Icons.pause_circle_outline_rounded),
  dialogue('Dialogues', Icons.chat_bubble_outline_rounded);

  const _WindowTarget(this.label, this.icon);

  final String label;
  final IconData icon;

  ProjectWindowRole get role => switch (this) {
    _WindowTarget.pause => ProjectWindowRole.pauseMenu,
    _WindowTarget.dialogue => ProjectWindowRole.dialogue,
  };
}

const _fillItems = <PokeMapDropdownItem<String>>[
  PokeMapDropdownItem(value: 'surface', label: 'Surface principale'),
  PokeMapDropdownItem(value: 'surfaceElevated', label: 'Surface élevée'),
  PokeMapDropdownItem(value: 'menuSurface', label: 'Couleur des menus'),
  PokeMapDropdownItem(value: 'dialogueSurface', label: 'Couleur des dialogues'),
  PokeMapDropdownItem(value: 'titleSurface', label: 'Couleur du titre'),
  PokeMapDropdownItem(value: 'battleHudSurface', label: 'Couleur du combat'),
];

const _borderItems = <PokeMapDropdownItem<String>>[
  PokeMapDropdownItem(value: 'outline', label: 'Contour du thème'),
  PokeMapDropdownItem(value: 'primary', label: 'Couleur principale'),
  PokeMapDropdownItem(value: 'success', label: 'Succès'),
  PokeMapDropdownItem(value: 'warning', label: 'Avertissement'),
  PokeMapDropdownItem(value: 'danger', label: 'Danger'),
];

List<PokeMapDropdownItem<ProjectWindowShape>> _shapeItems(
  ProjectWindowRole role,
) => <PokeMapDropdownItem<ProjectWindowShape>>[
  const PokeMapDropdownItem(
    value: ProjectWindowShape.rectangle,
    label: 'Rectangulaire',
  ),
  const PokeMapDropdownItem(
    value: ProjectWindowShape.rounded,
    label: 'Arrondie',
  ),
  const PokeMapDropdownItem(
    value: ProjectWindowShape.cutCorner,
    label: 'Angles coupés',
  ),
  if (role == ProjectWindowRole.dialogue)
    const PokeMapDropdownItem(
      value: ProjectWindowShape.speech,
      label: 'Bulle avec pointe',
    ),
];

List<PokeMapDropdownItem<int>> _intItems(
  List<int> values, {
  required String suffix,
}) => values
    .map(
      (value) => PokeMapDropdownItem<int>(value: value, label: '$value$suffix'),
    )
    .toList(growable: false);
