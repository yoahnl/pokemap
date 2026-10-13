import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../operations/border_json_codec_helpers.dart';
import 'border_value_objects.dart';

@immutable
final class BorderJumpBehavior {
  BorderJumpBehavior({
    this.side = BorderLineSide.primary,
    this.distanceCells = 2,
    this.durationMs = 500,
    this.peakHeightPx = 24,
  }) {
    if (distanceCells != 2 ||
        durationMs < 1 ||
        durationMs > 60000 ||
        peakHeightPx < 1 ||
        peakHeightPx > 1024) {
      throw const ValidationException(
        'Border jump geometry or timing is outside bounds',
      );
    }
  }

  final BorderLineSide side;
  final int distanceCells;
  final int durationMs;
  final int peakHeightPx;

  Map<String, Object?> toJson() => {
    'side': side.name,
    'distanceCells': distanceCells,
    'durationMs': durationMs,
    'peakHeightPx': peakHeightPx,
  };

  factory BorderJumpBehavior.fromJson(Object? json, {String path = r'$'}) {
    final value = borderJsonRequireObject(json, path);
    borderJsonRequireExactKeys(
      value,
      path: path,
      requiredKeys: const {
        'side',
        'distanceCells',
        'durationMs',
        'peakHeightPx',
      },
    );
    final side = switch (borderJsonRequireString(value['side'], '$path.side')) {
      'primary' => BorderLineSide.primary,
      'inverted' => BorderLineSide.inverted,
      _ => throw FormatException('$path.side: expected primary or inverted'),
    };
    final distance = borderJsonRequireInt(
      value['distanceCells'],
      '$path.distanceCells',
    );
    final duration = borderJsonRequireInt(
      value['durationMs'],
      '$path.durationMs',
    );
    final height = borderJsonRequireInt(
      value['peakHeightPx'],
      '$path.peakHeightPx',
    );
    return borderJsonConstructAtPath(
      path,
      () => BorderJumpBehavior(
        side: side,
        distanceCells: distance,
        durationMs: duration,
        peakHeightPx: height,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderJumpBehavior &&
          side == other.side &&
          distanceCells == other.distanceCells &&
          durationMs == other.durationMs &&
          peakHeightPx == other.peakHeightPx;

  @override
  int get hashCode =>
      Object.hash(side, distanceCells, durationMs, peakHeightPx);
}
