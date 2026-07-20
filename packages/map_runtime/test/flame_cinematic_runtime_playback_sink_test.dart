import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('FlameCinematicRuntimePlaybackSink', () {
    test('preflight rejects an unavailable actor without runtime mutation', () {
      final host = _FakeHost()..actors.remove('npc');
      final sink = FlameCinematicRuntimePlaybackSink(host: host);

      final result = sink.preflight(_visualAsset());

      expect(result.isReady, isFalse);
      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
      );
      expect(host.inputLocked, isFalse);
      expect(host.events, isEmpty);
    });

    test('preflight rejects an incomplete map actor binding without throwing',
        () {
      final host = _FakeHost();
      final sink = FlameCinematicRuntimePlaybackSink(host: host);
      final asset = _visualAsset(
        stageContext: CinematicStageContext(
          actorBindings: <CinematicActorBinding>[
            CinematicActorBinding(
              actorId: 'lysa',
              kind: CinematicActorBindingKind.mapEntity,
            ),
          ],
        ),
      );

      final result = sink.preflight(asset);

      expect(result.isReady, isFalse);
      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
      );
      expect(host.inputLocked, isFalse);
      expect(host.events, isEmpty);
    });

    test('renders the eight V1 beats and restores the runtime atomically',
        () async {
      final host = _FakeHost();
      final sink = FlameCinematicRuntimePlaybackSink(host: host);
      final controller = CinematicRuntimePlaybackController(sink: sink);

      final completion = controller.play(_visualAsset());

      expect(host.inputLocked, isTrue);
      controller.update(const Duration(milliseconds: 10));
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.camera);

      controller.update(const Duration(milliseconds: 50));
      expect(host.cameraPosition, Vector2(15, 15));
      expect(host.cameraVisibleGameSize, Vector2(80, 64));

      controller.update(const Duration(milliseconds: 50));
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.actorMove);
      controller.update(const Duration(milliseconds: 50));
      expect(host.actors['hero']!.focusPoint, Vector2(60, 30));

      controller.update(const Duration(milliseconds: 50));
      expect(
          controller.currentStep?.kind, CinematicTimelineStepKind.actorEmote);
      expect(host.emoteId, 'heart');
      expect(host.actors['npc']!.facing, EntityFacing.east);

      controller.update(const Duration(milliseconds: 100));
      expect(
        controller.currentStep?.kind,
        CinematicTimelineStepKind.dialogueLine,
      );
      expect(host.dialogueLine, 'Le phare nous attend.');
      expect(sink.isAwaitingDialogueLineAdvance, isTrue);

      expect(sink.signalDialogueLineComplete(), isTrue);
      controller.update(Duration.zero);
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.fade);
      controller.update(const Duration(milliseconds: 50));
      expect(host.fadeOpacity, closeTo(0.5, 0.001));

      controller.update(const Duration(milliseconds: 50));
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.shake);
      controller.update(const Duration(milliseconds: 50));
      expect(host.cameraPosition, isNot(Vector2(20, 20)));

      controller.update(const Duration(milliseconds: 50));
      final result = await completion;

      expect(result.success, isTrue);
      expect(host.inputLocked, isFalse);
      expect(host.cameraPosition, Vector2(10, 10));
      expect(host.cameraVisibleGameSize, Vector2(100, 80));
      expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
      expect(host.actors['npc']!.facing, EntityFacing.south);
      expect(host.dialogueLine, isNull);
      expect(host.fadeOpacity, isNull);
      expect(host.emoteId, isNull);
    });

    test('cancellation restores camera actors overlays and input once',
        () async {
      final host = _FakeHost();
      final sink = FlameCinematicRuntimePlaybackSink(host: host);
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final asset = _visualAsset(
        steps: <CinematicTimelineStep>[
          _actorMoveStep(),
        ],
      );

      final completion = controller.play(asset);
      controller.update(const Duration(milliseconds: 50));
      expect(host.actors['hero']!.focusPoint, Vector2(60, 30));

      expect(controller.cancel(), isTrue);
      expect(controller.cancel(), isFalse);
      final result = await completion;

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.cancelled,
      );
      expect(host.inputLocked, isFalse);
      expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
      expect(host.inputUnlockCount, 1);
    });

    test('restoration keeps unlocking input when overlay cleanup throws',
        () async {
      final host = _FakeHost()..throwWhenClearingDialogue = true;
      final sink = FlameCinematicRuntimePlaybackSink(host: host);
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final completion = controller.play(
        _visualAsset(
          steps: <CinematicTimelineStep>[
            CinematicTimelineStep(
              id: 'line',
              kind: CinematicTimelineStepKind.dialogueLine,
              dialogueText: 'Toujours restaurer.',
            ),
          ],
        ),
      );

      expect(controller.cancel(), isTrue);
      final result = await completion;

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.sinkFailure,
      );
      expect(host.inputLocked, isFalse);
      expect(host.inputUnlockCount, 1);
      expect(host.cameraPosition, Vector2(10, 10));
      expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
    });
  });
}

final class _FakeHost implements FlameCinematicRuntimeHost {
  bool ready = true;
  bool inputLocked = false;
  int inputUnlockCount = 0;
  bool throwWhenClearingDialogue = false;
  String? dialogueLine;
  String? emoteId;
  double? fadeOpacity;
  final List<String> events = <String>[];
  final Map<String, _FakeActor> actors = <String, _FakeActor>{
    'hero': _FakeActor(Vector2(20, 20), EntityFacing.north),
    'npc': _FakeActor(Vector2(40, 20), EntityFacing.south),
  };

  @override
  String get activeMapId => 'map_port';

  @override
  bool get isReady => ready;

  @override
  Vector2 cameraPosition = Vector2(10, 10);

  @override
  Vector2? cameraVisibleGameSize = Vector2(100, 80);

  @override
  Vector2 get sceneCenter => Vector2(50, 40);

  @override
  FlameCinematicRuntimeActorHandle? get playerActor => actors['hero'];

  @override
  FlameCinematicRuntimeActorHandle? mapEntityActor(String entityId) {
    return actors[entityId];
  }

  @override
  Vector2? mapEntityFocusPoint(String entityId) {
    return actors[entityId]?.focusPoint.clone();
  }

  @override
  Vector2 stagePointFocusPoint(CinematicStagePoint point) {
    return Vector2(point.x, point.y);
  }

  @override
  void setCinematicInputLocked(bool locked) {
    inputLocked = locked;
    events.add('input:$locked');
    if (!locked) inputUnlockCount++;
  }

  @override
  void showCinematicActorEmote(
    FlameCinematicRuntimeActorHandle? actor,
    String? emoteId,
  ) {
    this.emoteId = emoteId;
    events.add('emote:${emoteId ?? '-'}');
  }

  @override
  void showCinematicDialogueLine(String? text) {
    if (text == null && throwWhenClearingDialogue) {
      throw StateError('dialogue cleanup failed');
    }
    dialogueLine = text;
    events.add('dialogue:${text ?? '-'}');
  }

  @override
  Future<void> playCinematicDialogueAsset(String dialogueId) async {
    events.add('dialogueAsset:$dialogueId');
  }

  @override
  void cancelCinematicDialogueAsset() {
    events.add('dialogueAsset:cancel');
  }

  @override
  void setCinematicFadeOpacity(double? opacity) {
    fadeOpacity = opacity;
    events.add('fade:${opacity ?? '-'}');
  }
}

final class _FakeActor implements FlameCinematicRuntimeActorHandle {
  _FakeActor(this.focusPoint, this.facing);

  @override
  Vector2 focusPoint;

  @override
  EntityFacing facing;

  @override
  void setFacing(EntityFacing facing) {
    this.facing = facing;
  }

  @override
  void setFocusPoint(Vector2 focusPoint) {
    this.focusPoint = focusPoint.clone();
  }
}

CinematicAsset _visualAsset({
  List<CinematicTimelineStep>? steps,
  CinematicStageContext? stageContext,
}) {
  return CinematicAsset(
    id: 'cinematic_port',
    title: 'Port cinematic',
    mapId: 'map_port',
    requiredActors: <CinematicActorRef>[
      CinematicActorRef(actorId: 'hero'),
      CinematicActorRef(actorId: 'lysa'),
    ],
    movementTargets: <CinematicMovementTargetRef>[
      CinematicMovementTargetRef(targetId: 'lighthouse', label: 'Phare'),
    ],
    stageContext: stageContext ??
        CinematicStageContext(
          actorBindings: <CinematicActorBinding>[
            CinematicActorBinding(
              actorId: 'hero',
              kind: CinematicActorBindingKind.player,
            ),
            CinematicActorBinding(
              actorId: 'lysa',
              kind: CinematicActorBindingKind.mapEntity,
              mapEntityId: 'npc',
            ),
          ],
          movementTargetBindings: <CinematicMovementTargetBinding>[
            CinematicMovementTargetBinding(
              targetId: 'lighthouse',
              kind: CinematicMovementTargetBindingKind.stagePoint,
              sourceId: 'lighthouse_point',
            ),
          ],
          stagePoints: <CinematicStagePoint>[
            CinematicStagePoint(
              id: 'lighthouse_point',
              label: 'Phare',
              x: 100,
              y: 40,
            ),
          ],
        ),
    timeline: CinematicTimeline(
      steps: steps ??
          <CinematicTimelineStep>[
            CinematicTimelineStep(
              id: 'wait',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 10,
            ),
            CinematicTimelineStep(
              id: 'camera',
              kind: CinematicTimelineStepKind.camera,
              durationMs: 100,
              metadata: const <String, String>{
                cinematicTimelineCameraModeMetadataKey: 'focus',
                cinematicTimelineCameraTargetKindMetadataKey: 'actor',
                cinematicTimelineCameraTargetActorIdMetadataKey: 'hero',
                cinematicTimelineCameraZoomPresetMetadataKey: 'close',
              },
            ),
            _actorMoveStep(),
            CinematicTimelineStep(
              id: 'face',
              kind: CinematicTimelineStepKind.actorFace,
              actorId: 'lysa',
              metadata: const <String, String>{
                cinematicTimelineActorDirectionMetadataKey: 'right',
              },
            ),
            CinematicTimelineStep(
              id: 'emote',
              kind: CinematicTimelineStepKind.actorEmote,
              durationMs: 100,
              actorId: 'lysa',
              metadata: const <String, String>{
                cinematicTimelineActorEmoteEmoteIdMetadataKey: 'heart',
              },
            ),
            CinematicTimelineStep(
              id: 'line',
              kind: CinematicTimelineStepKind.dialogueLine,
              dialogueText: 'Le phare nous attend.',
            ),
            CinematicTimelineStep(
              id: 'fade',
              kind: CinematicTimelineStepKind.fade,
              durationMs: 100,
              metadata: const <String, String>{
                cinematicTimelineFadeModeMetadataKey: 'fadeOut',
              },
            ),
            CinematicTimelineStep(
              id: 'shake',
              kind: CinematicTimelineStepKind.shake,
              durationMs: 100,
            ),
          ],
    ),
  );
}

CinematicTimelineStep _actorMoveStep() {
  return CinematicTimelineStep(
    id: 'move',
    kind: CinematicTimelineStepKind.actorMove,
    durationMs: 100,
    actorId: 'hero',
    targetId: 'lighthouse',
    metadata: const <String, String>{
      cinematicTimelineActorMovementModeMetadataKey: 'walk',
      cinematicTimelineActorPathModeMetadataKey: 'direct',
    },
  );
}
