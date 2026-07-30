import 'package:flutter/foundation.dart';

/// Quantized animation time exposed directly to canvas painters.
///
/// The clock deliberately emits at most once per quantized value so a ticker
/// can drive animated frames without rebuilding the canvas widget tree.
final class EditorCanvasRepaintClock extends ChangeNotifier {
  EditorCanvasRepaintClock({
    this.frameStep = const Duration(milliseconds: 110),
  }) : assert(frameStep.inMilliseconds > 0);

  final Duration frameStep;

  int get elapsedMs => _elapsedMs;
  int _elapsedMs = 0;

  void update(Duration elapsed) {
    final step = frameStep.inMilliseconds;
    final next = elapsed.inMilliseconds ~/ step * step;
    if (next == _elapsedMs) return;
    _elapsedMs = next;
    notifyListeners();
  }

  void reset() {
    if (_elapsedMs == 0) return;
    _elapsedMs = 0;
    notifyListeners();
  }
}
