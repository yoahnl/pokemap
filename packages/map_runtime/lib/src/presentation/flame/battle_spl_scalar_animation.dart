final class BattleSplParticlePhase {
  factory BattleSplParticlePhase({
    required int age,
    required int lifetime,
    required int loopTime,
    int loopOffset = 0,
  }) {
    if (age < 0 ||
        age > 65535 ||
        lifetime < 1 ||
        lifetime > 65535 ||
        loopTime < 1 ||
        loopTime > 65535 ||
        loopOffset < 0 ||
        loopOffset > 255) {
      throw const FormatException('Invalid SPL particle phase');
    }
    return BattleSplParticlePhase._(
      _phase(age, lifetime, 0),
      _phase(age, loopTime, loopOffset),
    );
  }

  const BattleSplParticlePhase._(this.life, this.loop);

  final int life;
  final int loop;

  static int _phase(int age, int duration, int offset) =>
      (offset + (((65535 ~/ duration) * age) >> 8)) & 255;
}

final class BattleSplScalarAnimation {
  BattleSplScalarAnimation({
    required this.start,
    required this.middle,
    required this.end,
    required this.fadeIn,
    required this.fadeOut,
  }) {
    if (start < -32768 ||
        start > 32767 ||
        middle < -32768 ||
        middle > 32767 ||
        end < -32768 ||
        end > 32767 ||
        fadeIn < 0 ||
        fadeIn > 254 ||
        fadeOut < 0 ||
        fadeOut > 254) {
      throw const FormatException('Invalid SPL scalar animation');
    }
  }

  final int start;
  final int middle;
  final int end;
  final int fadeIn;
  final int fadeOut;

  int valueAt(int lifeRate) {
    if (lifeRate < 0 || lifeRate > 255) {
      throw ArgumentError.value(lifeRate, 'lifeRate');
    }
    if (lifeRate < fadeIn) {
      return start + ((middle - start) * lifeRate) ~/ fadeIn;
    }
    if (lifeRate < fadeOut) return middle;
    return end + ((end - middle) * (lifeRate - 255)) ~/ (255 - fadeOut);
  }
}

final class BattleSplAlphaAnimation {
  BattleSplAlphaAnimation({
    required int start,
    required int middle,
    required int end,
    required int fadeIn,
    required int fadeOut,
    required this.randomRange,
  }) : _animation = BattleSplScalarAnimation(
         start: start,
         middle: middle,
         end: end,
         fadeIn: fadeIn,
         fadeOut: fadeOut,
       ) {
    if (start < 0 ||
        start > 31 ||
        middle < 0 ||
        middle > 31 ||
        end < 0 ||
        end > 31 ||
        randomRange < 0 ||
        randomRange > 255) {
      throw const FormatException('Invalid SPL alpha animation');
    }
  }

  final BattleSplScalarAnimation _animation;
  final int randomRange;

  int valueAt({required int lifeRate, required int randomByte}) {
    if (randomByte < 0 || randomByte > 255) {
      throw ArgumentError.value(randomByte, 'randomByte');
    }
    final alpha = _animation.valueAt(lifeRate);
    return (alpha * (255 - ((randomRange * randomByte) >> 8))) >> 8;
  }
}
