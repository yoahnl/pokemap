import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  for (final viewport in const [Size(390, 844), Size(844, 390)]) {
    testWidgets(
      'root gives fight priority without hiding secondary commands at $viewport',
      (tester) async {
        await _pump(tester, viewport: viewport);
        final fight = tester.getRect(
          find.byKey(const ValueKey('battle-entry-0')),
        );
        final bag = tester.getRect(
          find.byKey(const ValueKey('battle-entry-1')),
        );
        final party = tester.getRect(
          find.byKey(const ValueKey('battle-entry-2')),
        );
        final run = tester.getRect(
          find.byKey(const ValueKey('battle-entry-3')),
        );
        if (viewport.height > viewport.width) {
          expect(fight.width, greaterThan(bag.width * 2));
          expect(fight.bottom, lessThanOrEqualTo(bag.top));
          expect(bag.top, party.top);
          expect(party.top, run.top);
        } else {
          expect(fight.left, lessThan(bag.left));
          expect(fight.width, greaterThan(bag.width));
          expect(fight.top, bag.top);
        }
        for (final rect in [fight, bag, party, run]) {
          expect(rect.height, greaterThanOrEqualTo(48));
        }
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'four moves remain a two by two grid and exhausted PP cannot submit',
    (tester) async {
      final actions = <PlayerBattleAction>[];
      await _pump(
        tester,
        viewport: const Size(844, 390),
        moves: true,
        onAction: actions.add,
      );
      final rects = [
        for (var index = 0; index < 4; index++)
          tester.getRect(find.byKey(ValueKey('battle-entry-$index'))),
      ];
      expect(rects[0].top, rects[1].top);
      expect(rects[2].top, rects[3].top);
      expect(rects[2].top - rects[0].bottom, greaterThanOrEqualTo(8));
      for (final rect in rects) {
        expect(rect.height, greaterThanOrEqualTo(48));
      }
      final back = tester.getRect(find.byKey(const ValueKey('battle-back')));
      expect(back.left - rects[1].right, greaterThanOrEqualTo(12));
      expect(find.text('PP 0/20'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('battle-entry-0')));
      expect(actions, isEmpty);
      await tester.tap(find.byKey(const ValueKey('battle-entry-1')));
      expect(
        actions.single,
        isA<PlayerBattleSelectEntryAction>()
            .having((action) => action.snapshotRevision, 'revision', 42)
            .having((action) => action.entryIndex, 'entry', 1),
      );
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('controller has a move list, details and a real back command', (
    tester,
  ) async {
    final actions = <PlayerBattleAction>[];
    await _pump(
      tester,
      viewport: const Size(844, 390),
      moves: true,
      source: PlayerInputSource.controller,
      onAction: actions.add,
    );
    expect(
      find.byKey(const ValueKey('battle-controller-moves')),
      findsOneWidget,
    );
    final first = tester.getRect(find.byKey(const ValueKey('battle-entry-0')));
    final last = tester.getRect(find.byKey(const ValueKey('battle-entry-3')));
    expect(first.left, last.left);
    expect(last.top, greaterThan(first.top));
    await tester.tap(find.byKey(const ValueKey('battle-back')));
    expect(
      actions.single,
      isA<PlayerBattleBackAction>().having(
        (value) => value.snapshotRevision,
        'revision',
        42,
      ),
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'paginated battle items keep every runtime index reachable without scrolling',
    (tester) async {
      final actions = <PlayerBattleAction>[];
      await _pump(
        tester,
        viewport: const Size(844, 390),
        bagCount: 10,
        onAction: actions.add,
      );
      expect(find.byType(Scrollable), findsNothing);
      expect(find.byKey(const ValueKey('battle-entry-9')), findsNothing);
      for (var index = 0; index < 4; index++) {
        await tester.tap(find.byKey(const ValueKey('battle-page-next')));
        await tester.pump();
      }
      expect(actions, isEmpty);
      expect(find.text('5 / 5'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('battle-entry-9')));
      expect(
        actions.single,
        isA<PlayerBattleSelectEntryAction>()
            .having((value) => value.entryIndex, 'runtime entry', 9)
            .having((value) => value.snapshotRevision, 'revision', 42),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion removes HUD entrance movement', (tester) async {
    await _pump(tester, viewport: const Size(844, 390), reducedMotion: true);
    final slides = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide));
    expect(slides, isNotEmpty);
    expect(slides.every((slide) => slide.duration == Duration.zero), isTrue);
  });

  testWidgets(
    'companion renders commands without stage HUD or redundant battle heading',
    (tester) async {
      await _pump(
        tester,
        viewport: const Size(600, 600),
        display: PlayerBattleDisplay.commandsOnly,
      );
      expect(find.text('Rival'), findsNothing);
      expect(find.text('Compagnon'), findsNothing);
      expect(find.byKey(const ValueKey('battle-entry-0')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Size viewport,
  bool moves = false,
  bool reducedMotion = false,
  int bagCount = 0,
  PlayerBattleDisplay display = PlayerBattleDisplay.full,
  ValueChanged<PlayerBattleAction>? onAction,
  PlayerInputSource source = PlayerInputSource.touch,
}) async {
  await tester.binding.setSurfaceSize(viewport);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  const hud = PlayerBattleHudViewData(
    ownerLabel: 'Compagnon',
    speciesLabel: 'Créature',
    level: 7,
    currentHp: 24,
    maxHp: 30,
  );
  final panelHeight = viewport.height > viewport.width ? 298.0 : 140.0;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(reducedMotion: reducedMotion),
      home: Scaffold(
        body: PlayerInputScope(
          activeInputSource: source,
          child: PlayerBattleSurface(
            display: display,
            paintBackground: false,
            onAction: onAction ?? (_) {},
            data: PlayerBattleViewData(
              revision: 42,
              enemy: hud,
              player: hud,
              battleLabel: 'Rival',
              title: bagCount > 0
                  ? 'Sac'
                  : moves
                  ? 'Capacités'
                  : 'Combat',
              prompt: moves
                  ? 'Choisissez une capacité.'
                  : 'Que doit faire Créature ?',
              narrationLines: const [],
              interactionsEnabled: true,
              canGoBack: moves || bagCount > 0,
              panelKind: bagCount > 0
                  ? PlayerBattlePanelKind.target
                  : moves
                  ? PlayerBattlePanelKind.moves
                  : PlayerBattlePanelKind.commands,
              viewportLayout: PlayerBattleViewportLayout(
                viewportSize: viewport,
                panelRect: Rect.fromLTWH(
                  0,
                  viewport.height - panelHeight,
                  viewport.width,
                  panelHeight,
                ),
                enemyHudRect: const Rect.fromLTWH(18, 16, 200, 70),
                playerHudRect: Rect.fromLTWH(
                  viewport.width - 228,
                  viewport.height - panelHeight - 90,
                  210,
                  80,
                ),
              ),
              commands: [
                for (
                  var index = 0;
                  index < (bagCount > 0 ? bagCount : 4);
                  index++
                )
                  PlayerBattleCommandViewData(
                    isBagItem: bagCount > 0,
                    index: index,
                    primaryLabel: bagCount > 0
                        ? 'Objet ${index + 1}'
                        : moves
                        ? 'Capacité ${index + 1}'
                        : const ['Combattre', 'Sac', 'Équipe', 'Fuite'][index],
                    secondaryLabel: moves ? 'normal' : '',
                    moveTypeId: moves ? 'normal' : null,
                    trailingLabel: moves
                        ? 'PP ${index == 0 ? 0 : 12}/20'
                        : null,
                    enabled: !moves || index != 0,
                    selected: index == 1,
                    tone: PlayerBattleEntryTone.attack,
                    commandId: moves || bagCount > 0
                        ? null
                        : ProjectBattleCommandId.values[index],
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
