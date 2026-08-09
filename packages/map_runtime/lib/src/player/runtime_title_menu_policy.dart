import 'runtime_player_models.dart';

/// The deliberately small public title menu used by a single-save game.
///
/// Advanced runtime actions remain available on [RuntimePlayerSnapshot], but
/// are not projected into this player-facing variant.
final class RuntimeTitleMenuProjection {
  RuntimeTitleMenuProjection({
    required List<RuntimePlayerActionAvailability> actions,
    required this.initialSelection,
    required this.requiresNewGameConfirmation,
  }) : actions = List<RuntimePlayerActionAvailability>.unmodifiable(actions);

  final List<RuntimePlayerActionAvailability> actions;
  final RuntimePlayerAction? initialSelection;
  final bool requiresNewGameConfirmation;
}

final class RuntimeTitleMenuPolicy {
  const RuntimeTitleMenuPolicy.singleSave();

  static const _publicActions = <RuntimePlayerAction>[
    RuntimePlayerAction.continueGame,
    RuntimePlayerAction.newGame,
    RuntimePlayerAction.openOptions,
    RuntimePlayerAction.returnToHost,
  ];

  RuntimeTitleMenuProjection project(RuntimePlayerSnapshot snapshot) {
    final declared = <RuntimePlayerAction, RuntimePlayerActionAvailability>{
      for (final availability in snapshot.actions)
        availability.action: availability,
    };
    final actions = <RuntimePlayerActionAvailability>[
      for (final action in _publicActions)
        declared[action] ??
            RuntimePlayerActionAvailability.disabled(
              action,
              reason: 'This action is unavailable for this game.',
            ),
    ];
    RuntimePlayerAction? initialSelection;
    for (final availability in actions) {
      if (availability.isEnabled) {
        initialSelection = availability.action;
        break;
      }
    }
    return RuntimeTitleMenuProjection(
      actions: actions,
      initialSelection: initialSelection,
      requiresNewGameConfirmation: snapshot.hasDiscoveredSave,
    );
  }
}
