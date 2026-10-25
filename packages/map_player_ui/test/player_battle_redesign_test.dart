import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';
import 'package:map_runtime/map_runtime.dart' show BattleCommandPanelPlacement;

void main() {
  for (final viewport in const [Size(390, 844), Size(844, 390)]) {
    testWidgets(
      'root provides two tactile rows without hiding secondary commands at $viewport',
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
        expect(fight.width, bag.width);
        expect(fight.top, party.top);
        expect(bag.top, run.top);
        expect(fight.bottom, lessThan(bag.top));
        expect(fight.left, lessThan(party.left));
        expect(bag.left, lessThan(run.left));
        for (final rect in [fight, bag, party, run]) {
          expect(rect.height, greaterThanOrEqualTo(48));
        }
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'all command labels contrast with their actual command background',
    (tester) async {
      await _pump(tester, viewport: const Size(390, 844));
      for (var index = 0; index < 4; index++) {
        final button = find.byKey(ValueKey('battle-entry-$index'));
        final material = tester.widget<Material>(
          find.descendant(of: button, matching: find.byType(Material)).first,
        );
        final label = tester.widget<Text>(
          find.descendant(of: button, matching: find.byType(Text)).first,
        );
        final background = material.color!.computeLuminance();
        final foreground = label.style!.color!.computeLuminance();
        final ratio = foreground > background
            ? (foreground + .05) / (background + .05)
            : (background + .05) / (foreground + .05);
        expect(ratio, greaterThanOrEqualTo(4.5), reason: 'command $index');
      }
    },
  );

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
      expect(find.text('0 / 20'), findsOneWidget);
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

  testWidgets(
    'busy turns show compact narration without disabled command grid',
    (tester) async {
      final actions = <PlayerBattleAction>[];
      await _pump(
        tester,
        viewport: const Size(844, 390),
        busy: true,
        onAction: actions.add,
      );
      expect(find.text('Le tour se déroule.'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Le tour se déroule.')).style?.color,
        const Color(0xFF070A10),
      );
      expect(find.byKey(const ValueKey('battle-entry-0')), findsNothing);
      expect(find.text('Choisissez une capacité.'), findsNothing);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('battle-dialogue-panel')))
            .height,
        lessThanOrEqualTo(80),
      );
      expect(actions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Ligue cards use bevels and distinguish exhausted moves', (
    tester,
  ) async {
    await _pump(tester, viewport: const Size(390, 844), moves: true);
    for (var index = 0; index < 4; index++) {
      final entry = find.byKey(ValueKey('battle-entry-$index'));
      final card = tester.widget<Material>(
        find.descendant(of: entry, matching: find.byType(Material)).first,
      );
      expect(card.shape, isNot(isA<RoundedRectangleBorder>()));
      expect(
        tester.getSize(find.byKey(ValueKey('battle-type-icon-$index'))),
        const Size(20, 20),
      );
      expect(
        card.color,
        index == 0
            ? const Color(0xFF3D4854)
            : index == 1
            ? const Color(0xFF070A10)
            : const Color(0xFFFFFFFF),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('authored shape and padding survive without color overrides', (
    tester,
  ) async {
    await _pump(
      tester,
      viewport: const Size(390, 844),
      profile: const ProjectBattlePresentationProfile(
        commandShape: ProjectWindowShape.capsule,
        commandPadding: 20,
      ),
    );
    final panel = tester.widget<PlayerPanel>(
      find.byKey(const ValueKey('battle-command-panel')),
    );
    expect(panel.windowStyleOverride?.shape, ProjectWindowShape.capsule);
    expect(panel.windowStyleOverride?.contentPadding, 20);
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const ValueKey('battle-entry-0')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.shape, isA<RoundedRectangleBorder>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('move footer exposes button semantics and full touch targets', (
    tester,
  ) async {
    await _pump(tester, viewport: const Size(390, 844), moves: true);
    for (final key in ['battle-move-info', 'battle-back']) {
      final button = find.byKey(ValueKey(key));
      expect(tester.getSemantics(button).flagsCollection.isButton, isTrue);
      expect(tester.getSize(button).shortestSide, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [
    Size(390, 844),
    Size(844, 390),
    Size(496, 432),
  ]) {
    testWidgets('PP values and type badges fit without ellipsis at $viewport', (
      tester,
    ) async {
      await _pump(
        tester,
        viewport: viewport,
        moves: true,
        display: viewport.width == 496
            ? PlayerBattleDisplay.commandsOnly
            : PlayerBattleDisplay.full,
        source: viewport.width == 844
            ? PlayerInputSource.controller
            : PlayerInputSource.touch,
      );
      for (var index = 0; index < 4; index++) {
        final numberFinder = find.byKey(ValueKey('battle-pp-number-$index'));
        final number = tester.widget<Text>(numberFinder);
        expect(number.overflow, isNot(TextOverflow.ellipsis));
        final measure = TextPainter(
          text: TextSpan(text: number.data, style: number.style),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.noScaling,
        )..layout();
        expect(
          tester.getSize(numberFinder).width,
          greaterThanOrEqualTo(measure.width - .1),
        );
        measure.dispose();
        final badge = find.byKey(ValueKey('battle-type-badge-$index'));
        final badgeText = tester.widget<Text>(
          find.descendant(of: badge, matching: find.byType(Text)),
        );
        final typeMeasure = TextPainter(
          text: TextSpan(text: badgeText.data, style: badgeText.style),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.noScaling,
        )..layout();
        expect(
          tester.getSize(badge).width,
          greaterThanOrEqualTo(typeMeasure.width + 14),
        );
        typeMeasure.dispose();
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'reference move names and details fit alongside type and PP using the rendered font',
    (tester) async {
      final font = ByteData.sublistView(
        await File('assets/fonts/DMSans-Variable.ttf').readAsBytes(),
      );
      await (FontLoader('Avenir Next')..addFont(Future.value(font))).load();
      await _pump(
        tester,
        viewport: const Size(844, 390),
        moves: true,
        referenceMoves: true,
        source: PlayerInputSource.controller,
      );
      for (var index = 0; index < 4; index++) {
        for (final part in ['name', 'detail']) {
          final finder = find.byKey(ValueKey('battle-move-$part-$index'));
          final text = tester.widget<Text>(finder);
          final context = tester.element(finder);
          final style = DefaultTextStyle.of(context).style.merge(text.style);
          final painter = TextPainter(
            text: TextSpan(text: text.data, style: style),
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          expect(
            tester.getSize(finder).width,
            greaterThanOrEqualTo(painter.width - .1),
            reason:
                '${text.data} must fit at its actual font metrics alongside its type and PP',
          );
          painter.dispose();
        }
      }
      expect(find.text('Fouet Lianes'), findsOneWidget);
      expect(find.text('Vampigraine'), findsOneWidget);
      expect(find.text('Poudre Dodo'), findsOneWidget);
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
  bool referenceMoves = false,
  ProjectBattlePresentationProfile? profile,
  bool busy = false,
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
  final sceneLayout = BattleSceneLayout.forViewport(
    viewportSize: viewport,
    commandPanelPlacement: source == PlayerInputSource.controller
        ? BattleCommandPanelPlacement.end
        : BattleCommandPanelPlacement.bottom,
  );
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: profile == null
          ? PokeMapPlayerTheme.dark(reducedMotion: reducedMotion)
          : PokeMapPlayerTheme.withBattleProfile(
              PokeMapPlayerTheme.dark(reducedMotion: reducedMotion),
              profile,
            ),
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
              narrationLines: busy ? const ['Le tour se déroule.'] : const [],
              interactionsEnabled: !busy,
              canGoBack: moves || bagCount > 0,
              panelKind: busy
                  ? PlayerBattlePanelKind.message
                  : bagCount > 0
                  ? PlayerBattlePanelKind.target
                  : moves
                  ? PlayerBattlePanelKind.moves
                  : PlayerBattlePanelKind.commands,
              viewportLayout: PlayerBattleViewportLayout(
                viewportSize: viewport,
                panelRect: sceneLayout.commandPanelRect,
                enemyHudRect: sceneLayout.enemyHudRect,
                playerHudRect: sceneLayout.playerHudRect,
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
                    primaryLabel: referenceMoves
                        ? const [
                            'Fouet Lianes',
                            'Charge',
                            'Vampigraine',
                            'Poudre Dodo',
                          ][index]
                        : bagCount > 0
                        ? 'Objet ${index + 1}'
                        : moves
                        ? 'Capacité ${index + 1}'
                        : const ['Combattre', 'Sac', 'Équipe', 'Fuite'][index],
                    secondaryLabel: moves ? 'normal' : '',
                    moveTypeId: moves
                        ? (referenceMoves && index != 1 ? 'grass' : 'normal')
                        : null,
                    statusLabel: referenceMoves
                        ? const ['Peu efficace', '', 'Statut', 'Épuisée'][index]
                        : null,
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
