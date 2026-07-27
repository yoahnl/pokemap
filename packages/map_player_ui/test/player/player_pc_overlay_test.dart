import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('PC renders runtime boxes and emits opaque transfer targets',
      (tester) async {
    final commands = <RuntimeWorldServiceCommand>[];
    final snapshot = _snapshot();

    await tester.pumpWidget(
      _app(
        PlayerPcOverlay(
          snapshot: snapshot,
          onCommand: commands.add,
        ),
      ),
    );

    expect(find.text('PC Pokémon'), findsOneWidget);
    expect(find.text('Équipe'), findsOneWidget);
    expect(find.text('Box A · 1/30'), findsOneWidget);
    expect(find.text('Lead'), findsOneWidget);
    expect(find.text('Stored'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('pc-summary-party-slot-0')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Résumé de Lead'), findsOneWidget);
    expect(find.text('Nature : Hardy'), findsOneWidget);
    expect(find.text('Talent : Steadfast'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('pc-summary-close')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('pc-deposit-party-slot-0')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('pc-withdraw-box-slot-0')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('pc-swap-box-slot-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('pc-swap-with-party-slot-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('pc-close')));

    expect(
      commands.map((command) => command.action),
      <RuntimeWorldServiceAction>[
        RuntimeWorldServiceAction.deposit,
        RuntimeWorldServiceAction.withdraw,
        RuntimeWorldServiceAction.swap,
        RuntimeWorldServiceAction.close,
      ],
    );
    expect(commands[0].targetId, 'party-slot-0');
    expect(commands[1].targetId, 'box-slot-0');
    expect(commands[2].targetId, 'box-slot-0');
    expect(commands[2].secondaryTargetId, 'party-slot-0');
    expect(commands.every((command) => command.snapshotRevision == 7), isTrue);
  });

  testWidgets('PC remains usable in mobile portrait and landscape',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;

    for (final size in <Size>[
      const Size(390, 844),
      const Size(844, 390),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _app(
          PlayerPcOverlay(
            snapshot: _snapshot(),
            onCommand: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$size');
      expect(find.byKey(const ValueKey<String>('pc-close')), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('pc-summary-party-slot-0')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('pc-summary-party-slot-0')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'summary at $size');
      await tester.tap(
        find.byKey(const ValueKey<String>('pc-summary-close')),
      );
      await tester.pumpAndSettle();
    }
  });

  testWidgets('PC summary localizes its new labels in English', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: PokeMapPlayerTheme.dark(),
        home: PlayerPcOverlay(
          snapshot: _snapshot(),
          onCommand: (_) {},
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('pc-summary-party-slot-0')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lead summary'), findsOneWidget);
    expect(find.text('Ability : Steadfast'), findsOneWidget);
    expect(find.text('Held item : None'), findsOneWidget);
    expect(find.text('Nickname : Flamme'), findsOneWidget);
    expect(find.text('Friendship : 92 / 255'), findsOneWidget);
    expect(find.text('Origin : Gift'), findsOneWidget);
    expect(find.text('Met location : Town'), findsOneWidget);
    expect(find.text('Source : Professor'), findsOneWidget);
    expect(find.text('Met level : 5'), findsOneWidget);
  });
}

RuntimeWorldServiceSnapshot _snapshot() => RuntimeWorldServiceSnapshot(
      revision: 7,
      request: const OpenPcService(
        interactionId: 'terminal.harbor',
        storageId: 'box-a',
      ),
      stage: RuntimeWorldServiceStage.active,
      content: RuntimePcServiceContent(
        title: 'PC Pokémon',
        message: 'Organisez votre équipe.',
        selectedBoxId: 'box-a',
        boxes: const <RuntimePcBoxSnapshot>[
          RuntimePcBoxSnapshot(
            boxId: 'box-a',
            label: 'Box A',
            count: 1,
            capacity: 30,
          ),
        ],
        party: <RuntimePcPokemonSnapshot>[
          RuntimePcPokemonSnapshot(
            targetId: 'party-slot-0',
            label: 'Lead',
            speciesId: 'lead',
            level: 5,
            natureId: 'hardy',
            abilityId: 'steadfast',
            currentHp: 12,
            nickname: 'Flamme',
            friendship: 92,
            originKind: 'gift',
            metMapId: 'town',
            metSourceId: 'professor',
            metLevel: 5,
            canTransfer: true,
          ),
        ],
        stored: <RuntimePcPokemonSnapshot>[
          RuntimePcPokemonSnapshot(
            targetId: 'box-slot-0',
            label: 'Stored',
            speciesId: 'stored',
            level: 5,
            natureId: 'bold',
            abilityId: 'torrent',
            currentHp: 10,
            canTransfer: true,
          ),
        ],
      ),
      actions: const <RuntimeWorldServiceActionAvailability>[
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.select,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.deposit,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.withdraw,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.swap,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
      ],
    );

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: child,
    );
