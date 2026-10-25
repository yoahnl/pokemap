import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/spatial/spatial_visual_playback.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';

void main() {
  test('scene transitions advance on simulation time and restore lower layers', () async {
    var current = SpatialVisualPatch();
    final base = SpatialVisualPatch.fromScene(camera: SpatialCameraProfile(), atmosphere: SpatialAtmosphereSettings(haloStrength: .8));
    final playback = SpatialVisualPlayback(readBase: () => base, publish: (value) => current = value);
    final owner = Object();
    final completed = playback.execute(SceneWorldPresentationInteractiveCommand(operation: SceneWorldPresentationOperation.atmosphere,
      visualSettings: SpatialVisualPatch.fromJson({'haloStrength': 1.8}), scope: SceneVisualScope.scene, durationMs: 1000, waitForCompletion: true), owner: owner);
    playback.advance(.5);
    expect(current.number(SpatialVisualParameter.haloStrength), closeTo(1.3, .00001));
    playback.advance(0);
    expect(current.number(SpatialVisualParameter.haloStrength), closeTo(1.3, .00001));
    playback.advance(.5);
    expect(await completed, 'completed');
    playback.releaseScene(Object());
    expect(current.isEmpty, isFalse);
    playback.releaseScene(owner);
    expect(current.isEmpty, isTrue);
    final pending = playback.execute(SceneWorldPresentationInteractiveCommand(operation: SceneWorldPresentationOperation.atmosphere,
      visualSettings: SpatialVisualPatch.fromJson({'fogOpacity': .3}), durationMs: 2000, waitForCompletion: true));
    playback.advance(.1);
    playback.reset();
    expect(await pending, 'cancelled');
    expect(current.isEmpty, isTrue);
  });
  test('map restore interpolates to inherited values and ends as a sparse patch', () async {
    var current = SpatialVisualPatch();
    final base = SpatialVisualPatch.fromScene(camera: SpatialCameraProfile(), atmosphere: SpatialAtmosphereSettings());
    final playback = SpatialVisualPlayback(readBase: () => base, publish: (value) => current = value);
    await playback.execute(SceneWorldPresentationInteractiveCommand(operation: SceneWorldPresentationOperation.atmosphere,
      visualSettings: SpatialVisualPatch.fromJson({'depthOfFieldStrength': .8})));
    final done = playback.execute(SceneWorldPresentationInteractiveCommand(operation: SceneWorldPresentationOperation.restoreAtmosphere, durationMs: 1000, waitForCompletion: true));
    playback.advance(.5);
    expect(current.number(SpatialVisualParameter.depthOfFieldStrength), lessThan(.8));
    playback.advance(.5);
    expect(await done, 'completed');
    expect(current.isEmpty, isTrue);
  });
  test('bounded runtime reader preserves missing baseline, reads both scopes and refuses future data', () async {
    final root = await Directory.systemTemp.createTemp('visual-runtime-');
    addTearDown(() => root.delete(recursive: true));
    expect((await loadSpatialVisualProfile(projectRoot: root.path)).isEmpty, isTrue);
    final file = File('${root.path}/project.visual.json');
    final patch = SpatialVisualPatch.fromJson({'pitchDegrees': 34});
    await file.writeAsString(jsonEncode(SpatialVisualDocument(profile: patch).toJson()));
    expect(await loadSpatialVisualProfile(projectRoot: root.path), patch);
    await file.writeAsString('{"schemaVersion":99,"profile":{}}');
    final before = await file.readAsBytes();
    await expectLater(loadSpatialVisualProfile(projectRoot: root.path), throwsA(isA<MapLoadException>()));
    expect(await file.readAsBytes(), before);
    await file.writeAsString(' ' * (SpatialVisualDocument.maxBytes + 1));
    await expectLater(loadSpatialVisualProfile(projectRoot: root.path), throwsA(isA<MapLoadException>()));
  });
}
