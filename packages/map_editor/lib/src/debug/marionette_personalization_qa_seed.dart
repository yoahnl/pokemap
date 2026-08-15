import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../application/use_cases/seed_pokemon_demo_data_use_case.dart';
import '../infrastructure/filesystem/project_filesystem.dart';
import '../infrastructure/repositories/file_repositories.dart';

typedef MarionetteQaAssetLoader = Future<List<int>> Function(String assetPath);

abstract final class MarionettePersonalizationQaSeed {
  static const seedId = 'personalization-v3';
  static const projectSeedDefine = 'MARIONETTE_PROJECT_SEED';
  static const runIdDefine = 'MARIONETTE_QA_RUN_ID';
  static const stageAssetPath =
      'assets/branding/pokemap_event_builder_project_thumb.png';
  static const portraitAssetPath =
      'assets/branding/pokemap_event_builder_mark.png';

  static Future<Directory> create({
    required Directory sandboxRoot,
    required String runId,
    required MarionetteQaAssetLoader loadAsset,
  }) async {
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]*$').hasMatch(runId)) {
      throw ArgumentError.value(runId, 'runId', 'Unsafe QA run identifier.');
    }
    final root = Directory(
      p.join(sandboxRoot.path, 'PokeMapMarionetteQA', runId),
    );
    if (root.existsSync()) {
      return Directory(root.resolveSymbolicLinksSync());
    }

    root.createSync(recursive: true);
    try {
      final stageBytes = await loadAsset(stageAssetPath);
      final portraitBytes = await loadAsset(portraitAssetPath);
      final portraitArtifact = ContentArtifactRef.fromBytes(
        portraitBytes,
        mediaType: 'image/png',
      );
      _writeBytes(root, 'assets/maps/qa-village.png', stageBytes);
      _writeBytes(root, 'assets/battle/qa-clearing.png', stageBytes);
      _writeBytes(root, 'assets/characters/qa-leo.png', portraitBytes);
      _writeBytes(root, assetBlobStorageKey(portraitArtifact), portraitBytes);
      _writeJson(root, 'project.json', _manifest);
      _writeJson(root, 'maps/qa_village.json', _map);
      _writeText(root, 'dialogues/qa_welcome.yarn', _dialogue);
      _writeJson(
        root,
        'assets/.pokemap-assets.json',
        AssetCatalog(
          records: <AssetRecord>[
            AssetRecord(
              id: 'portrait-qa-leo',
              logicalPath: 'assets/characters/qa-leo.png',
              artifact: portraitArtifact,
              tags: const <String>['portrait'],
            ),
          ],
        ).toJson(),
      );
      await SeedPokemonDemoDataUseCase(
        snapshotController: FilePokemonReadRepository(),
      ).execute(ProjectFileSystem(root.path));
      return Directory(root.resolveSymbolicLinksSync());
    } catch (_) {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      rethrow;
    }
  }

  static final Map<String, Object?> _manifest = <String, Object?>{
    'name': 'QA Personalization Studio',
    'version': 'v6',
    'maps': <Object?>[
      <String, Object?>{
        'id': 'qa_village',
        'name': 'Village QA',
        'relativePath': 'maps/qa_village.json',
        'role': 'exterior',
        'sortOrder': 0,
      },
    ],
    'tilesets': <Object?>[
      <String, Object?>{
        'id': 'qa-stage',
        'name': 'Décor QA',
        'relativePath': 'assets/maps/qa-village.png',
        'source': <String, Object?>{
          'kind': 'regular_atlas',
          'assetId': 'asset-qa-stage',
          'pixelWidth': 1,
          'pixelHeight': 1,
          'tileWidth': 1,
          'tileHeight': 1,
          'tileProperties': <Object?>[],
        },
      },
      <String, Object?>{
        'id': 'qa-leo-overworld',
        'name': 'Léo QA',
        'relativePath': 'assets/characters/qa-leo.png',
      },
    ],
    'dialogues': <Object?>[
      <String, Object?>{
        'id': 'qa_welcome',
        'name': 'Bienvenue QA',
        'relativePath': 'dialogues/qa_welcome.yarn',
        'defaultStartNode': 'Start',
      },
    ],
    'encounterTables': <Object?>[
      <String, Object?>{
        'id': 'qa_grass',
        'name': 'Herbes QA',
        'encounterKind': 'walk',
        'entries': <Object?>[
          <String, Object?>{
            'speciesId': 'bulbasaur',
            'minLevel': 7,
            'maxLevel': 7,
            'weight': 1,
          },
        ],
      },
    ],
    'characters': <Object?>[
      <String, Object?>{
        'id': 'qa_leo',
        'name': 'Léo',
        'tilesetId': 'qa-leo-overworld',
        'portraits': <Object?>[
          <String, Object?>{
            'portraitStateId': 'happy',
            'assetId': 'portrait-qa-leo',
            'fitMode': 'contain',
          },
        ],
        'sortOrder': 0,
      },
    ],
    'characterStudioCatalog': <String, Object?>{
      'portraitStates': <Object?>[
        <String, Object?>{
          'id': 'happy',
          'displayName': 'Heureux',
          'sortOrder': 0,
        },
      ],
    },
    'scenes': <Object?>[_completionScene().toJson()],
    'eventRegistry': NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: <NarrativeEventRecord>[
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: 'evt_019abcde-6000-7000-8000-000000000002',
            name: 'Démarrage QA',
            source: NarrativeEventSourceRef.mapEnter('qa_village'),
            conditions: const <NarrativeEventCondition>[],
            sceneId: 'scene.personalization.qa',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const <LegacySourceClaim>[],
    ).toJson(),
    'pokemon': const ProjectPokemonConfig(
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      enabled: true,
    ).toJson(),
    'settings': <String, Object?>{
      'tileWidth': 1,
      'tileHeight': 1,
      'displayScale': 1,
      'defaultMapWidth': 1,
      'defaultMapHeight': 1,
      'defaultPlayerCharacterId': 'qa_leo',
    },
    'newGame': <String, Object?>{
      'enabled': true,
      'startMapId': 'qa_village',
      'startSpawnId': 'qa_spawn',
      'playerName': 'Léo',
      'startingMoney': 500,
      'initialBag': <Object?>[],
      'initialParty': <Object?>[
        <String, Object?>{
          'speciesId': 'bulbasaur',
          'natureId': 'hardy',
          'abilityId': 'overgrow',
          'level': 5,
          'knownMoveIds': <Object?>[],
          'currentHp': 20,
        },
      ],
      'initialFacts': <String, Object?>{},
      'starterOptions': <Object?>[],
    },
  };

  static SceneAsset _completionScene() => SceneAsset(
    id: 'scene.personalization.qa',
    name: 'Parcours QA',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'finish',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.finishGame(
              endingId: 'ending.personalization.qa',
              outcome: SceneGameCompletionOutcome.completed,
              result: SceneFinishGameResult(
                title: SceneLocalizedText(fallback: 'QA terminée'),
                summary: SceneLocalizedText(
                  fallback: 'Le parcours Personalization est vérifié.',
                ),
              ),
              postGamePolicy: ScenePostGamePolicy.returnToTitle,
            ),
          ),
        ),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(
            outcomePolicy: SceneOutcomePolicy.progression,
          ),
        ),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start-finish',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'finish',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'finish-end',
          fromNodeId: 'finish',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );

  static const Map<String, Object?> _map = <String, Object?>{
    'id': 'qa_village',
    'name': 'Village QA',
    'size': <String, Object?>{'width': 1, 'height': 1},
    'version': 'v6',
    'tilesetId': 'qa-stage',
    'layers': <Object?>[
      <String, Object?>{
        'runtimeType': 'tile',
        'id': 'qa-stage-layer',
        'name': 'Décor QA',
        'isVisible': true,
        'opacity': 1.0,
        'purpose': 'visual',
        'palette': <Object?>[
          <String, Object?>{
            'tilesetId': 'qa-stage',
            'localTileId': 0,
            'transform': <String, Object?>{'quarterTurns': 0, 'flipX': false},
          },
        ],
        'cells': <Object?>[1],
      },
    ],
    'entities': <Object?>[
      <String, Object?>{
        'id': 'qa_spawn',
        'name': 'Arrivée QA',
        'kind': 'spawn',
        'pos': <String, Object?>{'x': 0, 'y': 0},
        'blocksMovement': false,
        'spawn': <String, Object?>{'role': 'player_start', 'facing': 'north'},
      },
      <String, Object?>{
        'id': 'qa_npc_leo',
        'name': 'Léo',
        'kind': 'npc',
        'pos': <String, Object?>{'x': 0, 'y': 0},
        'npc': <String, Object?>{
          'displayName': 'Léo',
          'facing': 'west',
          'dialogueId': 'qa_welcome',
        },
      },
    ],
    'gameplayZones': <Object?>[
      <String, Object?>{
        'id': 'qa_grass_zone',
        'name': 'Herbes QA',
        'kind': 'encounter',
        'area': <String, Object?>{
          'pos': <String, Object?>{'x': 0, 'y': 0},
          'size': <String, Object?>{'width': 1, 'height': 1},
        },
        'encounter': <String, Object?>{
          'encounterTableId': 'qa_grass',
          'encounterKind': 'walk',
          'battleBackgroundRelativePath': 'assets/battle/qa-clearing.png',
        },
      },
    ],
    'mapMetadata': <String, Object?>{'defaultSpawnId': 'qa_spawn'},
  };

  static const String _dialogue = '''title: Start
---
<<portrait qa_leo happy>>
Bienvenue dans le projet de vérification du Personalization Studio.
-> Continuer
  Vérifions les six scènes.
===
''';

  static void _writeJson(Directory root, String relativePath, Object value) {
    _writeText(
      root,
      relativePath,
      '${const JsonEncoder.withIndent('  ').convert(value)}\n',
    );
  }

  static void _writeText(Directory root, String relativePath, String value) {
    final file = File(p.join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(value, flush: true);
  }

  static void _writeBytes(
    Directory root,
    String relativePath,
    List<int> bytes,
  ) {
    final file = File(p.join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes, flush: true);
  }
}
