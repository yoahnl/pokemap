import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../../application/battle_start_request.dart';

class BattleOverlayComponent extends PositionComponent {
  BattleOverlayComponent({
    required this.request,
    required Vector2 viewportSize,
    required this.onExitRequested,
  }) : super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 97,
        );

  final BattleStartRequest request;
  final VoidCallback onExitRequested;
  bool _closed = false;

  @override
  Future<void> onLoad() async {
    final bg = RectangleComponent(
      size: size.clone(),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xF20B1020),
      priority: 0,
    );
    add(bg);

    final panelWidth = (size.x - 80).clamp(240.0, 760.0);
    final panelHeight = (size.y - 120).clamp(220.0, 520.0);
    final panel = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      position: Vector2((size.x - panelWidth) / 2, (size.y - panelHeight) / 2),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xE81A223B),
      priority: 1,
    );
    add(panel);

    final panelBorder = RectangleComponent(
      size: panel.size.clone(),
      anchor: Anchor.topLeft,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x66FFFFFF),
      priority: 2,
    );
    panel.add(panelBorder);

    final title = TextComponent(
      text: _titleForRequest(request),
      anchor: Anchor.topLeft,
      position: Vector2(22, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF5F5F5),
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 3,
    );
    panel.add(title);

    final lines = _detailLinesForRequest(request);
    for (var i = 0; i < lines.length; i++) {
      final line = TextComponent(
        text: lines[i],
        anchor: Anchor.topLeft,
        position: Vector2(22, 72 + i * 28),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFFE5E9F2),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        priority: 3,
      );
      panel.add(line);
    }

    final hint = TextComponent(
      text: 'MVP battle shell — E / Space / Enter / Esc pour revenir',
      anchor: Anchor.bottomLeft,
      position: Vector2(22, panelHeight - 18),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFC4CCDA),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    panel.add(hint);
  }

  String _titleForRequest(BattleStartRequest request) {
    return switch (request) {
      WildBattleStartRequest() => 'Combat sauvage',
      TrainerBattleStartRequest() => 'Combat dresseur',
    };
  }

  List<String> _detailLinesForRequest(BattleStartRequest request) {
    return switch (request) {
      WildBattleStartRequest(
        :final speciesId,
        :final level,
        :final encounterKind,
        :final mapId,
      ) =>
        <String>[
          'Espèce: $speciesId',
          'Niveau: $level',
          'Type rencontre: ${encounterKind.name}',
          'Map source: $mapId',
        ],
      TrainerBattleStartRequest(:final trainerId, :final mapId) => <String>[
          'Trainer ID: $trainerId',
          'Map source: $mapId',
        ],
    };
  }

  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    removeFromParent();
    onExitRequested();
  }
}
