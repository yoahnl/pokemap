import 'dart:math' as math;

import 'nanr.dart';
import 'ncer.dart';
import 'nmcr.dart';
import 'pose.dart';

final class Gen5AnimationEnvelope {
  const Gen5AnimationEnvelope(this.left, this.top, this.right, this.bottom);

  final double left, top, right, bottom;
}

Gen5AnimationEnvelope gen5AnimationEnvelope({
  required List<Gen5NcerCell> cells,
  required List<Gen5NitroSequence> animations,
  required List<Gen5NmcrMap> maps,
  required Gen5NitroSequence timeline,
  int maxWork = 1000000,
}) {
  var left = double.infinity, top = double.infinity;
  var right = double.negativeInfinity, bottom = double.negativeInfinity;
  var partCount = 0;
  var work = 0;
  void charge() {
    if (++work > maxWork) {
      throw const FormatException('Envelope work limit exceeded');
    }
  }

  for (final parent in timeline.frames) {
    charge();
    if (parent.targetIndex >= maps.length ||
        parent.scaleX == 0 ||
        parent.scaleY == 0) {
      throw const FormatException('Invalid envelope parent frame');
    }
    for (final record in maps[parent.targetIndex].records) {
      charge();
      if (record.animationIndex >= animations.length) {
        throw const FormatException('Invalid envelope animation reference');
      }
      for (final frame in animations[record.animationIndex].frames) {
        charge();
        if (frame.targetIndex >= cells.length ||
            frame.scaleX == 0 ||
            frame.scaleY == 0) {
          throw const FormatException('Invalid envelope cell frame');
        }
        for (final object in cells[frame.targetIndex].objects) {
          charge();
          partCount++;
          final part = Gen5PosePart(
            object: object,
            record: record,
            localFrame: frame,
            parentFrame: parent,
          );
          for (final corner in [
            (0.0, 0.0),
            (object.width.toDouble(), 0.0),
            (0.0, object.height.toDouble()),
            (object.width.toDouble(), object.height.toDouble()),
          ]) {
            final p = part.transform(corner.$1, corner.$2);
            left = math.min(left, p.x);
            right = math.max(right, p.x);
            top = math.min(top, p.y);
            bottom = math.max(bottom, p.y);
          }
        }
      }
    }
  }
  if (partCount == 0) throw const FormatException('Empty animation envelope');
  return Gen5AnimationEnvelope(left, top, right, bottom);
}
