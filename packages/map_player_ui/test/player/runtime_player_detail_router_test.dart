import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final section in <RuntimePlayerPauseSection>[
    RuntimePlayerPauseSection.party,
    RuntimePlayerPauseSection.bag,
    RuntimePlayerPauseSection.pokedex,
    RuntimePlayerPauseSection.map,
    RuntimePlayerPauseSection.options,
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
    addTearDown(tester.view.reset);
    final actions = <RuntimePlayerAction>[];
    final snapshot = RuntimePlayerSnapshot(
      revision: 12,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.root,
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
    expect(actions, <RuntimePlayerAction>[RuntimePlayerAction.save]);
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
