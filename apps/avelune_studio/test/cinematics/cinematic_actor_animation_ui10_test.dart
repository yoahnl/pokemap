import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_preview_transport.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_actor_animation.dart';
import '../support/ui10_cinematic_fixture.dart';

void main() {
  test(
    'walking and running start their animation at the movement, after waits',
    () {
      for (final mode in ['walk', 'run']) {
        final original = ui10Cinematic();
        final asset = original.copyWith(
          timeline: CinematicTimeline(
            steps: [
              for (final step in original.timeline.steps)
                if (step.kind == CinematicTimelineStepKind.actorMove)
                  CinematicTimelineStep.fromJson({
                    ...step.toJson(),
                    'metadata': {
                      ...step.metadata,
                      cinematicTimelineActorMovementModeMetadataKey: mode,
                    },
                  })
                else
                  step,
            ],
          ),
        );
        final plan = buildCinematicPreviewPlaybackPlan(cinematic: asset);
        final transport = CinematicPreviewTransport()..install(plan);
        final movement = plan.timelineItems.firstWhere(
          (s) => s.kind == CinematicTimelineStepKind.actorMove,
        );
        expect(movement.startMs, greaterThan(0));
        transport.seek(movement.startMs + 100);
        final pose = cinematicActorAnimation(asset, transport, 'hero', true);
        expect(pose.elapsedMs, 100);
        expect(
          pose.state,
          mode == 'run'
              ? CharacterAnimationState.run
              : CharacterAnimationState.walk,
        );
        expect(
          cinematicActorAnimation(asset, transport, 'hero', false).state,
          CharacterAnimationState.idle,
        );
        transport.dispose();
      }
    },
  );
}
