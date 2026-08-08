import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  const branding = RuntimeHostSplashBranding(
    displayName: 'PokeMap Runtime',
    signature: 'Une aventure prend vie',
  );

  testWidgets('exposes the premium timeline at 0, 45, 81 and 100 percent',
      (tester) async {
    for (final progress in <double>[0, .45, .81, 1]) {
      await tester.pumpWidget(
        _app(
          PlayerRuntimeSplashSurface(
            branding: branding,
            progress: .62,
            animationProgress: progress,
          ),
        ),
      );

      final timeline = tester.widget<PlayerSplashTimeline>(
        find.byKey(const ValueKey<String>('startup-splash-timeline')),
      );
      expect(timeline.progress, progress);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const ValueKey<String>('startup-splash-progress')),
            )
            .value,
        .62,
      );
      expect(tester.takeException(), isNull);
    }
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
    expect(timeline.progress, 1);
    expect(find.text('PokeMap Runtime'), findsOneWidget);
    expect(find.text('Une aventure prend vie'), findsOneWidget);
  });

  testWidgets('works in light and dark themes without a logo', (tester) async {
    for (final dark in <bool>[false, true]) {
      await tester.pumpWidget(
        _app(
          const PlayerRuntimeSplashSurface(
            branding: branding,
            progress: 1,
            animationProgress: 1,
          ),
          dark: dark,
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('startup-splash-fallback-mark')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('falls back safely when the supplied logo fails', (tester) async {
    await tester.pumpWidget(
      _app(
        const PlayerRuntimeSplashSurface(
          branding: branding,
          progress: 1,
          animationProgress: 1,
          logo: NetworkImage('not-a-valid-url'),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('startup-splash-fallback-mark')),
      findsOneWidget,
    );
  });
}

Widget _app(Widget child, {bool dark = true}) => MaterialApp(
      theme: dark ? PokeMapPlayerTheme.dark() : PokeMapPlayerTheme.light(),
      home: child,
    );
