import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSnapshotLoader', () {
    test('loads the manifest and maps from the real fixture', () async {
      final fixture = _realFixtureDirectory();
      final harness = await _SnapshotHarness.create(
        allowedRoot: fixture.parent,
      );
      final opened = await harness.openService.openProject(fixture.path);

      final snapshot = await harness.loader.load(opened.projectHandle);

      expect(snapshot.manifest.name, 'P3 Narrative Smoke Slice');
      expect(snapshot.maps, hasLength(1));
      expect(snapshot.maps.single.id, 'p3_narrative_smoke_map');
      expect(
          snapshot.mapById('p3_narrative_smoke_map'), same(snapshot.maps[0]));
      expect(snapshot.revision, matches(r'^sha256:[0-9a-f]{64}$'));
      expect(
        snapshot.resourceFingerprints.keys,
        ['map:p3_narrative_smoke_map', 'project'],
      );
      expect(
        snapshot.resourceFingerprints.values,
        everyElement(matches(r'^sha256:[0-9a-f]{64}$')),
      );
    });

    test('optionally profiles snapshot phases without changing the result',
        () async {
      final fixture = _realFixtureDirectory();
      final profiles = <ProjectSnapshotLoadProfile>[];
      final profiledHarness = await _SnapshotHarness.create(
        allowedRoot: fixture.parent,
        profileSink: profiles.add,
      );
      final profiledOpen =
          await profiledHarness.openService.openProject(fixture.path);

      final profiled =
          await profiledHarness.loader.load(profiledOpen.projectHandle);

      expect(profiles, hasLength(1));
      final profile = profiles.single;
      final phaseMicroseconds = <int>[
        profile.initialReadMicroseconds,
        profile.decodeModelMicroseconds,
        profile.secondObservationMicroseconds,
        profile.fingerprintMicroseconds,
        profile.projectionMicroseconds,
      ];
      expect(phaseMicroseconds, everyElement(greaterThanOrEqualTo(0)));
      expect(profile.totalMicroseconds, greaterThanOrEqualTo(0));
      expect(
        phaseMicroseconds.fold<int>(0, (total, value) => total + value),
        lessThanOrEqualTo(profile.totalMicroseconds),
      );
      expect(profile.resourceCount, profiled.resourceFingerprints.length);
      expect(
        profile.resourceBytes,
        profiled.resourceFingerprints.keys.fold<int>(
          0,
          (total, identity) => total + profiled.resourceBytes(identity).length,
        ),
      );

      final plainHarness = await _SnapshotHarness.create(
        allowedRoot: fixture.parent,
      );
      final plainOpen =
          await plainHarness.openService.openProject(fixture.path);
      final plain = await plainHarness.loader.load(plainOpen.projectHandle);

      expect(profiles, hasLength(1));
      expect(plain.revision, profiled.revision);
      expect(plain.manifest, profiled.manifest);
      expect(plain.maps, profiled.maps);
      expect(plain.resourceFingerprints, profiled.resourceFingerprints);
      for (final identity in profiled.resourceFingerprints.keys) {
        expect(plain.resourceBytes(identity), profiled.resourceBytes(identity));
      }
    });

    test('returns the same revision and deterministic map order on reload',
        () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_snapshot_order_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await _writeProject(
        sandbox,
        mapEntries: [
          _mapEntry('z-map', 'maps/z.json'),
          _mapEntry('a-map', 'maps/a.json'),
        ],
        maps: [
          _mapJson('z-map'),
          _mapJson('a-map'),
        ],
      );
      final harness = await _SnapshotHarness.create(allowedRoot: sandbox);
      final opened = await harness.openService.openProject(project.path);

      final first = await harness.loader.load(opened.projectHandle);
      final second = await harness.loader.load(opened.projectHandle);

      expect(second.revision, first.revision);
      expect(first.maps.map((map) => map.id), ['a-map', 'z-map']);
      expect(
        () => first.maps.add(first.maps.first),
        throwsUnsupportedError,
      );
      expect(
        () => first.resourceFingerprints['project'] = 'changed',
        throwsUnsupportedError,
      );
    });

    test('rejects a resource changed during the two-pass load', () async {
      final fixture = _realFixtureDirectory();
      final reader = _ChangingProjectReader(
        delegate: const LocalProjectFileReader(),
        changeProjectJsonOnRead: 3,
      );
      final harness = await _SnapshotHarness.create(
        allowedRoot: fixture.parent,
        reader: reader,
      );
      final opened = await harness.openService.openProject(fixture.path);

      await expectLater(
        () => harness.loader.load(opened.projectHandle),
        throwsA(
          isA<ProjectSnapshotException>().having(
            (error) => error.code,
            'code',
            'project.changed_during_snapshot',
          ),
        ),
      );
    });

    test('rejects a missing item catalog when the project references items',
        () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_snapshot_items_missing_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await _writeProject(
        sandbox,
        mapEntries: const [],
        maps: const [],
        initialBag: const <Map<String, Object?>>[
          <String, Object?>{'itemId': 'thread-charm', 'quantity': 1},
        ],
      );
      final harness = await _SnapshotHarness.create(allowedRoot: sandbox);
      final opened = await harness.openService.openProject(project.path);

      await expectLater(
        () => harness.loader.load(opened.projectHandle),
        throwsA(
          isA<ProjectSnapshotException>().having(
            (error) => error.code,
            'code',
            'project.item_catalog_missing',
          ),
        ),
      );
    });

    test('loads the strict item catalog into the coherent snapshot', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_snapshot_items_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await _writeProject(
        sandbox,
        mapEntries: const [],
        maps: const [],
        itemCatalog: const <String, Object?>{
          'schemaVersion': 1,
          'entries': <Object?>[
            <String, Object?>{
              'id': 'thread-charm',
              'displayName': 'Thread Charm',
              'pocketId': 'custom',
            },
          ],
        },
      );
      final harness = await _SnapshotHarness.create(allowedRoot: sandbox);
      final opened = await harness.openService.openProject(project.path);

      final snapshot = await harness.loader.load(opened.projectHandle);

      expect(snapshot.itemCatalog!.entries.single.id, 'thread-charm');
      expect(
        snapshot.resourceFingerprints,
        contains(itemCatalogResourceIdentity),
      );
      expect(
        snapshot.resourceStorageKeys[itemCatalogResourceIdentity],
        'data/pokemon/catalogs/items.json',
      );
    });

    test('rejects duplicate manifest map IDs', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_snapshot_duplicate_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await _writeProject(
        sandbox,
        mapEntries: [
          _mapEntry('same', 'maps/first.json'),
          _mapEntry('same', 'maps/second.json'),
        ],
        maps: [
          _mapJson('same'),
          _mapJson('same'),
        ],
      );
      final harness = await _SnapshotHarness.create(allowedRoot: sandbox);
      final opened = await harness.openService.openProject(project.path);

      await expectLater(
        () => harness.loader.load(opened.projectHandle),
        throwsA(
          isA<ProjectSnapshotException>().having(
            (error) => error.code,
            'code',
            'project.duplicate_map_id',
          ),
        ),
      );
    });

    test('rejects a map whose document ID differs from the manifest', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_snapshot_mismatch_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await _writeProject(
        sandbox,
        mapEntries: [_mapEntry('expected', 'maps/field.json')],
        maps: [_mapJson('actual')],
      );
      final harness = await _SnapshotHarness.create(allowedRoot: sandbox);
      final opened = await harness.openService.openProject(project.path);

      await expectLater(
        () => harness.loader.load(opened.projectHandle),
        throwsA(
          isA<ProjectSnapshotException>().having(
            (error) => error.code,
            'code',
            'project.map_identity_mismatch',
          ),
        ),
      );
    });

    test('rejects an unknown project handle', () async {
      final fixture = _realFixtureDirectory();
      final harness = await _SnapshotHarness.create(
        allowedRoot: fixture.parent,
      );

      await expectLater(
        () => harness.loader.load(const ProjectHandle('prj_unknown')),
        throwsA(isA<WorkspaceHandleException>()),
      );
    });

    test('tracks external dialogue sources in the coherent revision', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_snapshot_dialogue_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await _writeProject(
        sandbox,
        mapEntries: const [],
        maps: const [],
        dialogueEntries: const [
          {
            'id': 'intro',
            'name': 'Intro',
            'relativePath': 'dialogues/intro.yarn',
          },
        ],
        dialogueSources: const {
          'dialogues/intro.yarn': 'title: Start\n---\nBonjour\n===\n',
        },
      );
      final harness = await _SnapshotHarness.create(allowedRoot: sandbox);
      final opened = await harness.openService.openProject(project.path);

      final first = await harness.loader.load(opened.projectHandle);
      await File(_join(project.path, 'dialogues', 'intro.yarn')).writeAsString(
        'title: Start\n---\nBonjour encore\n===\n',
      );
      final second = await harness.loader.load(opened.projectHandle);

      expect(
        first.resourceFingerprints,
        contains(dialogueSourceResourceIdentity('intro')),
      );
      expect(second.revision, isNot(first.revision));
      expect(
        utf8.decode(
            second.resourceBytes(dialogueSourceResourceIdentity('intro'))),
        contains('Bonjour encore'),
      );
    });

    test('editor projection keeps maps readable and reports missing dialogue',
        () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_snapshot_editor_projection_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await _writeProject(
        sandbox,
        mapEntries: [_mapEntry('field', 'maps/field.json')],
        maps: [_mapJson('field')],
        dialogueEntries: const [
          {
            'id': 'missing',
            'name': 'Missing',
            'relativePath': 'dialogues/missing.yarn',
          },
        ],
      );
      final harness = await _SnapshotHarness.create(allowedRoot: sandbox);
      final opened = await harness.openService.openProject(project.path);

      await expectLater(
        () => harness.loader.load(opened.projectHandle),
        throwsA(
          isA<ProjectSnapshotException>().having(
            (error) => error.code,
            'code',
            'project.dialogue_source_missing',
          ),
        ),
      );

      final projected = await harness.loader.load(
        opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.editorReadProjection,
      );

      expect(projected.maps.single.id, 'field');
      expect(
        projected.loadDiagnostics.single.toJson(),
        {
          'code': 'project.dialogue_source_missing',
          'resourceKind': 'dialogueSource',
          'resourceId': 'missing',
          'blocking': true,
        },
      );
      expect(
        projected.resourceFingerprints,
        isNot(contains(dialogueSourceResourceIdentity('missing'))),
      );
    });

    test('rejects duplicate direct snapshot maps and invalid fingerprints', () {
      final map = MapData(
        id: 'same',
        name: 'Same',
        size: const GridSize(width: 1, height: 1),
        layers: const [],
      );
      final manifest = ProjectManifest(
        name: 'Direct Snapshot',
        maps: const [],
        tilesets: const [],
      );

      expect(
        () => ProjectSnapshot(
          projectHandle: const ProjectHandle('prj_direct'),
          revision: 'sha256:${List.filled(64, 'a').join()}',
          manifest: manifest,
          maps: [map, map],
          resourceFingerprints: {
            'project': 'sha256:${List.filled(64, 'b').join()}',
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => ProjectSnapshot(
          projectHandle: const ProjectHandle('prj_direct'),
          revision: 'sha256:${List.filled(64, 'a').join()}',
          manifest: manifest,
          maps: const [],
          resourceFingerprints: const {'project': 'not-a-fingerprint'},
        ),
        throwsArgumentError,
      );
    });
  });
}

final class _SnapshotHarness {
  const _SnapshotHarness({
    required this.openService,
    required this.loader,
  });

  static Future<_SnapshotHarness> create({
    required Directory allowedRoot,
    ProjectFileReader reader = const LocalProjectFileReader(),
    ProjectSnapshotLoadProfileSink? profileSink,
  }) async {
    var token = 0;
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [allowedRoot.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      clock: () => DateTime.utc(2026, 7, 31, 12),
      tokenFactory: (prefix) => '$prefix${token++}',
    );
    return _SnapshotHarness(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      loader: ProjectSnapshotLoader(
        handles: handles,
        profileSink: profileSink,
      ),
    );
  }

  final ProjectOpenService openService;
  final ProjectSnapshotLoader loader;
}

final class _ChangingProjectReader implements ProjectFileReader {
  _ChangingProjectReader({
    required this.delegate,
    required this.changeProjectJsonOnRead,
  });

  final ProjectFileReader delegate;
  final int changeProjectJsonOnRead;
  int _projectJsonReads = 0;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    final bytes = await delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    if (relativePath == 'project.json') {
      _projectJsonReads++;
      if (_projectJsonReads == changeProjectJsonOnRead) {
        return [...bytes, ...utf8.encode(' ')];
      }
    }
    return bytes;
  }
}

Future<Directory> _writeProject(
  Directory sandbox, {
  required List<Map<String, Object?>> mapEntries,
  required List<Map<String, Object?>> maps,
  List<Map<String, Object?>> dialogueEntries = const [],
  Map<String, String> dialogueSources = const {},
  List<Map<String, Object?>> initialBag = const [],
  Map<String, Object?>? itemCatalog,
}) async {
  final project = await Directory(_join(sandbox.path, 'project')).create();
  final mapsDirectory =
      await Directory(_join(project.path, 'maps')).create(recursive: true);
  final manifest = {
    'name': 'Snapshot Test',
    'version': 'v6',
    'maps': mapEntries,
    'tilesets': <Object?>[],
    'dialogues': dialogueEntries,
    'newGame': <String, Object?>{'initialBag': initialBag},
  };
  await File(_join(project.path, 'project.json'))
      .writeAsString(jsonEncode(manifest));
  for (var index = 0; index < mapEntries.length; index++) {
    final fileName =
        (mapEntries[index]['relativePath']! as String).split('/').last;
    await File(_join(mapsDirectory.path, fileName))
        .writeAsString(jsonEncode(maps[index]));
  }
  for (final entry in dialogueSources.entries) {
    final file = File(_join(project.path, entry.key));
    await file.parent.create(recursive: true);
    await file.writeAsString(entry.value);
  }
  if (itemCatalog != null) {
    final file = File(
      _join(project.path, 'data', 'pokemon', 'catalogs/items.json'),
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(itemCatalog));
  }
  return project;
}

Map<String, Object?> _mapEntry(String id, String relativePath) => {
      'id': id,
      'name': id,
      'relativePath': relativePath,
      'role': 'exterior',
      'sortOrder': 0,
    };

Map<String, Object?> _mapJson(String id) => {
      'id': id,
      'name': id,
      'size': {'width': 2, 'height': 2},
      'version': 'v6',
      'layers': <Object?>[],
    };

Directory _realFixtureDirectory() {
  return Directory(
    _join(
      Directory.current.parent.parent.path,
      'examples',
      'playable_runtime_host',
      'p3_narrative_smoke_slice',
    ),
  );
}

String _join(
  String first,
  String second, [
  String? third,
  String? fourth,
]) =>
    [
      first,
      second,
      if (third != null) third,
      if (fourth != null) fourth,
    ].join(Platform.pathSeparator);
