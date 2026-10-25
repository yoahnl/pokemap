import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_journal.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final format in [
    (size: Size(1440, 900), companion: false),
    (size: Size(1024, 768), companion: false),
    (size: Size(768, 1024), companion: false),
    (size: Size(844, 390), companion: false),
    (size: Size(390, 844), companion: false),
    (size: Size(496, 432), companion: true),
  ]) {
    testWidgets(
      'journal keeps three entries and its detail visible at $format',
      (tester) async {
        await _pump(
          tester,
          _detail(),
          size: format.size,
          companion: format.companion,
        );
        final body = tester.getRect(
          find.byKey(const ValueKey('runtime-player-detail-quests')),
        );
        for (final id in ['forest', 'first', 'stream']) {
          final row = find.byKey(ValueKey('journal-entry-$id'));
          expect(row.hitTestable(), findsOneWidget);
          final rect = tester.getRect(row);
          expect(body.contains(rect.topLeft), isTrue);
          expect(rect.bottom, lessThanOrEqualTo(body.bottom + .1));
        }
        final detail = tester.getRect(
          find.byKey(const ValueKey('journal-detail')),
        );
        final list = tester.getRect(find.byKey(const ValueKey('journal-list')));
        if (format.companion || format.size.aspectRatio > 1) {
          expect(detail.left, greaterThan(list.right));
          expect(detail.top, list.top);
          if (!format.companion) {
            expect(list.width / detail.width, closeTo(42 / 58, .01));
          }
        } else {
          expect(detail.top, greaterThan(list.bottom));
        }
        expect(detail.bottom, lessThanOrEqualTo(body.bottom + .1));
        expect(find.byKey(const ValueKey('player-page-next')), findsNothing);
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('journal selection displays every exact published field', (
    tester,
  ) async {
    await _pump(tester, _detail());
    await tester.tap(find.byKey(const ValueKey('journal-entry-first')));
    await tester.pumpAndSettle();
    expect(find.text('Le premier compagnon'), findsOneWidget);
    expect(find.text('Rencontrer le professeur'), findsOneWidget);
    expect(find.text('Terminé'), findsOneWidget);
    expect(find.text('Message public du journal'), findsOneWidget);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('journal-selected-progress')),
    );
    expect(progress.value, 1);
    expect(find.text('Parler au garde'), findsNothing);
    expect(find.textContaining('private-'), findsNothing);
  });

  testWidgets(
    'journal keyboard selects locally and lets Escape reach its shell',
    (tester) async {
      var returns = 0;
      await _pump(tester, _detail(), onBack: () => returns++);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Le premier compagnon'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(returns, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('journal replaces removed selections without stale data', (
    tester,
  ) async {
    await _pump(tester, _detail());
    await tester.tap(find.byKey(const ValueKey('journal-entry-first')));
    await tester.pumpAndSettle();
    await _pump(
      tester,
      RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.quests,
        title: 'Journal',
        entries: [
          RuntimePlayerDetailEntrySnapshot(
            id: 'private-new',
            title: 'Nouveau chapitre',
            subtitle: 'Objectif publié',
          ),
        ],
      ),
    );
    expect(find.text('Nouveau chapitre'), findsOneWidget);
    expect(find.text('Objectif publié'), findsOneWidget);
    expect(find.text('Le premier compagnon'), findsNothing);
    expect(
      find.byKey(const ValueKey('journal-selected-progress')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('large journal pages reveal keyboard selection after rotation', (
    tester,
  ) async {
    final detail = RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.quests,
      title: 'Journal',
      entries: [
        for (var index = 0; index < 20; index++)
          RuntimePlayerDetailEntrySnapshot(
            id: 'quest-$index',
            title: 'Chapitre $index',
            subtitle: 'Objectif $index',
          ),
      ],
    );
    await _pump(tester, detail, size: const Size(390, 844));
    for (var index = 0; index < 19; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(
      find.byKey(const ValueKey('journal-entry-quest-19')).hitTestable(),
      findsOneWidget,
    );
    await _pump(tester, detail, size: const Size(844, 390));
    expect(find.text('Chapitre 19'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('journal-entry-quest-19')).hitTestable(),
      findsOneWidget,
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text retains journal fields through bounded pages', (
    tester,
  ) async {
    await _pump(tester, _detail(), size: const Size(844, 390), scale: 2);
    final seen = <String>{};
    for (var page = 0; page < 16; page++) {
      for (final element in find.byType(Text).evaluate()) {
        if ((element.widget as Text).data case final text?) seen.add(text);
      }
      final next = find
          .byKey(const ValueKey('player-page-next'))
          .evaluate()
          .where((element) => (element.widget as IconButton).onPressed != null)
          .firstOrNull;
      if (next == null) break;
      await tester.tap(
        find.byElementPredicate((element) => identical(element, next)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(
      seen,
      containsAll(['Un passage dans la forêt', 'Parler au garde', 'En cours']),
    );
    expect(find.byType(Scrollable), findsNothing);
  });
}

RuntimePlayerPauseDetailSnapshot _detail() => RuntimePlayerPauseDetailSnapshot(
  section: RuntimePlayerPauseSection.quests,
  title: 'Journal',
  message: 'Message public du journal',
  entries: [
    RuntimePlayerDetailEntrySnapshot(
      id: 'forest',
      title: 'Un passage dans la forêt',
      subtitle: 'Parler au garde',
      trailingLabel: 'En cours',
      progress: .25,
    ),
    RuntimePlayerDetailEntrySnapshot(
      id: 'first',
      title: 'Le premier compagnon',
      subtitle: 'Rencontrer le professeur',
      trailingLabel: 'Terminé',
      progress: 1,
    ),
    RuntimePlayerDetailEntrySnapshot(
      id: 'stream',
      title: 'Au bord du ruisseau',
      subtitle: 'Explorer les environs',
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  RuntimePlayerPauseDetailSnapshot detail, {
  Size size = const Size(844, 390),
  bool companion = false,
  double scale = 1,
  VoidCallback? onBack,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: size.aspectRatio > 1 && !companion
              ? const EdgeInsets.fromLTRB(44, 12, 44, 20)
              : EdgeInsets.zero,
        ),
        child: companion ? PlayerCompanionScope(child: child!) : child!,
      ),
      home: PlayerMenuThemeScope(
        child: Scaffold(
          body: RuntimePlayerPauseShell(
            gameTitle: 'Voyage',
            pauseSection: RuntimePlayerPauseSection.quests,
            actions: {
              for (final action in PlayerPauseAction.values)
                action: PlayerActionAvailability.enabled,
            },
            onSelected: (_) {},
            onBackToRoot: onBack ?? () {},
            presentation: const PlayerPausePresentation(
              style: ProjectPauseMenuStyle.nightIllustrated,
            ),
            detailOwnsScroll: true,
            detail: RuntimePlayerJournal(detail: detail),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
