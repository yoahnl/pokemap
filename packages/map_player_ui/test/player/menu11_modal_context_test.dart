import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_bag.dart';
import 'package:map_player_ui/src/player/runtime_player_party.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('packages/map_player_ui/PokeMapSplashDMSans')
          ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf')))
        .load();
  });

  for (final effectsOpaque in [true, false]) {
    final mode = effectsOpaque ? 'session effects' : 'local opaque scope';

    testWidgets('bag confirmation preserves nested session context: $mode',
        (tester) async {
      final commands = <RuntimePlayerPauseCommand>[];
      await _pump(
          tester, RuntimePlayerBag(detail: _bag, onCommand: commands.add),
          role: ProjectPresentationSurfaceRole.bag,
          effectsOpaque: effectsOpaque);
      await _tap(tester, 'runtime-player-bag-use-potion');

      _expectModalContext(tester, effectsOpaque: effectsOpaque);
      expect(find.text('Utiliser Potion'), findsOneWidget);
      expect(find.text('Use Potion'), findsNothing);
      await _tap(tester, 'runtime-player-bag-target-pokemon.first');
      expect(find.text('Confirmer'), findsOneWidget);
      expect(find.text('Retour'), findsOneWidget);
      await _tap(tester, 'bag-use-confirm');

      expect(find.byType(Dialog), findsNothing);
      expect(commands, hasLength(1));
      expect(commands.single.kind, RuntimePlayerPauseCommandKind.useBagItem);
      expect(commands.single.itemTargetId, 'potion');
      expect(commands.single.partyTargetId, 'pokemon.first');
      expect(tester.takeException(), isNull);
    });

    testWidgets('party actions preserve nested session context: $mode',
        (tester) async {
      await _pump(tester, _party(), scale: 1.5, effectsOpaque: effectsOpaque);
      await _tap(tester, 'party-member-first');

      _expectModalContext(tester, scale: 1.5, effectsOpaque: effectsOpaque);
      expect(
          find.descendant(
              of: find.byType(Dialog), matching: find.text('Retour')),
          findsOneWidget);
      await tester.tap(find.descendant(
          of: find.byType(Dialog), matching: find.text('Retour')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('held item dialog preserves nested session context: $mode',
        (tester) async {
      final commands = <RuntimePlayerPauseCommand>[];
      await _pump(tester, _party(onCommand: commands.add),
          effectsOpaque: effectsOpaque);
      await _tap(tester, 'party-member-first');
      await _tap(tester, 'runtime-player-held-manage-pokemon.first');

      _expectModalContext(tester, effectsOpaque: effectsOpaque);
      expect(find.text('Remplacer par Restes'), findsOneWidget);
      await _tap(tester, 'runtime-player-held-option-pokemon.first-leftovers');

      expect(find.byType(Dialog), findsNothing);
      expect(commands, hasLength(1));
      expect(commands.single.kind, RuntimePlayerPauseCommandKind.equipHeldItem);
      expect(commands.single.itemTargetId, 'leftovers');
      expect(commands.single.partyTargetId, 'pokemon.first');
      expect(tester.takeException(), isNull);
    });

    testWidgets('summary dialog preserves nested session context: $mode',
        (tester) async {
      await _pump(tester, _party(), effectsOpaque: effectsOpaque);
      await _tap(tester, 'party-member-first');
      await _tap(tester, 'runtime-player-party-summary-pokemon.first');

      _expectModalContext(tester, effectsOpaque: effectsOpaque);
      final sheet = find.byType(PlayerPokemonSummarySheet);
      expect(find.descendant(of: sheet, matching: find.text('Niv. 17')),
          findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);
      await _tap(tester, 'pokemon-summary-close');
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pump(WidgetTester tester, Widget child,
    {double scale = 2,
    required bool effectsOpaque,
    ProjectPresentationSurfaceRole role =
        ProjectPresentationSurfaceRole.party}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1100);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: PokeMapPlayerTheme.dark(),
    home: Builder(builder: (context) {
      expect(Localizations.localeOf(context), const Locale('en'));
      expect(
          Localizations.of<PokeMapPlayerLocalizations>(
              context, PokeMapPlayerLocalizations),
          isNull);
      expect(MediaQuery.textScalerOf(context).scale(1), 1);
      expect(PlayerMenuEffectsScope.of(context), RuntimePlayerMenuEffects.full);
      return Localizations.override(
        context: context,
        locale: const Locale('fr'),
        delegates: PokeMapPlayerLocalizations.localizationsDelegates,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
          ),
          child: PlayerMenuEffectsScope(
            effects: effectsOpaque
                ? RuntimePlayerMenuEffects.opaque
                : RuntimePlayerMenuEffects.full,
            child: PlayerMenuThemeScope(
              role: role,
              opaque: !effectsOpaque,
              child: Scaffold(body: child),
            ),
          ),
        ),
      );
    }),
  ));
  await tester.pumpAndSettle();
}

void _expectModalContext(WidgetTester tester,
    {double scale = 2, required bool effectsOpaque}) {
  final dialog = find.byType(Dialog);
  expect(dialog, findsOneWidget);
  final context = tester.element(dialog);
  expect({
    'locale': Localizations.localeOf(context),
    'playerLocale': context.playerL10n.locale,
    'scale': MediaQuery.textScalerOf(context).scale(1),
    'reducedMotion': MediaQuery.disableAnimationsOf(context),
    'padding': MediaQuery.paddingOf(context),
    'opaque': context.playerMenuTheme.opaque,
    'effects': PlayerMenuEffectsScope.of(context),
  }, {
    'locale': const Locale('fr'),
    'playerLocale': const Locale('fr'),
    'scale': scale,
    'reducedMotion': true,
    'padding': const EdgeInsets.fromLTRB(24, 30, 24, 20),
    'opaque': true,
    'effects': effectsOpaque
        ? RuntimePlayerMenuEffects.opaque
        : RuntimePlayerMenuEffects.full,
  });
  expect(find.descendant(of: dialog, matching: find.byType(BackdropFilter)),
      findsNothing);
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

RuntimePlayerParty _party(
        {void Function(RuntimePlayerPauseCommand)? onCommand}) =>
    RuntimePlayerParty(
      detail: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.party,
        title: 'Équipe',
        entries: [
          RuntimePlayerDetailEntrySnapshot(
            id: 'pokemon.first',
            title: 'Bulbizarre',
            pokemonSummary: RuntimePokemonSummarySnapshot(
              targetId: 'pokemon.first',
              individualId: 'first',
              speciesLabel: 'Bulbizarre',
              nickname: '',
              level: 17,
              currentHp: 20,
              maxHp: 50,
              natureLabel: 'Modeste',
              abilityLabel: 'Engrais',
              friendship: 80,
            ),
            heldItemAction: RuntimePlayerHeldItemActionSnapshot(
              partyTargetId: 'pokemon.first',
              currentItemLabel: 'Baie Oran',
              options: [
                RuntimePlayerHeldItemOptionSnapshot(
                    itemTargetId: 'leftovers', label: 'Restes'),
              ],
            ),
          ),
        ],
      ),
      onCommand: onCommand ?? (_) {},
    );

final _bag = RuntimePlayerPauseDetailSnapshot(
  section: RuntimePlayerPauseSection.bag,
  title: 'Sac',
  entries: [
    RuntimePlayerDetailEntrySnapshot(
      id: 'bag.potion',
      title: 'Potion',
      bagItem: RuntimePlayerBagItemSnapshot(
          itemId: 'potion', quantity: 2, sortOrder: 0, pocketId: 'medicine'),
      bagAction: RuntimePlayerBagItemActionSnapshot(
          itemTargetId: 'potion',
          targetKind: RuntimePlayerBagUseTargetKind.partyMember,
          usability: ItemUsabilityState.usable,
          isEnabled: true),
    ),
  ],
  bagPockets: [RuntimePlayerBagPocketSnapshot(id: 'medicine', label: 'Soins')],
  bagTargets: [
    RuntimePlayerBagPartyTargetSnapshot(
        targetId: 'pokemon.first', label: 'Bulbizarre', subtitle: 'PV 20/50'),
  ],
);
