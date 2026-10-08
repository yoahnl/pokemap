import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import '../../../packages/map_editor/lib/src/application/services/pokemon_sdk_move_catalog_converter.dart';
import '../../../packages/map_editor/lib/src/application/services/pokemon_sdk_species_converter.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2)
    throw ArgumentError('Expected PSDK source and output roots');
  final source = Directory(args[0]).resolveSymbolicLinksSync();
  final output = Directory(args[1])..createSync(recursive: true);
  final sources = <Map<String, Object?>>[];
  final assets = <Map<String, Object?>>[];
  final documents = <Map<String, Object?>>[];
  final moveIds = <String>{};
  final typeIds = <String>{};
  final abilityIds = <String>{};
  final growthIds = <String>{};
  const names = {
    'bulbasaur': 'Bulbizarre',
    'pidgey': 'Roucool',
    'rattata': 'Rattata',
    'caterpie': 'Chenipan',
  };
  Future<Uint8List> read(String path) async {
    final file = File('$source/$path');
    final resolved = await file.resolveSymbolicLinks();
    if (!resolved.startsWith('$source/'))
      throw ArgumentError('Source escapes PSDK root');
    final bytes = await file.readAsBytes();
    sources.add({
      'path': path,
      'sha256': sha256.convert(bytes).toString(),
      'bytes': bytes.length,
    });
    return bytes;
  }

  Future<Map<String, dynamic>> readJson(String path) async =>
      Map<String, dynamic>.from(
        jsonDecode(utf8.decode(await read(path))) as Map,
      );
  Future<void> asset(
    String sourcePath,
    String id,
    String logicalPath, {
    bool cropIcon = false,
    bool cropPickup = false,
  }) async {
    final bytes = await read(sourcePath);
    final destination = File('${output.path}/$logicalPath');
    await destination.parent.create(recursive: true);
    var result = cropIcon
        ? image.encodePng(
            image.copyCrop(
              image.decodePng(bytes)!,
              x: 0,
              y: 0,
              width: 32,
              height: 32,
            ),
          )
        : bytes;
    if (cropPickup) {
      final decoded = image.decodePng(bytes)!;
      final sprite = image.Image(width: 32, height: 32, numChannels: 4);
      for (var y = 0; y < 20; y++) {
        for (var x = 0; x < 20; x++) {
          sprite.setPixel(x + 6, y + 10, decoded.getPixel(x ~/ 2 + 3, y ~/ 2 + 3));
        }
      }
      result = image.encodePng(sprite);
    }
    await destination.writeAsBytes(result);
    assets.add({
      'id': id,
      'logicalPath': logicalPath,
      'file': logicalPath,
      'sourcePath': sourcePath,
      'sourceSha256': sha256.convert(bytes).toString(),
      'sha256': sha256.convert(result).toString(),
      'bytes': result.length,
      if (cropIcon || cropPickup)
        'sourceRectPx': {
          'x': cropPickup ? 3 : 0,
          'y': cropPickup ? 3 : 0,
          'width': cropIcon ? 32 : 10,
          'height': cropIcon ? 32 : 10,
        },
      if (cropPickup)
        'destinationRectPx': {'x': 6, 'y': 10, 'width': 20, 'height': 20},
      if (cropPickup) 'nearestScale': 2,
    });
  }

  void document(String kind, String relativePath, Map<String, Object?> value) {
    documents.add({
      'actionId': 'pokemon.$kind.write',
      'parameters': {'relativePath': relativePath, 'document': value},
    });
  }

  for (final entry in names.entries) {
    final id = entry.key;
    final raw = await readJson('Data/Studio/pokemon/$id.json');
    final form = Map<String, dynamic>.from((raw['forms'] as List).first as Map);
    final abilities = (form['abilities'] as List).cast<String>();
    abilityIds.addAll(abilities);
    final types = <String>{
      form['type1'] as String,
      form['type2'] as String,
    }.where((type) => type != 'none' && type != '__undef__').toList();
    typeIds.addAll(types);
    final stats = {
      'hp': form['baseHp'],
      'atk': form['baseAtk'],
      'def': form['baseDfe'],
      'spa': form['baseAts'],
      'spd': form['baseDfs'],
      'spe': form['baseSpd'],
    };
    final species = const PokemonSdkSpeciesConverter().convert({
      'id': raw['id'],
      'dbSymbol': id,
      'name': {'fr': entry.value, 'en': id},
      'generation': 1,
      'types': types,
      'baseStats': stats,
      'abilities': {
        'primary': abilities.first,
        if (abilities.length > 2 && abilities[1] != abilities.first)
          'secondary': abilities[1],
        if (abilities.length > 1 &&
            abilities.last != abilities.first &&
            (abilities.length < 3 || abilities.last != abilities[1]))
          'hidden': abilities.last,
      },
      'height': form['height'],
      'weight': form['weight'],
    }).toJson();
    final growth = switch (form['experienceType']) {
      1 => 'medium',
      3 => 'medium_slow',
      _ => throw ArgumentError('Unexpected growth type'),
    };
    growthIds.add(growth);
    species['progression'] = {
      'growthRateId': growth,
      'baseExp': form['baseExperience'],
      'catchRate': form['catchRate'],
      'baseFriendship': form['baseLoyalty'],
    };
    species['forms'] = {
      'baseFormId': id,
      'isBaseForm': true,
      'formId': 'base',
      'otherForms': <String>[],
    };
    species['gameplayFlags'] = {
      'starterEligible': id == 'bulbasaur',
      'giftOnly': false,
      'tradeOnly': false,
    };
    final female = (form['femaleRate'] as num) / 100;
    species['breeding'] = {
      'genderRatio': {'female': female, 'male': 1 - female},
      'eggGroups': <String>[],
      'hatchCycles': 0,
    };
    document(
      'species',
      'data/pokemon/species/${(raw['id'] as num).toInt().toString().padLeft(4, '0')}-$id.json',
      PokemonSpeciesFile.fromJson(species).toJson(),
    );
    final moves = (form['moveSet'] as List)
        .cast<Map>()
        .where((move) => move['klass'] == 'LevelLearnableMove')
        .toList();
    moveIds.addAll(moves.map((move) => move['move'] as String));
    document(
      'learnset',
      'data/pokemon/learnsets/$id.json',
      PokemonLearnsetFile(
        speciesId: id,
        startingMoves: moves
            .where((move) => move['level'] == 1)
            .map((move) => move['move'] as String)
            .toList(),
        levelUp: moves
            .map(
              (move) => PokemonLearnsetLevelUpEntry(
                moveId: move['move'] as String,
                level: move['level'] as int,
                source: 'pokemon_sdk_studio',
                versionGroup: 'psdk-test-project',
              ),
            )
            .toList(),
      ).toJson(),
    );
    document(
      'evolution',
      'data/pokemon/evolutions/$id.json',
      PokemonEvolutionFile(speciesId: id).toJson(),
    );
    final resources = Map<String, dynamic>.from(form['resources'] as Map);
    final variant = <String, Object?>{};
    for (final role in ['front', 'back', 'frontShiny', 'backShiny']) {
      final side = role.startsWith('front') ? 'front' : 'back';
      final key = role.endsWith('Shiny')
          ? '${side}ShinyStatic'
          : '${side}Static';
      final path = 'assets/pokemon/sprites/$id/$role.png';
      final directory = 'poke$side${role.endsWith('Shiny') ? 'shiny' : ''}';
      await asset(
        'graphics/pokedex/$directory/${resources[role]}.png',
        'valbois-$id-$role',
        path,
      );
      variant[key] = path;
    }
    final iconPath = 'assets/pokemon/menu/$id/icon.png';
    await asset(
      'graphics/pokedex/pokeicon/${resources['icon']}.png',
      'valbois-$id-icon',
      iconPath,
      cropIcon: true,
    );
    variant['icon'] = iconPath;
    variant['party'] = iconPath;
    final cryPath = 'assets/pokemon/cries/$id.ogg';
    await asset(
      'audio/se/cries/${resources['cry']}',
      'valbois-$id-cry',
      cryPath,
    );
    variant['cry'] = cryPath;
    document(
      'media',
      'data/pokemon/media/$id.json',
      PokemonMediaFile(
        speciesId: id,
        defaultFormId: 'base',
        variants: {'base': PokemonMediaVariant.fromJson(variant)},
      ).toJson(),
    );
  }
  final movePayloads = <Map<String, Object?>>[];
  for (final id in moveIds.toList()..sort()) {
    final payload = await readJson('Data/Studio/moves/$id.json');
    payload['criticalRate'] = payload['movecriticalRate'];
    payload['battleEngineAimedTarget'] =
        switch (payload['battleEngineAimedTarget']) {
          'any_other_pokemon' => 'anyFoe',
          'all_ally' => 'allAllies',
          final value => value,
        };
    const stages = {
      'ATK_STAGE': 'attack',
      'DFE_STAGE': 'defense',
      'ATS_STAGE': 'specialAttack',
      'DFS_STAGE': 'specialDefense',
      'SPD_STAGE': 'speed',
      'ACC_STAGE': 'accuracy',
      'EVA_STAGE': 'evasion',
    };
    payload['battleStageMods'] = [
      for (final entry in (payload['battleStageMod'] as List))
        {
          ...Map<String, dynamic>.from(entry as Map),
          'stat': stages[entry['battleStage']] ?? entry['battleStage'],
        },
    ];
    payload['flags'] = {
      'direct': payload['isDirect'],
      'soundAttack': payload['isSoundAttack'],
      'blocable': payload['isBlocable'],
      'mirrorMove': payload['isMirrorMove'],
      'authentic': payload['isAuthentic'],
      'powder': payload['isPowder'],
      'gravity': payload['isGravity'],
      'punch': payload['isPunch'],
      'slicingAttack': payload['isSlicingAttack'],
      'wind': payload['isWind'],
      'heal': payload['isHeal'],
      'bite': payload['isBite'],
      'pulse': payload['isPulse'],
      'dance': payload['isDance'],
      'ballistics': payload['isBallistics'],
      'unfreeze': payload['isUnfreeze'],
    };
    movePayloads.add(payload);
  }
  final catalogs = <Map<String, Object?>>[
    const PokemonSdkMoveCatalogConverter()
        .convertCatalog(movePayloads)
        .toJson(),
  ];
  for (final category in {
    'types': typeIds,
    'abilities': abilityIds,
    'growth_rates': growthIds,
    'natures': {'hardy'},
  }.entries) {
    final entries = <Map<String, dynamic>>[];
    for (final id in category.value.toList()..sort()) {
      if (category.key != 'growth_rates')
        await readJson('Data/Studio/${category.key}/$id.json');
      entries.add({'id': id});
    }
    catalogs.add(
      PokemonCatalogFile(
        schemaVersion: 1,
        kind: 'pokemon_catalog',
        catalog: category.key,
        meta: const PokemonDataMeta(
          description: 'Bounded Valbois PSDK reference closure',
        ),
        entries: entries,
      ).toJson(),
    );
  }
  for (final id in ['potion', 'poke_ball']) {
    final item = await readJson('Data/Studio/items/$id.json');
    await asset('graphics/icons/${item['icon']}.png', 'valbois-$id-bag-icon',
        'data/pokemon/assets/items/$id.png');
  }
  await asset(
    'graphics/ball/ball_1.png',
    'valbois-poke-ball-capture',
    'assets/items/poke_ball/capture.png',
  );
  await asset(
    'graphics/characters/fx-pokeball.png',
    'valbois-pickup-sheet',
    'assets/items/pickup/pokeball.png',
    cropPickup: true,
  );
  final pack = {
    'schemaVersion': 1,
    'source': 'PSDK runnable test project',
    'sources': sources,
    'assets': assets,
    'documents': documents,
    'catalogs': catalogs,
    'ruleset': PokemonRulesetProfile.pokeMapBetaV1.toJson(),
    'limitations': [
      'Only four base species; no evolution targets or non-level-up moves are published.',
      'PSDK ExpList KIND_TO_METHOD: 1 normal, 3 parabolic; runtime retains the canonical PokeMap experience policy.',
      'Pokemon menu icons are exact 32x32 first-frame crops. Item icons retain original PSDK bytes and use canonical item paths. Pickup alpha bounds10x10 of the first16x16 frame are nearest-scaled2x into an alpha32x32 cell at6,10. Other images and cries retain source bytes.',
    ],
  };
  await File('${output.path}/valbois_pokemon_pack.json')
      .writeAsString('${const JsonEncoder.withIndent('  ').convert(pack)}\n');
  stdout.writeln(
    jsonEncode({
      'species': names.length,
      'moves': moveIds.length,
      'assets': assets.length,
      'output': output.path,
    }),
  );
}
