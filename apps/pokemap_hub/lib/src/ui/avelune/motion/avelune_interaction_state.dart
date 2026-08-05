enum AveluneInteractionState {
  idle,
  exchanging,
  aligning,
  descending,
  latched,
  launching,
  openingDetails,
  recovering,
  error,
}

typedef AveluneDelay = Future<void> Function(Duration duration);

abstract final class AveluneInteractionTransitions {
  static const Map<AveluneInteractionState, Set<AveluneInteractionState>>
      _allowed = <AveluneInteractionState, Set<AveluneInteractionState>>{
    AveluneInteractionState.idle: <AveluneInteractionState>{
      AveluneInteractionState.exchanging,
      AveluneInteractionState.aligning,
      AveluneInteractionState.openingDetails,
      AveluneInteractionState.error,
    },
    AveluneInteractionState.exchanging: <AveluneInteractionState>{
      AveluneInteractionState.idle,
      AveluneInteractionState.recovering,
      AveluneInteractionState.error,
    },
    AveluneInteractionState.aligning: <AveluneInteractionState>{
      AveluneInteractionState.descending,
      AveluneInteractionState.recovering,
      AveluneInteractionState.error,
    },
    AveluneInteractionState.descending: <AveluneInteractionState>{
      AveluneInteractionState.latched,
      AveluneInteractionState.recovering,
      AveluneInteractionState.error,
    },
    AveluneInteractionState.latched: <AveluneInteractionState>{
      AveluneInteractionState.launching,
      AveluneInteractionState.recovering,
      AveluneInteractionState.error,
    },
    AveluneInteractionState.launching: <AveluneInteractionState>{
      AveluneInteractionState.idle,
      AveluneInteractionState.recovering,
      AveluneInteractionState.error,
    },
    AveluneInteractionState.openingDetails: <AveluneInteractionState>{
      AveluneInteractionState.idle,
      AveluneInteractionState.error,
    },
    AveluneInteractionState.recovering: <AveluneInteractionState>{
      AveluneInteractionState.idle,
      AveluneInteractionState.error,
    },
    AveluneInteractionState.error: <AveluneInteractionState>{
      AveluneInteractionState.recovering,
      AveluneInteractionState.idle,
    },
  };

  static bool canTransition(
    AveluneInteractionState from,
    AveluneInteractionState to,
  ) =>
      _allowed[from]!.contains(to);

  static void ensureAllowed(
    AveluneInteractionState from,
    AveluneInteractionState to,
  ) {
    if (canTransition(from, to)) return;
    throw StateError('Invalid Avelune interaction transition: $from -> $to');
  }
}
