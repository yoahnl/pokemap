import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'generated/native_psdk_trainer_bundle_data.dart';

final class NativePsdkTrainerSourceFile {
  NativePsdkTrainerSourceFile({
    required this.relativePath,
    required this.sha256,
    required List<int> bytes,
  }) : bytes = List.unmodifiable(bytes) {
    if (!RegExp(r'^(Data/Studio/[a-z_]+/[a-z0-9_]+\.json|graphics/pokedex/poke(front|back)/[a-z0-9_]+\.png)$')
            .hasMatch(relativePath) ||
        bytes.length > 1048576 ||
        bytes.any((byte) => byte < 0 || byte > 255) ||
        crypto.sha256.convert(bytes).toString() != sha256.value) {
      throw ContractError('native_trainer.source_witness', relativePath,
          'The native reference requires bounded, exact JSON source bytes.');
    }
  }

  final String relativePath;
  final Sha256Hash sha256;
  final List<int> bytes;

  Map<String, Object?> get evidence => {
        'relativePath': relativePath,
        'sha256': sha256.value,
        'byteLength': bytes.length,
      };
}

final class NativePsdkTrainerBundle {
  NativePsdkTrainerBundle._({
    required this.speciesById,
    required this.learnsetsBySpeciesId,
    required this.movesById,
    required this.evolutionsBySpeciesId,
    required this.mediaBySpeciesId,
    required this.fallbackMedia,
    required this.catalogs,
    required this.evidence,
  });

  factory NativePsdkTrainerBundle.builtin() => NativePsdkTrainerBundle.fromJson(
      (jsonDecode(nativePsdkTrainerBundleJson) as Map).cast<String, dynamic>());

  factory NativePsdkTrainerBundle.fromJson(Map<String, dynamic> json) {
    if (json['kind'] != 'nativePsdkTrainerBundle' || json['version'] != 1) {
      throw ContractError('native_trainer.bundle_version', r'$',
          'A versioned native trainer reference bundle is required.');
    }
    final species = <String, PokemonSpeciesFile>{};
    final learnsets = <String, PokemonLearnsetFile>{};
    final catalogs = <String, PokemonCatalogFile>{};
    final moves = <String, PokemonMove>{};
    for (final raw in _objects(json['species'])) {
      final value = PokemonSpeciesFile.fromJson(raw);
      if (species.containsKey(value.id)) _invalid('duplicate_species');
      species[value.id] = value;
    }
    for (final raw in _objects(json['sourceLearnsets'])) {
      final value = PokemonLearnsetFile.fromJson(raw);
      if (learnsets.containsKey(value.speciesId)) {
        _invalid('duplicate_learnset');
      }
      learnsets[value.speciesId] = value;
    }
    for (final raw in _objects(json['catalogs'])) {
      final value = PokemonCatalogFile.fromJson(raw);
      if (catalogs.containsKey(value.catalog)) _invalid('duplicate_catalog');
      catalogs[value.catalog] = value;
    }
    final evolutions = <String, PokemonEvolutionFile>{};
    for (final raw in _objects(json['evolutions'])) {
      final value = PokemonEvolutionFile.fromJson(raw);
      if (evolutions.containsKey(value.speciesId)) {
        _invalid('duplicate_evolution');
      }
      evolutions[value.speciesId] = value;
    }
    final media = <String, PokemonMediaFile>{};
    for (final raw in _objects(json['media'])) {
      final value = PokemonMediaFile.fromJson(raw);
      if (media.containsKey(value.speciesId)) _invalid('duplicate_media');
      media[value.speciesId] = value;
    }
    final fallbackMedia = <String, Map<String, Object?>>{};
    for (final raw in _objects(json['fallbackMedia'])) {
      final target = raw['targetPath'];
      final encoded = raw['bytesBase64'];
      if (target is! String ||
          !RegExp(r'^assets/pokemon/native/[a-z0-9_]+_(front|back)\.png$')
              .hasMatch(target) ||
          encoded is! String ||
          encoded.length > 1398104 ||
          fallbackMedia.containsKey(target)) {
        _invalid('media_witness');
      }
      final bytes = base64Decode(encoded);
      if (crypto.sha256.convert(bytes).toString() != raw['sha256']) {
        _invalid('media_witness');
      }
      fallbackMedia[target] = _freeze(raw) as Map<String, Object?>;
    }
    final types = _ids(catalogs['types']);
    final abilities = _ids(catalogs['abilities']);
    if (types.length != 18 || !types.containsAll(nativeTrainerTypeIds)) {
      _invalid('type_closure');
    }
    for (final row in catalogs['types']!.entries) {
      for (final damage in _objects(row['damageTo'])) {
        if (!types.contains(damage['defensiveType']) ||
            !const <num>[0, 0.25, 0.5, 1, 2, 4].contains(damage['factor'])) {
          _invalid('type_chart');
        }
      }
    }
    for (final raw in catalogs['moves']?.entries ?? <Map<String, dynamic>>[]) {
      final value = PokemonMove.fromJson(raw);
      if (moves.containsKey(value.id) ||
          !types.contains(value.type) ||
          value.pp <= 0 ||
          !value.unsupportedReasons
              .any((reason) => reason.startsWith('psdk_method:'))) {
        _invalid('move_invalid');
      }
      moves[value.id] = value;
    }
    for (final value in species.values) {
      final stats = value.baseStats;
      if (value.id.isEmpty ||
          !learnsets.containsKey(value.id) ||
          !evolutions.containsKey(value.id) ||
          !media.containsKey(value.id) ||
          !types.containsAll(value.typing.types) ||
          value.typing.types.isEmpty ||
          !abilities.contains(value.abilities.primary) ||
          [stats.hp, stats.atk, stats.def, stats.spa, stats.spd, stats.spe]
              .any((stat) => stat <= 0)) {
        _invalid('species_invalid');
      }
    }
    if (species.isEmpty ||
        species.length > 128 ||
        moves.isEmpty ||
        moves.length > 512) {
      _invalid('bundle_quota');
    }
    final evidence = (json['evidence'] as Map).cast<String, Object?>();
    if (evidence['globalCatalogComplete'] != false ||
        evidence['globalLearnsetsPublished'] != true ||
        evidence['runtimeBattleBuilderQualified'] != false ||
        evidence['sourceScriptsExecuted'] != 0) {
      _invalid('qualification_scope');
    }
    return NativePsdkTrainerBundle._(
        speciesById: Map.unmodifiable(species),
        learnsetsBySpeciesId: Map.unmodifiable(learnsets),
        movesById: Map.unmodifiable(moves),
        evolutionsBySpeciesId: Map.unmodifiable(evolutions),
        mediaBySpeciesId: Map.unmodifiable(media),
        fallbackMedia: Map.unmodifiable(fallbackMedia),
        catalogs: Map.unmodifiable(catalogs),
        evidence: _freeze(evidence) as Map<String, Object?>);
  }

  final Map<String, PokemonSpeciesFile> speciesById;
  final Map<String, PokemonLearnsetFile> learnsetsBySpeciesId;
  final Map<String, PokemonMove> movesById;
  final Map<String, PokemonEvolutionFile> evolutionsBySpeciesId;
  final Map<String, PokemonMediaFile> mediaBySpeciesId;
  final Map<String, Map<String, Object?>> fallbackMedia;
  final Map<String, PokemonCatalogFile> catalogs;
  final Map<String, Object?> evidence;

  Map<String, Object?> toJson() => {
        'kind': 'nativePsdkTrainerBundle',
        'version': 1,
        'species': speciesById.values.map((value) => value.toJson()).toList(),
        'sourceLearnsets':
            learnsetsBySpeciesId.values.map((value) => value.toJson()).toList(),
        'evolutions': evolutionsBySpeciesId.values
            .map((value) => value.toJson())
            .toList(),
        'media':
            mediaBySpeciesId.values.map((value) => value.toJson()).toList(),
        'fallbackMedia': fallbackMedia.values.toList(),
        'catalogs': catalogs.values.map((value) => value.toJson()).toList(),
        'evidence': evidence,
      };
}

final class NativePsdkTrainerBundleBuilder {
  const NativePsdkTrainerBundleBuilder();

  NativePsdkTrainerBundle build({
    required List<NativePsdkTrainerSourceFile> files,
    required Map<String, Set<int>> requestedLevels,
  }) {
    if (files.length > 2048 ||
        requestedLevels.isEmpty ||
        requestedLevels.length > 64 ||
        files.fold<int>(0, (sum, file) => sum + file.bytes.length) > 16777216) {
      _invalid('bundle_quota');
    }
    final index = <String, NativePsdkTrainerSourceFile>{};
    for (final file in files) {
      if (index.containsKey(file.relativePath)) _invalid('duplicate_source');
      index[file.relativePath] = file;
    }
    final used = <String>{};
    Map<String, dynamic> read(String path, String id) {
      final file = index[path];
      if (file == null) _invalid('source_missing:$path');
      final raw =
          (jsonDecode(utf8.decode(file.bytes)) as Map).cast<String, dynamic>();
      if (raw['dbSymbol'] != id) _invalid('source_identity:$path');
      used.add(path);
      return raw;
    }

    final species = <Map<String, Object?>>[];
    final learnsets = <Map<String, Object?>>[];
    final evolutions = <Map<String, Object?>>[];
    final media = <Map<String, Object?>>[];
    final fallbackMedia = <Map<String, Object?>>[];
    final selectedMoves = <String>{};
    final battleDefaultMoves = <String>{};
    final abilityIds = <String>{};
    final growthIds = <String>{};
    final requestedSpecies = requestedLevels.keys.toList()..sort();
    final closure = requestedSpecies.toSet();
    final queue = requestedSpecies.toList();
    final raws = <String, Map<String, dynamic>>{};
    for (var cursor = 0; cursor < queue.length; cursor++) {
      if (queue.length > 64) _invalid('species_closure_quota');
      final id = queue[cursor];
      final raw = read('Data/Studio/pokemon/$id.json', id);
      raws[id] = raw;
      for (final form in _objects(raw['forms'])) {
        final targets = <String>[
          for (final evolution in _objects(form['evolutions']))
            (evolution['dbSymbol'] ?? id) as String,
          if (form['babyDbSymbol'] case final String baby) baby,
        ];
        for (final target in targets) {
          if (target != 'none' &&
              target != '__undef__' &&
              closure.add(target)) {
            queue.add(target);
          }
        }
      }
    }
    final orderedSpecies = raws.keys.toList()..sort();
    for (final baseId in orderedSpecies) {
      final raw = raws[baseId]!;
      final forms = _objects(raw['forms'])
        ..sort((a, b) => (a['form'] as int).compareTo(b['form'] as int));
      final formIds = forms.map((form) => '${form['form']}').toList();
      for (final form in forms) {
        final number = form['form'] as int;
        final id = nativePsdkFormSpeciesId(baseId, number);
        final abilities = (form['abilities'] as List).cast<String>();
        if (abilities.length != 3 || abilities.any((id) => id.isEmpty)) {
          _invalid('ability_slots');
        }
        abilityIds.addAll(abilities);
        final types = <String>{form['type1'] as String, form['type2'] as String}
          ..removeAll({'none', '__undef__'});
        final value = const PokemonSdkSpeciesConverter().convert({
          'id': raw['id'],
          'dbSymbol': id,
          'generation': 0,
          'types': types.toList(),
          'baseStats': {
            'hp': form['baseHp'],
            'atk': form['baseAtk'],
            'def': form['baseDfe'],
            'spa': form['baseAts'],
            'spd': form['baseDfs'],
            'spe': form['baseSpd']
          },
          'abilities': {
            'primary': abilities.first,
            if (abilities[1] != abilities.first) 'secondary': abilities[1],
            if (abilities[2] != abilities.first && abilities[2] != abilities[1])
              'hidden': abilities[2]
          },
          'height': form['height'],
          'weight': form['weight'],
        }).toJson();
        final growth = switch (form['experienceType']) {
          0 => 'fast',
          1 => 'medium',
          2 => 'slow',
          3 => 'medium_slow',
          4 => 'erratic',
          5 => 'fluctuating',
          _ => throw ContractError('native_trainer.growth_rate', id,
              'The PSDK experience curve is unknown.'),
        };
        growthIds.add(growth);
        value['progression'] = {
          'growthRateId': growth,
          'baseExp': form['baseExperience'],
          'catchRate': form['catchRate'],
          'baseFriendship': form['baseLoyalty']
        };
        value['forms'] = {
          'baseFormId': baseId,
          'isBaseForm': number == 0,
          'formId': '$number',
          'otherForms': formIds.where((value) => value != '$number').toList()
        };
        species.add(PokemonSpeciesFile.fromJson(value).toJson());
        final moveSet = _objects(form['moveSet']);
        selectedMoves.addAll(moveSet.map((move) => move['move'] as String));
        final levelMoves = moveSet
            .where((move) => move['klass'] == 'LevelLearnableMove')
            .map((move) => PokemonLearnsetLevelUpEntry(
                moveId: move['move'] as String,
                level: move['level'] as int,
                source: 'pokemon_sdk_studio',
                versionGroup: 'psdk-native-reference'))
            .toList();
        List<PokemonLearnsetMoveEntry> entries(String klass) => moveSet
            .where((move) => move['klass'] == klass)
            .map((move) => PokemonLearnsetMoveEntry(
                moveId: move['move'] as String,
                versionGroup: 'psdk-native-reference'))
            .toList();
        if (moveSet.any((move) => !const {
              'LevelLearnableMove',
              'TechLearnableMove',
              'TutorLearnableMove',
              'BreedLearnableMove',
              'EvolutionLearnableMove'
            }.contains(move['klass']))) {
          _invalid('learnset_class');
        }
        final learnset = PokemonLearnsetFile(
            speciesId: id,
            startingMoves: levelMoves
                .where((move) => move.level == 1)
                .map((move) => move.moveId)
                .toList(),
            levelUp: levelMoves,
            tm: entries('TechLearnableMove'),
            tutor: entries('TutorLearnableMove'),
            egg: entries('BreedLearnableMove'),
            event: entries('EvolutionLearnableMove'));
        learnsets.add(learnset.toJson());
        if (number == 0 && requestedLevels.containsKey(baseId)) {
          final levels = requestedLevels[baseId]!;
          if (levels.isEmpty ||
              levels.any((level) => level < 1 || level > 100)) {
            _invalid('level_invalid');
          }
          for (final level in levels) {
            final defaults = nativeTrainerDefaultMoveIds(learnset, level);
            if (defaults.isEmpty) {
              _invalid('empty_moves');
            }
            battleDefaultMoves.addAll(defaults);
          }
        }
        final evolutionEntries = <PokemonEvolutionEntry>[];
        for (final evolution in _objects(form['evolutions'])) {
          final conditions = _objects(evolution['conditions']);
          final target = nativePsdkFormSpeciesId(
              (evolution['dbSymbol'] ?? baseId) as String,
              evolution['form'] as int);
          final condition = conditions.length == 1 ? conditions.single : null;
          final type = condition?['type'];
          evolutionEntries.add(PokemonEvolutionEntry(
              targetSpeciesId: target,
              method: type == 'minLevel'
                  ? 'level_up'
                  : type == 'minLoyalty'
                      ? 'friendship'
                      : type == 'skill1'
                          ? 'known_move'
                          : 'conditional',
              minLevel: type == 'minLevel' ? condition!['value'] as int : null,
              minFriendship:
                  type == 'minLoyalty' ? condition!['value'] as int : null,
              requiredMoveId:
                  type == 'skill1' ? condition!['value'] as String : null,
              conditionText: {'psdk': jsonEncode(conditions)}));
        }
        evolutions.add(
            PokemonEvolutionFile(speciesId: id, evolutions: evolutionEntries)
                .toJson());
        final variants = <String, PokemonMediaVariant>{};
        for (final other in forms) {
          final otherId = nativePsdkFormSpeciesId(baseId, other['form'] as int);
          variants['${other['form']}'] = PokemonMediaVariant(
              frontStatic: nativePsdkMediaTarget(otherId, 'front'),
              backStatic: nativePsdkMediaTarget(otherId, 'back'));
        }
        media.add(PokemonMediaFile(
                speciesId: id, defaultFormId: '$number', variants: variants)
            .toJson());
        if (number != 0) {
          final resources = (form['resources'] as Map).cast<String, dynamic>();
          for (final side in ['front', 'back']) {
            final path = 'graphics/pokedex/poke$side/${resources[side]}.png';
            final source = index[path];
            if (source == null) _invalid('source_missing:$path');
            used.add(path);
            fallbackMedia.add({
              'targetPath': nativePsdkMediaTarget(id, side),
              'sourcePath': path,
              'sha256': source.sha256.value,
              'byteLength': source.bytes.length,
              'bytesBase64': base64Encode(source.bytes)
            });
          }
        }
      }
    }

    final movePayloads = <Map<String, Object?>>[];
    for (final id in selectedMoves.toList()..sort()) {
      final raw = read('Data/Studio/moves/$id.json', id);
      final payload = Map<String, Object?>.from(raw);
      payload['criticalRate'] = raw['movecriticalRate'];
      payload['battleEngineAimedTarget'] =
          switch (raw['battleEngineAimedTarget']) {
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
        'EVA_STAGE': 'evasion'
      };
      payload['battleStageMods'] = [
        for (final change in _objects(raw['battleStageMod']))
          {
            ...change,
            'stat': stages[change['battleStage']] ?? change['battleStage']
          }
      ];
      payload['flags'] = {
        for (final flag in const {
          'direct': 'isDirect',
          'blocable': 'isBlocable',
          'mirrorMove': 'isMirrorMove',
          'soundAttack': 'isSoundAttack',
          'authentic': 'isAuthentic',
          'powder': 'isPowder',
          'gravity': 'isGravity',
          'punch': 'isPunch',
          'slicingAttack': 'isSlicingAttack',
          'wind': 'isWind',
          'heal': 'isHeal',
          'bite': 'isBite',
          'pulse': 'isPulse',
          'dance': 'isDance',
          'ballistics': 'isBallistics',
          'unfreeze': 'isUnfreeze',
        }.entries)
          flag.key: raw[flag.value]
      };
      movePayloads.add(payload);
    }
    final catalogs = <Map<String, Object?>>[
      const PokemonSdkMoveCatalogConverter()
          .convertCatalog(movePayloads)
          .toJson(),
    ];
    final moveCatalog = catalogs.single;
    for (final value in moveCatalog['entries'] as List) {
      final move = value as Map<String, dynamic>;
      if (!battleDefaultMoves.contains(move['id'])) {
        move['engineSupportLevel'] = 'catalog_only';
        move['unsupportedReasons'] = [
          ...move['unsupportedReasons'] as List,
          'native_roster_unused_move_unqualified'
        ];
      }
    }
    final types = <Map<String, dynamic>>[];
    for (final id in nativeTrainerTypeIds.toList()..sort()) {
      final raw = read('Data/Studio/types/$id.json', id);
      types.add({'id': id, 'damageTo': raw['damageTo']});
    }
    final abilities = <Map<String, dynamic>>[];
    for (final id in abilityIds.toList()..sort()) {
      read('Data/Studio/abilities/$id.json', id);
      abilities.add({'id': id});
    }
    read('Data/Studio/natures/hardy.json', 'hardy');
    for (final entry in {
      'types': types,
      'abilities': abilities,
      'growth_rates': [
        for (final id in growthIds.toList()..sort()) {'id': id}
      ],
      'natures': [
        {'id': 'hardy'}
      ],
    }.entries) {
      catalogs.add(PokemonCatalogFile(
              schemaVersion: 1,
              kind: 'pokemon_catalog',
              catalog: entry.key,
              meta: const PokemonDataMeta(
                  description: 'Bounded Avelune native trainer reference'),
              entries: entry.value)
          .toJson());
    }
    return NativePsdkTrainerBundle.fromJson({
      'kind': 'nativePsdkTrainerBundle',
      'version': 1,
      'species': species,
      'sourceLearnsets': learnsets,
      'evolutions': evolutions,
      'media': media,
      'fallbackMedia': fallbackMedia,
      'catalogs': catalogs,
      'evidence': {
        'authority': 'AveluneNativePsdkData',
        'scope': 'nativeTrainerSpeciesCompanionClosure',
        'globalCatalogComplete': false,
        'globalLearnsetsPublished': true,
        'nativeClosureComplete': true,
        'sourceLearnsetSemantics': {
          'TechLearnableMove': 'tm',
          'TutorLearnableMove': 'tutor',
          'BreedLearnableMove': 'egg',
          'EvolutionLearnableMove': 'event'
        },
        'nativeEvolutionMoveExecutionQualified': false,
        'conditionalEvolutionExecutionQualified': false,
        'runtimeBattleBuilderQualified': false,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'nativeBattleDefaultMoveIds': battleDefaultMoves.toList()..sort(),
        'nativeStatProfile': 'trainerV0',
        'nativeAbilityPolicy': 'speciesPrimary',
        'movePolicy': 'nativeAveluneDefaults',
        'moveDerivation': 'startingThenRelearnThenOrderedLevelUpUniqueLastFour',
        'requestedLevels': {
          for (final id in requestedSpecies)
            id: requestedLevels[id]!.toList()..sort()
        },
        'sources': [
          for (final path in used.toList()..sort()) index[path]!.evidence
        ],
        'growthRateOracle': 'PFM::Pokemon::ExpList::KIND_TO_METHOD',
      },
    });
  }
}

const nativeTrainerTypeIds = {
  'normal',
  'fire',
  'water',
  'electric',
  'grass',
  'ice',
  'fighting',
  'poison',
  'ground',
  'flying',
  'psychic',
  'bug',
  'rock',
  'ghost',
  'dragon',
  'dark',
  'steel',
  'fairy',
};

Set<String> _ids(PokemonCatalogFile? catalog) {
  if (catalog == null) _invalid('catalog_missing');
  final ids = <String>{};
  for (final value in catalog.entries) {
    final id = value['id'];
    if (id is! String || id.isEmpty || !ids.add(id)) {
      _invalid('catalog_identity');
    }
  }
  return ids;
}

List<Map<String, dynamic>> _objects(Object? value) {
  if (value is! List ||
      value.length > 4096 ||
      value.any((entry) => entry is! Map)) {
    _invalid('document_shape');
  }
  return value.map((entry) => (entry as Map).cast<String, dynamic>()).toList();
}

Object? _freeze(Object? value) => switch (value) {
      Map value => Map<String, Object?>.unmodifiable(
          value.map((key, entry) => MapEntry(key as String, _freeze(entry)))),
      List value => List<Object?>.unmodifiable(value.map(_freeze)),
      _ => value,
    };

Never _invalid(String reason) => throw ContractError('native_trainer.$reason',
    r'$', 'The native trainer reference is invalid: $reason.');

List<String> nativeTrainerDefaultMoveIds(
    PokemonLearnsetFile learnset, int level) {
  final ordered = [
    ...learnset.startingMoves,
    ...learnset.relearnMoves,
    for (final move in learnset.levelUp)
      if (move.level <= level) move.moveId,
  ];
  final unique = <String>[];
  for (final id in ordered) {
    if (id.isNotEmpty && !unique.contains(id)) unique.add(id);
  }
  return List.unmodifiable(
      unique.length <= 4 ? unique : unique.sublist(unique.length - 4));
}

String nativePsdkFormSpeciesId(String id, int form) =>
    form == 0 ? id : '${id}_form$form';
String nativePsdkMediaTarget(String id, String side) =>
    'assets/pokemon/native/${id}_$side.png';
