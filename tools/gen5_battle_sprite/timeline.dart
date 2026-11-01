import 'nanr.dart';

Gen5NitroFrame gen5FrameAtTick(Gen5NitroSequence sequence, int tick) {
  final frames = sequence.frames;
  if (frames.isEmpty ||
      sequence.loopStart < 0 ||
      sequence.loopStart >= frames.length) {
    throw const FormatException('Invalid animation sequence');
  }
  if (sequence.playbackType < 0 || sequence.playbackType > 4) {
    throw const FormatException('Unsupported animation playback');
  }
  tick = tick < 0 ? 0 : tick;
  final forward = List<int>.generate(frames.length, (index) => index);
  final pingPong =
      !sequence.isMultiCellTimeline &&
      (sequence.playbackType == 3 || sequence.playbackType == 4);
  final looping =
      sequence.playbackType == 2 ||
      (!sequence.isMultiCellTimeline && sequence.playbackType == 4);
  final reverseEnd = looping ? sequence.loopStart : 0;
  final reverse = <int>[
    if (pingPong)
      for (var index = frames.length - 2; index >= reverseEnd; index--) index,
  ];
  final all = [...forward, ...reverse];
  int duration(Iterable<int> indices) =>
      indices.fold(0, (sum, index) => sum + frames[index].duration);
  final initialDuration = duration(all);
  if (initialDuration == 0) return frames.first;
  if (tick >= initialDuration) {
    if (!looping) {
      tick = initialDuration - 1;
    } else {
      final prefixDuration = duration(forward.take(sequence.loopStart));
      final loopDuration = initialDuration - prefixDuration;
      tick = loopDuration > 0
          ? prefixDuration + (tick - prefixDuration) % loopDuration
          : tick % initialDuration;
    }
  }
  for (final index in all) {
    final frame = frames[index];
    if (tick < frame.duration) return frame;
    tick -= frame.duration;
  }
  return frames.last;
}
