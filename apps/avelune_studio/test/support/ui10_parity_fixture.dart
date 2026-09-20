import 'dart:convert';
import 'dart:io';
import 'package:map_core/map_core.dart';
import 'ui07_story_fixture.dart';
import 'ui10_cinematic_fixture.dart';

CinematicAsset ui10ParityCinematic({bool cameraReset = false}) {
  final asset = ui10Cinematic();
  return asset.copyWith(
    timeline: CinematicTimeline(
      steps: [
        ...asset.timeline.steps.take(4),
        CinematicTimelineStep(
          id: 'step_shake',
          kind: CinematicTimelineStepKind.shake,
          label: 'Tremblement caméra',
          durationMs: 600,
          metadata: {'fx.intensity': '0.5'},
        ),
        if (cameraReset)
          CinematicTimelineStep(
            id: 'camera_reset',
            kind: CinematicTimelineStepKind.camera,
            durationMs: 300,
            metadata: {cinematicTimelineCameraModeMetadataKey: 'reset'},
          ),
        ...asset.timeline.steps.skip(4),
      ],
    ),
  );
}

Future<Ui07StoryFixture> createUi10ParityFixture({
  int tileSize = 32,
  int? tileHeight,
  bool cameraReset = false,
}) async {
  final fixture = await createUi10Fixture(
    runtimeEntry: true,
    tileSize: tileSize,
  );
  final file = File('${fixture.directory.path}/project.json');
  final manifest =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  manifest['cinematics'] = [
    ui10ParityCinematic(cameraReset: cameraReset).toJson(),
  ];
  if (tileHeight != null) {
    (manifest['settings'] as Map<String, dynamic>)['tileHeight'] = tileHeight;
  }
  await file.writeAsString(jsonEncode(manifest));
  return fixture;
}
