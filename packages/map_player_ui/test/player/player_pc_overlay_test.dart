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
      find.byKey(const ValueKey<String>('pc-deposit-party-slot-0')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('pc-withdraw-box-slot-0')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('pc-close')));

    expect(
      commands.map((command) => command.action),
      <RuntimeWorldServiceAction>[
        RuntimeWorldServiceAction.deposit,
        RuntimeWorldServiceAction.withdraw,
        RuntimeWorldServiceAction.close,
      ],
    );
    expect(commands[0].targetId, 'party-slot-0');
    expect(commands[1].targetId, 'box-slot-0');
    expect(commands.every((command) => command.snapshotRevision == 7), isTrue);
  });

  testWidgets('PC remains usable in mobile portrait and landscape',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

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
    }
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
        party: const <RuntimePcPokemonSnapshot>[
          RuntimePcPokemonSnapshot(
            targetId: 'party-slot-0',
            label: 'Lead',
            level: 5,
            canTransfer: true,
          ),
        ],
        stored: const <RuntimePcPokemonSnapshot>[
          RuntimePcPokemonSnapshot(
            targetId: 'box-slot-0',
            label: 'Stored',
            level: 5,
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
