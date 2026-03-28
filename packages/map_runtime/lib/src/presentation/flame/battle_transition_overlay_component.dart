import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../../application/battle_start_request.dart';

class BattleTransitionOverlayComponent extends PositionComponent {
  BattleTransitionOverlayComponent({
    required this.request,
    required Vector2 viewportSize,
    required this.onFinished,
    this.duration = const Duration(milliseconds: 420),
  }) : super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 96,
        );

  final BattleStartRequest request;
  final VoidCallback onFinished;
  final Duration duration;
  bool _closed = false;

  @override
  Future<void> onLoad() async {
    final blocker = RectangleComponent(
      size: size.clone(),
      paint: Paint()..color = const Color(0xEE050505),
      anchor: Anchor.topLeft,
      priority: 0,
    );
    add(blocker);

    final title = TextComponent(
      text: _titleForRequest(request),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - 10),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF8F8F8),
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    add(title);

    final subtitle = TextComponent(
      text: 'Transition vers le combat...',
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 + 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFDFDFDF),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    add(subtitle);

    Future.delayed(duration, close);
  }

  String _titleForRequest(BattleStartRequest request) {
    return switch (request) {
      WildBattleStartRequest(:final speciesId) =>
        'Un $speciesId sauvage apparaît !',
      TrainerBattleStartRequest() => 'Un dresseur vous défie !',
    };
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
