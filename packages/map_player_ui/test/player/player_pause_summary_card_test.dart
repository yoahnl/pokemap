import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('summary displays only the real location and progress',
      (tester) async {
    await tester.pumpWidget(_app(PlayerPauseSummaryCard(
      gameTitle: 'Voyage',
      profile: _profile(),
    )));
    expect(find.text('Port des brumes'), findsOneWidget);
    expect(find.text('Camille'), findsOneWidget);
    expect(find.text('Badges : 2 / 8'), findsOneWidget);
    expect(find.text('Temps de jeu : 12:05'), findsOneWidget);
    expect(find.text('Pokédex : 42 / 151'), findsOneWidget);
    expect(find.text('map.internal.004'), findsNothing);
    final size = tester
        .getSize(find.byKey(const ValueKey('player-pause-summary-panel')));
    expect(size.width, inInclusiveRange(520, 640));
    expect(size.height, closeTo(208, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary without a profile stays generic and has a silhouette',
      (tester) async {
    await tester.pumpWidget(_app(const PlayerPauseSummaryCard(
      gameTitle: 'Les chemins de l’aube',
    )));
    expect(find.text('Les chemins de l’aube'), findsOneWidget);
    expect(find.byKey(const ValueKey('player-pause-summary-silhouette')),
        findsOneWidget);
    expect(find.textContaining('Badges'), findsNothing);
    expect(find.textContaining('Temps de jeu'), findsNothing);
    expect(find.textContaining('Pokédex'), findsNothing);
    expect(find.textContaining('Camille'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'partial profile omits unknown values instead of inventing zeroes',
      (tester) async {
    await tester.pumpWidget(_app(PlayerPauseSummaryCard(
      gameTitle: 'Voyage',
      profile: RuntimePlayerProfileSnapshot(
        playerName: 'Camille',
        currentMapId: 'map.internal.004',
        money: 350,
        locationName: '   ',
      ),
    )));
    expect(find.text('Voyage'), findsOneWidget);
    expect(find.text('Camille'), findsOneWidget);
    expect(find.textContaining('Badges'), findsNothing);
    expect(find.textContaining('Temps de jeu'), findsNothing);
    expect(find.textContaining('Pokédex'), findsNothing);
    expect(find.textContaining('map.internal.004'), findsNothing);
    expect(find.textContaining('350'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('known badge count without a total and zero playtime are exact',
      (tester) async {
    await tester.pumpWidget(_app(PlayerPauseSummaryCard(
      gameTitle: 'Voyage',
      profile: RuntimePlayerProfileSnapshot(
        playerName: 'Camille',
        currentMapId: 'map.internal.004',
        money: 0,
        badgeIds: ['badge.tide'],
        playtimeSeconds: 0,
      ),
    )));
    expect(find.text('Badges : 1'), findsOneWidget);
    expect(find.text('Temps de jeu : 0:00'), findsOneWidget);
    expect(find.textContaining('/ 8'), findsNothing);
    expect(find.textContaining('Pokédex'), findsNothing);
  });

  for (final compact in [false, true]) {
    testWidgets('summary wraps at 300 pixels with large fonts compact=$compact',
        (tester) async {
      await tester.pumpWidget(_app(
          PlayerPauseSummaryCard(
            gameTitle: 'Voyage',
            profile: _profile(),
            compact: compact,
          ),
          width: 300,
          textScaler: const TextScaler.linear(2)));
      expect(find.text('Port des brumes'), findsOneWidget);
      expect(find.text('Badges : 2 / 8'), findsOneWidget);
      expect(find.text('Temps de jeu : 12:05'), findsOneWidget);
      expect(find.text('Pokédex : 42 / 151'), findsOneWidget);
      expect(
          tester
              .getSize(find.byKey(const ValueKey('player-pause-summary-panel')))
              .width,
          300);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('corrupt portrait retains a neutral silhouette', (tester) async {
    await tester.pumpWidget(_app(PlayerPauseSummaryCard(
      gameTitle: 'Voyage',
      profile: _profile(),
      portraitImage: MemoryImage(Uint8List.fromList([137, 80, 78, 71])),
    )));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('player-pause-summary-silhouette')),
        findsOneWidget);
    expect(find.text('Camille'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait keeps its ratio and releases its decoded image',
      (tester) async {
    final baseline = PaintingBinding.instance.imageCache.liveImageCount;
    final png = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(const Color(0xFF305070), BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(800, 1200);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      return data!.buffer.asUint8List();
    });
    await tester.pumpWidget(_app(PlayerPauseSummaryCard(
      gameTitle: 'Voyage',
      profile: _profile(),
      portraitImage: MemoryImage(png!),
    )));
    final portrait =
        find.byKey(const ValueKey('player-pause-summary-portrait'));
    final imageWidget = tester.widget<Image>(portrait);
    expect(imageWidget.fit, BoxFit.contain);
    expect(imageWidget.alignment, Alignment.bottomRight);
    final provider = imageWidget.image as ResizeImage;
    expect(provider.width, 320);
    expect(provider.height, 368);
    expect(provider.policy, ResizeImagePolicy.fit);
    ui.Image? decoded;
    for (var attempt = 0; attempt < 50 && decoded == null; attempt++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      decoded = tester
          .widgetList<RawImage>(
              find.descendant(of: portrait, matching: find.byType(RawImage)))
          .map((widget) => widget.image)
          .nonNulls
          .firstOrNull;
    }
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(320));
    expect(decoded.height, lessThanOrEqualTo(368));
    expect(decoded.width / decoded.height, closeTo(2 / 3, .005));
    expect(find.byKey(const ValueKey('player-pause-summary-silhouette')),
        findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(PaintingBinding.instance.imageCache.liveImageCount, baseline);
    expect(tester.takeException(), isNull);
  });
}

RuntimePlayerProfileSnapshot _profile() => RuntimePlayerProfileSnapshot(
      playerName: 'Camille',
      currentMapId: 'map.internal.004',
      locationName: 'Port des brumes',
      money: 350,
      badgeIds: ['badge.tide', 'badge.mist'],
      badgeTotal: 8,
      playtimeSeconds: 12 * 3600 + 5 * 60 + 49,
      pokedex: const RuntimePlayerPokedexProgressSnapshot(
          seen: 60, caught: 42, total: 151),
    );

Widget _app(Widget child,
        {double width = 640, TextScaler textScaler = TextScaler.noScaling}) =>
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!),
      home: Scaffold(
          body: SingleChildScrollView(
              child: Center(
        child:
            PlayerMenuThemeScope(child: SizedBox(width: width, child: child)),
      ))),
    );
