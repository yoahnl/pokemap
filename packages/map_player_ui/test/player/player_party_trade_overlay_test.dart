import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  RuntimeWorldServiceSnapshot snapshot(
    RuntimePartyTradePhase phase, {
    bool applying = false,
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
      members: const [
        RuntimePartyTradePokemonSnapshot(
          individualId: 'a',
          speciesId: 'machoke',
          label: 'Machoke',
          level: 28,
        ),
        RuntimePartyTradePokemonSnapshot(
          individualId: 'b',
          speciesId: 'onix',
          label: 'Onix',
          level: 25,
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
    List<RuntimeWorldServiceCommand> commands,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: PokeMapPlayerTheme.dark(),
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
    await tester.pump();
    await tester.pump();
  }

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
