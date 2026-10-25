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

  for (final size in [
    const Size(844, 390),
    const Size(390, 844),
    const Size(768, 432),
    const Size(496, 432),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('six healing members fit without pages $size dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            PlayerHealConfirmation(snapshot: _sixMembers(), onCommand: (_) {}),
            theme: dark
                ? PokeMapPlayerTheme.dark()
                : PokeMapPlayerTheme.light(),
          ),
        );
        await tester.pumpAndSettle();
        for (var i = 0; i < 6; i++) {
          expect(
            find.byKey(ValueKey('heal-member-$i')).hitTestable(),
            findsOneWidget,
          );
        }
        expect(find.byKey(const ValueKey('player-page-next')), findsNothing);
        expect(find.byType(Scrollable), findsNothing);
        expect(find.text('Soigner'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final size in [
    const Size(844, 390),
    const Size(390, 844),
    const Size(768, 432),
    const Size(496, 432),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'completed receipt retains six restored members $size dark=$dark',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final commands = <RuntimeWorldServiceCommand>[];
          await tester.pumpWidget(
            _app(
              PlayerHealConfirmation(
                snapshot: _sixMembers(completed: true),
                onCommand: commands.add,
              ),
              theme: dark
                  ? PokeMapPlayerTheme.dark()
                  : PokeMapPlayerTheme.light(),
            ),
          );
          await tester.pumpAndSettle();
          for (var i = 0; i < 6; i++) {
            expect(
              find.byKey(ValueKey('heal-member-$i')).hitTestable(),
              findsOneWidget,
            );
          }
          expect(find.text('PV 48 / 48'), findsNWidgets(6));
          expect(find.byKey(const ValueKey('player-page-next')), findsNothing);
          expect(find.byKey(const ValueKey('heal-confirm')), findsNothing);
          expect(find.byKey(const ValueKey('heal-cancel')), findsNothing);
          await tester.tap(find.byKey(const ValueKey('heal-close')));
          expect(commands.single.action, RuntimeWorldServiceAction.close);
          expect(commands.single.snapshotRevision, 20);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('healing retry stacks complete controls with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        PlayerHealConfirmation(
          snapshot: _sixMembers(failed: true),
          onCommand: (_) {},
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();
    final retry = find.byKey(const ValueKey('heal-confirm'));
    final cancel = find.byKey(const ValueKey('heal-cancel'));
    expect(
      tester.getRect(cancel).top,
      greaterThanOrEqualTo(tester.getRect(retry).bottom + 8),
    );
    for (final action in [retry, cancel]) {
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
  testWidgets(
    'unavailable healing uses the Ligue surface and current close command',
    (tester) async {
      final commands = <RuntimeWorldServiceCommand>[];
      await tester.pumpWidget(
        _app(
          PlayerHealConfirmation(
            snapshot: RuntimeWorldServiceSnapshot(
              revision: 19,
              request: const OpenHealService(interactionId: 'unavailable'),
              stage: RuntimeWorldServiceStage.failed,
              actions: const [
                RuntimeWorldServiceActionAvailability.enabled(
                  RuntimeWorldServiceAction.close,
                ),
              ],
            ),
            onCommand: commands.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PlayerPanel), findsNothing);
      expect(find.byType(PlayerMenuPanel), findsOneWidget);
      await tester.tap(find.byType(PlayerActionButton));
      expect(commands.single.action, RuntimeWorldServiceAction.close);
      expect(commands.single.snapshotRevision, 19);
    },
  );

  testWidgets('heal confirmation renders runtime party data and commands', (
    tester,
  ) async {
    final commands = <RuntimeWorldServiceCommand>[];
    final snapshot = RuntimeWorldServiceSnapshot(
      revision: 6,
      request: const OpenHealService(interactionId: 'npc.nurse'),
      stage: RuntimeWorldServiceStage.active,
      content: RuntimeHealServiceContent(
        title: 'Centre Pokémon',
        message: 'Voulez-vous soigner votre équipe ?',
        members: const <RuntimeHealPartyMemberSnapshot>[
          RuntimeHealPartyMemberSnapshot(
            partyIndex: 0,
            label: 'Sproutle',
            currentHp: 3,
            maxHp: 24,
            hasStatus: true,
            depletedMoveCount: 1,
          ),
        ],
      ),
      actions: const <RuntimeWorldServiceActionAvailability>[
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.confirm,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.cancel,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(PlayerHealConfirmation(snapshot: snapshot, onCommand: commands.add)),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(PlayerHealConfirmation),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );

    expect(find.text('Centre Pokémon'), findsOneWidget);
    expect(find.text('Sproutle'), findsOneWidget);
    expect(find.byType(PlayerPanel), findsNothing);
    expect(find.byKey(const ValueKey('heal-member-0')), findsOneWidget);
    expect(find.byType(PlayerMenuGauge), findsOneWidget);
    expect(find.text('PV 3 / 24'), findsOneWidget);
    expect(find.textContaining('Statut'), findsOneWidget);
    expect(find.textContaining('PP'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('heal-confirm')));
    expect(commands.single.action, RuntimeWorldServiceAction.confirm);
    expect(commands.single.snapshotRevision, 6);
  });

  testWidgets('completed heal shows result and closes with current revision', (
    tester,
  ) async {
    final commands = <RuntimeWorldServiceCommand>[];
    final snapshot = RuntimeWorldServiceSnapshot(
      revision: 9,
      request: const OpenHealService(interactionId: 'npc.nurse'),
      stage: RuntimeWorldServiceStage.completed,
      content: RuntimeHealServiceContent(
        title: 'Centre Pokémon',
        message: 'Votre équipe est entièrement soignée.',
        members: const <RuntimeHealPartyMemberSnapshot>[],
        wasHealed: true,
      ),
      safeMessage: 'Votre équipe est entièrement soignée.',
      actions: const <RuntimeWorldServiceActionAvailability>[
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(PlayerHealConfirmation(snapshot: snapshot, onCommand: commands.add)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Votre équipe est entièrement soignée.'), findsWidgets);
    expect(
      tester.getSize(find.byKey(const ValueKey('heal-service-panel'))).height,
      lessThan(300),
    );
    expect(find.byKey(const ValueKey<String>('heal-confirm')), findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('heal-close')));
    expect(commands.single.action, RuntimeWorldServiceAction.close);
    expect(commands.single.snapshotRevision, 9);
  });

  testWidgets('healing controls and member state localize in English', (
    tester,
  ) async {
    final snapshot = RuntimeWorldServiceSnapshot(
      revision: 10,
      request: const OpenHealService(interactionId: 'npc.nurse'),
      stage: RuntimeWorldServiceStage.active,
      content: RuntimeHealServiceContent(
        title: 'Pokémon Center',
        message: 'Heal the party?',
        members: const <RuntimeHealPartyMemberSnapshot>[
          RuntimeHealPartyMemberSnapshot(
            partyIndex: 0,
            label: 'Sproutle',
            currentHp: 3,
            maxHp: 24,
            hasStatus: true,
            depletedMoveCount: 1,
          ),
        ],
      ),
      actions: const <RuntimeWorldServiceActionAvailability>[
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.confirm,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.cancel,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        PlayerHealConfirmation(snapshot: snapshot, onCommand: (_) {}),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HP 3 / 24'), findsOneWidget);
    expect(find.text('Status needs healing'), findsOneWidget);
    expect(find.text('PP to restore: 1'), findsOneWidget);
    expect(find.text('Heal'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}

RuntimeWorldServiceSnapshot _sixMembers({
  bool failed = false,
  bool completed = false,
}) => RuntimeWorldServiceSnapshot(
  revision: 20,
  request: const OpenHealService(interactionId: 'six-members'),
  stage: completed
      ? RuntimeWorldServiceStage.completed
      : failed
      ? RuntimeWorldServiceStage.failed
      : RuntimeWorldServiceStage.active,
  content: RuntimeHealServiceContent(
    title: 'Soigner votre équipe ?',
    message: 'Nous pouvons restaurer les PV et les PP de vos compagnons.',
    members: [
      for (var i = 0; i < 6; i++)
        RuntimeHealPartyMemberSnapshot(
          partyIndex: i,
          label: 'Compagnon ${i + 1}',
          currentHp: completed ? 48 : 32,
          maxHp: 48,
          hasStatus: !completed && i == 1,
          depletedMoveCount: completed ? 0 : 1,
        ),
    ],
  ),
  actions: [
    if (completed)
      const RuntimeWorldServiceActionAvailability.enabled(
        RuntimeWorldServiceAction.close,
      )
    else ...[
      const RuntimeWorldServiceActionAvailability.enabled(
        RuntimeWorldServiceAction.confirm,
      ),
      const RuntimeWorldServiceActionAvailability.enabled(
        RuntimeWorldServiceAction.cancel,
      ),
    ],
  ],
);

Widget _app(
  Widget child, {
  Locale locale = const Locale('fr'),
  ThemeData? theme,
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  locale: locale,
  supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
  localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
  theme: theme ?? PokeMapPlayerTheme.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
    child: child!,
  ),
  home: child,
);
