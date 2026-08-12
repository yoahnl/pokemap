import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'pokemap_player_theme.dart';

@immutable
final class PokeMapPlayerSurfacePaletteTheme
    extends ThemeExtension<PokeMapPlayerSurfacePaletteTheme> {
  const PokeMapPlayerSurfacePaletteTheme(this.profile);

  final ProjectPresentationSurfacePalettesProfile profile;

  ProjectSurfacePaletteProfile? resolve(
    ProjectPresentationSurfaceRole role,
  ) =>
      profile.resolve(role);

  @override
  PokeMapPlayerSurfacePaletteTheme copyWith({
    ProjectPresentationSurfacePalettesProfile? profile,
  }) =>
      PokeMapPlayerSurfacePaletteTheme(profile ?? this.profile);

  @override
  PokeMapPlayerSurfacePaletteTheme lerp(
    covariant ThemeExtension<PokeMapPlayerSurfacePaletteTheme>? other,
    double t,
  ) =>
      t < .5 || other is! PokeMapPlayerSurfacePaletteTheme ? this : other;
}

extension PokeMapPlayerSurfacePaletteContext on BuildContext {
  ProjectSurfacePaletteProfile? playerSurfacePalette(
    ProjectPresentationSurfaceRole role,
  ) =>
      dependOnInheritedWidgetOfExactType<_ResolvedPlayerSurfacePalette>()
          ?.palette ??
      Theme.of(this)
          .extension<PokeMapPlayerSurfacePaletteTheme>()
          ?.resolve(role);
}

class PlayerSurfacePaletteScope extends StatelessWidget {
  const PlayerSurfacePaletteScope({
    super.key,
    required this.role,
    required this.child,
    this.paintBackground = false,
  });

  final ProjectPresentationSurfaceRole role;
  final Widget child;
  final bool paintBackground;

  @override
  Widget build(BuildContext context) {
    final palette = context.playerSurfacePalette(role);
    if (palette == null) return child;
    final theme = PokeMapPlayerTheme.withSurfacePalette(
      Theme.of(context),
      palette,
    );
    final background = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
      palette.background,
    );
    final content = Theme(
      data: theme,
      child: _ResolvedPlayerSurfacePalette(
        palette: palette,
        child: child,
      ),
    );
    if (!paintBackground || background == null) return content;
    return ColoredBox(color: background, child: content);
  }
}

class _ResolvedPlayerSurfacePalette extends InheritedWidget {
  const _ResolvedPlayerSurfacePalette({
    required this.palette,
    required super.child,
  });

  final ProjectSurfacePaletteProfile palette;

  @override
  bool updateShouldNotify(_ResolvedPlayerSurfacePalette oldWidget) =>
      oldWidget.palette != palette;
}
