import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';

enum PokeMapGuidedSliderLayout {
  stacked,
  inline,
}

/// Integer-only guided control for authoring values presented as percentages.
///
/// Product screens keep their domain conversion outside this primitive. The
/// slider only exposes a named, accessible value between [min] and [max].
class PokeMapGuidedSlider extends StatefulWidget {
  const PokeMapGuidedSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.description,
    this.valueFormatter,
    this.min = 0,
    this.max = 100,
    this.layout = PokeMapGuidedSliderLayout.stacked,
  }) : assert(min < max);

  final String label;
  final String? description;
  final String Function(int value)? valueFormatter;
  final int value;
  final int min;
  final int max;
  final PokeMapGuidedSliderLayout layout;
  final ValueChanged<int> onChanged;
  final ValueChanged<int>? onChangeStart;
  final ValueChanged<int>? onChangeEnd;

  @override
  State<PokeMapGuidedSlider> createState() => _PokeMapGuidedSliderState();
}

class _PokeMapGuidedSliderState extends State<PokeMapGuidedSlider> {
  final FocusNode _focusNode = FocusNode();

  bool _interactionActive = false;
  bool _focusHighlightRequested = false;
  _GuidedSliderFocusOrigin? _focusOrigin;
  int? _lastInteractionValue;

  int get _clampedValue => widget.value.clamp(widget.min, widget.max).toInt();

  bool get _showFocusHighlight =>
      _focusHighlightRequested &&
      _focusOrigin == _GuidedSliderFocusOrigin.keyboard;

  int _roundedValue(double value) =>
      value.round().clamp(widget.min, widget.max).toInt();

  void _beginInteraction(int value) {
    if (_interactionActive) {
      return;
    }
    _interactionActive = true;
    _lastInteractionValue = value;
    widget.onChangeStart?.call(value);
  }

  void _endInteraction([int? value]) {
    if (!_interactionActive) {
      return;
    }
    final finalValue = value ?? _lastInteractionValue ?? _clampedValue;
    _interactionActive = false;
    _lastInteractionValue = null;
    widget.onChangeEnd?.call(finalValue);
  }

  void _runDiscreteChange(int value) {
    _beginInteraction(_clampedValue);
    try {
      _lastInteractionValue = value;
      widget.onChanged(value);
    } finally {
      _endInteraction(value);
    }
  }

  void _handleChangeStart(double value) {
    _beginInteraction(_roundedValue(value));
  }

  void _handleChanged(double value) {
    final roundedValue = _roundedValue(value);
    if (!_interactionActive) {
      _runDiscreteChange(roundedValue);
      return;
    }
    _lastInteractionValue = roundedValue;
    widget.onChanged(roundedValue);
  }

  void _handleChangeEnd(double value) {
    _endInteraction(_roundedValue(value));
  }

  void _adjustWithKeyboard(int delta) {
    _setFocusOrigin(_GuidedSliderFocusOrigin.keyboard);
    if (_interactionActive) {
      return;
    }
    final nextValue =
        (_clampedValue + delta).clamp(widget.min, widget.max).toInt();
    if (nextValue == _clampedValue) {
      return;
    }
    _runDiscreteChange(nextValue);
  }

  void _setFocusOrigin(_GuidedSliderFocusOrigin origin) {
    if (_focusOrigin == origin) {
      return;
    }
    setState(() => _focusOrigin = origin);
  }

  void _handleFocusChange(bool focused) {
    if (focused) {
      if (_focusOrigin == null) {
        _setFocusOrigin(_GuidedSliderFocusOrigin.keyboard);
      }
      return;
    }
    if (_focusOrigin != null) {
      setState(() => _focusOrigin = null);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _setFocusOrigin(_GuidedSliderFocusOrigin.pointer);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final clampedValue = _clampedValue;
    final formattedValue =
        widget.valueFormatter?.call(clampedValue) ?? '$clampedValue %';
    final label = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (widget.description case final description?) ...[
          const SizedBox(height: 2),
          Text(
            description,
            maxLines:
                widget.layout == PokeMapGuidedSliderLayout.inline ? 1 : null,
            overflow: widget.layout == PokeMapGuidedSliderLayout.inline
                ? TextOverflow.ellipsis
                : null,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
    final valueLabel = Text(
      formattedValue,
      style: TextStyle(
        color: colors.brandPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
    final slider = FocusableActionDetector(
      focusNode: _focusNode,
      onFocusChange: _handleFocusChange,
      onShowFocusHighlight: (show) {
        if (_focusHighlightRequested == show) {
          return;
        }
        setState(() => _focusHighlightRequested = show);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowLeft):
            _AdjustGuidedSliderIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowDown):
            _AdjustGuidedSliderIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowRight):
            _AdjustGuidedSliderIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowUp):
            _AdjustGuidedSliderIntent(1),
      },
      actions: <Type, Action<Intent>>{
        _AdjustGuidedSliderIntent: CallbackAction<_AdjustGuidedSliderIntent>(
          onInvoke: (intent) {
            _adjustWithKeyboard(intent.delta);
            return null;
          },
        ),
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Listener(
            onPointerDown: _handlePointerDown,
            onPointerUp: (_) => _endInteraction(),
            onPointerCancel: (_) => _endInteraction(),
            child: CupertinoSlider(
              value: clampedValue.toDouble(),
              min: widget.min.toDouble(),
              max: widget.max.toDouble(),
              divisions: widget.max - widget.min,
              activeColor: colors.brandPrimary,
              thumbColor: colors.surfaceBase,
              onChangeStart: _handleChangeStart,
              onChanged: _handleChanged,
              onChangeEnd: _handleChangeEnd,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 100),
                tween: Tween<double>(
                  begin: 0,
                  end: _showFocusHighlight ? 1 : 0,
                ),
                builder: (context, progress, child) => DecoratedBox(
                  key: const ValueKey<String>(
                    'pokemap-guided-slider-focus-indicator',
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color.lerp(
                        colors.brandPrimary.withValues(alpha: 0),
                        colors.brandPrimary,
                        progress,
                      )!,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    final content = switch (widget.layout) {
      PokeMapGuidedSliderLayout.stacked => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: label),
                const SizedBox(width: 12),
                valueLabel,
              ],
            ),
            const SizedBox(height: 4),
            slider,
          ],
        ),
      PokeMapGuidedSliderLayout.inline => Row(
          children: [
            Flexible(child: label),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: slider),
            const SizedBox(width: 8),
            valueLabel,
          ],
        ),
    };
    return Semantics(
      slider: true,
      label: widget.label,
      value: formattedValue,
      child: content,
    );
  }
}

class _AdjustGuidedSliderIntent extends Intent {
  const _AdjustGuidedSliderIntent(this.delta);

  final int delta;
}

enum _GuidedSliderFocusOrigin {
  keyboard,
  pointer,
}
