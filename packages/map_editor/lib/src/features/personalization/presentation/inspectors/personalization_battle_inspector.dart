import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/personalization_capability_descriptor.dart';
import '../personalization_surface_color_editor.dart';
import '../project_typography_editor.dart';
import '../project_window_studio.dart';
import 'battle/battle_commands_section.dart';
import 'battle/battle_hud_section.dart';
import 'battle/battle_panel_section.dart';

enum PersonalizationBattleInspectorSection {
  commands,
  hud,
  moves,
  target,
  message,
}

class PersonalizationBattleInspector extends StatefulWidget {
  static const capabilityIds = <String>{
    'battle.previewState',
    'battle.commands',
    'battle.hud',
    'battle.moves',
    'battle.target',
    'battle.message',
    'battle.layout',
    'battle.windows',
    'battle.typography',
  };

  const PersonalizationBattleInspector({
    super.key,
    required this.profile,
    required this.previewState,
    required this.onPreviewStateChanged,
    required this.onBattleChanged,
    required this.onWindowsChanged,
    required this.onLayoutsChanged,
    required this.onImportCombatFont,
    required this.onUseSystemCombatFont,
    this.initialSection,
    this.onImportNumbersFont,
    this.onUseSystemNumbersFont,
    this.onCombatMetricsChanged,
    this.onNumbersMetricsChanged,
    this.onSurfacePalettesChanged,
    this.previewFamilies = const <ProjectTypographyRole, String>{},
  });

  final ProjectPresentationProfile profile;
  final PersonalizationBattlePreviewState previewState;
  final ValueChanged<PersonalizationBattlePreviewState> onPreviewStateChanged;
  final ValueChanged<ProjectBattlePresentationProfile> onBattleChanged;
  final ValueChanged<ProjectPresentationWindowsProfile?> onWindowsChanged;
  final ValueChanged<ProjectPresentationLayoutsProfile?> onLayoutsChanged;
  final VoidCallback onImportCombatFont;
  final VoidCallback onUseSystemCombatFont;
  final PersonalizationBattleInspectorSection? initialSection;
  final VoidCallback? onImportNumbersFont;
  final VoidCallback? onUseSystemNumbersFont;
  final ValueChanged<ProjectTypographyMetricsProfile>? onCombatMetricsChanged;
  final ValueChanged<ProjectTypographyMetricsProfile>? onNumbersMetricsChanged;
  final ValueChanged<ProjectPresentationSurfacePalettesProfile?>?
  onSurfacePalettesChanged;
  final Map<ProjectTypographyRole, String> previewFamilies;

  @override
  State<PersonalizationBattleInspector> createState() =>
      _PersonalizationBattleInspectorState();
}

class _PersonalizationBattleInspectorState
    extends State<PersonalizationBattleInspector> {
  late PersonalizationBattleInspectorSection _section;
  var _advanced = false;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection ?? _sectionForPreview(widget.previewState);
  }

  @override
  void didUpdateWidget(covariant PersonalizationBattleInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSection != oldWidget.initialSection &&
        widget.initialSection != null) {
      _section = widget.initialSection!;
    } else if (widget.previewState != oldWidget.previewState &&
        _section != PersonalizationBattleInspectorSection.hud) {
      _section = _sectionForPreview(widget.previewState);
    }
  }

  ProjectBattlePresentationProfile get _battle =>
      widget.profile.battle ?? const ProjectBattlePresentationProfile();

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('personalization-battle-inspector'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const PokeMapSectionHeader(
        title: 'Personnaliser le combat',
        description:
            'Choisissez une partie de l’interface : la preview affiche immédiatement le même état.',
      ),
      const SizedBox(height: 8),
      PokeMapCard(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final section in PersonalizationBattleInspectorSection.values)
              PokeMapButton(
                key: ValueKey<String>('battle-section-${section.name}'),
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                isSelected: _section == section,
                onPressed: () => _select(section),
                child: Text(_sectionLabel(section)),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _buildSection(),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          PokeMapButton(
            key: ValueKey<String>('battle-reset-${_section.name}'),
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            onPressed: _resetSection,
            leading: const Icon(Icons.restart_alt_rounded),
            child: const Text('Réinitialiser cette section'),
          ),
          PokeMapButton(
            key: const ValueKey<String>('battle-advanced-toggle'),
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            isSelected: _advanced,
            onPressed: () => setState(() => _advanced = !_advanced),
            leading: Icon(
              _advanced ? Icons.expand_less_rounded : Icons.tune_rounded,
            ),
            child: Text(
              _advanced ? 'Masquer les réglages avancés' : 'Réglages avancés',
            ),
          ),
        ],
      ),
      if (_advanced) ...<Widget>[const SizedBox(height: 18), _buildAdvanced()],
    ],
  );

  Widget _buildSection() => switch (_section) {
    PersonalizationBattleInspectorSection.commands => BattleCommandsSection(
      profile: _battle,
      inheritedTheme: widget.profile.theme ?? safeProjectSemanticTheme,
      onChanged: widget.onBattleChanged,
    ),
    PersonalizationBattleInspectorSection.hud => BattleHudSection(
      profile: _battle,
      onChanged: widget.onBattleChanged,
    ),
    PersonalizationBattleInspectorSection.moves => BattlePanelSection(
      id: 'moves',
      title: 'Capacités',
      description:
          'Réglez uniquement la liste des capacités, des PP et des actions indisponibles.',
      profile: _battle.moves,
      inheritedTheme: widget.profile.theme ?? safeProjectSemanticTheme,
      onChanged: (value) =>
          widget.onBattleChanged(_battle.copyWith(moves: value)),
    ),
    PersonalizationBattleInspectorSection.target => BattlePanelSection(
      id: 'target',
      title: 'Choix d’une cible',
      description:
          'Réglez le panneau utilisé lorsque le joueur choisit une créature.',
      profile: _battle.target,
      inheritedTheme: widget.profile.theme ?? safeProjectSemanticTheme,
      onChanged: (value) =>
          widget.onBattleChanged(_battle.copyWith(target: value)),
    ),
    PersonalizationBattleInspectorSection.message => BattlePanelSection(
      id: 'message',
      title: 'Messages de combat',
      description:
          'Réglez le panneau des narrations et des messages longs entre deux actions.',
      profile: _battle.message,
      inheritedTheme: widget.profile.theme ?? safeProjectSemanticTheme,
      onChanged: (value) =>
          widget.onBattleChanged(_battle.copyWith(message: value)),
    ),
  };

  Widget _buildAdvanced() => Column(
    key: const ValueKey<String>('battle-advanced-editor'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      ProjectWindowStudio(
        profile: _battleWindows(widget.profile.windows),
        fixedRole: ProjectWindowRole.battle,
        onChanged: widget.onWindowsChanged,
      ),
      const SizedBox(height: 18),
      PersonalizationSurfaceColorEditor(
        role: ProjectPresentationSurfaceRole.battleHud,
        palette: personalizationSurfacePalette(
          widget.profile.surfacePalettes,
          ProjectPresentationSurfaceRole.battleHud,
        ),
        inheritedTheme: widget.profile.theme ?? safeProjectSemanticTheme,
        onChanged: (palette) => widget.onSurfacePalettesChanged?.call(
          replacePersonalizationSurfacePalette(
            widget.profile.surfacePalettes,
            ProjectPresentationSurfaceRole.battleHud,
            palette,
          ),
        ),
      ),
      const SizedBox(height: 18),
      ProjectTypographyEditor(
        profile: widget.profile.typography ?? const ProjectTypographyProfile(),
        previewFamilies: widget.previewFamilies,
        roles: const <ProjectTypographyRole>[
          ProjectTypographyRole.combat,
          ProjectTypographyRole.numbers,
        ],
        onImportRole: (role) => switch (role) {
          ProjectTypographyRole.combat => widget.onImportCombatFont(),
          ProjectTypographyRole.numbers => widget.onImportNumbersFont?.call(),
          _ => null,
        },
        onUseSystemFont: (role) => switch (role) {
          ProjectTypographyRole.combat => widget.onUseSystemCombatFont(),
          ProjectTypographyRole.numbers =>
            widget.onUseSystemNumbersFont?.call(),
          _ => null,
        },
        onMetricsChanged: (role, metrics) => switch (role) {
          ProjectTypographyRole.combat => widget.onCombatMetricsChanged?.call(
            metrics,
          ),
          ProjectTypographyRole.numbers => widget.onNumbersMetricsChanged?.call(
            metrics,
          ),
          _ => null,
        },
      ),
    ],
  );

  void _select(PersonalizationBattleInspectorSection section) {
    setState(() => _section = section);
    final preview = _previewForSection(section);
    if (preview != null) widget.onPreviewStateChanged(preview);
  }

  void _resetSection() {
    const defaults = ProjectBattlePresentationProfile();
    widget.onBattleChanged(switch (_section) {
      PersonalizationBattleInspectorSection.commands => _battle.copyWith(
        commandLayout: defaults.commandLayout,
        commandColumns: defaults.commandColumns,
        showCommandIcons: defaults.showCommandIcons,
        commandShape: defaults.commandShape,
        commandPadding: defaults.commandPadding,
        commandSurfaceColor: defaults.commandSurfaceColor,
        commandBorderColor: defaults.commandBorderColor,
        commandTextColor: defaults.commandTextColor,
        commandSelectionColor: defaults.commandSelectionColor,
        commands: defaults.commands,
      ),
      PersonalizationBattleInspectorSection.hud => _battle.copyWith(
        hudShape: defaults.hudShape,
        enemyHudPosition: defaults.enemyHudPosition,
        playerHudPosition: defaults.playerHudPosition,
        showOwnerLabel: defaults.showOwnerLabel,
        showLevel: defaults.showLevel,
        showExactHp: defaults.showExactHp,
        hpBarShape: defaults.hpBarShape,
        hpHealthyColor: defaults.hpHealthyColor,
        hpWarningColor: defaults.hpWarningColor,
        hpDangerColor: defaults.hpDangerColor,
        statusColor: defaults.statusColor,
      ),
      PersonalizationBattleInspectorSection.moves => _battle.copyWith(
        moves: defaults.moves,
      ),
      PersonalizationBattleInspectorSection.target => _battle.copyWith(
        target: defaults.target,
      ),
      PersonalizationBattleInspectorSection.message => _battle.copyWith(
        message: defaults.message,
      ),
    });
  }
}

PersonalizationBattleInspectorSection _sectionForPreview(
  PersonalizationBattlePreviewState state,
) => switch (state) {
  PersonalizationBattlePreviewState.commands =>
    PersonalizationBattleInspectorSection.commands,
  PersonalizationBattlePreviewState.moves =>
    PersonalizationBattleInspectorSection.moves,
  PersonalizationBattlePreviewState.target =>
    PersonalizationBattleInspectorSection.target,
  PersonalizationBattlePreviewState.message =>
    PersonalizationBattleInspectorSection.message,
};

PersonalizationBattlePreviewState? _previewForSection(
  PersonalizationBattleInspectorSection section,
) => switch (section) {
  PersonalizationBattleInspectorSection.commands =>
    PersonalizationBattlePreviewState.commands,
  PersonalizationBattleInspectorSection.hud => null,
  PersonalizationBattleInspectorSection.moves =>
    PersonalizationBattlePreviewState.moves,
  PersonalizationBattleInspectorSection.target =>
    PersonalizationBattlePreviewState.target,
  PersonalizationBattleInspectorSection.message =>
    PersonalizationBattlePreviewState.message,
};

String _sectionLabel(PersonalizationBattleInspectorSection section) =>
    switch (section) {
      PersonalizationBattleInspectorSection.commands => 'Commandes',
      PersonalizationBattleInspectorSection.hud => 'HUD et PV',
      PersonalizationBattleInspectorSection.moves => 'Capacités',
      PersonalizationBattleInspectorSection.target => 'Cible',
      PersonalizationBattleInspectorSection.message => 'Message',
    };

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
