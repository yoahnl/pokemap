import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import 'project_theme_token_dialog.dart';

class PersonalizationSurfaceColorEditor extends StatelessWidget {
  const PersonalizationSurfaceColorEditor({
    super.key,
    required this.role,
    required this.palette,
    required this.inheritedTheme,
    required this.onChanged,
  });

  final ProjectPresentationSurfaceRole role;
  final ProjectSurfacePaletteProfile? palette;
  final ProjectSemanticThemeProfile inheritedTheme;
  final ValueChanged<ProjectSurfacePaletteProfile?> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    key: ValueKey<String>('surface-colors-${role.name}'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      PokeMapSectionHeader(
        title: 'Couleurs de ${_roleLabel(role)}',
        description:
            'Chaque valeur héritée suit le style global. Personnalisez uniquement ce qui doit être différent ici.',
      ),
      const SizedBox(height: 8),
      for (final token in _SurfaceColorToken.values) ...<Widget>[
        _tokenCard(context, token),
        const SizedBox(height: 8),
      ],
      if (palette != null)
        Align(
          alignment: Alignment.centerLeft,
          child: PokeMapButton(
            key: ValueKey<String>('surface-colors-reset-${role.name}'),
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            onPressed: () => onChanged(null),
            leading: const Icon(Icons.restart_alt_rounded),
            child: const Text('Réutiliser tout le style global'),
          ),
        ),
    ],
  );

  Widget _tokenCard(BuildContext context, _SurfaceColorToken token) {
    final explicit = _explicitValue(token);
    final resolved = explicit ?? _inheritedValue(token);
    return PokeMapCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _tokenLabel(token),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    PokeMapBadge(label: resolved),
                    PokeMapBadge(
                      label: explicit == null ? 'Hérité' : 'Personnalisé',
                      variant: explicit == null
                          ? PokeMapBadgeVariant.info
                          : PokeMapBadgeVariant.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (explicit != null)
            PokeMapIconButton(
              key: ValueKey<String>(
                'surface-color-inherit-${role.name}-${token.name}',
              ),
              tooltip: 'Revenir à la couleur globale',
              onPressed: () => _inherit(token),
              icon: const Icon(Icons.link_rounded),
            ),
          const SizedBox(width: 4),
          PokeMapButton(
            key: ValueKey<String>(
              'surface-color-edit-${role.name}-${token.name}',
            ),
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            onPressed: () => _edit(context, token, resolved),
            leading: const Icon(Icons.palette_outlined),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    _SurfaceColorToken token,
    String currentValue,
  ) async {
    final value = await showProjectThemeTokenDialog(
      context: context,
      tokenLabel: _tokenLabel(token).toLowerCase(),
      currentValue: currentValue,
    );
    if (value == null || value == currentValue) return;
    onChanged(_replace(token, value));
  }

  void _inherit(_SurfaceColorToken token) {
    final updated = _replace(token, null);
    onChanged(_isEmpty(updated) ? null : updated);
  }

  String? _explicitValue(_SurfaceColorToken token) => switch (token) {
    _SurfaceColorToken.background => palette?.background,
    _SurfaceColorToken.surface => palette?.surface,
    _SurfaceColorToken.border => palette?.border,
    _SurfaceColorToken.text => palette?.text,
    _SurfaceColorToken.accent => palette?.accent,
    _SurfaceColorToken.selection => palette?.selection,
  };

  String _inheritedValue(_SurfaceColorToken token) => switch (token) {
    _SurfaceColorToken.background => inheritedTheme.background,
    _SurfaceColorToken.surface => switch (role) {
      ProjectPresentationSurfaceRole.title ||
      ProjectPresentationSurfaceRole.titlePrompt => inheritedTheme.titleSurface,
      ProjectPresentationSurfaceRole.pauseMenu => inheritedTheme.menuSurface,
      ProjectPresentationSurfaceRole.dialogue => inheritedTheme.dialogueSurface,
      ProjectPresentationSurfaceRole.battleHud =>
        inheritedTheme.battleHudSurface,
      _ => inheritedTheme.surface,
    },
    _SurfaceColorToken.border => inheritedTheme.outline,
    _SurfaceColorToken.text => inheritedTheme.textPrimary,
    _SurfaceColorToken.accent ||
    _SurfaceColorToken.selection => inheritedTheme.primary,
  };

  ProjectSurfacePaletteProfile _replace(
    _SurfaceColorToken token,
    String? value,
  ) {
    final current = palette ?? const ProjectSurfacePaletteProfile();
    return switch (token) {
      _SurfaceColorToken.background => current.copyWith(background: value),
      _SurfaceColorToken.surface => current.copyWith(surface: value),
      _SurfaceColorToken.border => current.copyWith(border: value),
      _SurfaceColorToken.text => current.copyWith(text: value),
      _SurfaceColorToken.accent => current.copyWith(accent: value),
      _SurfaceColorToken.selection => current.copyWith(selection: value),
    };
  }
}

enum _SurfaceColorToken { background, surface, border, text, accent, selection }

bool _isEmpty(ProjectSurfacePaletteProfile palette) =>
    palette.background == null &&
    palette.surface == null &&
    palette.border == null &&
    palette.text == null &&
    palette.accent == null &&
    palette.selection == null;

String _roleLabel(ProjectPresentationSurfaceRole role) => switch (role) {
  ProjectPresentationSurfaceRole.title ||
  ProjectPresentationSurfaceRole.titlePrompt => 'l’écran titre',
  ProjectPresentationSurfaceRole.pauseMenu => 'menu Pause',
  ProjectPresentationSurfaceRole.dialogue => 'la bulle de dialogue',
  ProjectPresentationSurfaceRole.battleHud => 'l’interface de combat',
  _ => 'cette scène',
};

String _tokenLabel(_SurfaceColorToken token) => switch (token) {
  _SurfaceColorToken.background => 'Arrière-plan',
  _SurfaceColorToken.surface => 'Fenêtre',
  _SurfaceColorToken.border => 'Contour',
  _SurfaceColorToken.text => 'Texte',
  _SurfaceColorToken.accent => 'Boutons et accents',
  _SurfaceColorToken.selection => 'Sélection et focus',
};

ProjectSurfacePaletteProfile? personalizationSurfacePalette(
  ProjectPresentationSurfacePalettesProfile? palettes,
  ProjectPresentationSurfaceRole role,
) => palettes?.resolve(role);

ProjectPresentationSurfacePalettesProfile? replacePersonalizationSurfacePalette(
  ProjectPresentationSurfacePalettesProfile? palettes,
  ProjectPresentationSurfaceRole role,
  ProjectSurfacePaletteProfile? replacement,
) {
  final current = palettes ?? const ProjectPresentationSurfacePalettesProfile();
  final updated = switch (role) {
    ProjectPresentationSurfaceRole.title ||
    ProjectPresentationSurfaceRole.titlePrompt => current.copyWith(
      title: replacement,
    ),
    ProjectPresentationSurfaceRole.pauseMenu => current.copyWith(
      pauseMenu: replacement,
    ),
    ProjectPresentationSurfaceRole.dialogue => current.copyWith(
      dialogue: replacement,
    ),
    ProjectPresentationSurfaceRole.battleHud => current.copyWith(
      battle: replacement,
    ),
    _ => throw ArgumentError.value(role, 'role'),
  };
  if (updated.title == null &&
      updated.pauseMenu == null &&
      updated.dialogue == null &&
      updated.battle == null) {
    return null;
  }
  return updated;
}
