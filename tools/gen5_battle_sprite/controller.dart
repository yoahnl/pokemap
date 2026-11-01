import 'nanr.dart';

final class Gen5SequenceController {
  Gen5SequenceController(this.sequence) {
    final frames = sequence.frames;
    if (frames.isEmpty ||
        sequence.loopStart < 0 ||
        sequence.loopStart >= frames.length ||
        sequence.playbackType < 1 ||
        sequence.playbackType > 4 ||
        frames.any((frame) => frame.duration < 0) ||
        !frames.skip(sequence.loopStart).any((frame) => frame.duration > 0)) {
      throw const FormatException('Invalid animation controller sequence');
    }
    _index = sequence.loopStart;
    _skipZeroFrames();
  }

  final Gen5NitroSequence sequence;
  late int _index;
  int? _visibleIndex;
  int _elapsed = 0;
  bool _reverse = false;
  bool _active = true;

  Gen5NitroFrame get frame => sequence.frames[_visibleIndex!];
  bool get isActive => _active;

  bool advance() {
    if (!_active) return false;
    _elapsed++;
    if (_elapsed < sequence.frames[_index].duration) return false;
    _elapsed -= sequence.frames[_index].duration;
    _moveNext();
    _skipZeroFrames();
    return true;
  }

  void _skipZeroFrames() {
    var steps = 0;
    while (_active && sequence.frames[_index].duration == 0) {
      if (++steps > sequence.frames.length * 2 + 2) {
        throw const FormatException('Animation has no reachable frame');
      }
      _moveNext();
    }
    if (sequence.frames[_index].duration > 0) {
      _visibleIndex = _index;
    }
    if (_visibleIndex == null) {
      throw const FormatException('Animation has no active frame');
    }
  }

  void _moveNext() {
    final count = sequence.frames.length;
    final mode = sequence.playbackType;
    final reverseMode = mode == 3 || mode == 4;
    final looping = mode == 2 || mode == 4;
    final next = _index + (_reverse ? -1 : 1);
    if (!_reverse && next >= count) {
      if (reverseMode) {
        _reverse = true;
        _index = count - 1;
      } else if (looping) {
        _index = sequence.loopStart;
      } else {
        _index = count - 1;
        _active = false;
      }
    } else if (_reverse && next < sequence.loopStart) {
      if (looping) {
        _reverse = false;
        _index = sequence.loopStart;
      } else {
        _index = next < 0 ? 0 : next;
        _active = false;
      }
    } else {
      _index = next;
    }
  }
}
