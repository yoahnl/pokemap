import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_presentation_draft.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  for (final mode in [
    MapEntityNpcMovementMode.idle,
    MapEntityNpcMovementMode.patrol,
  ]) {
    test('presentation movement and contact from ${mode.name}', () {
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 6, height: 6),
        entities: [
          MapEntity(
            id: 'guide',
            kind: MapEntityKind.npc,
            pos: const GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(
              characterId: 'guide-character',
              movement: MapEntityNpcMovementConfig(
                mode: mode,
                waypoints: mode == MapEntityNpcMovementMode.patrol
                    ? const [GridPos(x: 2, y: 1)]
                    : const [],
              ),
            ),
          ),
        ],
      );
      const project = ProjectManifest(
        name: 'Pages',
        maps: [],
        tilesets: [],
        characters: [
          ProjectCharacterEntry(
            id: 'guide-character',
            name: 'Guide',
            tilesetId: 'guide-atlas',
          ),
        ],
      );
      final document = _document(map);
      final commands = MapEntityEditingCommands(document, project);
      MapEntityPresentationDraft draft() => MapEntityPresentationDraft(
        document.current,
        document.current.entities.single,
      );
      commands.setPresentation('guide', draft().add());
      expect(
        document
            .current
            .entities
            .single
            .presentation!
            .variants
            .single
            .movement
            .mode,
        MapEntityNpcMovementMode.idle,
      );
      final beforeRoute = document.current;
      expect(
        () => draft().replace(0, {
          'movement': const MapEntityNpcMovementConfig(
            mode: MapEntityNpcMovementMode.fixedRoute,
          ).toJson(),
        }),
        throwsFormatException,
      );
      expect(document.current, same(beforeRoute));
      commands.setPresentation(
        'guide',
        draft().replace(0, {
          'movement': const MapEntityNpcMovementConfig(
            mode: MapEntityNpcMovementMode.fixedRoute,
            routeSteps: [
              MapEntityNpcRouteStep.face(direction: EntityFacing.south),
            ],
          ).toJson(),
        }),
      );
      expect(
        document
            .current
            .entities
            .single
            .presentation!
            .variants
            .single
            .movement
            .mode,
        MapEntityNpcMovementMode.fixedRoute,
      );
      commands.setPresentation(
        'guide',
        draft().replace(0, {'startsOnNpcContact': true}),
      );
      expect(
        document
            .current
            .entities
            .single
            .presentation!
            .variants
            .single
            .startsOnNpcContact,
        isTrue,
      );
      commands.setPresentation(
        'guide',
        draft().replace(0, {'characterId': null}),
      );
      final variant =
          document.current.entities.single.presentation!.variants.single;
      expect(variant.characterId, isNull);
      expect(variant.movement.mode, MapEntityNpcMovementMode.idle);
      expect(variant.startsOnNpcContact, isFalse);
    });
  }

  test('variants use canonical action with validation and one-step undo', () {
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 6, height: 6),
      entities: const [
        MapEntity(
          id: 'owner',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 1, y: 1),
        ),
      ],
    );
    final document = _document(map);
    final commands = MapEntityEditingCommands(
      document,
      const ProjectManifest(name: 'Test', maps: [], tilesets: []),
    );
    MapEntityPresentationDraft draft() => MapEntityPresentationDraft(
      document.current,
      document.current.entities.single,
    );
    commands.setPresentation('owner', draft().add());
    expect(
      document.current.entities.single.presentation!.variants,
      hasLength(1),
    );
    commands.setPresentation(
      'owner',
      draft().replace(0, {'blocksMovement': false}),
    );
    expect(
      document
          .current
          .entities
          .single
          .presentation!
          .variants
          .single
          .blocksMovement,
      isFalse,
    );
    final before = document.current;
    final undo = document.undoCount;
    for (final invalid in ['wrong', '0', '65', '6']) {
      expect(
        () => draft().resize(0, invalid, width: true),
        throwsFormatException,
      );
    }
    expect(document.current, same(before));
    expect(document.undoCount, undo);
    commands.setPresentation('owner', draft().resize(0, '2', width: true));
    expect(
      document.current.entities.single.presentation!.variants.single.size.width,
      2,
    );
    document.restore(redo: false);
    expect(document.current, before);
  });

  test('variant ordering, unique identifiers and last removal preserve base entity', () {
    const entity = MapEntity(
      id: 'owner',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 1),
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 6, height: 6),
      entities: [entity],
    );
    var current = entity;
    MapEntityPresentationDraft draft() =>
        MapEntityPresentationDraft(map, current);
    current = current.copyWith(presentation: draft().add());
    current = current.copyWith(presentation: draft().add());
    expect(current.presentation!.variants.map((value) => value.id), [
      'variant_1',
      'variant_2',
    ]);
    current = current.copyWith(presentation: draft().promote(1));
    expect(current.presentation!.variants.first.id, 'variant_2');
    current = current.copyWith(presentation: draft().remove(0));
    expect(draft().remove(0), isNull);
    expect(entity.presentation, isNull);
  });
}

EditableMapDocument _document(MapData map) => EditableMapDocument(
  MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
);
