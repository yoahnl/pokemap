import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const owner = MapEntity(
      id: 'owner', kind: MapEntityKind.custom, pos: GridPos(x: 1, y: 1));
  final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 5, height: 5),
      entities: [owner]);
  const project = ProjectManifest(name: 'Test', maps: [], tilesets: []);
  final presentation = MapEntityPresentation(variants: [
    MapEntityPresentationVariant(
        id: 'one',
        condition: NarrativeEventConditionExpression.all([]),
        blocksMovement: false)
  ]);
  test('canonical presentation action sets and clears one stable owner', () {
    const actions = EntityActions();
    final result = actions.setPresentation(map,
        project: project, entityId: owner.id, presentation: presentation);
    expect(result.entities.single.presentation, presentation);
    expect(result.entities.single.copyWith(presentation: null), owner);
    expect(
        actions.setPresentation(result,
            project: project, entityId: owner.id, presentation: null),
        map);
  });
  for (final invalid in [
    'character',
    'fact',
    'bounds',
    'owner',
    'temporaryOwner'
  ]) {
    test('canonical presentation action rejects $invalid', () {
      var target = map;
      var variant = presentation.variants.single.toJson();
      if (invalid == 'character') variant['characterId'] = 'missing';
      if (invalid == 'fact')
        variant['condition'] = NarrativeEventConditionExpression.leaf(
                NarrativeEventCondition.fact('missing', true))
            .toJson();
      if (invalid == 'bounds') variant['size'] = {'width': 5, 'height': 5};
      if (invalid == 'owner')
        target = map.copyWith(entities: [
          owner.copyWith(
              kind: MapEntityKind.item,
              item: const MapEntityItemData(gameItemId: 'item'))
        ]);
      if (invalid == 'temporaryOwner')
        variant['condition'] = NarrativeEventConditionExpression.leaf(
                NarrativeEventCondition.mapEventInstanceBoolean(
                    mapId: 'other',
                    eventId: 'other',
                    key: 'A',
                    expectedValue: false))
            .toJson();
      expect(
          () => const EntityActions().setPresentation(target,
              project: project,
              entityId: owner.id,
              presentation: MapEntityPresentation(
                  variants: [MapEntityPresentationVariant.fromJson(variant)])),
          throwsA(isA<MapAuthoringException>()));
    });
  }
}
