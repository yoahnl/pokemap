import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  testWidgets('recent activities are displayed with titles and relative time',
      (tester) async {
    await _pumpHome(tester, activities: _activities(2));
    await tester.pump();

    expect(find.text('ACTIVITÉ RÉCENTE'), findsOneWidget);
    expect(find.text('Act 0'), findsOneWidget);
    expect(find.text('Act 1'), findsOneWidget);
  });

  testWidgets('no activity section when there is no recent activity',
      (tester) async {
    await _pumpHome(tester, activities: const []);
    await tester.pump();

    expect(find.text('ACTIVITÉ RÉCENTE'), findsNothing);
  });

  testWidgets('voir tout appears and opens a sheet when overflowing',
      (tester) async {
    await _pumpHome(tester, activities: _activities(5));
    await tester.pump();

    expect(find.text('Voir tout'), findsOneWidget);

    await tester.tap(find.text('Voir tout'));
    await tester.pumpAndSettle();

    expect(find.text('Activité récente'), findsOneWidget);
    expect(find.text('Act 4'), findsOneWidget);
  });

  testWidgets('tapping an activatable activity launches continue',
      (tester) async {
    var continueCalls = 0;
    await _pumpHome(
      tester,
      activities: _activities(1, activatable: true),
      matchingGame: _game(
        id: 'games.avelune.activity-0',
        action: AvelunePrimaryAction.continueGame,
      ),
      onContinue: (_) => continueCalls++,
    );
    await tester.pump();

    await tester.tap(find.text('Act 0'));
    await tester.pump();
    await tester.pump();

    expect(continueCalls, 1);
  });

  testWidgets('non-activatable activity selects but does not launch',
      (tester) async {
    var continueCalls = 0;
    await _pumpHome(
      tester,
      activities: _activities(1, activatable: false),
      matchingGame: _game(
        id: 'games.avelune.activity-0',
        action: AvelunePrimaryAction.continueGame,
      ),
      onContinue: (_) => continueCalls++,
    );
    await tester.pump();

    await tester.tap(find.text('Act 0'));
    await tester.pump();
    await tester.pump();

    expect(continueCalls, 0);
  });
}

List<AveluneRecentActivityViewData> _activities(
  int count, {
  bool activatable = false,
}) =>
    List<AveluneRecentActivityViewData>.generate(
      count,
      (index) => AveluneRecentActivityViewData(
        gameId: 'games.avelune.activity-$index',
        gameTitle: 'Act $index',
        artwork: const AveluneArtworkViewData(
          kind: AveluneArtworkKind.fallback,
        ),
        occurredAt: DateTime(2026, 8, 5, 12).subtract(Duration(hours: index)),
        kind: AveluneRecentActivityKind.latestSave,
        canActivate: activatable,
      ),
    );

AveluneGameViewData _game({
  required String id,
  required AvelunePrimaryAction action,
}) =>
    AveluneGameViewData(
      id: id,
      title: 'Cartouche',
      subtitle: 'Studio Avelune',
      authorName: 'Studio Avelune',
      artwork: const AveluneArtworkViewData(
        kind: AveluneArtworkKind.fallback,
      ),
      shellColor: const Color(0xFF633C88),
      validity: AveluneGameValidity.available,
      primaryAction: action,
      isSelected: true,
      lastSaveAt: action == AvelunePrimaryAction.continueGame
          ? DateTime(2026, 8, 5, 12)
          : null,
      playTimeSeconds: 0,
    );

Future<void> _pumpHome(
  WidgetTester tester, {
  required List<AveluneRecentActivityViewData> activities,
  AveluneGameViewData? matchingGame,
  AveluneGameLaunchCallback? onContinue,
}) async {
  const size = Size(390, 844);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final theme = AveluneThemeData.standard.applyTo(ThemeData.dark());

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: theme,
      home: MediaQuery(
        data: const MediaQueryData(
          size: size,
          padding: EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: AveluneHomeScreen(
          viewData: _viewData(activities, matchingGame),
          appearance: const AveluneAppearancePreferences(),
          onContinue: onContinue,
          onNewGame: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AveluneHomeViewData _viewData(
  List<AveluneRecentActivityViewData> activities,
  AveluneGameViewData? game,
) =>
    AveluneHomeViewData(
      status: AveluneHomeStatus.ready,
      games: game == null
          ? const <AveluneGameViewData>[]
          : <AveluneGameViewData>[game],
      selectedGameId: game?.id,
      recentActivity: activities,
      import: const AveluneImportViewData.idle(canStart: true),
      safeErrorMessage: null,
      reducedMotion: true,
    );
