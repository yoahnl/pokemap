import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime preview blocks references unavailable to the runtime', () {
    final cinematic = CinematicAsset(
      id: 'intro',
      title: 'Intro',
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'line',
            kind: CinematicTimelineStepKind.dialogueLine,
            assetRef: 'missing_dialogue',
            durationMs: 250,
          ),
        ],
      ),
    );
    final project = ProjectManifest(
      name: 'Runtime preview',
      maps: const [],
      tilesets: const [],
      cinematics: [cinematic],
    );

    final preview = const CinematicRuntimePreviewAdapter().inspect(
      project: project,
      cinematic: cinematic,
    );

    expect(preview.canStart, isFalse);
    expect(
      preview.preflightIssues.map((issue) => issue['kind']),
      contains('missingDialogue'),
    );
    expect(preview.timelineKinds, ['dialogueLine']);
    expect(preview.hostLimitations, isNotEmpty);
  });
}
