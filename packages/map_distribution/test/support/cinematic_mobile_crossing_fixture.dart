import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'spatial_package_fixture.dart';

Map<String, List<int>> mobileCrossingPayload() {
  final files = spatialPayload();
  final project = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!))
          as Map<String, dynamic>);
  files['project/project.json'] =
      utf8.encode(jsonEncode(project.copyWith(cinematics: [
    CinematicAsset(
        id: 'crossing',
        title: 'Crossing',
        mapId: 'map',
        allowMobileActorCrossing: true,
        timeline: CinematicTimeline(steps: [
          CinematicTimelineStep(
              id: 'wait', kind: CinematicTimelineStepKind.wait, durationMs: 100)
        ]))
  ]).toJson()));
  return files;
}
