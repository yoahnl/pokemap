import 'cinematic_actor_sprite_preview_plan.dart';
import 'cinematic_actor_walking_animation_preview_resolver.dart';

enum CinematicPlaybackPreviewAnimationState { ready, partial, none }

enum CinematicPlaybackPreviewFallbackSeverity { info, warning, error }

final class CinematicPlaybackPreviewFallbackMessage {
  const CinematicPlaybackPreviewFallbackMessage({
    required this.label,
    required this.severity,
  });

  final String label;
  final CinematicPlaybackPreviewFallbackSeverity severity;
}

final class CinematicPlaybackPreviewFallbackSummary {
  const CinematicPlaybackPreviewFallbackSummary({
    required this.messages,
    required this.visibleMessages,
    required this.extraCount,
  });

  const CinematicPlaybackPreviewFallbackSummary.empty()
      : messages = const [],
        visibleMessages = const [],
        extraCount = 0;

  final List<CinematicPlaybackPreviewFallbackMessage> messages;
  final List<CinematicPlaybackPreviewFallbackMessage> visibleMessages;
  final int extraCount;

  bool get hasDetails => visibleMessages.isNotEmpty;
}

CinematicPlaybackPreviewFallbackSummary
    buildCinematicPlaybackPreviewFallbackSummary({
  required CinematicPlaybackPreviewAnimationState animationState,
  required bool isPlaybackOverlayActive,
  required List<CinematicActorWalkingAnimationPreviewFrame> walkingFrames,
  required CinematicActorSpritePreviewPlan? spritePreviewPlan,
  int visibleLimit = 3,
}) {
  if (!isPlaybackOverlayActive ||
      animationState == CinematicPlaybackPreviewAnimationState.ready) {
    return const CinematicPlaybackPreviewFallbackSummary.empty();
  }

  final spriteActors = spritePreviewPlan?.actors ?? const [];
  if (walkingFrames.isEmpty && spriteActors.isEmpty) {
    return const CinematicPlaybackPreviewFallbackSummary.empty();
  }

  final actorLabels = {
    for (final actor in spriteActors) actor.actorId: actor.actorLabel,
  };
  final messages = <CinematicPlaybackPreviewFallbackMessage>[];
  final seenLabels = <String>{};

  void add(CinematicPlaybackPreviewFallbackMessage message) {
    if (seenLabels.add(message.label)) {
      messages.add(message);
    }
  }

  for (final frame in walkingFrames) {
    final message = _messageForWalkingFrame(frame, actorLabels[frame.actorId]);
    if (message != null) {
      add(message);
    }
  }

  for (final actor in spriteActors) {
    final message = _messageForSpriteActor(actor);
    if (message != null) {
      add(message);
    }
  }

  if (messages.isEmpty) {
    add(switch (animationState) {
      CinematicPlaybackPreviewAnimationState.partial =>
        const CinematicPlaybackPreviewFallbackMessage(
          label:
              'Prévisualisation partielle : certains acteurs restent en pose fixe.',
          severity: CinematicPlaybackPreviewFallbackSeverity.warning,
        ),
      CinematicPlaybackPreviewAnimationState.none =>
        const CinematicPlaybackPreviewFallbackMessage(
          label:
              'Aucun acteur ne possède encore d’animation exploitable pour cette prévisualisation.',
          severity: CinematicPlaybackPreviewFallbackSeverity.info,
        ),
      CinematicPlaybackPreviewAnimationState.ready =>
        throw StateError('Ready previews do not expose fallback details.'),
    });
  }

  messages.sort(
      (a, b) => _severityRank(b.severity).compareTo(_severityRank(a.severity)));
  final visible = messages.take(visibleLimit).toList(growable: false);
  return CinematicPlaybackPreviewFallbackSummary(
    messages: List.unmodifiable(messages),
    visibleMessages: visible,
    extraCount: messages.length - visible.length,
  );
}

CinematicPlaybackPreviewFallbackMessage? _messageForWalkingFrame(
  CinematicActorWalkingAnimationPreviewFrame frame,
  String? actorLabel,
) {
  if (!frame.isMoving &&
      frame.fallbackReason !=
          CinematicActorWalkingAnimationFallbackReason.missingPlaybackPose) {
    return null;
  }
  final actor = _actorLabel(actorLabel);
  return switch (frame.fallbackReason) {
    CinematicActorWalkingAnimationFallbackReason.none ||
    CinematicActorWalkingAnimationFallbackReason.stationary =>
      null,
    CinematicActorWalkingAnimationFallbackReason.actorNotRenderable =>
      CinematicPlaybackPreviewFallbackMessage(
        label: '$actor ne peut pas encore être animé dans cette preview.',
        severity: CinematicPlaybackPreviewFallbackSeverity.error,
      ),
    CinematicActorWalkingAnimationFallbackReason.missingSprite ||
    CinematicActorWalkingAnimationFallbackReason.invalidFrame =>
      CinematicPlaybackPreviewFallbackMessage(
        label: '$actor utilise un repère visuel : sprite acteur indisponible.',
        severity: CinematicPlaybackPreviewFallbackSeverity.warning,
      ),
    CinematicActorWalkingAnimationFallbackReason.missingCharacter =>
      CinematicPlaybackPreviewFallbackMessage(
        label: '$actor utilise un repère visuel : personnage non lié.',
        severity: CinematicPlaybackPreviewFallbackSeverity.warning,
      ),
    CinematicActorWalkingAnimationFallbackReason.missingAnimation =>
      CinematicPlaybackPreviewFallbackMessage(
        label: frame.kind == CinematicActorWalkingAnimationPreviewKind.idle
            ? '$actor utilise une pose fixe : animation de marche indisponible.'
            : '$actor utilise une animation de secours : animation de marche indisponible.',
        severity: CinematicPlaybackPreviewFallbackSeverity.warning,
      ),
    CinematicActorWalkingAnimationFallbackReason.missingDirection =>
      CinematicPlaybackPreviewFallbackMessage(
        label:
            '$actor utilise une autre direction : direction d’animation indisponible.',
        severity: CinematicPlaybackPreviewFallbackSeverity.warning,
      ),
    CinematicActorWalkingAnimationFallbackReason.emptyFrames =>
      CinematicPlaybackPreviewFallbackMessage(
        label: '$actor utilise une pose fixe : animation de marche vide.',
        severity: CinematicPlaybackPreviewFallbackSeverity.warning,
      ),
    CinematicActorWalkingAnimationFallbackReason.missingPlaybackPose =>
      CinematicPlaybackPreviewFallbackMessage(
        label: '$actor reste en pose fixe : position de preview indisponible.',
        severity: CinematicPlaybackPreviewFallbackSeverity.info,
      ),
  };
}

CinematicPlaybackPreviewFallbackMessage? _messageForSpriteActor(
  CinematicActorSpritePreviewActor actor,
) {
  final label = _actorLabel(actor.actorLabel);
  return switch (actor.status) {
    CinematicActorSpriteStatus.spriteReady ||
    CinematicActorSpriteStatus.hidden =>
      null,
    CinematicActorSpriteStatus.placeholderFallback =>
      CinematicPlaybackPreviewFallbackMessage(
        label:
            '$label utilise un repère visuel : apparence acteur à compléter.',
        severity: CinematicPlaybackPreviewFallbackSeverity.info,
      ),
    CinematicActorSpriteStatus.missingCharacter =>
      CinematicPlaybackPreviewFallbackMessage(
        label: '$label utilise un repère visuel : personnage non lié.',
        severity: CinematicPlaybackPreviewFallbackSeverity.warning,
      ),
    CinematicActorSpriteStatus.missingTileset ||
    CinematicActorSpriteStatus.invalidSourceRect =>
      CinematicPlaybackPreviewFallbackMessage(
        label: '$label utilise un repère visuel : sprite acteur indisponible.',
        severity: CinematicPlaybackPreviewFallbackSeverity.warning,
      ),
    CinematicActorSpriteStatus.missingIdleAnimation =>
      CinematicPlaybackPreviewFallbackMessage(
        label:
            '$label utilise une pose fixe : animation de repos indisponible.',
        severity: CinematicPlaybackPreviewFallbackSeverity.warning,
      ),
    CinematicActorSpriteStatus.missingDirectionFrame =>
      CinematicPlaybackPreviewFallbackMessage(
        label:
            '$label utilise une autre direction : direction d’animation indisponible.',
        severity: CinematicPlaybackPreviewFallbackSeverity.warning,
      ),
    CinematicActorSpriteStatus.unsupported =>
      CinematicPlaybackPreviewFallbackMessage(
        label: '$label ne peut pas encore être animé dans cette preview.',
        severity: CinematicPlaybackPreviewFallbackSeverity.error,
      ),
  };
}

String _actorLabel(String? label) {
  final trimmed = label?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return 'Acteur';
  }
  return trimmed;
}

int _severityRank(CinematicPlaybackPreviewFallbackSeverity severity) {
  return switch (severity) {
    CinematicPlaybackPreviewFallbackSeverity.error => 3,
    CinematicPlaybackPreviewFallbackSeverity.warning => 2,
    CinematicPlaybackPreviewFallbackSeverity.info => 1,
  };
}
