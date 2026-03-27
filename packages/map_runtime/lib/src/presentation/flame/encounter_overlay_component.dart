import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_gameplay/map_gameplay.dart';

class EncounterOverlayComponent extends PositionComponent {
  EncounterOverlayComponent({
    required this.encounter,
    required Vector2 viewportSize,
    required this.onFinished,
    this.displayDuration = const Duration(milliseconds: 1100),
  }) : super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 95,
        );

  final GameplayEncounter encounter;
  final VoidCallback onFinished;
  final Duration displayDuration;
  bool _closed = false;

  @override
  Future<void> onLoad() async {
    final width = (size.x - 40).clamp(180.0, 560.0);
    const panelHeight = 84.0;
    final panel = RectangleComponent(
      position: Vector2((size.x - width) / 2, size.y - panelHeight - 24),
      size: Vector2(width, panelHeight),
      paint: Paint()..color = const Color(0xCC111111),
      anchor: Anchor.topLeft,
    );

    final border = RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(width, panelHeight),
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x66FFFFFF),
      anchor: Anchor.topLeft,
    );
    panel.add(border);

    final title = TextComponent(
      text: 'Rencontre sauvage',
      position: Vector2(14, 12),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF6F6F6),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      anchor: Anchor.topLeft,
    );
    panel.add(title);

    final subtitle = TextComponent(
      text: '${encounter.speciesId} · Niv. ${encounter.level}',
      position: Vector2(14, 44),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE9E9E9),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      anchor: Anchor.topLeft,
    );
    panel.add(subtitle);

    add(panel);

    Future.delayed(displayDuration, close);
  }

  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    removeFromParent();
    onFinished();
  }
}
