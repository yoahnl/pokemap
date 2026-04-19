import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// Placeholder visuel de combattant pour la battle scene runtime.
///
/// Le lot 4b modernise la lecture de scène sans mentir :
/// - toujours aucun sprite battle dédié ;
/// - toujours aucune dépendance battle-core ;
/// - mais une silhouette plus vivante, avec une plateforme plus lisible et un
///   vrai ancrage joueur/ennemi inspiré du rythme du gif de référence.
class BattleSceneCombatantComponent extends PositionComponent {
  BattleSceneCombatantComponent({
    required Vector2 position,
    required Vector2 size,
    required this.isPlayerSide,
    required String speciesLabel,
  })  : _speciesLabel = speciesLabel,
        super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 10,
        );

  final bool isPlayerSide;

  String _speciesLabel;
  TextComponent? _speciesText;
  TextComponent? _monogramText;

  @override
  Future<void> onLoad() async {
    _speciesText = TextComponent(
      text: _speciesLabel,
      position: Vector2(size.x / 2, size.y - 8),
      anchor: Anchor.bottomCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF8FBFF),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      priority: 13,
    );
    await add(_speciesText!);

    _monogramText = TextComponent(
      text: _speciesMonogram(_speciesLabel),
      position: Vector2(size.x * 0.54, size.y * 0.4),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xF8FFFFFF),
          fontSize: 34,
          fontWeight: FontWeight.w900,
        ),
      ),
      priority: 13,
    );
    await add(_monogramText!);
  }

  void sync({
    required String speciesLabel,
  }) {
    _speciesLabel = speciesLabel;
    _speciesText?.text = _speciesLabel;
    _monogramText?.text = _speciesMonogram(_speciesLabel);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final platformRect = Rect.fromCenter(
      center: Offset(size.x * 0.56, size.y * 0.8),
      width: size.x * (isPlayerSide ? 0.86 : 0.7),
      height: isPlayerSide ? 34 : 28,
    );
    canvas.drawOval(
      platformRect,
      Paint()..color = const Color(0x995E4E34),
    );
    canvas.drawOval(
      platformRect.deflate(5),
      Paint()..color = const Color(0xFFD8C59E),
    );

    final shadowRect = Rect.fromCenter(
      center: Offset(size.x * 0.54, size.y * 0.69),
      width: size.x * 0.42,
      height: size.y * 0.12,
    );
    canvas.drawOval(
      shadowRect,
      Paint()..color = const Color(0x33000000),
    );

    final auraRect = Rect.fromCenter(
      center: Offset(size.x * (isPlayerSide ? 0.48 : 0.58), size.y * 0.42),
      width: size.x * (isPlayerSide ? 0.64 : 0.48),
      height: size.y * 0.54,
    );
    canvas.drawOval(
      auraRect,
      Paint()
        ..shader = RadialGradient(
          colors: isPlayerSide
              ? const <Color>[
                  Color(0x667AA9F4),
                  Color(0x00000000),
                ]
              : const <Color>[
                  Color(0x66B9D27A),
                  Color(0x00000000),
                ],
        ).createShader(auraRect),
    );

    _renderSilhouette(canvas);
  }

  void _renderSilhouette(Canvas canvas) {
    final primaryColor =
        isPlayerSide ? const Color(0xFF3E4B7E) : const Color(0xFF6B87B7);
    final secondaryColor =
        isPlayerSide ? const Color(0xFF7DB4F7) : const Color(0xFFD7E8FF);

    final bodyRect = Rect.fromCenter(
      center: Offset(size.x * 0.52, size.y * 0.44),
      width: size.x * (isPlayerSide ? 0.42 : 0.28),
      height: size.y * (isPlayerSide ? 0.48 : 0.34),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(34)),
      Paint()..color = primaryColor,
    );

    final chestRect = Rect.fromCenter(
      center: Offset(size.x * 0.54, size.y * 0.46),
      width: bodyRect.width * 0.72,
      height: bodyRect.height * 0.68,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chestRect, const Radius.circular(28)),
      Paint()..color = secondaryColor.withValues(alpha: 0.88),
    );

    final headRect = Rect.fromCircle(
      center: Offset(size.x * 0.5, size.y * 0.22),
      radius: isPlayerSide ? size.x * 0.11 : size.x * 0.085,
    );
    canvas.drawOval(
      headRect,
      Paint()..color = secondaryColor,
    );

    final accentPath = Path();
    if (isPlayerSide) {
      accentPath
        ..moveTo(size.x * 0.3, size.y * 0.44)
        ..lineTo(size.x * 0.14, size.y * 0.3)
        ..lineTo(size.x * 0.2, size.y * 0.58)
        ..close();
    } else {
      accentPath
        ..moveTo(size.x * 0.6, size.y * 0.34)
        ..lineTo(size.x * 0.8, size.y * 0.2)
        ..lineTo(size.x * 0.74, size.y * 0.5)
        ..close();
    }
    canvas.drawPath(accentPath, Paint()..color = primaryColor.withValues(alpha: 0.92));
  }

  String _speciesMonogram(String speciesLabel) {
    final trimmed = speciesLabel.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.substring(0, 1).toUpperCase();
  }
}
