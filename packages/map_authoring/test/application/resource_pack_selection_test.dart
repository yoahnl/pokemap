import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_pack_export_test.dart' show mixedFixture;
import '../domains/assets/resource_pack_import_fixture.dart';

void main() {
  test('native context family and label filters preserve hidden selections and bound escaped pages', () async {
    final base = mixedFixture().$1.environmentPresets.single;
    final target = ProjectManifest(
      name: 'Filters',
      maps: [],
      tilesets: [],
      settings: ProjectSettings(tileWidth: 2, tileHeight: 2),
      environmentPresets: [
        for (var i = 0; i < 250; i++)
          EnvironmentPreset(
            id: 'été_$i',
            name: 'Pièce ${'"\\' * 180}$i',
            templateId: base.templateId,
            palette: base.palette,
            defaultParams: base.defaultParams,
            sortOrder: i,
          ),
      ],
      resourceLibraryCatalog: ResourceLibraryCatalog(
        families: [
          ResourceFamily(id: 'parent', name: 'Parent'),
          ResourceFamily(id: 'child', name: 'Enfant', parentId: 'parent'),
        ],
        entries: [
          for (var i = 0; i < 250; i++)
            ResourceLibraryEntry(
              resourceKind: 'environmentPreset',
              resourceId: 'été_$i',
              familyId: i.isEven ? 'child' : null,
              placementContext: [
                ResourcePlacementContext.interior,
                ResourcePlacementContext.exterior,
                ResourcePlacementContext.both,
                null,
              ][i % 4],
            ),
        ],
      ),
    );
    var now = DateTime.utc(2026, 10, 17);
    final fixture = await NativeResourcePackImportFixture.create(
      target: target,
      clock: () => now,
    );
    final api = LocalResourcePackTransferApi(
      mutations: fixture.mutations,
      snapshotLoader: fixture.loader,
    );
    try {
      final selected = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'selection.create',
        input: {'mode': 'native'},
      );
      final sourceQuery = await api.queryTransfer(
        fixture.opened.projectHandle,
        AuthoringQueryRequest(
          resourceKind: 'resourcePackSelection',
          operation: AuthoringQueryOperation.get,
          ids: [selected['selectionHandle'] as String],
        ),
      );
      expect(sourceQuery['snapshotRevision'], isNotNull);
      final filter = {
        'kind': 'environmentPreset',
        'context': 'interior',
        'familyId': 'parent',
        'search': 'Pièce',
      };
      var page = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'entries',
        input: {
          'selectionHandle': selected['selectionHandle'],
          'filter': filter,
          'limit': 200,
        },
      );
      expect(page['totalAvailable'], 125);
      final first = (page['items'] as List).first as Map;
      expect(() => first['placementContext'] = 'exterior', throwsUnsupportedError);
      expect(() => (first['familyIds'] as List).clear(), throwsUnsupportedError);
      final immutableQuery = await api.queryTransfer(fixture.opened.projectHandle,
          AuthoringQueryRequest(resourceKind: 'resourcePackEntry', operation: AuthoringQueryOperation.get,
              ids: [selected['selectionHandle'] as String], filters: filter));
      expect(() => ((immutableQuery['items'] as List).first as Map)['label'] = 'forged', throwsUnsupportedError);
      final seen = <String>{};
      var pages = 0;
      while (true) {
        pages++;
        final envelope = {
          'jsonrpc': '2.0',
          'id': 'x' * 128,
          'result': {
            'contents': [
              {
                'uri': 'pokemap://test',
                'mimeType': 'application/json',
                'text': jsonEncode(page),
              },
            ],
          },
        };
        expect(
          utf8.encode(jsonEncode(envelope)).length,
          lessThanOrEqualTo(256 * 1024),
        );
        expect(page['returned'], greaterThan(0));
        seen.addAll(
          (page['items'] as List).map((row) => (row as Map)['id'] as String),
        );
        if (page['nextCursor'] == null) break;
        page = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'entries',
          input: {
            'selectionHandle': selected['selectionHandle'],
            'filter': filter,
            'limit': 200,
            'cursor': page['nextCursor'],
          },
        );
      }
      expect(pages, greaterThan(1));
      expect(seen.length, 125);
      final chosen = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'selection.select_filtered',
        input: {
          'selectionHandle': selected['selectionHandle'],
          'revision': selected['revision'],
          'filter': filter,
        },
      );
      expect(chosen['selectedCount'], 125);
      final hidden = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'entries',
        input: {
          'selectionHandle': chosen['selectionHandle'],
          'filter': {'context': 'unspecified'},
        },
      );
      expect(
        (hidden['items'] as List).every(
          (row) => (row as Map)['selected'] == false,
        ),
        isTrue,
      );
      final both = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'entries',
        input: {
          'selectionHandle': chosen['selectionHandle'],
          'filter': {'context': 'exterior', 'selected': true},
        },
      );
      expect(both['totalAvailable'], 62);
      await expectLater(
        api.transfer(
          fixture.opened.projectHandle,
          verb: 'selection.patch',
          input: {
            'selectionHandle': selected['selectionHandle'],
            'revision': selected['revision'],
            'remove': [],
          },
        ),
        throwsA(
          isA<ResourcePackTransferException>().having(
            (e) => e.code,
            'code',
            'resource_pack.selection_stale',
          ),
        ),
      );
      now = now.add(Duration(hours: 3));
      await expectLater(
        api.queryTransfer(
          fixture.opened.projectHandle,
          AuthoringQueryRequest(
            resourceKind: 'resourcePackSelection',
            operation: AuthoringQueryOperation.get,
            ids: [selected['selectionHandle'] as String],
          ),
        ),
        throwsA(isA<WorkspaceHandleException>()),
      );
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });
}
