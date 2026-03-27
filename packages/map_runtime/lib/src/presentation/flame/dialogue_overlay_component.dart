import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../application/dialogue_runtime_models.dart';

typedef OnDialogueFinished = void Function();

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
  static const double _kChoiceLineHeight = 26.0;
  static final Color _kHintColor = Colors.white.withValues(alpha: 0.55);

  static final Paint _bgPaint = Paint()..color = const Color(0xDD000000);
  static final Paint _borderPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  late TextPainter _textPainter;
  late TextPainter _hintPainter;
  late TextPainter _cursorPainter;
  List<TextPainter> _choicePainters = [];

  DialogueSession get currentSession => _session;

  bool get isShowingChoices => _session.state is DialogueWaitingForChoice;

  @override
  Future<void> onLoad() async {
    _cursorPainter = TextPainter(
      text: const TextSpan(
        text: '▶',
        style: TextStyle(color: Colors.white, fontSize: _kFontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _rebuildPainters();
    return super.onLoad();
  }

  void _rebuildPainters() {
    final state = _session.state;
    if (state is DialogueShowingLine) {
      _rebuildLinePainters(state);
    } else if (state is DialogueWaitingForChoice) {
      _rebuildChoicePainters(state);
    }
  }

  void _rebuildLinePainters(DialogueShowingLine state) {
    _textPainter = TextPainter(
      text: TextSpan(
        text: state.text,
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
        text: _session.isLastContent ? 'E · Fermer' : 'E · Suite',
        style: TextStyle(color: _kHintColor, fontSize: _kHintFontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _rebuildChoicePainters(DialogueWaitingForChoice state) {
    final maxW =
        size.x - 32 - _kPaddingH * 2 - _cursorPainter.width - 8;
    _choicePainters = state.choices
        .map(
          (c) => TextPainter(
            text: TextSpan(
              text: c.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: _kFontSize,
                height: 1.4,
                fontFamily: 'monospace',
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout(maxWidth: maxW),
        )
        .toList();

    _hintPainter = TextPainter(
      text: TextSpan(
        text: '↑/↓ · Choisir  E · Valider',
        style: TextStyle(color: _kHintColor, fontSize: _kHintFontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void render(Canvas canvas) {
    final state = _session.state;
    if (state is DialogueShowingLine) {
      _renderLine(canvas);
    } else if (state is DialogueWaitingForChoice) {
      _renderChoices(canvas, state);
    }
  }

  void _renderLine(Canvas canvas) {
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

  void _renderChoices(Canvas canvas, DialogueWaitingForChoice state) {
    final vw = size.x;
    final vh = size.y;
    final boxH = _kPaddingV * 2 +
        state.choices.length * _kChoiceLineHeight +
        _kHintFontSize * 2.0;
    final boxY = vh - boxH - 16.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(16, boxY, vw - 32, boxH),
      const Radius.circular(_kCornerRadius),
    );
    canvas.drawRRect(rrect, _bgPaint);
    canvas.drawRRect(rrect, _borderPaint);

    for (var i = 0; i < _choicePainters.length; i++) {
      final y = boxY + _kPaddingV + i * _kChoiceLineHeight;
      if (i == state.selectedIndex) {
        _cursorPainter.paint(canvas, Offset(16 + _kPaddingH, y));
      }
      _choicePainters[i].paint(
        canvas,
        Offset(16 + _kPaddingH + _cursorPainter.width + 8, y),
      );
    }

    _hintPainter.paint(
      canvas,
      Offset(
        16 + (vw - 32) - _kPaddingH - _hintPainter.width,
        boxY + boxH - _kPaddingV - _hintPainter.height,
      ),
    );
  }

  void moveCursor(int delta) {
    _session = _session.moveChoiceCursor(delta);
  }

  bool confirmChoice() {
    final next = _session.confirmChoice();
    if (next == null) {
      removeFromParent();
      onFinished();
      return false;
    }
    _session = next;
    _rebuildPainters();
    return true;
  }

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
