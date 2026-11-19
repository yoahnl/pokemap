import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/resource_owner_seed.dart';
import 'resource_fixture.dart';

void main() {
  test('the resource editor replaces placed decor before removing its definition and source', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final adapter = fixture.resources;
    final sheet = (await fixture.import()).createdTilesetId!;
    await seedFreeDecor(fixture, placed: true);
    final original = (await fixture.maps.loadProject(fixture.session))
        .elements
        .single;
    final instance = (await fixture.loadMap()).map.placedElements.single;
    final beforeMap = await fixture.mapFile.readAsBytes();

    Future<ResourceMutationReceipt> apply(
      String action,
      Map<String, Object?> values,
    ) async {
      final preparation = await adapter.prepareOperation(action, values);
      return adapter.applyPrepared(preparation, confirmDestructive: true);
    }

    final duplicate = await apply('element.duplicate', {
      'sourceElementId': original.id,
      'newElementId': 'pine',
      'name': 'Pin',
      'categoryId': 'nature',
    });
    final copy = duplicate.manifest.elements.singleWhere((e) => e.id == 'pine');
    expect(copy.frames, original.frames);
    expect(copy.tilesetId, sheet);
    expect(await fixture.mapFile.readAsBytes(), beforeMap);
    await expectLater(
      adapter.prepareOperation('element.delete', {'elementId': original.id}),
      throwsA(
        isA<ResourceFailure>().having(
          (e) => e.message,
          'usage',
          contains('Ce décor est encore utilisé'),
        ),
      ),
    );
    await apply('resource.usages.replace', {
      'family': 'decors',
      'resourceId': original.id,
      'replacementId': copy.id,
    });
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadProject(fixture.session);
    final reopened = await maps.loadMap(fixture.session, ResourceFixture.entry);
    expect(reopened.map.placedElements, [instance.copyWith(elementId: 'pine')]);
    final removed = await apply('element.delete', {'elementId': original.id});
    expect(removed.manifest.elements, [copy]);
    final beforeRemoval = await fixture.manifestFile.readAsBytes();
    await expectLater(
      adapter.prepareOperation('tileset.remove', {
        'tilesetId': sheet,
        'removeSource': true,
      }),
      throwsA(
        isA<ResourceFailure>().having(
          (e) => e.message,
          'usage',
          contains('Cette planche est encore utilisée'),
        ),
      ),
    );
    expect(await fixture.manifestFile.readAsBytes(), beforeRemoval);
    final current = await fixture.loadMap();
    await fixture.maps.saveMap(
      fixture.session,
      current,
      current.map.copyWith(placedElements: []),
    );
    await apply('element.delete', {'elementId': copy.id});
    await apply('tileset.remove', {'tilesetId': sheet, 'removeSource': true});
    final after = await LocalMapWorkspaceAdapter().loadProject(fixture.session);
    expect(after.elements, isEmpty);
    expect(after.tilesets, isEmpty);
  });
}
