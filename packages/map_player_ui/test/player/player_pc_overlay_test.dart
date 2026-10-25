import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets(
    'PC empty slots have no summary or transfer and never invent targets',
    (tester) async {
      final commands = <RuntimeWorldServiceCommand>[];
      await tester.pumpWidget(
        _app(PlayerPcOverlay(snapshot: _snapshot(), onCommand: commands.add)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pc-slot-29')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('pc-summary-empty')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('pc-withdraw-empty')))
            .onPressed,
        isNull,
      );
      expect(commands, isEmpty);
      expect(find.text('Aucun Pokémon'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pc-party-toggle')));
      await tester.pumpAndSettle();
      tester
          .widget<RuntimePlayerActions>(find.byType(RuntimePlayerActions))
          .onBack();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('pc-slot-29')))
            .properties
            .selected,
        isTrue,
      );
      expect(commands, isEmpty);
      await tester.tap(find.byKey(const ValueKey('pc-slot-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pc-withdraw-box-slot-0')));
      expect(commands.single.targetId, 'box-slot-0');
      expect(commands.single.snapshotRevision, 7);
    },
  );
  testWidgets('PC shows thirty anchored slots without a scrolling surface', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in [
      const Size(390, 844),
      const Size(844, 390),
      const Size(960, 540),
      const Size(640, 480),
      const Size(432, 560),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _app(PlayerPcOverlay(snapshot: _snapshot(), onCommand: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scrollable), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
      final frame = tester.getRect(
        find.byKey(const ValueKey('player-menu-edge-to-edge')),
      );
      expect(frame, Offset.zero & size);
      for (var i = 0; i < 30; i++) {
        final cell = find.byKey(ValueKey('pc-slot-$i'));
        expect(cell, findsOneWidget, reason: '$size slot $i');
        expect(tester.getRect(cell).overlaps(Offset.zero & size), isTrue);
      }
      final summary = find.byKey(const ValueKey('pc-summary-box-slot-0'));
      final summaryBounds = tester.getRect(summary);
      final label = find.descendant(of: summary, matching: find.byType(Text));
      final labelBounds = tester.getRect(label);
      expect(labelBounds.bottom, lessThanOrEqualTo(summaryBounds.bottom));
      expect(labelBounds.top, greaterThanOrEqualTo(summaryBounds.top));
      expect(summary.hitTestable(), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('pc-slot-0'))).height,
        48,
      );
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });
  testWidgets('PC companion keeps thirty 48px targets with clear margins', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in [const Size(496, 432), const Size(768, 432)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _app(
          PlayerCompanionScope(
            child: PlayerPcOverlay(
              key: ValueKey(size),
              snapshot: _snapshot(),
              onCommand: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 30; i++) {
        final cell = find.byKey(ValueKey('pc-slot-$i'));
        final bounds = tester.getRect(cell);
        expect(bounds.width, greaterThanOrEqualTo(48), reason: '$size slot $i');
        expect(
          bounds.height,
          greaterThanOrEqualTo(48),
          reason: '$size slot $i',
        );
        expect(cell.hitTestable(), findsOneWidget, reason: '$size slot $i');
      }
      final first = tester.getRect(find.byKey(const ValueKey('pc-slot-0')));
      final second = tester.getRect(find.byKey(const ValueKey('pc-slot-1')));
      final nextRow = tester.getRect(find.byKey(const ValueKey('pc-slot-6')));
      final header = tester.getRect(find.byKey(const ValueKey('pc-close')));
      expect(second.left - first.right, greaterThanOrEqualTo(8));
      expect(nextRow.top - first.bottom, greaterThanOrEqualTo(8));
      expect(first.top - header.bottom, greaterThanOrEqualTo(12));
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('PC renders runtime boxes and emits opaque transfer targets', (
    tester,
  ) async {
    final commands = <RuntimeWorldServiceCommand>[];
    final snapshot = _snapshot();

    await tester.pumpWidget(
      _app(PlayerPcOverlay(snapshot: snapshot, onCommand: commands.add)),
    );

    expect(find.text('PC Pokémon'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pc-party-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Équipe'), findsOneWidget);
    expect(find.byKey(const ValueKey('pc-party-slot-0')), findsOneWidget);
    expect(find.text('Lead'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey<String>('pc-summary-party-slot-0')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Résumé de Lead'), findsOneWidget);
    expect(find.text('Nature : Hardy'), findsOneWidget);
    for (
      var page = 0;
      page < 10 && find.text('Talent : Steadfast').evaluate().isEmpty;
      page++
    ) {
      final next = find.byKey(const ValueKey('player-page-next'));
      expect(next, findsOneWidget);
      expect(tester.widget<IconButton>(next).onPressed, isNotNull);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(find.text('Talent : Steadfast'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('pc-summary-close')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('pc-deposit-party-slot-0')),
    );
    await tester.tap(find.byKey(const ValueKey('pc-party-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('pc-withdraw-box-slot-0')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('pc-swap-box-slot-0')));
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

  testWidgets('PC remains usable in mobile portrait and landscape', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;

    for (final size in <Size>[const Size(390, 844), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _app(
          PlayerPcOverlay(
            key: ValueKey(size),
            snapshot: _snapshot(),
            onCommand: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size');
      expect(find.byKey(const ValueKey<String>('pc-close')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pc-party-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('pc-summary-party-slot-0')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'summary at $size');
      await tester.tap(find.byKey(const ValueKey<String>('pc-summary-close')));
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
        home: PlayerPcOverlay(snapshot: _snapshot(), onCommand: (_) {}),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('pc-party-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Party'), findsOneWidget);
    expect(find.text('Deposit'), findsOneWidget);
    expect(find.text('Box A'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pc-footer-close')).hitTestable(),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('pc-summary-party-slot-0')),
    );
    await tester.pumpAndSettle();

    final expected = <String>{
      'Lead summary',
      'Ability : Steadfast',
      'Held item : None',
      'Nickname : Flamme',
      'Friendship : 92 / 255',
      'Origin : Gift',
      'Met location : Town',
      'Source : Professor',
      'Met level : 5',
    };
    for (var page = 0; page < 10 && expected.isNotEmpty; page++) {
      expected.removeWhere((label) => find.text(label).evaluate().isNotEmpty);
      final next = find.byKey(const ValueKey('player-page-next'));
      if (next.evaluate().isEmpty ||
          tester.widget<IconButton>(next).onPressed == null) {
        break;
      }
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(expected, isEmpty);
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
