import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/personalization_preview_projection.dart';
import 'project_branding_title_preview.dart';

/// Runtime-shaped preview surface driven by the current presentation draft.
///
/// The preview reads the same `ProjectPresentationProfile` contract that is
/// packaged for the player. Simulation controls added around this widget stay
/// editor-local and never mutate that contract.
class PersonalizationRuntimePreview extends StatefulWidget {
  const PersonalizationRuntimePreview({
    super.key,
    required this.profile,
    required this.projectName,
    required this.projectRootPath,
    this.baselineProfile,
  });

  final ProjectPresentationProfile profile;
  final ProjectPresentationProfile? baselineProfile;
  final String projectName;
  final String projectRootPath;

  @override
  State<PersonalizationRuntimePreview> createState() =>
      _PersonalizationRuntimePreviewState();
}

class _PersonalizationRuntimePreviewState
    extends State<PersonalizationRuntimePreview> {
  PersonalizationPreviewSurface _surface = PersonalizationPreviewSurface.title;

  @override
  Widget build(BuildContext context) {
    final projection = PersonalizationPreviewProjection(widget.profile);
    final surfaceProjection = projection.surface(_surface);
    return PokeMapPanel(
      key: const ValueKey<String>('personalization-runtime-preview'),
      header: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Aperçu dans le jeu',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            PokeMapBadge(
              label: surfaceProjection.fontFamily,
              variant: PokeMapBadgeVariant.info,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final surface in PersonalizationPreviewSurface.values)
                PokeMapButton(
                  key: ValueKey<String>(
                    'personalization-preview-${surface.name}',
                  ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  isSelected: _surface == surface,
                  onPressed: () => setState(() => _surface = surface),
                  child: Text(_surfaceLabel(surface)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: switch (_surface) {
              PersonalizationPreviewSurface.title =>
                ProjectBrandingTitlePreview(
                    key: const ValueKey<String>(
                      'personalization-title-composition',
                    ),
                    projectName: widget.projectName,
                    projectRootPath: widget.projectRootPath,
                    branding: widget.profile.branding,
                    theme: widget.profile.theme ?? safeProjectSemanticTheme,
                    typography: widget.profile.typography,
                  ),
              PersonalizationPreviewSurface.dialogue =>
                _DialogueRuntimePreview(
                  projection: surfaceProjection,
                  theme: widget.profile.theme ?? safeProjectSemanticTheme,
                ),
              PersonalizationPreviewSurface.menu => _MenuRuntimePreview(
                  projection: surfaceProjection,
                  theme: widget.profile.theme ?? safeProjectSemanticTheme,
                ),
              PersonalizationPreviewSurface.overworldHud =>
                _OverworldHudRuntimePreview(
                  projection: surfaceProjection,
                  theme: widget.profile.theme ?? safeProjectSemanticTheme,
                ),
              PersonalizationPreviewSurface.battleHud =>
                _BattleHudRuntimePreview(
                  projection: surfaceProjection,
                  theme: widget.profile.theme ?? safeProjectSemanticTheme,
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _DialogueRuntimePreview extends StatelessWidget {
  const _DialogueRuntimePreview({
    required this.projection,
    required this.theme,
  });

  final PersonalizationPreviewSurfaceProjection projection;
  final ProjectSemanticThemeProfile theme;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final background = _previewColor(theme.background, colors.surfaceSubtle);
    final surface = _previewColor(
      projection.backgroundHex,
      colors.surfaceBase,
    );
    final foreground = _previewColor(
      projection.textHex,
      colors.textPrimary,
    );
    final secondary = _previewColor(theme.textSecondary, colors.textSecondary);
    final outline = _previewColor(theme.outline, colors.borderStrong);
    final primary = _previewColor(theme.primary, colors.brandPrimary);

    return _RuntimeFrame(
      key: const ValueKey<String>('personalization-dialogue-composition'),
      background: background,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 20,
            top: 18,
            child: Icon(Icons.park_outlined, size: 54, color: secondary),
          ),
          Positioned(
            right: 30,
            top: 28,
            child: Icon(Icons.home_outlined, size: 48, color: secondary),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: outline, width: 2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: _previewColor(
                        theme.onPrimary,
                        colors.textInverse,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Professeure Saule',
                          style: TextStyle(
                            color: primary,
                            fontFamily: projection.fontFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Le monde est peuplé de créatures étonnantes. '
                          'Partons à leur rencontre !',
                          key: const ValueKey<String>(
                            'personalization-dialogue-sample-text',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontFamily: projection.fontFamily,
                            fontSize: 14,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRuntimePreview extends StatelessWidget {
  const _MenuRuntimePreview({
    required this.projection,
    required this.theme,
  });

  final PersonalizationPreviewSurfaceProjection projection;
  final ProjectSemanticThemeProfile theme;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final background = _previewColor(
      projection.backgroundHex,
      colors.surfaceSubtle,
    );
    final foreground = _previewColor(
      projection.textHex,
      colors.textPrimary,
    );
    final secondary = _previewColor(theme.textSecondary, colors.textSecondary);
    final elevated = _previewColor(
      theme.surfaceElevated,
      colors.surfaceRaised,
    );
    final primary = _previewColor(theme.primary, colors.brandPrimary);
    final outline = _previewColor(theme.outline, colors.borderStrong);

    const entries = <(IconData, String)>[
      (Icons.catching_pokemon_outlined, 'ÉQUIPE'),
      (Icons.backpack_outlined, 'SAC'),
      (Icons.map_outlined, 'CARTE'),
      (Icons.settings_outlined, 'OPTIONS'),
    ];
    return _RuntimeFrame(
      key: const ValueKey<String>('personalization-menu-composition'),
      background: background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.menu_book_outlined, color: primary),
                const SizedBox(width: 8),
                Text(
                  'MENU',
                  style: TextStyle(
                    color: foreground,
                    fontFamily: projection.fontFamily,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '12:34',
                  style: TextStyle(
                    color: secondary,
                    fontFamily: projection.fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 3.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: <Widget>[
                  for (var index = 0; index < entries.length; index++)
                    Container(
                      decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: index == 0 ? primary : outline,
                          width: index == 0 ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            entries[index].$1,
                            color: index == 0 ? primary : secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entries[index].$2,
                            key: index == 0
                                ? const ValueKey<String>(
                                    'personalization-menu-sample-text',
                                  )
                                : null,
                            style: TextStyle(
                              color: foreground,
                              fontFamily: projection.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverworldHudRuntimePreview extends StatelessWidget {
  const _OverworldHudRuntimePreview({
    required this.projection,
    required this.theme,
  });

  final PersonalizationPreviewSurfaceProjection projection;
  final ProjectSemanticThemeProfile theme;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final world = _previewColor(theme.background, colors.surfaceSubtle);
    final surface = _previewColor(
      projection.backgroundHex,
      colors.surfaceBase,
    );
    final foreground = _previewColor(
      projection.textHex,
      colors.textPrimary,
    );
    final secondary = _previewColor(theme.textSecondary, colors.textSecondary);
    final primary = _previewColor(theme.primary, colors.brandPrimary);
    final outline = _previewColor(theme.outline, colors.borderStrong);

    return _RuntimeFrame(
      key: const ValueKey<String>(
        'personalization-overworld-hud-composition',
      ),
      background: world,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: 0.42,
              child: Wrap(
                spacing: 24,
                runSpacing: 20,
                children: <Widget>[
                  for (var index = 0; index < 28; index++)
                    Icon(
                      index.isEven
                          ? Icons.grass_outlined
                          : Icons.circle_outlined,
                      size: 18,
                      color: secondary,
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.explore_outlined, size: 18, color: primary),
                  const SizedBox(width: 7),
                  Text(
                    'Route des Brumes',
                    style: TextStyle(
                      color: foreground,
                      fontFamily: projection.fontFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary, width: 2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.flag_outlined, size: 18, color: primary),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Rejoins le laboratoire de la Professeure Saule.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontFamily: projection.fontFamily,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.directions_walk_outlined,
              color: primary,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleHudRuntimePreview extends StatelessWidget {
  const _BattleHudRuntimePreview({
    required this.projection,
    required this.theme,
  });

  final PersonalizationPreviewSurfaceProjection projection;
  final ProjectSemanticThemeProfile theme;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final arena = _previewColor(theme.background, colors.surfaceSubtle);
    final surface = _previewColor(
      projection.backgroundHex,
      colors.surfaceBase,
    );
    final foreground = _previewColor(
      projection.textHex,
      colors.textPrimary,
    );
    final secondary = _previewColor(theme.textSecondary, colors.textSecondary);
    final outline = _previewColor(theme.outline, colors.borderStrong);
    final success = _previewColor(theme.success, colors.success);
    final danger = _previewColor(theme.danger, colors.error);

    return _RuntimeFrame(
      key: const ValueKey<String>('personalization-battle-hud-composition'),
      background: arena,
      child: Stack(
        children: <Widget>[
          Positioned(
            right: 34,
            top: 62,
            child: Icon(
              Icons.catching_pokemon_outlined,
              size: 76,
              color: danger,
            ),
          ),
          Positioned(
            left: 44,
            bottom: 28,
            child: Icon(
              Icons.catching_pokemon_rounded,
              size: 86,
              color: success,
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: _BattleStatusCard(
              name: 'ROUCOOL',
              level: 'N. 8',
              hpLabel: 'PV',
              hpFraction: 0.72,
              projection: projection,
              surface: surface,
              foreground: foreground,
              secondary: secondary,
              outline: outline,
              hpColor: success,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: _BattleStatusCard(
              name: 'BRINDIBOU',
              level: 'N. 12',
              hpLabel: 'PV 42 / 55',
              hpFraction: 42 / 55,
              projection: projection,
              surface: surface,
              foreground: foreground,
              secondary: secondary,
              outline: outline,
              hpColor: success,
              numbersKey: const ValueKey<String>(
                'personalization-battle-numbers-sample',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleStatusCard extends StatelessWidget {
  const _BattleStatusCard({
    required this.name,
    required this.level,
    required this.hpLabel,
    required this.hpFraction,
    required this.projection,
    required this.surface,
    required this.foreground,
    required this.secondary,
    required this.outline,
    required this.hpColor,
    this.numbersKey,
  });

  final String name;
  final String level;
  final String hpLabel;
  final double hpFraction;
  final PersonalizationPreviewSurfaceProjection projection;
  final Color surface;
  final Color foreground;
  final Color secondary;
  final Color outline;
  final Color hpColor;
  final Key? numbersKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: foreground,
                    fontFamily: projection.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                level,
                style: TextStyle(
                  color: secondary,
                  fontFamily: projection.fontFamily,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: hpFraction,
              color: hpColor,
              backgroundColor: outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hpLabel,
            key: numbersKey,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: foreground,
              fontFamily: projection.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuntimeFrame extends StatelessWidget {
  const _RuntimeFrame({
    super.key,
    required this.background,
    required this.child,
  });

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: context.pokeMapColors.borderSubtle),
          ),
          child: child,
        ),
      ),
    );
  }
}

Color _previewColor(String value, Color fallback) {
  final normalized = value.trim();
  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(normalized)) return fallback;
  return Color(
    0xff000000 | int.parse(normalized.substring(1), radix: 16),
  );
}

String _surfaceLabel(PersonalizationPreviewSurface surface) => switch (surface) {
      PersonalizationPreviewSurface.title => 'Titre',
      PersonalizationPreviewSurface.dialogue => 'Dialogue',
      PersonalizationPreviewSurface.menu => 'Menu',
      PersonalizationPreviewSurface.overworldHud => 'HUD exploration',
      PersonalizationPreviewSurface.battleHud => 'HUD combat',
    };
