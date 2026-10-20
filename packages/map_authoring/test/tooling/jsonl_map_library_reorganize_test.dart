import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/compiled_dart_executable.dart';

const _groups = [
  {
    'id': 'world',
    'name': 'Monde',
    'type': 'special',
    'sortOrder': 2,
  },
  {
    'id': 'area',
    'name': 'Secteur',
    'type': 'cave',
    'parentGroupId': 'world',
    'sortOrder': 5,
    'tags': ['exploration'],
  },
  {
    'id': 'interiors',
    'name': 'Intérieurs',
    'type': 'facility',
    'parentGroupId': 'area',
    'sortOrder': 3,
  },
];

const _organization = {
  'groups': _groups,
  'assignments': [
    {'mapId': 'town', 'groupId': 'world', 'sortOrder': 2},
    {'mapId': 'cave', 'groupId': 'area', 'sortOrder': 1},
    {'mapId': 'house', 'groupId': 'interiors', 'sortOrder': 0},
  ],
};

void main() {
  test(
      'JSONL organizes nested groups, replays once and undoes after cold reopen',
      () async {
    final fixture = await _LibraryFixture.create();
    addTearDown(fixture.dispose);
    final before = await fixture.authoredBytes();
    final session = await _LibrarySession.start(fixture.root);
    final described = await session.send('describe');
    final descriptor = (described.data['mutationActions']! as List)
        .map(_record)
        .singleWhere((action) => action['id'] == 'map.library.reorganize');
    expect(descriptor['version'], 1);
    final initial = await session.project();
    final plan = await session.plan(_organization);
    _success(plan);
    expect(await fixture.authoredBytes(), before);
    expect(
      _record(plan.data['plan'])['referenceImpact'],
      containsPair('mapContentUnchanged', true),
    );

    final applied = await session.apply(plan, 'organize-once');
    _success(applied);
    final receipt = _record(applied.data['receipt']);
    expect(receipt['actionId'], 'map.library.reorganize');
    expect(receipt['status'], 'applied');
    final queried = await session.project();
    _expectOrganization(queried.data);
    expect(await fixture.mapBytes(), fixture.initialMapBytes);

    final after = await fixture.authoredBytes();
    final replayed = await session.apply(plan, 'organize-once');
    _success(replayed);
    expect(replayed.data, applied.data);
    expect(await fixture.authoredBytes(), after);
    expect((await session.history()).data['entries'], hasLength(1));
    await session.finish();

    final reopened = await _LibrarySession.start(fixture.root);
    _expectOrganization((await reopened.project()).data);
    expect((await reopened.history()).data['entries'], hasLength(1));
    final undone = await reopened.send('undo', {
      'projectHandle': reopened.projectHandle,
      'entryId': receipt['receiptId'],
      'idempotencyKey': 'undo-library-after-reopen',
    });
    _success(undone);
    expect(await fixture.authoredBytes(), before);
    expect(
      (await reopened.project()).data['items'],
      initial.data['items'],
    );
    expect(await fixture.mapBytes(), fixture.initialMapBytes);
    await reopened.finish();
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('JSONL assignments preserve folders and refuse applying a no-op',
      () async {
    final fixture = await _LibraryFixture.create();
    addTearDown(fixture.dispose);
    final session = await _LibrarySession.start(fixture.root);
    _success(await session.apply(await session.plan(_organization), 'initial'));
    final beforeGroups =
        _projectDetail((await session.project()).data)['groups'];
    const assignments = {
      'assignments': [
        {'mapId': 'town', 'groupId': null, 'sortOrder': 9},
      ],
    };
    final plan = await session.plan(assignments);
    _success(plan);
    _success(await session.apply(plan, 'unassign-town'));
    final project = _projectDetail((await session.project()).data);
    expect(project['groups'], beforeGroups);
    expect(
      _records(project['groups']).map((group) => group['id']),
      ['world', 'area', 'interiors'],
    );
    final maps = _records(project['maps']);
    expect(maps.singleWhere((map) => map['id'] == 'town')['groupId'], isNull);
    expect(maps.singleWhere((map) => map['id'] == 'town')['sortOrder'], 9);
    expect(maps.singleWhere((map) => map['id'] == 'cave')['groupId'], 'area');
    expect(maps.singleWhere((map) => map['id'] == 'cave')['sortOrder'], 1);
    expect(maps.singleWhere((map) => map['id'] == 'house')['groupId'],
        'interiors');
    final beforeNoOp = await fixture.authoredBytes();
    final noOp = await session.plan(assignments);
    _success(noOp);
    expect(_record(noOp.data['plan'])['applicable'], isFalse);
    expect(_record(noOp.data['plan'])['nonApplicableReason'], 'no_changes');
    final rejected = await session.apply(noOp, 'no-op');
    _failure(rejected, 'plan.no_changes');
    expect(await fixture.authoredBytes(), beforeNoOp);
    expect(await fixture.mapBytes(), fixture.initialMapBytes);
    expect((await session.history()).data['entries'], hasLength(2));
    await session.finish();
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('JSONL refuses invalid assignments and cyclic folders atomically',
      () async {
    final fixture = await _LibraryFixture.create();
    addTearDown(fixture.dispose);
    final session = await _LibrarySession.start(fixture.root);
    final before = await fixture.authoredBytes();
    final initial = await session.project();
    final cases = <(Map<String, Object?>, String)>[
      (
        {
          'assignments': [
            {'mapId': 'missing', 'groupId': null},
          ],
        },
        'map.library.assignment_invalid'
      ),
      (
        {
          'assignments': [
            {'mapId': 'town', 'groupId': 'missing'},
          ],
        },
        'map.library.assignment_invalid'
      ),
      (
        {
          'assignments': [
            {'mapId': 'town', 'groupId': null},
            {'mapId': 'town', 'groupId': null},
          ],
        },
        'map.library.assignment_invalid'
      ),
      (
        {
          'groups': [
            {'id': 'a', 'name': 'A', 'type': 'city', 'parentGroupId': 'b'},
            {'id': 'b', 'name': 'B', 'type': 'city', 'parentGroupId': 'a'},
          ],
          'assignments': <Object?>[],
        },
        'validation.failed'
      ),
      (
        {
          'groups': [
            {
              'id': 'a',
              'name': 'A',
              'type': 'city',
              'parentGroupId': 'missing'
            },
          ],
          'assignments': <Object?>[],
        },
        'validation.failed'
      ),
    ];
    for (final (parameters, code) in cases) {
      final result = await session.plan(parameters);
      _failure(result, code);
      expect(result.data, isEmpty);
      expect(await fixture.authoredBytes(), before);
      expect((await session.project()).data, initial.data);
      expect((await session.history()).data['entries'], isEmpty);
    }
    await session.finish();
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('JSONL refuses stale apply and removal of a referenced folder',
      () async {
    final fixture = await _LibraryFixture.create();
    addTearDown(fixture.dispose);
    final session = await _LibrarySession.start(fixture.root);
    final winner = await session.plan(_organization);
    final stale = await session.plan({
      'assignments': [
        {'mapId': 'town', 'groupId': null, 'sortOrder': 20},
      ],
    });
    _success(winner);
    _success(stale);
    _success(await session.apply(winner, 'winner'));
    final after = await fixture.authoredBytes();
    final rejected = await session.apply(stale, 'stale-library');
    _failure(rejected, 'plan.stale');
    expect(rejected.error!.code, AuthoringErrorCode.revisionConflict);
    expect(rejected.error!.retryable, isTrue);
    expect(await fixture.authoredBytes(), after);
    final removal = await session.plan({
      'groups': <Object?>[],
      'assignments': <Object?>[],
    });
    _failure(removal, 'map.library.group_not_empty');
    expect(await fixture.authoredBytes(), after);
    expect(await fixture.mapBytes(), fixture.initialMapBytes);
    _expectOrganization((await session.project()).data);
    expect((await session.history()).data['entries'], hasLength(1));
    await session.finish();
  }, timeout: const Timeout(Duration(minutes: 2)));
}

void _success(AuthoringResult result) => expect(
      result.status,
      AuthoringResultStatus.success,
      reason: jsonEncode(result.toJson()),
    );

void _failure(AuthoringResult result, String code) {
  expect(result.status, AuthoringResultStatus.failure,
      reason: jsonEncode(result.toJson()));
  expect(result.error!.details['domainCode'], code);
  expect(result.receipt, isNull);
}

Map<String, Object?> _record(Object? value) =>
    Map<String, Object?>.from(value! as Map);

List<Map<String, Object?>> _records(Object? value) =>
    (value! as List).map(_record).toList();

Map<String, Object?> _projectDetail(Map<String, Object?> data) =>
    _records(data['items']).single;

void _expectOrganization(Map<String, Object?> data) {
  final detail = _projectDetail(data);
  final groups = _records(detail['groups']);
  expect(groups.map((group) => group['id']), ['world', 'area', 'interiors']);
  expect(
      groups.map((group) => group['name']), ['Monde', 'Secteur', 'Intérieurs']);
  expect(groups.map((group) => group['type']), ['special', 'cave', 'facility']);
  expect(groups.map((group) => group['sortOrder']), [2, 5, 3]);
  expect(groups[0]['parentGroupId'], isNull);
  expect(groups[1]['parentGroupId'], 'world');
  expect(groups[2]['parentGroupId'], 'area');
  expect(groups[1]['tags'], ['exploration']);
  final maps = _records(detail['maps']);
  expect(maps.map((map) => map['id']), ['town', 'cave', 'house']);
  expect(maps.map((map) => map['groupId']), ['world', 'area', 'interiors']);
  expect(maps.map((map) => map['sortOrder']), [2, 1, 0]);
}

final class _LibraryFixture {
  _LibraryFixture(this.root, this.initialMapBytes);

  final Directory root;
  final Map<String, List<int>> initialMapBytes;

  static Future<_LibraryFixture> create() async {
    final root = await Directory.systemTemp.createTemp('jsonl-map-library-');
    final directory = await Directory('${root.path}/documents').create();
    final maps = <ProjectMapEntry>[];
    final bytes = <String, List<int>>{};
    for (final (index, id) in ['town', 'cave', 'house'].indexed) {
      final map = MapData(
        id: id,
        name: id,
        version: ProjectVersion.v8,
        size: const GridSize(width: 3, height: 2),
        layers: const [
          CollisionLayer(
            id: 'collision',
            name: 'Collision',
            collisions: [false, true, false, true, false, true],
          ),
        ],
        properties: {'preserved': 'content-$id'},
      );
      final encoded = encodeMapAuthoringDocument(map);
      await File('${directory.path}/$id.json').writeAsBytes(encoded);
      bytes[id] = encoded;
      maps.add(ProjectMapEntry(
        id: id,
        name: id,
        relativePath: 'documents/$id.json',
        sortOrder: index + 7,
      ));
    }
    final manifest = ProjectManifest(
      name: 'JSONL map library',
      version: ProjectVersion.v8,
      maps: maps,
      tilesets: const [],
    );
    await File('${root.path}/project.json')
        .writeAsString('${jsonEncode(manifest.toJson())}\n');
    return _LibraryFixture(root, bytes);
  }

  Future<Map<String, List<int>>> mapBytes() async => {
        for (final id in initialMapBytes.keys)
          id: await File('${root.path}/documents/$id.json').readAsBytes(),
      };

  Future<Map<String, List<int>>> authoredBytes() async => {
        'project': await File('${root.path}/project.json').readAsBytes(),
        ...await mapBytes(),
      };

  Future<void> dispose() => root.delete(recursive: true);
}

final class _LibrarySession {
  _LibrarySession(this._process)
      : _lines = StreamIterator(
          _process.stdout
              .transform(utf8.decoder)
              .transform(const LineSplitter()),
        ),
        _stderr = _process.stderr.transform(utf8.decoder).join();

  final Process _process;
  final StreamIterator<String> _lines;
  final Future<String> _stderr;
  late String projectHandle;
  late String workspaceHandle;
  int _sequence = 0;
  bool _finished = false;

  static Future<_LibrarySession> start(Directory root) async {
    final session = _LibrarySession(await Process.start(
      Platform.resolvedExecutable,
      ['run', 'bin/pokemap_authoring.dart', '--root', root.path],
      workingDirectory: Directory.current.path,
    ));
    addTearDown(session.dispose);
    final opened = await session.send('open', {'projectRoot': root.path});
    _success(opened);
    session.projectHandle = opened.data['projectHandle']! as String;
    session.workspaceHandle = opened.data['workspaceHandle']! as String;
    return session;
  }

  Future<AuthoringResult> send(String command,
      [Map<String, Object?> args = const {}]) async {
    final id = 'library-wire-${++_sequence}';
    _process.stdin
        .writeln(jsonEncode({'id': id, 'command': command, 'args': args}));
    await _process.stdin.flush();
    final available =
        await _lines.moveNext().timeout(const Duration(seconds: 30));
    if (!available) {
      fail('The CLI closed before replying: '
          'exit ${await _process.exitCode}, stderr: ${await _stderr}');
    }
    final response = AuthoringResult.fromJson(
      Map<String, dynamic>.from(jsonDecode(_lines.current) as Map),
    );
    expect(response.requestId, id);
    return response;
  }

  Future<AuthoringResult> project() => send('query', {
        'projectHandle': projectHandle,
        'request': AuthoringQueryRequest(
          resourceKind: 'project',
          operation: AuthoringQueryOperation.get,
          view: AuthoringQueryView.detail,
          ids: const ['project'],
        ).toJson(),
      });

  Future<AuthoringResult> plan(Map<String, Object?> parameters) async {
    final queried = await project();
    _success(queried);
    final key = 'library-plan-${_sequence + 1}';
    return send('plan', {
      'projectHandle': projectHandle,
      'request': AuthoringRequest(
        requestId: key,
        actionId: 'map.library.reorganize',
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: parameters,
        expectedRevision: queried.data['snapshotRevision']! as String,
        idempotencyKey: key,
      ).toJson(),
    });
  }

  Future<AuthoringResult> apply(AuthoringResult plan, String operationId) =>
      send('apply', {
        'projectHandle': projectHandle,
        'planId': plan.data['planId'],
        'operationId': operationId,
      });

  Future<AuthoringResult> history() =>
      send('history', {'projectHandle': projectHandle, 'limit': 20});

  Future<void> finish() async {
    final closed = await send('close', {'workspaceHandle': workspaceHandle});
    _success(closed);
    await _process.stdin.close();
    expect(await _process.exitCode.timeout(const Duration(seconds: 10)), 0);
    await _lines.cancel();
    expect(await _stderr, isEmpty);
    _finished = true;
  }

  Future<void> dispose() async {
    if (_finished) return;
    await _process.stdin.close();
    try {
      await _process.exitCode.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      await CompiledDartExecutable.terminate(_process);
    }
    await _lines.cancel();
    await _stderr;
    _finished = true;
  }
}
