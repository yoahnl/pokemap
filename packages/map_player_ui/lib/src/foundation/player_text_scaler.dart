import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Applies the player's readability preference without discarding the
/// platform accessibility scaling strategy.
@immutable
final class PlayerTextScaler extends TextScaler {
  const PlayerTextScaler({
    required this.systemScaler,
    required this.preferenceScale,
  }) : assert(preferenceScale > 0);

  final TextScaler systemScaler;
  final double preferenceScale;

  @override
  double scale(double fontSize) =>
      systemScaler.scale(fontSize) * preferenceScale;

  @override
  // Flutter keeps this getter only for legacy consumers of [TextScaler].
  // ignore: deprecated_member_use
  double get textScaleFactor => systemScaler.textScaleFactor * preferenceScale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerTextScaler &&
          other.systemScaler == systemScaler &&
          other.preferenceScale == preferenceScale;

  @override
  int get hashCode => Object.hash(systemScaler, preferenceScale);
}
