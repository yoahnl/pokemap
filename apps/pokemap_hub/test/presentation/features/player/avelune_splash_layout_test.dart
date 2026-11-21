import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/presentation/features/player/splash/avelune_splash.dart';
import 'package:pokemap_hub/presentation/features/player/splash/avelune_splash_painter.dart';
import 'package:pokemap_hub/presentation/features/player/splash/avelune_splash_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the splash stays inside its own viewport on a shared canvas', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..drawColor(const ui.Color(0xffff0000), ui.BlendMode.src);
    canvas.translate(150, 0);
    _painter().paint(canvas, const ui.Size(200, 260));
    final bytes = await _pixels(recorder, 500, 260);

    expect(bytes.getUint32(0), 0xff0000ff);
    expect(bytes.getUint32((500 - 1) * 4), 0xff0000ff);
    expect(bytes.getUint32(151 * 4), isNot(0xff0000ff));
  });

  test(
    'the logo size stays stable when a resized window crosses square',
    () async {
      final a = await _logoWidth(479, 480);
      final b = await _logoWidth(481, 480);

      expect(a, greaterThan(60));
      expect((b - a).abs(), lessThan(4));
    },
  );

  test('the settled logo, title and background keep moving subtly', () async {
    const width = 390;
    const height = 844;
    final asset = await rootBundle.load(AveluneSplashPalette.ios.wordmarkAsset);
    final codec = await ui.instantiateImageCodec(asset.buffer.asUint8List());
    addTearDown(codec.dispose);
    final wordmark = (await codec.getNextFrame()).image;
    addTearDown(wordmark.dispose);

    Future<ByteData> frame(double ambient) {
      final recorder = ui.PictureRecorder();
      AveluneSplashPainter(
        progress: const AlwaysStoppedAnimation(1),
        ambient: AlwaysStoppedAnimation(ambient),
        wordmark: wordmark,
        brand: AveluneSplashPalette.ios,
        reducedMotion: false,
      ).paint(
        ui.Canvas(recorder),
        ui.Size(width.toDouble(), height.toDouble()),
      );
      return _pixels(recorder, width, height);
    }

    final initial = await frame(0);
    final quarter = await frame(.25);
    final half = await frame(.5);
    final markDrift =
        _brightCenterY(quarter, width, 290, 475) -
        _brightCenterY(initial, width, 290, 475);
    final titleDrift =
        _brightCenterY(half, width, 480, 552) -
        _brightCenterY(initial, width, 480, 552);
    final background = initial.buffer.asUint8List(
      180 * width * 4,
      60 * width * 4,
    );
    final movingBackground = quarter.buffer.asUint8List(
      180 * width * 4,
      60 * width * 4,
    );

    expect(markDrift.abs(), inExclusiveRange(.5, 5));
    expect(titleDrift.abs(), inExclusiveRange(.6, 4));
    expect(Object.hashAll(movingBackground), isNot(Object.hashAll(background)));
  });

  testWidgets('ambient motion starts after the intro and follows visibility', (
    tester,
  ) async {
    final intro = AnimationController(vsync: tester);
    addTearDown(intro.dispose);

    Future<void> show({bool active = true, bool disableAnimations = false}) =>
        tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: AveluneSplash(
              progress: intro,
              palette: AveluneSplashPalette.ios,
              reducedMotion: false,
              active: active,
            ),
          ),
        );

    AveluneSplashPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(AveluneSplash),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as AveluneSplashPainter;

    await show();
    intro.value = .8;
    await tester.pump(const Duration(seconds: 2));
    expect(painter().ambient.value, 0);

    intro.value = 1;
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    final phase = painter().ambient.value;
    expect(phase, closeTo(.25, .01));

    await show(active: false);
    await tester.pump(const Duration(seconds: 2));
    expect(painter().ambient.value, phase);

    await show(disableAnimations: true);
    await tester.pump(const Duration(seconds: 2));
    expect(painter().reducedMotion, isTrue);
    expect(painter().ambient.value, phase);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

double _brightCenterY(ByteData frame, int width, int top, int bottom) {
  var count = 0;
  var total = 0;
  for (var y = top; y < bottom; y++) {
    for (var x = 0; x < width; x++) {
      if (frame.getUint8((y * width + x) * 4 + 2) >= 150) {
        count++;
        total += y;
      }
    }
  }
  expect(count, greaterThan(0));
  return total / count;
}

AveluneSplashPainter _painter() => AveluneSplashPainter(
  progress: const AlwaysStoppedAnimation(1),
  ambient: const AlwaysStoppedAnimation(0),
  wordmark: null,
  brand: AveluneSplashPalette.ios,
  reducedMotion: true,
);

Future<int> _logoWidth(int width, int height) async {
  final recorder = ui.PictureRecorder();
  _painter().paint(
    ui.Canvas(recorder),
    ui.Size(width.toDouble(), height.toDouble()),
  );
  final bytes = await _pixels(recorder, width, height);
  var left = width;
  var right = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (bytes.getUint8((y * width + x) * 4 + 2) < 170) continue;
      if (x < left) left = x;
      if (x > right) right = x;
    }
  }
  return right - left;
}

Future<ByteData> _pixels(
  ui.PictureRecorder recorder,
  int width,
  int height,
) async {
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  } finally {
    image.dispose();
    picture.dispose();
  }
}
