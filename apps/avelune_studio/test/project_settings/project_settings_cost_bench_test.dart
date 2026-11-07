import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_audio/application/project_audio_controller.dart';
import 'package:avelune_studio/features/project_cs/application/project_cs_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  final root = Platform.environment['AVELUNE_SETTINGS_BENCH_ROOT'];
  final mapId =
      Platform.environment['AVELUNE_SETTINGS_BENCH_MAP'] ?? 'first-map';
  final repeats = int.parse(
    Platform.environment['AVELUNE_SETTINGS_BENCH_REPEATS'] ?? '3',
  );

  test(
    'project settings cost on a real working catalog',
    () async {
      final reader = _CountingReader();
      final adapter = LocalMapWorkspaceAdapter(reader: reader);
      final session = await LocalProjectSessionAdapter().open(root!);
      expect(session.storage, ProjectSessionStorage.workingCatalog);
      final workspace = MapWorkspaceController(session, adapter);

      Future<void> measure(String label, Future<bool> Function() body) async {
        reader.reset();
        final started = DateTime.now();
        final watch = Stopwatch()..start();
        expect(await body(), isTrue, reason: label);
        watch.stop();
        final written = await _writtenSince(root, started);
        stdout.writeln(
          'bench $label ms=${watch.elapsedMilliseconds} ${reader.summary()} '
          'writes=${written.length} ${_summarizeWrites(written)}',
        );
      }

      await measure('open workspace', () async {
        await workspace.initialize();
        return workspace.error == null;
      });
      late final ProjectAudioController audio;
      late final ProjectCsController abilities;
      late final ProjectSurfController surf;
      void adopt(String before, String after) {
        audio.adoptRevision(before, after);
        abilities.adoptRevision(before, after);
        surf.adoptRevision(before, after);
      }

      audio = ProjectAudioController(
        session: session,
        port: adapter,
        onRevisionChanged: adopt,
        onSaved: workspace.acceptAudio,
      );
      abilities = ProjectCsController(
        session: session,
        port: adapter,
        onRevisionChanged: adopt,
        onSaved: workspace.acceptFieldAbilities,
      );
      surf = ProjectSurfController(
        session: session,
        port: adapter,
        dimension: workspace.project!.settings.dimension,
        onRevisionChanged: adopt,
        onSaved: workspace.acceptSurfConfiguration,
      );
      final projectVisuals = ProjectVisualsController(
        session: session,
        port: adapter,
      );
      final mapVisuals = ProjectVisualsController(
        session: session,
        port: adapter,
      );
      final entry = workspace.project!.maps.singleWhere(
        (map) => map.id == mapId,
      );
      await measure('open sounds', () async {
        await audio.open();
        return audio.error == null;
      });
      await measure('open field abilities', () async {
        await abilities.open();
        await surf.open();
        return abilities.error == null && surf.error == null;
      });
      await measure('open image and weather', () async {
        await projectVisuals.open();
        await mapVisuals.open(map: entry);
        return projectVisuals.error == null && mapVisuals.error == null;
      });

      final feedback = <String, List<int>>{};
      Future<bool> gesture(
        String label,
        void Function() edit,
        Future<bool> Function() save,
      ) async {
        final watch = Stopwatch()..start();
        edit();
        feedback.putIfAbsent(label, () => []).add(watch.elapsedMicroseconds);
        return save();
      }

      final cut = abilities.preview.value.disabledAbilityIds.contains('cut');
      for (var repeat = 0; repeat < repeats; repeat++) {
        await measure(
          'gain#$repeat',
          () => gesture(
            'gain',
            () => audio.gain(ProjectSoundCue.uiConfirm, '${40 + 5 * repeat}'),
            () => audio.saveCue(ProjectSoundCue.uiConfirm),
          ),
        );
        await measure(
          'image#$repeat',
          () => gesture(
            'image',
            () => projectVisuals.edit(
              _with(
                projectVisuals.preview.value,
                SpatialVisualParameter.pitchDegrees,
                30 + repeat,
              ),
            ),
            () => projectVisuals.saveWhere(isImageVisualParameter),
          ),
        );
        await measure(
          'map exception#$repeat',
          () => gesture(
            'map exception',
            () => mapVisuals.edit(
              _with(
                mapVisuals.preview.value,
                SpatialVisualParameter.fieldOfViewDegrees,
                40 + repeat,
              ),
            ),
            () => mapVisuals.saveWhere(isImageVisualParameter),
          ),
        );
        await measure(
          'map inheritance#$repeat',
          () => gesture(
            'map inheritance',
            () => mapVisuals.edit(
              _without(
                mapVisuals.preview.value,
                SpatialVisualParameter.fieldOfViewDegrees,
              ),
            ),
            () => mapVisuals.saveWhere(isImageVisualParameter),
          ),
        );
        await measure(
          'weather#$repeat',
          () => gesture(
            'weather',
            () => projectVisuals.edit(
              _with(
                projectVisuals.preview.value,
                SpatialVisualParameter.minuteOfDay,
                600 + repeat,
              ),
            ),
            () => projectVisuals.saveWhere(isTimeWeatherVisualParameter),
          ),
        );
        await measure(
          'field ability#$repeat',
          () => gesture(
            'field ability',
            () => abilities.setEnabledId('cut', repeat.isEven == cut),
            abilities.save,
          ),
        );
        await measure(
          'surf#$repeat',
          () => gesture(
            'surf',
            () => surf.editSpeed('${1 + repeat}${repeat.isEven ? ',5' : ''}'),
            surf.save,
          ),
        );
      }
      stdout.writeln(
        'bench feedback us ${feedback.entries.map((entry) => '${entry.key}=${entry.value}').join(' ')}',
      );

      final cold = LocalMapWorkspaceAdapter();
      final reopenedAudio = await cold.loadAudio(session);
      expect(
        reopenedAudio.configuration?.cues[ProjectSoundCue.uiConfirm]?.gain,
        audio.saved!.configuration!.cues[ProjectSoundCue.uiConfirm]!.gain,
      );
      expect(
        (await cold.loadVisuals(session)).profile,
        projectVisuals.saved!.profile,
      );
      expect(
        (await cold.loadVisuals(session, map: entry)).profile,
        mapVisuals.saved!.profile,
      );
      expect(
        (await cold.loadFieldAbilities(session)).configuration,
        abilities.saved!.configuration,
      );
      expect(
        (await cold.loadSurf(session)).configuration,
        surf.saved!.configuration,
      );
      stdout.writeln(
        'bench reopened gain=${reopenedAudio.configuration?.cues[ProjectSoundCue.uiConfirm]?.gain} '
        'pitch=${projectVisuals.saved!.profile.value(SpatialVisualParameter.pitchDegrees)} '
        'minute=${projectVisuals.saved!.profile.value(SpatialVisualParameter.minuteOfDay)} '
        'mapFov=${mapVisuals.saved!.profile.value(SpatialVisualParameter.fieldOfViewDegrees)} '
        'surf=${surf.saved!.configuration?.speedCellsPerSecond}',
      );
      for (final owner in [audio, abilities, surf]) {
        owner.dispose();
      }
      projectVisuals.dispose();
      mapVisuals.dispose();
      workspace.dispose();
    },
    skip: root == null
        ? 'Set AVELUNE_SETTINGS_BENCH_ROOT to a QA copy.'
        : false,
    timeout: const Timeout(Duration(minutes: 60)),
  );
}

SpatialVisualPatch _with(
  SpatialVisualPatch patch,
  SpatialVisualParameter parameter,
  Object value,
) => SpatialVisualPatch({...patch.values, parameter: value});

SpatialVisualPatch _without(
  SpatialVisualPatch patch,
  SpatialVisualParameter parameter,
) => SpatialVisualPatch({...patch.values}..remove(parameter));

Future<List<String>> _writtenSince(String root, DateTime since) async {
  final marker = File('$root/.bench-marker');
  await marker.writeAsString('');
  await marker.setLastModified(since);
  final result = await Process.run('find', [
    root,
    '-type',
    'f',
    '-newer',
    marker.path,
    '-not',
    '-name',
    '.bench-marker',
  ]);
  await marker.delete();
  return [
    for (final line in LineSplitter.split(result.stdout as String))
      if (line.isNotEmpty) line.substring(root.length + 1),
  ];
}

String _summarizeWrites(List<String> paths) {
  final counts = <String, int>{};
  for (final path in paths) {
    final key = path.startsWith('catalog/objects/')
        ? 'catalog/objects'
        : path.startsWith('.pokemap/authoring/')
        ? 'authoring'
        : path;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts.entries.map((entry) => '${entry.key}:${entry.value}').join(' ');
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  var bytes = 0;
  final delegate = const LocalProjectFileReader();

  void reset() {
    paths.clear();
    bytes = 0;
  }

  String summary() {
    final counts = <String, int>{};
    for (final path in paths) {
      final key = path.startsWith('catalog/objects/')
          ? 'objects'
          : path.startsWith('maps/')
          ? 'maps'
          : path.startsWith('assets/')
          ? 'assets'
          : path;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return 'reads=${paths.length} readKB=${(bytes / 1e3).toStringAsFixed(1)} '
        '${counts.entries.map((entry) => '${entry.key}:${entry.value}').join(' ')}';
  }

  @override
  bool get supportsStreamingResources => true;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.probeResource(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    paths.add(relativePath);
    final value = await delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    bytes += value.length;
    return value;
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
