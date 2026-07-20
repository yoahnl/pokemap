import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('shared Selbrume media fixture has a publishable playback sequence', () {
    final json = jsonDecode(
      File('test/fixtures/cinematic_media_contract/project.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final project = ProjectManifest.fromJson(json);
    final cinematic = project.cinematics.single;
    final report = preflightCinematicPlayback(
      cinematic: cinematic,
      dialogues: project.dialogues,
      mediaAssets: project.cinematicMediaAssets,
    );
    final plan = buildCinematicPreviewPlaybackPlan(
      cinematic: cinematic,
      dialogues: project.dialogues,
      mediaAssets: project.cinematicMediaAssets,
    );

    expect(report.isReady, isTrue);
    expect(plan.capabilities.hasUnsupportedSteps, isFalse);
    expect(plan.playbackCues, hasLength(5));
    expect(
        plan.playbackCues.map((cue) => cue.stepId), isNot(contains('marker')));
    expect(plan.executableDurationMs, 2900);
    expect(plan.totalDurationMs, 3200);
  });
}
