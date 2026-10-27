import 'package:map_core/map_core.dart';

final class SpatialLiftMotion {
  SpatialLiftMotion(
      {required this.definition,
      required this.sourceOffset,
      required this.raised}) {
    if (!sourceOffset.isFinite ||
        (sourceOffset.abs() > 1e-6 &&
            (sourceOffset - definition.travelHeight).abs() > 1e-6)) {
      throw const FormatException('A lift must start at one of its stops.');
    }
  }
  final SpatialLiftDefinition definition;
  final double sourceOffset;
  final bool raised;
  double _elapsed = 0;
  bool _cancelled = false;
  double get targetOffset => raised ? definition.travelHeight : 0;
  bool get complete => !_cancelled && _elapsed >= definition.durationMs;
  double get offset => _cancelled
      ? sourceOffset
      : sourceOffset +
          (targetOffset - sourceOffset) *
              (_elapsed / definition.durationMs).clamp(0, 1);
  double get height => definition.lowerHeight + offset;
  void advance(double seconds, {bool paused = false}) {
    if (!seconds.isFinite || seconds < 0) {
      throw ArgumentError.value(seconds, 'seconds');
    }
    if (!_cancelled && !paused) {
      _elapsed = (_elapsed + seconds * 1000)
          .clamp(0, definition.durationMs.toDouble());
    }
  }

  void cancel() {
    _cancelled = true;
  }
}
