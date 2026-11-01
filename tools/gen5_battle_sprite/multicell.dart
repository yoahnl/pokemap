import 'controller.dart';
import 'nanr.dart';
import 'ncer.dart';
import 'nmcr.dart';
import 'pose.dart';

final class Gen5MultiCellController {
  Gen5MultiCellController({
    required this.cells,
    required this.animations,
    required this.maps,
    required Gen5NitroSequence timeline,
  }) : _parent = Gen5SequenceController(timeline) {
    _bindNodes();
  }

  final List<Gen5NcerCell> cells;
  final List<Gen5NitroSequence> animations;
  final List<Gen5NmcrMap> maps;
  final Gen5SequenceController _parent;
  final Map<int, Gen5SequenceController> _children = {};
  int _totalFrames = 0;

  Gen5NmcrMap get _map {
    final index = _parent.frame.targetIndex;
    if (index >= maps.length)
      throw const FormatException('Invalid multi-cell reference');
    return maps[index];
  }

  void _bindNodes() {
    final map = _map;
    final next = <int, Gen5SequenceController>{};
    for (final record in map.records) {
      final slot = record.sharedAnimationIndex;
      if (slot >= map.sharedAnimationCount || record.nodePlaybackMode > 1) {
        throw const FormatException('Invalid shared node');
      }
      if (next.containsKey(slot)) continue;
      if (record.animationIndex >= animations.length) {
        throw const FormatException('Invalid animation reference');
      }
      final sequence = animations[record.animationIndex];
      final child = Gen5SequenceController(sequence);
      if (record.nodePlaybackMode == 1) {
        final length = sequence.frames.fold<int>(
          0,
          (sum, frame) => sum + frame.duration,
        );
        final loops = sequence.playbackType == 2 || sequence.playbackType == 4;
        final steps = loops
            ? _totalFrames % length
            : (_totalFrames < length ? _totalFrames : length);
        if (steps > 65535)
          throw const FormatException('Node replay limit exceeded');
        for (var i = 0; i < steps; i++) {
          child.advance();
        }
      }
      next[slot] = child;
    }
    _children
      ..clear()
      ..addAll(next);
  }

  void advance() {
    final previousDuration = _parent.frame.duration;
    if (_parent.advance()) {
      _totalFrames = (_totalFrames + previousDuration) & 0xffff;
      _bindNodes();
    } else {
      for (final child in _children.values) {
        child.advance();
      }
    }
  }

  List<Gen5PosePart> get parts {
    final map = _map;
    final result = <(int, Gen5PosePart)>[];
    if (_parent.frame.scaleX == 0 || _parent.frame.scaleY == 0) {
      throw const FormatException('Unvalidated zero scale');
    }
    for (final record in map.records) {
      final child = _children[record.sharedAnimationIndex];
      if (child == null || child.frame.targetIndex >= cells.length) {
        throw const FormatException('Invalid shared cell reference');
      }
      if (child.frame.scaleX == 0 || child.frame.scaleY == 0) {
        throw const FormatException('Unvalidated zero scale');
      }
      for (final object in cells[child.frame.targetIndex].objects) {
        if (result.length >= 65536)
          throw const FormatException('Too many sprite parts');
        result.add((
          result.length,
          Gen5PosePart(
            object: object,
            record: record,
            localFrame: child.frame,
            parentFrame: _parent.frame,
          ),
        ));
      }
    }
    result.sort((a, b) {
      final priority = b.$2.object.priority.compareTo(a.$2.object.priority);
      return priority != 0 ? priority : b.$1.compareTo(a.$1);
    });
    return List.unmodifiable(result.map((entry) => entry.$2));
  }
}
