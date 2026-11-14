import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_journal.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'packages/map_player_ui/PokeMapSplashDMSans',
    )..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'))).load();
  });

  testWidgets('the selected entry shows its long text by paragraph', (
    tester,
  ) async {
    await _pump(tester, _detail(paragraphs: 2));

    expect(find.text('Paragraphe 0 du rival.'), findsOneWidget);
    expect(find.text('Paragraphe 1 du rival.'), findsOneWidget);
    expect(find.byKey(const ValueKey('journal-selected-body-2')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('journal-entry-clue')));
    await tester.pumpAndSettle();

    expect(find.text('Paragraphe 0 du rival.'), findsNothing);
    expect(find.text('Indice'), findsOneWidget);
    expect(find.byKey(const ValueKey('journal-selected-body-0')), findsNothing);
  });

  testWidgets('a long text pages with the keyboard without scrolling', (
    tester,
  ) async {
    await _pump(tester, _detail(paragraphs: 14));
    final seen = <String>{};
    for (var page = 0; page < 20; page++) {
      for (final element in find.byType(Text).hitTestable().evaluate()) {
        if ((element.widget as Text).data case final text?) seen.add(text);
      }
      if (seen.contains('Paragraphe 13 du rival.')) break;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    expect(seen, containsAll([for (var i = 0; i < 14; i++) _paragraph(i)]));
    expect(find.byType(Scrollable), findsNothing);
  });
}

String _paragraph(int index) => 'Paragraphe $index du rival.';

RuntimePlayerPauseDetailSnapshot _detail({required int paragraphs}) =>
    RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.quests,
      title: 'Journal',
      entries: [
        RuntimePlayerDetailEntrySnapshot(
          id: 'rival',
          title: 'Le rival',
          trailingLabel: 'En cours',
          body: [for (var i = 0; i < paragraphs; i++) _paragraph(i)]
              .join('\n\n'),
        ),
        RuntimePlayerDetailEntrySnapshot(
          id: 'clue',
          title: 'Des traces au nord',
          trailingLabel: 'Indice',
        ),
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  RuntimePlayerPauseDetailSnapshot detail,
) async {
  tester.view.physicalSize = const Size(844, 390);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: RuntimePlayerActions(
        onBack: () {},
        onMenu: () {},
        onInputSourceChanged: (_) {},
        includeDefaultKeyboardShortcuts: false,
        child: PlayerMenuThemeScope(
          child: Scaffold(
            body: RuntimePlayerPauseShell(
              gameTitle: 'Voyage',
              pauseSection: RuntimePlayerPauseSection.quests,
              actions: {
                for (final action in PlayerPauseAction.values)
                  action: PlayerActionAvailability.enabled,
              },
              onSelected: (_) {},
              onBackToRoot: () {},
              presentation: const PlayerPausePresentation(
                style: ProjectPauseMenuStyle.nightIllustrated,
              ),
              detailOwnsScroll: true,
              detail: RuntimePlayerJournal(detail: detail),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
