import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('heal confirmation renders runtime party data and commands',
      (tester) async {
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
      _app(
        PlayerHealConfirmation(
          snapshot: snapshot,
          onCommand: commands.add,
        ),
      ),
    );

    expect(find.text('Centre Pokémon'), findsOneWidget);
    expect(find.text('Sproutle'), findsOneWidget);
    expect(find.text('PV 3 / 24'), findsOneWidget);
    expect(find.textContaining('Statut'), findsOneWidget);
    expect(find.textContaining('PP'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('heal-confirm')));
    expect(commands.single.action, RuntimeWorldServiceAction.confirm);
    expect(commands.single.snapshotRevision, 6);
  });

  testWidgets('completed heal shows result and closes with current revision',
      (tester) async {
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
      _app(
        PlayerHealConfirmation(
          snapshot: snapshot,
          onCommand: commands.add,
        ),
      ),
    );

    expect(find.text('Votre équipe est entièrement soignée.'), findsWidgets);
    expect(find.byKey(const ValueKey<String>('heal-confirm')), findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('heal-close')));
    expect(commands.single.action, RuntimeWorldServiceAction.close);
    expect(commands.single.snapshotRevision, 9);
  });
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: child,
    );
