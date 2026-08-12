import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../../ui/design_system/design_system.dart';
import '../../project_theme_token_dialog.dart';

class BattleCommandsSection extends StatefulWidget {
  const BattleCommandsSection({
    super.key,
    required this.profile,
    required this.inheritedTheme,
    required this.onChanged,
  });

  final ProjectBattlePresentationProfile profile;
  final ProjectSemanticThemeProfile inheritedTheme;
  final ValueChanged<ProjectBattlePresentationProfile> onChanged;

  @override
  State<BattleCommandsSection> createState() => _BattleCommandsSectionState();
}

class _BattleCommandsSectionState extends State<BattleCommandsSection> {
  var _group = _BattleCommandsGroup.organization;
  var _selectedCommand = ProjectBattleCommandId.fight;

  ProjectBattlePresentationProfile get profile => widget.profile;
  ProjectSemanticThemeProfile get inheritedTheme => widget.inheritedTheme;
  ValueChanged<ProjectBattlePresentationProfile> get onChanged =>
      widget.onChanged;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('battle-commands-editor'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const PokeMapSectionHeader(
        title: 'Menu de commandes',
        description:
            'Réglez les quatre actions principales sans modifier leur logique de jeu.',
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final group in _BattleCommandsGroup.values)
            PokeMapButton(
              key: ValueKey<String>('battle-command-group-${group.name}'),
              size: PokeMapButtonSize.small,
              variant: PokeMapButtonVariant.secondary,
              isSelected: _group == group,
              onPressed: () => setState(() => _group = group),
              child: Text(_groupLabel(group)),
            ),
        ],
      ),
      const SizedBox(height: 8),
      if (_group == _BattleCommandsGroup.organization)
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Disposition',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final layout in ProjectBattleCommandLayout.values)
                    PokeMapButton(
                      key: ValueKey<String>(
                        'battle-command-layout-${layout.name}',
                      ),
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.secondary,
                      isSelected: profile.commandLayout == layout,
                      onPressed: () =>
                          onChanged(profile.copyWith(commandLayout: layout)),
                      child: Text(_layoutLabel(layout)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              PokeMapGuidedSlider(
                key: const ValueKey<String>('battle-command-columns'),
                label: 'Colonnes',
                description: 'Nombre de commandes affichées sur une ligne.',
                value: profile.commandColumns,
                min: 1,
                max: 4,
                onChanged: (value) =>
                    onChanged(profile.copyWith(commandColumns: value)),
              ),
              const SizedBox(height: 8),
              PokeMapToggleTile(
                key: const ValueKey<String>('battle-command-icons'),
                label: 'Afficher les icônes',
                value: profile.showCommandIcons,
                onChanged: (value) =>
                    onChanged(profile.copyWith(showCommandIcons: value)),
              ),
            ],
          ),
        ),
      if (_group == _BattleCommandsGroup.appearance)
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PokeMapDropdownField<ProjectWindowShape>(
                label: 'Forme du panneau',
                value: profile.commandShape,
                items: <PokeMapDropdownItem<ProjectWindowShape>>[
                  for (final shape in ProjectWindowShape.values)
                    if (shape != ProjectWindowShape.speech)
                      PokeMapDropdownItem<ProjectWindowShape>(
                        value: shape,
                        label: _shapeLabel(shape),
                      ),
                ],
                onChanged: (value) =>
                    onChanged(profile.copyWith(commandShape: value)),
              ),
              const SizedBox(height: 12),
              PokeMapGuidedSlider(
                label: 'Marge intérieure',
                value: profile.commandPadding.round(),
                min: 4,
                max: 32,
                onChanged: (value) => onChanged(
                  profile.copyWith(commandPadding: value.toDouble()),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _colorButton(context, _CommandColor.surface),
                  _colorButton(context, _CommandColor.border),
                  _colorButton(context, _CommandColor.text),
                  _colorButton(context, _CommandColor.selection),
                ],
              ),
            ],
          ),
        ),
      if (_group == _BattleCommandsGroup.actions)
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Actions', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final command in profile.effectiveCommands)
                    PokeMapButton(
                      key: ValueKey<String>(
                        'battle-command-select-${command.id.name}',
                      ),
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.secondary,
                      isSelected: command.id == _selectedCommand,
                      onPressed: () =>
                          setState(() => _selectedCommand = command.id),
                      child: Text(
                        command.label ?? _commandDefaultLabel(command.id),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _commandRow(
                profile.effectiveCommands.indexWhere(
                  (command) => command.id == _selectedCommand,
                ),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _commandRow(int index) {
    final commands = profile.effectiveCommands;
    final command = commands[index];
    return Row(
      children: <Widget>[
        Expanded(
          child: PokeMapTextField(
            label: _commandLabel(command.id),
            fieldKey: ValueKey<String>(
              'battle-command-label-${command.id.name}',
            ),
            placeholder: command.label ?? _commandDefaultLabel(command.id),
            onSubmitted: (value) => _replaceCommand(
              index,
              command.copyWith(
                label: value.trim().isEmpty ? null : value.trim(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 122,
          child: PokeMapDropdownField<ProjectBattleCommandIcon>(
            label: 'Icône',
            compact: true,
            value: command.icon ?? _defaultIcon(command.id),
            items: <PokeMapDropdownItem<ProjectBattleCommandIcon>>[
              for (final icon in ProjectBattleCommandIcon.values)
                PokeMapDropdownItem<ProjectBattleCommandIcon>(
                  value: icon,
                  label: _iconLabel(icon),
                ),
            ],
            onChanged: (icon) =>
                _replaceCommand(index, command.copyWith(icon: icon)),
          ),
        ),
        const SizedBox(width: 6),
        PokeMapIconButton(
          tooltip: 'Monter',
          onPressed: index == 0 ? null : () => _move(index, index - 1),
          icon: const Icon(Icons.arrow_upward_rounded),
        ),
        PokeMapIconButton(
          tooltip: 'Descendre',
          onPressed: index == commands.length - 1
              ? null
              : () => _move(index, index + 1),
          icon: const Icon(Icons.arrow_downward_rounded),
        ),
      ],
    );
  }

  void _replaceCommand(int index, ProjectBattleCommandProfile command) {
    final commands = profile.effectiveCommands.toList();
    commands[index] = command;
    onChanged(profile.copyWith(commands: commands));
  }

  void _move(int from, int to) {
    final commands = profile.effectiveCommands.toList();
    final command = commands.removeAt(from);
    commands.insert(to, command);
    onChanged(profile.copyWith(commands: commands));
  }

  Widget _colorButton(BuildContext context, _CommandColor color) =>
      PokeMapButton(
        key: ValueKey<String>('battle-command-color-${color.name}'),
        size: PokeMapButtonSize.small,
        variant: PokeMapButtonVariant.secondary,
        onPressed: () => _editColor(context, color),
        leading: const Icon(Icons.palette_outlined),
        child: Text(_colorLabel(color)),
      );

  Future<void> _editColor(BuildContext context, _CommandColor color) async {
    final current = _colorValue(color) ?? _inheritedColor(color);
    final value = await showProjectThemeTokenDialog(
      context: context,
      tokenLabel: _colorLabel(color).toLowerCase(),
      currentValue: current,
      impactDescription:
          'Cette couleur affecte seulement le menu principal du combat.',
    );
    if (value == null || value == current) return;
    onChanged(switch (color) {
      _CommandColor.surface => profile.copyWith(commandSurfaceColor: value),
      _CommandColor.border => profile.copyWith(commandBorderColor: value),
      _CommandColor.text => profile.copyWith(commandTextColor: value),
      _CommandColor.selection => profile.copyWith(commandSelectionColor: value),
    });
  }

  String? _colorValue(_CommandColor color) => switch (color) {
    _CommandColor.surface => profile.commandSurfaceColor,
    _CommandColor.border => profile.commandBorderColor,
    _CommandColor.text => profile.commandTextColor,
    _CommandColor.selection => profile.commandSelectionColor,
  };

  String _inheritedColor(_CommandColor color) => switch (color) {
    _CommandColor.surface => inheritedTheme.battleHudSurface,
    _CommandColor.border => inheritedTheme.outline,
    _CommandColor.text => inheritedTheme.textPrimary,
    _CommandColor.selection => inheritedTheme.primary,
  };
}

enum _BattleCommandsGroup { organization, appearance, actions }

String _groupLabel(_BattleCommandsGroup group) => switch (group) {
  _BattleCommandsGroup.organization => 'Organisation',
  _BattleCommandsGroup.appearance => 'Apparence',
  _BattleCommandsGroup.actions => 'Libellés et ordre',
};

enum _CommandColor { surface, border, text, selection }

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

String _commandLabel(ProjectBattleCommandId id) =>
    'Libellé — ${_commandDefaultLabel(id)}';

String _commandDefaultLabel(ProjectBattleCommandId id) => switch (id) {
  ProjectBattleCommandId.fight => 'Attaquer',
  ProjectBattleCommandId.bag => 'Sac',
  ProjectBattleCommandId.party => 'Équipe',
  ProjectBattleCommandId.run => 'Fuite',
};

ProjectBattleCommandIcon _defaultIcon(ProjectBattleCommandId id) =>
    ProjectBattleCommandIcon.values.byName(id.name);

String _iconLabel(ProjectBattleCommandIcon icon) => switch (icon) {
  ProjectBattleCommandIcon.fight => 'Combat',
  ProjectBattleCommandIcon.bag => 'Sac',
  ProjectBattleCommandIcon.party => 'Équipe',
  ProjectBattleCommandIcon.run => 'Fuite',
};

String _colorLabel(_CommandColor color) => switch (color) {
  _CommandColor.surface => 'Fond',
  _CommandColor.border => 'Contour',
  _CommandColor.text => 'Texte',
  _CommandColor.selection => 'Sélection',
};
