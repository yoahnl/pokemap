import 'dart:math' as math;

import 'nanr.dart';
import 'ncer.dart';
import 'nmcr.dart';
import 'timeline.dart';

final class Gen5PosePart {
  const Gen5PosePart({
    required this.object,
    required this.record,
    required this.localFrame,
    required this.parentFrame,
  });

  final Gen5NcerObject object;
  final Gen5NmcrRecord record;
  final Gen5NitroFrame localFrame, parentFrame;

  ({double x, double y}) transform(double x, double y) {
    final offsetX = object.x + (object.doubleSize ? object.width / 2 : 0);
    final offsetY = object.y + (object.doubleSize ? object.height / 2 : 0);
    final local = _transform(localFrame, x + offsetX, y + offsetY);
    return _transform(parentFrame, local.x + record.x, local.y + record.y);
  }
}

({double x, double y}) _transform(Gen5NitroFrame frame, double x, double y) {
  final angle = frame.rotation * 2 * math.pi / 65536;
  final sx = x * frame.scaleX / 4096;
  final sy = y * frame.scaleY / 4096;
  final cosine = math.cos(angle);
  final sine = math.sin(angle);
  return (
    x: frame.translateX + sx * cosine - sy * sine,
    y: frame.translateY + sx * sine + sy * cosine,
  );
}

List<Gen5PosePart> resolveGen5Pose({
  required List<Gen5NcerCell> cells,
  required List<Gen5NitroSequence> animations,
  required List<Gen5NmcrMap> maps,
  required Gen5NitroSequence timeline,
  required int tick,
}) {
  if (tick > 0) {
    throw const FormatException('Multi-cell node timing is not yet validated');
  }
  if (timeline.loopStart != 0) {
    throw const FormatException(
      'Multi-cell initial frame is not yet validated',
    );
  }
  final parent = gen5FrameAtTick(timeline, tick);
  if (parent.scaleX == 0 || parent.scaleY == 0) {
    throw const FormatException('Unvalidated zero scale');
  }
  if (parent.targetIndex >= maps.length) {
    throw const FormatException('Invalid NMAR map reference');
  }
  final parts = <(int, Gen5PosePart)>[];
  final map = maps[parent.targetIndex];
  final seenShared = <int>{};
  for (final record in map.records) {
    if (record.sharedAnimationIndex >= map.sharedAnimationCount ||
        !seenShared.add(record.sharedAnimationIndex) ||
        record.nodePlaybackMode > 1) {
      throw const FormatException('Unsupported multi-cell node sharing');
    }
    if (record.animationIndex >= animations.length) {
      throw const FormatException('Invalid NMCR animation reference');
    }
    final sequence = animations[record.animationIndex];
    if (sequence.loopStart != 0) {
      throw const FormatException('Cell initial frame is not yet validated');
    }
    final frame = gen5FrameAtTick(sequence, tick);
    if (frame.scaleX == 0 || frame.scaleY == 0) {
      throw const FormatException('Unvalidated zero scale');
    }
    if (frame.targetIndex >= cells.length) {
      throw const FormatException('Invalid NANR cell reference');
    }
    for (final object in cells[frame.targetIndex].objects) {
      if (parts.length >= 65536)
        throw const FormatException('Too many sprite parts');
      parts.add((
        parts.length,
        Gen5PosePart(
          object: object,
          record: record,
          localFrame: frame,
          parentFrame: parent,
        ),
      ));
    }
  }
  parts.sort((a, b) {
    final priority = b.$2.object.priority.compareTo(a.$2.object.priority);
    return priority != 0 ? priority : b.$1.compareTo(a.$1);
  });
  return List.unmodifiable(parts.map((part) => part.$2));
}
