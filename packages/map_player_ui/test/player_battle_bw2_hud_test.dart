import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets(
    'trainer badge preserves name and HP rail sizes at native HUD height',
    (tester) async {
      for (final custom in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          await _pumpOverlayVisibility(
            tester,
            custom: custom,
            visible: true,
            scale: scale,
            hudWidth: 208,
            hudHeight: 40.5,
          );
          final name = tester.getRect(
            find.byKey(const ValueKey('battle-species-enemy')),
          );
          final rail = tester.getRect(
            find.byKey(const ValueKey('battle-hp-plate-enemy')),
          );
          await _pumpOverlayVisibility(
            tester,
            custom: custom,
            visible: true,
            scale: scale,
            hudWidth: 208,
            hudHeight: 40.5,
            remainingTeamCount: 3,
            teamSize: 6,
          );
          expect(
            tester.getRect(find.byKey(const ValueKey('battle-species-enemy'))),
            name,
          );
          expect(
            tester.getRect(find.byKey(const ValueKey('battle-hp-plate-enemy'))),
            rail,
          );
          expect(find.text('3 / 6'), findsOneWidget);
          expect(tester.getSize(find.text('3 / 6')).height, greaterThan(0));
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets(
    'trainer HUD maps remaining team count without showing wild teams',
    (tester) async {
      await _pumpOverlayVisibility(
        tester,
        custom: false,
        visible: true,
        remainingTeamCount: 3,
        teamSize: 6,
      );
      expect(
        find.byKey(const ValueKey('battle-trainer-gauge-enemy')),
        findsOneWidget,
      );
      expect(find.text('3 / 6'), findsOneWidget);
      expect(find.byIcon(Icons.catching_pokemon), findsNWidgets(6));
      expect(
        find.byKey(const ValueKey('battle-trainer-gauge-player')),
        findsNothing,
      );

      await _pumpOverlayVisibility(tester, custom: false, visible: true);
      expect(
        find.byKey(const ValueKey('battle-trainer-gauge-enemy')),
        findsNothing,
      );
      expect(find.byIcon(Icons.catching_pokemon), findsNothing);
    },
  );

  testWidgets(
    'trainer gauge fits enlarged narrow HUDs and hides with the sequence',
    (tester) async {
      await _pumpOverlayVisibility(
        tester,
        custom: false,
        visible: true,
        remainingTeamCount: 0,
        teamSize: 6,
        scale: 2,
        hudWidth: 156,
        enemyStatus: 'PAR',
      );
      expect(find.text('0 / 6'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _pumpOverlayVisibility(
        tester,
        custom: false,
        visible: false,
        remainingTeamCount: 0,
        teamSize: 6,
        scale: 2,
        hudWidth: 156,
        enemyStatus: 'PAR',
      );
      expect(
        tester.renderObject(
          find.byKey(const ValueKey('battle-hud-target-enemy')),
        ),
        paintsNothing,
      );
      expect(
        find.byKey(const ValueKey('battle-hud-target-enemy')).hitTestable(),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final custom in [false, true]) {
    testWidgets(
      'hidden HUDs stop painting and targeting with custom layout $custom',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _pumpOverlayVisibility(tester, custom: custom, visible: true);
          final enemy = find.byKey(const ValueKey('battle-hud-target-enemy'));
          final player = find.byKey(const ValueKey('battle-hud-target-player'));
          expect(enemy.hitTestable(), findsOneWidget);
          expect(player.hitTestable(), findsOneWidget);
          expect(find.semantics.byLabel(RegExp('Moustillon')), findsOneWidget);
          final xpElement = tester.element(
            find.byKey(const ValueKey('battle-xp-player')),
          );

          await _pumpOverlayVisibility(tester, custom: custom, visible: false);

          expect(tester.renderObject(enemy), paintsNothing);
          expect(tester.renderObject(player), paintsNothing);
          expect(enemy.hitTestable(), findsNothing);
          expect(player.hitTestable(), findsNothing);
          expect(
            find.semantics.byLabel(RegExp('Moustillon|Chacripan')),
            findsNothing,
          );
          expect(
            tester.element(find.byKey(const ValueKey('battle-xp-player'))),
            same(xpElement),
          );

          await _pumpOverlayVisibility(tester, custom: custom, visible: true);

          expect(enemy.hitTestable(), findsOneWidget);
          expect(player.hitTestable(), findsOneWidget);
          expect(find.semantics.byLabel(RegExp('Moustillon')), findsOneWidget);
          expect(
            tester.element(find.byKey(const ValueKey('battle-xp-player'))),
            same(xpElement),
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('BW2 HUD separates its name from the dark angular HP rail', (
    tester,
  ) async {
    await _pump(tester);
    final name = tester.widget<Text>(
      find.byKey(const ValueKey('battle-species-player')),
    );
    final level = tester.widget<Text>(
      find.byKey(const ValueKey('battle-level-player')),
    );
    final rail = find.byKey(const ValueKey('battle-hp-plate-player'));
    expect(name.style?.color, const Color(0xFFFFFFFF));
    expect(level.style?.color, const Color(0xFFF3CC50));
    expect(rail, findsOneWidget);
    final material = tester.widget<Material>(rail);
    expect(material.color, const Color(0xFF171D23));
    expect(material.shape, isA<BeveledRectangleBorder>());
    expect(
      tester
          .getRect(find.byKey(const ValueKey('battle-species-player')))
          .bottom,
      lessThanOrEqualTo(tester.getRect(rail).top),
    );
    final exact = tester.getRect(
      find.byKey(const ValueKey('battle-exact-hp-player')),
    );
    expect(tester.getRect(rail).contains(exact.center), isTrue);
    expect(find.text('HP'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('battle-exact-hp-enemy')), findsNothing);
    expect(find.byKey(const ValueKey('battle-xp-player')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BW2 HUD keeps threshold colors and blue experience readable', (
    tester,
  ) async {
    for (final state in [
      (hp: 80, color: const Color(0xFF4DD968)),
      (hp: 40, color: const Color(0xFFF2BD37)),
      (hp: 10, color: const Color(0xFFEF6756)),
    ]) {
      await _pump(tester, hp: state.hp);
      final hp = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(const ValueKey('battle-hp-rounded-player')),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(hp.color, state.color);
      final xp = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(const ValueKey('battle-xp-player')),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(xp.color, const Color(0xFF36B8ED));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('BW2 HUD preserves authored shape, HP visibility and colors', (
    tester,
  ) async {
    await _pump(
      tester,
      hp: 40,
      profile: const ProjectBattlePresentationProfile(
        hudShape: ProjectWindowShape.rectangle,
        hpBarShape: ProjectBattleHpBarShape.flat,
        showLevel: false,
        showExactHp: false,
        hpWarningColor: '#FFAA00',
      ),
    );
    final material = tester.widget<Material>(
      find.byKey(const ValueKey('battle-hp-plate-player')),
    );
    expect(material.shape, isA<RoundedRectangleBorder>());
    expect(find.byKey(const ValueKey('battle-level-player')), findsNothing);
    expect(find.byKey(const ValueKey('battle-exact-hp-player')), findsNothing);
    final hp = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: find.byKey(const ValueKey('battle-hp-flat-player')),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(hp.color, const Color(0xFFFFAA00));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'BW2 HUD fits narrow and enlarged text without hiding live data',
    (tester) async {
      for (final scale in [1.0, 2.0]) {
        await _pump(tester, scale: scale, width: 156);
        expect(
          find.byKey(const ValueKey('battle-exact-hp-player')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('battle-xp-player')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}

Future<void> _pumpOverlayVisibility(
  WidgetTester tester, {
  required bool custom,
  required bool visible,
  int? remainingTeamCount,
  int? teamSize,
  double scale = 1,
  double hudWidth = 270,
  double hudHeight = 100,
  String? enemyStatus,
}) async {
  final theme = PokeMapPlayerTheme.dark(reducedMotion: true);
  BattleCommandOverlayHudSnapshot hud(bool player) =>
      BattleCommandOverlayHudSnapshot(
        rect: Rect.fromLTWH(
          player ? 400 : 20,
          player ? 300 : 20,
          hudWidth,
          hudHeight,
        ),
        ownerLabel: player ? 'Compagnon' : 'Adversaire',
        speciesLabel: player ? 'Moustillon' : 'Chacripan',
        level: 12,
        currentHp: 80,
        maxHp: 100,
        isPlayerSide: player,
        experienceProgress: player ? .4 : null,
        isVisible: visible,
        remainingTeamCount: player ? null : remainingTeamCount,
        teamSize: player ? null : teamSize,
        statusLabel: player ? null : enemyStatus,
      );
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      theme: custom
          ? PokeMapPlayerTheme.withBattleProfile(
              theme,
              const ProjectBattlePresentationProfile(
                commandLayout: ProjectBattleCommandLayout.list,
                hudShape: ProjectWindowShape.rectangle,
                enemyHudPosition: ProjectBattleHudPosition.topEnd,
              ),
            )
          : theme,
      home: Scaffold(
        body: PlayerBattleOverlay(
          display: PlayerBattleDisplay.hudOnly,
          onCommand: (_) {},
          snapshot: BattleCommandOverlaySnapshot(
            mode: BattleCommandOverlayMode.fight,
            viewportSize: const Size(800, 600),
            panelRect: const Rect.fromLTWH(0, 500, 800, 100),
            enemyHud: hud(false),
            playerHud: hud(true),
            battleLabel: 'Combat',
            title: '',
            prompt: '',
            narrationLines: const [],
            entries: const [],
            interactionsEnabled: false,
            canGoBack: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pump(
  WidgetTester tester, {
  int hp = 80,
  double scale = 1,
  double width = 270,
  ProjectBattlePresentationProfile? profile,
}) async {
  final theme = PokeMapPlayerTheme.dark(reducedMotion: true);
  final hud = PlayerBattleHudViewData(
    ownerLabel: 'Compagnon',
    speciesLabel: 'Moustillon',
    level: 12,
    currentHp: hp,
    maxHp: 100,
    experienceProgress: .4,
    genderSymbol: '♂',
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: profile == null
          ? theme
          : PokeMapPlayerTheme.withBattleProfile(theme, profile),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: PlayerBattleSurface(
            display: PlayerBattleDisplay.hudOnly,
            paintBackground: false,
            onAction: (_) {},
            data: PlayerBattleViewData(
              revision: 1,
              enemy: PlayerBattleHudViewData(
                ownerLabel: 'Adversaire',
                speciesLabel: 'Chacripan',
                level: 12,
                currentHp: hp,
                maxHp: 100,
              ),
              player: hud,
              battleLabel: 'Combat',
              title: '',
              prompt: '',
              narrationLines: const [],
              commands: const [],
              interactionsEnabled: false,
              canGoBack: false,
              viewportLayout: PlayerBattleViewportLayout(
                viewportSize: const Size(800, 600),
                panelRect: const Rect.fromLTWH(0, 500, 800, 100),
                enemyHudRect: Rect.fromLTWH(20, 20, width, 100),
                playerHudRect: Rect.fromLTWH(400, 300, width, 100),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
