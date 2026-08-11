import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final section in <RuntimePlayerPauseSection>[
    RuntimePlayerPauseSection.party,
    RuntimePlayerPauseSection.bag,
    RuntimePlayerPauseSection.pokedex,
    RuntimePlayerPauseSection.map,
  ]) {
    testWidgets('${section.name} renders runtime-provided detail data',
        (tester) async {
      final snapshot = _detailSnapshot(
        section,
        detail: RuntimePlayerPauseDetailSnapshot(
          section: section,
          title: 'Titre ${section.name}',
          entries: <RuntimePlayerDetailEntrySnapshot>[
            RuntimePlayerDetailEntrySnapshot(
              id: '${section.name}-entry',
              title: 'Contenu ${section.name}',
              subtitle: 'Donnée runtime',
              trailingLabel: '1 / 1',
              progress: 1,
            ),
          ],
        ),
      );

      await tester.pumpWidget(_app(
        RuntimePlayerDetailRouter(snapshot: snapshot),
      ));

      expect(
        find.byKey(
          ValueKey<String>('runtime-player-detail-${section.name}'),
        ),
        findsOneWidget,
      );
      expect(find.text('Contenu ${section.name}'), findsOneWidget);
      expect(find.text('Donnée runtime'), findsOneWidget);
    });
  }

  testWidgets('options expose a persisted touch-control opacity slider',
      (tester) async {
    PlayerPreferencesSnapshot? changed;
    final snapshot = RuntimePlayerSnapshot(
      revision: 3,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.options,
      preferences: const PlayerPreferencesSnapshot(
        locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(),
        touchControlsOpacity: 0.82,
      ),
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.openOptions,
        ),
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.updatePreferences,
        ),
      ],
    );

    await tester.pumpWidget(_app(
      RuntimePlayerDetailRouter(
        snapshot: snapshot,
        onPreferencesChanged: (preferences) => changed = preferences,
      ),
    ));

    final slider = find.byKey(
      const ValueKey<String>('touch-controls-opacity-slider'),
    );
    expect(slider, findsOneWidget);
    await tester.drag(slider, const Offset(-120, 0));
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed!.touchControlsOpacity, lessThan(0.82));
  });

  testWidgets('bag selects a party target and keeps key items unavailable',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );
    RuntimePlayerPauseCommand? command;
    final detail = RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.bag,
      title: 'Sac',
      entries: <RuntimePlayerDetailEntrySnapshot>[
        RuntimePlayerDetailEntrySnapshot(
          id: 'bag.medicine.potion',
          title: 'Potion',
          trailingLabel: '×2',
          bagAction: RuntimePlayerBagItemActionSnapshot(
            itemTargetId: 'potion',
            targetKind: RuntimePlayerBagUseTargetKind.partyMember,
            usability: ItemUsabilityState.usable,
            isEnabled: true,
          ),
        ),
        RuntimePlayerDetailEntrySnapshot(
          id: 'bag.key-items.harbor-pass',
          title: 'Passe du port',
          trailingLabel: '×1',
          bagAction: RuntimePlayerBagItemActionSnapshot(
            itemTargetId: 'harbor-pass',
            targetKind: RuntimePlayerBagUseTargetKind.partyMember,
            usability: ItemUsabilityState.passive,
            isEnabled: false,
            unavailableReason:
                'Cet objet clé s’utilise automatiquement et n’est pas consommé.',
          ),
        ),
      ],
      bagTargets: <RuntimePlayerBagPartyTargetSnapshot>[
        RuntimePlayerBagPartyTargetSnapshot(
          targetId: 'party.0',
          label: 'Salamèche',
          subtitle: 'PV 12/39',
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerDetailRouter(
          snapshot: _detailSnapshot(
            RuntimePlayerPauseSection.bag,
            detail: detail,
          ),
          onPauseCommand: (value) => command = value,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.byKey(
        const ValueKey<String>('runtime-player-bag-use-potion'),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('runtime-player-bag-use-potion'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.byKey(
        const ValueKey<String>('runtime-player-bag-target-party.0'),
      ),
    );
    await tester.pumpAndSettle();

    expect(command?.itemTargetId, 'potion');
    expect(command?.partyTargetId, 'party.0');
    final keyItemButton = tester.widget<PlayerActionButton>(
      find.byKey(
        const ValueKey<String>('runtime-player-bag-use-harbor-pass'),
      ),
    );
    expect(keyItemButton.onPressed, isNull);
    expect(keyItemButton.disabledReason, contains('pas consommé'));
  });

  testWidgets('TM target picker teaches directly or chooses a move to forget',
      (tester) async {
    RuntimePlayerPauseCommand? command;
    final detail = RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.bag,
      title: 'Sac',
      entries: <RuntimePlayerDetailEntrySnapshot>[
        RuntimePlayerDetailEntrySnapshot(
          id: 'bag.machines.tm-protect',
          title: 'TM Protect',
          bagAction: RuntimePlayerBagItemActionSnapshot(
            itemTargetId: 'tm-protect',
            targetKind: RuntimePlayerBagUseTargetKind.partyMoveReplacement,
            usability: ItemUsabilityState.usable,
            isEnabled: true,
          ),
        ),
      ],
      bagTargets: <RuntimePlayerBagPartyTargetSnapshot>[
        RuntimePlayerBagPartyTargetSnapshot(
          targetId: 'party.0',
          label: 'Bulbizarre',
          moves: const <RuntimePlayerBagMoveTargetSnapshot>[
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'tackle',
              label: 'Charge',
            ),
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'growl',
              label: 'Rugissement',
            ),
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'vine-whip',
              label: 'Fouet Lianes',
            ),
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'sleep-powder',
              label: 'Poudre Dodo',
            ),
          ],
        ),
        RuntimePlayerBagPartyTargetSnapshot(
          targetId: 'party.1',
          label: 'Carapuce',
          moves: const <RuntimePlayerBagMoveTargetSnapshot>[
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'tackle',
              label: 'Charge',
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerDetailRouter(
          snapshot: _detailSnapshot(
            RuntimePlayerPauseSection.bag,
            detail: detail,
          ),
          onPauseCommand: (value) => command = value,
        ),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('runtime-player-bag-use-tm-protect'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Apprendre à Carapuce'), findsOneWidget);
    expect(
      find.text('Apprendre à Bulbizarre en oubliant Rugissement'),
      findsOneWidget,
    );
    await tester.tap(
      find.text('Apprendre à Bulbizarre en oubliant Rugissement'),
    );
    await tester.pumpAndSettle();

    expect(command?.itemTargetId, 'tm-protect');
    expect(command?.partyTargetId, 'party.0');
    expect(command?.moveTargetId, 'growl');
  });

  testWidgets('map identifies the current area and explains travel limits',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );
    final detail = RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.map,
      title: 'Carte',
      message:
          'Carte consultable uniquement : le voyage rapide sera ajouté plus tard.',
      entries: <RuntimePlayerDetailEntrySnapshot>[
        RuntimePlayerDetailEntrySnapshot(
          id: 'map.route',
          title: 'Route des Brumes',
          subtitle: 'Position actuelle',
          trailingLabel: 'Ici',
        ),
        RuntimePlayerDetailEntrySnapshot(
          id: 'map.cave',
          title: '???',
          subtitle: 'Zone non découverte',
          trailingLabel: 'Inconnue',
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: RuntimePlayerDetailRouter(
            snapshot: _detailSnapshot(
              RuntimePlayerPauseSection.map,
              detail: detail,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('runtime-player-map-message')),
      findsOneWidget,
    );
    expect(find.text('Position actuelle'), findsOneWidget);
    expect(find.text('Ici'), findsOneWidget);
    expect(find.text('???'), findsOneWidget);
  });

  testWidgets('missing or empty detail gives a guided empty state',
      (tester) async {
    final snapshot = _detailSnapshot(
      RuntimePlayerPauseSection.party,
      detail: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.party,
        title: 'Équipe',
        emptyMessage: 'Aucun Pokémon dans votre équipe.',
      ),
    );

    await tester.pumpWidget(_app(
      RuntimePlayerDetailRouter(snapshot: snapshot),
    ));

    expect(
      find.byKey(const ValueKey<String>('runtime-player-detail-empty')),
      findsOneWidget,
    );
    expect(find.text('Aucun Pokémon dans votre équipe.'), findsOneWidget);
  });

  testWidgets('disabled detail shows the runtime-provided reason',
      (tester) async {
    final snapshot = RuntimePlayerSnapshot(
      revision: 4,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.pokedex,
      actions: <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.disabled(
          RuntimePlayerAction.openPokedex,
          reason: 'Obtenez le Pokédex auprès du professeur.',
        ),
      ],
    );

    await tester.pumpWidget(_app(
      RuntimePlayerDetailRouter(snapshot: snapshot),
    ));

    expect(
      find.byKey(const ValueKey<String>('runtime-player-detail-unavailable')),
      findsOneWidget,
    );
    expect(
      find.text('Obtenez le Pokédex auprès du professeur.'),
      findsOneWidget,
    );
  });

  testWidgets('Save dispatches only the runtime save command', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );
    final actions = <RuntimePlayerAction>[];
    final snapshot = RuntimePlayerSnapshot(
      revision: 12,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.root,
      activeSaveAddress: const RuntimePlayerSaveAddress(
        gameId: 'com.example.aube',
        profileId: 'karim',
        slotId: 'slot-2',
      ),
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.resume),
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.save),
      ],
    );

    await tester.pumpWidget(_app(RuntimePlayerSurfaceRouter(
      snapshot: snapshot,
      titlePresentation: const RuntimePlayerTitlePresentation(
        author: 'Studio Test',
      ),
      gameSceneBuilder: (_) => const SizedBox.expand(),
      onAction: (action) async {
        actions.add(action);
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        );
      },
    )));

    await tester.tap(find.text('Sauvegarder'));
    await tester.pumpAndSettle();
    expect(actions, isEmpty);
    expect(
      find.text('Profil « karim », slot « slot-2 ».'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('runtime-save-confirm')),
    );
    await tester.pumpAndSettle();
    expect(actions, <RuntimePlayerAction>[RuntimePlayerAction.save]);
  });

  testWidgets('manual Save receipt names the persisted profile and slot',
      (tester) async {
    const address = RuntimePlayerSaveAddress(
      gameId: 'com.example.aube',
      profileId: 'karim',
      slotId: 'slot-2',
    );
    final snapshot = RuntimePlayerSnapshot(
      revision: 13,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.root,
      activeSaveAddress: address,
      saveReceipt: const RuntimePlayerSaveReceipt(
        address: address,
        trigger: GameSessionCheckpointTrigger.manual,
      ),
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.resume),
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.save),
      ],
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerSurfaceRouter(
          snapshot: snapshot,
          titlePresentation: const RuntimePlayerTitlePresentation(
            author: 'Studio Test',
          ),
          gameSceneBuilder: (_) => const SizedBox.expand(),
          onAction: (_) async => const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.accepted,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('runtime-save-receipt')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Partie sauvegardée — profil « karim », slot « slot-2 ».',
      ),
      findsOneWidget,
    );
  });
}

RuntimePlayerSnapshot _detailSnapshot(
  RuntimePlayerPauseSection section, {
  required RuntimePlayerPauseDetailSnapshot detail,
}) {
  return RuntimePlayerSnapshot(
    revision: 2,
    phase: RuntimePlayerPhase.paused,
    gameTitle: 'Aube',
    pauseSection: section,
    pauseDetails: <RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>{
      section: detail,
    },
    actions: <RuntimePlayerActionAvailability>[
      RuntimePlayerActionAvailability.enabled(_actionFor(section)),
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.returnToPauseRoot,
      ),
    ],
  );
}

RuntimePlayerAction _actionFor(RuntimePlayerPauseSection section) =>
    switch (section) {
      RuntimePlayerPauseSection.party => RuntimePlayerAction.openParty,
      RuntimePlayerPauseSection.bag => RuntimePlayerAction.openBag,
      RuntimePlayerPauseSection.pokedex => RuntimePlayerAction.openPokedex,
      RuntimePlayerPauseSection.map => RuntimePlayerAction.openMap,
      RuntimePlayerPauseSection.options => RuntimePlayerAction.openOptions,
      RuntimePlayerPauseSection.root => throw ArgumentError('root'),
    };

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: child,
    );
