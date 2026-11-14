import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/catalog_unit_reads.dart';
import '../support/map_directory_fixture.dart';
import '../support/narrative_title_fixture.dart';

void main() {
  Future<AuthoringQueryPage> query(
      NarrativeTitleFixture fixture, String kind, List<String> ids,
      {bool wire = false,
      Future<void> Function(Future<void> Function() read)? measure}) async {
    final handles = WorkspaceHandleStore();
    const files = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [fixture.root.path], fileReader: files);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy,
            fileReader: files,
            handles: handles,
            catalogMetadataFields: const {}),
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    final opened = await api.openProject(fixture.root.path);
    final request = AuthoringQueryRequest(
        resourceKind: kind,
        operation: kind == sceneDocumentResourceKind
            ? AuthoringQueryOperation.get
            : AuthoringQueryOperation.batchGet,
        view: kind == sceneDocumentResourceKind
            ? AuthoringQueryView.detail
            : AuthoringQueryView.summary,
        ids: ids);
    try {
      if (measure != null) {
        late AuthoringQueryPage page;
        await measure(() async =>
            page = await api.queryProject(opened.projectHandle, request));
        return page;
      }
      if (!wire) return await api.queryProject(opened.projectHandle, request);
      final result = AuthoringResult.fromJson(
          jsonDecode(await JsonlWorker(api: api).processLine(jsonEncode({
        'id': 'scene-document',
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

  for (final wire in [false, true]) {
    test(
        'a scene reads with its dialogues, behaviours and map names '
        'JSONL=$wire', () async {
      final fixture = await createMapDirectoryFixture();
      addTearDown(fixture.close);
      await expectLater(
          query(fixture, sceneDocumentResourceKind, ['scene_talk'], wire: wire),
          throwsA(code('query.map_directory_preparation_required')));
      await fixture.prepare(CatalogMapDirectory.preparationScope);

      final item = (await query(
              fixture, sceneDocumentResourceKind, ['scene_talk'],
              wire: wire))
          .items
          .single;
      expect((item['scene'] as Map)['id'], 'scene_talk');
      final dialogue = (item['dialogues'] as List).single as Map;
      expect((dialogue['entry'] as Map)['id'], 'greet');
      expect(dialogue['source'], contains('Welcome to the lab.'));
      expect(
          dialogue['revision'],
          narrativeEventBytesFingerprint(
              await File('${fixture.root.path}/dialogues/greet.yarn')
                  .readAsBytes()));
      expect(
          (((item['events'] as List).single as Map)['definition'] as Map)['id'],
          narrativeTitleEvent(7));
      final directory = (item['mapDirectory'] as List).single as Map;
      expect(directory['mapId'], 'map_0');
      expect(((directory['elements'] as List).first as Map)['characterId'],
          'character_0');
      expect((item['reads'] as Map)['maps'], 0);

      final pages = await query(
          fixture, mapDirectoryResourceKind, ['map_0', 'map_1'],
          wire: wire);
      expect(pages.items.map((page) => page['name']), ['Map 0', 'Map 1']);
      await expectLater(
          query(fixture, mapDirectoryResourceKind, ['map_9'], wire: wire),
          throwsA(code('query.resource_not_found')));
    });
  }

  test('reading a scene opens no map file whatever the project size', () async {
    Future<({Map<String, int> units, int mapFiles})> reads(int maps) async {
      final fixture = await createMapDirectoryFixture(maps: maps);
      try {
        await fixture.prepare(CatalogMapDirectory.preparationScope);
        var mapFiles = 0;
        late Map<String, int> units;
        await query(fixture, sceneDocumentResourceKind, ['scene_talk'],
            measure: (read) async {
          final outside = Zone.current;
          await IOOverrides.runZoned(() async {
            units = await CatalogUnitReads(fixture.root).count(read);
          }, createFile: (path) {
            if (path.contains('/maps/')) mapFiles++;
            return outside.run(() => File(path));
          });
        });
        return (units: units, mapFiles: mapFiles);
      } finally {
        await fixture.close();
      }
    }

    final small = await reads(2);
    final large = await reads(60);
    printOnFailure(jsonEncode({'small': small.units, 'large': large.units}));
    expect(small.mapFiles, 0);
    expect(large.mapFiles, 0);
    expect(large.units, small.units);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
