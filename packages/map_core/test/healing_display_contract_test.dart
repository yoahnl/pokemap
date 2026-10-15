import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('openHeal preserves its optional native display reference', () {
    final command = SceneInteractiveCommand.fromJson({
      'kind': 'openHeal',
      'requiresConfirmation': false,
      'displayEntityId': 'center-healing-display',
    });
    expect(command.toJson()['displayEntityId'], 'center-healing-display');
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
  });

  test('healing display remains a typed nonblocking custom object', () {
    final json = <String, dynamic>{
      'id': 'center-healing-display',
      'kind': 'custom',
      'pos': {'x': 7, 'y': 4},
      'blocksMovement': false,
      'healingDisplay': {
        'variantElementIds': [for (var n = 1; n <= 6; n++) 'healing-$n'],
      },
    };
    final entity = MapEntity.fromJson(json);
    expect(entity.toJson()['healingDisplay'], json['healingDisplay']);
    expect(entity.npc, isNull);
    expect(entity.blocksMovement, isFalse);
    assertValidMapEntityTypedPayloads(entity);
  });

  test('openHeal rejects malformed or unqualified display identities', () {
    for (final value in ['', ' ', ' center ', 4, null]) {
      expect(
        () => SceneInteractiveCommand.fromJson({
          'kind': 'openHeal',
          'displayEntityId': value,
        }),
        throwsFormatException,
      );
    }
  });

  test(
    'display variants are immutable and select precisely zero through six members',
    () {
      final ids = [for (var i = 1; i <= 6; i++) 'healing-$i'];
      final data = MapEntityHealingDisplayData(variantElementIds: ids);
      ids[0] = 'changed';
      expect(data.elementIdForMemberCount(0), isNull);
      expect(data.elementIdForMemberCount(1), 'healing-1');
      expect(data.elementIdForMemberCount(6), 'healing-6');
      expect(() => data.variantElementIds.clear(), throwsUnsupportedError);
      expect(() => data.elementIdForMemberCount(-1), throwsRangeError);
      expect(() => data.elementIdForMemberCount(7), throwsRangeError);
      expect(MapEntityHealingDisplayData.fromJson(data.toJson()), data);
    },
  );

  test(
    'wire refuses unknown formats, collisions and nondecorative payloads',
    () {
      final source = _display().toJson();
      for (final json in <Map<String, dynamic>>[
        {...source, 'kind': 'npc'},
        {...source, 'blocksMovement': true},
        {
          ...source,
          'size': {'width': 2, 'height': 1},
        },
        {...source, 'npc': const MapEntityNpcData().toJson()},
        {
          ...source,
          'fieldObstacle': const MapEntityFieldObstacleData().toJson(),
        },
        {
          ...source,
          'editorVisual': const MapEntityEditorVisual(
            elementId: 'healing-1',
          ).toJson(),
        },
        {
          ...source,
          'properties': {'collision.width': '1'},
        },
        {
          ...source,
          'properties': {'collisionWidth': '1'},
        },
        {
          ...source,
          'healingDisplay': {
            'variantElementIds': ['one'],
          },
        },
        {
          ...source,
          'healingDisplay': {'variantElementIds': List.filled(6, 'same')},
        },
        {
          ...source,
          'healingDisplay': {
            'variantElementIds': [for (var i = 0; i < 6; i++) i],
          },
        },
        {
          ...source,
          'healingDisplay': {
            'variantElementIds': [for (var i = 1; i <= 6; i++) 'healing-$i'],
            'variableId': 6,
          },
        },
      ]) {
        expect(
          () => MapEntity.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    },
  );

  test(
    'typed operations and native resolver reject a blocking, wide or duplicate display',
    () {
      final entity = _display();
      final map = _map(entity);
      expect(resolveHealingDisplayEntity(map, entity.id), entity);
      for (final invalid in [
        entity.copyWith(blocksMovement: true),
        entity.copyWith(size: const GridSize(width: 2, height: 1)),
        entity.copyWith(properties: const {'collision.offsetX': '0'}),
      ]) {
        expect(
          () => assertValidMapEntityTypedPayloads(invalid),
          throwsA(isA<ValidationException>()),
        );
        expect(resolveHealingDisplayEntity(_map(invalid), entity.id), isNull);
      }
      expect(
        resolveHealingDisplayEntity(
          map.copyWith(entities: [entity, entity]),
          entity.id,
        ),
        isNull,
      );
      expect(resolveHealingDisplayEntity(map, 'other'), isNull);
      expect(
        resolveHealingDisplayEntity(
          map.copyWith(version: ProjectVersion.v9),
          entity.id,
        ),
        isNull,
      );
      expect(resolveHealingDisplayEntity(map, ' healing-balls '), isNull);
    },
  );

  test('canonical entity updates preserve and explicitly clear the typed display', () {
    final entity = _display();
    final map = _map(entity);
    final renamed = updateEntityOnMap(map, entityId: entity.id, name: 'Machine de soin');
    expect(renamed.entities.single.healingDisplay, entity.healingDisplay);
    final removed = updateEntityOnMap(renamed, entityId: entity.id, healingDisplay: null);
    expect(removed.entities.single.healingDisplay, isNull);
    final restored = updateEntityOnMap(removed, entityId: entity.id, healingDisplay: entity.healingDisplay);
    expect(restored.entities.single.name, 'Machine de soin');
    expect(restored.entities.single.healingDisplay, entity.healingDisplay);
    expect(map.entities.single.name, entity.name);
    expect(() => updateEntityOnMap(map.copyWith(version: ProjectVersion.v9),
      entityId: entity.id, name: 'No spatial display'), throwsA(isA<ValidationException>()));
  });

  test('six native 64 by 48 animated variants use existing atlas frames', () {
    final entity = _display();
    final project = _project();
    expect(
      () => assertHealingDisplayVisualsAgainstProject(entity, project),
      returnsNormally,
    );
    final saved = MapEntity.fromJson(entity.toJson());
    expect(saved.healingDisplay, entity.healingDisplay);
    expect(saved.blocksMovement, isFalse);
    MapValidator.validate(_map(saved), projectDialogueContext: project);
  });

  test(
    'display references reject missing, ambiguous, out-of-bounds or changing-size frames',
    () {
      final entity = _display();
      final project = _project();
      final first = project.elements.first;
      for (final candidate in [
        project.copyWith(elements: project.elements.skip(1).toList()),
        project.copyWith(elements: [...project.elements, first]),
        project.copyWith(tilesets: []),
        project.copyWith(
          settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        ),
        project.copyWith(
          elements: [
            first.copyWith(
              frames: [
                const TilesetVisualFrame(source: TilesetSourceRect(x: 4, y: 1)),
              ],
            ),
            ...project.elements.skip(1),
          ],
        ),
        project.copyWith(
          elements: [
            first.copyWith(
              frames: [
                const TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 1, width: 2),
                ),
              ],
            ),
            ...project.elements.skip(1),
          ],
        ),
      ]) {
        expect(
          () => assertHealingDisplayVisualsAgainstProject(entity, candidate),
          throwsA(isA<ValidationException>()),
        );
      }
    },
  );

  test(
    'guided command builder preserves an optional semantic display picker',
    () {
      final descriptor = NarrativeCommandCatalog.canonical().byId('openHeal')!;
      final parameter = descriptor.parameters.singleWhere(
        (entry) => entry.id == 'displayEntityId',
      );
      expect(parameter.kind, NarrativeCommandParameterKind.mapEntityReference);
      expect(parameter.required, isFalse);
      final payload =
          buildScenePayloadForNarrativeCommand(
                commandId: descriptor.id,
                parameters: {
                  'requiresConfirmation': 'false',
                  'displayEntityId': 'healing-balls',
                },
              )
              as SceneActionPayload;
      expect(payload.interactiveCommand!.toJson(), {
        'kind': 'openHeal',
        'requiresConfirmation': false,
        'displayEntityId': 'healing-balls',
      });
      expect(
        () => SceneInteractiveCommand.fromJson({
          'kind': 'openHeal',
          'variableId': 6,
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'Scene diagnostics require a unique known native display and valid variants',
    () {
      final scene = SceneAsset(
        id: 'heal',
        name: 'Soin',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'heal',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(
                SceneInteractiveCommand.openHeal(
                  displayEntityId: 'healing-balls',
                ),
              ),
            ),
          ],
          edges: [],
        ),
      );
      final project = _project();
      final map = _map(_display());
      expect(diagnoseSceneAgainstProject(scene, project, mapsById: {'wrong-key': map})
        .byCode(SceneDiagnosticCode.commandInvalidHealingDisplay), hasLength(1));
      expect(
        diagnoseSceneAgainstProject(
          scene,
          project,
          mapsById: {'center': map},
        ).byCode(SceneDiagnosticCode.commandInvalidHealingDisplay),
        isEmpty,
      );
      expect(
        diagnoseSceneAgainstProject(
          scene,
          project,
          mapsById: {},
        ).byCode(SceneDiagnosticCode.commandInvalidHealingDisplay),
        hasLength(1),
      );
      expect(
        diagnoseSceneAgainstProject(
          scene,
          project.copyWith(elements: []),
          mapsById: {'center': map},
        ).byCode(SceneDiagnosticCode.commandInvalidHealingDisplay),
        hasLength(1),
      );
    },
  );
}

MapEntity _display() => MapEntity(
  id: 'healing-balls',
  kind: MapEntityKind.custom,
  pos: const GridPos(x: 7, y: 4),
  blocksMovement: false,
  healingDisplay: MapEntityHealingDisplayData(
    variantElementIds: [for (var i = 1; i <= 6; i++) 'healing-$i'],
  ),
);

MapData _map(MapEntity entity) => MapData(
  id: 'center',
  name: 'Centre',
  size: const GridSize(width: 20, height: 20),
  entities: [entity],
);

ProjectManifest _project() => ProjectManifest(
  name: 'Centre',
  maps: const [
    ProjectMapEntry(
      id: 'center',
      name: 'Centre',
      relativePath: 'maps/center.json',
    ),
  ],
  tilesets: [
    for (var sheet = 1; sheet <= 2; sheet++)
      ProjectTilesetEntry(
        id: 'healing-sheet-$sheet',
        name: 'Boules $sheet',
        relativePath: 'tilesets/healing-$sheet.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: 'healing-sheet-$sheet',
          pixelWidth: 256,
          pixelHeight: 192,
          tileWidth: 64,
          tileHeight: 48,
        ),
      ),
  ],
  elements: [
    for (var i = 1; i <= 6; i++)
      ProjectElementEntry(
        id: 'healing-$i',
        name: 'Boules $i',
        tilesetId: 'healing-sheet-${i <= 3 ? 1 : 2}',
        categoryId: 'healing',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: (i - 1) % 3 + 1),
            durationMs: 200,
          ),
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 1, y: (i - 1) % 3 + 1),
            durationMs: 200,
          ),
        ],
      ),
  ],
);
