import 'package:avelune_studio/features/map_workspace/application/map_spatial_settings_commands.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spatial_environment_fixture.dart';
import '../support/spatial_ramp_fixture.dart';

void main() {
  test('fishing height commits French decimals and supports undo', () {
    final map = spatialEnvironmentMap();
    final document = rampDocument(map);
    final commands = MapSpatialSettingsCommands(document);
    expect(commands.fishingDrop('0,5', spatialEnvironmentProject()), isTrue);
    expect(
      document.current.spatialScene!.navigation.maximumFishingDropWorld,
      .5,
    );
    expect(document.undoCount, 1);
    expect(
      document.current.spatialScene!.instances,
      map.spatialScene!.instances,
    );
    final changed = document.current;
    for (final invalid in ['5', '-1', 'NaN', 'Infinity', 'text']) {
      expect(
        commands.fishingDrop(invalid, spatialEnvironmentProject()),
        isFalse,
      );
    }
    expect(document.current, same(changed));
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, map);
  });

  test('fishing refuses writes while saving', () {
    final map = spatialEnvironmentMap();
    final document = rampDocument(map)..saving = true;
    expect(
      MapSpatialSettingsCommands(document)
          .fishingDrop('1', spatialEnvironmentProject()),
      isFalse,
    );
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
  });
}
