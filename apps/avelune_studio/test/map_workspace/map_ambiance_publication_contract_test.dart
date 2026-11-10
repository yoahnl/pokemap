import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_spatial_settings_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('map ambiance publishes cycle atmosphere and weather without an inspector and preserves another map draft', () async {
    final qa = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109/t01-map-ambiance',
    );
    await qa.create(recursive: true);
    final root = await qa.createTemp('publication-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    await Directory('${root.path}/maps').create();
    const entries = [
      ProjectMapEntry(id: 'a', name: 'A', relativePath: 'maps/a.json'),
      ProjectMapEntry(id: 'b', name: 'B', relativePath: 'maps/b.json'),
    ];
    final project = ProjectManifest(
      name: 'Ambiances indépendantes',
      version: ProjectVersion.v9,
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      maps: entries,
      tilesets: const [],
    );
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    for (final entry in entries) {
      final map = MapData(
        id: entry.id,
        name: entry.name,
        version: ProjectVersion.v9,
        size: const GridSize(width: 12, height: 10),
        spatialScene: MapSpatialScene(width: 12, depth: 10),
      );
      await File('${root.path}/${entry.relativePath}')
          .writeAsString(jsonEncode(map.toJson()));
    }
    final session = ProjectSession(
      sessionId: root.path,
      name: project.name,
      directoryPath: root.path,
    );
    final adapter = LocalMapWorkspaceAdapter();
    final workspace = MapWorkspaceController(session, adapter);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final first = workspace.active!;
    final firstAtmosphere = first.atmosphere!;
    await workspace.activate(entries.last);
    final second = workspace.active!;
    final secondAtmosphere = second.atmosphere!;
    final secondSavedAtmosphere = secondAtmosphere.current;
    final secondFile = File('${root.path}/maps/b.json');
    final secondBytes = await secondFile.readAsBytes();
    second.commit(second.current.copyWith(name: 'B gardée en brouillon'));
    secondAtmosphere.edit(
      secondAtmosphere.current.copyWith(depthFogEnabled: true),
    );
    final secondDraft = second.current;
    final secondAtmosphereDraft = secondAtmosphere.current;
    await workspace.activate(entries.first);
    expect(workspace.active, same(first));
    final weather = workspace.weatherDraftFor(first)!;
    await _waitForWeather(weather);
    final commands = MapSpatialSettingsCommands(first);
    expect(commands.dayNight(SpatialDayNightCycle()), isTrue);
    expect(
      commands.dayDuration('2,5', first.current.spatialScene!.dayNightCycle!),
      isTrue,
    );
    expect(
      commands.dayStart('21:30', first.current.spatialScene!.dayNightCycle!),
      isTrue,
    );
    firstAtmosphere.edit(
      firstAtmosphere.current.copyWith(
        depthOfFieldEnabled: true,
        depthOfFieldStrength: .65,
        depthOfFieldFocusRange: 18,
      ),
    );
    final editing = SpatialVisualEditing(
      patch: weather.preview.value,
      inherited: workspace.inheritedVisualProfile,
      onChanged: weather.edit,
    );
    editing.setMapWeatherSource('fixed');
    weather.edit(
      weather.preview.value
          .set(SpatialVisualParameter.weatherKind, 'storm')
          .set(SpatialVisualParameter.weatherIntensity, .8),
    );
    final expectedMap = first.current;
    final expectedAtmosphere = firstAtmosphere.current;
    final expectedWeather = weather.preview.value;
    expect(first.dirty, isTrue);
    expect(firstAtmosphere.dirty, isTrue);
    expect(weather.dirty, isTrue);
    expect(await workspace.save(first), isTrue, reason: first.error);
    expect(first.dirty, isFalse);
    expect(firstAtmosphere.dirty, isFalse);
    expect(weather.dirty, isFalse);
    expect(workspace.dirty, isTrue);
    expect(second.current, same(secondDraft));
    expect(second.dirty, isTrue);
    expect(secondAtmosphere.current, same(secondAtmosphereDraft));
    expect(secondAtmosphere.dirty, isTrue);
    expect(await secondFile.readAsBytes(), secondBytes);
    final cold = LocalMapWorkspaceAdapter();
    final reopened = await cold.loadProject(session);
    final firstEntry = reopened.maps.singleWhere((map) => map.id == 'a');
    final persistedMap = await cold.loadMap(session, firstEntry);
    expect(persistedMap.map, expectedMap);
    expect(persistedMap.map.spatialScene!.dayNightCycle!.durationSeconds, 150);
    expect(
      persistedMap.map.spatialScene!.dayNightCycle!.startMinuteOfDay,
      1290,
    );
    expect(
      (await cold.loadAtmosphere(session, 'a')).settings,
      expectedAtmosphere,
    );
    expect(
      (await cold.loadVisuals(session, map: firstEntry)).profile,
      expectedWeather,
    );
    final secondEntry = reopened.maps.singleWhere((map) => map.id == 'b');
    await cold.loadMap(session, secondEntry);
    expect(
      (await cold.loadAtmosphere(session, 'b')).settings,
      secondSavedAtmosphere,
    );
    expect(await secondFile.readAsBytes(), secondBytes);
  });
}

Future<void> _waitForWeather(ProjectVisualsController controller) async {
  if (controller.saved != null) return;
  final ready = Completer<void>();
  void changed() {
    if (ready.isCompleted) return;
    if (controller.error case final error?) {
      ready.completeError(StateError(error));
    } else if (controller.saved != null) {
      ready.complete();
    }
  }

  controller.addListener(changed);
  try {
    changed();
    await ready.future.timeout(const Duration(seconds: 10));
  } finally {
    controller.removeListener(changed);
  }
}
