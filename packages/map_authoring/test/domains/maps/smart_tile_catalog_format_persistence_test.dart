import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'smart_tile_lifecycle_api_test.dart'
    show lifecycleFixture, independentRead;

void main() {
  test('catalog authoring writes the canonical format alongside new records',
      () async {
    final fixture = await lifecycleFixture();
    addTearDown(fixture.dispose);
    final file = File('${fixture.root.path}/project.json');
    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final catalog = raw['smartTileCatalog'] as Map<String, dynamic>;
    final savedDraft = (catalog['drafts'] as List).single;
    catalog['formatVersion'] = 2;
    catalog.remove('drafts');
    raw['unrelated'] = {
      'authored': ['intact']
    };
    await file.writeAsString(jsonEncode(raw));
    final sheets = jsonEncode(raw['tilesets']);
    await fixture.mutate('smart_tile.pattern.upsert', {
      'pattern': {
        'id': 'cutout',
        'name': 'Découpe',
        'usage': 'path',
        'width': 1,
        'height': 1,
        'repeatMode': 'stamp',
        'cells': [
          {'x': 0, 'y': 0, 'eraseMaterial': true}
        ],
      },
    });
    final first = await independentRead(fixture);
    expect(first.smartTileCatalog.formatVersion,
        ProjectSmartTileCatalog.currentFormatVersion);
    expect(first.smartTileCatalog.patterns.single.id, 'cutout');
    await fixture
        .mutate('smart_tile.preset.draft.upsert', {'draft': savedDraft});
    final reopened = await independentRead(fixture);
    expect(reopened.smartTileCatalog.drafts.single.id, 'editing');
    expect(reopened.smartTileCatalog.patterns.single.id, 'cutout');
    final written = jsonDecode(await file.readAsString()) as Map;
    expect(jsonEncode(written['tilesets']), sheets);
    expect(written['unrelated'], raw['unrelated']);
    expect((written['smartTileCatalog'] as Map)['formatVersion'],
        ProjectSmartTileCatalog.currentFormatVersion);
  });
}
