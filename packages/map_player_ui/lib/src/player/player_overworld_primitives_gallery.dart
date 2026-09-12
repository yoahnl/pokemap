import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_overworld_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';

enum PlayerOverworldGalleryState {
  idle,
  interaction,
  movement,
  running,
  hardware,
  pressed,
  focused,
  disabled,
  hidden,
}

enum PlayerOverworldGalleryBackdrop { dark, light, busy }

class PlayerOverworldPrimitivesGallery extends StatelessWidget {
  const PlayerOverworldPrimitivesGallery({
    super.key,
    this.state = PlayerOverworldGalleryState.interaction,
    this.backdrop = PlayerOverworldGalleryBackdrop.dark,
    this.opaque = false,
    this.highContrast = false,
    this.reducedMotion = false,
    this.textScale = 1,
    this.actionLabel,
    this.glyph = '×',
    this.theme,
    this.onInvoked,
  });

  final PlayerOverworldGalleryState state;
  final PlayerOverworldGalleryBackdrop backdrop;
  final bool opaque;
  final bool highContrast;
  final bool reducedMotion;
  final double textScale;
  final String? actionLabel;
  final String glyph;
  final ThemeData? theme;
  final ValueChanged<String>? onInvoked;

  @override
  Widget build(BuildContext context) => Theme(
        data: theme ??
            PokeMapPlayerTheme.dark(
              highContrast: highContrast,
              reducedMotion: reducedMotion,
            ),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            highContrast: highContrast,
            disableAnimations: reducedMotion,
          ),
          child: PlayerMenuEffectsScope(
            effects: opaque
                ? RuntimePlayerMenuEffects.opaque
                : reducedMotion
                    ? RuntimePlayerMenuEffects.reduced
                    : RuntimePlayerMenuEffects.full,
            child: Builder(builder: _buildScene),
          ),
        ),
      );

  Widget _buildScene(BuildContext context) {
    final tokens = context.playerColors;
    final background = backdrop == PlayerOverworldGalleryBackdrop.light
        ? tokens.textPrimary
        : tokens.background;
    final movement = state == PlayerOverworldGalleryState.movement ||
        state == PlayerOverworldGalleryState.running;
    final actionVisible = state != PlayerOverworldGalleryState.idle &&
        state != PlayerOverworldGalleryState.hidden &&
        !movement;
    return Material(
      color: background,
      child: LayoutBuilder(builder: (context, constraints) {
        final insets = MediaQuery.paddingOf(context);
        return Stack(
          children: [
            if (backdrop == PlayerOverworldGalleryBackdrop.busy)
              Positioned.fill(
                child: CustomPaint(
                  painter: _GalleryTexture(tokens: tokens),
                ),
              ),
            PlayerOverworldControlsLayout(
              visible: state != PlayerOverworldGalleryState.hidden,
              menuButton: PlayerOverworldMenuButton(
                key: const ValueKey('overworld-gallery-menu'),
                label: context.playerL10n.menu,
                onPressed: () => onInvoked?.call('menu'),
              ),
              actionCapsule: PlayerOverworldActionCapsule(
                key: const ValueKey('overworld-gallery-action'),
                visible: actionVisible,
                label: actionLabel ?? context.playerL10n.interact,
                icon: Icons.chat_bubble_outline_rounded,
                glyph: state == PlayerOverworldGalleryState.hardware
                    ? glyph
                    : null,
                enabled: state != PlayerOverworldGalleryState.disabled,
                pressed: state == PlayerOverworldGalleryState.pressed,
                focused: state == PlayerOverworldGalleryState.focused,
                onPressed: () => onInvoked?.call('interaction'),
              ),
              joystick: movement
                  ? PlayerOverworldJoystickVisual(
                      anchor: Offset(insets.left + 96,
                          constraints.maxHeight - insets.bottom - 100),
                      displacement: state == PlayerOverworldGalleryState.running
                          ? const Offset(.75, -.45)
                          : const Offset(.25, -.3),
                      running: state == PlayerOverworldGalleryState.running,
                    )
                  : null,
            ),
          ],
        );
      }),
    );
  }
}

class _GalleryTexture extends CustomPainter {
  const _GalleryTexture({required this.tokens});

  final PokeMapPlayerColors tokens;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 24.0;
    final colors = [
      tokens.surface,
      tokens.success,
      tokens.primary,
      tokens.textSecondary,
      tokens.warning
    ];
    for (var row = 0; row * cell < size.height; row++) {
      for (var column = 0; column * cell < size.width; column++) {
        final index = (row * 7 + column * 3 + row * column) % colors.length;
        final rect = Rect.fromLTWH(column * cell, row * cell, cell, cell);
        canvas.drawRect(
            rect, Paint()..color = colors[index].withValues(alpha: .65));
        canvas.drawCircle(rect.center, 4,
            Paint()..color = colors[(index + 2) % colors.length]);
      }
    }
  }

  @override
  bool shouldRepaint(_GalleryTexture oldDelegate) =>
      oldDelegate.tokens != tokens;
}
