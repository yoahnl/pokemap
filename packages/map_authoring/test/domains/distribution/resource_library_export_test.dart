import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_actions_test.dart'
    show informationFixture;
import '../assets/resource_information_fixture.dart'
    show smartInformationFixture;
import '../maps/map_catalog_fixture.dart' show catalogMap;
import '../assets/resource_library_actions_test.dart'
    show librarySceneMap, librarySceneProject;

void main() {
  for (final payload in [
    SceneYarnDialoguePayload(dialogueId: 'talk'),
    SceneCinematicPayload(cinematicId: 'cutscene')
  ]) {
    test(
        'canonical export rejects event scene ${payload.runtimeType} using another map local character',
        () async {
      final maps = [catalogMap('a'), librarySceneMap('b')];
      final project = librarySceneProject(maps, payload).copyWith(
          pokemon: const ProjectPokemonConfig(
              enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1),
          resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
            ResourceLibraryEntry(
                resourceKind: 'character', resourceId: 'person', mapId: 'a')
          ]));
      final root = await _writeSource(project, maps);
      final dialogue = File('${root.path}/dialogues/talk.yarn');
      await dialogue.parent.create(recursive: true);
      await dialogue
          .writeAsString('title: Start\n---\n<<speaker person>>\nBonjour\n===');
      await expectLater(
          () => const CanonicalGamePackageExportService().build(
              projectRoot: root,
              profile: _profile,
              mode: GamePackageExportMode.localTest),
          _scopeConflict);
    });
  }
  test('canonical export rejects unknown catalog resources and scopes',
      () async {
    for (final entry in [
      ResourceLibraryEntry(resourceKind: 'element', resourceId: 'missing'),
      ResourceLibraryEntry(
          resourceKind: 'element', resourceId: 'decor', mapId: 'missing')
    ]) {
      final project = informationFixture().copyWith(
          pokemon: const ProjectPokemonConfig(
              enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1),
          resourceLibraryCatalog: ResourceLibraryCatalog(entries: [entry]));
      final root = await _writeSource(project, []);
      await expectLater(
          () => const CanonicalGamePackageExportService().build(
              projectRoot: root,
              profile: _profile,
              mode: GamePackageExportMode.localTest),
          throwsA(isA<GamePackageExportException>().having(
              (error) => error.code, 'code', 'resource_library.invalid')));
    }
  });

  test(
      'canonical export rejects local smart tile use before spatial projection',
      () async {
    final maps = [
      catalogMap('a'),
      catalogMap('b').copyWith(layers: [
        MapLayer.smartTile(
            id: 'ground',
            name: 'Sol',
            presetId: 'ground',
            usage: SmartTileUsage.terrain,
            field: SmartTileField.cell(semanticCells: List.filled(30, 0)))
      ])
    ];
    final source = smartInformationFixture();
    final project = _withMaps(
        source.copyWith(
            version: ProjectVersion.v9,
            settings: ProjectSettings(
                dimension: ProjectDimension.threeD,
                spatialCamera: SpatialCameraProfile()),
            resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
              ResourceLibraryEntry(
                  resourceKind: 'smartTilePreset',
                  resourceId: 'ground',
                  mapId: 'a')
            ])),
        maps);
    final root = await _writeSource(project, maps);
    await expectLater(
        () => const CanonicalGamePackageExportService().build(
            projectRoot: root,
            profile: _profile,
            mode: GamePackageExportMode.localTest),
        _scopeConflict);
  });

  test('export retains a valid local classification and source map usage',
      () async {
    final maps = [
      catalogMap('a').copyWith(placedElements: const [
        MapPlacedElement(
            id: 'placed',
            layerId: 'base',
            elementId: 'decor',
            pos: GridPos(x: 1, y: 1))
      ]),
      catalogMap('b')
    ];
    final catalog = ResourceLibraryCatalog(families: [
      ResourceFamily(id: 'forest-a', name: 'Forêt A', parentId: 'trees')
    ], entries: [
      ResourceLibraryEntry(
          resourceKind: 'element',
          resourceId: 'decor',
          familyId: 'forest-a',
          mapId: 'a')
    ]);
    final project = _withMaps(
        informationFixture().copyWith(resourceLibraryCatalog: catalog), maps);
    final root = await _writeSource(project, maps);
    final projection = await const RuntimeProjectProjectionBuilder()
        .build(projectRoot: root, profile: _profile);
    expect(projection.project.resourceLibraryCatalog, catalog);
    final exported = ProjectManifest.fromJson(jsonDecode(
            utf8.decode(projection.payloadFiles['project/project.json']!))
        as Map<String, dynamic>);
    expect(exported.resourceLibraryCatalog, catalog);
    expect(
        jsonDecode(
            utf8.decode(projection.payloadFiles['project/maps/a.json']!)),
        maps.first.toJson());
  });

  test('export scopes character references through compiled dialogue ownership',
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
    final project = _withMaps(
        informationFixture().copyWith(
            dialogues: const [
              ProjectDialogueEntry(
                  id: 'talk', name: 'Talk', relativePath: 'dialogues/talk.json')
            ],
            characters: const [
              ProjectCharacterEntry(
                  id: 'person', name: 'Personne', tilesetId: 'sheet')
            ],
            resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
              ResourceLibraryEntry(
                  resourceKind: 'character', resourceId: 'person', mapId: 'a')
            ])),
        maps);
    final root = await _writeSource(project, maps);
    final dialogue = File('${root.path}/dialogues/talk.json');
    await dialogue.parent.create(recursive: true);
    await dialogue.writeAsBytes(const RuntimeDialogueDocumentCodec()
        .encodeUtf8(RuntimeDialogueDocument(nodes: [
      RuntimeDialogueNode(
          title: 'Start',
          steps: [RuntimeDialogueLine('Bonjour', characterId: 'person')])
    ])));
    await expectLater(
        () => const CanonicalGamePackageExportService().build(
            projectRoot: root,
            profile: _profile,
            mode: GamePackageExportMode.localTest),
        _scopeConflict);
  });

  test(
      'export rejects map identity mismatches instead of missing scope consumers',
      () async {
    final map = catalogMap('other').copyWith(placedElements: const [
      MapPlacedElement(
          id: 'placed',
          layerId: 'base',
          elementId: 'decor',
          pos: GridPos(x: 1, y: 1))
    ]);
    final project = _withMaps(
        informationFixture().copyWith(
            resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
          ResourceLibraryEntry(
              resourceKind: 'element', resourceId: 'decor', mapId: 'a')
        ])),
        [catalogMap('a')]);
    final root = await _writeSource(project, []);
    final file = File('${root.path}/maps/a.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map.toJson()));
    await expectLater(
        () => const RuntimeProjectProjectionBuilder()
            .build(projectRoot: root, profile: _profile),
        throwsA(isA<GamePackageExportException>().having((error) => error.code,
            'code', 'resource_library.usage_incomplete')));
  });
  test('canonical export refuses a cinematic using another map local character',
      () async {
    final maps = [catalogMap('a'), catalogMap('b')];
    final project = _withMaps(
        informationFixture().copyWith(
            characters: const [
              ProjectCharacterEntry(
                  id: 'person', name: 'Personne', tilesetId: 'sheet')
            ],
            cinematics: [
              CinematicAsset(
                  id: 'cutscene',
                  title: 'Scène',
                  mapId: 'b',
                  timeline: CinematicTimeline(steps: const []),
                  stageContext: CinematicStageContext(actorAppearanceBindings: [
                    CinematicActorAppearanceBinding(
                        actorId: 'npc', characterId: 'person')
                  ]))
            ],
            resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
              ResourceLibraryEntry(
                  resourceKind: 'character', resourceId: 'person', mapId: 'a')
            ])),
        maps);
    final root = await _writeSource(project, maps);
    await expectLater(
        () => const CanonicalGamePackageExportService().build(
            projectRoot: root,
            profile: _profile,
            mode: GamePackageExportMode.localTest),
        _scopeConflict);
  });
}

final _scopeConflict = throwsA(isA<GamePackageExportException>()
    .having((error) => error.code, 'code', 'resource_library.scope_conflict'));

final _profile = GamePackageExportProfile(
    gameId: 'games.test.resource-library',
    gameVersion: '0.1.0',
    title: 'Resource library',
    authorName: 'Tester',
    defaultLocale: 'en',
    supportedLocales: const ['en']);

ProjectManifest _withMaps(ProjectManifest project, List<MapData> maps) =>
    project.copyWith(
        pokemon: const ProjectPokemonConfig(
            enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1),
        maps: [
          for (final map in maps)
            ProjectMapEntry(
                id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
        ]);

Future<Directory> _writeSource(
    ProjectManifest project, List<MapData> maps) async {
  final root =
      await Directory.systemTemp.createTemp('resource-library-export-');
  addTearDown(() => root.delete(recursive: true));
  await File('${root.path}/project.json')
      .writeAsString(jsonEncode(project.toJson()));
  for (final map in maps) {
    final file = File('${root.path}/maps/${map.id}.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map.toJson()));
  }
  return root;
}
