typedef BattleGen5SwingValue = ({int x, int y, bool done});

int battleGen5SwingStep(int value, int frames) =>
    frames < 1 || frames > 600 || value < -65536 || value > 65536
    ? 0
    : (((value * 1048576) ~/ frames + 524288) / 1048576).floor();

final class BattleGen5Swing {
  BattleGen5Swing({
    required this.startX,
    required this.startY,
    required int deltaX,
    required int deltaY,
    required this.frames,
    required this.wait,
    required int count,
    bool mirrorX = false,
  }) : _x = startX,
       _y = startY,
       _remainingSteps = frames,
       _remainingLegs = count * 2,
       _stepX = (mirrorX ? -1 : 1) * battleGen5SwingStep(deltaX, frames),
       _stepY = battleGen5SwingStep(deltaY, frames) {
    const limit = 2147483647;
    if (frames < 1 ||
        frames > 600 ||
        wait < 0 ||
        wait > 600 ||
        count < 1 ||
        count > 32 ||
        frames * 2 * count * (wait + 1) - wait > 1800 ||
        startX < -limit ||
        startX > limit ||
        startY < -limit ||
        startY > limit ||
        deltaX < -65536 ||
        deltaX > 65536 ||
        deltaY < -65536 ||
        deltaY > 65536 ||
        startX.abs() + deltaX.abs() > limit ||
        startY.abs() + deltaY.abs() > limit) {
      throw const FormatException('Invalid Gen 5 swing');
    }
  }

  final int startX;
  final int startY;
  final int frames;
  final int wait;
  int _x;
  int _y;
  int _remainingSteps;
  int _remainingLegs;
  int _stepX;
  int _stepY;
  int _remainingWait = 0;

  BattleGen5SwingValue advance() {
    if (_remainingLegs == 0) return (x: startX, y: startY, done: true);
    if (_remainingWait > 0) {
      _remainingWait--;
      return (x: _x, y: _y, done: false);
    }
    _x += _stepX;
    _y += _stepY;
    _remainingSteps--;
    if (_remainingSteps == 0) {
      _remainingLegs--;
      if (_remainingLegs == 0) {
        _x = startX;
        _y = startY;
        return (x: _x, y: _y, done: true);
      }
      _remainingSteps = frames;
      _stepX = -_stepX;
      _stepY = -_stepY;
    }
    _remainingWait = wait;
    return (x: _x, y: _y, done: false);
  }
}
