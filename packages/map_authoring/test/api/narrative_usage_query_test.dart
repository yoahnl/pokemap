import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/narrative_title_fixture.dart';
import '../support/narrative_usage_fixture.dart';

void main() {
  Future<AuthoringQueryPage> query(
      NarrativeTitleFixture fixture, AuthoringQueryRequest request,
      {required bool wire}) async {
    final handles = WorkspaceHandleStore();
    const files = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [fixture.root.path], fileReader: files);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: files, handles: handles),
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    final opened = await api.openProject(fixture.root.path);
    try {
      if (!wire) return await api.queryProject(opened.projectHandle, request);
      final result = AuthoringResult.fromJson(
          jsonDecode(await JsonlWorker(api: api).processLine(jsonEncode({
        'id': 'usages',
        'command': 'query',
        'args': {
          'projectHandle': opened.projectHandle.value,
          'request': request.toJson()
        },
      }))) as Map<String, dynamic>);
      if (result.status != AuthoringResultStatus.success) {
        throw AuthoringQueryException(
            result.error!.details['domainCode'] as String,
            result.error!.message);
      }
      return AuthoringQueryPage.fromJson(
          Map<String, dynamic>.from(result.data));
    } finally {
      await api.closeWorkspace(opened.workspaceHandle);
    }
  }

  Matcher code(String value) => isA<AuthoringQueryException>()
      .having((error) => error.code, 'code', value);

  AuthoringQueryRequest facts(List<String> ids) => AuthoringQueryRequest(
      resourceKind: narrativeFactUsersResourceKind,
      operation: AuthoringQueryOperation.batchGet,
      ids: ids);

  for (final wire in [false, true]) {
    test('narrative usages answer with their coverage JSONL=$wire', () async {
      final fixture = await createNarrativeUsageFixture();
      addTearDown(fixture.close);
      await expectLater(query(fixture, facts(['fact_fact_0']), wire: wire),
          throwsA(code('query.narrative_usages_preparation_required')));
      await fixture.prepare(CatalogNarrativeUsages.preparationScope);
      final page =
          await query(fixture, facts(['fact_fact_3', 'none']), wire: wire);
      expect(page.totalAvailable, 2);
      expect(page.items.first['factId'], 'fact_fact_3');
      expect(page.items.first['users'], [
        {'id': 'main', 'kind': 'storyline', 'role': 'cite'},
        {'id': 'world_rule_tree', 'kind': 'worldRule', 'role': 'read'},
      ]);
      expect(page.items.last['users'], isEmpty);
      expect((page.items.first['coverage'] as Map)['notCovered'],
          contains('maps'));
      final owners = await query(
          fixture,
          AuthoringQueryRequest(
              resourceKind: narrativeMapElementOwnersResourceKind,
              operation: AuthoringQueryOperation.get,
              filters: {'mapId': 'town'},
              ids: ['npc']),
          wire: wire);
      expect(owners.items.single['owners'], [
        {'id': 'arrival', 'kind': 'cinematic', 'sourceKind': 'entity'},
        {'id': narrativeTitleEvent(1), 'kind': 'event', 'sourceKind': 'entity'},
      ]);
      await expectLater(
          query(
              fixture,
              AuthoringQueryRequest(
                  resourceKind: narrativeMapElementOwnersResourceKind,
                  operation: AuthoringQueryOperation.get,
                  ids: ['npc']),
              wire: wire),
          throwsA(code('query.narrative_usage_scope_invalid')));
    });
  }
}
