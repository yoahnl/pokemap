import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart';

void main() {
  group('Cinematic Actor Walking Animation Preview Resolver', () {
    test('moving actor selects a walk frame and stationary actor selects idle',
        () {
      final character = _character(animations: [
        _animation(
          CharacterAnimationState.idle,
          EntityFacing.south,
          [_frame(0, 0)],
        ),
        _animation(
          CharacterAnimationState.walk,
          EntityFacing.east,
          [_frame(1, 0)],
        ),
      ]);
      final actor = _actor(direction: CinematicActorPreviewDirection.south);
      final step = _actorMoveStep('move_1', movementMode: 'walk');

      final moving = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(
          140,
          pose: _pose(
            facing: CinematicActorPreviewDirection.east,
            activeStepId: 'move_1',
          ),
        ),
        playbackTimeMs: 140,
        isPlaybackPlaying: false,
        timelineSteps: [step],
        character: character,
      );

      expect(moving.actorId, 'actor_lysa');
      expect(moving.kind, CinematicActorWalkingAnimationPreviewKind.walk);
      expect(moving.isMoving, isTrue);
      expect(moving.isFallback, isFalse);
      expect(moving.direction, EntityFacing.east);
      expect(
        moving.sourceRect,
        const TilesetSourceRect(x: 1, y: 0, width: 1, height: 2),
      );
      expect(moving.fallbackReason,
          CinematicActorWalkingAnimationFallbackReason.none);

      final stationary = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(
          0,
          pose: _pose(
            facing: CinematicActorPreviewDirection.east,
            isInterpolated: false,
            activeStepId: 'move_1',
          ),
        ),
        playbackTimeMs: 0,
        isPlaybackPlaying: true,
        timelineSteps: [step],
        character: character,
      );

      expect(stationary.kind, CinematicActorWalkingAnimationPreviewKind.idle);
      expect(stationary.isMoving, isFalse);
      expect(stationary.direction, EntityFacing.south);
      expect(
        stationary.sourceRect,
        const TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
      );
    });

    test('missing playback poses remain visible as idle or fallback', () {
      final actor = _actor();
      final character = _character(animations: [
        _animation(
          CharacterAnimationState.idle,
          EntityFacing.south,
          [_frame(0, 0)],
        ),
      ]);

      final missingPose = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: null,
        playbackTimeMs: 300,
        isPlaybackPlaying: true,
        timelineSteps: const [],
        character: character,
      );

      expect(missingPose.kind, CinematicActorWalkingAnimationPreviewKind.idle);
      expect(missingPose.isMoving, isFalse);
      expect(
        missingPose.diagnostics.map((diagnostic) => diagnostic.code),
        contains(CinematicActorWalkingAnimationPreviewDiagnosticCode
            .walkingAnimationPoseMissing),
      );

      final noPosition = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(
          300,
          pose: const CinematicActorPlaybackPose(
            actorId: 'actor_lysa',
            facing: CinematicActorPreviewDirection.south,
            source: CinematicActorPlaybackPoseSource.actorMoveDirect,
            isInterpolated: true,
            activeStepId: 'move_1',
          ),
        ),
        playbackTimeMs: 300,
        isPlaybackPlaying: true,
        timelineSteps: [_actorMoveStep('move_1')],
        character: character,
      );

      expect(noPosition.kind, CinematicActorWalkingAnimationPreviewKind.idle);
      expect(noPosition.isMoving, isFalse);
    });

    test('run mode selects run and falls back to walk when run is missing', () {
      final actor = _actor();
      final withRun = _character(animations: [
        _animation(
          CharacterAnimationState.walk,
          EntityFacing.east,
          [_frame(1, 0)],
        ),
        _animation(
          CharacterAnimationState.run,
          EntityFacing.east,
          [_frame(2, 0)],
        ),
      ]);
      final runStep = _actorMoveStep('move_run', movementMode: 'run');

      final run = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(
          90,
          pose: _pose(
            facing: CinematicActorPreviewDirection.east,
            activeStepId: 'move_run',
          ),
        ),
        playbackTimeMs: 90,
        isPlaybackPlaying: true,
        timelineSteps: [runStep],
        character: withRun,
      );

      expect(run.kind, CinematicActorWalkingAnimationPreviewKind.run);
      expect(
        run.sourceRect,
        const TilesetSourceRect(x: 2, y: 0, width: 1, height: 2),
      );

      final withoutRun = _character(animations: [
        _animation(
          CharacterAnimationState.walk,
          EntityFacing.east,
          [_frame(3, 0)],
        ),
      ]);
      final fallbackWalk = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(
          90,
          pose: _pose(
            facing: CinematicActorPreviewDirection.east,
            activeStepId: 'move_run',
          ),
        ),
        playbackTimeMs: 90,
        isPlaybackPlaying: true,
        timelineSteps: [runStep],
        character: withoutRun,
      );

      expect(fallbackWalk.kind, CinematicActorWalkingAnimationPreviewKind.walk);
      expect(
        fallbackWalk.sourceRect,
        const TilesetSourceRect(x: 3, y: 0, width: 1, height: 2),
      );

      final unknownMode = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(
          90,
          pose: _pose(
            facing: CinematicActorPreviewDirection.east,
            activeStepId: 'move_unknown',
          ),
        ),
        playbackTimeMs: 90,
        isPlaybackPlaying: true,
        timelineSteps: [_actorMoveStep('move_unknown', movementMode: 'dash')],
        character: withoutRun,
      );

      expect(unknownMode.kind, CinematicActorWalkingAnimationPreviewKind.walk);

      final sameDirectionWalkBeforeOtherDirectionRun =
          resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(
          90,
          pose: _pose(
            facing: CinematicActorPreviewDirection.east,
            activeStepId: 'move_run',
          ),
        ),
        playbackTimeMs: 90,
        isPlaybackPlaying: true,
        timelineSteps: [runStep],
        character: _character(animations: [
          _animation(
            CharacterAnimationState.run,
            EntityFacing.west,
            [_frame(4, 0)],
          ),
          _animation(
            CharacterAnimationState.walk,
            EntityFacing.east,
            [_frame(5, 0)],
          ),
        ]),
      );

      expect(
        sameDirectionWalkBeforeOtherDirectionRun.kind,
        CinematicActorWalkingAnimationPreviewKind.walk,
      );
      expect(
        sameDirectionWalkBeforeOtherDirectionRun.direction,
        EntityFacing.east,
      );
    });

    test('facing selects matching directional animation and falls back safely',
        () {
      final actor = _actor(direction: CinematicActorPreviewDirection.west);
      final character = _character(animations: [
        _animation(
          CharacterAnimationState.walk,
          EntityFacing.north,
          [_frame(0, 1)],
        ),
        _animation(
          CharacterAnimationState.walk,
          EntityFacing.south,
          [_frame(0, 2)],
        ),
        _animation(
          CharacterAnimationState.walk,
          EntityFacing.east,
          [_frame(0, 3)],
        ),
        _animation(
          CharacterAnimationState.walk,
          EntityFacing.west,
          [_frame(0, 4)],
        ),
      ]);
      final step = _actorMoveStep('move_1');

      for (final entry in const {
        CinematicActorPreviewDirection.north: EntityFacing.north,
        CinematicActorPreviewDirection.south: EntityFacing.south,
        CinematicActorPreviewDirection.east: EntityFacing.east,
        CinematicActorPreviewDirection.west: EntityFacing.west,
      }.entries) {
        final resolved = resolveCinematicActorWalkingAnimationPreviewFrame(
          actor: actor,
          playbackFrame: _frameAt(
            0,
            pose: _pose(facing: entry.key, activeStepId: 'move_1'),
          ),
          playbackTimeMs: 0,
          isPlaybackPlaying: true,
          timelineSteps: [step],
          character: character,
        );

        expect(resolved.direction, entry.value);
        expect(resolved.kind, CinematicActorWalkingAnimationPreviewKind.walk);
      }

      final missingDirection =
          resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(
          0,
          pose: _pose(
            facing: CinematicActorPreviewDirection.north,
            activeStepId: 'move_1',
          ),
        ),
        playbackTimeMs: 0,
        isPlaybackPlaying: true,
        timelineSteps: [step],
        character: _character(animations: [
          _animation(
            CharacterAnimationState.walk,
            EntityFacing.south,
            [_frame(8, 0)],
          ),
        ]),
      );

      expect(missingDirection.direction, EntityFacing.south);
      expect(
        missingDirection.diagnostics.map((diagnostic) => diagnostic.code),
        contains(CinematicActorWalkingAnimationPreviewDiagnosticCode
            .walkingAnimationDirectionMissing),
      );

      final unknownFacing = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(
          0,
          pose: _pose(
            facing: CinematicActorPreviewDirection.unknown,
            activeStepId: 'move_1',
          ),
        ),
        playbackTimeMs: 0,
        isPlaybackPlaying: true,
        timelineSteps: [step],
        character: character,
      );

      expect(unknownFacing.direction, EntityFacing.west);
    });

    test('frame cadence uses durationMs, cycles, clamps, and remains stable',
        () {
      final actor = _actor();
      final character = _character(animations: [
        _animation(
          CharacterAnimationState.walk,
          EntityFacing.east,
          [
            _frame(0, 0, durationMs: 100),
            _frame(1, 0, durationMs: 250),
            _frame(2, 0, durationMs: -1),
          ],
        ),
      ]);
      final step = _actorMoveStep('move_1');

      CinematicActorWalkingAnimationPreviewFrame resolveAt(int timeMs) {
        return resolveCinematicActorWalkingAnimationPreviewFrame(
          actor: actor,
          playbackFrame: _frameAt(
            timeMs,
            pose: _pose(
              facing: CinematicActorPreviewDirection.east,
              activeStepId: 'move_1',
            ),
          ),
          playbackTimeMs: timeMs,
          isPlaybackPlaying: false,
          timelineSteps: [step],
          character: character,
        );
      }

      expect(resolveAt(-20).frameIndex, 0);
      expect(resolveAt(100).frameIndex, 1);
      expect(resolveAt(349).frameIndex, 1);
      expect(resolveAt(350).frameIndex, 2);
      expect(resolveAt(490).frameIndex, 0);
      expect(resolveAt(350).frameDurationMs, 140);
      expect(resolveAt(350), resolveAt(350));
    });

    test('single-frame animation stays at frame zero', () {
      final resolved = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: _actor(),
        playbackFrame: _frameAt(
          999,
          pose: _pose(
            facing: CinematicActorPreviewDirection.east,
            activeStepId: 'move_1',
          ),
        ),
        playbackTimeMs: 999,
        isPlaybackPlaying: true,
        timelineSteps: [_actorMoveStep('move_1')],
        character: _character(animations: [
          _animation(
            CharacterAnimationState.walk,
            EntityFacing.east,
            [_frame(4, 0, durationMs: 80)],
          ),
        ]),
      );

      expect(resolved.frameIndex, 0);
      expect(resolved.frameDurationMs, 80);
    });

    test('fallbacks cover missing walk, missing idle, empty and invalid frames',
        () {
      final actor = _actor();
      final step = _actorMoveStep('move_1');

      final idleFallback = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(
          0,
          pose: _pose(
            facing: CinematicActorPreviewDirection.east,
            activeStepId: 'move_1',
          ),
        ),
        playbackTimeMs: 0,
        isPlaybackPlaying: true,
        timelineSteps: [step],
        character: _character(animations: [
          _animation(
            CharacterAnimationState.idle,
            EntityFacing.east,
            [_frame(9, 0)],
          ),
        ]),
      );

      expect(idleFallback.kind, CinematicActorWalkingAnimationPreviewKind.idle);
      expect(idleFallback.isFallback, isTrue);
      expect(idleFallback.fallbackReason,
          CinematicActorWalkingAnimationFallbackReason.missingAnimation);

      final placeholder = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(0, pose: _pose(activeStepId: 'move_1')),
        playbackTimeMs: 0,
        isPlaybackPlaying: true,
        timelineSteps: [step],
        character: _character(animations: const []),
      );

      expect(
          placeholder.kind, CinematicActorWalkingAnimationPreviewKind.fallback);
      expect(placeholder.fallbackReason,
          CinematicActorWalkingAnimationFallbackReason.missingAnimation);

      final emptyWalk = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(0, pose: _pose(activeStepId: 'move_1')),
        playbackTimeMs: 0,
        isPlaybackPlaying: true,
        timelineSteps: [step],
        character: _character(animations: const [
          CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: EntityFacing.south,
            frames: [],
          ),
        ]),
      );

      expect(
          emptyWalk.kind, CinematicActorWalkingAnimationPreviewKind.fallback);
      expect(
        emptyWalk.diagnostics.map((diagnostic) => diagnostic.code),
        contains(CinematicActorWalkingAnimationPreviewDiagnosticCode
            .walkingAnimationFrameMissing),
      );

      final invalid = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(0, pose: _pose(activeStepId: 'move_1')),
        playbackTimeMs: 0,
        isPlaybackPlaying: true,
        timelineSteps: [step],
        character: _character(animations: const [
          CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: EntityFacing.south,
            frames: [
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: -1, y: 0, width: 1, height: 2),
              ),
            ],
          ),
        ]),
      );

      expect(invalid.kind, CinematicActorWalkingAnimationPreviewKind.fallback);
      expect(invalid.fallbackReason,
          CinematicActorWalkingAnimationFallbackReason.invalidFrame);
    });

    test('actor without character or sprite returns placeholder fallback', () {
      final actor = _actor(
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
        ),
        renderHint: CinematicActorPreviewRenderHint.placeholder,
      );

      final resolved = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(0, pose: _pose(activeStepId: 'move_1')),
        playbackTimeMs: 0,
        isPlaybackPlaying: true,
        timelineSteps: [_actorMoveStep('move_1')],
        character: null,
      );

      expect(resolved.kind, CinematicActorWalkingAnimationPreviewKind.fallback);
      expect(resolved.isFallback, isTrue);
      expect(resolved.fallbackReason,
          CinematicActorWalkingAnimationFallbackReason.missingCharacter);
    });

    test('resolver is deterministic and does not mutate source models', () {
      final actor = _actor();
      final character = _character(animations: [
        _animation(
          CharacterAnimationState.walk,
          EntityFacing.south,
          [_frame(0, 0), _frame(1, 0)],
        ),
      ]);
      final step = _actorMoveStep('move_1');
      final beforeActorDiagnostics = actor.diagnostics;
      final beforeCharacterJson = character.toJson();
      final beforeStepMetadata = step.metadata;

      final first = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(140, pose: _pose(activeStepId: 'move_1')),
        playbackTimeMs: 140,
        isPlaybackPlaying: true,
        timelineSteps: [step],
        character: character,
      );
      final second = resolveCinematicActorWalkingAnimationPreviewFrame(
        actor: actor,
        playbackFrame: _frameAt(140, pose: _pose(activeStepId: 'move_1')),
        playbackTimeMs: 140,
        isPlaybackPlaying: true,
        timelineSteps: [step],
        character: character,
      );

      expect(first, second);
      expect(actor.diagnostics, same(beforeActorDiagnostics));
      expect(character.toJson(), beforeCharacterJson);
      expect(step.metadata, same(beforeStepMetadata));
    });
  });
}

CinematicActorDisplayPreviewActor _actor({
  CinematicActorPreviewDirection direction =
      CinematicActorPreviewDirection.south,
  CinematicActorPreviewAppearance appearance =
      const CinematicActorPreviewAppearance(
    status: CinematicActorPreviewAppearanceStatus.spriteReady,
    characterId: 'char_lysa',
    tilesetId: 'tileset_characters',
  ),
  CinematicActorPreviewRenderHint renderHint =
      CinematicActorPreviewRenderHint.sprite,
}) {
  return CinematicActorDisplayPreviewActor(
    actorId: 'actor_lysa',
    label: 'Lysa',
    role: null,
    bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
    bindingKind: CinematicActorBindingKind.cinematicOnly,
    bindingSourceId: null,
    bindingSourceLabel: null,
    position: const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.resolved,
      sourceKind: CinematicActorPreviewPositionSourceKind.stagePoint,
      x: 4,
      y: 6,
    ),
    appearance: appearance,
    direction: direction,
    directionSource: CinematicActorPreviewDirectionSource.actorFace,
    renderHint: renderHint,
    diagnostics: const [],
  );
}

ProjectCharacterEntry _character({
  required List<CharacterAnimation> animations,
}) {
  return ProjectCharacterEntry(
    id: 'char_lysa',
    name: 'Lysa',
    tilesetId: 'tileset_characters',
    frameWidth: 1,
    frameHeight: 2,
    animations: animations,
  );
}

CharacterAnimation _animation(
  CharacterAnimationState state,
  EntityFacing direction,
  List<CharacterAnimationFrame> frames,
) {
  return CharacterAnimation(
    state: state,
    direction: direction,
    frames: frames,
  );
}

CharacterAnimationFrame _frame(
  int x,
  int y, {
  int durationMs = 140,
}) {
  return CharacterAnimationFrame(
    source: TilesetSourceRect(x: x, y: y, width: 1, height: 2),
    durationMs: durationMs,
  );
}

CinematicTimelineStep _actorMoveStep(
  String id, {
  String movementMode = 'walk',
}) {
  return CinematicTimelineStep(
    id: id,
    kind: CinematicTimelineStepKind.actorMove,
    actorId: 'actor_lysa',
    metadata: {
      cinematicTimelineActorMovementModeMetadataKey: movementMode,
    },
  );
}

CinematicPreviewPlaybackFrame _frameAt(
  int timeMs, {
  required CinematicActorPlaybackPose pose,
}) {
  return CinematicPreviewPlaybackFrame(
    timeMs: timeMs,
    clampedTimeMs: timeMs < 0 ? 0 : timeMs,
    activeStepIds: pose.activeStepId == null ? const [] : [pose.activeStepId!],
    actorPoses: [pose],
    visibleDiagnostics: const [],
  );
}

CinematicActorPlaybackPose _pose({
  CinematicActorPreviewDirection facing = CinematicActorPreviewDirection.south,
  bool isInterpolated = true,
  String? activeStepId,
}) {
  return CinematicActorPlaybackPose(
    actorId: 'actor_lysa',
    actorLabel: 'Lysa',
    x: 4.2,
    y: 6.4,
    facing: facing,
    source: CinematicActorPlaybackPoseSource.actorMoveDirect,
    isInterpolated: isInterpolated,
    activeStepId: activeStepId,
  );
}
