import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../application/dialogue_runtime_models.dart';
import '../../application/dialogue_feedback_playback_port.dart';
import '../../application/dialogue_portrait_resolver.dart';
import '../../infrastructure/runtime_ui_image.dart';
import '../flutter/dialogue_presentation_snapshot.dart';
import 'dialogue_text_speed.dart';

typedef OnDialogueFinished = void Function(String? outcomeId);

class DialogueOverlayComponent extends PositionComponent {
  DialogueOverlayComponent({
    required DialogueSession session,
    required this.onFinished,
    required Vector2 viewportSize,
    this.textSpeed = RuntimeDialogueTextSpeed.instant,
    this.onPresentationSnapshotChanged,
    this.nextPresentationRevision,
    this.portraitResolver,
    this.feedbackPlaybackPort,
    this.iconBytesLoader,
    RuntimeResourceBudget? resourceBudget,
    this.onFailed,
    bool renderInFlame = true,
  })  : _session = session,
        _resourceBudget = resourceBudget ?? RuntimeResourceBudget(),
        _ownsResourceBudget = resourceBudget == null,
        _renderInFlame = renderInFlame,
        super(
          position: Vector2.zero(),
          size: viewportSize,
          priority: 100,
        );

  DialogueSession _session;
  final OnDialogueFinished onFinished;
  final ValueChanged<DialoguePresentationSnapshot?>?
      onPresentationSnapshotChanged;
  final int Function()? nextPresentationRevision;
  final DialoguePortraitResolver? portraitResolver;
  final DialogueFeedbackPlaybackPort? feedbackPlaybackPort;
  final DialogueIconBytesLoader? iconBytesLoader;
  final RuntimeResourceBudget _resourceBudget;
  final bool _ownsResourceBudget;
  final void Function(Object error)? onFailed;
  final Map<String, Uint8List> _iconBytes = {};
  final Map<String, ui.Image> _iconImages = {};
  final Map<String, RuntimeUiImageLease> _iconLeases = {};
  double _waitElapsedMicros = 0;
  bool _finished = false;
  bool _linePlaybackReady = false;
  final Set<String> _playedCues = {};
  static int _nextPlaybackScope = 0;
  final String _playbackScope = 'dialogue-${_nextPlaybackScope++}';
  RuntimeDialogueTextSpeed textSpeed;
  bool _renderInFlame;
  bool _presentationReady = false;
  int _visibleRuneCount = 0;
  double _revealAccumulatorSeconds = 0;
  int _presentationRevision = 0;
  DialoguePresentationSnapshot? _currentPresentationSnapshot;

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

  String get visibleText {
    final state = _session.state;
    if (state is! DialogueShowingLine) {
      return '';
    }
    if (_revealIntervalMicros == 0) {
      return state.text;
    }
    return String.fromCharCodes(state.text.runes.take(_visibleRuneCount));
  }

  bool get isCurrentLineFullyRevealed {
    final state = _session.state;
    return state is! DialogueShowingLine ||
        _revealIntervalMicros == 0 ||
        _visibleRuneCount >= state.text.runes.length;
  }

  DialoguePresentationSnapshot? get currentPresentationSnapshot =>
      _currentPresentationSnapshot;

  @override
  Future<void> onLoad() async {
    try {
      await _loadPresentation();
    } on Object catch (error, stackTrace) {
      _failFeedback(error);
      if (onFailed == null) Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _loadPresentation() async {
    await portraitResolver?.preload(_session);
    if (_finished) return;
    for (final feedback in _session.lineFeedback) {
      for (final icon in feedback.segments.whereType<DialogueIconSegment>()) {
        if (_iconBytes.containsKey(icon.assetId)) continue;
        final loader = iconBytesLoader;
        if (loader == null) throw StateError('Dialogue icon loader is missing.');
        final bytes = await loader(icon.assetId);
        if (_finished) return;
        validateDialogueIconPng(bytes);
        final lease = await decodeRuntimeUiImage(bytes,
          resourceBudget: _resourceBudget,
          retainedEncodedBytes: bytes.length,
          isCurrent: () => !_finished,
        );
        if (_finished) {
          lease.dispose();
          return;
        }
        _iconBytes[icon.assetId] = Uint8List.fromList(bytes).asUnmodifiableView();
        _iconImages[icon.assetId] = lease.image;
        _iconLeases[icon.assetId] = lease;
      }
    }
    _resetRevealForCurrentState();
    await _beginLineFeedback();
    if (_finished) return;
    _cursorPainter = TextPainter(
      text: const TextSpan(
        text: '▶',
        style: TextStyle(color: Colors.white, fontSize: _kFontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _rebuildPainters();
    _presentationReady = true;
    _publishPresentationSnapshot();
    return super.onLoad();
  }

  int get _revealIntervalMicros {
    final state = _session.state;
    final explicit = state is DialogueShowingLine ? state.feedback?.revealIntervalMicros : null;
    return explicit ?? textSpeed.revealInterval?.inMicroseconds ?? 0;
  }

  bool get _autoAdvance => _session.state is DialogueShowingLine &&
      (_session.state as DialogueShowingLine).feedback?.advance.kind == DialogueLineAdvanceKind.autoAfterReveal;

  Future<void> _beginLineFeedback() async {
    _linePlaybackReady = false;
    final state = _session.state;
    final cue = state is DialogueShowingLine ? state.feedback?.audioCue : null;
    if (cue != null) {
      final port = feedbackPlaybackPort;
      if (port == null) {
        throw StateError('Dialogue feedback audio port is missing.');
      }
      if (_visibleRuneCount >= cue.revealOffset && _playedCues.add(cue.cueId)) {
        await port.playCue(cue, playbackId: '$_playbackScope:${cue.cueId}');
      }
    }
    if (!_finished && identical(state, _session.state)) {
      _linePlaybackReady = true;
    }
  }

  void _startLineFeedback() {
    unawaited(_beginLineFeedback().catchError((Object error, StackTrace stackTrace) {
      _failFeedback(error);
      if (onFailed == null) Zone.current.handleUncaughtError(error, stackTrace);
    }));
  }

  void _failFeedback(Object error) {
    if (_finished) return;
    _finished = true;
    for (final lease in _iconLeases.values) {
      lease.dispose();
    }
    _iconLeases.clear();
    _iconBytes.clear();
    _iconImages.clear();
    if (_ownsResourceBudget) _resourceBudget.dispose();
    removeFromParent();
    onFailed?.call(error);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_finished || !_linePlaybackReady || !dt.isFinite || dt < 0) return;
    final state = _session.state;
    if (state is! DialogueShowingLine) return;
    var availableMicros = dt * Duration.microsecondsPerSecond;
    if (!isCurrentLineFullyRevealed) {
      final interval = _revealIntervalMicros;
      final remaining = state.text.runes.length - _visibleRuneCount;
      final needed = remaining * interval - _revealAccumulatorSeconds * Duration.microsecondsPerSecond;
      if (availableMicros + 0.000001 >= needed) {
        _visibleRuneCount = state.text.runes.length;
        _revealAccumulatorSeconds = 0;
        availableMicros = (availableMicros - needed).clamp(0, double.infinity);
      } else {
        _revealAccumulatorSeconds += dt;
        final accumulated = _revealAccumulatorSeconds * Duration.microsecondsPerSecond;
        final revealed = (accumulated + 0.000001) ~/ interval;
        _visibleRuneCount += revealed;
        _revealAccumulatorSeconds -= revealed * interval / Duration.microsecondsPerSecond;
        availableMicros = 0;
      }
      _rebuildLinePainters(state);
      _publishPresentationSnapshot();
      _startLineFeedback();
    }
    if (!_linePlaybackReady) return;
    if (!_autoAdvance || !isCurrentLineFullyRevealed) return;
    _waitElapsedMicros += availableMicros;
    final delay = state.feedback!.advance.delayMicros;
    if (_waitElapsedMicros + 0.000001 >= delay) _advanceLine(automatic: true);
  }

  @override
  void onRemove() {
    _finished = true;
    for (final lease in _iconLeases.values) {
      lease.dispose();
    }
    _iconLeases.clear();
    _iconBytes.clear();
    _iconImages.clear();
    if (_ownsResourceBudget) _resourceBudget.dispose();
    super.onRemove();
  }

  void setRenderInFlame(bool renderInFlame) {
    _renderInFlame = renderInFlame;
    _publishPresentationSnapshot();
  }

  void setTextSpeed(RuntimeDialogueTextSpeed speed) {
    if (textSpeed == speed) {
      return;
    }
    textSpeed = speed;
    _revealAccumulatorSeconds = 0;
    if (_revealIntervalMicros == 0) {
      _revealCurrentLineFully();
    }
    if (_presentationReady) {
      _rebuildPainters();
      _publishPresentationSnapshot();
    }
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
        children: _lineSpans(state),
        style: const TextStyle(
          color: Colors.white,
          fontSize: _kFontSize,
          height: 1.4,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 4,
    );
    final visibleIcons = _visibleSegments(state).whereType<DialogueIconSegment>().toList(growable: false);
    if (visibleIcons.isNotEmpty) {
      _textPainter.setPlaceholderDimensions([
        for (final icon in visibleIcons) PlaceholderDimensions(
          size: Size(icon.widthPx.toDouble(), icon.heightPx.toDouble()), alignment: ui.PlaceholderAlignment.middle),
      ]);
    }
    _textPainter.layout(maxWidth: size.x - 32 - _kPaddingH * 2);

    _hintPainter = TextPainter(
      text: TextSpan(
        text: _autoAdvance && isCurrentLineFullyRevealed ? '' : !isCurrentLineFullyRevealed
            ? 'E · Afficher'
            : _session.isLastContent
                ? 'E · Fermer'
                : 'E · Suite',
        style: TextStyle(color: _kHintColor, fontSize: _kHintFontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  List<DialogueLineSegment> _visibleSegments(DialogueShowingLine state) =>
      visibleDialogueLineSegments(state.feedback?.segments ?? const [], visibleText.runes.length);

  List<InlineSpan> _lineSpans(DialogueShowingLine state) {
    final segments = _visibleSegments(state);
    if (segments.isEmpty) return [TextSpan(text: visibleText)];
    return [for (final segment in segments) switch (segment) {
      DialogueTextSegment() => TextSpan(text: segment.text, style: TextStyle(
        color: segment.style?.colorArgb == null ? null : Color(segment.style!.colorArgb!),
        shadows: segment.style?.shadowColorArgb == null ? null : [Shadow(
          color: Color(segment.style!.shadowColorArgb!), offset: const Offset(1, 1))])),
      DialogueIconSegment() => WidgetSpan(alignment: ui.PlaceholderAlignment.middle,
        child: SizedBox(width: segment.widthPx.toDouble(), height: segment.heightPx.toDouble())),
    }];
  }

  void _rebuildChoicePainters(DialogueWaitingForChoice state) {
    final maxW = size.x - 32 - _kPaddingH * 2 - _cursorPainter.width - 8;
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
    if (!_renderInFlame) {
      return;
    }
    final state = _session.state;
    if (state is DialogueShowingLine) {
      _renderLine(canvas);
    } else if (state is DialogueWaitingForChoice) {
      _renderChoices(canvas, state);
    }
  }

  void _renderLine(Canvas canvas) {
    final state = _session.state as DialogueShowingLine;
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
    var offset = 0;
    for (final segment in _visibleSegments(state)) {
      if (segment is DialogueIconSegment) {
        final image = _iconImages[segment.assetId];
        final boxes = _textPainter.getBoxesForSelection(TextSelection(baseOffset: offset, extentOffset: offset + 1));
        if (image != null && boxes.isNotEmpty) {
          final box = boxes.first;
          final textOrigin = Offset(16 + _kPaddingH, boxY + _kPaddingV);
          canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
            Rect.fromLTWH(textOrigin.dx + box.left, textOrigin.dy + box.top,
              segment.widthPx.toDouble(), segment.heightPx.toDouble()), Paint()..filterQuality = FilterQuality.none);
        }
      }
      offset += segment.plainText.length;
    }

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
    final visibleCount = ((vh - 32 - _kPaddingV * 2 - _kHintFontSize * 2) / _kChoiceLineHeight)
        .floor().clamp(1, state.choices.length);
    final first = (state.selectedIndex - visibleCount + 1).clamp(0, state.choices.length - visibleCount);
    final boxH = _kPaddingV * 2 +
        visibleCount * _kChoiceLineHeight +
        _kHintFontSize * 2.0;
    final boxY = vh - boxH - 16.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(16, boxY, vw - 32, boxH),
      const Radius.circular(_kCornerRadius),
    );
    canvas.drawRRect(rrect, _bgPaint);
    canvas.drawRRect(rrect, _borderPaint);

    for (var i = first; i < first + visibleCount; i++) {
      final y = boxY + _kPaddingV + (i - first) * _kChoiceLineHeight;
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
    _publishPresentationSnapshot();
  }

  bool cancelChoice() {
    final outcome = _session.choiceCancellationOutcomeId;
    if (outcome == null) return true;
    final next = _session.cancelChoice();
    if (next == null) {
      removeFromParent();
      onFinished(outcome);
      return false;
    }
    _session = next;
    _resetRevealForCurrentState();
    _startLineFeedback();
    _rebuildPainters();
    _publishPresentationSnapshot();
    return true;
  }

  bool confirmChoice() {
    final state = _session.state;
    final choiceOutcomeId = state is DialogueWaitingForChoice
        ? state.choices[state.selectedIndex].outcomeId
        : null;
    final next = _session.confirmChoice();
    if (next == null) {
      removeFromParent();
      onFinished(choiceOutcomeId ?? _session.selectedOutcomeId);
      return false;
    }
    _session = next;
    _resetRevealForCurrentState();
    _startLineFeedback();
    _rebuildPainters();
    _publishPresentationSnapshot();
    return true;
  }

  bool advance() => _advanceLine();

  bool _advanceLine({bool automatic = false}) {
    if (_finished) return false;
    if (!_linePlaybackReady && _presentationReady) return true;
    if (!isCurrentLineFullyRevealed) {
      _revealCurrentLineFully();
      if (_presentationReady) {
        _rebuildPainters();
        _publishPresentationSnapshot();
      }
      return true;
    }
    if (_autoAdvance && !automatic) return true;
    final next = _session.advance();
    if (next == null) {
      removeFromParent();
      _finished = true;
      onFinished(_session.selectedOutcomeId);
      return false;
    }
    _session = next;
    _resetRevealForCurrentState();
    _startLineFeedback();
    _rebuildPainters();
    _publishPresentationSnapshot();
    return true;
  }

  void _publishPresentationSnapshot() {
    final snapshot = buildDialoguePresentationSnapshot(
      session: _session,
      revision: nextPresentationRevision?.call() ?? ++_presentationRevision,
      visibleText: visibleText,
      isCurrentLineFullyRevealed: isCurrentLineFullyRevealed,
      resolvePortrait: portraitResolver?.resolve,
      iconPngBytes: _iconBytes,
      iconImages: _iconImages,
    );
    _currentPresentationSnapshot = snapshot;
    onPresentationSnapshotChanged?.call(snapshot);
  }

  void _resetRevealForCurrentState() {
    _revealAccumulatorSeconds = 0;
    _waitElapsedMicros = 0;
    final state = _session.state;
    _visibleRuneCount = state is DialogueShowingLine &&
            _revealIntervalMicros == 0
        ? state.text.runes.length
        : 0;
  }

  void _revealCurrentLineFully() {
    final state = _session.state;
    if (state is DialogueShowingLine) {
      _visibleRuneCount = state.text.runes.length;
    }
    _revealAccumulatorSeconds = 0;
    if (_presentationReady && !_finished && _linePlaybackReady) {
      _startLineFeedback();
    }
  }
}
