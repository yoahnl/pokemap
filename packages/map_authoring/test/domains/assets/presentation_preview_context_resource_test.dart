import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('presentationPreviewContext resource', () {
    test('projects every real project-backed preview context', () {
      final snapshot = _snapshot();
      final before = jsonEncode(snapshot.manifest.toJson());
      final page = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'presentationPreviewContext',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
        ),
      );

      expect(page.snapshotRevision, _revision);
      expect(page.totalAvailable, 8);
      expect(
        page.items.map((item) => item['id']),
        <String>[
          'characterPortrait:leo:happy',
          'dialogue:welcome',
          'dialogueScenario:welcome:0:0',
          'dialogueScenario:welcome:0:1',
          'dialogueScenario:welcome:0:2',
          'encounter:grass',
          'map:village',
          'map:woods',
        ],
      );
      expect(
        page.items.map((item) => item['contextKind']).toSet(),
        <String>{
          'map',
          'dialogue',
          'dialogueScenario',
          'characterPortrait',
          'encounter',
        },
      );
      expect(jsonEncode(snapshot.manifest.toJson()), before);
    });

    test('exposes usable references and explicit degraded diagnostics', () {
      final map = _get('map:village');
      final missingMap = _get('map:woods');
      final dialogue = _get('dialogue:welcome');
      final portrait = _get('characterPortrait:leo:happy');
      final characterLine = _get('dialogueScenario:welcome:0:0');
      final textLine = _get('dialogueScenario:welcome:0:1');
      final choice = _get('dialogueScenario:welcome:0:2');
      final encounter = _get('encounter:grass');

      expect(map['availability'], 'ready');
      expect((map['map']! as Map)['id'], 'village');
      expect(missingMap['availability'], 'degraded');
      expect(
        missingMap['diagnosticCodes'],
        <Object?>['previewContext.mapSourceUnavailable'],
      );
      expect(dialogue['sourceAvailable'], isTrue);
      expect(dialogue['relativePath'], 'dialogues/welcome.yarn');
      expect(portrait['portraitAssetId'], 'portrait-leo-happy');
      expect(portrait['portraitPath'], 'characters/leo/happy.png');
      expect(portrait['portraitStateLabel'], 'Joyeux');
      expect(characterLine['availability'], 'ready');
      expect(characterLine['scenarioKind'], 'characterLine');
      expect(characterLine['text'], 'Bienvenue !');
      expect(characterLine['characterId'], 'leo');
      expect(characterLine['characterName'], 'Léo');
      expect(characterLine['portraitStateId'], 'happy');
      expect(characterLine['portraitStateLabel'], 'Joyeux');
      expect(characterLine['portraitAssetId'], 'portrait-leo-happy');
      expect(characterLine['portraitPath'], 'characters/leo/happy.png');
      expect(textLine['scenarioKind'], 'textLine');
      expect(textLine['text'], 'Le vent se lève sur le village.');
      expect(textLine, isNot(contains('characterId')));
      expect(choice['scenarioKind'], 'choice');
      expect(choice['choices'], <Object?>[
        <String, Object?>{'label': 'Explorer'},
        <String, Object?>{'label': 'Rester'},
      ]);
      expect(encounter['entries'], <Object?>[
        <String, Object?>{
          'speciesId': 'roucool',
          'minLevel': 4,
          'maxLevel': 6,
          'weight': 1,
        },
      ]);
      expect((encounter['playerPokemon']! as Map)['speciesId'], 'brindibou');
      expect(
        (encounter['battleMediaDiagnostics']! as List),
        <Object?>[
          'previewContext.enemyBattleSpriteUnavailable',
          'previewContext.playerBattleSpriteUnavailable',
        ],
      );
    });

    test('keeps deterministic pagination bound to the snapshot revision', () {
      final first = const ProjectQueryService().query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'presentationPreviewContext',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.summary,
          pageSize: 2,
        ),
      );
      final second = const ProjectQueryService().query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'presentationPreviewContext',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.summary,
          pageSize: 2,
          cursor: first.nextCursor,
        ),
      );

      expect(first.items, hasLength(2));
      expect(first.nextCursor, isNotNull);
      expect(second.items, hasLength(2));
      expect(second.snapshotRevision, _revision);
      expect(second.items.first['id'], 'dialogueScenario:welcome:0:0');
    });

    test('marks combat context degraded without a playable party', () {
      final context = const PresentationPreviewContextProjector()
          .project(
            manifest: const ProjectManifest(
              name: 'No party',
              maps: <ProjectMapEntry>[],
              tilesets: <ProjectTilesetEntry>[],
              encounterTables: <ProjectEncounterTable>[
                ProjectEncounterTable(
                  id: 'grass',
                  name: 'Herbes',
                  encounterKind: EncounterKind.walk,
                  entries: <ProjectEncounterEntry>[
                    ProjectEncounterEntry(
                      speciesId: 'roucool',
                      minLevel: 4,
                      maxLevel: 4,
                    ),
                  ],
                ),
              ],
            ),
            workspaceRevision: _revision,
            maps: const <MapData>[],
            dialogueSourceText: (_) => null,
            portraitAssetPath: (_) => null,
          )
          .single
          .detail;

      expect(context['availability'], 'degraded');
      expect(
        context['diagnosticCodes'],
        <Object?>['previewContext.playerPokemonUnavailable'],
      );
      expect(context, isNot(contains('playerPokemon')));
    });

    test(
        'projects resolved battle names and sprites without persisting a selection',
        () {
      final context = const PresentationPreviewContextProjector()
          .project(
            manifest: const ProjectManifest(
              name: 'Resolved battle',
              maps: <ProjectMapEntry>[],
              tilesets: <ProjectTilesetEntry>[],
              encounterTables: <ProjectEncounterTable>[
                ProjectEncounterTable(
                  id: 'grass',
                  name: 'Herbes',
                  encounterKind: EncounterKind.walk,
                  entries: <ProjectEncounterEntry>[
                    ProjectEncounterEntry(
                      speciesId: 'enemy-species',
                      minLevel: 4,
                      maxLevel: 4,
                    ),
                  ],
                ),
              ],
              newGame: ProjectNewGameConfig(
                initialParty: <PlayerPokemon>[
                  PlayerPokemon(
                    speciesId: 'player-species',
                    natureId: 'hardy',
                    abilityId: 'starter',
                    level: 5,
                  ),
                ],
              ),
            ),
            workspaceRevision: _revision,
            maps: const <MapData>[],
            dialogueSourceText: (_) => null,
            portraitAssetPath: (_) => null,
            speciesDisplayName: (id) =>
                id == 'enemy-species' ? 'Adversaire réel' : 'Partenaire réel',
            battleSpritePath: (id, playerSide) => playerSide
                ? 'assets/pokemon/player-back.png'
                : 'assets/pokemon/enemy-front.png',
          )
          .single
          .detail;

      expect((context['entries']! as List).single,
          containsPair('displayName', 'Adversaire réel'));
      expect((context['entries']! as List).single,
          containsPair('battleSpritePath', 'assets/pokemon/enemy-front.png'));
      expect(context['playerPokemon'],
          containsPair('displayName', 'Partenaire réel'));
      expect(context['playerPokemon'],
          containsPair('battleSpritePath', 'assets/pokemon/player-back.png'));
      expect(context['battleMediaDiagnostics'], isEmpty);
      expect(context, isNot(contains('selectedCreatureId')));
    });

    test('reports missing species and battle media without inventing them', () {
      final context = const PresentationPreviewContextProjector()
          .project(
            manifest: const ProjectManifest(
              name: 'Missing battle media',
              maps: <ProjectMapEntry>[],
              tilesets: <ProjectTilesetEntry>[],
              encounterTables: <ProjectEncounterTable>[
                ProjectEncounterTable(
                  id: 'grass',
                  name: 'Herbes',
                  encounterKind: EncounterKind.walk,
                  entries: <ProjectEncounterEntry>[
                    ProjectEncounterEntry(
                      speciesId: 'unknown-enemy',
                      minLevel: 4,
                      maxLevel: 4,
                    ),
                  ],
                ),
              ],
              newGame: ProjectNewGameConfig(
                initialParty: <PlayerPokemon>[
                  PlayerPokemon(
                    speciesId: 'unknown-player',
                    natureId: 'hardy',
                    abilityId: 'starter',
                    level: 5,
                  ),
                ],
              ),
            ),
            workspaceRevision: _revision,
            maps: const <MapData>[],
            dialogueSourceText: (_) => null,
            portraitAssetPath: (_) => null,
            speciesDisplayName: (_) => null,
            battleSpritePath: (_, __) => null,
          )
          .single
          .detail;

      expect(
        (context['entries']! as List).single,
        isNot(contains('displayName')),
      );
      expect(
        (context['entries']! as List).single,
        isNot(contains('battleSpritePath')),
      );
      expect(
        context['battleMediaDiagnostics'],
        <Object?>[
          'previewContext.enemyBattleSpriteUnavailable',
          'previewContext.playerBattleSpriteUnavailable',
        ],
      );
    });

    test('reports orphan dialogue references without inventing a portrait', () {
      final contexts = const PresentationPreviewContextProjector().project(
        manifest: const ProjectManifest(
          name: 'Orphan dialogue',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          dialogues: <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'orphan',
              name: 'Orphelin',
              relativePath: 'dialogues/orphan.yarn',
            ),
          ],
        ),
        workspaceRevision: _revision,
        maps: const <MapData>[],
        dialogueSourceText: (_) =>
            'title: Start\n---\n<<portrait inconnu triste>>\nBonjour.\n===',
        portraitAssetPath: (_) => null,
      );
      final scenario = contexts
          .singleWhere(
            (context) => context.detail['contextKind'] == 'dialogueScenario',
          )
          .detail;

      expect(scenario['availability'], 'degraded');
      expect(scenario['characterId'], 'inconnu');
      expect(scenario, isNot(contains('portraitAssetId')));
      expect(scenario['diagnosticCodes'], <Object?>[
        'previewContext.dialogueCharacterUnknown',
        'previewContext.dialoguePortraitStateUnknown',
      ]);
    });

    test('keeps the legacy dialogue context when source compilation fails', () {
      final contexts = const PresentationPreviewContextProjector().project(
        manifest: const ProjectManifest(
          name: 'Invalid dialogue',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          dialogues: <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'invalid',
              name: 'Invalide',
              relativePath: 'dialogues/invalid.yarn',
            ),
          ],
        ),
        workspaceRevision: _revision,
        maps: const <MapData>[],
        dialogueSourceText: (_) => 'not yarn',
        portraitAssetPath: (_) => null,
      );

      expect(contexts, hasLength(1));
      expect(contexts.single.detail['id'], 'dialogue:invalid');
      expect(contexts.single.detail['sourceAvailable'], isTrue);
    });
  });
}

Map<String, Object?> _get(String id) {
  return const ProjectQueryService()
      .query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'presentationPreviewContext',
          operation: AuthoringQueryOperation.get,
          view: AuthoringQueryView.detail,
          ids: <String>[id],
        ),
      )
      .items
      .single;
}

const _revision =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

ProjectSnapshot _snapshot() {
  const manifest = ProjectManifest(
    name: 'Preview contexts',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'woods',
        name: 'Bois Vermeil',
        relativePath: 'maps/woods.json',
      ),
      ProjectMapEntry(
        id: 'village',
        name: 'Village Vermeil',
        relativePath: 'maps/village.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    dialogues: <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'welcome',
        name: 'Bienvenue',
        relativePath: 'dialogues/welcome.yarn',
      ),
    ],
    encounterTables: <ProjectEncounterTable>[
      ProjectEncounterTable(
        id: 'grass',
        name: 'Herbes du village',
        encounterKind: EncounterKind.walk,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'roucool',
            minLevel: 4,
            maxLevel: 6,
          ),
        ],
      ),
    ],
    characterStudioCatalog: ProjectCharacterStudioCatalog(
      portraitStates: <CharacterPortraitStateDefinition>[
        CharacterPortraitStateDefinition(
          id: 'happy',
          displayName: 'Joyeux',
        ),
      ],
    ),
    characters: <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'leo',
        name: 'Léo',
        tilesetId: 'leo-sheet',
        portraits: <CharacterPortraitVariant>[
          CharacterPortraitVariant(
            portraitStateId: 'happy',
            assetId: 'portrait-leo-happy',
          ),
        ],
      ),
    ],
    newGame: ProjectNewGameConfig(
      initialParty: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'brindibou',
          natureId: 'hardy',
          abilityId: 'engrais',
          level: 8,
          currentHp: 24,
          knownMoveIds: <String>['charge'],
        ),
      ],
    ),
  );
  final projectBytes = utf8.encode(jsonEncode(manifest.toJson()));
  final assetCatalog = AssetCatalog(
    records: <AssetRecord>[
      AssetRecord(
        id: 'portrait-leo-happy',
        logicalPath: 'characters/leo/happy.png',
        artifact: ContentArtifactRef.fromBytes(
          const <int>[1, 2, 3],
          mediaType: 'image/png',
        ),
      ),
    ],
  );
  final assetCatalogBytes = utf8.encode(jsonEncode(assetCatalog.toJson()));
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('presentation_preview_contexts'),
    revision: _revision,
    manifest: manifest,
    maps: const <MapData>[
      MapData(
        id: 'village',
        name: 'Village Vermeil',
        size: GridSize(width: 20, height: 15),
      ),
    ],
    resourceFingerprints: const <String, String>{
      'project': _revision,
      'dialogueSource:welcome': _revision,
      'assetCatalog': _revision,
    },
    resourceBytes: <String, List<int>>{
      'project': projectBytes,
      'dialogueSource:welcome': utf8.encode(
        'title: Start\n---\n'
        '<<portrait leo happy>>\n'
        'Bienvenue !\n'
        'Le vent se lève sur le village.\n'
        '-> Explorer\n'
        '  Allons-y.\n'
        '-> Rester\n'
        '  Prends ton temps.\n'
        '===',
      ),
      'assetCatalog': assetCatalogBytes,
    },
  );
}
