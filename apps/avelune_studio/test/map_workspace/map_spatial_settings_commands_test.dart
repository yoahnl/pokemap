import 'package:avelune_studio/features/map_workspace/application/map_spatial_settings_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';
import '../support/spatial_ramp_fixture.dart';

void main() {
  test('camera numbers use French decimals and one local undo', () {
    final map = spatialEnvironmentMap();
    final document = rampDocument(map);
    final commands = MapSpatialSettingsCommands(document);
    final camera = map.spatialScene!.camera;
    expect(
      commands.cameraNumber(
        '45,5',
        (value) => camera.copyWith(pitchDegrees: value),
      ),
      isTrue,
    );
    expect(document.current.spatialScene!.camera.pitchDegrees, 45.5);
    expect(
      document.current.spatialScene!.instances,
      map.spatialScene!.instances,
    );
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, map);
  });

  test(
    'camera rejects nonfinite and invalid values without editing the map',
    () {
      final map = spatialEnvironmentMap();
      final document = rampDocument(map);
      final commands = MapSpatialSettingsCommands(document);
      final camera = map.spatialScene!.camera;
      expect(
        commands.cameraNumber(
          'NaN',
          (value) => camera.copyWith(pitchDegrees: value),
        ),
        isFalse,
      );
      expect(document.error, 'Saisissez un nombre valide.');
      expect(commands.camera(() => camera.copyWith(pitchDegrees: 91)), isFalse);
      expect(document.current, same(map));
      expect(document.canUndo, isFalse);
    },
  );

  test('day cycle duration and start time preserve their opposite fields', () {
    final document = rampDocument(spatialEnvironmentMap());
    final commands = MapSpatialSettingsCommands(document);
    final cycle = SpatialDayNightCycle(startMinuteOfDay: 720);
    expect(commands.dayNight(cycle), isTrue);
    expect(commands.dayDuration('0,5', cycle), isTrue);
    final changed = document.current.spatialScene!.dayNightCycle!;
    expect(changed.durationSeconds, 30);
    expect(changed.startMinuteOfDay, 720);
    expect(commands.dayStart('23:59', changed), isTrue);
    expect(
      document.current.spatialScene!.dayNightCycle!.startMinuteOfDay,
      1439,
    );
    expect(document.current.spatialScene!.dayNightCycle!.durationSeconds, 30);
    expect(commands.dayNight(null), isTrue);
    expect(document.current.spatialScene!.dayNightCycle, isNull);
    document.restore(redo: false);
    expect(
      document.current.spatialScene!.dayNightCycle!.startMinuteOfDay,
      1439,
    );
  });

  test(
    'invalid day times and durations preserve the original cycle and history',
    () {
      final document = rampDocument(spatialEnvironmentMap());
      final commands = MapSpatialSettingsCommands(document);
      final cycle = SpatialDayNightCycle();
      expect(commands.dayNight(cycle), isTrue);
      final map = document.current;
      final history = document.undoCount;
      for (final invalid in ['NaN', '0', '1441']) {
        expect(commands.dayDuration(invalid, cycle), isFalse);
      }
      for (final invalid in ['24:00', '12:60', '12', '-1:00']) {
        expect(commands.dayStart(invalid, cycle), isFalse);
      }
      expect(document.current, same(map));
      expect(document.undoCount, history);
    },
  );
  test('terrain appearance retains cliff texture and generation independently with undo', () {
    final map = spatialEnvironmentMap();
    final document = rampDocument(map);
    final commands = MapSpatialSettingsCommands(document);
    const frame = SmartTileFrameRef(atlasId: 'cliff', column: 0, row: 0);
    expect(
      commands.terrainAppearance(cliffFrame: frame, generateCliffs: false),
      isTrue,
    );
    expect(document.current.spatialScene!.cliffFrame, frame);
    expect(document.current.spatialScene!.generateCliffs, isFalse);
    expect(
      commands.terrainAppearance(cliffFrame: frame, generateCliffs: true),
      isTrue,
    );
    expect(document.current.spatialScene!.cliffFrame, frame);
    expect(document.current.spatialScene!.generateCliffs, isTrue);
    expect(commands.terrainAppearance(), isTrue);
    expect(document.current.spatialScene!.cliffFrame, isNull);
    expect(document.current.spatialScene!.generateCliffs, isTrue);
    document.restore(redo: false);
    expect(document.current.spatialScene!.cliffFrame, frame);
    document.saving = true;
    final before = document.current;
    expect(commands.terrainAppearance(generateCliffs: false), isFalse);
    expect(document.current, same(before));
  });
}
