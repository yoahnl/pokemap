import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

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
      final portraitDigest = sha256.convert(portraitBytes).toString();
      _writeBytes(root, 'assets/maps/qa-village.png', stageBytes);
      _writeBytes(root, 'assets/battle/qa-clearing.png', stageBytes);
      _writeBytes(root, 'assets/characters/qa-leo.png', portraitBytes);
      _writeBytes(
        root,
        'assets/.pokemap-store/$portraitDigest.blob',
        portraitBytes,
      );
      _writeJson(root, 'project.json', _manifest);
      _writeJson(root, 'maps/qa_village.json', _map);
      _writeText(root, 'dialogues/qa_welcome.yarn', _dialogue);
      _writeJson(
        root,
        'assets/.pokemap-assets.json',
        _assetRegistry(portraitDigest, portraitBytes.length),
      );
      return Directory(root.resolveSymbolicLinksSync());
    } catch (_) {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      rethrow;
    }
  }

  static const Map<String, Object?> _manifest = <String, Object?>{
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
            'speciesId': 'roucool',
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
    'settings': <String, Object?>{
      'tileWidth': 1,
      'tileHeight': 1,
      'displayScale': 1,
      'defaultMapWidth': 1,
      'defaultMapHeight': 1,
      'defaultPlayerCharacterId': 'qa_leo',
    },
  };

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

  static Map<String, Object?> _assetRegistry(String digest, int byteLength) {
    return <String, Object?>{
      'schemaVersion': 1,
      'records': <Object?>[
        <String, Object?>{
          'id': 'portrait-qa-leo',
          'logicalPath': 'assets/characters/qa-leo.png',
          'artifact': <String, Object?>{
            'digest': 'sha256:$digest',
            'handle': 'artifact://sha256/$digest',
            'mediaType': 'image/png',
            'byteLength': byteLength,
          },
          'usages': <Object?>[],
          'tags': <Object?>['portrait'],
        },
      ],
    };
  }

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
