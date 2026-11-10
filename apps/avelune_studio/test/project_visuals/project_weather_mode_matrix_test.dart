import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  final modes = <String, SpatialVisualPatch>{
    'fixed': SpatialVisualPatch()
        .set(SpatialVisualParameter.weatherMode, 'fixed')
        .set(SpatialVisualParameter.weatherKind, 'storm')
        .set(SpatialVisualParameter.timeMode, 'fixed')
        .set(SpatialVisualParameter.minuteOfDay, 1320),
    'automatic': SpatialVisualPatch()
        .set(SpatialVisualParameter.weatherMode, 'automatic')
        .set(SpatialVisualParameter.weatherSequence, ['clear', 'snow'])
        .set(SpatialVisualParameter.weatherIntervalSeconds, 900)
        .set(SpatialVisualParameter.timeMode, 'cycle')
        .set(SpatialVisualParameter.dayDurationSeconds, 2400),
    'real': SpatialVisualPatch()
        .set(SpatialVisualParameter.weatherMode, 'real')
        .set(SpatialVisualParameter.weatherSequence, ['cloudy', 'rain'])
        .set(SpatialVisualParameter.timeMode, 'real'),
    'occasional': SpatialVisualPatch()
        .set(SpatialVisualParameter.weatherMode, 'occasional')
        .set(SpatialVisualParameter.weatherDryMinSeconds, 600)
        .set(SpatialVisualParameter.weatherDryMaxSeconds, 1200)
        .set(SpatialVisualParameter.weatherStormWeight, 0),
  };

  for (final entry in modes.entries) {
    test(
      '${entry.key} weather serializes, saves and reloads its values',
      () async {
        final port = _JsonPort();
        final owner = ProjectVisualsController(
          session: workspaceSession,
          port: port,
        );
        addTearDown(owner.dispose);
        await owner.open();
        owner.edit(
          entry.value.set(SpatialVisualParameter.depthOfFieldEnabled, true),
        );
        final settings = ProjectSettingsSessionController(
          projectVisuals: owner,
        );
        addTearDown(settings.dispose);
        expect(await settings.save(ProjectSettingsSection.timeWeather), isTrue);
        final reopened = ProjectVisualsController(
          session: workspaceSession,
          port: port,
        );
        addTearDown(reopened.dispose);
        await reopened.open();
        expect(reopened.saved!.profile, entry.value);
        expect(
          reopened.saved!.profile.enabled(
            SpatialVisualParameter.depthOfFieldEnabled,
          ),
          isNull,
        );
      },
    );
  }

  test('real weather without a service falls back to the saved sequence deterministically', () {
    final settings = modes['real']!.set(
      SpatialVisualParameter.weatherIntervalSeconds,
      600,
    );
    final first = resolveWorldEnvironment(
      settings: settings,
      elapsedSeconds: 700,
      localTime: DateTime(2026, 11, 7, 3, 0),
    );
    final again = resolveWorldEnvironment(
      settings: settings,
      elapsedSeconds: 700,
      localTime: DateTime(2026, 11, 7, 3, 0),
    );
    expect(first.weatherKind, SpatialWeatherKind.rain);
    expect(again.weatherKind, first.weatherKind);
    expect(first.minuteOfDay, 180);
    final live = resolveWorldEnvironment(
      settings: settings,
      elapsedSeconds: 700,
      localTime: DateTime(2026, 11, 7, 3, 0),
      realWeatherKind: SpatialWeatherKind.snow,
    );
    expect(live.weatherKind, SpatialWeatherKind.snow);
  });

  test(
    'switching mode with a draft keeps the other modes fields and the history',
    () async {
      final owner = ProjectVisualsController(
        session: workspaceSession,
        port: _JsonPort(),
      );
      addTearDown(owner.dispose);
      await owner.open();
      owner.edit(modes['automatic']!);
      final controls = SpatialVisualEditing(
        patch: owner.preview.value,
        inherited: SpatialVisualPatch(),
        onChanged: owner.edit,
      );
      controls.change(SpatialVisualParameter.weatherMode, 'occasional');
      expect(
        owner.preview.value.choice(SpatialVisualParameter.weatherMode),
        'occasional',
      );
      expect(
        owner.preview.value.value(SpatialVisualParameter.weatherSequence),
        ['clear', 'snow'],
      );
      expect(
        owner.preview.value.number(
          SpatialVisualParameter.weatherIntervalSeconds,
        ),
        900,
      );
      owner.undoWhere(isTimeWeatherVisualParameter);
      expect(
        owner.preview.value.choice(SpatialVisualParameter.weatherMode),
        'automatic',
      );
      expect(owner.canRedoWhere(isTimeWeatherVisualParameter), isTrue);
    },
  );

}

final class _JsonPort implements ProjectVisualsPort {
  Map<String, dynamic> json = {};
  int writes = 0;

  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) async => ProjectVisualsState(
    profile: SpatialVisualPatch.fromJson(json),
    revision: '$writes',
  );

  @override
  Future<ProjectVisualsState> saveVisuals(
    ProjectSession session,
    SpatialVisualPatch profile,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) async {
    if (expectedRevision != '$writes') throw StateError('stale');
    writes++;
    json = profile.toJson();
    return ProjectVisualsState(
      profile: SpatialVisualPatch.fromJson(json),
      revision: '$writes',
    );
  }

  @override
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => throw UnimplementedError();
}
