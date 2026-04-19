import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// Placeholder visuel de combattant pour le lot 1.
///
/// Ce composant sert uniquement à donner une vraie lecture de scène :
/// - un ancrage visuel côté ennemi ;
/// - un ancrage visuel côté joueur ;
/// - sans dépendre d'assets battle dédiés qui n'existent pas encore.
///
/// Garde-fous :
/// - aucun sprite loading ;
/// - aucune vérité métier ;
/// - aucune tentative de résoudre un fond contextuel ;
/// - aucune tentative d'ouvrir une pipeline d'assets "pour plus tard".
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
  TextComponent? _roleText;
  TextComponent? _speciesText;
  TextComponent? _monogramText;

  @override
  Future<void> onLoad() async {
    // Le rendu reste volontairement très sobre :
    // il donne une présence de scène au combattant, mais laisse le vrai futur
    // travail d'assets ou d'arrière-plan contextuel aux lots suivants.
    _roleText = TextComponent(
      text: isPlayerSide ? 'JOUEUR' : 'ENNEMI',
      position: Vector2(0, isPlayerSide ? size.y - 20 : 6),
      anchor: isPlayerSide ? Anchor.bottomLeft : Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xCCFFFFFF),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
    await add(_roleText!);

    _speciesText = TextComponent(
      text: _speciesLabel,
      position: Vector2(
        size.x / 2,
        isPlayerSide ? size.y - 12 : size.y - 20,
      ),
      anchor: Anchor.bottomCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF5F7FB),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 13,
    );
    await add(_speciesText!);

    _monogramText = TextComponent(
      text: _speciesMonogram(_speciesLabel),
      position: Vector2(size.x / 2, size.y * 0.38),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF3F6FF),
          fontSize: 34,
          fontWeight: FontWeight.w800,
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

    final baseY = size.y * 0.72;
    final platformRect = Rect.fromCenter(
      center: Offset(size.x * 0.5, baseY + 22),
      width: size.x * 0.78,
      height: isPlayerSide ? 28 : 24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(platformRect, const Radius.circular(20)),
      Paint()..color = const Color(0x1AFFFFFF),
    );

    final shadowRect = Rect.fromCenter(
      center: Offset(size.x * 0.5, baseY + 6),
      width: size.x * 0.46,
      height: size.y * 0.14,
    );
    canvas.drawOval(
      shadowRect,
      Paint()..color = const Color(0x55000000),
    );

    final bodyRect = Rect.fromCenter(
      center: Offset(size.x * 0.5, size.y * 0.42),
      width: isPlayerSide ? size.x * 0.44 : size.x * 0.34,
      height: isPlayerSide ? size.y * 0.48 : size.y * 0.38,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(28)),
      Paint()
        ..color =
            isPlayerSide ? const Color(0xD83C5F92) : const Color(0xD8A75E4F),
    );

    final innerRect = bodyRect.deflate(10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(22)),
      Paint()
        ..color =
            isPlayerSide ? const Color(0xCC7FC0FF) : const Color(0xCCFFD7A8),
    );
  }

  String _speciesMonogram(String speciesLabel) {
    final trimmed = speciesLabel.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.substring(0, 1).toUpperCase();
  }
}
