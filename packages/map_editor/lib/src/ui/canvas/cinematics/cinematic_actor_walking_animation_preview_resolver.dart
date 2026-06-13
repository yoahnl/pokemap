import 'package:map_core/map_core.dart';

enum CinematicActorWalkingAnimationPreviewKind {
  idle,
  walk,
  run,
  fallback,
}

enum CinematicActorWalkingAnimationFallbackReason {
  none,
  actorNotRenderable,
  missingSprite,
  missingCharacter,
  missingAnimation,
  missingDirection,
  emptyFrames,
  invalidFrame,
  stationary,
  missingPlaybackPose,
}

enum CinematicActorWalkingAnimationPreviewDiagnosticSeverity {
  info,
  warning,
  error,
}

enum CinematicActorWalkingAnimationPreviewDiagnosticCode {
  walkingAnimationMissing,
  walkingAnimationDirectionMissing,
  walkingAnimationFrameMissing,
  walkingAnimationSourceRectInvalid,
  walkingAnimationNoSprite,
  walkingAnimationCharacterMissing,
  walkingAnimationPoseMissing,
  walkingAnimationFallbackToIdle,
  walkingAnimationUnsupportedActorKind,
}

final class CinematicActorWalkingAnimationPreviewDiagnostic {
  const CinematicActorWalkingAnimationPreviewDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    this.actorId,
    this.characterId,
  });

  final CinematicActorWalkingAnimationPreviewDiagnosticCode code;
  final CinematicActorWalkingAnimationPreviewDiagnosticSeverity severity;
  final String message;
  final String? actorId;
  final String? characterId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicActorWalkingAnimationPreviewDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.actorId == actorId &&
          other.characterId == characterId;

  @override
  int get hashCode =>
      Object.hash(code, severity, message, actorId, characterId);
}

final class CinematicActorWalkingAnimationPreviewFrame {
  CinematicActorWalkingAnimationPreviewFrame({
    required this.actorId,
    required this.kind,
    required this.direction,
    required this.frameIndex,
    required this.frameDurationMs,
    required this.isMoving,
    required this.isFallback,
    required this.fallbackReason,
    required List<CinematicActorWalkingAnimationPreviewDiagnostic> diagnostics,
    this.sourceRect,
    this.characterId,
    this.tilesetId,
  }) : diagnostics =
            List<CinematicActorWalkingAnimationPreviewDiagnostic>.unmodifiable(
          diagnostics,
        );

  final String actorId;
  final CinematicActorWalkingAnimationPreviewKind kind;
  final EntityFacing? direction;
  final int frameIndex;
  final int frameDurationMs;
  final bool isMoving;
  final bool isFallback;
  final CinematicActorWalkingAnimationFallbackReason fallbackReason;
  final List<CinematicActorWalkingAnimationPreviewDiagnostic> diagnostics;
  final TilesetSourceRect? sourceRect;
  final String? characterId;
  final String? tilesetId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicActorWalkingAnimationPreviewFrame &&
          other.actorId == actorId &&
          other.kind == kind &&
          other.direction == direction &&
          other.frameIndex == frameIndex &&
          other.frameDurationMs == frameDurationMs &&
          other.isMoving == isMoving &&
          other.isFallback == isFallback &&
          other.fallbackReason == fallbackReason &&
          _listEquals(other.diagnostics, diagnostics) &&
          other.sourceRect == sourceRect &&
          other.characterId == characterId &&
          other.tilesetId == tilesetId;

  @override
  int get hashCode => Object.hash(
        actorId,
        kind,
        direction,
        frameIndex,
        frameDurationMs,
        isMoving,
        isFallback,
        fallbackReason,
        Object.hashAll(diagnostics),
        sourceRect,
        characterId,
        tilesetId,
      );
}

final class CinematicActorAnimationCadenceHint {
  const CinematicActorAnimationCadenceHint({
    required this.actorId,
    required this.velocityTilesPerSecond,
    required this.sampleWindowMs,
  });

  final String actorId;
  final double velocityTilesPerSecond;
  final int sampleWindowMs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicActorAnimationCadenceHint &&
          other.actorId == actorId &&
          other.velocityTilesPerSecond == velocityTilesPerSecond &&
          other.sampleWindowMs == sampleWindowMs;

  @override
  int get hashCode =>
      Object.hash(actorId, velocityTilesPerSecond, sampleWindowMs);
}

// V1-115 is deliberately editor-only read logic: it only chooses a symbolic
// frame. The preview renderer will consume this later in V1-116.
CinematicActorWalkingAnimationPreviewFrame
    resolveCinematicActorWalkingAnimationPreviewFrame({
  required CinematicActorDisplayPreviewActor actor,
  required CinematicPreviewPlaybackFrame? playbackFrame,
  required int playbackTimeMs,
  required bool isPlaybackPlaying,
  required List<CinematicTimelineStep> timelineSteps,
  required ProjectCharacterEntry? character,
  CinematicActorAnimationCadenceHint? cadenceHint,
}) {
  final diagnostics = <CinematicActorWalkingAnimationPreviewDiagnostic>[];
  final pose = playbackFrame?.actorPoseById(actor.actorId);
  if (pose == null) {
    diagnostics.add(_diagnostic(
      CinematicActorWalkingAnimationPreviewDiagnosticCode
          .walkingAnimationPoseMissing,
      CinematicActorWalkingAnimationPreviewDiagnosticSeverity.info,
      'Pose fixe utilisée pour cet acteur.',
      actor,
      character,
    ));
  }

  final moving = pose != null &&
      pose.hasPosition &&
      pose.isInterpolated &&
      pose.activeStepId != null;
  final preferredDirection = _directionFor(actor, pose);

  if (!actor.isRenderable) {
    return _fallback(
      actor,
      character,
      isMoving: moving,
      reason: CinematicActorWalkingAnimationFallbackReason.actorNotRenderable,
      diagnostics: [
        ...diagnostics,
        _diagnostic(
          CinematicActorWalkingAnimationPreviewDiagnosticCode
              .walkingAnimationUnsupportedActorKind,
          CinematicActorWalkingAnimationPreviewDiagnosticSeverity.warning,
          'Acteur non affichable dans la preview.',
          actor,
          character,
        ),
      ],
    );
  }

  if (character == null) {
    return _fallback(
      actor,
      null,
      isMoving: moving,
      reason: CinematicActorWalkingAnimationFallbackReason.missingCharacter,
      diagnostics: [
        ...diagnostics,
        _diagnostic(
          CinematicActorWalkingAnimationPreviewDiagnosticCode
              .walkingAnimationCharacterMissing,
          CinematicActorWalkingAnimationPreviewDiagnosticSeverity.warning,
          'Sprite de marche introuvable, placeholder affiché.',
          actor,
          null,
        ),
      ],
    );
  }

  if (actor.appearance.status !=
          CinematicActorPreviewAppearanceStatus.spriteReady ||
      actor.renderHint != CinematicActorPreviewRenderHint.sprite) {
    return _fallback(
      actor,
      character,
      isMoving: moving,
      reason: CinematicActorWalkingAnimationFallbackReason.missingSprite,
      diagnostics: [
        ...diagnostics,
        _diagnostic(
          CinematicActorWalkingAnimationPreviewDiagnosticCode
              .walkingAnimationNoSprite,
          CinematicActorWalkingAnimationPreviewDiagnosticSeverity.warning,
          'Sprite de marche introuvable, placeholder affiché.',
          actor,
          character,
        ),
      ],
    );
  }

  final requestedState = moving
      ? _movementStateFor(
          pose.activeStepId!,
          timelineSteps,
        )
      : CharacterAnimationState.idle;
  final selection = _selectAnimation(
    character: character,
    preferredDirection: preferredDirection,
    requestedState: requestedState,
    isMoving: moving,
  );

  if (selection == null) {
    return _fallback(
      actor,
      character,
      isMoving: moving,
      reason: CinematicActorWalkingAnimationFallbackReason.missingAnimation,
      diagnostics: [
        ...diagnostics,
        _diagnostic(
          CinematicActorWalkingAnimationPreviewDiagnosticCode
              .walkingAnimationMissing,
          CinematicActorWalkingAnimationPreviewDiagnosticSeverity.warning,
          'Animation de marche indisponible pour cet acteur.',
          actor,
          character,
        ),
      ],
    );
  }

  diagnostics.addAll(selection.diagnostics.map(
    (diagnostic) => diagnostic.withActor(actor, character),
  ));

  final animation = selection.animation;
  if (animation.frames.isEmpty) {
    return _fallback(
      actor,
      character,
      isMoving: moving,
      reason: CinematicActorWalkingAnimationFallbackReason.emptyFrames,
      diagnostics: [
        ...diagnostics,
        _diagnostic(
          CinematicActorWalkingAnimationPreviewDiagnosticCode
              .walkingAnimationFrameMissing,
          CinematicActorWalkingAnimationPreviewDiagnosticSeverity.warning,
          'Animation de marche vide, pose fixe affichée.',
          actor,
          character,
        ),
      ],
    );
  }

  final frameIndex = _frameIndexFor(
    frames: animation.frames,
    kind: selection.kind,
    playbackTimeMs: playbackTimeMs,
    cadenceHint: moving ? cadenceHint : null,
  );
  final frame = animation.frames[frameIndex];
  final durationMs = _durationFor(
    frame,
    selection.kind,
    cadenceHint: moving ? cadenceHint : null,
  );
  if (!_isValidSource(frame.source)) {
    return _fallback(
      actor,
      character,
      isMoving: moving,
      reason: CinematicActorWalkingAnimationFallbackReason.invalidFrame,
      diagnostics: [
        ...diagnostics,
        _diagnostic(
          CinematicActorWalkingAnimationPreviewDiagnosticCode
              .walkingAnimationSourceRectInvalid,
          CinematicActorWalkingAnimationPreviewDiagnosticSeverity.warning,
          'Sprite de marche introuvable, placeholder affiché.',
          actor,
          character,
        ),
      ],
    );
  }

  return CinematicActorWalkingAnimationPreviewFrame(
    actorId: actor.actorId,
    kind: selection.kind,
    direction: animation.direction,
    frameIndex: frameIndex,
    frameDurationMs: durationMs,
    isMoving: moving,
    isFallback: selection.isFallback,
    fallbackReason: selection.fallbackReason,
    diagnostics: diagnostics,
    sourceRect: frame.source,
    characterId: character.id,
    tilesetId: character.tilesetId,
  );
}

CharacterAnimationState _movementStateFor(
  String activeStepId,
  List<CinematicTimelineStep> timelineSteps,
) {
  for (final step in timelineSteps) {
    if (step.id != activeStepId) {
      continue;
    }
    return switch (cinematicTimelineActorMovementModeOf(step)) {
      CinematicTimelineActorMovementMode.run => CharacterAnimationState.run,
      CinematicTimelineActorMovementMode.walk ||
      null =>
        CharacterAnimationState.walk,
    };
  }
  return CharacterAnimationState.walk;
}

EntityFacing? _directionFor(
  CinematicActorDisplayPreviewActor actor,
  CinematicActorPlaybackPose? pose,
) {
  final poseDirection = _entityFacingFromPreviewDirection(pose?.facing);
  if (poseDirection != null) {
    return poseDirection;
  }
  return _entityFacingFromPreviewDirection(actor.direction);
}

EntityFacing? _entityFacingFromPreviewDirection(
  CinematicActorPreviewDirection? direction,
) {
  return switch (direction) {
    CinematicActorPreviewDirection.north => EntityFacing.north,
    CinematicActorPreviewDirection.south => EntityFacing.south,
    CinematicActorPreviewDirection.east => EntityFacing.east,
    CinematicActorPreviewDirection.west => EntityFacing.west,
    CinematicActorPreviewDirection.unknown || null => null,
  };
}

_AnimationSelection? _selectAnimation({
  required ProjectCharacterEntry character,
  required EntityFacing? preferredDirection,
  required CharacterAnimationState requestedState,
  required bool isMoving,
}) {
  final candidates = isMoving
      ? requestedState == CharacterAnimationState.run
          ? const [
              _AnimationCandidate.directional(CharacterAnimationState.run),
              _AnimationCandidate.directional(CharacterAnimationState.walk),
              _AnimationCandidate.anyDirection(CharacterAnimationState.run),
              _AnimationCandidate.anyDirection(CharacterAnimationState.walk),
              _AnimationCandidate.directional(CharacterAnimationState.idle),
              _AnimationCandidate.anyDirection(CharacterAnimationState.idle),
            ]
          : const [
              _AnimationCandidate.directional(CharacterAnimationState.walk),
              _AnimationCandidate.anyDirection(CharacterAnimationState.walk),
              _AnimationCandidate.directional(CharacterAnimationState.idle),
              _AnimationCandidate.anyDirection(CharacterAnimationState.idle),
            ]
      : const [
          _AnimationCandidate.directional(CharacterAnimationState.idle),
          _AnimationCandidate.anyDirection(CharacterAnimationState.idle),
        ];

  for (final candidate in candidates) {
    final animation = candidate.requiresPreferredDirection
        ? _animationFor(
            character.animations,
            candidate.state,
            preferredDirection,
          )
        : _firstAnimationFor(character.animations, candidate.state);
    if (animation == null) {
      continue;
    }

    final sameState = candidate.state == requestedState;
    return _AnimationSelection(
      animation: animation,
      kind: _kindFor(candidate.state),
      isFallback: !sameState || !candidate.requiresPreferredDirection,
      fallbackReason: candidate.requiresPreferredDirection
          ? sameState
              ? CinematicActorWalkingAnimationFallbackReason.none
              : CinematicActorWalkingAnimationFallbackReason.missingAnimation
          : CinematicActorWalkingAnimationFallbackReason.missingDirection,
      diagnostics: candidate.requiresPreferredDirection
          ? sameState
              ? const []
              : const [_SelectionDiagnostic.fallbackToIdle()]
          : const [_SelectionDiagnostic.directionMissing()],
    );
  }

  return null;
}

CharacterAnimation? _animationFor(
  List<CharacterAnimation> animations,
  CharacterAnimationState state,
  EntityFacing? direction,
) {
  if (direction == null) {
    return null;
  }
  for (final animation in animations) {
    if (animation.state == state && animation.direction == direction) {
      return animation;
    }
  }
  return null;
}

CharacterAnimation? _firstAnimationFor(
  List<CharacterAnimation> animations,
  CharacterAnimationState state,
) {
  for (final animation in animations) {
    if (animation.state == state) {
      return animation;
    }
  }
  return null;
}

CinematicActorWalkingAnimationPreviewKind _kindFor(
  CharacterAnimationState state,
) {
  return switch (state) {
    CharacterAnimationState.idle =>
      CinematicActorWalkingAnimationPreviewKind.idle,
    CharacterAnimationState.walk =>
      CinematicActorWalkingAnimationPreviewKind.walk,
    CharacterAnimationState.run =>
      CinematicActorWalkingAnimationPreviewKind.run,
  };
}

int _frameIndexFor({
  required List<CharacterAnimationFrame> frames,
  required CinematicActorWalkingAnimationPreviewKind kind,
  required int playbackTimeMs,
  CinematicActorAnimationCadenceHint? cadenceHint,
}) {
  if (frames.length <= 1) {
    return 0;
  }

  final durations = [
    for (final frame in frames)
      _durationFor(frame, kind, cadenceHint: cadenceHint),
  ];
  final cycleDurationMs = durations.fold<int>(0, (sum, value) => sum + value);
  if (cycleDurationMs <= 0) {
    return 0;
  }

  final timeInCycle = playbackTimeMs < 0 ? 0 : playbackTimeMs % cycleDurationMs;
  var elapsed = 0;
  for (var i = 0; i < durations.length; i++) {
    elapsed += durations[i];
    if (timeInCycle < elapsed) {
      return i;
    }
  }
  return frames.length - 1;
}

int _durationFor(
  CharacterAnimationFrame frame,
  CinematicActorWalkingAnimationPreviewKind kind, {
  CinematicActorAnimationCadenceHint? cadenceHint,
}) {
  final baseDurationMs =
      frame.durationMs > 0 ? frame.durationMs : _fallbackDurationFor(kind);
  return _effectiveDurationForCadence(
    baseDurationMs: baseDurationMs,
    kind: kind,
    cadenceHint: cadenceHint,
  );
}

int _fallbackDurationFor(CinematicActorWalkingAnimationPreviewKind kind) {
  return switch (kind) {
    CinematicActorWalkingAnimationPreviewKind.run => 90,
    CinematicActorWalkingAnimationPreviewKind.idle ||
    CinematicActorWalkingAnimationPreviewKind.walk ||
    CinematicActorWalkingAnimationPreviewKind.fallback =>
      140,
  };
}

bool _isValidSource(TilesetSourceRect source) {
  return source.x >= 0 &&
      source.y >= 0 &&
      source.width > 0 &&
      source.height > 0;
}

int _effectiveDurationForCadence({
  required int baseDurationMs,
  required CinematicActorWalkingAnimationPreviewKind kind,
  required CinematicActorAnimationCadenceHint? cadenceHint,
}) {
  if (cadenceHint == null ||
      cadenceHint.velocityTilesPerSecond <= 0 ||
      cadenceHint.sampleWindowMs <= 0 ||
      (kind != CinematicActorWalkingAnimationPreviewKind.walk &&
          kind != CinematicActorWalkingAnimationPreviewKind.run)) {
    return baseDurationMs;
  }

  // The hint is derived from playback poses only; keeping the adjustment here
  // avoids any actorMove/manual-path route recalculation in the renderer.
  final referenceSpeed = switch (kind) {
    CinematicActorWalkingAnimationPreviewKind.run => 4.0,
    CinematicActorWalkingAnimationPreviewKind.walk => 2.0,
    CinematicActorWalkingAnimationPreviewKind.idle ||
    CinematicActorWalkingAnimationPreviewKind.fallback =>
      0.0,
  };
  if (referenceSpeed <= 0) {
    return baseDurationMs;
  }

  final rawFactor = cadenceHint.velocityTilesPerSecond / referenceSpeed;
  final cadenceFactor = rawFactor.clamp(0.75, 1.75).toDouble();
  return (baseDurationMs / cadenceFactor).round().clamp(60, 260);
}

CinematicActorWalkingAnimationPreviewFrame _fallback(
  CinematicActorDisplayPreviewActor actor,
  ProjectCharacterEntry? character, {
  required bool isMoving,
  required CinematicActorWalkingAnimationFallbackReason reason,
  required List<CinematicActorWalkingAnimationPreviewDiagnostic> diagnostics,
}) {
  return CinematicActorWalkingAnimationPreviewFrame(
    actorId: actor.actorId,
    kind: CinematicActorWalkingAnimationPreviewKind.fallback,
    direction: _entityFacingFromPreviewDirection(actor.direction),
    frameIndex: 0,
    frameDurationMs: _fallbackDurationFor(
      CinematicActorWalkingAnimationPreviewKind.fallback,
    ),
    isMoving: isMoving,
    isFallback: true,
    fallbackReason: reason,
    diagnostics: diagnostics,
    characterId: character?.id,
    tilesetId: character?.tilesetId,
  );
}

CinematicActorWalkingAnimationPreviewDiagnostic _diagnostic(
  CinematicActorWalkingAnimationPreviewDiagnosticCode code,
  CinematicActorWalkingAnimationPreviewDiagnosticSeverity severity,
  String message,
  CinematicActorDisplayPreviewActor actor,
  ProjectCharacterEntry? character,
) {
  return CinematicActorWalkingAnimationPreviewDiagnostic(
    code: code,
    severity: severity,
    message: message,
    actorId: actor.actorId,
    characterId: character?.id,
  );
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

final class _AnimationSelection {
  const _AnimationSelection({
    required this.animation,
    required this.kind,
    required this.isFallback,
    required this.fallbackReason,
    required this.diagnostics,
  });

  final CharacterAnimation animation;
  final CinematicActorWalkingAnimationPreviewKind kind;
  final bool isFallback;
  final CinematicActorWalkingAnimationFallbackReason fallbackReason;
  final List<_SelectionDiagnostic> diagnostics;
}

final class _AnimationCandidate {
  const _AnimationCandidate.directional(this.state)
      : requiresPreferredDirection = true;

  const _AnimationCandidate.anyDirection(this.state)
      : requiresPreferredDirection = false;

  final CharacterAnimationState state;
  final bool requiresPreferredDirection;
}

final class _SelectionDiagnostic {
  const _SelectionDiagnostic(this.code, this.message);

  const _SelectionDiagnostic.directionMissing()
      : this(
          CinematicActorWalkingAnimationPreviewDiagnosticCode
              .walkingAnimationDirectionMissing,
          'Direction de marche indisponible, pose par défaut affichée.',
        );

  const _SelectionDiagnostic.fallbackToIdle()
      : this(
          CinematicActorWalkingAnimationPreviewDiagnosticCode
              .walkingAnimationFallbackToIdle,
          'Pose fixe utilisée pour cet acteur.',
        );

  final CinematicActorWalkingAnimationPreviewDiagnosticCode code;
  final String message;

  CinematicActorWalkingAnimationPreviewDiagnostic withActor(
    CinematicActorDisplayPreviewActor actor,
    ProjectCharacterEntry character,
  ) {
    return _diagnostic(
      code,
      CinematicActorWalkingAnimationPreviewDiagnosticSeverity.info,
      message,
      actor,
      character,
    );
  }
}
