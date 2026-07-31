import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  group('AuthoringQueryAdapter', () {
    test('keeps project and map projections identical to the reference files',
        () async {
      final fixture = _goldenFangameFixture();
      final legacyManifest = ProjectManifest.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
            await File('${fixture.path}/project.json').readAsString(),
          ) as Map,
        ),
      );
      final reader = _CountingReader(const EditorProjectFileReader());
      final adapter = AuthoringQueryAdapter(fileReader: reader);

      final session = await adapter.open(fixture.path);
      addTearDown(session.close);

      expect(session.manifest.toJson(), legacyManifest.toJson());
      expect(
        session.maps.map((map) => map.id),
        ['golden_route', 'golden_summit', 'golden_town'],
      );
      for (final map in session.maps) {
        final entry = legacyManifest.maps.singleWhere(
          (candidate) => candidate.id == map.id,
        );
        final legacyMap = MapData.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(
              await File('${fixture.path}/${entry.relativePath}')
                  .readAsString(),
            ) as Map,
          ),
        );
        expect(map.toJson(), legacyMap.toJson());
      }
      expect(session.snapshotRevision, matches(r'^sha256:[0-9a-f]{64}$'));
    });

    test('paginates and searches the frozen snapshot without rereading files',
        () async {
      final reader = _CountingReader(const EditorProjectFileReader());
      final session = await AuthoringQueryAdapter(fileReader: reader)
          .open(_goldenFangameFixture().path);
      addTearDown(session.close);
      final readsAfterOpen = reader.readCount;

      final first = session.query(
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          pageSize: 2,
        ),
      );
      final second = session.query(
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          pageSize: 2,
          cursor: first['nextCursor']! as String,
        ),
      );
      final search = session.query(
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.search,
          searchTerm: 'golden',
          sort: const [AuthoringQuerySort(field: 'name')],
          pageSize: 10,
        ),
      );

      expect(_ids(first), ['golden_route', 'golden_summit']);
      expect(_ids(second), ['golden_town']);
      expect(_ids(search), ['golden_route', 'golden_summit', 'golden_town']);
      expect(reader.readCount, readsAfterOpen);
    });

    test('reports reference diagnostics and closes handles fail-closed',
        () async {
      final session = await AuthoringQueryAdapter(
        fileReader: const EditorProjectFileReader(),
      ).open(_goldenFangameFixture().path);

      final validation = session.validate();
      expect(validation['snapshotRevision'], session.snapshotRevision);
      expect(validation['references'], isA<Map<String, Object?>>());

      await session.close();
      expect(
        () => session.query(
          AuthoringQueryRequest(
            resourceKind: 'project',
            operation: AuthoringQueryOperation.summary,
          ),
        ),
        throwsStateError,
      );
      await session.close();
    });

    test('shares one Authoring snapshot across project and map repositories',
        () async {
      final fixture = _goldenFangameFixture();
      final reader = _CountingReader(const EditorProjectFileReader());
      final adapter = AuthoringQueryAdapter(fileReader: reader);
      final projects = FileProjectRepository(authoringQueries: adapter);
      final maps = FileMapRepository(authoringQueries: adapter);

      final project =
          await projects.loadProject('${fixture.path}/project.json');
      final readsAfterProject = reader.readCount;
      final mapEntry = project.maps.singleWhere(
        (entry) => entry.id == 'golden_route',
      );
      final document = await maps.loadMapDocument(
        '${fixture.path}/${mapEntry.relativePath}',
      );

      expect(document.map.id, 'golden_route');
      expect(document.revision, matches(r'^sha256:[0-9a-f]{64}$'));
      expect(reader.readCount, readsAfterProject);
      await adapter.closeAll();
    });

    test('opens the reference project inside the read budget', () async {
      final stopwatch = Stopwatch()..start();
      final session = await AuthoringQueryAdapter(
        fileReader: const EditorProjectFileReader(),
      ).open(_goldenFangameFixture().path);
      stopwatch.stop();
      await session.close();

      // This is deliberately a generous regression ceiling, not a benchmark.
      // The immutable snapshot performs two filesystem passes by design.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('opens the large Selbrume workspace inside the regression budget',
        () async {
      final stopwatch = Stopwatch()..start();
      final reader = _CountingReader(const EditorProjectFileReader());
      final session =
          await AuthoringQueryAdapter(fileReader: reader).open(_selbrume().path);
      stopwatch.stop();
      addTearDown(session.close);
      final readsAfterOpen = reader.readCount;

      final page = session.query(
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          pageSize: 100,
        ),
      );
      final dialogues = session.query(
        AuthoringQueryRequest(
          resourceKind: 'dialogue',
          operation: AuthoringQueryOperation.list,
          pageSize: 100,
        ),
      );
      final scenes = session.query(
        AuthoringQueryRequest(
          resourceKind: 'scene',
          operation: AuthoringQueryOperation.list,
          pageSize: 100,
        ),
      );

      expect(session.maps, hasLength(10));
      expect(page['totalAvailable'], 10);
      expect(dialogues['totalAvailable'], 24);
      expect(scenes['totalAvailable'], 35);
      expect(reader.readCount, readsAfterOpen);
      // Selbrume contains thousands of project files and large media assets.
      // Authoring reads only declared structured resources; this generous
      // ceiling guards an accidental workspace crawl without being a benchmark.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));
    });
  });
}

Directory _goldenFangameFixture() => Directory(
      '${Directory.current.parent.parent.path}/examples/'
      'playable_runtime_host/golden_fangame_slice',
    );

Directory _selbrume() => Directory(
      '${Directory.current.parent.parent.path}/selbrume',
    );

List<String> _ids(Map<String, Object?> page) => [
      for (final item in page['items']! as List<Object?>)
        (item! as Map<String, Object?>)['id']! as String,
    ];

final class _CountingReader implements ProjectFileReader {
  _CountingReader(this.delegate);

  final ProjectFileReader delegate;
  int readCount = 0;

  @override
  Future<String> canonicalizeDirectory(String path) {
    return delegate.canonicalizeDirectory(path);
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    readCount++;
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
