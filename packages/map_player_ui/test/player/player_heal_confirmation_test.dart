import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
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
    await tester.pump();
    await tester.pump();

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
    await tester.pump();
    await tester.pump();

    expect(find.text('Votre équipe est entièrement soignée.'), findsWidgets);
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
    await tester.pump();
    await tester.pump();

    expect(find.text('HP 3 / 24'), findsOneWidget);
    expect(find.text('Status needs healing'), findsOneWidget);
    expect(find.text('PP to restore: 1'), findsOneWidget);
    expect(find.text('Heal party'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}

Widget _app(Widget child, {Locale locale = const Locale('fr')}) => MaterialApp(
  locale: locale,
  supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
  localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
  theme: PokeMapPlayerTheme.dark(),
  home: child,
);
