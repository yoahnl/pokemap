import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_move_machine_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  test('loads authored TM/HM metadata and resolves compatibility', () async {
    final root =
        await Directory.systemTemp.createTemp('runtime-machine-loader-');
    addTearDown(() => root.delete(recursive: true));
    await _writeFixtures(root);
    final loader = RuntimeMoveMachineLoader();

    final tm = await loader.loadCandidate(
      projectRootDirectory: root.path,
      pokemonConfig: _config,
      itemId: 'tm-protect',
      speciesRef: 'sproutle',
      fallbackSpeciesId: 'sproutle',
    );
    final hm = await loader.loadCandidate(
      projectRootDirectory: root.path,
      pokemonConfig: _config,
      itemId: 'hm-surf',
      speciesRef: 'sproutle',
      fallbackSpeciesId: 'sproutle',
    );
    final unknown = await loader.loadDefinition(
      projectRootDirectory: root.path,
      pokemonConfig: _config,
      itemId: 'potion',
    );

    expect(tm?.moveId, 'protect');
    expect(tm?.consumable, isTrue);
    expect(hm?.moveId, 'surf');
    expect(hm?.consumable, isFalse);
    expect(unknown, isNull);
  });

  test('fails closed on malformed machine metadata', () async {
    final root =
        await Directory.systemTemp.createTemp('runtime-machine-invalid-');
    addTearDown(() => root.delete(recursive: true));
    await _writeJson(
      root,
      'custom/catalogs/items.json',
      <String, Object?>{
        'catalog': 'items',
        'entries': <Object?>[
          <String, Object?>{
            'id': 'hm-surf',
            'machine': <String, Object?>{
              'kind': 'hm',
              'moveId': 'surf',
              'consumable': true,
            },
          },
        ],
      },
    );

    await expectLater(
      () => RuntimeMoveMachineLoader().loadDefinition(
        projectRootDirectory: root.path,
        pokemonConfig: _config,
        itemId: 'hm-surf',
      ),
      throwsA(isA<RuntimeBattleSetupException>()),
    );
  });
}

const _config = ProjectPokemonConfig(
  learnsetsDir: 'custom/learnsets',
  catalogFiles: <String, String>{
    'items': 'custom/catalogs/items.json',
    'moves': 'custom/catalogs/moves.json',
  },
);

Future<void> _writeFixtures(Directory root) async {
  await _writeJson(
    root,
    'custom/catalogs/items.json',
    <String, Object?>{
      'catalog': 'items',
      'entries': <Object?>[
        <String, Object?>{
          'id': 'tm-protect',
          'machine': <String, Object?>{
            'kind': 'tm',
            'moveId': 'protect',
            'consumable': true,
          },
        },
        <String, Object?>{
          'id': 'hm-surf',
          'machine': <String, Object?>{
            'kind': 'hm',
            'moveId': 'surf',
            'consumable': false,
          },
        },
        <String, Object?>{'id': 'potion'},
      ],
    },
  );
  await _writeJson(
    root,
    'custom/learnsets/sproutle.json',
    <String, Object?>{
      'speciesId': 'sproutle',
      'startingMoves': <String>[],
      'relearnMoves': <String>[],
      'levelUp': <Object?>[],
      'tm': <Object?>[
        <String, String>{'moveId': 'protect'},
      ],
      'hm': <Object?>[
        <String, String>{'moveId': 'surf'},
      ],
    },
  );
  await _writeJson(
    root,
    'custom/catalogs/moves.json',
    <String, Object?>{
      'catalog': 'moves',
      'entries': <Object?>[
        _move('protect', 10),
        _move('surf', 15),
      ],
    },
  );
}

Map<String, Object?> _move(String id, int pp) {
  return PokemonMove(
    id: id,
    name: id,
    source: 'machine-test',
    type: 'normal',
    category: PokemonMoveCategory.status,
    basePower: 0,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: pp,
    engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
  ).toJson();
}

Future<void> _writeJson(
  Directory root,
  String relativePath,
  Map<String, Object?> json,
) async {
  final file = File(p.join(root.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(json));
}
