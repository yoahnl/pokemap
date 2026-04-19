import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// Panneau debug optionnel pour l'overlay combat.
///
/// Il reste explicitement hors du chemin visuel normal :
/// - le runtime produit l'instancie désactivé par défaut ;
/// - il ne porte que des informations de diagnostic dérivées de la vérité
///   battle/runtime déjà existante ;
/// - il ne doit jamais redevenir la "vraie" UI de combat.
class BattleDebugPanelComponent extends PositionComponent {
  BattleDebugPanelComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 40,
        );

  TextComponent? _titleText;
  TextComponent? _bodyText;

  @override
  Future<void> onLoad() async {
    _titleText = TextComponent(
      text: 'Debug combat',
      position: Vector2(14, 12),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF5F7FB),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    await add(_titleText!);

    _bodyText = TextComponent(
      text: '',
      position: Vector2(14, 36),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE4EAF6),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
      ),
      priority: 41,
    );
    await add(_bodyText!);
  }

  void sync({
    required List<String> lines,
  }) {
    _bodyText?.text = lines.join('\n');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Offset.zero & Size(size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()..color = const Color(0xCC111827),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(1),
        const Radius.circular(17),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x44FFFFFF),
    );
  }
}
