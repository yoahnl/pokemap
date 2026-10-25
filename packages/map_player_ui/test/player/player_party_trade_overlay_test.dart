import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'packages/map_player_ui/PokeMapSplashDMSans',
    )..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'))).load();
  });
  RuntimeWorldServiceSnapshot snapshot(
    RuntimePartyTradePhase phase, {
    bool applying = false,
    bool fullParty = false,
  }) => RuntimeWorldServiceSnapshot(
    revision: 12,
    request: const OpenPartyTradeService(interactionId: 'center.trade'),
    stage: applying
        ? RuntimeWorldServiceStage.applying
        : phase == RuntimePartyTradePhase.completed
        ? RuntimeWorldServiceStage.completed
        : RuntimeWorldServiceStage.active,
    content: RuntimePartyTradeServiceContent(
      phase: phase,
      firstIndividualId: 'a',
      partnerIndividualId: 'b',
      completionMessage: phase == RuntimePartyTradePhase.completed
          ? 'Machoke est devenu Machamp.'
          : null,
      members: [
        const RuntimePartyTradePokemonSnapshot(
          individualId: 'a',
          speciesId: 'machoke',
          label: 'Machoke',
          level: 28,
        ),
        const RuntimePartyTradePokemonSnapshot(
          individualId: 'b',
          speciesId: 'onix',
          label: 'Onix',
          level: 25,
        ),
        if (fullParty)
          for (var index = 2; index < 6; index++)
            RuntimePartyTradePokemonSnapshot(
              individualId: 'member$index',
              speciesId: 'species$index',
              label: 'Compagnon $index',
              level: 16,
            ),
      ],
    ),
    actions: [
      if (!applying) ...[
        if (phase != RuntimePartyTradePhase.completed) ...[
          RuntimeWorldServiceActionAvailability.enabled(
            phase == RuntimePartyTradePhase.review
                ? RuntimeWorldServiceAction.confirm
                : RuntimeWorldServiceAction.select,
          ),
          const RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.cancel,
          ),
        ],
        const RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
      ],
    ],
  );
  Future<void> pump(
    WidgetTester tester,
    RuntimeWorldServiceSnapshot data,
    List<RuntimeWorldServiceCommand> commands, {
    TextScaler textScaler = TextScaler.noScaling,
    EdgeInsets padding = EdgeInsets.zero,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: PokeMapPlayerTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: textScaler, padding: padding),
          child: child!,
        ),
        home: PlayerPartyTradeOverlay(
          snapshot: data,
          onCommand: commands.add,
          controlProfile: PlayerControlProfile.standard
              .rebind(
                device: PlayerControlDevice.keyboard,
                control: RuntimeInputControl.secondary,
                inputId: 'keyQ',
              )
              .profile,
        ),
      ),
    );
    if (data.stage == RuntimeWorldServiceStage.applying) {
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    } else if (settle) {
      await tester.pumpAndSettle();
    }
  }

  for (final size in [
    const Size(844, 390),
    const Size(390, 844),
    const Size(768, 432),
    const Size(496, 432),
  ]) {
    testWidgets(
      'six trade choices fit without pages with real safe insets at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final commands = <RuntimeWorldServiceCommand>[];
        final data = snapshot(
          RuntimePartyTradePhase.selectFirst,
          fullParty: true,
        );
        await pump(
          tester,
          data,
          commands,
          padding: size == const Size(844, 390)
              ? const EdgeInsets.fromLTRB(44, 12, 44, 20)
              : size == const Size(390, 844)
              ? const EdgeInsets.only(top: 32, bottom: 24)
              : EdgeInsets.zero,
        );
        await tester.pumpAndSettle();
        for (final member
            in (data.content as RuntimePartyTradeServiceContent).members) {
          final button = find.byKey(
            ValueKey('party-trade-pokemon-${member.individualId}'),
          );
          expect(button.hitTestable(), findsOneWidget);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        }
        expect(find.byKey(const ValueKey('player-page-next')), findsNothing);
        await tester.tap(
          find.byKey(const ValueKey('party-trade-pokemon-member4')),
        );
        expect(commands.single.targetId, 'member4');
        expect(commands.single.snapshotRevision, data.revision);
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('trade review sizes its panel to both identities at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester, snapshot(RuntimePartyTradePhase.review), []);
      await tester.pumpAndSettle();
      expect(find.text('Pokémon : Machoke').hitTestable(), findsOneWidget);
      expect(find.text('Partenaire : Onix').hitTestable(), findsOneWidget);
      expect(find.byKey(const ValueKey('player-page-next')), findsNothing);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('party-trade-service-panel')))
            .height,
        lessThan(size.height - 40),
      );
      expect(find.text('Confirmer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'landscape trade review natural panel height settles without resizing its pager width',
    (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final commands = <RuntimeWorldServiceCommand>[];
      await pump(
        tester,
        snapshot(RuntimePartyTradePhase.review),
        commands,
        padding: const EdgeInsets.fromLTRB(44, 12, 44, 20),
        settle: false,
      );
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(tester.binding.hasScheduledFrame, isFalse);
      final panel = find.byKey(const ValueKey('party-trade-service-panel'));
      final bounds = tester.getRect(panel);
      expect(bounds.height, lessThan(350));
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.getRect(panel), bounds);
        expect(tester.binding.hasScheduledFrame, isFalse);
      }
      expect(find.text('Pokémon : Machoke').hitTestable(), findsOneWidget);
      expect(find.text('Partenaire : Onix').hitTestable(), findsOneWidget);
      expect(find.byKey(const ValueKey('player-page-next')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('party-trade-confirm')));
      expect(commands.single.action, RuntimeWorldServiceAction.confirm);
      expect(commands.single.snapshotRevision, 12);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('trade review keeps complete controls at text scale two', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(
      tester,
      snapshot(RuntimePartyTradePhase.review),
      [],
      textScaler: const TextScaler.linear(2),
    );
    await tester.pumpAndSettle();
    for (final key in ['party-trade-confirm', 'party-trade-cancel']) {
      final action = find.byKey(ValueKey(key));
      expect(action.hitTestable(), findsOneWidget);
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      final label = find.descendant(of: action, matching: find.byType(Text));
      expect(
        tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
        isFalse,
      );
    }
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(1000, 700), const Size(360, 640)]) {
    testWidgets(
      'party picker selects the individual and honors remapped Back at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final commands = <RuntimeWorldServiceCommand>[];
        await pump(
          tester,
          snapshot(RuntimePartyTradePhase.selectFirst),
          commands,
        );
        expect(find.byType(Scrollable), findsNothing);
        expect(find.text('Machoke · Niv. 28'), findsOneWidget);
        expect(find.text('Onix · Niv. 25'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('party-trade-pokemon-a')));
        expect(commands.single.action, RuntimeWorldServiceAction.select);
        expect(commands.single.targetId, 'a');
        expect(commands.single.snapshotRevision, 12);
        commands.clear();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        expect(commands, isEmpty);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
        expect(commands.single.action, RuntimeWorldServiceAction.cancel);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('partner choices expose both genuine source branches', (
    tester,
  ) async {
    final commands = <RuntimeWorldServiceCommand>[];
    await pump(
      tester,
      snapshot(RuntimePartyTradePhase.choosePartner),
      commands,
    );
    await tester.tap(find.byKey(const ValueKey('party-trade-same-partner')));
    expect(
      commands.single.targetId,
      RuntimePartyTradeServiceContent.samePartnerTarget,
    );
    commands.clear();
    await tester.tap(find.byKey(const ValueKey('party-trade-other-partner')));
    expect(
      commands.single.targetId,
      RuntimePartyTradeServiceContent.otherPartnerTarget,
    );
  });
  testWidgets(
    'review shows both identities and confirms only with an explicit action',
    (tester) async {
      final commands = <RuntimeWorldServiceCommand>[];
      await pump(tester, snapshot(RuntimePartyTradePhase.review), commands);
      expect(find.text('Pokémon : Machoke'), findsOneWidget);
      expect(find.text('Partenaire : Onix'), findsOneWidget);
      final pair = find.byKey(const ValueKey('party-trade-pair'));
      expect(pair, findsOneWidget);
      expect(
        find.descendant(of: pair, matching: find.byType(PlayerMenuPanel)),
        findsNWidgets(2),
      );
      expect(find.text('Niv. 28'), findsOneWidget);
      expect(find.text('Niv. 25'), findsOneWidget);
      expect(find.byType(PlayerPanel), findsNothing);
      expect(commands, isEmpty);
      await tester.tap(find.byKey(const ValueKey('party-trade-confirm')));
      expect(commands.single.action, RuntimeWorldServiceAction.confirm);
      expect(commands.single.targetId, isNull);
    },
  );
  testWidgets('applying cannot send cancel confirm or repeated selection', (
    tester,
  ) async {
    final commands = <RuntimeWorldServiceCommand>[];
    await pump(
      tester,
      snapshot(RuntimePartyTradePhase.review, applying: true),
      commands,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byKey(const ValueKey('party-trade-confirm')), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    expect(commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'completion waits for Close and displays the native evolution result',
    (tester) async {
      final commands = <RuntimeWorldServiceCommand>[];
      await pump(tester, snapshot(RuntimePartyTradePhase.completed), commands);
      expect(find.text('Machoke est devenu Machamp.'), findsOneWidget);
      expect(find.byKey(const ValueKey('party-trade-confirm')), findsNothing);
      expect(commands, isEmpty);
      await tester.tap(find.byKey(const ValueKey('party-trade-close')));
      expect(commands.single.action, RuntimeWorldServiceAction.close);
    },
  );
}
