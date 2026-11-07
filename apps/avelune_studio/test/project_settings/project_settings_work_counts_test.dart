import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_audio/application/project_audio_controller.dart';
import 'package:avelune_studio/features/project_cs/application/project_cs_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../support/spatial_environment_fixture.dart';

const _catalogGestures = {'gain', 'field ability', 'surf'};
const _visualGestures = {
  'image': 'project.visual.json',
  'map exception': 'maps/a.visual.json',
  'map inheritance': 'maps/a.visual.json',
  'weather': 'project.visual.json',
};

const _ledgers = ['history.jsonl', 'audit.jsonl'];

bool _unrelated(String path) =>
    path.contains('foreign') ||
    _ledgers.any((ledger) => path.endsWith('.pokemap/authoring/$ledger'));

void main() {
  final counts = <int, Map<String, List<_Work>>>{};

  for (final unrelated in [24, 25, 48]) {
    test(
      'settings gestures touch only their storage units with $unrelated unrelated maps, media and history',
      () async {
        final fixture = await _Fixture.create(unrelated);
        addTearDown(fixture.dispose);
        final reader = _CountingReader();
        final adapter = LocalMapWorkspaceAdapter(reader: reader);
        final workspace = MapWorkspaceController(fixture.session, adapter);
        addTearDown(workspace.dispose);
        await workspace.initialize();
        expect(workspace.error, isNull);
        var notifications = 0;
        workspace.addListener(() => notifications++);
        final owners = _Owners(fixture.session, adapter, workspace);
        addTearDown(owners.dispose);
        await owners.open(
          workspace.project!.maps.singleWhere((map) => map.id == 'a'),
        );

        final observed = <String, List<_Work>>{};
        for (var repeat = 0; repeat < 2; repeat++) {
          for (final gesture in owners.gestures.entries) {
            reader.reset();
            final before = await _tree(fixture.directory);
            final builds = workspace.visualProjectionBuilds;
            final notified = notifications;
            final outside = Zone.current;
            final attempts = <String>[];
            final saved = await IOOverrides.runZoned(
              () => gesture.value(repeat),
              createFile: (path) {
                final file = outside.run(() => File(path));
                return _unrelated(file.path)
                    ? _UnreadableFile(file, attempts)
                    : file;
              },
            );
            expect(saved, isTrue, reason: '${gesture.key}: ${owners.error}');
            expect(
              attempts,
              isEmpty,
              reason: '${gesture.key} opened unrelated content or history',
            );
            final work = _Work(
              reads: List.of(reader.reads),
              probes: List.of(reader.probes),
              definitions: List.of(reader.definitions),
              writes: _changed(before, await _tree(fixture.directory)),
              projectionBuilds: workspace.visualProjectionBuilds - builds,
              notifications: notifications - notified,
            );
            _expectBounded(gesture.key, work);
            observed.putIfAbsent(gesture.key, () => []).add(work);
          }
        }
        counts[unrelated] = observed;

        if (unrelated == 25) {
          expect(
            [for (final work in observed['gain']!) work.reads.length],
            [for (final work in counts[24]!['gain']!) work.reads.length],
            reason: 'one unrelated map added no read to changing the gain of an action',
          );
        }
        if (unrelated != 24) {
          for (final gesture in owners.gestures.keys) {
            for (var repeat = 0; repeat < 2; repeat++) {
              expect(
                observed[gesture]![repeat].signature,
                counts[24]![gesture]![repeat].signature,
                reason: '$gesture #$repeat depends on unrelated content',
              );
            }
          }
        }

        await owners.expectReopened(fixture.session);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}

void _expectBounded(String gesture, _Work work) {
  final foreign = [...work.reads, ...work.probes].where(_unrelated);
  expect(foreign, isEmpty, reason: '$gesture read unrelated content');
  expect(
    work.definitions.where((key) => key.contains('foreign')),
    isEmpty,
    reason: '$gesture decoded an unrelated definition',
  );
  expect(
    work.writes.where((path) => path.contains('foreign')),
    isEmpty,
    reason: '$gesture wrote unrelated content',
  );
  expect(work.projectionBuilds, 0, reason: '$gesture rebuilt map visuals');
  final stored = [
    for (final path in work.writes)
      if (!path.startsWith('.pokemap/authoring/')) path,
  ];
  if (_visualGestures[gesture] case final document?) {
    expect(work.reads, isEmpty, reason: '$gesture read through the project');
    expect(work.probes.toSet(), {
      document,
      document == 'project.visual.json' ? 'project.json' : 'maps/a.json',
    }, reason: '$gesture probed more than its document and owner');
    expect(stored, [document], reason: '$gesture wrote outside its document');
    expect(work.definitions, isEmpty);
    expect(work.notifications, 0);
    return;
  }
  expect(_catalogGestures, contains(gesture));
  expect(
    work.reads.where(
      (path) => path != 'project.json' && !path.startsWith('catalog/'),
    ),
    isEmpty,
    reason: '$gesture read outside the project settings catalog',
  );
  expect(
    stored.where(
      (path) =>
          path != 'catalog/HEAD.json' && !path.startsWith('catalog/objects/'),
    ),
    isEmpty,
    reason: '$gesture wrote outside the project settings catalog',
  );
  expect(
    work.definitions.where(
      (key) =>
          !key.contains('publication-shell') &&
          !key.contains('narrativeEventDocuments'),
    ),
    isEmpty,
    reason: '$gesture decoded a definition it does not depend on',
  );
  expect(work.notifications, 1);
}

final class _Owners {
  _Owners(this.session, this.adapter, MapWorkspaceController workspace) {
    audio = ProjectAudioController(
      session: session,
      port: adapter,
      onRevisionChanged: _adopt,
      onSaved: workspace.acceptAudio,
    );
    abilities = ProjectCsController(
      session: session,
      port: adapter,
      onRevisionChanged: _adopt,
      onSaved: workspace.acceptFieldAbilities,
    );
    surf = ProjectSurfController(
      session: session,
      port: adapter,
      dimension: ProjectDimension.threeD,
      onRevisionChanged: _adopt,
      onSaved: workspace.acceptSurfConfiguration,
    );
    projectVisuals = ProjectVisualsController(session: session, port: adapter);
    mapVisuals = ProjectVisualsController(session: session, port: adapter);
  }

  final ProjectSession session;
  final LocalMapWorkspaceAdapter adapter;
  late final ProjectAudioController audio;
  late final ProjectCsController abilities;
  late final ProjectSurfController surf;
  late final ProjectVisualsController projectVisuals;
  late final ProjectVisualsController mapVisuals;
  late ProjectMapEntry map;

  void _adopt(String before, String after) {
    audio.adoptRevision(before, after);
    abilities.adoptRevision(before, after);
    surf.adoptRevision(before, after);
  }

  String? get error =>
      audio.error ??
      abilities.error ??
      surf.error ??
      projectVisuals.error ??
      mapVisuals.error;

  Future<void> open(ProjectMapEntry entry) async {
    map = entry;
    await audio.open();
    await abilities.open();
    await surf.open();
    await projectVisuals.open();
    await mapVisuals.open(map: entry);
    expect(error, isNull);
    expect(isImageVisualParameter(SpatialVisualParameter.pitchDegrees), isTrue);
    expect(
      isImageVisualParameter(SpatialVisualParameter.fieldOfViewDegrees),
      isTrue,
    );
    expect(
      isTimeWeatherVisualParameter(SpatialVisualParameter.weatherEnabled),
      isTrue,
    );
  }

  late final gestures = <String, Future<bool> Function(int)>{
    'gain': (repeat) {
      audio.gain(ProjectSoundCue.uiConfirm, '${40 + 10 * repeat}');
      return audio.saveCue(ProjectSoundCue.uiConfirm);
    },
    'image': (repeat) {
      projectVisuals.edit(
        _with(
          projectVisuals.preview.value,
          SpatialVisualParameter.pitchDegrees,
          30 + repeat,
        ),
      );
      return projectVisuals.saveWhere(isImageVisualParameter);
    },
    'map exception': (repeat) {
      mapVisuals.edit(
        _with(
          mapVisuals.preview.value,
          SpatialVisualParameter.fieldOfViewDegrees,
          40 + repeat,
        ),
      );
      return mapVisuals.saveWhere(isImageVisualParameter);
    },
    'map inheritance': (repeat) {
      mapVisuals.edit(
        _without(
          mapVisuals.preview.value,
          SpatialVisualParameter.fieldOfViewDegrees,
        ),
      );
      return mapVisuals.saveWhere(isImageVisualParameter);
    },
    'weather': (repeat) {
      projectVisuals.edit(
        _with(
          projectVisuals.preview.value,
          SpatialVisualParameter.weatherEnabled,
          repeat.isEven,
        ),
      );
      return projectVisuals.saveWhere(isTimeWeatherVisualParameter);
    },
    'field ability': (repeat) {
      abilities.setEnabledId('cut', repeat.isOdd);
      return abilities.save();
    },
    'surf': (repeat) {
      surf.editSpeed(repeat.isEven ? '1,5' : '2');
      return surf.save();
    },
  };

  Future<void> expectReopened(ProjectSession session) async {
    final cold = LocalMapWorkspaceAdapter();
    final reopenedAudio = await cold.loadAudio(session);
    expect(
      reopenedAudio.configuration?.cues[ProjectSoundCue.uiConfirm]?.gain,
      .5,
    );
    final reopenedImage = await cold.loadVisuals(session);
    expect(reopenedImage.profile, projectVisuals.saved!.profile);
    expect(
      reopenedImage.profile.value(SpatialVisualParameter.pitchDegrees),
      31,
    );
    expect(
      reopenedImage.profile.value(SpatialVisualParameter.weatherEnabled),
      false,
    );
    final reopenedMap = await cold.loadVisuals(session, map: map);
    expect(
      reopenedMap.profile.values,
      isNot(contains(SpatialVisualParameter.fieldOfViewDegrees)),
      reason: 'returning to inheritance removes the map exception',
    );
    expect(
      (await cold.loadFieldAbilities(session))
          .configuration
          ?.disabledAbilityIds,
      isNot(contains('cut')),
    );
    expect(
      (await cold.loadSurf(session)).configuration?.speedCellsPerSecond,
      2,
    );
  }

  void dispose() {
    audio.dispose();
    abilities.dispose();
    surf.dispose();
    projectVisuals.dispose();
    mapVisuals.dispose();
  }
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

final class _Work {
  const _Work({
    required this.reads,
    required this.probes,
    required this.definitions,
    required this.writes,
    required this.projectionBuilds,
    required this.notifications,
  });

  final List<String> reads, probes, definitions, writes;
  final int projectionBuilds, notifications;

  List<int> get signature => [
    reads.length,
    probes.length,
    definitions.length,
    writes.length,
    projectionBuilds,
    notifications,
  ];
}

Future<Map<String, String>> _tree(Directory root) async {
  final files = <String, String>{};
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final stat = await entity.stat();
    files[p.relative(entity.path, from: root.path)] =
        '${stat.size}:${stat.modified.microsecondsSinceEpoch}';
  }
  return files;
}

List<String> _changed(Map<String, String> before, Map<String, String> after) =>
    [
      for (final entry in after.entries)
        if (before[entry.key] != entry.value) entry.key,
      for (final path in before.keys)
        if (!after.containsKey(path)) path,
    ]..sort();

final class _Fixture {
  _Fixture(this.root, this.directory, this.session);

  final Directory root;
  final Directory directory;
  final ProjectSession session;

  static Future<_Fixture> create(int unrelated) async {
    final root = await Directory.systemTemp.createTemp('settings-counts-');
    final project = spatialEnvironmentProject().copyWith(
      maps: [
        const ProjectMapEntry(id: 'a', name: 'A', relativePath: 'maps/a.json'),
        for (var i = 0; i < unrelated; i++)
          ProjectMapEntry(
            id: 'foreign-$i',
            name: 'Foreign $i',
            relativePath: 'maps/foreign-$i.json',
          ),
      ],
      models3d: [
        ...spatialEnvironmentProject().models3d,
        for (var i = 0; i < unrelated; i++)
          ProjectModel3dEntry(
            id: 'foreign-model-$i',
            name: 'Foreign $i',
            sourceAssetId: 'foreign-source-$i',
            relativePath: 'assets/models3d/foreign-model-$i.glb',
            inspection: spatialEnvironmentProject().models3d.single.inspection,
          ),
      ],
      dialogues: [
        for (var i = 0; i < unrelated; i++)
          ProjectDialogueEntry(
            id: 'foreign-dialogue-$i',
            name: 'Foreign $i',
            relativePath: 'dialogues/foreign-$i.yarn',
          ),
      ],
      environmentPresets: const [],
    );
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'settings-counts-$unrelated',
      project: project,
    );
    await _write(
      root,
      'maps/a.json',
      jsonEncode(spatialEnvironmentMap().toJson()),
    );
    for (var i = 0; i < unrelated; i++) {
      await _write(
        root,
        'maps/foreign-$i.json',
        jsonEncode(
          spatialEnvironmentMap()
              .copyWith(id: 'foreign-$i', name: 'Foreign $i')
              .toJson(),
        ),
      );
      await _write(
        root,
        'maps/foreign-$i.visual.json',
        jsonEncode(
          SpatialVisualDocument(
            mapId: 'foreign-$i',
            profile: SpatialVisualPatch({
              SpatialVisualParameter.fieldOfViewDegrees: 20 + i,
            }),
          ).toJson(),
        ),
      );
      await _write(root, 'assets/models3d/foreign-model-$i.glb', 'glTF$i');
      await _write(root, 'assets/foreign-$i.png', 'png$i');
      await _write(root, 'assets/audio/foreign-$i.ogg', 'OggS$i');
      await _write(
        root,
        'dialogues/foreign-$i.yarn',
        'title: foreign\n---\n===\n',
      );
    }
    for (final ledger in _ledgers) {
      await _write(
        root,
        '.pokemap/authoring/$ledger',
        'unrelated history must remain unread\n' * (unrelated + 1),
      );
    }
    final directory = Directory(await root.resolveSymbolicLinks());
    return _Fixture(
      root,
      directory,
      ProjectSession(
        sessionId: root.path,
        name: project.name,
        directoryPath: directory.path,
        storage: ProjectSessionStorage.workingCatalog,
      ),
    );
  }

  static Future<void> _write(Directory root, String path, String text) async {
    final file = File('${root.path}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsString(text);
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final reads = <String>[];
  final probes = <String>[];
  final definitions = <String>[];
  final delegate = const LocalProjectFileReader();

  void reset() {
    reads.clear();
    probes.clear();
    definitions.clear();
  }

  void _record(String projectRoot, String relativePath) {
    reads.add(relativePath);
    if (!relativePath.startsWith('catalog/objects/')) return;
    final text = File('$projectRoot/$relativePath').readAsStringSync();
    if (text.startsWith('{"key":')) {
      definitions.add(jsonEncode((jsonDecode(text) as Map)['key']));
    }
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
    probes.add(relativePath);
    return delegate.probeResource(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    _record(projectRoot, relativePath);
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    _record(projectRoot, relativePath);
    return delegate.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

final class _UnreadableFile implements File {
  _UnreadableFile(this.delegate, this.attempts);

  final File delegate;
  final List<String> attempts;

  Never _deny() {
    attempts.add(path);
    throw StateError('Unrelated file opened: $path');
  }

  @override
  String get path => delegate.path;
  @override
  Uri get uri => delegate.uri;
  @override
  bool get isAbsolute => delegate.isAbsolute;
  @override
  File get absolute => delegate.absolute;
  @override
  Directory get parent => delegate.parent;
  @override
  Future<bool> exists() => delegate.exists();
  @override
  Future<FileStat> stat() => delegate.stat();
  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();
  @override
  Future<Uint8List> readAsBytes() async => _deny();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async => _deny();
  @override
  Stream<List<int>> openRead([int? start, int? end]) => _deny();
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      _deny();
  @override
  dynamic noSuchMethod(Invocation invocation) => _deny();
}
