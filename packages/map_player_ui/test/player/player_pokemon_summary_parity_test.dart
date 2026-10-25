import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets(
    'portrait summary changes tabs from body focus without repeating held Page keys',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final bodyFocus = FocusNode(debugLabel: 'Summary action body');
      addTearDown(bodyFocus.dispose);
      final sources = <PlayerInputSource>[];
      await tester.pumpWidget(
        _host(
          RuntimePlayerActions(
            onBack: () {},
            onMenu: () {},
            onInputSourceChanged: sources.add,
            child: RuntimePlayerInputBindings(
              child: PlayerPokemonSummarySheet(
                summary: _summary(),
                actions: TextButton(
                  focusNode: bodyFocus,
                  onPressed: () {},
                  child: const Text('Action publiée'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('pokemon-summary-tab-actions')),
      );
      await tester.pumpAndSettle();
      bodyFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlayerMenuSelectableRow>(
              find.byKey(const ValueKey('pokemon-summary-tab-stats')),
            )
            .selected,
        isTrue,
      );
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlayerMenuSelectableRow>(
              find.byKey(const ValueKey('pokemon-summary-tab-stats')),
            )
            .selected,
        isTrue,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.pageUp);
      await tester.tap(
        find.byKey(const ValueKey('pokemon-summary-tab-actions')),
      );
      await tester.pumpAndSettle();
      bodyFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlayerMenuSelectableRow>(
              find.byKey(const ValueKey('pokemon-summary-tab-summary')),
            )
            .selected,
        isTrue,
      );
      expect(sources, contains(PlayerInputSource.keyboard));
      expect(tester.takeException(), isNull);
    },
  );

  setUpAll(() async {
    await (FontLoader(
      'packages/map_player_ui/PokeMapSplashDMSans',
    )..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'))).load();
  });
  group('BETA-PTY-001 Party and PC render one shared sheet', () {
    testWidgets('the same summary renders identical text on both surfaces', (
      tester,
    ) async {
      final summary = _summary();

      await tester.pumpWidget(
        _host(
          PlayerPokemonSummarySheet(
            summary: summary,
            surfaceRole: ProjectPresentationSurfaceRole.party,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fromParty = await _allTabText(tester);

      await tester.pumpWidget(
        _host(
          PlayerPokemonSummarySheet(
            summary: summary,
            surfaceRole: ProjectPresentationSurfaceRole.pokedex,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fromPc = await _allTabText(tester);

      expect(
        fromParty,
        fromPc,
        reason: 'the surface role themes the panel, never the content',
      );
    });

    testWidgets('the sheet shows the localized species, never the raw id', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(PlayerPokemonSummarySheet(summary: _summary())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bulbizarre'), findsWidgets);
      expect(find.text('bulbasaur'), findsNothing);
      expect(find.text('Bulbasaur'), findsNothing);
    });

    testWidgets('every canonical field reaches the screen', (tester) async {
      await tester.pumpWidget(
        _host(PlayerPokemonSummarySheet(summary: _summary())),
      );
      await tester.pumpAndSettle();

      final content = await _allTabText(tester);
      for (final value in [
        'Niv. 12',
        '20/48',
        'Hardy',
        'Overgrow',
        'Mâle',
        '120',
        'Baie Oran',
        '70/255',
        'Charge · Normal',
        'PP 30/35',
        'Capturé',
        'Route Hanazuki',
        'Tall Grass',
        '5',
        'Poke Ball',
        '49',
      ]) {
        expect(
          content,
          contains(value),
          reason:
              'The authored field $value must remain reachable through the real tabs and pages.',
        );
      }
      expect(find.byType(Scrollable), findsNothing);
    });

    testWidgets('the HP gauge carries the same threshold as the battle HUD', (
      tester,
    ) async {
      Color gaugeColorFor({required int currentHp, required int maxHp}) {
        return tester
                .widget<LinearProgressIndicator>(
                  find.byType(LinearProgressIndicator),
                )
                .color ??
            const Color(0x00000000);
      }

      await tester.pumpWidget(
        _host(
          PlayerPokemonSummarySheet(
            summary: _summary(currentHp: 44, maxHp: 48),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final healthy = gaugeColorFor(currentHp: 44, maxHp: 48);

      await tester.pumpWidget(
        _host(
          PlayerPokemonSummarySheet(
            summary: _summary(currentHp: 20, maxHp: 48),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final warning = gaugeColorFor(currentHp: 20, maxHp: 48);

      await tester.pumpWidget(
        _host(
          PlayerPokemonSummarySheet(summary: _summary(currentHp: 4, maxHp: 48)),
        ),
      );
      await tester.pumpAndSettle();
      final danger = gaugeColorFor(currentHp: 4, maxHp: 48);

      expect(
        <Color>{healthy, warning, danger},
        hasLength(3),
        reason:
            'a Pokémon at 20/48 must not look as healthy as one at 44/48, '
            'and one at 4/48 must not look like either',
      );
      expect(playerHpToneFor(44 / 48), PlayerHpTone.healthy);
      expect(playerHpToneFor(20 / 48), PlayerHpTone.warning);
      expect(playerHpToneFor(4 / 48), PlayerHpTone.danger);
    });

    testWidgets('the gauge track never reads as a full bar', (tester) async {
      await tester.pumpWidget(
        _host(
          PlayerPokemonSummarySheet(
            summary: _summary(currentHp: 20, maxHp: 48),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final gauge = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(
        gauge.backgroundColor,
        isNotNull,
        reason:
            'without an explicit neutral track the theme painted a '
            'saturated green behind the fill, so a damaged Pokémon looked '
            'untouched',
      );
      expect(gauge.value, closeTo(20 / 48, 0.0001));
    });

    testWidgets('a move without PP tracking shows a dash, never zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          PlayerPokemonSummarySheet(
            summary: _summary(
              moves: <RuntimePokemonMoveSummarySnapshot>[
                const RuntimePokemonMoveSummarySnapshot(
                  moveId: 'tackle',
                  label: 'Charge',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('pokemon-summary-tab-moves')));
      await tester.pumpAndSettle();
      expect(find.text('—'), findsOneWidget);
      expect(find.text('PP 0/0'), findsNothing);
    });

    testWidgets('a summary without stats hides the stats block entirely', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(PlayerPokemonSummarySheet(summary: _summary(stats: null))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('pokemon-summary-tab-stats')));
      await tester.pumpAndSettle();
      expect(find.text('Attaque'), findsNothing);
      expect(find.text('Défense'), findsNothing);
      expect(find.text('Aucun'), findsOneWidget);
    });

    testWidgets('all four tab labels fit at the five target surface sizes', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final size in [
        const Size(390, 844),
        const Size(844, 390),
        const Size(496, 432),
        const Size(768, 432),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          _host(
            PlayerPokemonSummarySheet(
              key: ValueKey(size),
              summary: _summary(
                moves: [
                  for (var i = 0; i < 4; i++)
                    RuntimePokemonMoveSummarySnapshot(
                      moveId: i == 0 ? 'tackle' : 'tackle$i',
                      label: [
                        'Charge',
                        'Fouet Lianes',
                        'Vampigraine',
                        'Poudre Dodo',
                      ][i],
                      typeLabel: 'Normal',
                      currentPp: 20,
                      maxPp: 20,
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final name in ['summary', 'moves', 'stats', 'actions']) {
          final button = find.byKey(ValueKey('pokemon-summary-tab-$name'));
          final bounds = tester.getRect(button);
          final text = find.descendant(of: button, matching: find.byType(Text));
          final paragraph = tester.renderObject<RenderParagraph>(text);
          expect(paragraph.didExceedMaxLines, isFalse, reason: '$size $name');
          expect(bounds.height, greaterThanOrEqualTo(48));
          expect(button.hitTestable(), findsOneWidget);
        }
        final firstTab = tester.getRect(
          find.byKey(const ValueKey('pokemon-summary-tab-summary')),
        );
        final lastTab = tester.getRect(
          find.byKey(const ValueKey('pokemon-summary-tab-actions')),
        );
        expect(
          firstTab.top,
          lastTab.top,
          reason: '$size keeps four normal-size tabs on one line',
        );
        await tester.tap(
          find.byKey(const ValueKey('pokemon-summary-tab-moves')),
        );
        await tester.pumpAndSettle();
        final move = find.byKey(const ValueKey('pokemon-summary-move-tackle'));
        expect(move.hitTestable(), findsOneWidget);
        expect(tester.getSize(move).height, greaterThanOrEqualTo(48));
        for (var i = 1; i < 4; i++) {
          expect(
            find.byKey(ValueKey('pokemon-summary-move-tackle$i')).hitTestable(),
            findsOneWidget,
            reason: '$size move $i',
          );
        }
        if (size.width >= 450) {
          final second = tester.getRect(
            find.byKey(const ValueKey('pokemon-summary-move-tackle1')),
          );
          expect(tester.getRect(move).top, second.top);
          expect(second.left, greaterThan(tester.getRect(move).right));
        }
        await tester.tap(move);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('pokemon-summary-selected-move')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets(
      'companion keeps all four moves in its constrained content pane',
      (tester) async {
        await tester.pumpWidget(
          _host(
            Center(
              child: SizedBox(
                width: 432,
                height: 240,
                child: PlayerCompanionScope(
                  child: PlayerPokemonSummarySheet(
                    showHeader: false,
                    summary: _summary(
                      moves: [
                        for (var i = 0; i < 4; i++)
                          RuntimePokemonMoveSummarySnapshot(
                            moveId: 'move$i',
                            label: [
                              'Fouet Lianes',
                              'Charge',
                              'Vampigraine',
                              'Poudre Dodo',
                            ][i],
                            currentPp: i,
                            maxPp: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('pokemon-summary-tab-moves')),
        );
        await tester.pumpAndSettle();
        for (var i = 0; i < 4; i++) {
          expect(
            find.byKey(ValueKey('pokemon-summary-move-move$i')).hitTestable(),
            findsOneWidget,
          );
        }
        final first = tester.getRect(
          find.byKey(const ValueKey('pokemon-summary-move-move0')),
        );
        final second = tester.getRect(
          find.byKey(const ValueKey('pokemon-summary-move-move1')),
        );
        expect(first.top, second.top);
        expect(second.left - first.right, greaterThanOrEqualTo(8));
        expect(
          find
              .byKey(const ValueKey('pokemon-summary-selected-move'))
              .hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('the sheet survives a narrow portrait viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(PlayerPokemonSummarySheet(summary: _summary())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Bulbizarre'), findsWidgets);
    });
  });
}

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
  localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
  theme: PokeMapPlayerTheme.dark(),
  home: PlayerMenuThemeScope(
    role: ProjectPresentationSurfaceRole.party,
    child: Scaffold(body: child),
  ),
);

Set<String> _visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .where((value) => value.isNotEmpty)
    .toSet();

Future<Set<String>> _allTabText(WidgetTester tester) async {
  final content = <String>{};
  for (final tab in ['summary', 'moves', 'stats', 'actions']) {
    await tester.tap(find.byKey(ValueKey('pokemon-summary-tab-$tab')));
    await tester.pumpAndSettle();
    for (var page = 0; page < 40; page++) {
      content.addAll(_visibleText(tester));
      final next = find.byKey(const ValueKey('player-page-next'));
      if (next.evaluate().isEmpty ||
          tester.widget<IconButton>(next).onPressed == null) {
        break;
      }
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  }
  return content;
}

RuntimePokemonSummarySnapshot _summary({
  int currentHp = 20,
  int maxHp = 48,
  RuntimePokemonStatsSummarySnapshot? stats =
      const RuntimePokemonStatsSummarySnapshot(
        attack: 49,
        defense: 49,
        specialAttack: 65,
        specialDefense: 65,
        speed: 45,
      ),
  List<RuntimePokemonMoveSummarySnapshot> moves =
      const <RuntimePokemonMoveSummarySnapshot>[
        RuntimePokemonMoveSummarySnapshot(
          moveId: 'tackle',
          label: 'Charge',
          typeLabel: 'Normal',
          currentPp: 30,
          maxPp: 35,
        ),
      ],
}) {
  return RuntimePokemonSummarySnapshot(
    targetId: 'pokemon.indiv-1',
    individualId: 'indiv-1',
    speciesLabel: 'Bulbizarre',
    nickname: '',
    level: 12,
    experience: 120,
    currentHp: currentHp,
    maxHp: maxHp,
    stats: stats,
    natureLabel: 'Hardy',
    abilityLabel: 'Overgrow',
    genderLabel: 'Mâle',
    heldItemLabel: 'Baie Oran',
    friendship: 70,
    moves: moves,
    provenance: const RuntimePokemonProvenanceSummarySnapshot(
      originLabel: 'Capturé',
      metMapLabel: 'Route Hanazuki',
      metSourceLabel: 'Tall Grass',
      metLevel: 5,
      ballLabel: 'Poke Ball',
    ),
  );
}
