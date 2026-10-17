import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/generated/native_psdk_trainer_bundle_data.dart';
import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

void main() {
  test('embedded reference matches the rebuildable asset exactly', () async {
    final asset =
        await File('assets/native_psdk_trainer_bundle.json').readAsString();
    expect(asset, nativePsdkTrainerBundleJson);
    final builtin = NativePsdkTrainerBundle.builtin();
    final restored = NativePsdkTrainerBundle.fromJson(
        jsonDecode(jsonEncode(builtin.toJson())) as Map<String, dynamic>);
    expect(
        canonicalHashOf(builtin.toJson()), canonicalHashOf(restored.toJson()));
    final paths = (builtin.evidence['sources'] as List).cast<Map>();
    expect(paths, hasLength(583));
    expect(
        paths.every(
            (source) => !(source['relativePath'] as String).startsWith('/')),
        isTrue);
    expect(
        paths.every((source) => !source.containsKey('absolutePath')), isTrue);
  });

  test('preserves the qualified native documents and trainer recipe', () {
    final json =
        jsonDecode(jsonEncode(NativePsdkTrainerBundle.builtin().toJson()))
            as Map<String, dynamic>;
    json.remove('version');
    for (final species in (json['species'] as List).cast<Map>()) {
      (species['breeding'] as Map).remove('genderRatio');
    }
    (json['catalogs'] as List)
        .removeWhere((catalog) => (catalog as Map)['catalog'] == 'natures');
    final evidence = json['evidence'] as Map;
    for (final field in [
      'genderRatioOracle',
      'natureStatOracle',
      'natureEffectPolicy'
    ]) {
      evidence.remove(field);
    }
    (evidence['sources'] as List).removeWhere((source) =>
        ((source as Map)['relativePath'] as String)
            .startsWith('Data/Studio/natures/'));
    expect(canonicalHashOf(json).value,
        '699bc40673918781767d199381f1113486e77c204fa9d8e12e5c08db443af069');
  });

  test('rejects duplicate documents and incomplete type charts', () {
    final original = NativePsdkTrainerBundle.builtin().toJson();
    final duplicate = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
    (duplicate['species'] as List).add((duplicate['species'] as List).first);
    expect(
        () => NativePsdkTrainerBundle.fromJson(duplicate),
        throwsA(isA<ContractError>().having((error) => error.code, 'code',
            'native_trainer.duplicate_species')));
    final missing = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
    final types = (missing['catalogs'] as List)
        .cast<Map>()
        .singleWhere((catalog) => catalog['catalog'] == 'types');
    (types['entries'] as List).removeLast();
    expect(
        () => NativePsdkTrainerBundle.fromJson(missing),
        throwsA(isA<ContractError>().having(
            (error) => error.code, 'code', 'native_trainer.type_closure')));
  });

  test('maps every native form female rate to canonical gender weights', () {
    for (final (rate, expected) in <(num, Map<String, double>)>[
      (-1, {'genderless': 1}),
      (0, {'male': 100, 'female': 0}),
      (12.5, {'male': 87.5, 'female': 12.5}),
      (50, {'male': 50, 'female': 50}),
      (100, {'male': 0, 'female': 100}),
    ]) {
      final bundle = _buildFixture(femaleRate: rate);
      expect(bundle.speciesById['fixture']!.breeding.genderRatio, expected);
      expect(bundle.speciesById['fixture_form1']!.breeding.genderRatio,
          {'male': 75, 'female': 25});
    }
  });

  test('rejects missing and invalid native form female rates before output',
      () {
    for (final invalid in [null, '50', -2, -0.5, 100.1, 101]) {
      expect(() => _buildFixture(femaleRate: invalid), _code('female_rate'));
    }
    for (final invalid in ['1e400', '-1e400']) {
      final sources = _fixtureSources();
      final source = sources.first;
      final text = utf8
          .decode(source.bytes)
          .replaceFirst('"femaleRate":50', '"femaleRate":$invalid');
      final bytes = utf8.encode(text);
      sources[0] = NativePsdkTrainerSourceFile(
          relativePath: source.relativePath,
          sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
          bytes: bytes);
      expect(
          () => const NativePsdkTrainerBundleBuilder()
                  .build(files: sources, requestedLevels: {
                'fixture': {1}
              }),
          _code('female_rate'));
    }
  });

  test('rejects a missing female rate on an alternate form', () {
    final sources = _fixtureSources();
    _mutateSource(sources, 'Data/Studio/pokemon/fixture.json',
        (raw) => ((raw['forms'] as List).last as Map).remove('femaleRate'));
    expect(
        () => const NativePsdkTrainerBundleBuilder()
                .build(files: sources, requestedLevels: {
              'fixture': {1}
            }),
        _code('female_rate'));
  });

  test('publishes all native nature effects with exact source witnesses', () {
    final bundle = _buildFixture();
    final entries = bundle.catalogs['natures']!.entries;
    expect(entries.map((entry) => entry['id']),
        orderedEquals(_natureRows.map((row) => row.$1).toList()..sort()));
    final neutral = <String>[];
    for (final entry in entries) {
      final row = _natureRows.singleWhere((row) => row.$1 == entry['id']);
      const stats = [
        'attack',
        'defense',
        'speed',
        'specialAttack',
        'specialDefense'
      ];
      expect(entry['increasedStat'],
          row.$2.contains(110) ? stats[row.$2.indexOf(110)] : null);
      expect(entry['decreasedStat'],
          row.$2.contains(90) ? stats[row.$2.indexOf(90)] : null);
      if (entry['increasedStat'] == null) neutral.add(entry['id'] as String);
    }
    expect(neutral, ['bashful', 'docile', 'hardy', 'quirky', 'serious']);
    final files = _fixtureSources();
    final witnesses = (bundle.evidence['sources'] as List).cast<Map>();
    for (final source in files.where(
        (source) => source.relativePath.startsWith('Data/Studio/natures/'))) {
      expect(
          witnesses
              .singleWhere((row) => row['relativePath'] == source.relativePath),
          source.evidence);
    }
  });

  test('rejects missing or noncanonical native nature source data', () {
    for (final mutation in <void Function(List<NativePsdkTrainerSourceFile>)>[
      (sources) => sources.removeWhere((source) =>
          source.relativePath == 'Data/Studio/natures/adamant.json'),
      (sources) => _mutateSource(sources, 'Data/Studio/natures/adamant.json',
          (raw) => (raw['stats'] as Map).remove('ats')),
      (sources) => _mutateSource(sources, 'Data/Studio/natures/adamant.json',
          (raw) => (raw['stats'] as Map)['ats'] = 100),
      (sources) => _mutateSource(
          sources, 'Data/Studio/natures/adamant.json', (raw) => raw['id'] = 4),
      (sources) => _mutateSource(sources, 'Data/Studio/natures/adamant.json',
          (raw) => raw['klass'] = 'Move'),
      (sources) => _mutateSource(sources, 'Data/Studio/natures/adamant.json',
          (raw) => raw['dbSymbol'] = 'jolly'),
      (sources) => sources.add(sources.singleWhere((source) =>
          source.relativePath == 'Data/Studio/natures/adamant.json')),
    ]) {
      final sources = _fixtureSources();
      mutation(sources);
      expect(
          () => const NativePsdkTrainerBundleBuilder()
                  .build(files: sources, requestedLevels: {
                'fixture': {1}
              }),
          throwsA(isA<ContractError>()));
    }
  });

  test('rejects incoherent canonical bundle gender ratios', () {
    for (final ratio in <Map<String, Object?>>[
      {},
      {'genderless': 1, 'male': 100},
      {'male': 50},
      {'male': 60, 'female': 50},
      {'male': -1, 'female': 101},
      {'male': double.nan, 'female': 50},
      {'male': 50, 'female': double.infinity},
      {'genderless': 100},
      {'unknown': 100},
    ]) {
      final json = _buildFixture().toJson();
      final first = (json['species'] as List).first as Map;
      (first['breeding'] as Map)['genderRatio'] = ratio;
      expect(
          () => NativePsdkTrainerBundle.fromJson(json), _code('gender_ratio'));
    }
  });

  test('rejects incomplete duplicate or tampered bundle nature effects', () {
    for (final mutation in <void Function(Map<String, Object?>)>[
      (json) => _natureEntries(json).removeLast(),
      (json) => _natureEntries(json).add(_natureEntries(json).first),
      (json) => (_natureEntries(json).first as Map)['increasedStat'] = 'speed',
      (json) => (_natureEntries(json).first as Map).remove('decreasedStat'),
      (json) => _natureEntries(json).clear(),
      (json) => (_natureEntries(json).first as Map)['id'] = 'invented',
    ]) {
      final json = jsonDecode(jsonEncode(_buildFixture().toJson()))
          as Map<String, dynamic>;
      mutation(json);
      expect(() => NativePsdkTrainerBundle.fromJson(json),
          throwsA(isA<ContractError>()));
    }
  });

  test('rejects obsolete bundle contracts and missing nature witnesses', () {
    final obsolete = _buildFixture().toJson()..['version'] = 1;
    expect(() => NativePsdkTrainerBundle.fromJson(obsolete),
        _code('bundle_version'));
    final missing = jsonDecode(jsonEncode(_buildFixture().toJson()))
        as Map<String, dynamic>;
    ((missing['evidence'] as Map)['sources'] as List).removeWhere((source) =>
        (source as Map)['relativePath'] == 'Data/Studio/natures/jolly.json');
    expect(() => NativePsdkTrainerBundle.fromJson(missing),
        _code('nature_source_witness'));
  });

  test('builds deterministic documents from unordered exact witnesses', () {
    final files = _fixtureSources();
    final ordered = const NativePsdkTrainerBundleBuilder()
        .build(files: files, requestedLevels: {
      'fixture': {1}
    });
    final reversed = const NativePsdkTrainerBundleBuilder()
        .build(files: files.reversed.toList(), requestedLevels: {
      'fixture': {1}
    });
    expect(
        canonicalHashOf(ordered.toJson()), canonicalHashOf(reversed.toJson()));
    expect(ordered.movesById.keys, ['cut']);
    expect(ordered.evidence['nativeBattleDefaultMoveIds'], ['cut']);
    expect(ordered.speciesById['fixture']!.baseStats.toJson(), {
      'hp': 65,
      'atk': 90,
      'def': 40,
      'spa': 45,
      'spd': 80,
      'spe': 75,
      'bst': 395
    });
    expect(ordered.learnsetsBySpeciesId['fixture']!.startingMoves, ['cut']);
  });

  final sourceRoot = Platform.environment['AVELUNE_NATIVE_PSDK_REFERENCE_ROOT'];
  test('rebuilds the same species, moves and charts from attested PSDK JSON',
      () async {
    final builtin = NativePsdkTrainerBundle.builtin();
    final files = <NativePsdkTrainerSourceFile>[];
    for (final raw in (builtin.evidence['sources'] as List).cast<Map>()) {
      final path = raw['relativePath'] as String;
      final bytes = await File('$sourceRoot/$path').readAsBytes();
      expect(crypto.sha256.convert(bytes).toString(), raw['sha256']);
      files.add(NativePsdkTrainerSourceFile(
          relativePath: path,
          sha256: Sha256Hash(raw['sha256'] as String),
          bytes: bytes));
    }
    final levels = (builtin.evidence['requestedLevels'] as Map).map(
        (key, value) =>
            MapEntry(key as String, (value as List).cast<int>().toSet()));
    final rebuilt = const NativePsdkTrainerBundleBuilder()
        .build(files: files, requestedLevels: levels);
    expect(rebuilt.toJson()['species'], builtin.toJson()['species']);
    expect(rebuilt.toJson()['sourceLearnsets'],
        builtin.toJson()['sourceLearnsets']);
    expect(rebuilt.toJson()['catalogs'], builtin.toJson()['catalogs']);
    expect(rebuilt.evidence['sources'], builtin.evidence['sources']);
  },
      skip: sourceRoot == null
          ? 'Requires the optional read-only PSDK reference root.'
          : false);
}

Matcher _code(String suffix) => throwsA(isA<ContractError>()
    .having((error) => error.code, 'code', 'native_trainer.$suffix'));

List<dynamic> _natureEntries(Map<String, Object?> json) =>
    ((json['catalogs'] as List).cast<Map>().singleWhere(
        (catalog) => catalog['catalog'] == 'natures')['entries'] as List);

NativePsdkTrainerBundle _buildFixture({Object? femaleRate = 50}) =>
    const NativePsdkTrainerBundleBuilder().build(
        files: _fixtureSources(femaleRate: femaleRate),
        requestedLevels: {
          'fixture': {1}
        });

NativePsdkTrainerSourceFile _source(String path, Object raw) {
  final bytes = utf8.encode(jsonEncode(raw));
  return NativePsdkTrainerSourceFile(
      relativePath: path,
      sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
      bytes: bytes);
}

void _mutateSource(List<NativePsdkTrainerSourceFile> sources, String path,
    void Function(Map<String, dynamic>) mutate) {
  final index = sources.indexWhere((source) => source.relativePath == path);
  final raw =
      jsonDecode(utf8.decode(sources[index].bytes)) as Map<String, dynamic>;
  mutate(raw);
  sources[index] = _source(path, raw);
}

List<NativePsdkTrainerSourceFile> _fixtureSources({Object? femaleRate = 50}) {
  Map<String, Object?> form(int number, Object? rate) => {
        'form': number,
        'femaleRate': rate,
        'type1': 'bug',
        'type2': 'poison',
        'baseHp': 65,
        'baseAtk': 90,
        'baseDfe': 40,
        'baseAts': 45,
        'baseDfs': 80,
        'baseSpd': 75,
        'height': 1,
        'weight': 29.5,
        'experienceType': 1,
        'baseExperience': 178,
        'catchRate': 45,
        'baseLoyalty': 70,
        'abilities': ['swarm', 'swarm', 'swarm'],
        'moveSet': [
          {'klass': 'LevelLearnableMove', 'move': 'cut', 'level': 1}
        ],
        'evolutions': [],
        'resources': {'front': 'fixture', 'back': 'fixture'},
      };
  final cut = base64Decode(
      'ew0KICAia2xhc3MiOiAiTW92ZSIsDQogICJpZCI6IDE1LA0KICAiZGJTeW1ib2wiOiAiY3V0IiwNCiAgIm1hcFVzZSI6IDIxLA0KICAiYmF0dGxlRW5naW5lTWV0aG9kIjogInNfYmFzaWMiLA0KICAidHlwZSI6ICJub3JtYWwiLA0KICAicG93ZXIiOiA1MCwNCiAgImFjY3VyYWN5IjogOTUsDQogICJwcCI6IDMwLA0KICAiY2F0ZWdvcnkiOiAicGh5c2ljYWwiLA0KICAibW92ZWNyaXRpY2FsUmF0ZSI6IDEsDQogICJwcmlvcml0eSI6IDAsDQogICJpc0F1dGhlbnRpYyI6IGZhbHNlLA0KICAiaXNCYWxsaXN0aWNzIjogZmFsc2UsDQogICJpc0JpdGUiOiBmYWxzZSwNCiAgImlzQmxvY2FibGUiOiB0cnVlLA0KICAiaXNDaGFyZ2UiOiBmYWxzZSwNCiAgImlzRGFuY2UiOiBmYWxzZSwNCiAgImlzRGlyZWN0IjogdHJ1ZSwNCiAgImlzRWZmZWN0Q2hhbmNlIjogZmFsc2UsDQogICJpc0dyYXZpdHkiOiBmYWxzZSwNCiAgImlzSGVhbCI6IGZhbHNlLA0KICAiaXNLaW5nUm9ja1V0aWxpdHkiOiB0cnVlLA0KICAiaXNNYWdpY0NvYXRBZmZlY3RlZCI6IGZhbHNlLA0KICAiaXNNZW50YWwiOiBmYWxzZSwNCiAgImlzTWlycm9yTW92ZSI6IHRydWUsDQogICJpc05vblNreUJhdHRsZSI6IGZhbHNlLA0KICAiaXNQb3dkZXIiOiBmYWxzZSwNCiAgImlzUHVsc2UiOiBmYWxzZSwNCiAgImlzUHVuY2giOiBmYWxzZSwNCiAgImlzUmVjaGFyZ2UiOiBmYWxzZSwNCiAgImlzU25hdGNoYWJsZSI6IGZhbHNlLA0KICAiaXNTb3VuZEF0dGFjayI6IGZhbHNlLA0KICAiaXNTbGljaW5nQXR0YWNrIjogZmFsc2UsDQogICJpc1VuZnJlZXplIjogZmFsc2UsDQogICJpc1dpbmQiOiBmYWxzZSwNCiAgImJhdHRsZUVuZ2luZUFpbWVkVGFyZ2V0IjogImFkamFjZW50X3Bva2Vtb24iLA0KICAiYmF0dGxlU3RhZ2VNb2QiOiBbXSwNCiAgIm1vdmVTdGF0dXMiOiBbXSwNCiAgImVmZmVjdENoYW5jZSI6IDAsDQogICJjb25kaXRpb24iOiAiY29vbCIsDQogICJhcHBlYWwiOiA0LA0KICAiamFtIjogMCwNCiAgImNvbWJvTW92ZXMiOiBbXSwNCiAgImVmZmVjdFRhZ3MiOiBbXQ0KfQ==');
  final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==');
  return [
    _source('Data/Studio/pokemon/fixture.json', {
      'klass': 'Specie',
      'id': 15,
      'dbSymbol': 'fixture',
      'forms': [form(0, femaleRate), form(1, 25)],
    }),
    NativePsdkTrainerSourceFile(
        relativePath: 'Data/Studio/moves/cut.json',
        sha256: Sha256Hash(crypto.sha256.convert(cut).toString()),
        bytes: cut),
    for (final side in ['front', 'back'])
      NativePsdkTrainerSourceFile(
          relativePath: 'graphics/pokedex/poke$side/fixture.png',
          sha256: Sha256Hash(crypto.sha256.convert(png).toString()),
          bytes: png),
    _source('Data/Studio/abilities/swarm.json',
        {'klass': 'Ability', 'id': 68, 'dbSymbol': 'swarm'}),
    for (final id in nativeTrainerTypeIds)
      _source('Data/Studio/types/$id.json', {'dbSymbol': id, 'damageTo': []}),
    for (var index = 0; index < _natureRows.length; index++)
      _source('Data/Studio/natures/${_natureRows[index].$1}.json', {
        'klass': 'Nature',
        'id': index,
        'dbSymbol': _natureRows[index].$1,
        'stats': {
          for (final (offset, stat)
              in ['atk', 'dfe', 'spd', 'ats', 'dfs'].indexed)
            stat: _natureRows[index].$2[offset],
        },
      }),
  ];
}

const _natureRows = <(String, List<int>)>[
  ('hardy', [100, 100, 100, 100, 100]),
  ('lonely', [110, 90, 100, 100, 100]),
  ('brave', [110, 100, 90, 100, 100]),
  ('adamant', [110, 100, 100, 90, 100]),
  ('naughty', [110, 100, 100, 100, 90]),
  ('bold', [90, 110, 100, 100, 100]),
  ('docile', [100, 100, 100, 100, 100]),
  ('relaxed', [100, 110, 90, 100, 100]),
  ('impish', [100, 110, 100, 90, 100]),
  ('lax', [100, 110, 100, 100, 90]),
  ('timid', [90, 100, 110, 100, 100]),
  ('hasty', [100, 90, 110, 100, 100]),
  ('serious', [100, 100, 100, 100, 100]),
  ('jolly', [100, 100, 110, 90, 100]),
  ('naive', [100, 100, 110, 100, 90]),
  ('modest', [90, 100, 100, 110, 100]),
  ('mild', [100, 90, 100, 110, 100]),
  ('quiet', [100, 100, 90, 110, 100]),
  ('bashful', [100, 100, 100, 100, 100]),
  ('rash', [100, 100, 100, 110, 90]),
  ('calm', [90, 100, 100, 100, 110]),
  ('gentle', [100, 90, 100, 100, 110]),
  ('sassy', [100, 100, 90, 100, 110]),
  ('careful', [100, 100, 100, 90, 110]),
  ('quirky', [100, 100, 100, 100, 100]),
];
