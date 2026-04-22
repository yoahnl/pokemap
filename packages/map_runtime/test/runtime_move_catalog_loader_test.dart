import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeMoveCatalogLoader', () {
    late Directory tempProjectRoot;
    final loader = RuntimeMoveCatalogLoader();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_move_catalog_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test(
        'loads a canonical moves catalog and preserves runtime-relevant fields',
        () async {
      await _writeCanonicalMovesCatalog(
        tempProjectRoot,
        entries: <Map<String, dynamic>>[
          _canonicalMove(
            id: 'thunderbolt',
            name: 'Thunderbolt',
            type: 'electric',
            category: PokemonMoveCategory.special,
            basePower: 90,
            accuracy: const PokemonMoveAccuracy.percent(value: 100),
            effects: const <PokemonMoveEffect>[
              PokemonMoveEffect.applyStatus(
                chance: 10,
                statusId: 'par',
              ),
            ],
          ),
          _canonicalMove(
            id: 'swift',
            name: 'Swift',
            type: 'normal',
            category: PokemonMoveCategory.special,
            basePower: 60,
            accuracy: const PokemonMoveAccuracy.alwaysHits(),
          ),
          _canonicalMove(
            id: 'trick_room',
            name: 'Trick Room',
            type: 'psychic',
            category: PokemonMoveCategory.status,
            basePower: 0,
            accuracy: const PokemonMoveAccuracy.alwaysHits(),
            effects: const <PokemonMoveEffect>[
              PokemonMoveEffect.setPseudoWeather(
                pseudoWeatherId: 'trickroom',
              ),
            ],
            engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
            unsupportedReasons: const <String>[
              'unsupported_mechanic:turn_order_inversion',
            ],
          ),
        ],
      );

      final catalog = await loader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final thunderbolt = catalog.lookup('thunderbolt');
      expect(thunderbolt, isNotNull);
      expect(thunderbolt!.basePower, equals(90));
      expect(
        thunderbolt.accuracy,
        const PokemonMoveAccuracy.percent(value: 100),
      );
      expect(
        thunderbolt.effects,
        contains(
          const PokemonMoveEffect.applyStatus(
            chance: 10,
            statusId: 'par',
          ),
        ),
      );

      final swift = catalog.lookup('swift');
      expect(swift, isNotNull);
      expect(
        swift!.accuracy,
        const PokemonMoveAccuracy.alwaysHits(),
      );

      final trickRoom = catalog.lookup('trick_room');
      expect(trickRoom, isNotNull);
      expect(
        trickRoom!.engineSupportLevel,
        PokemonMoveEngineSupportLevel.structuredPartial,
      );
      expect(
        trickRoom.unsupportedReasons,
        equals(<String>['unsupported_mechanic:turn_order_inversion']),
      );
      expect(
        trickRoom.effects,
        contains(
          const PokemonMoveEffect.setPseudoWeather(
            pseudoWeatherId: 'trickroom',
          ),
        ),
      );
    });

    test('fails explicitly on an invalid canonical move entry', () async {
      await _writeCanonicalMovesCatalog(
        tempProjectRoot,
        entries: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'broken_move',
            'name': 'Broken Move',
            'type': 'normal',
            'category': 'special',
            'basePower': 40,
            // Le runtime ne doit jamais accepter cette forme legacy ici :
            // c'est un catalogue canonique invalide, pas un cas à réparer.
            'accuracy': 100,
            'pp': 35,
          },
        ],
      );

      await expectLater(
        () => loader.load(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('entrée canonique invalide'),
          ),
        ),
      );
    });

    test('fails explicitly on duplicate canonical move ids', () async {
      await _writeCanonicalMovesCatalog(
        tempProjectRoot,
        entries: <Map<String, dynamic>>[
          _canonicalMove(
            id: 'tackle',
            name: 'Tackle',
            type: 'normal',
            category: PokemonMoveCategory.physical,
            basePower: 40,
            accuracy: const PokemonMoveAccuracy.percent(value: 100),
          ),
          _canonicalMove(
            id: ' tackle ',
            name: 'Shadow Tackle',
            type: 'ghost',
            category: PokemonMoveCategory.special,
            basePower: 50,
            accuracy: const PokemonMoveAccuracy.percent(value: 100),
          ),
        ],
      );

      await expectLater(
        () => loader.load(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('ids dupliqués'),
          ),
        ),
      );
    });

    test('fails explicitly when catalog metadata is missing', () async {
      await _writeProjectRelativeJson(
        tempProjectRoot,
        'custom/pokemon/catalogs/moves.json',
        <String, dynamic>{
          'schemaVersion': 1,
          'kind': 'pokemon_catalog',
          'meta': <String, Object>{
            'description': 'Broken runtime move catalog loader test catalog',
          },
          'entries': <Map<String, dynamic>>[
            _canonicalMove(
              id: 'tackle',
              name: 'Tackle',
              type: 'normal',
              category: PokemonMoveCategory.physical,
              basePower: 40,
              accuracy: const PokemonMoveAccuracy.percent(value: 100),
            ),
          ],
        },
      );

      await expectLater(
        () => loader.load(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('missing a non-empty "catalog" field'),
          ),
        ),
      );
    });
  });
}

ProjectPokemonConfig _pokemonConfig() {
  return const ProjectPokemonConfig(
    dataRoot: 'custom/pokemon',
    speciesDir: 'custom/pokemon/species',
    learnsetsDir: 'custom/pokemon/learnsets',
    evolutionsDir: 'custom/pokemon/evolutions',
    mediaDir: 'custom/pokemon/media',
    catalogFiles: <String, String>{
      'moves': 'custom/pokemon/catalogs/moves.json',
    },
  );
}

Future<void> _writeCanonicalMovesCatalog(
  Directory projectRoot, {
  required List<Map<String, dynamic>> entries,
}) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Runtime move catalog loader test catalog',
      },
      'entries': entries,
    },
  );
}

Map<String, dynamic> _canonicalMove({
  required String id,
  required String name,
  required String type,
  required PokemonMoveCategory category,
  required int basePower,
  required PokemonMoveAccuracy accuracy,
  List<PokemonMoveEffect> effects = const <PokemonMoveEffect>[],
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
}) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: type,
    category: category,
    target: PokemonMoveTarget.normal,
    basePower: basePower,
    accuracy: accuracy,
    pp: 35,
    effects: effects,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
  ).toJson();
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}
