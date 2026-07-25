import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('routes one canonical surface for every player phase',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 1,
      phase: RuntimePlayerPhase.title,
      actions: <RuntimePlayerActionAvailability>[
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.continueGame,
        ),
      ],
    ));
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller)));
    expect(_surfaceFinder(RuntimePlayerPhase.title), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('test-game-scene')), findsNothing);

    for (final phase in <RuntimePlayerPhase>[
      RuntimePlayerPhase.preparingSession,
      RuntimePlayerPhase.loadingSession,
      RuntimePlayerPhase.playing,
      RuntimePlayerPhase.paused,
      RuntimePlayerPhase.saving,
      RuntimePlayerPhase.lifecyclePaused,
      RuntimePlayerPhase.completing,
      RuntimePlayerPhase.result,
      RuntimePlayerPhase.credits,
      RuntimePlayerPhase.disposingSession,
      RuntimePlayerPhase.externalExit,
      RuntimePlayerPhase.error,
    ]) {
      controller.publish(_snapshot(revision: 2 + phase.index, phase: phase));
      await tester.pump();

      expect(
        _surfaceFinder(phase),
        findsOneWidget,
        reason: 'The ${phase.name} phase must have one canonical surface.',
      );
      expect(_allCanonicalSurfaces(), findsOneWidget);
    }
  });

  testWidgets('dispatches title actions with the current snapshot revision',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 7,
      phase: RuntimePlayerPhase.title,
      actions: <RuntimePlayerActionAvailability>[
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.continueGame,
        ),
        RuntimePlayerActionAvailability.disabled(
          RuntimePlayerAction.newGame,
          reason: 'Profil requis',
        ),
      ],
    ));
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller)));
    await tester.tap(find.text('Continuer'));

    expect(controller.commands, hasLength(1));
    expect(controller.commands.single.action, RuntimePlayerAction.continueGame);
    expect(controller.commands.single.snapshotRevision, 7);

    final newGameButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Nouvelle partie'),
    );
    expect(newGameButton.onPressed, isNull);
    expect(controller.commands, hasLength(1));
  });

  testWidgets('shows runtime loading progress and dispatches cancellation',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 11,
      phase: RuntimePlayerPhase.loadingSession,
      loadingProgress: const GameSessionLoadingProgress(
        stage: 'catalogues',
        current: 2,
        total: 4,
      ),
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.cancel),
      ],
    ));
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller)));

    expect(find.text('catalogues'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .value,
      .5,
    );

    await tester.tap(find.text('Annuler'));
    expect(controller.commands.single.action, RuntimePlayerAction.cancel);
    expect(controller.commands.single.snapshotRevision, 11);
  });

  testWidgets('keeps the game scene mounted only across live session phases',
      (tester) async {
    final lifecycle = _SceneLifecycle();
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(revision: 1, phase: RuntimePlayerPhase.loadingSession),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller, lifecycle: lifecycle)));
    expect(lifecycle.mounts, 1);
    expect(lifecycle.disposals, 0);

    for (final phase in <RuntimePlayerPhase>[
      RuntimePlayerPhase.playing,
      RuntimePlayerPhase.paused,
      RuntimePlayerPhase.saving,
      RuntimePlayerPhase.lifecyclePaused,
      RuntimePlayerPhase.completing,
      RuntimePlayerPhase.disposingSession,
    ]) {
      controller.publish(_snapshot(revision: phase.index + 10, phase: phase));
      await tester.pump();
      expect(lifecycle.mounts, 1);
      expect(lifecycle.disposals, 0);
    }

    controller.publish(_snapshot(
      revision: 30,
      phase: RuntimePlayerPhase.result,
    ));
    await tester.pump();
    expect(lifecycle.disposals, 1);
  });

  testWidgets('shows safe error context and optional diagnostics',
      (tester) async {
    var diagnosticCalls = 0;
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 19,
      phase: RuntimePlayerPhase.error,
      loadingProgress: const GameSessionLoadingProgress(
        stage: 'project',
        current: 1,
        total: 3,
      ),
      failure: const GameSessionFailure(
        code: GameSessionFailureCode.integrity,
        recoverability: GameSessionFailureRecoverability.repair,
        safeMessage: 'Un fichier du jeu est invalide.',
      ),
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.retry),
      ],
    ));
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(
      controller,
      onShowDiagnostics: () => diagnosticCalls++,
    )));

    expect(find.text('Un fichier du jeu est invalide.'), findsOneWidget);
    expect(find.textContaining('project'), findsOneWidget);
    expect(find.textContaining('integrity'), findsOneWidget);
    expect(find.textContaining('réparez'), findsOneWidget);

    await tester.tap(find.text('Diagnostics'));
    expect(diagnosticCalls, 1);
  });
}

PokeMapPlayerSessionView _view(
  RuntimePlayerViewController controller, {
  _SceneLifecycle? lifecycle,
  VoidCallback? onShowDiagnostics,
}) {
  return PokeMapPlayerSessionView(
    controller: controller,
    titlePresentation: const RuntimePlayerTitlePresentation(
      author: 'Studio Test',
      description: 'Une aventure de test.',
    ),
    gameSceneBuilder: (_) => _SceneProbe(
      key: const ValueKey<String>('test-game-scene'),
      lifecycle: lifecycle ?? _SceneLifecycle(),
    ),
    onShowDiagnostics: onShowDiagnostics,
  );
}

RuntimePlayerSnapshot _snapshot({
  required int revision,
  required RuntimePlayerPhase phase,
  List<RuntimePlayerActionAvailability> actions =
      const <RuntimePlayerActionAvailability>[],
  GameSessionLoadingProgress? loadingProgress,
  GameSessionFailure? failure,
}) {
  return RuntimePlayerSnapshot(
    revision: revision,
    phase: phase,
    gameTitle: 'Aube',
    pauseSection: phase == RuntimePlayerPhase.paused
        ? RuntimePlayerPauseSection.root
        : null,
    actions: actions,
    loadingProgress: loadingProgress,
    failure: failure,
    result: phase == RuntimePlayerPhase.result
        ? const GameResultSnapshot(
            title: 'Victoire',
            summary: 'La région est sauvée.',
          )
        : null,
    credits: phase == RuntimePlayerPhase.result ||
            phase == RuntimePlayerPhase.credits
        ? const GameCreditsSnapshot(
            title: 'Aube',
            author: 'Studio Test',
            endingLabel: 'Fin principale',
          )
        : null,
  );
}

Finder _surfaceFinder(RuntimePlayerPhase phase) => find.byKey(
      ValueKey<String>('runtime-player-surface-${phase.name}'),
    );

Finder _allCanonicalSurfaces() => find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          ((widget.key! as ValueKey<String>).value)
              .startsWith('runtime-player-surface-'),
    );

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: child,
    );

final class _FakeRuntimePlayerCoordinator
    implements RuntimePlayerViewController {
  _FakeRuntimePlayerCoordinator(this._snapshot);

  final _snapshots = StreamController<RuntimePlayerSnapshot>.broadcast();
  final commands = <RuntimePlayerCommand>[];
  RuntimePlayerSnapshot _snapshot;

  @override
  RuntimePlayerSnapshot get snapshot => _snapshot;

  @override
  Stream<RuntimePlayerSnapshot> get snapshots => _snapshots.stream;

  void publish(RuntimePlayerSnapshot snapshot) {
    _snapshot = snapshot;
    _snapshots.add(snapshot);
  }

  @override
  Future<RuntimePlayerCommandResult> dispatch(
    RuntimePlayerCommand command,
  ) async {
    commands.add(command);
    return const RuntimePlayerCommandResult(
      status: RuntimePlayerCommandStatus.accepted,
    );
  }

  Future<void> dispose() => _snapshots.close();
}

final class _SceneLifecycle {
  int mounts = 0;
  int disposals = 0;
}

class _SceneProbe extends StatefulWidget {
  const _SceneProbe({
    super.key,
    required this.lifecycle,
  });

  final _SceneLifecycle lifecycle;

  @override
  State<_SceneProbe> createState() => _SceneProbeState();
}

class _SceneProbeState extends State<_SceneProbe> {
  @override
  void initState() {
    super.initState();
    widget.lifecycle.mounts++;
  }

  @override
  void dispose() {
    widget.lifecycle.disposals++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.black);
}
