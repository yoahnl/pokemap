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
  );
  late Uint8List logoBytes;

  setUpAll(() async {
    logoBytes = await _logoBytes();
    await (FontLoader('packages/map_player_ui/PokeMapSplashMarcellus')
          ..addFont(rootBundle.load('assets/fonts/Marcellus-Regular.ttf')))
        .load();
    await (FontLoader('packages/map_player_ui/PokeMapSplashDMSans')
          ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf')))
        .load();
  });

  testWidgets('ports every signed premium splash timestamp', (tester) async {
    const times = <int>[0, 500, 1500, 3000, 4500, 5750, 6750, 7200];
    for (final milliseconds in times) {
      final loading = _mockLoadingProgress(milliseconds);
      await tester.pumpWidget(
        _app(
          PlayerSplashTimeline(
            branding: branding,
            progress:
                (milliseconds / kPlayerSplashTimelineMilliseconds).clamp(0, 1),
            exitProgress: 0,
            ambientProgress: (milliseconds % 10000) / 10000,
            loadingProgress: loading,
            loadingLabel: _mockLoadingLabel(loading),
            reducedMotion: false,
          ),
        ),
      );

      final timeline = tester.widget<PlayerSplashTimeline>(
        find.byType(PlayerSplashTimeline),
      );
      expect(
        timeline.progress,
        closeTo(milliseconds / kPlayerSplashTimelineMilliseconds, .0001),
      );
      expect(timeline.loadingProgress, loading);
      expect(
        find.byKey(const ValueKey<String>('startup-splash-progress-value')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'holds a live composition when real loading outlasts the timeline',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const PlayerRuntimeSplashSurface(
          branding: branding,
          progress: .62,
          animationProgress: 1,
          ambientProgress: .93,
          loadingLabel: 'Accord du monde',
        ),
      ),
    );

    final timeline = tester.widget<PlayerSplashTimeline>(
      find.byKey(const ValueKey<String>('startup-splash-timeline')),
    );
    expect(timeline.progress, kPlayerSplashHoldProgress);
    expect(
      find.byKey(const ValueKey<String>('startup-splash-progress-label')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('startup-splash-progress-value')),
      findsOneWidget,
    );
    expect(_curtainAlpha(tester), 0);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey<String>('startup-splash-mark')),
          )
          .opacity,
      greaterThan(.5),
    );
  });

  testWidgets('finishes the exact curtain only after loading is complete',
      (tester) async {
    Future<double> curtain(double animation, double exit) async {
      await tester.pumpWidget(
        _app(
          PlayerRuntimeSplashSurface(
            branding: branding,
            progress: 1,
            animationProgress: animation,
            exitProgress: exit,
          ),
        ),
      );
      return _curtainAlpha(tester);
    }

    expect(await curtain(kPlayerSplashHoldProgress, 0), 0);
    expect(await curtain(6750 / 7200, 0), closeTo(.261, .01));
    expect(await curtain(1, 0), closeTo(.866, .01));
    expect(await curtain(1, 1), 1);
  });

  testWidgets('reduced motion renders the complete static composition',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const PlayerRuntimeSplashSurface(
          branding: branding,
          progress: .2,
          animationProgress: 0,
          reducedMotion: true,
        ),
      ),
    );

    final timeline = tester.widget<PlayerSplashTimeline>(
      find.byKey(const ValueKey<String>('startup-splash-timeline')),
    );
    expect(timeline.progress, kPlayerSplashHoldProgress);
    expect(
      find.byKey(const ValueKey<String>('startup-splash-wordmark')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('startup-splash-signature')),
      findsOneWidget,
    );
    expect(_curtainAlpha(tester), 0);
  });

  testWidgets('matches desktop and 9:16 responsive geometry', (tester) async {
    final logo = MemoryImage(logoBytes);
    await _setViewport(tester, const Size(1600, 900));
    await tester.pumpWidget(
      _app(
        PlayerRuntimeSplashSurface(
          branding: branding,
          progress: .68,
          animationProgress: 4500 / 7200,
          ambientProgress: .45,
          logo: logo,
        ),
      ),
    );
    await tester.pump();

    expect(
      tester
          .getSize(
              find.byKey(const ValueKey<String>('startup-splash-progress')))
          .width,
      470,
    );
    expect(tester.getSize(find.byType(Image).first).width, 176);

    await _setViewport(tester, const Size(390, 693.333333));
    await tester.pumpWidget(
      _app(
        PlayerRuntimeSplashSurface(
          branding: branding,
          progress: .68,
          animationProgress: 4500 / 7200,
          ambientProgress: .45,
          logo: logo,
        ),
      ),
    );
    await tester.pump();

    expect(
      tester
          .getSize(
              find.byKey(const ValueKey<String>('startup-splash-progress')))
          .width,
      closeTo(296.4, .01),
    );
    expect(tester.getSize(find.byType(Image).first).width, closeTo(132.6, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back safely when the supplied logo fails', (tester) async {
    await tester.pumpWidget(
      _app(
        const PlayerRuntimeSplashSurface(
          branding: branding,
          progress: 1,
          animationProgress: .5,
          logo: NetworkImage('not-a-valid-url'),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('startup-splash-fallback-mark')),
      findsWidgets,
    );
  });

  testWidgets('certifies the desktop timeline against deterministic goldens',
      (tester) async {
    await _setViewport(tester, const Size(1600, 900));
    final logo = MemoryImage(logoBytes);
    const frames = <int>[0, 500, 1500, 3000, 4500, 5750, 6750, 7200];
    for (final milliseconds in frames) {
      final loading = _mockLoadingProgress(milliseconds);
      await tester.pumpWidget(
        _goldenApp(
          PlayerSplashTimeline(
            branding: branding,
            progress: milliseconds / 7200,
            exitProgress: 0,
            ambientProgress: (milliseconds % 10000) / 10000,
            loadingProgress: loading,
            loadingLabel: _mockLoadingLabel(loading),
            logo: logo,
            reducedMotion: false,
          ),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byKey(const ValueKey<String>('startup-splash-golden')),
        matchesGoldenFile(
          'goldens/player_runtime_splash/desktop_${milliseconds.toString().padLeft(4, '0')}.png',
        ),
      );
    }

    await tester.pumpWidget(
      _goldenApp(
        PlayerSplashTimeline(
          branding: branding,
          progress: 1,
          exitProgress: 1,
          ambientProgress: .748,
          loadingProgress: 1,
          loadingLabel: 'Prêt',
          logo: logo,
          reducedMotion: false,
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(const ValueKey<String>('startup-splash-golden')),
      matchesGoldenFile(
        'goldens/player_runtime_splash/desktop_7480.png',
      ),
    );
  });

  testWidgets('certifies the mobile 9:16 composition', (tester) async {
    await _setViewport(tester, const Size(390, 693.333333));
    final logo = MemoryImage(logoBytes);
    await tester.pumpWidget(
      _goldenApp(
        PlayerSplashTimeline(
          branding: branding,
          progress: 4500 / 7200,
          exitProgress: 0,
          ambientProgress: .45,
          loadingProgress: _mockLoadingProgress(4500),
          loadingLabel: 'Accord du monde',
          logo: logo,
          reducedMotion: false,
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(const ValueKey<String>('startup-splash-golden')),
      matchesGoldenFile('goldens/player_runtime_splash/mobile_9x16_4500.png'),
    );
  });
}

Widget _app(Widget child) => MaterialApp(
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

Future<Uint8List> _logoBytes() => File(
      '../../apps/pokemap_hub/assets/avelune/logo/avelune_mark.webp',
    ).readAsBytes();

double _mockLoadingProgress(int milliseconds) {
  final elapsed = (milliseconds / 7200).clamp(0.0, 1.0);
  final value = switch (elapsed) {
    < .2 => (elapsed / .2) * 24,
    < .48 => 24 + ((elapsed - .2) / .28) * 31,
    < .78 => 55 + ((elapsed - .48) / .3) * 29,
    _ => 84 + ((elapsed - .78) / .22) * 16,
  };
  return value.round().clamp(0, 100) / 100;
}

String _mockLoadingLabel(double progress) => switch (progress) {
      < .24 => 'Éveil',
      < .55 => 'Préparation du voyage',
      < .84 => 'Accord du monde',
      _ => 'Prêt',
    };

double _curtainAlpha(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find.byKey(const ValueKey<String>('startup-splash-curtain')),
    )
    .color
    .a;
