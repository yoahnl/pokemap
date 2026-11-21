enum FrameAcknowledgement { flutterFrameSubmitted, platformPresented }

sealed class DestinationReadiness {
  const DestinationReadiness();
}

final class DestinationPrepared extends DestinationReadiness {
  const DestinationPrepared();
}

final class DestinationAlreadyCovered extends DestinationReadiness {
  const DestinationAlreadyCovered();
}

final class DestinationSuperseded extends DestinationReadiness {
  const DestinationSuperseded();
}

final class DestinationPreparationUnavailable extends DestinationReadiness {
  const DestinationPreparationUnavailable();
}

final class DestinationPreparationFailed extends DestinationReadiness {
  const DestinationPreparationFailed(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

abstract interface class DestinationRenderPort<Destination> {
  Future<DestinationReadiness> prepareDestination(
    Destination destination,
    bool Function() isCurrent,
  );

  Future<FrameAcknowledgement> nextFrame();
}
