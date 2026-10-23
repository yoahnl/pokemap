import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

MapData templateMap() => MapData(
      id: 'room',
      name: 'Room',
      size: const GridSize(width: 4, height: 4),
      layers: [
        TileLayer(id: 'ground', name: 'Ground', cells: List.filled(16, 0))
      ],
      warps: const [
        MapWarp(
            id: 'arrival',
            pos: GridPos(x: 0, y: 0),
            targetMapId: 'room',
            targetPos: GridPos(x: 0, y: 0))
      ],
      entities: const [
        MapEntity(
            id: 'guide',
            name: 'Guide',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 1, y: 1))
      ],
    );

ProjectManifest templateProject() => ProjectManifest(
      name: 'Synthetic templates',
      maps: const [
        ProjectMapEntry(
            id: 'room', name: 'Room', relativePath: 'maps/room.json')
      ],
      tilesets: const [],
      characters: const [
        ProjectCharacterEntry(id: 'person', name: 'Person', tilesetId: 'people')
      ],
      dialogues: const [
        ProjectDialogueEntry(
            id: 'hello', name: 'Hello', relativePath: 'dialogues/hello.yarn'),
        ProjectDialogueEntry(
            id: 'after', name: 'After', relativePath: 'dialogues/after.yarn'),
      ],
      facts: [NarrativeFactDefinition(id: 'met', label: 'Met')],
      trainers: const [
        ProjectTrainerEntry(
            id: 'trainer',
            name: 'Trainer',
            trainerClass: 'Trainer',
            team: [ProjectTrainerPokemonEntry(speciesId: 'sample', level: 5)])
      ],
      eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [],
          legacyClaims: []),
    );

StandardEventTemplateSpec templateSpec(StandardEventTemplateKind kind) =>
    StandardEventTemplateSpec(
        kind: kind,
        mapId: 'room',
        entityId: 'guide',
        name: 'Sample',
        parameters: switch (kind) {
          StandardEventTemplateKind.conditionalNpc => const {
              'factId': 'met',
              'dialogueId': 'hello',
              'alternateDialogueId': 'after',
              'characterId': 'person'
            },
          StandardEventTemplateKind.pickup => const {
              'itemId': 'key',
              'quantity': 1,
              'characterId': 'person'
            },
          StandardEventTemplateKind.lockedDoor => const {
              'itemId': 'key',
              'destinationMapId': 'room',
              'destinationWarpId': 'arrival',
              'dialogueId': 'hello'
            },
          StandardEventTemplateKind.trainer => const {
              'trainerId': 'trainer',
              'dialogueId': 'hello',
              'alternateDialogueId': 'after',
              'characterId': 'person'
            },
        });

ProjectItemCatalog templateItems() =>
    const ProjectItemCatalog(schemaVersion: 1, entries: [
      ProjectItemDefinition(id: 'key', displayName: 'Key', pocketId: 'items')
    ]);
