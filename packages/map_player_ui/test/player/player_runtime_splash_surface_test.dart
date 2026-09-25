import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  const branding = RuntimeHostSplashBranding(
    displayName: 'AVELUNE',
    signature: 'UNE EXPÉRIENCE DE JEU',
    backgroundColorHex: '#030306',
    minimumDisplayDuration: Duration(milliseconds: 2400),
    exitTransitionDuration: Duration(milliseconds: 360),
    finalCurtainDuration: Duration(milliseconds: 180),
  );
  late MemoryImage logo;
  late MemoryImage wordmark;

  setUpAll(() async {
    logo = MemoryImage(await File(
      '../../apps/pokemap_hub/assets/avelune/logo/avelune_moon.png',
    ).readAsBytes());
    wordmark = MemoryImage(await File(
      '../../apps/pokemap_hub/assets/avelune/logo/avelune_glass_wordmark.png',
    ).readAsBytes());
    await (FontLoader('packages/map_player_ui/PokeMapSplashDMSans')
          ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf')))
        .load();
  });

  testWidgets('keeps the symbol at its final size without a camera zoom',
      (tester) async {
    final scales = <double>[];
    for (final progress in <double>[0, .12, .24, .36, .48, .7, 1]) {
      await tester.pumpWidget(_app(_timeline(
        branding: branding,
        progress: progress,
        logo: logo,
        wordmark: wordmark,
      )));
      final camera = tester.widget<Transform>(find.byKey(
        const ValueKey<String>('startup-splash-mark-zoom'),
      ));
      scales.add(camera.transform.storage[0]);
      expect(find.byKey(const ValueKey<String>('startup-splash-mark')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey<String>('startup-splash-wordmark-image')),
          findsOneWidget);
    }
    expect(scales.first, closeTo(.96, .001));
    for (var i = 1; i < scales.length; i++) {
      expect(scales[i], greaterThanOrEqualTo(scales[i - 1]));
      expect(scales[i], lessThanOrEqualTo(1));
    }
    expect(scales.last, closeTo(1, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('holds a clean logo while a game continues loading',
      (tester) async {
    await tester.pumpWidget(_app(PlayerRuntimeSplashSurface(
      branding: branding,
      progress: .35,
      animationProgress: 1,
      logo: logo,
      wordmark: wordmark,
    )));
    final timeline = tester.widget<PlayerSplashTimeline>(
      find.byKey(const ValueKey<String>('startup-splash-timeline')),
    );
    expect(timeline.progress, kPlayerSplashHoldProgress);
    expect(_curtainAlpha(tester), 0);
    expect(find.byKey(const ValueKey<String>('startup-splash-progress-label')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps adjacent 60 fps reveal frames continuous', (tester) async {
    double? previousMark;
    double? previousName;
    double? previousScale;
    for (var frame = 0; frame <= 118; frame++) {
      await tester.pumpWidget(_app(_timeline(
        branding: branding,
        progress: frame / 144,
        logo: logo,
        wordmark: wordmark,
      )));
      final mark = tester
          .widget<Opacity>(find.byKey(
            const ValueKey<String>('startup-splash-reveal'),
          ))
          .opacity;
      final name = tester
          .widget<Opacity>(find.byKey(
            const ValueKey<String>('startup-splash-name'),
          ))
          .opacity;
      final scale = tester
          .widget<Transform>(find.byKey(
            const ValueKey<String>('startup-splash-mark-zoom'),
          ))
          .transform
          .storage[0];
      if (previousMark != null) {
        expect(mark, inInclusiveRange(previousMark, previousMark + .08));
        expect(name, inInclusiveRange(previousName!, previousName + .08));
        expect(scale, inInclusiveRange(previousScale!, previousScale + .004));
      }
      previousMark = mark;
      previousName = name;
      previousScale = scale;
    }
    expect(previousMark, 1);
    expect(previousName, 1);
    expect(previousScale, 1);
  });

  testWidgets('reveals decoded artwork without a first-frame pop',
      (tester) async {
    final alphas = <double>[];
    for (final progress in <double>[0, .08, .16, .26, .37]) {
      await tester.pumpWidget(_app(_timeline(
        branding: branding,
        progress: progress,
        logo: logo,
        wordmark: wordmark,
      )));
      alphas.add(tester
          .widget<Opacity>(find.byKey(
            const ValueKey<String>('startup-splash-reveal'),
          ))
          .opacity);
    }
    expect(alphas.first, 0);
    for (var i = 1; i < alphas.length; i++) {
      expect(alphas[i], greaterThan(alphas[i - 1]));
    }
    expect(alphas.last, 1);
  });

  testWidgets('reduced motion shows the final lockup immediately',
      (tester) async {
    await tester.pumpWidget(_app(PlayerRuntimeSplashSurface(
      branding: branding,
      progress: .2,
      animationProgress: 0,
      logo: logo,
      wordmark: wordmark,
      reducedMotion: true,
    )));
    final camera = tester.widget<Transform>(find.byKey(
      const ValueKey<String>('startup-splash-mark-zoom'),
    ));
    expect(camera.transform.storage[0], 1);
    expect(
      find.byKey(const ValueKey<String>('startup-splash-wordmark-image')),
      findsOneWidget,
    );
    expect(_curtainAlpha(tester), 0);
  });

  testWidgets('closes the curtain only after loading is complete',
      (tester) async {
    Future<double> opacity(
        double loading, double animation, double exit) async {
      await tester.pumpWidget(_app(PlayerRuntimeSplashSurface(
        branding: branding,
        progress: loading,
        animationProgress: animation,
        exitProgress: exit,
      )));
      return _curtainAlpha(tester);
    }

    expect(await opacity(.99, 1, 1), 0);
    expect(await opacity(1, kPlayerSplashHoldProgress, 0), 0);
    expect(await opacity(1, .94, 0), 0);
    expect(await opacity(1, 1, 0), 0);
    expect(await opacity(1, 1, 1), 1);
  });

  testWidgets('keeps the host name if the supplied images cannot decode',
      (tester) async {
    await tester.pumpWidget(_app(PlayerRuntimeSplashSurface(
      branding: branding,
      progress: .5,
      animationProgress: .5,
      wordmark: MemoryImage(Uint8List.fromList(<int>[0, 1, 2])),
    )));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('startup-splash-fallback-mark')),
      findsOneWidget,
    );
    expect(find.text('AVELUNE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits the settled lockup and progress on desktop and phone',
      (tester) async {
    for (final size in <Size>[
      const Size(1600, 900),
      const Size(390, 693.333333),
    ]) {
      await _setViewport(tester, size);
      await tester.pumpWidget(_app(_timeline(
        branding: branding,
        progress: .7,
        logo: logo,
        wordmark: wordmark,
      )));
      await tester.pump();
      expect(
        tester
            .getSize(find.byKey(
              const ValueKey<String>('startup-splash-progress'),
            ))
            .width,
        lessThanOrEqualTo(size.width * .76),
      );
      expect(tester.takeException(), isNull);
    }
  });

  for (final viewport in <(String, Size)>[
    ('desktop', const Size(1600, 900)),
    ('mobile', const Size(390, 693.333333)),
  ]) {
    testWidgets('matches the ${viewport.$1} motion checkpoints',
        (tester) async {
      await _setViewport(tester, viewport.$2);
      for (final milliseconds in <int>[0, 240, 480, 720, 1152, 1968]) {
        final progress = milliseconds / 2400;
        await tester.pumpWidget(_goldenApp(_timeline(
          branding: branding,
          progress: progress,
          loadingProgress: progress,
          logo: logo,
          wordmark: wordmark,
        )));
        await tester.pump();
        await expectLater(
          find.byKey(const ValueKey<String>('startup-splash-golden')),
          matchesGoldenFile(
            'goldens/player_runtime_splash/v3_${viewport.$1}_${milliseconds.toString().padLeft(4, '0')}.png',
          ),
        );
      }
    });
  }

  testWidgets('matches the mobile slow-loading hold', (tester) async {
    await _setViewport(tester, const Size(390, 693.333333));
    await tester.pumpWidget(_goldenApp(PlayerSplashTimeline(
      branding: branding,
      progress: kPlayerSplashHoldProgress,
      exitProgress: 0,
      ambientProgress: .5,
      loadingProgress: 0,
      logo: logo,
      wordmark: wordmark,
      reducedMotion: false,
    )));
    await tester.pump();
    await expectLater(
      find.byKey(const ValueKey<String>('startup-splash-golden')),
      matchesGoldenFile(
        'goldens/player_runtime_splash/v3_mobile_waiting.png',
      ),
    );
  });
}

PlayerSplashTimeline _timeline({
  required RuntimeHostSplashBranding branding,
  required double progress,
  double? loadingProgress,
  ImageProvider? logo,
  ImageProvider? wordmark,
}) =>
    PlayerSplashTimeline(
      branding: branding,
      progress: progress,
      exitProgress: 0,
      ambientProgress: progress,
      loadingProgress: loadingProgress ?? .5,
      logo: logo,
      wordmark: wordmark,
      reducedMotion: false,
    );

Widget _app(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: PokeMapPlayerTheme.dark(),
      home: child,
    );

Widget _goldenApp(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: PokeMapPlayerTheme.dark(),
      home: RepaintBoundary(
        key: const ValueKey<String>('startup-splash-golden'),
        child: child,
      ),
    );

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

double _curtainAlpha(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find.byKey(const ValueKey<String>('startup-splash-curtain')),
    )
    .color
    .a;
