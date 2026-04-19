import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'battle_background_resolver.dart';

/// Fond de scène par défaut pour le lot 1.
///
/// Garde-fous de périmètre :
/// - ce composant vit côté `map_runtime` parce qu'il ne transporte aucune
///   vérité métier battle ; il ne fait que peindre une ambiance de scène ;
/// - après le lot 2, il reste volontairement borné à la consommation d'une
///   petite spec déjà résolue ;
/// - il ne résout lui-même ni biome, ni map, ni trainer, ni encounter ;
/// - ce vrai seam de résolution appartient explicitement au runtime amont.
class BattleSceneBackdropComponent extends PositionComponent {
  BattleSceneBackdropComponent({
    required Vector2 size,
    BattleBackgroundSpec backgroundSpec =
        const BattleBackgroundSpec.fallbackField(),
  })  : _backgroundSpec = backgroundSpec,
        super(
          size: size,
          anchor: Anchor.topLeft,
          priority: 0,
        );

  BattleBackgroundSpec _backgroundSpec;

  @visibleForTesting
  BattleBackgroundKey get currentBackgroundKey => _backgroundSpec.key;

  /// Le backdrop reste un consommateur passif de spec.
  ///
  /// Pourquoi ce setter existe déjà :
  /// - il garde le composant localement testable ;
  /// - il laisse le lot 2 injecter une variation de contexte visible ;
  /// - il ne promet pas pour autant un système de theming plus large.
  void sync({
    required BattleBackgroundSpec backgroundSpec,
  }) {
    _backgroundSpec = backgroundSpec;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Offset.zero & Size(size.x, size.y);
    final palette = _paletteFor(_backgroundSpec.key);

    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.y),
        palette.skyColors,
        const <double>[0.0, 0.36, 0.72, 1.0],
      );
    canvas.drawRect(rect, skyPaint);

    final horizonGlowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.x * palette.glowCenterDx, size.y * palette.glowCenterDy),
        size.x * palette.glowRadiusScale,
        <Color>[
          palette.glowColor,
          palette.glowColor.withValues(alpha: 0.08),
          const Color(0x00000000),
        ],
        const <double>[0.0, 0.45, 1.0],
      );
    canvas.drawRect(rect, horizonGlowPaint);

    _renderMidground(canvas, palette);
    _renderFloor(canvas, palette);
    _renderForegroundAccent(canvas, palette);
  }

  void _renderMidground(Canvas canvas, _BattleBackdropPalette palette) {
    switch (_backgroundSpec.key) {
      case BattleBackgroundKey.fallbackField:
        _renderFallbackBands(canvas, palette);
      case BattleBackgroundKey.wildOutdoor:
        _renderWildHills(canvas, palette);
      case BattleBackgroundKey.trainerOutdoor:
        _renderTrainerBanners(canvas, palette);
      case BattleBackgroundKey.indoor:
        _renderIndoorPanels(canvas, palette);
    }
  }

  void _renderFallbackBands(Canvas canvas, _BattleBackdropPalette palette) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.08, size.y * 0.18, size.x * 0.62, 22),
        const Radius.circular(14),
      ),
      Paint()..color = palette.bandColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.28, size.y * 0.28, size.x * 0.52, 18),
        const Radius.circular(12),
      ),
      Paint()..color = palette.softBandColor,
    );
  }

  void _renderWildHills(Canvas canvas, _BattleBackdropPalette palette) {
    final hillPaint = Paint()..color = palette.bandColor;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.22, size.y * 0.55),
        width: size.x * 0.48,
        height: size.y * 0.22,
      ),
      hillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.66, size.y * 0.5),
        width: size.x * 0.66,
        height: size.y * 0.28,
      ),
      Paint()..color = palette.softBandColor,
    );
  }

  void _renderTrainerBanners(Canvas canvas, _BattleBackdropPalette palette) {
    final leftPath = Path()
      ..moveTo(0, size.y * 0.16)
      ..lineTo(size.x * 0.2, size.y * 0.12)
      ..lineTo(size.x * 0.34, size.y * 0.46)
      ..lineTo(0, size.y * 0.42)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = palette.bandColor);

    final rightPath = Path()
      ..moveTo(size.x, size.y * 0.12)
      ..lineTo(size.x * 0.78, size.y * 0.08)
      ..lineTo(size.x * 0.6, size.y * 0.42)
      ..lineTo(size.x, size.y * 0.38)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = palette.softBandColor);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.28, size.y * 0.22, size.x * 0.44, 14),
        const Radius.circular(10),
      ),
      Paint()..color = palette.ribbonColor,
    );
  }

  void _renderIndoorPanels(Canvas canvas, _BattleBackdropPalette palette) {
    final wallRect = Rect.fromLTWH(
        size.x * 0.08, size.y * 0.14, size.x * 0.84, size.y * 0.34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(wallRect, const Radius.circular(26)),
      Paint()..color = palette.bandColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        wallRect.deflate(12),
        const Radius.circular(18),
      ),
      Paint()..color = palette.softBandColor,
    );

    final spotlightPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.x * 0.5, size.y * 0.62),
        size.x * 0.24,
        <Color>[
          palette.ribbonColor,
          palette.ribbonColor.withValues(alpha: 0.0),
        ],
      );
    canvas.drawRect(Offset.zero & Size(size.x, size.y), spotlightPaint);
  }

  void _renderFloor(Canvas canvas, _BattleBackdropPalette palette) {
    final floorPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.y * 0.58),
        Offset(0, size.y),
        palette.floorColors,
        const <double>[0.0, 0.34, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.58, size.x, size.y * 0.42),
      floorPaint,
    );
  }

  void _renderForegroundAccent(Canvas canvas, _BattleBackdropPalette palette) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.24, size.y * 0.73),
        width: size.x * 0.24,
        height: size.y * 0.06,
      ),
      Paint()..color = palette.floorAccentColor,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.74, size.y * 0.41),
        width: size.x * 0.18,
        height: size.y * 0.05,
      ),
      Paint()..color = palette.softBandColor.withValues(alpha: 0.45),
    );
  }

  _BattleBackdropPalette _paletteFor(BattleBackgroundKey key) {
    return switch (key) {
      BattleBackgroundKey.fallbackField => const _BattleBackdropPalette(
          skyColors: <Color>[
            Color(0xFF16243B),
            Color(0xFF263B5D),
            Color(0xFF4F7A79),
            Color(0xFF99A56E),
          ],
          floorColors: <Color>[
            Color(0x14000000),
            Color(0x4411161E),
            Color(0xCC0B0E14),
          ],
          glowColor: Color(0x55FFF7C8),
          bandColor: Color(0x12FFFFFF),
          softBandColor: Color(0x10FFFFFF),
          ribbonColor: Color(0x16FFFFFF),
          floorAccentColor: Color(0x24000000),
          glowCenterDx: 0.52,
          glowCenterDy: 0.42,
          glowRadiusScale: 0.42,
        ),
      BattleBackgroundKey.wildOutdoor => const _BattleBackdropPalette(
          skyColors: <Color>[
            Color(0xFF10304D),
            Color(0xFF215F6B),
            Color(0xFF5A9A6F),
            Color(0xFFB9C97A),
          ],
          floorColors: <Color>[
            Color(0x18050C08),
            Color(0x66151F12),
            Color(0xD012140F),
          ],
          glowColor: Color(0x6BFFF2B4),
          bandColor: Color(0x4C3E6F58),
          softBandColor: Color(0x384FA172),
          ribbonColor: Color(0x26E6FFD0),
          floorAccentColor: Color(0x38456A35),
          glowCenterDx: 0.44,
          glowCenterDy: 0.38,
          glowRadiusScale: 0.34,
        ),
      BattleBackgroundKey.trainerOutdoor => const _BattleBackdropPalette(
          skyColors: <Color>[
            Color(0xFF2A163C),
            Color(0xFF6D3151),
            Color(0xFFB75A45),
            Color(0xFFE0AE61),
          ],
          floorColors: <Color>[
            Color(0x180B0608),
            Color(0x6B2D1517),
            Color(0xD0140D12),
          ],
          glowColor: Color(0x75FFD4A4),
          bandColor: Color(0x523E1B43),
          softBandColor: Color(0x4FA33E57),
          ribbonColor: Color(0x40FFE2A0),
          floorAccentColor: Color(0x42321A25),
          glowCenterDx: 0.5,
          glowCenterDy: 0.32,
          glowRadiusScale: 0.3,
        ),
      BattleBackgroundKey.indoor => const _BattleBackdropPalette(
          skyColors: <Color>[
            Color(0xFF141729),
            Color(0xFF232742),
            Color(0xFF394063),
            Color(0xFF6B6A78),
          ],
          floorColors: <Color>[
            Color(0x1A020305),
            Color(0x8036374A),
            Color(0xD0111219),
          ],
          glowColor: Color(0x4CC9D9FF),
          bandColor: Color(0x5B252A3B),
          softBandColor: Color(0x643C435D),
          ribbonColor: Color(0x3838F0FF),
          floorAccentColor: Color(0x3B727A95),
          glowCenterDx: 0.5,
          glowCenterDy: 0.24,
          glowRadiusScale: 0.24,
        ),
    };
  }
}

final class _BattleBackdropPalette {
  const _BattleBackdropPalette({
    required this.skyColors,
    required this.floorColors,
    required this.glowColor,
    required this.bandColor,
    required this.softBandColor,
    required this.ribbonColor,
    required this.floorAccentColor,
    required this.glowCenterDx,
    required this.glowCenterDy,
    required this.glowRadiusScale,
  });

  final List<Color> skyColors;
  final List<Color> floorColors;
  final Color glowColor;
  final Color bandColor;
  final Color softBandColor;
  final Color ribbonColor;
  final Color floorAccentColor;
  final double glowCenterDx;
  final double glowCenterDy;
  final double glowRadiusScale;
}
