import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/narrative_title_fixture.dart';

void main() {
  Future<({AuthoringReadApi api, OpenedProject opened})> reader(
      NarrativeTitleFixture fixture) async {
    final handles = WorkspaceHandleStore();
    const files = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [fixture.root.path], fileReader: files);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: files, handles: handles),
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    final opened = await api.openProject(fixture.root.path);
    addTearDown(() => api.closeWorkspace(opened.workspaceHandle));
    return (api: api, opened: opened);
  }

  Future<AuthoringQueryPage> query(
      ({AuthoringReadApi api, OpenedProject opened}) read,
      AuthoringQueryRequest request,
      {required bool wire}) async {
    if (!wire) return read.api.queryProject(read.opened.projectHandle, request);
    final result = AuthoringResult.fromJson(
        jsonDecode(await JsonlWorker(api: read.api).processLine(jsonEncode({
      'id': 'titles',
      'command': 'query',
      'args': {
        'projectHandle': read.opened.projectHandle.value,
        'request': request.toJson()
      },
    }))) as Map<String, dynamic>);
    if (result.status != AuthoringResultStatus.success) {
      throw AuthoringQueryException(
          result.error!.details['domainCode'] as String, result.error!.message);
    }
    return AuthoringQueryPage.fromJson(Map<String, dynamic>.from(result.data));
  }

  AuthoringQueryRequest titles(String kind,
          {String? cursor, int pageSize = 200}) =>
      AuthoringQueryRequest(
          resourceKind: narrativeTitleResourceKind,
          operation: AuthoringQueryOperation.list,
          filters: {'kind': kind},
          pageSize: pageSize,
          cursor: cursor);

  Matcher code(String value) => isA<AuthoringQueryException>()
      .having((error) => error.code, 'code', value);

  for (final wire in [false, true]) {
    test('narrative titles page through the derived index JSONL=$wire',
        () async {
      final fixture = await NarrativeTitleFixture.create(facts: 300);
      addTearDown(fixture.close);
      final read = await reader(fixture);
      await expectLater(query(read, titles('facts'), wire: wire),
          throwsA(code('query.narrative_titles_preparation_required')));
      await fixture.prepare();
      final first = await query(read, titles('facts'), wire: wire);
      expect(first.totalAvailable, 300);
      expect(first.items, hasLength(200));
      expect(first.items[130], {
        'kind': 'facts',
        'id': 'fact_fact_130',
        'title': 'Fact 130',
        'tags': <String>[],
        'category': 'quest',
        'valueKind': 'bool',
        'initialValue': false,
        'position': 130,
      });
      final second = await query(
          read, titles('facts', cursor: first.nextCursor),
          wire: wire);
      expect(second.items, hasLength(100));
      expect(second.items.first['position'], 200);
      expect(second.nextCursor, isNull);
      final events = await query(read, titles('narrativeEvents'), wire: wire);
      expect(
          events.items.map((item) => item['title']), ['Wake up', 'Leave home']);
      await expectLater(
          query(read, titles('facts', cursor: first.nextCursor, pageSize: 50),
              wire: wire),
          throwsA(code('query.cursor_mismatch')));
      await expectLater(
          query(
              read,
              AuthoringQueryRequest(
                  resourceKind: narrativeTitleResourceKind,
                  operation: AuthoringQueryOperation.list),
              wire: wire),
          throwsA(code('query.narrative_title_scope_invalid')));
      await fixture.apply('fact.update',
          {'fact': narrativeTitleFact(1, label: 'Renamed').toJson()}, 'rename');
      await expectLater(
          query(read, titles('facts', cursor: first.nextCursor), wire: wire),
          throwsA(code('query.cursor_stale')));
    });
  }
}
