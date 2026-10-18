import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'presentation selects one page, masks graphics and restores collision',
    () {
      final condition = NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.fact('changed', true),
      );
      final entity = MapEntity(
        id: 'owner',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 2, y: 2),
        presentation: MapEntityPresentation(
          variants: [
            MapEntityPresentationVariant(
              id: 'high',
              condition: condition,
              blocksMovement: false,
              size: const GridSize(width: 2, height: 2),
            ),
            MapEntityPresentationVariant(
              id: 'base',
              condition: NarrativeEventConditionExpression.not(condition),
              characterId: 'hero',
              blocksMovement: true,
              size: const GridSize(width: 4, height: 1),
            ),
          ],
        ),
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 10, height: 10),
        entities: [entity],
      );
      final project = ProjectManifest(
        name: 'Test',
        maps: const [],
        tilesets: const [],
        characters: const [
          ProjectCharacterEntry(id: 'hero', name: 'Hero', tilesetId: 'actors'),
        ],
        facts: [NarrativeFactDefinition(id: 'changed', label: 'Changed')],
      );
      final first = projectMapEntityPresentations(
        project: project,
        gameState: const GameState(saveId: 'save'),
        map: map,
      );
      expect(first.entities.single.id, 'owner');
      expect(first.entities.single.npc?.characterId, 'hero');
      expect(first.entities.single.blocksMovement, isTrue);
      expect(first.entities.single.size.width, 4);
      final changed = projectMapEntityPresentations(
        project: project,
        gameState: const GameState(
          saveId: 'save',
          storyFlags: StoryFlags(activeFlags: {'changed'}),
        ),
        map: map,
      );
      expect(changed.entities.single.npc, isNull);
      expect(changed.entities.single.blocksMovement, isFalse);
      expect(changed.entities.single.size.height, 2);
      expect(entity.npc, isNull);
      expect(MapEntity.fromJson(entity.toJson()), entity);
      expect(
        projectMapEntityPresentations(
          project: project,
          gameState: const GameState(saveId: 'save'),
          map: map,
        ),
        first,
      );
      expect(resolveEntityCollisionCells(first.entities.single), hasLength(4));
      expect(
        resolveEntityCollisionCells(changed.entities.single),
        hasLength(4),
      );
    },
  );

  test('unavailable conditions stay closed under negation', () {
    final entity = MapEntity(
      id: 'owner',
      kind: MapEntityKind.custom,
      pos: const GridPos(x: 1, y: 1),
      presentation: MapEntityPresentation(
        variants: [
          MapEntityPresentationVariant(
            id: 'missing',
            condition: NarrativeEventConditionExpression.not(
              NarrativeEventConditionExpression.leaf(
                NarrativeEventCondition.fact('missing', true),
              ),
            ),
            blocksMovement: true,
          ),
        ],
      ),
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 5, height: 5),
      entities: [entity],
    );
    expect(
      projectMapEntityPresentations(
        project: const ProjectManifest(name: 'Test', maps: [], tilesets: []),
        gameState: const GameState(saveId: 'save'),
        map: map,
      ).entities,
      isEmpty,
    );
  });

  test(
    'presentation wire contract rejects unknown versions and malformed groups',
    () {
      expect(
        () => MapEntityPresentation.fromJson({
          'schemaVersion': 2,
          'variants': [],
        }),
        throwsFormatException,
      );
      expect(
        () => MapEntityPresentationVariant(
          id: 'bad',
          condition: NarrativeEventConditionExpression.any([]),
          blocksMovement: false,
        ),
        throwsArgumentError,
      );
    },
  );

  test('invalid character, owner and footprint references are rejected', () {
    final variant = MapEntityPresentationVariant(
      id: 'one',
      condition: NarrativeEventConditionExpression.all([]),
      blocksMovement: false,
      characterId: 'missing',
      size: const GridSize(width: 2, height: 2),
    );
    final entity = MapEntity(
      id: 'owner',
      kind: MapEntityKind.custom,
      pos: const GridPos(x: 4, y: 4),
      presentation: MapEntityPresentation(variants: [variant]),
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 5, height: 5),
      entities: [entity],
    );
    const project = ProjectManifest(name: 'Test', maps: [], tilesets: []);
    expect(
      validateMapEntityPresentation(project: project, map: map, entity: entity),
      containsAll([
        'variantFootprintOutOfBounds',
        'variantCharacterReferenceInvalid',
      ]),
    );
    expect(() => MapValidator.validate(map.copyWith(entities: [
      entity.copyWith(pos: const GridPos(x: 1, y: 1)),
    ]), projectDialogueContext: project),
      throwsA(isA<ValidationException>().having((error) => error.code, 'code', 'entity.presentation.invalid')));
    expect(
      () => MapEntity.fromJson(
        entity
            .copyWith(
              kind: MapEntityKind.item,
              item: const MapEntityItemData(gameItemId: 'item'),
            )
            .toJson(),
      ),
      throwsFormatException,
    );
    final local = entity.copyWith(
      presentation: MapEntityPresentation(
        variants: [
          MapEntityPresentationVariant(
            id: 'one',
            blocksMovement: false,
            condition: NarrativeEventConditionExpression.leaf(
              NarrativeEventCondition.mapEventInstanceBoolean(
                mapId: 'other',
                eventId: 'other',
                key: 'A',
                expectedValue: true,
              ),
            ),
          ),
        ],
      ),
    );
    expect(
      validateMapEntityPresentation(project: project, map: map, entity: local),
      containsAll([
        'variantInstanceRetentionMissing',
        'variantInstanceOwnerMustBeSelf',
      ]),
    );
  });
}
