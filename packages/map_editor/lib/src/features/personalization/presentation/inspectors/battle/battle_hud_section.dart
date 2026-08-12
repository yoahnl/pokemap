import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../../ui/design_system/design_system.dart';
import '../../project_theme_token_dialog.dart';

class BattleHudSection extends StatefulWidget {
  const BattleHudSection({
    super.key,
    required this.profile,
    required this.onChanged,
  });

  final ProjectBattlePresentationProfile profile;
  final ValueChanged<ProjectBattlePresentationProfile> onChanged;

  @override
  State<BattleHudSection> createState() => _BattleHudSectionState();
}

class _BattleHudSectionState extends State<BattleHudSection> {
  var _group = _BattleHudGroup.visibility;

  ProjectBattlePresentationProfile get profile => widget.profile;
  ValueChanged<ProjectBattlePresentationProfile> get onChanged =>
      widget.onChanged;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('battle-hud-editor'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const PokeMapSectionHeader(
        title: 'HUD et points de vie',
        description:
            'Placez les panneaux et choisissez les informations visibles. Les seuils de danger restent définis par le moteur.',
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final group in _BattleHudGroup.values)
            PokeMapButton(
              key: ValueKey<String>('battle-hud-group-${group.name}'),
              size: PokeMapButtonSize.small,
              variant: PokeMapButtonVariant.secondary,
              isSelected: _group == group,
              onPressed: () => setState(() => _group = group),
              child: Text(_groupLabel(group)),
            ),
        ],
      ),
      const SizedBox(height: 8),
      if (_group == _BattleHudGroup.placement)
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PokeMapDropdownField<ProjectWindowShape>(
                label: 'Forme des panneaux',
                value: profile.hudShape,
                items: <PokeMapDropdownItem<ProjectWindowShape>>[
                  for (final shape in ProjectWindowShape.values)
                    if (shape != ProjectWindowShape.speech)
                      PokeMapDropdownItem<ProjectWindowShape>(
                        value: shape,
                        label: _shapeLabel(shape),
                      ),
                ],
                onChanged: (value) =>
                    onChanged(profile.copyWith(hudShape: value)),
              ),
              const SizedBox(height: 12),
              PokeMapDropdownField<ProjectBattleHudPosition>(
                label: 'Panneau adverse',
                value: profile.enemyHudPosition,
                items: _positions(excluding: profile.playerHudPosition),
                onChanged: (value) =>
                    onChanged(profile.copyWith(enemyHudPosition: value)),
              ),
              const SizedBox(height: 12),
              PokeMapDropdownField<ProjectBattleHudPosition>(
                label: 'Panneau du joueur',
                value: profile.playerHudPosition,
                items: _positions(excluding: profile.enemyHudPosition),
                onChanged: (value) =>
                    onChanged(profile.copyWith(playerHudPosition: value)),
              ),
            ],
          ),
        ),
      if (_group == _BattleHudGroup.visibility)
        Column(
          children: <Widget>[
            PokeMapToggleTile(
              key: const ValueKey<String>('battle-hud-show-owner'),
              label: 'Afficher le camp',
              description: 'Par exemple « sauvage » ou « joueur ».',
              value: profile.showOwnerLabel,
              onChanged: (value) =>
                  onChanged(profile.copyWith(showOwnerLabel: value)),
            ),
            const SizedBox(height: 8),
            PokeMapToggleTile(
              key: const ValueKey<String>('battle-hud-show-level'),
              label: 'Afficher le niveau',
              value: profile.showLevel,
              onChanged: (value) =>
                  onChanged(profile.copyWith(showLevel: value)),
            ),
            const SizedBox(height: 8),
            PokeMapToggleTile(
              key: const ValueKey<String>('battle-hud-show-exact-hp'),
              label: 'Afficher les PV exacts',
              value: profile.showExactHp,
              onChanged: (value) =>
                  onChanged(profile.copyWith(showExactHp: value)),
            ),
          ],
        ),
      if (_group == _BattleHudGroup.health)
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PokeMapDropdownField<ProjectBattleHpBarShape>(
                label: 'Forme de la jauge de PV',
                value: profile.hpBarShape,
                items: <PokeMapDropdownItem<ProjectBattleHpBarShape>>[
                  for (final shape in ProjectBattleHpBarShape.values)
                    PokeMapDropdownItem<ProjectBattleHpBarShape>(
                      value: shape,
                      label: _hpShapeLabel(shape),
                    ),
                ],
                onChanged: (value) =>
                    onChanged(profile.copyWith(hpBarShape: value)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final color in _HudColor.values)
                    PokeMapButton(
                      key: ValueKey<String>('battle-hud-color-${color.name}'),
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.secondary,
                      onPressed: () => _editColor(context, color),
                      leading: const Icon(Icons.palette_outlined),
                      child: Text(_colorLabel(color)),
                    ),
                ],
              ),
            ],
          ),
        ),
    ],
  );

  List<PokeMapDropdownItem<ProjectBattleHudPosition>> _positions({
    required ProjectBattleHudPosition excluding,
  }) => <PokeMapDropdownItem<ProjectBattleHudPosition>>[
    for (final position in ProjectBattleHudPosition.values)
      if (position != excluding)
        PokeMapDropdownItem<ProjectBattleHudPosition>(
          value: position,
          label: _positionLabel(position),
        ),
  ];

  Future<void> _editColor(BuildContext context, _HudColor color) async {
    final current = switch (color) {
      _HudColor.healthy => profile.hpHealthyColor,
      _HudColor.warning => profile.hpWarningColor,
      _HudColor.danger => profile.hpDangerColor,
      _HudColor.status => profile.statusColor,
    };
    final value = await showProjectThemeTokenDialog(
      context: context,
      tokenLabel: _colorLabel(color).toLowerCase(),
      currentValue: current,
      impactDescription:
          'Cette couleur modifie la présentation, jamais les seuils de PV du combat.',
    );
    if (value == null || value == current) return;
    onChanged(switch (color) {
      _HudColor.healthy => profile.copyWith(hpHealthyColor: value),
      _HudColor.warning => profile.copyWith(hpWarningColor: value),
      _HudColor.danger => profile.copyWith(hpDangerColor: value),
      _HudColor.status => profile.copyWith(statusColor: value),
    });
  }
}

enum _BattleHudGroup { placement, visibility, health }

String _groupLabel(_BattleHudGroup group) => switch (group) {
  _BattleHudGroup.placement => 'Placement',
  _BattleHudGroup.visibility => 'Informations',
  _BattleHudGroup.health => 'PV et statut',
};

enum _HudColor { healthy, warning, danger, status }

String _shapeLabel(ProjectWindowShape shape) => switch (shape) {
  ProjectWindowShape.rectangle => 'Rectangle',
  ProjectWindowShape.rounded => 'Arrondie',
  ProjectWindowShape.capsule => 'Capsule',
  ProjectWindowShape.cutCorner => 'Coins coupés',
  ProjectWindowShape.speech => 'Bulle',
};

String _positionLabel(ProjectBattleHudPosition position) => switch (position) {
  ProjectBattleHudPosition.topStart => 'En haut à gauche',
  ProjectBattleHudPosition.topEnd => 'En haut à droite',
  ProjectBattleHudPosition.bottomStart => 'En bas à gauche',
  ProjectBattleHudPosition.bottomEnd => 'En bas à droite',
};

String _hpShapeLabel(ProjectBattleHpBarShape shape) => switch (shape) {
  ProjectBattleHpBarShape.flat => 'Plate',
  ProjectBattleHpBarShape.rounded => 'Arrondie',
  ProjectBattleHpBarShape.segmented => 'Segmentée',
};

String _colorLabel(_HudColor color) => switch (color) {
  _HudColor.healthy => 'PV hauts',
  _HudColor.warning => 'PV moyens',
  _HudColor.danger => 'PV faibles',
  _HudColor.status => 'Statut',
};
