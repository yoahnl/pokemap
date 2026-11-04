import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'battle_gen5_swing.dart';

final class BattleGen5SourceBackground extends Component {
  BattleGen5SourceBackground({required this.viewport}) : super(priority: 2);

  final ui.Rect Function() viewport;
  final ui.Paint _paint = ui.Paint()..filterQuality = ui.FilterQuality.none;
  ui.Image? _image;
  ui.Offset offset = ui.Offset.zero;
  bool visible = false;
  bool hideField = false;
  int? _remaining;
  BattleGen5Swing? _swing;
  int? _moveTargetX;
  int _moveTargetY = 0;
  int _movePositionX = 0;
  int _movePositionY = 0;
  int _moveStepX = 0;
  int _moveStepY = 0;
  int _moveWait = 0;
  int _moveWaitRemaining = 0;
  int? _waveFrames;
  int _waveMode = 0;
  int _waveAmplitude = 0;
  int _waveStep = 0;
  int _waveShift = 0;
  List<ui.Image>? _paletteFrames;
  List<int>? _paletteDurations;
  int _paletteIndex = 0;
  int _paletteTimer = 0;
  int _paletteLoops = 0;
  ui.Offset _step = ui.Offset.zero;

  bool get isMoving => _remaining != null || _swing != null || _moveTargetX != null;
  bool get isWaving => _waveFrames != null;
  bool get isPaletteAnimating => _paletteFrames != null;

  void setPaletteFade(int level, ui.Color color) {
    _paint.colorFilter = level == 0
        ? null
        : ui.ColorFilter.mode(
            color.withValues(alpha: level / 16), ui.BlendMode.srcATop);
  }

  void load(ui.Image image) {
    if (image.width != 512 || image.height != 512) {
      throw const FormatException('Invalid source background dimensions');
    }
    _image = image;
    offset = ui.Offset.zero;
    visible = false;
    _remaining = null;
    _swing = null;
    _moveTargetX = null;
    _paletteFrames = null;
    _paletteDurations = null;
  }

  void scroll({
    required int x,
    required int y,
    required int frames,
    bool mirror = false,
  }) {
    if (frames < 0) throw const FormatException('Invalid background duration');
    _step = ui.Offset((mirror ? -x : x).toDouble(), y.toDouble());
    _remaining = frames;
    _swing = null;
    _moveTargetX = null;
  }

  void move({required int x, required int y, required int frames, required int wait}) {
    if (frames < 1 || frames > 600 || wait < 0 || wait > 600) {
      throw const FormatException('Invalid background movement');
    }
    _movePositionX = (offset.dx * 4096).round();
    _movePositionY = (offset.dy * 4096).round();
    _moveTargetX = _movePositionX + x * 4096;
    _moveTargetY = _movePositionY + y * 4096;
    _moveStepX = x * 4096 ~/ frames;
    _moveStepY = y * 4096 ~/ frames;
    if (_moveStepX == 0 && x != 0) _moveStepX = x.sign;
    if (_moveStepY == 0 && y != 0) _moveStepY = y.sign;
    _moveWait = wait;
    _moveWaitRemaining = 0;
    _remaining = null;
    _swing = null;
  }

  void startWave({required int mode, required int amplitude, required int step,
      required int frames}) {
    if ((mode != 0 && mode != 1) || amplitude < 0 || amplitude > 65536 ||
        step < 1 || step > 360 || frames < 1 || frames > 600) {
      throw const FormatException('Invalid background wave');
    }
    _waveMode = mode;
    _waveAmplitude = amplitude;
    _waveStep = (65535 * step) ~/ 360;
    _waveShift = 0;
    _waveFrames = frames;
  }

  void swing({
    required int x,
    required int y,
    required int frames,
    required int wait,
    required int count,
  }) {
    _swing = BattleGen5Swing(
      startX: (offset.dx % 512).round() * 4096,
      startY: (offset.dy % 512).round() * 4096,
      deltaX: x * 4096,
      deltaY: y * 4096,
      frames: frames,
      wait: wait,
      count: count,
      maxDelta: 512 * 4096,
    );
    _remaining = null;
    _moveTargetX = null;
  }

  void animatePalette({
    required List<ui.Image> frames,
    required List<int> durations,
    required int loops,
  }) {
    if (_image == null || frames.isEmpty || frames.length > 32 ||
        frames.length != durations.length || loops < 0 || loops > 32 ||
        frames.any((image) => image.width != 512 || image.height != 512) ||
        durations.any((duration) => duration < 0 || duration > 255)) {
      throw const FormatException('Invalid background palette animation');
    }
    _paletteFrames = List.unmodifiable(frames);
    _paletteDurations = List.unmodifiable(durations);
    _paletteIndex = 0;
    _paletteTimer = 255;
    _paletteLoops = math.max(1, loops);
  }

  void tick() {
    final swing = _swing;
    if (swing != null) {
      final value = swing.advance();
      offset = ui.Offset((value.x >> 12).toDouble(), (value.y >> 12).toDouble());
      if (value.done) _swing = null;
    } else if (_moveTargetX != null) {
      if (_moveWaitRemaining > 0) {
        _moveWaitRemaining--;
      } else {
        int advance(int value, int step, int target) {
          final next = value + step;
          return step < 0 ? math.max(next, target) : math.min(next, target);
        }
        _movePositionX = advance(_movePositionX, _moveStepX, _moveTargetX!);
        _movePositionY = advance(_movePositionY, _moveStepY, _moveTargetY);
        offset = ui.Offset((_movePositionX >> 12).toDouble(),
            (_movePositionY >> 12).toDouble());
        _moveWaitRemaining = _moveWait;
        if (_movePositionX == _moveTargetX && _movePositionY == _moveTargetY) {
          _moveTargetX = null;
        }
      }
    } else {
      final remaining = _remaining;
      if (remaining != null) {
        offset += _step;
        _remaining = remaining == 0 ? null : remaining - 1;
      }
    }
    final waveFrames = _waveFrames;
    if (waveFrames != null) {
      _waveShift = (_waveShift + 1) % (_waveMode == 0 ? 192 : 256);
      _waveFrames = waveFrames == 1 ? null : waveFrames - 1;
    }
    final frames = _paletteFrames;
    final durations = _paletteDurations;
    if (frames == null || durations == null) return;
    if (_paletteTimer < durations[_paletteIndex] - 2) {
      _paletteTimer++;
      return;
    }
    _image = frames[_paletteIndex];
    _paletteTimer = 0;
    if (_paletteIndex == frames.length - 1) {
      _paletteLoops--;
      if (_paletteLoops == 0) {
        _paletteFrames = null;
        _paletteDurations = null;
      } else {
        _paletteIndex = 0;
      }
    } else {
      _paletteIndex++;
    }
  }

  void reset() {
    _image = null;
    offset = ui.Offset.zero;
    visible = false;
    hideField = false;
    _remaining = null;
    _swing = null;
    _moveTargetX = null;
    _waveFrames = null;
    _paletteFrames = null;
    _paletteDurations = null;
    _step = ui.Offset.zero;
    _paint.colorFilter = null;
  }

  @override
  void render(ui.Canvas canvas) {
    final image = _image;
    final rect = viewport();
    if (rect.isEmpty || (!hideField && (!visible || image == null))) return;
    canvas.save();
    canvas.clipRect(rect);
    if (hideField) {
      canvas.drawRect(rect, ui.Paint()..color = const ui.Color(0xff000000));
    }
    if (!visible || image == null) {
      canvas.restore();
      return;
    }
    final scale = math.max(rect.width / 256, rect.height / 192);
    final width = rect.width / scale;
    final height = rect.height / scale;
    final left = offset.dx + (256 - width) / 2;
    final top = offset.dy + (192 - height) / 2;
    canvas.translate(rect.left, rect.top);
    canvas.scale(scale);
    void drawTiled(double sourceLeft, double sourceTop) {
      final firstX = (sourceLeft / image.width).floor();
      final firstY = (sourceTop / image.height).floor();
      final lastX = ((sourceLeft + width) / image.width).ceil();
      final lastY = ((sourceTop + height) / image.height).ceil();
      for (var y = firstY; y < lastY; y++) {
        for (var x = firstX; x < lastX; x++) {
          canvas.drawImage(image,
              ui.Offset(x * image.width - sourceLeft, y * image.height - sourceTop),
              _paint);
        }
      }
    }
    if (!isWaving) {
      drawTiled(left, top);
    } else {
      final screenTop = (192 - height) / 2;
      final lines = _waveMode == 0 ? 192 : 256;
      for (var line = screenTop.floor(); line < (screenTop + height).ceil(); line++) {
        final localY = line - screenTop;
        final phase = ((line + _waveShift + 1) % lines) * _waveStep;
        final displacement = (math.sin((phase & 0xffff) * math.pi * 2 / 65536) *
            _waveAmplitude / 4096).floorToDouble();
        canvas.save();
        canvas.clipRect(ui.Rect.fromLTWH(0, localY, width, 1));
        drawTiled(left + (_waveMode == 0 ? displacement : 0),
            top + (_waveMode == 1 ? displacement : 0));
        canvas.restore();
      }
    }
    canvas.restore();
  }
}
