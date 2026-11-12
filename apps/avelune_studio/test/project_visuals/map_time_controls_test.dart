import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final realTime = SpatialVisualPatch.fromJson({
    'timeMode': 'real',
    'dayNightEnabled': true,
    'dayDurationSeconds': 1200,
    'minuteOfDay': 720,
  });

  test('a fixed map hour overrides a real time project and inherits back', () {
    var patch = SpatialVisualPatch.fromJson({'haloStrength': 1.2});
    SpatialVisualEditing editing() => SpatialVisualEditing(
      patch: patch,
      inherited: realTime,
      onChanged: (next) => patch = next,
    );
    expect(editing().mapTimeSource, MapTimeSource.inherit);

    editing().setMapTimeSource(MapTimeSource.fixed);

    expect(editing().mapTimeSource, MapTimeSource.fixed);
    expect(patch.choice(SpatialVisualParameter.timeMode), 'fixed');
    expect(patch.number(SpatialVisualParameter.minuteOfDay), 720);
    expect(editing().mapMinuteOfDay, 720);

    editing().setMapMinuteOfDay(22 * 60 + 30);

    expect(editing().mapMinuteOfDay, 1350);
    final frame = resolveWorldEnvironment(
      settings: realTime.overriddenBy(patch),
      elapsedSeconds: 5000,
      overrides: patch,
      localTime: DateTime(2026, 11, 12, 9, 15),
    );
    expect(frame.minuteOfDay, 1350);

    editing().setMapTimeSource(MapTimeSource.inherit);

    expect(editing().mapTimeSource, MapTimeSource.inherit);
    expect(patch.toJson(), {'haloStrength': 1.2});
  });

  test('a clock override that is not a fixed hour is reported as custom', () {
    var patch = SpatialVisualPatch.fromJson({
      'timeMode': 'cycle',
      'dayDurationSeconds': 300,
    });
    SpatialVisualEditing editing() => SpatialVisualEditing(
      patch: patch,
      inherited: realTime,
      onChanged: (next) => patch = next,
    );
    expect(editing().mapTimeSource, MapTimeSource.custom);

    editing().setMapTimeSource(MapTimeSource.fixed);

    expect(patch.toJson(), {'timeMode': 'fixed', 'minuteOfDay': 720.0});
  });

  test('a fixed hour outside the day is refused', () {
    var patch = SpatialVisualPatch.fromJson({
      'timeMode': 'fixed',
      'minuteOfDay': 600,
    });
    final editing = SpatialVisualEditing(
      patch: patch,
      inherited: realTime,
      onChanged: (next) => patch = next,
    );

    expect(editing.setMapMinuteOfDay(1440), isFalse);
    expect(editing.setMapMinuteOfDay(-1), isFalse);
    expect(patch.number(SpatialVisualParameter.minuteOfDay), 600);
  });
}
