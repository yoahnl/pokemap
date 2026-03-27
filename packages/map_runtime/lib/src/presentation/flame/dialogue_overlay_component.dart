import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../application/dialogue_runtime_models.dart';

/// Callback invoked when the player advances through all dialogue lines.
typedef OnDialogueFinished = void Function();

/// Full-screen HUD overlay that displays a Yarn dialogue session line by line.
///
/// Add this to [camera.viewport] to keep it fixed on screen. Call [advance]
/// each time the player presses the confirm key; it automatically removes
/// itself and calls [onFinished] after the last line.
class DialogueOverlayComponent extends PositionComponent {
  DialogueOverlayComponent({
    required DialogueSession session,
    required this.onFinished,
    required Vector2 viewportSize,
  })  : _session = session,
        super(
          position: Vector2.zero(),
          size: viewportSize,
          priority: 100,
        );

  DialogueSession _session;
  final OnDialogueFinished onFinished;

  static const double _kBoxHeightFraction = 0.28;
  static const double _kPaddingH = 20.0;
  static const double _kPaddingV = 14.0;
  static const double _kCornerRadius = 8.0;
  static const double _kFontSize = 15.0;
  static const double _kHintFontSize = 11.0;
  static final Color _kHintColor = Colors.white.withValues(alpha: 0.55);

  static final Paint _bgPaint = Paint()..color = const Color(0xDD000000);
  static final Paint _borderPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  late TextPainter _textPainter;
  late TextPainter _hintPainter;

  @override
  Future<void> onLoad() async {
    _rebuildPainters();
    return super.onLoad();
  }

  void _rebuildPainters() {
    _textPainter = TextPainter(
      text: TextSpan(
        text: _session.currentLine,
        style: const TextStyle(
          color: Colors.white,
          fontSize: _kFontSize,
          height: 1.4,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 4,
    )..layout(maxWidth: size.x - 32 - _kPaddingH * 2);

    _hintPainter = TextPainter(
      text: TextSpan(
        text: _session.isLastLine ? 'E · Fermer' : 'E · Suite',
        style: TextStyle(color: _kHintColor, fontSize: _kHintFontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void render(Canvas canvas) {
    final vw = size.x;
    final vh = size.y;
    final boxH = vh * _kBoxHeightFraction;
    final boxY = vh - boxH - 16.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(16, boxY, vw - 32, boxH),
      const Radius.circular(_kCornerRadius),
    );
    canvas.drawRRect(rrect, _bgPaint);
    canvas.drawRRect(rrect, _borderPaint);

    _textPainter.paint(canvas, Offset(16 + _kPaddingH, boxY + _kPaddingV));

    _hintPainter.paint(
      canvas,
      Offset(
        16 + (vw - 32) - _kPaddingH - _hintPainter.width,
        boxY + boxH - _kPaddingV - _hintPainter.height,
      ),
    );
  }

  /// Advance to the next line. Returns true if the dialogue is still open,
  /// false if it just finished (component removes itself automatically).
  bool advance() {
    final next = _session.advance();
    if (next == null) {
      removeFromParent();
      onFinished();
      return false;
    }
    _session = next;
    _rebuildPainters();
    return true;
  }
}
