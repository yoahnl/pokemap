import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('cinematic awaits a custom character animation before restoring',
      () async {
    final sink = _CustomAnimationSink();
    final controller = CinematicRuntimePlaybackController(sink: sink);
    final command = CharacterCustomAnimationRuntimeCommand(
      actorId: 'actor',
      definitionId: 'saluer',
      direction: EntityFacing.south,
    );
    final asset = CinematicAsset(
      id: 'cinematic_custom_animation',
      title: 'Custom animation',
      requiredActors: [CinematicActorRef(actorId: 'actor')],
      stageContext: CinematicStageContext(
        actorBindings: [
          CinematicActorBinding(
            actorId: 'actor',
            kind: CinematicActorBindingKind.player,
          ),
        ],
      ),
      timeline: CinematicTimeline(
        steps: [
          buildCinematicCharacterCustomAnimationStep(
            id: 'saluer_step',
            command: command,
          ),
        ],
      ),
    );

    final completion = controller.play(asset);

    expect(sink.command, command);
    controller.update(const Duration(milliseconds: 300));
    expect(controller.isPlaying, isTrue);

    sink.completed = true;
    controller.update(Duration.zero);

    expect((await completion).success, isTrue);
    expect(sink.termination, CinematicRuntimeTermination.completed);
  });
}

final class _CustomAnimationSink
    implements
        CinematicRuntimePlaybackSink,
        CinematicRuntimeStepCompletionPolicy {
  CharacterCustomAnimationRuntimeCommand? command;
  bool completed = false;
  CinematicRuntimeTermination? termination;

  @override
  CinematicRuntimeSinkPreflightResult preflight(CinematicAsset asset) {
    return const CinematicRuntimeSinkPreflightResult.ready();
  }

  @override
  void beginStep(CinematicRuntimeStepContext context) {
    command = cinematicCharacterCustomAnimationCommandOf(context.step);
  }

  @override
  void updateStep(CinematicRuntimeStepContext context) {}

  @override
  bool isStepVisuallyComplete(CinematicRuntimeStepContext context) => completed;

  @override
  bool requiresSinkCompletion(CinematicRuntimeStepContext context) => true;

  @override
  void endStep(CinematicRuntimeStepContext context) {}

  @override
  void restore(CinematicRuntimeTermination termination) {
    this.termination = termination;
  }
}
