import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../maps/map_catalog_fixture.dart';
import 'resource_information_actions_test.dart' show informationFixture;
import 'resource_information_fixture.dart' show smartInformationFixture;
import 'element_definition_fixture.dart'
    show elementSnapshot, retainedElementBorder;

void main() {
  test('role-only classification persists and omission preserves all metadata',
      () async {
    var project = await _apply(informationFixture(), 'resource.classify', {
      'resourceKind': 'element',
      'resourceId': 'decor',
      'role': 'component',
    });
    expect(project.resourceLibraryCatalog.entries.single.role,
        ResourceLibraryRole.component);
    project = await _apply(project, 'resource.classify', {
      'resourceKind': 'element',
      'resourceId': 'decor',
      'familyId': 'trees',
    });
    project = await _apply(project, 'resource.classify_batch', {
      'entries': [
        {'resourceKind': 'element', 'resourceId': 'decor'}
      ],
    });
    final entry = project.resourceLibraryCatalog.entries.single;
    expect(entry.familyId, 'trees');
    expect(entry.role, ResourceLibraryRole.component);
    project = await _apply(project, 'resource.classify', {
      'resourceKind': 'element',
      'resourceId': 'decor',
      'familyId': null,
      'role': 'standard',
    });
    expect(project.resourceLibraryCatalog.isEmpty, isTrue);
    for (final role in [null, 'unknown', 2]) {
      await expectLater(
          () => _apply(project, 'resource.classify', {
                'resourceKind': 'element',
                'resourceId': 'decor',
                'role': role,
              }),
          throwsA(isA<VisualLibraryException>()));
    }
  });
  test('classification batch has one change and accepts 100 typed resources',
      () async {
    final base = informationFixture();
    final project = base.copyWith(elements: [
      for (var index = 0; index < 100; index++)
        base.elements.single.copyWith(id: 'decor-$index'),
    ]);
    final draft = await MapMutationDispatcher.canonical().build(catalogContext(
      librarySnapshot([], project: project),
      'resource.classify_batch',
      {
        'entries': [
          for (final element in project.elements)
            {
              'resourceKind': 'element',
              'resourceId': element.id,
              'familyId': 'trees'
            },
        ],
      },
    ));
    expect(draft.changeSet.changes, hasLength(1));
    expect(draft.changeSet.diff.entries, hasLength(1));
    final updated = ProjectManifest.fromJson(jsonDecode(utf8.decode(
      draft.changeSet.changes.single.afterBytes!,
    )) as Map<String, dynamic>);
    expect(updated.resourceLibraryCatalog.entries, hasLength(100));
    expect(updated.elements, project.elements);
  });

  test('batch shares absent and null semantics and typed identities', () async {
    var project = smartInformationFixture().copyWith(
        resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
      ResourceLibraryEntry(
          resourceKind: 'element', resourceId: 'decor', familyId: 'trees'),
      ResourceLibraryEntry(
          resourceKind: 'smartTilePreset',
          resourceId: 'ground',
          familyId: 'ground'),
    ]));
    project = await _apply(project, 'resource.classify_batch', {
      'entries': [
        {'resourceKind': 'element', 'resourceId': 'decor', 'mapId': null},
        {
          'resourceKind': 'smartTilePreset',
          'resourceId': 'ground',
          'familyId': null
        },
      ]
    });
    expect(
        project.resourceLibraryCatalog.entryFor('element', 'decor')!.familyId,
        'trees');
    expect(project.resourceLibraryCatalog.entryFor('smartTilePreset', 'ground'),
        isNull);
    final noop = await MapMutationDispatcher.canonical().build(catalogContext(
      librarySnapshot([], project: project),
      'resource.classify_batch',
      {
        'entries': [
          {'resourceKind': 'element', 'resourceId': 'decor'}
        ]
      },
    ));
    expect(noop.changeSet.changes, isEmpty);
  });

  test('batch rejects malformed oversized duplicate and unknown entries',
      () async {
    final snapshot = librarySnapshot([], project: informationFixture());
    final valid = {
      'resourceKind': 'element',
      'resourceId': 'decor',
      'familyId': 'trees'
    };
    for (final parameters in <Map<String, Object?>>[
      {'entries': []},
      {'entries': List.filled(101, valid)},
      {
        'entries': [valid, valid]
      },
      {
        'entries': [valid, false]
      },
      {
        'entries': [
          valid,
          {'resourceKind': 'element', 'resourceId': 'missing'}
        ]
      },
      {
        'entries': [
          valid,
          {
            'resourceKind': 'tileset',
            'resourceId': 'sheet',
            'familyId': 'missing'
          }
        ]
      },
      {
        'entries': [
          valid,
          {'resourceKind': 'tileset', 'resourceId': 'sheet', 'mapId': 'missing'}
        ]
      },
      {
        'entries': [
          valid,
          {'resourceKind': 'tileset', 'resourceId': 'sheet', 'extra': true}
        ]
      },
      {
        'entries': [valid],
        'extra': true
      },
    ]) {
      await expectLater(
          () => MapMutationDispatcher.canonical().build(catalogContext(
                snapshot,
                'resource.classify_batch',
                parameters,
              )),
          throwsA(isA<VisualLibraryException>()),
          reason: '$parameters');
    }
  });

  test('batch validates final direct and transitive map scopes', () async {
    final maps = [
      catalogMap('a'),
      catalogMap('b').copyWith(placedElements: [_placed()])
    ];
    final project = _withMaps(informationFixture(), maps);
    final snapshot = librarySnapshot(maps, project: project);
    for (final kindAndId in [('element', 'decor'), ('tileset', 'sheet')]) {
      await expectLater(
          () => MapMutationDispatcher.canonical().build(catalogContext(
                snapshot,
                'resource.classify_batch',
                {
                  'entries': [
                    {
                      'resourceKind':
                          kindAndId.$1 == 'element' ? 'tileset' : 'element',
                      'resourceId':
                          kindAndId.$1 == 'element' ? 'sheet' : 'decor',
                      'familyId': 'trees'
                    },
                    {
                      'resourceKind': kindAndId.$1,
                      'resourceId': kindAndId.$2,
                      'mapId': 'a'
                    },
                  ]
                },
              )),
          throwsA(isA<VisualLibraryException>().having((error) => error.code,
              'code', 'resource_library.scope_conflict')));
    }
    final accepted =
        await MapMutationDispatcher.canonical().build(catalogContext(
      snapshot,
      'resource.classify_batch',
      {
        'entries': [
          {
            'resourceKind': 'element',
            'resourceId': 'decor',
            'familyId': 'trees',
            'mapId': 'b'
          },
          {'resourceKind': 'tileset', 'resourceId': 'sheet', 'mapId': 'b'},
        ]
      },
    ));
    expect(accepted.changeSet.changes, hasLength(1));
  });

  test(
      'creates updates classifies queries and refuses nonempty family deletion',
      () async {
    var project = await _apply(informationFixture(), 'resource.family.create',
        {'familyId': 'forest-a', 'name': 'Forêt A', 'parentId': 'trees'});
    project = await _apply(project, 'resource.family.update',
        {'familyId': 'forest-a', 'name': 'Forêt B'});
    expect(project.resourceLibraryCatalog.families.single.parentId, 'trees');
    project = await _apply(project, 'resource.classify', {
      'resourceKind': 'element',
      'resourceId': 'decor',
      'familyId': 'forest-a'
    });
    final snapshot = librarySnapshot([], project: project);
    final queried = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
            resourceKind: 'resourceLibraryEntry',
            operation: AuthoringQueryOperation.get,
            ids: ['element:decor'],
            view: AuthoringQueryView.detail));
    expect(queried.items.single['familyId'], 'forest-a');
    expect(
        () => ResourceLibraryActions().build(catalogContext(
            snapshot, 'resource.family.delete', {'familyId': 'forest-a'})),
        throwsA(isA<VisualLibraryException>()));
    project = await _apply(project, 'resource.classify',
        {'resourceKind': 'element', 'resourceId': 'decor', 'familyId': null});
    project = await _apply(
        project, 'resource.family.delete', {'familyId': 'forest-a'});
    expect(project.resourceLibraryCatalog.isEmpty, isTrue);
  });

  test(
      'unknown resource map family cycles and builtin modification fail closed',
      () {
    final snapshot = librarySnapshot([], project: informationFixture());
    for (final request in [
      (
        'resource.classify',
        {'resourceKind': 'model3d', 'resourceId': 'decor', 'familyId': 'trees'}
      ),
      (
        'resource.classify',
        {'resourceKind': 'element', 'resourceId': 'decor', 'mapId': 'missing'}
      ),
      (
        'resource.classify',
        {
          'resourceKind': 'element',
          'resourceId': 'decor',
          'familyId': 'missing'
        }
      ),
      ('resource.family.create', {'familyId': 'trees', 'name': 'Override'}),
      (
        'resource.family.create',
        {'familyId': 'a', 'name': 'A', 'parentId': 'a'}
      ),
    ]) {
      expect(
          () => ResourceLibraryActions()
              .build(catalogContext(snapshot, request.$1, request.$2)),
          throwsA(isA<VisualLibraryException>()));
    }
  });

  test(
      'all newly published resource kinds return their canonical typed definitions',
      () {
    final map = catalogMap('a');
    final project = _withMaps(informationFixture(), [map]).copyWith(
        models3d: [
          ProjectModel3dEntry(
              id: 'tree',
              name: 'Tree',
              sourceAssetId: 'model',
              relativePath: 'assets/models3d/tree.glb',
              inspection: Model3dInspection(
                  bounds: Model3dBounds(
                      min: Model3dVector3.zero,
                      max: Model3dVector3(x: 1, y: 1, z: 1)),
                  meshCount: 1,
                  triangleCount: 1))
        ],
        characters: const [
          ProjectCharacterEntry(
              id: 'person', name: 'Personne', tilesetId: 'sheet')
        ],
        environmentPresets: [
          EnvironmentPreset(
              id: 'forest',
              name: 'Forêt',
              templateId: 'forest',
              palette: [EnvironmentPaletteItem(elementId: 'decor', weight: 1)],
              defaultParams: EnvironmentGenerationParams(
                  density: 1, variation: 0, edgeDensity: 1, minSpacingCells: 0),
              sortOrder: 0)
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(families: [
          ResourceFamily(id: 'forest-a', name: 'Forêt A', parentId: 'trees')
        ], entries: [
          ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'tree',
              familyId: 'forest-a',
              mapId: 'a')
        ]));
    final snapshot = librarySnapshot([map], project: project);
    final registry = AuthoringResourceKindRegistry.canonical();
    for (final target in [
      ('resourceLibraryCatalog', 'resource-library'),
      ('resourceFamily', 'forest-a'),
      ('resourceLibraryEntry', 'model3d:tree'),
      ('element', 'decor'),
      ('model3d', 'tree'),
      ('environmentPreset', 'forest'),
      ('character', 'person'),
      ('tileset', 'sheet')
    ]) {
      expect(registry.queryableResourceKindIds, contains(target.$1));
      final page = const ProjectQueryService().query(
          snapshot,
          AuthoringQueryRequest(
              resourceKind: target.$1,
              operation: AuthoringQueryOperation.get,
              ids: [target.$2],
              view: AuthoringQueryView.detail));
      expect(page.items.single['id'], target.$2, reason: target.$1);
    }
  });

  test(
      'rejects restricting a used resource and its dependent sheet to another map',
      () async {
    final maps = [
      catalogMap('a'),
      catalogMap('b').copyWith(placedElements: [_placed()])
    ];
    final project = _withMaps(informationFixture(), maps);
    final snapshot = librarySnapshot(maps, project: project);
    expect(resourceLibraryMapUsages(snapshot, 'element', 'decor'), {'b'});
    expect(resourceLibraryMapUsages(snapshot, 'tileset', 'sheet'), {'b'});
    for (final target in [('element', 'decor'), ('tileset', 'sheet')]) {
      await expectLater(
          () => MapMutationDispatcher.canonical().build(catalogContext(
                  snapshot, 'resource.classify', {
                'resourceKind': target.$1,
                'resourceId': target.$2,
                'mapId': 'a'
              })),
          throwsA(isA<VisualLibraryException>().having((error) => error.code,
              'code', 'resource_library.scope_conflict')));
    }
  });

  test('canonical placement permits owner map and rejects other map', () async {
    final maps = [catalogMap('a'), catalogMap('b')];
    final project = _withMaps(informationFixture(), maps).copyWith(
        resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
      ResourceLibraryEntry(
          resourceKind: 'element',
          resourceId: 'decor',
          familyId: 'trees',
          mapId: 'a')
    ]));
    final snapshot = librarySnapshot(maps, project: project);
    final dispatcher = MapMutationDispatcher.canonical();
    final accepted = await dispatcher.build(catalogContext(
        snapshot,
        'placed_element.place',
        {'mapId': 'a', 'instance': _placed().toJson()}));
    expect(accepted.changeSet.changes, hasLength(1));
    await expectLater(
        () => dispatcher.build(catalogContext(snapshot, 'placed_element.place',
            {'mapId': 'b', 'instance': _placed().toJson()})),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'resource_library.scope_conflict')));
  });

  test('smart tile dependencies include atlas sheet consumers', () {
    final project = smartInformationFixture();
    final map = catalogMap('a').copyWith(layers: [
      ...catalogMap('a').layers,
      MapLayer.smartTile(
          id: 'ground',
          name: 'Ground',
          presetId: 'ground',
          usage: SmartTileUsage.terrain,
          field: SmartTileField.cell(semanticCells: List.filled(30, 0)))
    ]);
    final snapshot = librarySnapshot([map], project: _withMaps(project, [map]));
    expect(
        resourceLibraryMapUsages(snapshot, 'smartTilePreset', 'ground'), {'a'});
    expect(resourceLibraryMapUsages(snapshot, 'tileset', 'sheet'), {'a'});
  });

  test('character scope follows NPC usage and its tileset dependency',
      () async {
    final maps = [
      catalogMap('a'),
      catalogMap('b').copyWith(entities: const [
        MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(characterId: 'person'))
      ])
    ];
    final project = _withMaps(informationFixture(), maps)
        .copyWith(characters: const [
      ProjectCharacterEntry(id: 'person', name: 'Personne', tilesetId: 'sheet')
    ]);
    final snapshot = librarySnapshot(maps, project: project);
    expect(resourceLibraryMapUsages(snapshot, 'character', 'person'), {'b'});
    expect(resourceLibraryMapUsages(snapshot, 'tileset', 'sheet'), {'b'});
    await _expectScopeRefusal(snapshot, 'character', 'person');
  });

  test('border scope includes the primitive element and sheet dependencies',
      () async {
    final map = catalogMap('b').copyWith(layers: [
      BorderLayer(
          id: 'border',
          name: 'Bordure',
          content: BorderLayerContent(features: [
            BorderFeature(
                id: 'line',
                name: 'Ligne',
                blueprintId: 'border',
                seed: BorderSignedInt64.zero,
                overrides: const [],
                keepOutRegions: const [],
                geometry: BorderStrokeGeometry(strokes: [
                  BorderStroke(
                      id: 'stroke',
                      closed: false,
                      points: const [GridPos(x: 1, y: 1), GridPos(x: 2, y: 1)])
                ]))
          ]))
    ]);
    final maps = [catalogMap('a'), map];
    final project = _withMaps(informationFixture(), maps)
        .copyWith(borderCatalog: retainedElementBorder());
    final snapshot = librarySnapshot(maps, project: project);
    expect(
        resourceLibraryMapUsages(snapshot, 'borderBlueprint', 'border'), {'b'});
    expect(resourceLibraryMapUsages(snapshot, 'element', 'decor'), {'b'});
    expect(resourceLibraryMapUsages(snapshot, 'tileset', 'sheet'), {'b'});
    await _expectScopeRefusal(snapshot, 'borderBlueprint', 'border');
    await _expectScopeRefusal(snapshot, 'element', 'decor');
  });

  test('environment scope follows areas and transitive palette dependencies',
      () async {
    final map = catalogMap('b').copyWith(layers: [
      ...catalogMap('b').layers,
      MapLayer.environment(
          id: 'forest',
          name: 'Forêt',
          content: EnvironmentLayerContent(targetTileLayerId: 'base', areas: [
            EnvironmentArea(
                id: 'area',
                name: 'Zone',
                presetId: 'forest',
                mask: EnvironmentAreaMask(
                    width: 6, height: 5, cells: List.filled(30, true)),
                seed: 7)
          ]))
    ]);
    final maps = [catalogMap('a'), map];
    final project =
        _withMaps(informationFixture(), maps).copyWith(environmentPresets: [
      EnvironmentPreset(
          id: 'forest',
          name: 'Forêt',
          templateId: 'forest',
          palette: [EnvironmentPaletteItem(elementId: 'decor', weight: 1)],
          defaultParams: EnvironmentGenerationParams(
              density: 1, variation: 0, edgeDensity: 1, minSpacingCells: 0),
          sortOrder: 0)
    ]);
    final snapshot = librarySnapshot(maps, project: project);
    expect(resourceLibraryMapUsages(snapshot, 'environmentPreset', 'forest'),
        {'b'});
    expect(resourceLibraryMapUsages(snapshot, 'element', 'decor'), {'b'});
    expect(resourceLibraryMapUsages(snapshot, 'tileset', 'sheet'), {'b'});
    await _expectScopeRefusal(snapshot, 'environmentPreset', 'forest');
    await _expectScopeRefusal(snapshot, 'element', 'decor');
  });

  test('dialogue character references retain the map owning the dialogue', () {
    final maps = [
      catalogMap('a'),
      catalogMap('b').copyWith(entities: const [
        MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(dialogue: DialogueRef(dialogueId: 'talk')))
      ])
    ];
    final project =
        _withMaps(informationFixture(), maps).copyWith(characters: const [
      ProjectCharacterEntry(id: 'person', name: 'Personne', tilesetId: 'sheet')
    ], dialogues: const [
      ProjectDialogueEntry(
          id: 'talk', name: 'Talk', relativePath: 'dialogues/talk.yarn')
    ]);
    final snapshot =
        librarySnapshot(maps, project: project, referenceDocuments: {
      'dialogueSource:talk':
          utf8.encode('title: Start\n---\n<<speaker person>>\nBonjour\n===')
    });
    expect(resourceLibraryMapUsages(snapshot, 'character', 'person'), {'b'});
  });

  test('dialogue source updates validate the replacement character usage',
      () async {
    final maps = [
      catalogMap('a'),
      catalogMap('b').copyWith(entities: const [
        MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(dialogue: DialogueRef(dialogueId: 'talk')))
      ])
    ];
    final project = _withMaps(informationFixture(), maps).copyWith(
        characters: const [
          ProjectCharacterEntry(
              id: 'person', name: 'Personne', tilesetId: 'sheet')
        ],
        dialogues: const [
          ProjectDialogueEntry(
              id: 'talk', name: 'Talk', relativePath: 'dialogues/talk.yarn')
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
          ResourceLibraryEntry(
              resourceKind: 'character', resourceId: 'person', mapId: 'a')
        ]));
    final snapshot = librarySnapshot(maps,
        project: project,
        referenceDocuments: {
          'dialogueSource:talk': utf8.encode('title: Start\n---\nBonjour\n===')
        });
    await expectLater(
        () => MapMutationDispatcher.canonical()
                .build(catalogContext(snapshot, 'dialogue.source_update', {
              'dialogueId': 'talk',
              'source': 'title: Start\n---\n<<speaker person>>\nBonjour\n==='
            })),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'resource_library.scope_conflict')));
  });

  test(
      'deleting an unused dialogue removes its usage document with local assets',
      () async {
    final maps = [catalogMap('a'), catalogMap('b')];
    final project = _withMaps(informationFixture(), maps).copyWith(
        characters: const [
          ProjectCharacterEntry(
              id: 'person', name: 'Personne', tilesetId: 'sheet')
        ],
        dialogues: const [
          ProjectDialogueEntry(
              id: 'talk', name: 'Talk', relativePath: 'dialogues/talk.yarn')
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
          ResourceLibraryEntry(
              resourceKind: 'character', resourceId: 'person', mapId: 'a')
        ]));
    final snapshot = librarySnapshot(maps,
        project: project,
        referenceDocuments: {
          'dialogueSource:talk': utf8.encode('title: Start\n---\nBonjour\n===')
        });
    final draft = await MapMutationDispatcher.canonical().build(
        catalogContext(snapshot, 'dialogue.delete', {'dialogueId': 'talk'}));
    final projected = ProjectManifest.fromJson(Map<String, dynamic>.from(
        jsonDecode(utf8.decode(draft.changeSet.changes
            .singleWhere((change) => change.resource.kind == 'project')
            .afterBytes!)) as Map));
    expect(projected.dialogues, isEmpty);
    expect(
        draft.changeSet.changes.any((change) =>
            change.resource.kind == 'dialogue' && change.afterBytes == null),
        isTrue);
  });

  test('the default player character is a project-wide consumer', () async {
    final maps = [catalogMap('a'), catalogMap('b')];
    final project = _withMaps(informationFixture(), maps).copyWith(
        settings: const ProjectSettings(defaultPlayerCharacterId: 'person'),
        characters: const [
          ProjectCharacterEntry(
              id: 'person', name: 'Personne', tilesetId: 'sheet')
        ]);
    final snapshot = librarySnapshot(maps, project: project);
    expect(
        resourceLibraryMapUsages(snapshot, 'character', 'person'), {'a', 'b'});
    await _expectScopeRefusal(snapshot, 'character', 'person');
  });

  test('event scene dialogue closes the transitive character map usage',
      () async {
    final maps = [catalogMap('a'), librarySceneMap('b')];
    final project =
        librarySceneProject(maps, SceneYarnDialoguePayload(dialogueId: 'talk'));
    final snapshot =
        librarySnapshot(maps, project: project, referenceDocuments: {
      'dialogueSource:talk':
          utf8.encode('title: Start\n---\n<<speaker person>>\nBonjour\n===')
    });
    expect(resourceLibraryMapUsages(snapshot, 'character', 'person'), {'b'});
    await _expectScopeRefusal(snapshot, 'character', 'person');
  });

  test(
      'event scene world cinematic closes appearance usage without catalog consumers',
      () async {
    final maps = [catalogMap('a'), librarySceneMap('b')];
    final project = librarySceneProject(
        maps, SceneCinematicPayload(cinematicId: 'cutscene'));
    final snapshot = librarySnapshot(maps,
        project: project,
        referenceDocuments: {
          'dialogueSource:talk': utf8.encode('title: Start\n---\nBonjour\n===')
        });
    expect(resourceLibraryMapUsages(snapshot, 'character', 'person'), {'b'});
    await _expectScopeRefusal(snapshot, 'character', 'person');
  });

  test('map-bound cinematic appearance keeps its actual map ownership',
      () async {
    final maps = [catalogMap('a'), catalogMap('b')];
    final project =
        _withMaps(informationFixture(), maps).copyWith(characters: const [
      ProjectCharacterEntry(id: 'person', name: 'Personne', tilesetId: 'sheet')
    ], cinematics: [
      CinematicAsset(
          id: 'cutscene',
          title: 'Scène',
          mapId: 'b',
          timeline: CinematicTimeline(steps: const []),
          stageContext: CinematicStageContext(actorAppearanceBindings: [
            CinematicActorAppearanceBinding(
                actorId: 'npc', characterId: 'person')
          ]))
    ]);
    final snapshot = librarySnapshot(maps, project: project);
    expect(resourceLibraryMapUsages(snapshot, 'character', 'person'), {'b'});
    expect(resourceLibraryMapUsages(snapshot, 'tileset', 'sheet'), {'b'});
    await _expectScopeRefusal(snapshot, 'character', 'person');
  });

  test(
      'deleting an unused resource cleans catalog and duplication inherits typed metadata',
      () async {
    final project = informationFixture().copyWith(
        resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
      ResourceLibraryEntry(
          resourceKind: 'element',
          resourceId: 'decor',
          familyId: 'trees',
          role: ResourceLibraryRole.component)
    ]));
    final duplicated = await _apply(project, 'element.duplicate', {
      'sourceElementId': 'decor',
      'newElementId': 'copy',
      'name': 'Copy',
      'categoryId': 'shared'
    });
    expect(
        duplicated.resourceLibraryCatalog.entryFor('element', 'copy')?.familyId,
        'trees');
    expect(duplicated.resourceLibraryCatalog.entryFor('element', 'copy')?.role,
        ResourceLibraryRole.component);
    final deleted =
        await _apply(project, 'element.delete', {'elementId': 'decor'});
    expect(deleted.resourceLibraryCatalog.entries, isEmpty);
  });

  test('map copy and delete cannot silently broaden local assets', () async {
    final map = catalogMap('a').copyWith(placedElements: [_placed()]);
    final project = _withMaps(informationFixture(), [map]).copyWith(
        resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
      ResourceLibraryEntry(
          resourceKind: 'element', resourceId: 'decor', mapId: 'a')
    ]));
    final snapshot = librarySnapshot([map], project: project);
    await expectLater(
        () => MapMutationDispatcher.canonical().build(catalogContext(
            snapshot,
            'map.duplicate',
            {'sourceMapId': 'a', 'targetMapId': 'b', 'name': 'B'})),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'resource_library.scope_conflict')));
    await expectLater(
        () => MapMutationDispatcher.canonical().build(
            catalogContext(snapshot, 'map.delete_apply', {'mapId': 'a'})),
        throwsA(isA<VisualLibraryException>().having((error) => error.code,
            'code', 'resource_library.map_has_local_resources')));
  });

  test('model usages remain distinct from element identities in spatial maps',
      () {
    final model = ProjectModel3dEntry(
        id: 'decor',
        name: 'Model',
        sourceAssetId: 'model',
        relativePath: 'assets/models3d/decor.glb',
        inspection: Model3dInspection(
            bounds: Model3dBounds(
                min: Model3dVector3.zero,
                max: Model3dVector3(x: 1, y: 1, z: 1)),
            meshCount: 1,
            triangleCount: 1));
    final map = MapData(
        id: 'a',
        name: 'A',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        spatialScene: MapSpatialScene(width: 4, depth: 4, instances: [
          SpatialModelInstance(
              id: 'instance', modelId: 'decor', position: Model3dVector3.zero)
        ]));
    final project =
        _withMaps(informationFixture(), [map]).copyWith(models3d: [model]);
    final snapshot = librarySnapshot([map], project: project);
    expect(resourceLibraryMapUsages(snapshot, 'model3d', 'decor'), {'a'});
    expect(resourceLibraryMapUsages(snapshot, 'element', 'decor'), isEmpty);
  });

  test('canonical spatial placement enforces the same owner map scope',
      () async {
    final model = ProjectModel3dEntry(
        id: 'tree',
        name: 'Tree',
        sourceAssetId: 'model',
        relativePath: 'assets/models3d/tree.glb',
        inspection: Model3dInspection(
            bounds: Model3dBounds(
                min: Model3dVector3.zero,
                max: Model3dVector3(x: 1, y: 1, z: 1)),
            meshCount: 1,
            triangleCount: 1));
    final maps = [
      for (final id in ['a', 'b'])
        MapData(
            id: id,
            name: id,
            version: ProjectVersion.v9,
            size: const GridSize(width: 4, height: 4),
            spatialScene: MapSpatialScene(width: 4, depth: 4))
    ];
    final project = _withMaps(
        ProjectManifest(
            name: 'Spatial library',
            version: ProjectVersion.v9,
            maps: [],
            tilesets: [],
            models3d: [model],
            settings: ProjectSettings(
                dimension: ProjectDimension.threeD,
                spatialCamera: SpatialCameraProfile()),
            resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
              ResourceLibraryEntry(
                  resourceKind: 'model3d',
                  resourceId: 'tree',
                  familyId: 'trees',
                  mapId: 'a')
            ])),
        maps);
    final snapshot = librarySnapshot(maps, project: project);
    final instance = SpatialModelInstance(
        id: 'placed',
        modelId: 'tree',
        position: Model3dVector3(x: 1, y: 0, z: 1));
    final dispatcher = MapMutationDispatcher.canonical();
    expect(
        (await dispatcher.build(catalogContext(
                snapshot,
                'map3d.instance.upsert',
                {'mapId': 'a', 'instance': instance.toJson()})))
            .changeSet
            .changes,
        hasLength(1));
    await expectLater(
        () => dispatcher.build(catalogContext(snapshot, 'map3d.instance.upsert',
            {'mapId': 'b', 'instance': instance.toJson()})),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'resource_library.scope_conflict')));
  });
}

MapData librarySceneMap(String id) => catalogMap(id).copyWith(events: const [
      MapEventDefinition(
          id: 'event',
          title: 'Événement',
          position: EventPosition(layerId: 'base', x: 1, y: 1),
          pages: [
            MapEventPage(
                pageNumber: 0,
                sceneTarget: MapEventSceneTarget(sceneId: 'scene'))
          ])
    ]);

ProjectManifest librarySceneProject(
        List<MapData> maps, SceneNodePayload payload) =>
    _withMaps(informationFixture(), maps).copyWith(
        characters: const [
          ProjectCharacterEntry(
              id: 'person', name: 'Personne', tilesetId: 'sheet')
        ],
        dialogues: const [
          ProjectDialogueEntry(
              id: 'talk', name: 'Talk', relativePath: 'dialogues/talk.yarn')
        ],
        scenes: [
          SceneAsset(
              id: 'scene',
              name: 'Scene',
              graph: SceneGraph(startNodeId: 'start', nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                    id: 'consume',
                    kind: payload is SceneCinematicPayload
                        ? SceneNodeKind.cinematic
                        : SceneNodeKind.yarnDialogue,
                    payload: payload),
                SceneNode(id: 'end', kind: SceneNodeKind.end)
              ], edges: [
                SceneEdge(
                    id: 'start-consume',
                    fromNodeId: 'start',
                    fromPortId: 'completed',
                    toNodeId: 'consume',
                    kind: SceneEdgeKind.defaultFlow),
                SceneEdge(
                    id: 'consume-end',
                    fromNodeId: 'consume',
                    fromPortId: 'completed',
                    toNodeId: 'end',
                    kind: payload is SceneCinematicPayload
                        ? SceneEdgeKind.cinematicCompleted
                        : SceneEdgeKind.dialogueOutcome)
              ]))
        ],
        cinematicLibraryCatalog: CinematicLibraryCatalog(entries: [
          CinematicLibraryEntry(
              family: CinematicLibraryFamily.world,
              cinematicId: 'cutscene',
              sortOrder: 0)
        ]),
        cinematics: [
          CinematicAsset(
              id: 'cutscene',
              title: 'Scène',
              timeline: CinematicTimeline(steps: const []),
              stageContext: CinematicStageContext(actorAppearanceBindings: [
                CinematicActorAppearanceBinding(
                    actorId: 'npc', characterId: 'person')
              ]))
        ]);

Future<void> _expectScopeRefusal(
    ProjectSnapshot snapshot, String kind, String id) async {
  await expectLater(
      () => MapMutationDispatcher.canonical().build(catalogContext(
          snapshot,
          'resource.classify',
          {'resourceKind': kind, 'resourceId': id, 'mapId': 'a'})),
      throwsA(isA<VisualLibraryException>().having(
          (error) => error.code, 'code', 'resource_library.scope_conflict')));
}

MapPlacedElement _placed() => const MapPlacedElement(
    id: 'placed',
    layerId: 'base',
    elementId: 'decor',
    pos: GridPos(x: 1, y: 1));
ProjectManifest _withMaps(ProjectManifest project, List<MapData> maps) =>
    project.copyWith(maps: [
      for (final map in maps)
        ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
    ]);
Future<ProjectManifest> _apply(ProjectManifest project, String action,
    Map<String, Object?> parameters) async {
  final draft = await MapMutationDispatcher.canonical().build(catalogContext(
      librarySnapshot([], project: project), action, parameters));
  if (draft.changeSet.changes.isEmpty) return project;
  return ProjectManifest.fromJson(Map<String, dynamic>.from(jsonDecode(
      utf8.decode(draft.changeSet.changes
          .firstWhere((change) => change.resource.kind == 'project')
          .afterBytes!)) as Map));
}

ProjectSnapshot librarySnapshot(List<MapData> maps,
    {required ProjectManifest project,
    Map<String, List<int>> referenceDocuments = const {}}) {
  final snapshot = elementSnapshot(project, maps: maps);
  final resources = {
    for (final id in snapshot.resourceFingerprints.keys)
      id: snapshot.resourceBytes(id),
    ...referenceDocuments,
  };
  final storageKeys = {
    'project': 'project.json',
    for (final map in maps) 'map:${map.id}': 'maps/${map.id}.json',
    for (final entry in project.dialogues)
      if (resources.containsKey('dialogueSource:${entry.id}'))
        'dialogueSource:${entry.id}': entry.relativePath,
  };
  return ProjectSnapshot(
      projectHandle: snapshot.projectHandle,
      revision: snapshot.revision,
      manifest: project,
      maps: maps,
      pokemonInventoryComplete: true,
      resourceFingerprints: {
        for (final entry in resources.entries)
          entry.key: computeAuthoringBytesFingerprint(entry.value,
              logicalName: storageKeys[entry.key] ?? entry.key),
      },
      resourceBytes: resources,
      resourceStorageKeys: storageKeys);
}
