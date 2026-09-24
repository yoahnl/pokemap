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

  testWidgets('moves the entire lockup through one continuous camera pull',
      (tester) async {
    final scales = <double>[];
    for (final progress in <double>[0, .12, .24, .36, .48, .7]) {
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
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey<String>('startup-splash-mark')),
          matching: find.byKey(
            const ValueKey<String>('startup-splash-mark-zoom'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey<String>('startup-splash-wordmark')),
          matching: find.byKey(
            const ValueKey<String>('startup-splash-mark-zoom'),
          ),
        ),
        findsOneWidget,
      );
    }
    expect(scales.first, closeTo(5.2, .001));
    for (var i = 1; i < 5; i++) {
      expect(scales[i], lessThan(scales[i - 1]));
    }
    expect(scales[4], closeTo(1, .001));
    expect(scales[5], closeTo(1, .001));
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
    expect(
      find.byKey(const ValueKey<String>('startup-splash-progress-value')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reveals decoded artwork without a first-frame pop',
      (tester) async {
    final alphas = <double>[];
    for (final progress in <double>[0, .025, .05, .075, .1]) {
      await tester.pumpWidget(_app(_timeline(
        branding: branding,
        progress: progress,
        logo: logo,
        wordmark: wordmark,
      )));
      alphas.add(tester.widget<Opacity>(find.byKey(
        const ValueKey<String>('startup-splash-reveal'),
      )).opacity);
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
    final closing = await opacity(1, .94, 0);
    expect(closing, greaterThan(0));
    expect(closing, lessThan(.86));
    expect(await opacity(1, 1, 0), closeTo(.86, .001));
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
