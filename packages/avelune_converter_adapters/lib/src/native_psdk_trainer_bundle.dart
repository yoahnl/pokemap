import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'generated/native_psdk_trainer_bundle_data.dart';

final class NativePsdkTrainerSourceFile {
  NativePsdkTrainerSourceFile({
    required this.relativePath,
    required this.sha256,
    required List<int> bytes,
  }) : bytes = List.unmodifiable(bytes) {
    if (!RegExp(r'^(Data/Studio/[a-z_]+/[a-z0-9_]+\.json|Data/Text/Dialogs/(100000|100067)\.csv|graphics/pokedex/poke(front|back)/[a-z0-9_]+\.png)$')
            .hasMatch(relativePath) ||
        bytes.length > 1048576 ||
        bytes.any((byte) => byte < 0 || byte > 255) ||
        crypto.sha256.convert(bytes).toString() != sha256.value) {
      throw ContractError('native_trainer.source_witness', relativePath,
          'The native reference requires bounded, exact source bytes.');
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

abstract interface class NativePsdkCatalog {
  Map<String, PokemonSpeciesFile> get speciesById;
  Map<String, PokemonLearnsetFile> get learnsetsBySpeciesId;
  Map<String, PokemonMove> get movesById;
  Map<String, PokemonEvolutionFile> get evolutionsBySpeciesId;
  Map<String, PokemonMediaFile> get mediaBySpeciesId;
  Map<String, Map<String, Object?>> get fallbackMedia;
  Map<String, PokemonCatalogFile> get catalogs;
  Map<String, Object?> get evidence;
  Map<String, Object?> toJson();
}

final class NativePsdkTrainerBundle implements NativePsdkCatalog {
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
    if (json['kind'] != 'nativePsdkTrainerBundle' || json['version'] != 2) {
      throw ContractError('native_trainer.bundle_version', r'$',
          'A versioned native trainer reference bundle is required.');
    }
    final species = <String, PokemonSpeciesFile>{};
    final learnsets = <String, PokemonLearnsetFile>{};
    final catalogs = <String, PokemonCatalogFile>{};
    final moves = <String, PokemonMove>{};
    for (final raw in _objects(json['species'])) {
      final breeding = raw['breeding'];
      _validateGenderRatio(breeding is Map ? breeding['genderRatio'] : null);
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
    final natures = _ids(catalogs['natures']);
    if (natures.length != canonicalPokemonNatureIds.length ||
        !natures.containsAll(canonicalPokemonNatureIds)) {
      _invalid('nature_closure');
    }
    for (final entry in catalogs['natures']!.entries) {
      _validateNatureEntry(entry);
    }
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
    final witnesses = _objects(evidence['sources']);
    for (final id in canonicalPokemonNatureIds) {
      final sources = witnesses.where(
          (source) => source['relativePath'] == 'Data/Studio/natures/$id.json');
      if (sources.length != 1) _invalid('nature_source_witness');
      final source = sources.single;
      final hash = source['sha256'];
      final byteLength = source['byteLength'];
      if (hash is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
          byteLength is! int ||
          byteLength <= 0 ||
          byteLength > 1048576) {
        _invalid('nature_source_witness');
      }
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

  @override
  final Map<String, PokemonSpeciesFile> speciesById;
  @override
  final Map<String, PokemonLearnsetFile> learnsetsBySpeciesId;
  @override
  final Map<String, PokemonMove> movesById;
  @override
  final Map<String, PokemonEvolutionFile> evolutionsBySpeciesId;
  @override
  final Map<String, PokemonMediaFile> mediaBySpeciesId;
  @override
  final Map<String, Map<String, Object?>> fallbackMedia;
  @override
  final Map<String, PokemonCatalogFile> catalogs;
  @override
  final Map<String, Object?> evidence;

  @override
  Map<String, Object?> toJson() => {
        'kind': 'nativePsdkTrainerBundle',
        'version': 2,
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

const nativeQualifiedFieldMoveSourceHashes = <String, String>{
  'cut': 'e9c317f52c3785df6ac9731ef14d791903b5f5e5b28aee1264893f731a56fdb5',
};

final class NativePsdkCatalogRequest {
  NativePsdkCatalogRequest({
    required this.baseId,
    required this.form,
    required this.level,
    List<String>? explicitMoveIds,
  }) : explicitMoveIds = explicitMoveIds == null
            ? null
            : List.unmodifiable(explicitMoveIds) {
    if (!_nativeSymbol.hasMatch(baseId) ||
        form < 0 ||
        level < 1 ||
        level > 100 ||
        (explicitMoveIds != null &&
            (explicitMoveIds.isEmpty ||
                explicitMoveIds.length > 4 ||
                explicitMoveIds.toSet().length != explicitMoveIds.length ||
                explicitMoveIds.any((id) => !_nativeSymbol.hasMatch(id))))) {
      _invalid('request_invalid');
    }
  }

  factory NativePsdkCatalogRequest.fromJson(Map<String, dynamic> json) {
    if (json.keys.any((key) => !const {
              'baseId',
              'form',
              'level',
              'explicitMoveIds'
            }.contains(key)) ||
        json['baseId'] is! String ||
        json['form'] is! int ||
        json['level'] is! int ||
        (json.containsKey('explicitMoveIds') &&
            (json['explicitMoveIds'] is! List ||
                (json['explicitMoveIds'] as List)
                    .any((id) => id is! String)))) {
      _invalid('request_invalid');
    }
    return NativePsdkCatalogRequest(
        baseId: json['baseId'] as String,
        form: json['form'] as int,
        level: json['level'] as int,
        explicitMoveIds: (json['explicitMoveIds'] as List?)?.cast<String>());
  }

  final String baseId;
  final int form;
  final int level;
  final List<String>? explicitMoveIds;

  Map<String, Object?> toJson() => {
        'baseId': baseId,
        'form': form,
        'level': level,
        if (explicitMoveIds != null) 'explicitMoveIds': explicitMoveIds,
      };
}

final _nativeSymbol = RegExp(r'^[a-z][a-z0-9_]*$');

Map<int, String> nativePsdkEnglishSpeciesNames(
    NativePsdkTrainerSourceFile file) {
  final table = _NativePsdkNameTable(file);
  return Map.unmodifiable({
    for (var index = 0; index < table.rows.length; index++)
      index: table.rows[index][table.enIndex].replaceAll(r'\nl', '\n'),
  });
}

final class _NativePsdkNameTable {
  _NativePsdkNameTable._(this.path, this.rows, this.enIndex, this.frIndex);

  factory _NativePsdkNameTable(NativePsdkTrainerSourceFile file) {
    final path = file.relativePath;
    final String text;
    try {
      text = utf8.decode(file.bytes);
    } on FormatException {
      _invalid('source_csv:$path');
    }
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var state = 0;
    void finishField() {
      row.add(field.toString());
      field = StringBuffer();
      state = 0;
    }

    for (var i = 0; i < text.length; i++) {
      final character = text[i];
      if (state == 1) {
        if (character == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            state = 2;
          }
        } else {
          field.write(character);
        }
      } else if (character == ',') {
        finishField();
      } else if (character == '\r' || character == '\n') {
        finishField();
        rows.add(row);
        row = <String>[];
        if (character == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
          i++;
        }
      } else if (character == '"' && state == 0 && field.isEmpty) {
        state = 1;
      } else {
        if (character == '"' || state == 2) _invalid('source_csv:$path');
        field.write(character);
      }
    }
    if (state == 1) _invalid('source_csv:$path');
    if (row.isNotEmpty || field.isNotEmpty || state == 2) {
      finishField();
      rows.add(row);
    }
    if (rows.isEmpty) _invalid('name_languages:$path');
    final header =
        rows.first.map((value) => value.trim().toLowerCase()).toList();
    if (header.any((value) => value.isEmpty) ||
        header.toSet().length != header.length ||
        !header.contains('en') ||
        !header.contains('fr')) {
      _invalid('name_languages:$path');
    }
    if (rows.any((row) => row.length != header.length)) {
      _invalid('source_csv:$path');
    }
    return _NativePsdkNameTable._(
        path, rows.sublist(1), header.indexOf('en'), header.indexOf('fr'));
  }

  final String path;
  final List<List<String>> rows;
  final int enIndex;
  final int frIndex;

  Map<String, String> names(int index) {
    if (index < 0 || index >= rows.length) {
      _invalid('name_missing:$path:$index');
    }
    final names = {
      'en': rows[index][enIndex].replaceAll(r'\nl', '\n'),
      'fr': rows[index][frIndex].replaceAll(r'\nl', '\n')
    };
    if (names.values.any((value) => value.trim().isEmpty)) {
      _invalid('name_missing:$path:$index');
    }
    return names;
  }
}

final class NativePsdkTrainerBundleBuilder {
  const NativePsdkTrainerBundleBuilder();

  NativePsdkTrainerBundle build({
    required List<NativePsdkTrainerSourceFile> files,
    required List<NativePsdkCatalogRequest> requests,
  }) {
    if (requests.isEmpty) _invalid('request_invalid');
    if (requests.length > 256) _invalid('request_quota');
    if (files.length > 2048) _invalid('source_file_quota');
    if (files.fold<int>(0, (sum, file) => sum + file.bytes.length) > 16777216) {
      _invalid('source_bytes_quota');
    }
    final orderedRequests = requests.toList()
      ..sort((a, b) {
        final base = a.baseId.compareTo(b.baseId);
        if (base != 0) return base;
        final form = a.form.compareTo(b.form);
        if (form != 0) return form;
        final level = a.level.compareTo(b.level);
        if (level != 0) return level;
        if (a.explicitMoveIds == null) {
          return b.explicitMoveIds == null ? 0 : -1;
        }
        if (b.explicitMoveIds == null) return 1;
        return jsonEncode(a.explicitMoveIds)
            .compareTo(jsonEncode(b.explicitMoveIds));
      });
    final requestKeys = <String>{};
    for (final request in orderedRequests) {
      if (!requestKeys.add(canonicalHashOf(request.toJson()).value)) {
        _invalid('duplicate_request');
      }
    }
    final requestedSpecies =
        orderedRequests.map((r) => r.baseId).toSet().toList()..sort();
    if (requestedSpecies.length > 64) _invalid('requested_base_quota');
    final index = <String, NativePsdkTrainerSourceFile>{};
    for (final file in files) {
      if (index.containsKey(file.relativePath)) _invalid('duplicate_source');
      index[file.relativePath] = file;
    }
    final used = <String>{};
    Map<String, dynamic> read(String path, String id) {
      final file = index[path];
      if (file == null) _invalid('source_missing:$path');
      final fieldMoveHash = nativeQualifiedFieldMoveSourceHashes[id];
      if (path == 'Data/Studio/moves/$id.json' &&
          fieldMoveHash != null &&
          file.sha256.value != fieldMoveHash) {
        _invalid('field_move_source_witness:$path');
      }
      final Object? decoded;
      try {
        decoded = jsonDecode(utf8.decode(file.bytes));
      } on FormatException {
        _invalid('source_json:$path');
      }
      if (decoded is! Map<String, dynamic>) _invalid('source_json:$path');
      final raw = decoded;
      if (raw['dbSymbol'] != id) _invalid('source_identity:$path');
      used.add(path);
      return raw;
    }

    _NativePsdkNameTable readNames(String path) {
      final file = index[path];
      if (file == null) _invalid('source_missing:$path');
      final table = _NativePsdkNameTable(file);
      used.add(path);
      return table;
    }

    final speciesNames = readNames('Data/Text/Dialogs/100000.csv');
    final formNames = readNames('Data/Text/Dialogs/100067.csv');
    final nativeFormNames = <String, Map<String, String>>{};
    final species = <Map<String, Object?>>[];
    final learnsets = <Map<String, Object?>>[];
    final evolutions = <Map<String, Object?>>[];
    final media = <Map<String, Object?>>[];
    final fallbackMedia = <Map<String, Object?>>[];
    final selectedMoves = {
      ...nativeQualifiedFieldMoveSourceHashes.keys,
      for (final request in orderedRequests) ...?request.explicitMoveIds,
    };
    final battleDefaultMoves = <String>{};
    final abilityIds = <String>{};
    final growthIds = <String>{};
    final closure = requestedSpecies.toSet();
    final queue = requestedSpecies.toList();
    final raws = <String, Map<String, dynamic>>{};
    final formsByBase = <String, List<Map<String, dynamic>>>{};
    final sourceSpeciesAdaptations = <Map<String, Object?>>[];
    var formCount = 0;
    for (var cursor = 0; cursor < queue.length; cursor++) {
      if (queue.length > 128) _invalid('species_closure_quota');
      final id = queue[cursor];
      final raw = read('Data/Studio/pokemon/$id.json', id);
      if (raw['klass'] != 'Specie' ||
          raw['id'] is! int ||
          (raw['id'] as int) < 0) {
        _invalid('species_identity');
      }
      raws[id] = raw;
      final forms = _objects(raw['forms']);
      if (id == 'sneasel' &&
          index['Data/Studio/pokemon/sneasel.json']!.sha256.value ==
              'c10ef9bcaaa901bcc779a1fb62fc77f04c3f9cc33ed239800801d4be79a9781f' &&
          raw['id'] == 215 &&
          forms.length == 1 &&
          forms.single['form'] == 0 &&
          forms.single['babyDbSymbol'] == 'sneasel' &&
          forms.single['babyForm'] == 1) {
        forms.single['babyForm'] = 0;
        sourceSpeciesAdaptations.add({
          'sourceSpeciesId': id,
          'form': 0,
          'field': 'babyForm',
          'sourceValue': 1,
          'nativeValue': 0,
          'reason': 'danglingSelfBabyFormInNativeReference',
        });
      }
      formCount += forms.length;
      if (formCount > 128) _invalid('form_quota');
      final formNumbers = <int>{};
      for (final form in forms) {
        final number = form['form'];
        if (number is! int || number < 0) _invalid('form_invalid');
        if (!formNumbers.add(number)) _invalid('form_ambiguous');
      }
      if (!formNumbers.contains(0)) _invalid('form_missing');
      formsByBase[id] = forms
        ..sort((a, b) => (a['form'] as int).compareTo(b['form'] as int));
      for (final form in forms) {
        final targets = <String>[
          for (final evolution in _objects(form['evolutions']))
            (evolution['dbSymbol'] ?? id) as String,
          if (form['babyDbSymbol'] case final String baby) baby,
        ];
        for (final target in targets) {
          if (target != 'none' &&
              target != '__undef__' &&
              closure.add(target)) {
            if (!_nativeSymbol.hasMatch(target)) _invalid('species_identity');
            if (closure.length > 128) _invalid('species_closure_quota');
            queue.add(target);
          }
        }
      }
    }
    void requireForm(String base, Object? number) {
      final forms = formsByBase[base];
      if (number is! int ||
          number < 0 ||
          forms == null ||
          !forms.any((form) => form['form'] == number)) {
        _invalid('form_missing');
      }
    }

    for (final request in orderedRequests) {
      requireForm(request.baseId, request.form);
    }
    for (final base in formsByBase.entries) {
      for (final form in base.value) {
        for (final rule in _objects(form['evolutions'])) {
          requireForm((rule['dbSymbol'] ?? base.key) as String, rule['form']);
          for (final condition in _objects(rule['conditions'])) {
            if (condition['type'] == 'skill1') {
              final move = condition['value'];
              if (move is! String || !_nativeSymbol.hasMatch(move)) {
                _invalid('move_identity');
              }
              selectedMoves.add(move);
            }
          }
        }
        final baby = form['babyDbSymbol'];
        if (baby is String && baby != 'none' && baby != '__undef__') {
          requireForm(baby, form['babyForm']);
        }
        for (final move in _objects(form['moveSet'])) {
          final id = move['move'];
          if (id is! String || !_nativeSymbol.hasMatch(id)) {
            _invalid('move_identity');
          }
          selectedMoves.add(id);
        }
      }
    }
    if (selectedMoves.length > 512) _invalid('move_quota');
    final requestBindings = <Map<String, Object?>>[];
    final orderedSpecies = raws.keys.toList()..sort();
    for (final baseId in orderedSpecies) {
      final raw = raws[baseId]!;
      final forms = formsByBase[baseId]!;
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
        value['names'] = speciesNames.names(raw['id'] as int);
        final formTextId = form['formTextId'];
        final formNameIndex = formTextId is Map ? formTextId['name'] : null;
        if (formNameIndex is! int || formNameIndex < 0) {
          _invalid('form_text_id');
        }
        final names = formNames.names(formNameIndex);
        nativeFormNames[id] = names;
        final growth = switch (form['experienceType']) {
          0 => 'fast',
          1 => 'medium',
          2 => 'slow',
          3 => 'medium_slow',
          4 => 'slow_then_very_fast',
          5 => 'fast_then_very_slow',
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
        value['breeding'] = {
          ...value['breeding'] as Map,
          'genderRatio': _nativeGenderRatio(form['femaleRate']),
        };
        value['forms'] = {
          'baseFormId': baseId,
          'isBaseForm': number == 0,
          'formId': '$number',
          'formName': names['en'],
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
        for (final request in orderedRequests.where(
            (request) => request.baseId == baseId && request.form == number)) {
          final defaults = request.explicitMoveIds == null
              ? nativeTrainerDefaultMoveIds(learnset, request.level)
              : request.explicitMoveIds!;
          if (defaults.isEmpty) _invalid('empty_moves');
          if (request.explicitMoveIds == null) {
            battleDefaultMoves.addAll(defaults);
          }
          requestBindings.add({
            'baseId': baseId,
            'form': number,
            'level': request.level,
            'movePolicy':
                request.explicitMoveIds == null ? 'nativeDefaults' : 'explicit',
            'moveIds': defaults,
          });
        }
        final evolutionEntries = <PokemonEvolutionEntry>[];
        for (final evolution in _objects(form['evolutions'])) {
          final conditions = _objects(evolution['conditions']);
          final target = nativePsdkFormSpeciesId(
              (evolution['dbSymbol'] ?? baseId) as String,
              evolution['form'] as int);
          final condition = conditions.length == 1 ? conditions.single : null;
          final type = condition?['type'];
          final trade = _nativeTradeRequirements(conditions);
          evolutionEntries.add(PokemonEvolutionEntry(
              targetSpeciesId: target,
              method: trade != null
                  ? 'trade'
                  : type == 'minLevel'
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
              conditionText: {'psdk': jsonEncode(conditions)},
              tradeRequirements: trade));
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
    final sourceMoveAdaptations = <Map<String, Object?>>[];
    for (final id in selectedMoves.toList()..sort()) {
      final raw = read('Data/Studio/moves/$id.json', id);
      final payload = Map<String, Object?>.from(raw);
      payload['criticalRate'] = raw['movecriticalRate'];
      if (raw['movecriticalRate'] is num &&
          (raw['movecriticalRate'] as num) <= 0) {
        if (raw['movecriticalRate'] != 0 ||
            raw['category'] != 'status' ||
            raw['power'] != 0) {
          _invalid('move_critical_rate');
        }
        payload['criticalRate'] = 1;
        sourceMoveAdaptations.add({
          'sourceMoveId': id,
          'field': 'movecriticalRate',
          'sourceValue': 0,
          'nativeValue': 1,
          'reason': 'statusMoveDoesNotCalculateCriticalDamage',
        });
      }
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
    final natures = <Map<String, dynamic>>[];
    for (final id in canonicalPokemonNatureIds.toList()..sort()) {
      final raw = read('Data/Studio/natures/$id.json', id);
      natures.add(_nativeNatureEntry(id, raw));
    }
    for (final entry in {
      'types': types,
      'abilities': abilities,
      'growth_rates': [
        for (final id in growthIds.toList()..sort()) {'id': id}
      ],
      'natures': natures,
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
      'version': 2,
      'species': species,
      'sourceLearnsets': learnsets,
      'evolutions': evolutions,
      'media': media,
      'fallbackMedia': fallbackMedia,
      'catalogs': catalogs,
      'evidence': {
        'authority': 'AveluneNativePsdkData',
        'scope': 'nativeSpeciesCompanionClosure',
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
        'nativeQualifiedFieldMoveIds':
            nativeQualifiedFieldMoveSourceHashes.keys.toList()..sort(),
        'nativeQualifiedFieldMoveSourceHashes':
            nativeQualifiedFieldMoveSourceHashes,
        'nativeStatProfile': 'trainerV0',
        'nativeAbilityPolicy': 'speciesPrimary',
        'movePolicy': 'perNativeCatalogRequest',
        'moveDerivation': 'startingThenRelearnThenOrderedLevelUpUniqueLastFour',
        'catalogRequests': [
          for (final request in orderedRequests) request.toJson()
        ],
        'nativeRequestMoveBindings': requestBindings,
        'nativeNamesQualified': false,
        'speciesNamesQualified': true,
        'formNamesQualified': true,
        'speciesNameOracle': 'Studio::Creature#name:table0:JSON.id',
        'formNameOracle':
            'Studio::CreatureForm#form_name:table67:formTextId.name',
        'nativeFormNameLanguage': 'en',
        'nativeFormNamesBySpeciesId': nativeFormNames,
        'nativeMoveDataFidelityOnly': true,
        if (sourceMoveAdaptations.isNotEmpty)
          'sourceMoveAdaptations': sourceMoveAdaptations,
        if (sourceSpeciesAdaptations.isNotEmpty)
          'sourceSpeciesAdaptations': sourceSpeciesAdaptations,
        'activationRequiresExactRuntimeMoveQualification': true,
        'quotas': {
          'requests': 256,
          'requestedBases': 64,
          'closureBases': 128,
          'forms': 128,
          'moves': 512,
          'sourceFiles': 2048,
          'perSourceBytes': 1048576,
          'totalSourceBytes': 16777216
        },
        'sources': [
          for (final path in used.toList()..sort()) index[path]!.evidence
        ],
        'growthRateOracle': 'PFM::Pokemon::ExpList::KIND_TO_METHOD',
        'genderRatioOracle': 'Studio::CreatureForm#female_rate',
        'natureStatOracle': 'Studio::Nature#stats',
        'natureEffectPolicy': 'canonicalPokemonNatureEffect',
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

Map<String, double> _nativeGenderRatio(Object? femaleRate) {
  if (femaleRate is! num ||
      !femaleRate.isFinite ||
      (femaleRate != -1 && (femaleRate < 0 || femaleRate > 100))) {
    _invalid('female_rate');
  }
  if (femaleRate == -1) return {'genderless': 1};
  return {'male': 100 - femaleRate.toDouble(), 'female': femaleRate.toDouble()};
}

void _validateGenderRatio(Object? value) {
  if (value is! Map ||
      value.values.any((weight) =>
          weight is! num || !weight.isFinite || weight < 0 || weight > 100)) {
    _invalid('gender_ratio');
  }
  if (value.length == 1 && value['genderless'] == 1) return;
  if (value.length != 2 ||
      !value.containsKey('male') ||
      !value.containsKey('female') ||
      (value['male'] as num) + (value['female'] as num) != 100) {
    _invalid('gender_ratio');
  }
}

Map<String, dynamic> _nativeNatureEntry(String id, Map<String, dynamic> raw) {
  final stats = raw['stats'];
  if (raw['klass'] != 'Nature' ||
      raw['id'] != canonicalPokemonNatureIds.indexOf(id) ||
      stats is! Map ||
      stats.length != 5) {
    _invalid('nature_stats');
  }
  const nativeStats = {
    'atk': PokemonNatureStat.attack,
    'dfe': PokemonNatureStat.defense,
    'spd': PokemonNatureStat.speed,
    'ats': PokemonNatureStat.specialAttack,
    'dfs': PokemonNatureStat.specialDefense,
  };
  final effect = canonicalPokemonNatureEffect(id);
  String? increased, decreased;
  for (final entry in nativeStats.entries) {
    final value = stats[entry.key];
    if (value is! int || value != effect.apply(100, entry.value)) {
      _invalid('nature_stats');
    }
    if (value == 110) increased = entry.value.name;
    if (value == 90) decreased = entry.value.name;
  }
  return {'id': id, 'increasedStat': increased, 'decreasedStat': decreased};
}

void _validateNatureEntry(Map<String, dynamic> entry) {
  final effect = canonicalPokemonNatureEffect(entry['id'] as String);
  if (!entry.containsKey('increasedStat') ||
      !entry.containsKey('decreasedStat') ||
      entry['increasedStat'] != effect.increasedStat?.name ||
      entry['decreasedStat'] != effect.decreasedStat?.name) {
    _invalid('nature_effect');
  }
}

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

PokemonTradeEvolutionRequirements? _nativeTradeRequirements(
    List<Map<String, dynamic>> conditions) {
  if (conditions.isEmpty || conditions.length > 2) return null;
  final seen = <String>{};
  String? item, partner;
  var trade = false;
  for (final condition in conditions) {
    if (condition.length != 2 ||
        !condition.containsKey('type') ||
        !condition.containsKey('value')) {
      return null;
    }
    final type = condition['type'];
    if (type is! String || !seen.add(type)) return null;
    final value = condition['value'];
    switch (type) {
      case 'trade':
        if (value != true || partner != null) return null;
        trade = true;
      case 'tradeWith':
        if (value is! String || trade) return null;
        partner = value;
      case 'itemHold':
        if (value is! String) return null;
        item = value;
      default:
        return null;
    }
  }
  if (!trade && partner == null) return null;
  try {
    return PokemonTradeEvolutionRequirements(
            requiredHeldItemId: item, requiredPartnerSpeciesId: partner)
        .validated();
  } on FormatException {
    return null;
  }
}
