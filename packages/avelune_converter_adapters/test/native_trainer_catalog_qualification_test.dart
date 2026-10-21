import 'dart:convert';
import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/native_trainer_money_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_media_source_fixture.dart';

final class _Symbol {
  const _Symbol(this.value);
  final String value;
}

final class _EncodedMarshal {
  const _EncodedMarshal(this.bytes);
  final List<int> bytes;
}

_EncodedMarshal _hashWithFields(List<MapEntry<Object, Object?>> fields) =>
    _EncodedMarshal([
      123,
      ..._integer(fields.length),
      for (final field in fields) ...[
        ..._encode(field.key),
        ..._encode(field.value)
      ]
    ]);

_EncodedMarshal _objectWithFields(
        String name, List<MapEntry<String, Object?>> fields) =>
    _EncodedMarshal([
      111,
      ..._encode(_Symbol(name)),
      ..._integer(fields.length),
      for (final field in fields) ...[
        ..._encode(_Symbol(field.key)),
        ..._encode(field.value)
      ]
    ]);

List<int> _integer(int value) => value == 0
    ? [0]
    : value > 0 && value < 123
        ? [value + 5]
        : value < 0 && value > -124
            ? [(value - 5) & 255]
            : [2, value & 255, (value >> 8) & 255];

List<int> _encode(Object? value) {
  if (value is _EncodedMarshal) return value.bytes;
  if (value == null) return [48];
  if (value is int) return [105, ..._integer(value)];
  if (value is String || value is _Symbol) {
    final bytes =
        utf8.encode(value is String ? value : (value as _Symbol).value);
    return [value is String ? 34 : 58, ..._integer(bytes.length), ...bytes];
  }
  if (value is List) {
    return [91, ..._integer(value.length), ...value.expand(_encode)];
  }
  if (value is Map) {
    return [
      123,
      ..._integer(value.length),
      for (final row in value.entries) ...[
        ..._encode(row.key),
        ..._encode(row.value)
      ]
    ];
  }
  final object = value as LiteralFixtureObject;
  return [
    111,
    ..._encode(_Symbol(object.name)),
    ..._integer(object.fields.length),
    for (final row in object.fields.entries) ...[
      ..._encode(_Symbol(row.key)),
      ..._encode(row.value)
    ]
  ];
}

Map<Object, Object?> _member(
        {String symbol = 'RATTATA',
        int level = 16,
        Map<String, Object?> fields = const {}}) =>
    {
      const _Symbol('species'): _Symbol(symbol),
      const _Symbol('level'): level,
      for (final field in fields.entries) _Symbol(field.key): field.value,
    };

typedef _Roster = ({
  String type,
  String name,
  int version,
  List<Map<Object, Object?>> party,
  List<Object> items,
  String loseText
});

_Roster _roster(
        {String type = 'ARBITRARY',
        String name = 'Joey',
        int version = 0,
        List<Map<Object, Object?>>? party,
        List<Object> items = const [],
        String loseText = 'Good game!'}) =>
    (
      type: type,
      name: name,
      version: version,
      party: party ?? [_member()],
      items: items,
      loseText: loseText
    );

Future<({LiteralTileFixture fixture, SourcePbsProject pbs})> _source(
    List<_Roster> rosters,
    {String? pbs,
    List<_Roster>? compiled,
    bool contradictoryProfile = false,
    Map<String, List<int>> extraFiles = const {},
    Object Function(_Roster row, LiteralFixtureObject object)?
        transformCompiledRecord}) async {
  final records = compiled ?? rosters;
  final trainerBytes = [
    4,
    8,
    123,
    ..._integer(records.length),
    for (final row in records) ...[
      ..._encode([_Symbol(row.type), row.name, row.version]),
      ..._encode(((LiteralFixtureObject object) =>
              transformCompiledRecord?.call(row, object) ?? object)(
          LiteralFixtureObject('GameData::Trainer', {
        '@id': [_Symbol(row.type), row.name, row.version],
        '@trainer_type': _Symbol(row.type),
        '@real_name': row.name,
        '@version': row.version,
        '@items': row.items,
        '@real_lose_text': row.loseText,
        '@pokemon': row.party,
        '@pbs_file_suffix': '',
      }))),
    ],
  ];
  final speciesBytes = [
    4,
    8,
    ..._encode({
      const _Symbol('RATTATA'):
          const LiteralFixtureObject('GameData::Species', {
        '@id': _Symbol('RATTATA'),
        '@species': _Symbol('RATTATA'),
        '@form': 0,
        '@real_name': 'Rattata',
      })
    })
  ];
  final fixture = await LiteralTileFixture.create(
      contradictoryProfile: contradictoryProfile,
      extraFiles: {
        'PBS/trainer_types.txt': utf8.encode(rosters
            .map((row) => row.type)
            .toSet()
            .map((type) => '[$type]\nName = Original Trainer\nBaseMoney = 30\n')
            .join()),
        'Data/trainer_types.dat': literalFixtureMarshal({
          for (final type in rosters.map((row) => row.type).toSet())
            LiteralFixtureSymbol(type):
                LiteralFixtureObject('GameData::TrainerType', {
              '@id': LiteralFixtureSymbol(type),
              '@base_money': 30,
            }),
        }),
        'PBS/trainers.txt': utf8.encode(pbs ??
            rosters
                .map((row) =>
                    '[${row.type},${row.name},${row.version}]\nLoseText = ${row.loseText}\n'
                    '${row.party.map((member) => 'Pokemon = ${(member.entries.firstWhere((e) => (e.key as _Symbol).value == 'species').value as _Symbol).value},${member.entries.firstWhere((e) => (e.key as _Symbol).value == 'level').value}\n').join()}')
                .join()),
        'PBS/pokemon.txt': utf8.encode('[RATTATA]\nName = Rattata\n'),
        'Data/trainers.dat': trainerBytes,
        'Data/species.dat': speciesBytes,
        ...extraFiles,
      });
  final parsed = await const SourcePbsParser()
      .read(snapshot: fixture.snapshot, files: fixture.files);
  return (fixture: fixture, pbs: parsed);
}

SourcePbsIdentity _key(ConverterId namespace,
        {String type = 'ARBITRARY', String name = 'Joey', int version = 0}) =>
    SourcePbsIdentity(
        namespace: namespace,
        family: SourcePbsFamily.trainers,
        trainerType: type,
        trainerName: name,
        version: version);

Future<NativeTrainerCatalogQualification> _prepare(
        ({LiteralTileFixture fixture, SourcePbsProject pbs}) input,
        {Iterable<SourcePbsIdentity>? requested,
        ScanCancellation? cancellation,
        NativeTrainerQualificationLimits limits =
            const NativeTrainerQualificationLimits(),
        NativePsdkCatalog? catalog}) =>
    NativeTrainerCatalogQualification.prepare(
        normalizedSource: input.fixture.source,
        source: input.pbs,
        files: input.fixture.files,
        nativeCatalog: catalog ?? NativePsdkTrainerBundle.builtin(),
        cancellation: cancellation,
        requestedTrainers:
            requested ?? [_key(input.pbs.logicalProjectNamespace)],
        limits: limits);

Matcher _error(String code) =>
    throwsA(isA<ContractError>().having((e) => e.code, 'code', code));

const _proofLimits = ContractLimits(
    maxNodes: 2000000, maxStringCodeUnits: 1048576, maxTextCodeUnits: 33554432);

NativeTrainerQualificationArtifacts _forge(
    NativeTrainerCatalogQualification result,
    void Function(Map<String, Object?>) change) {
  final proof =
      (jsonDecode(jsonEncode(result.evidence)) as Map).cast<String, Object?>();
  change(proof);
  final bytes = utf8.encode(canonicalJsonOf(proof, limits: _proofLimits));
  final chunks = <NativeArtifact>[];
  for (var offset = 0; offset < bytes.length; offset += 45000) {
    final end = offset + 45000 < bytes.length ? offset + 45000 : bytes.length;
    chunks.add(NativeArtifact(
        bytes: utf8.encode(canonicalJsonOf({
          'kind': 'nativeTrainerQualificationChunk',
          'version': 1,
          'index': chunks.length,
          'bytes': base64.encode(bytes.sublist(offset, end)),
        })),
        mediaType: 'application/json'));
  }
  return NativeTrainerQualificationArtifacts(chunks, {
    ...result.artifacts().evidence,
    'qualificationHash': canonicalHashOf(proof, limits: _proofLimits).value,
    'byteLength': bytes.length,
    'chunks': [
      for (final chunk in chunks)
        {
          'handle': chunk.handle,
          'sha256': chunk.rawSha256.value,
          'byteLength': chunk.bytes.length
        }
    ],
  });
}

final class _OracleFiles implements SourceFilePort {
  _OracleFiles(this.snapshot, this.roots);
  final SourceSnapshot snapshot;
  final List<String> roots;
  final reads = <String, int>{};
  @override
  Future<List<int>> read(ConverterId id) async {
    final entry = snapshot.entries.singleWhere((entry) => entry.fileId == id);
    reads.update(entry.relativePath, (count) => count + 1, ifAbsent: () => 1);
    for (final root in roots) {
      final file = File('$root/${entry.relativePath}');
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      if (bytes.length != entry.byteLength ||
          literalFixtureHash(bytes) != entry.sha256) {
        throw StateError('Exact source witness differs: ${entry.relativePath}');
      }
      return bytes;
    }
    throw StateError('Source witness unavailable: ${entry.relativePath}');
  }
}

Future<void> _realOracle(String studyPath) async {
  final raw = jsonDecode(
      await File('$studyPath/world_audit/current-source-snapshot.json')
          .readAsString()) as Map;
  final snapshot = SourceSnapshot(
      logicalProjectNamespace:
          ConverterId(raw['logicalProjectNamespace'] as String),
      policyHash: Sha256Hash(raw['policyHash'] as String),
      entries: [
        for (final entry in raw['entries'] as List)
          SourceFileEntry(
              fileId: ConverterId(entry['fileId'] as String),
              relativePath: entry['relativePath'] as String,
              kind: SourceNodeKind.values.byName(entry['kind'] as String),
              byteLength: entry['byteLength'] as int,
              sha256: entry['sha256'] == null
                  ? null
                  : Sha256Hash(entry['sha256'] as String),
              format: entry['format'] as String,
              family: entry['family'] as String)
      ],
      diagnostics: [],
      excludedPaths: (raw['excludedPaths'] as List).cast<String>(),
      profileEvidence: [
        for (final entry in raw['profileEvidence'] as List)
          SourceProfileEvidence(
              relativePath: entry['relativePath'] as String,
              fileHash: Sha256Hash(entry['fileHash'] as String),
              version: entry['version'] as String,
              line: entry['line'] as int,
              excerpt: entry['excerpt'] as String)
      ],
      state: SourceScanState.complete);
  expect(snapshot.canonicalHash.value, raw['canonicalHash']);
  final root =
      (await File('$studyPath/world_audit/source_path.txt').readAsString())
          .trim();
  final files = _OracleFiles(snapshot, [
    root,
    root.replaceFirst(' - Kanto', ' - Johto'),
    root.replaceFirst(' - Kanto', ' - Hoenn')
  ]);
  final audit = jsonDecode(
      await File('$studyPath/real_trainer_versions_audit/current.json')
          .readAsString()) as Map;
  final normalized = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: files,
      selectedMapIds: {
        for (final row in audit['programs'] as List) row['mapId'] as int
      },
      includeEventSystem: true);
  final pbs =
      await const SourcePbsParser().read(snapshot: snapshot, files: files);
  expect(audit['sourceSnapshotHash'], snapshot.canonicalHash.value);
  final requested = [
    for (final row in audit['programs'] as List)
      _key(snapshot.logicalProjectNamespace,
          type: row['trainerType'] as String,
          name: row['trainerName'] as String,
          version: row['trainerVersion'] as int)
  ];
  final catalog = NativePsdkCatalogManifest.builtin();
  files.reads.clear();
  final result = await NativeTrainerCatalogQualification.prepare(
      normalizedSource: normalized,
      source: pbs,
      files: files,
      nativeCatalog: catalog,
      requestedTrainers: requested);
  expect(files.reads['Data/trainers.dat'], 1);
  expect(files.reads['Data/species.dat'], 1);
  final analysis = SourceEventAnalyzer.forProject(normalized,
      profile: SourceEventProfile.forProject(
        normalized,
        interpretationProfile: fixtureSourceInterpretationProfile,
      )).analyze();
  final eventBindings = await const SourceTrainerEventBindingResolver()
      .read(source: normalized, analysis: analysis, files: files);
  expect(eventBindings.byEventIdentity, hasLength(197),
      reason: eventBindings.refusals.toString());
  expect(eventBindings.refusals, hasLength(1));
  expect(eventBindings.refusals.values.single, 'native_trainer.pbs_missing');
  expect(result.trainers, hasLength(189));
  expect(result.refusals, hasLength(1));
  expect(result.refusals.single.identity.trainerName, 'ARTHUR');
  expect(result.refusals.single.code, 'native_trainer.pbs_missing');

  expect(result.trainers.fold<int>(0, (count, row) => count + row.team.length),
      451);
  final limits =
      sourceCatalogStudyWriteLimitsFor(383, includeNativeCatalog: true);
  final portable = result.artifacts(limits: limits);
  final restored = await NativeTrainerCatalogQualification.fromArtifacts(
      evidence: portable.evidence,
      artifacts: portable.artifacts,
      normalizedSource: normalized,
      files: files,
      nativeCatalog: catalog,
      writeLimits: limits);
  expect(restored.evidenceHash, result.evidenceHash);
  final grunt = _key(snapshot.logicalProjectNamespace,
      type: 'FRLG_ROCKETGRUNT_M', name: 'Grunt', version: 40);
  final gruntRows =
      pbs.entries.where((entry) => entry.identity?.key == grunt.key).toList();
  expect(gruntRows, hasLength(2));
  expect(
      gruntRows.map((entry) => entry.headerLocator.line).toSet(), {2431, 3209});
  expect(
      pbs.diagnostics
          .where((row) => row.identityKey == grunt.key && row.blocking),
      isNotEmpty);
  final chosen = <String>{grunt.key};
  SourcePbsEntry select(bool Function(SourcePbsEntry) predicate) {
    final entry = pbs.entries.firstWhere((entry) =>
        entry.family == SourcePbsFamily.trainers &&
        entry.identity != null &&
        !chosen.contains(entry.identity!.key) &&
        predicate(entry));
    chosen.add(entry.identity!.key);
    return entry;
  }

  final heldItem = select(
      (entry) => entry.party.any((member) => member.field('Item') != null));
  final negativeRequests = [grunt, heldItem.identity!];
  final negative = await NativeTrainerCatalogQualification.prepare(
      normalizedSource: normalized,
      source: pbs,
      files: files,
      nativeCatalog: catalog,
      requestedTrainers: [requested.first, ...negativeRequests]);
  expect(negative.trainers, hasLength(1));
  expect(negative.refusals, hasLength(2));
  expect(negative.refusals[0].code, 'native_trainer.pbs_ambiguous');
  expect(negative.refusals[1].code, 'native_trainer.party_override');
  print(jsonEncode({
    'kind': 'nativeTrainerRealDataQualification',
    'requested': requested.length,
    'uniqueRequested': requested.map((row) => row.key).toSet().length,
    'qualified': result.trainers.length,
    'refusals': result.refusals.map((row) => row.toJson()).toList(),
    'members':
        result.trainers.fold<int>(0, (count, row) => count + row.team.length),
    'qualificationHash': result.evidenceHash.value,
    'restoredQualificationHash': restored.evidenceHash.value,
    'evidenceBytes': utf8
        .encode(canonicalJsonOf(result.evidence, limits: _proofLimits))
        .length,
    'artifacts': portable.artifacts.length,
    'artifactBytes': portable.artifacts
        .fold<int>(0, (count, row) => count + row.bytes.length),
    'negativeRealRequests':
        negative.refusals.map((row) => row.toJson()).toList(),
    'duplicateGrunt40HeaderLines':
        gruntRows.map((entry) => entry.headerLocator.line).toList(),
    'sourceSnapshotHash': snapshot.canonicalHash.value,
    'normalizationHash': normalized.canonicalHash.value,
    'sourcePbsHash': pbs.canonicalHash.value,
    'nativeCatalogHash': result.evidence['nativeCatalogHash'],
    'sourceScriptsExecuted': 0,
    'aiCalls': 0,
    'runtimeBattleBuilderQualified': false,
    'eventActivationQualified': false
  }));
}

void main() {
  test('compiled prize witness cannot be borrowed from another source snapshot',
      () async {
    final first = await _source([_roster()]);
    final second = await _source([
      _roster()
    ], extraFiles: {
      'Graphics/Pictures/unrelated.bin': [1, 2, 3],
    });
    expect(first.fixture.snapshot.canonicalHash,
        isNot(second.fixture.snapshot.canonicalHash));
    final witness = await NativeTrainerMoneyWitness.read(
        snapshot: first.fixture.snapshot, files: first.fixture.files);
    final team = (await _prepare(second)).trainers.single.team;
    final roster = second.pbs.entries
        .singleWhere((entry) => entry.family == SourcePbsFamily.trainers);
    expect(
        () => NativeTrainerMoneyBinding.fromPbs(
            source: second.pbs,
            roster: roster,
            team: team,
            compiledWitness: witness),
        _error('native_trainer.money_witness_context'));
  });
  test('qualified prize money agrees with PBS and compiled trainer type',
      () async {
    final input = await _source([
      _roster(party: [_member(level: 25), _member(level: 5)]),
    ]);
    final result = await _prepare(input);
    expect(result.refusals, isEmpty);
    expect(result.trainers.single.moneyReward, 750);
    final proof = result.rows.single['prizeMoney'] as Map;
    expect(proof['compiledTrainerTypeAttested'], isTrue);
    expect(proof['highestTeamLevel'], 25);
  });

  for (final defect in ['amount', 'identity', 'duplicate']) {
    test('contradictory compiled prize $defect refuses its trainer', () async {
      final symbol = LiteralFixtureSymbol('ARBITRARY');
      final object = LiteralFixtureObject('GameData::TrainerType', {
        '@id':
            LiteralFixtureSymbol(defect == 'identity' ? 'OTHER' : 'ARBITRARY'),
        '@base_money': defect == 'amount' ? 99 : 30,
      });
      final bytes = defect == 'duplicate'
          ? [
              4,
              8,
              ..._hashWithFields([
                MapEntry(
                    const _Symbol('ARBITRARY'),
                    LiteralFixtureObject('GameData::TrainerType', {
                      '@id': const _Symbol('ARBITRARY'),
                      '@base_money': 30,
                    })),
                MapEntry(
                    const _Symbol('ARBITRARY'),
                    LiteralFixtureObject('GameData::TrainerType', {
                      '@id': const _Symbol('ARBITRARY'),
                      '@base_money': 30,
                    })),
              ]).bytes
            ]
          : literalFixtureMarshal({symbol: object});
      final input = await _source([
        _roster()
      ], extraFiles: {
        'Data/trainer_types.dat': bytes,
      });
      final result = await _prepare(input);
      expect(result.trainers, isEmpty);
      expect(result.refusals.single.code,
          'native_trainer.money_compiled_mismatch');
    });
  }

  test('a forged portable prize cannot survive source requalification',
      () async {
    final input = await _source([_roster()]);
    final result = await _prepare(input);
    final forged = _forge(result, (proof) {
      final row = (proof['trainers'] as List).single as Map;
      (row['nativeTrainer'] as Map)['moneyReward'] = 999999;
    });
    await expectLater(
      NativeTrainerCatalogQualification.fromArtifacts(
        artifacts: forged.artifacts,
        evidence: forged.evidence,
        normalizedSource: input.fixture.source,
        files: input.fixture.files,
        nativeCatalog: NativePsdkTrainerBundle.builtin(),
      ),
      _error('native_trainer.portable_requalification'),
    );
  });
  final authoredFiles = <String, List<int>>{
    'PBS/moves.txt': utf8.encode(
        '[TACKLE]\nName = Tackle\nType = NORMAL\nCategory = Physical\nPower = 40\nAccuracy = 100\nTotalPP = 35\nTarget = NearOther\nFunctionCode = None\n'
        '[QUICKATTACK]\nName = Quick Attack\nType = NORMAL\nCategory = Physical\nPower = 40\nAccuracy = 100\nTotalPP = 30\nPriority = 1\nTarget = NearOther\nFunctionCode = None\n'),
    'Data/moves.dat': literalFixtureMarshal({
      for (final value in [
        (symbol: 'TACKLE', name: 'Tackle', pp: 35, priority: 0),
        (symbol: 'QUICKATTACK', name: 'Quick Attack', pp: 30, priority: 1)
      ])
        LiteralFixtureSymbol(value.symbol):
            LiteralFixtureObject('GameData::Move', {
          '@id': LiteralFixtureSymbol(value.symbol),
          '@real_name': value.name,
          '@type': const LiteralFixtureSymbol('NORMAL'),
          '@category': 0,
          '@power': 40,
          '@accuracy': 100,
          '@total_pp': value.pp,
          '@target': const LiteralFixtureSymbol('NearOther'),
          '@priority': value.priority,
          '@function_code': 'None',
          '@flags': <String>[],
          '@effect_chance': 0,
          '@real_description': '',
          '@pbs_file_suffix': '',
        }),
    }),
    'PBS/items.txt': utf8.encode(
        '[FULLHEAL]\nName = Full Heal\nNamePlural = Full Heals\nPocket = 2\nPrice = 400\nSellPrice = 100\nFieldUse = OnPokemon\nBattleUse = OnPokemon\nFlags = Fling_30\n'),
    'Data/items.dat': literalFixtureMarshal({
      const LiteralFixtureSymbol('FULLHEAL'):
          const LiteralFixtureObject('GameData::Item', {
        '@id': LiteralFixtureSymbol('FULLHEAL'),
        '@real_name': 'Full Heal',
        '@real_name_plural': 'Full Heals',
        '@pocket': 2,
        '@price': 400,
        '@sell_price': 100,
        '@bp_price': 1,
        '@field_use': 1,
        '@battle_use': 1,
        '@flags': ['Fling_30'],
        '@consumable': true,
        '@move': null,
        '@real_description': '',
        '@pbs_file_suffix': '',
      }),
    }),
  };
  test(
      'authored moves keep their exact PBS compiled order and native identities',
      () async {
    final source = await _source([
      _roster(party: [
        _member(fields: {
          'moves': [const _Symbol('QUICKATTACK'), const _Symbol('TACKLE')],
        })
      ])
    ],
        pbs:
            '[ARBITRARY,Joey,0]\nLoseText = Good game!\nPokemon = RATTATA,16\nMoves = QUICKATTACK,TACKLE\n',
        extraFiles: authoredFiles);
    final result = await _prepare(source);
    expect(result.refusals.map((value) => value.toJson()), isEmpty);
    expect(
        result.trainers.single.team.single.moves, ['quick_attack', 'tackle']);
  });
  test('authored trainer medicines retain repeated source quantities',
      () async {
    final source = await _source(
        [_roster(items: List.filled(5, const _Symbol('FULLHEAL')))],
        pbs:
            '[ARBITRARY,Joey,0]\nLoseText = Good game!\nItems = FULLHEAL,FULLHEAL,FULLHEAL,FULLHEAL,FULLHEAL\nPokemon = RATTATA,16\n',
        extraFiles: authoredFiles);
    final result = await _prepare(source);
    expect(result.refusals, isEmpty);
    expect(result.trainers.single.battleItems, {'full-heal': 5});
    expect(result.battleItemDefinitions.single.id, 'full-heal');
  });
  Future<
      ({LiteralTileFixture fixture, SourcePbsProject pbs})> authoredMoveSource({
    String moves = 'QUICKATTACK,TACKLE',
    List<String> compiledMoves = const ['QUICKATTACK', 'TACKLE'],
    Map<String, List<int>> overrides = const {},
  }) =>
      _source(
          [
            _roster(party: [
              _member(fields: {
                'moves': compiledMoves.map(_Symbol.new).toList(),
              })
            ])
          ],
          pbs:
              '[ARBITRARY,Joey,0]\nLoseText = Good game!\nPokemon = RATTATA,16\nMoves = $moves\n',
          extraFiles: {...authoredFiles, ...overrides});
  test('authored move order must agree with the compiled trainer roster',
      () async {
    final result = await _prepare(
        await authoredMoveSource(compiledMoves: ['TACKLE', 'QUICKATTACK']));
    expect(result.trainers, isEmpty);
    expect(result.refusals.single.code, 'native_trainer.roster_changed');
  });
  test('unknown authored move identities never fall back to native defaults',
      () async {
    final result = await _prepare(await authoredMoveSource(
        moves: 'CUSTOMMOVE', compiledMoves: ['CUSTOMMOVE']));
    expect(result.trainers, isEmpty);
    expect(result.refusals.single.code, 'native_trainer.authored_pbs_identity');
  });
  test('authored moves require the exact compiled move witness', () async {
    final result = await _prepare(await authoredMoveSource(
        overrides: {'Data/moves.dat': literalFixtureMarshal({})}));
    expect(result.trainers, isEmpty);
    expect(result.refusals.single.code,
        'native_trainer.authored_compiled_identity');
  });
  test('custom source move functions are refused before native binding',
      () async {
    final altered = utf8
        .decode(authoredFiles['PBS/moves.txt']!)
        .replaceAll('FunctionCode = None', 'FunctionCode = CustomRuby');
    final result = await _prepare(await authoredMoveSource(
        overrides: {'PBS/moves.txt': utf8.encode(altered)}));
    expect(result.trainers, isEmpty);
    expect(
        result.refusals.single.code, 'native_trainer.authored_catalog_changed');
  });
  test('source move names cannot impersonate the declared native move',
      () async {
    final altered = utf8
        .decode(authoredFiles['PBS/moves.txt']!)
        .replaceAll('Name = Quick Attack', 'Name = Custom Move');
    final result = await _prepare(await authoredMoveSource(
        overrides: {'PBS/moves.txt': utf8.encode(altered)}));
    expect(result.trainers, isEmpty);
    expect(
        result.refusals.single.code, 'native_trainer.authored_catalog_changed');
  });
  test(
      'matching PBS and compiled custom functions do not redefine standard moves',
      () async {
    final altered = utf8
        .decode(authoredFiles['PBS/moves.txt']!)
        .replaceAll('FunctionCode = None', 'FunctionCode = CustomRuby');
    final result = await _prepare(
        await authoredMoveSource(moves: 'TACKLE', compiledMoves: [
      'TACKLE'
    ], overrides: {
      'PBS/moves.txt': utf8.encode(altered),
      'Data/moves.dat': literalFixtureMarshal({
        const LiteralFixtureSymbol('TACKLE'):
            const LiteralFixtureObject('GameData::Move', {
          '@id': LiteralFixtureSymbol('TACKLE'),
          '@real_name': 'Tackle',
          '@type': LiteralFixtureSymbol('NORMAL'),
          '@category': 0,
          '@power': 40,
          '@accuracy': 100,
          '@total_pp': 35,
          '@target': LiteralFixtureSymbol('NearOther'),
          '@priority': 0,
          '@function_code': 'CustomRuby',
          '@flags': [],
          '@effect_chance': 0,
        }),
      }),
    }));
    expect(result.trainers, isEmpty);
    expect(
        result.refusals.single.code, 'native_trainer.authored_catalog_changed');
  });
  test(
      'authored fixed damage keeps Avelune metadata with declared source differences',
      () async {
    final result = await _prepare(
        await authoredMoveSource(moves: 'SONICBOOM', compiledMoves: [
          'SONICBOOM'
        ], overrides: {
          'PBS/moves.txt': utf8.encode(
              '[SONICBOOM]\nName = Sonic Boom\nType = NORMAL\nCategory = Special\nPower = 1\nAccuracy = 90\nTotalPP = 20\nTarget = NearOther\nFunctionCode = FixedDamage20\n'),
          'Data/moves.dat': literalFixtureMarshal({
            const LiteralFixtureSymbol('SONICBOOM'):
                const LiteralFixtureObject('GameData::Move', {
              '@id': LiteralFixtureSymbol('SONICBOOM'),
              '@real_name': 'Sonic Boom',
              '@type': LiteralFixtureSymbol('NORMAL'),
              '@category': 1,
              '@power': 1,
              '@accuracy': 90,
              '@total_pp': 20,
              '@target': LiteralFixtureSymbol('NearOther'),
              '@priority': 0,
              '@function_code': 'FixedDamage20',
              '@flags': [],
              '@effect_chance': 0,
            }),
          }),
        }),
        catalog: NativePsdkCatalogManifest.builtin());
    expect(result.refusals.map((refusal) => refusal.toJson()), isEmpty);
    expect(result.trainers.single.team.single.moves, ['sonic_boom']);
    final evidence =
        ((result.evidence['authoredBindings'] as Map)['bindings'] as List)
            .single as Map;
    expect(evidence['sourceCategory'], 'Special');
    expect(evidence['nativeCategory'], 'physical');
    expect(evidence['nativeEngineMethod'], 's_fixed_damage');
  });
  test('trainer medicine quantities must agree with the compiled roster',
      () async {
    final source = await _source([
      _roster(items: [const _Symbol('FULLHEAL')])
    ],
        pbs:
            '[ARBITRARY,Joey,0]\nLoseText = Good game!\nItems = FULLHEAL,FULLHEAL\nPokemon = RATTATA,16\n',
        extraFiles: authoredFiles);
    final result = await _prepare(source);
    expect(result.trainers, isEmpty);
    expect(result.refusals.single.code, 'native_trainer.roster_changed');
  });
  test('trainer medicine use overrides remain refused', () async {
    final source = await _source(
        [
          _roster(items: [const _Symbol('FULLHEAL')])
        ],
        pbs:
            '[ARBITRARY,Joey,0]\nLoseText = Good game!\nItems = FULLHEAL\nPokemon = RATTATA,16\n',
        extraFiles: {
          ...authoredFiles,
          'PBS/items.txt': utf8.encode(utf8
              .decode(authoredFiles['PBS/items.txt']!)
              .replaceAll('BattleUse = OnPokemon', 'BattleUse = OnFoe'))
        });
    final result = await _prepare(source);
    expect(result.trainers, isEmpty);
    expect(result.refusals.single.code, startsWith('native_trainer.authored_'));
  });
  test(
      'sealed authored qualification binds without a historical roster whitelist',
      () async {
    final source = await authoredMoveSource();
    final native = NativePsdkTrainerBundle.builtin();
    final qualification = await _prepare(source, catalog: native);
    final result = const NativeTrainerCatalogBindings().bind(
        source: source.pbs,
        requestedTrainers: [_key(source.pbs.logicalProjectNamespace)],
        native: native,
        movePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults,
        qualification: qualification);
    expect(
        result.trainers.single.team.single.moves, ['quick_attack', 'tackle']);
    expect(
        result.evidence['qualificationHash'], qualification.evidenceHash.value);
    final other =
        await authoredMoveSource(moves: 'TACKLE', compiledMoves: ['TACKLE']);
    expect(
        () => const NativeTrainerCatalogBindings().bind(
            source: other.pbs,
            requestedTrainers: [_key(other.pbs.logicalProjectNamespace)],
            native: native,
            movePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults,
            qualification: qualification),
        _error('native_trainer.qualification_context'));
  });
  test(
      'published native bundle retains the exact qualified authored move order',
      () async {
    final native = NativePsdkTrainerBundle.builtin();
    final source =
        await authoredMoveSource(overrides: nativeMediaSourceFiles(native));
    final qualification = await _prepare(source, catalog: native);
    expect(qualification.refusals, isEmpty);
    final published = await const SourceCatalogProjector().read(
        source: source.fixture.source,
        pbs: source.pbs,
        files: source.fixture.files,
        nativeMapIds: {1: 'native_map'},
        requestedTrainerKeys: [_key(source.pbs.logicalProjectNamespace)],
        nativeTrainerQualification: qualification,
        nativeTrainerBundle: native,
        nativeTrainerMovePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults);
    expect(published.trainers.single.team.single.moves,
        ['quick_attack', 'tackle']);
    final moves = published.documents
        .singleWhere((document) =>
            document.relativePath == 'data/pokemon/catalogs/moves.json')
        .document;
    expect((moves['entries'] as List).map((entry) => (entry as Map)['id']),
        containsAll(['quick_attack', 'tackle']));
    expect(published.artifacts, isNotEmpty);
  });
  test('published authored trainers require their exact compiled qualification',
      () async {
    final native = NativePsdkTrainerBundle.builtin();
    final source =
        await authoredMoveSource(overrides: nativeMediaSourceFiles(native));
    await expectLater(
        const SourceCatalogProjector().read(
            source: source.fixture.source,
            pbs: source.pbs,
            files: source.fixture.files,
            nativeMapIds: {1: 'native_map'},
            requestedTrainerKeys: [_key(source.pbs.logicalProjectNamespace)],
            nativeTrainerKeys: [_key(source.pbs.logicalProjectNamespace)],
            nativeTrainerBundle: native,
            nativeTrainerMovePolicy:
                NativeTrainerMovePolicy.nativeAveluneDefaults),
        _error('native_trainer.projection_binding'));
  });
  test('published authored trainers reject source changes after qualification',
      () async {
    final native = NativePsdkTrainerBundle.builtin();
    final source =
        await authoredMoveSource(overrides: nativeMediaSourceFiles(native));
    final qualification = await _prepare(source, catalog: native);
    source.fixture.files.overrides['Data/trainers.dat'] =
        literalFixtureMarshal({});
    await expectLater(
        const SourceCatalogProjector().read(
            source: source.fixture.source,
            pbs: source.pbs,
            files: source.fixture.files,
            nativeMapIds: {1: 'native_map'},
            requestedTrainerKeys: [_key(source.pbs.logicalProjectNamespace)],
            nativeTrainerQualification: qualification,
            nativeTrainerBundle: native,
            nativeTrainerMovePolicy:
                NativeTrainerMovePolicy.nativeAveluneDefaults),
        _error('native_trainer.source_changed'));
  });
  test('authored witnesses and medicine definitions survive proof roundtrip',
      () async {
    final source = await authoredMoveSource();
    final native = NativePsdkTrainerBundle.builtin();
    final qualification = await _prepare(source, catalog: native);
    final artifacts = qualification.artifacts();
    final restored = await NativeTrainerCatalogQualification.fromArtifacts(
        evidence: artifacts.evidence,
        artifacts: artifacts.artifacts,
        normalizedSource: source.fixture.source,
        files: source.fixture.files,
        nativeCatalog: native);
    expect(restored.evidenceHash, qualification.evidenceHash);
    expect(
        restored.trainers.single.team.single.moves, ['quick_attack', 'tackle']);
    final witness = source.fixture.snapshot.entries
        .singleWhere((file) => file.relativePath == 'Data/moves.dat');
    source.fixture.files.overrides[witness.relativePath] = [0];
    await expectLater(
        restored.validateContext(
            normalizedSource: source.fixture.source,
            source: source.pbs,
            files: source.fixture.files,
            nativeCatalog: native,
            requestedTrainers: [_key(source.pbs.logicalProjectNamespace)]),
        _error('native_trainer.source_changed'));
  });
  final study = Platform.environment['AVELUNE_NATIVE_TRAINER_STUDY'];
  test(
      'real oracle qualifies 189 exact identities and refuses absent ARTHUR locally',
      () async => _realOracle(study!),
      skip: study == null ? 'Requires existing inert source study.' : false,
      timeout: const Timeout(Duration(minutes: 3)));
  test('qualifies an arbitrary trainer outside the historical roster whitelist',
      () async {
    final source = await _source([_roster()]);
    final result = await _prepare(source);
    expect(result.refusals, isEmpty);
    expect(result.trainers.single.name, 'Joey');
    expect(result.trainers.single.team.single.speciesId, 'rattata');
    expect(result.trainers.single.team.single.level, 16);
    expect(result.trainers.single.team.single.moves, isNotEmpty);
    final native = NativePsdkTrainerBundle.builtin();
    expect(
        result.trainers.single.team.single.moves,
        nativeTrainerDefaultMoveIds(
            native.learnsetsBySpeciesId['rattata']!, 16));
    expect(result.evidence['movePolicy'],
        'nativeAveluneDefaultsOnlyWithoutAuthoredMoves');
    expect(result.evidence['runtimeBattleBuilderQualified'], false);
  });

  test('ambiguous version observations do not fabricate a source confirmation',
      () async {
    final source = await _source([_roster()], contradictoryProfile: true);
    expect(source.fixture.snapshot.profile.state,
        SourceProfileState.requiresConfirmation);
    final result = await _prepare(source);
    expect(result.trainers, hasLength(1));
    expect(result.evidence['sourceProfileState'], 'requiresConfirmation');
    expect(result.evidence['observedSourceVersions'], ['21.1', '22']);
    expect(result.evidence['sourceVersionConfirmed'], false);
    expect(result.evidence['sourceProfileId'],
        source.fixture.source.sourceProfileId.value);
  });

  test(
      'partial PBS with the same sealed snapshot is refused before qualification',
      () async {
    final source = await _source([
      _roster()
    ], extraFiles: {
      'PBS/items.txt': utf8.encode('[POTION]\nName = Potion\n')
    });
    final partial = await const SourcePbsParser().read(
        snapshot: source.fixture.snapshot,
        files: source.fixture.files,
        families: {
          SourcePbsFamily.species,
          SourcePbsFamily.forms,
          SourcePbsFamily.trainers
        });
    expect(partial.sourceSnapshotHash, source.pbs.sourceSnapshotHash);
    expect(partial.logicalProjectNamespace, source.pbs.logicalProjectNamespace);
    expect(partial.canonicalHash, isNot(source.pbs.canonicalHash));
    await expectLater(_prepare((fixture: source.fixture, pbs: partial)),
        _error('native_trainer.pbs_context'));
  });

  test(
      'complete PBS including items qualifies and restores the exact full context',
      () async {
    final source = await _source([
      _roster()
    ], extraFiles: {
      'PBS/items.txt': utf8.encode('[POTION]\nName = Potion\n')
    });
    source.fixture.files.reads.clear();
    final result = await _prepare(source);
    expect(result.trainers, hasLength(1));
    expect(result.evidence['sourcePbsHash'], source.pbs.canonicalHash.value);
    for (final path in [
      'PBS/trainers.txt',
      'PBS/pokemon.txt',
      'PBS/items.txt',
      'Data/trainers.dat',
      'Data/species.dat'
    ]) {
      final id = source.fixture.snapshot.entries
          .singleWhere((row) => row.relativePath == path)
          .fileId;
      expect(
          source.fixture.files.reads.where((read) => read == id), hasLength(1),
          reason: path);
    }
    final packed = result.artifacts();
    final restored = await NativeTrainerCatalogQualification.fromArtifacts(
        evidence: packed.evidence,
        artifacts: packed.artifacts,
        normalizedSource: source.fixture.source,
        files: source.fixture.files,
        nativeCatalog: NativePsdkTrainerBundle.builtin());
    expect(restored.evidenceHash, result.evidenceHash);
  });

  test(
      'a provided PBS cannot conceal changed files behind its old snapshot hash',
      () async {
    final source = await _source([
      _roster()
    ], extraFiles: {
      'PBS/items.txt': utf8.encode('[POTION]\nName = Potion\n')
    });
    source.fixture.files.overrides['PBS/items.txt'] =
        utf8.encode('[POTION]\nName = Forged\n');
    await expectLater(_prepare(source), _error('pbs.source_changed'));
  });

  test('keeps exact versions, deduplicates requests and supports more than 64',
      () async {
    final rosters = [for (var i = 0; i < 80; i++) _roster(version: i)];
    final source = await _source(rosters);
    final keys = [
      for (var i = 79; i >= 0; i--)
        _key(source.pbs.logicalProjectNamespace, version: i)
    ];
    final result = await _prepare(source, requested: [...keys, keys.first]);
    expect(result.trainers, hasLength(80));
    expect(result.rows.first['sourceIdentity'], keys.first.toJson());
    expect(result.rows.last['sourceIdentity'], keys.last.toJson());
    expect(result.trainers.map((row) => row.id).toSet(), hasLength(80));
  });

  test('an absent exact ARTHUR identity refuses only that request', () async {
    final source = await _source([_roster()]);
    final result = await _prepare(source, requested: [
      _key(source.pbs.logicalProjectNamespace, name: 'ARTHUR'),
      _key(source.pbs.logicalProjectNamespace)
    ]);
    expect(result.trainers, hasLength(1));
    expect(result.refusals.single.code, 'native_trainer.pbs_missing');
  });

  test('a shared qualification rejects missing or additional selected roots',
      () async {
    final source = await _source([_roster(), _roster(name: 'Other')]);
    final first = _key(source.pbs.logicalProjectNamespace);
    final second = _key(source.pbs.logicalProjectNamespace, name: 'Other');
    final subset = await _prepare(source, requested: [first]);
    final complete = await _prepare(source, requested: [first, second]);
    final catalog = NativePsdkTrainerBundle.builtin();
    for (final request in [
      (subset, [first, second]),
      (complete, [first])
    ]) {
      await expectLater(
          request.$1.validateContext(
              normalizedSource: source.fixture.source,
              source: source.pbs,
              files: source.fixture.files,
              nativeCatalog: catalog,
              requestedTrainers: request.$2),
          _error('native_trainer.context_binding'));
    }
    await complete.validateContext(
        normalizedSource: source.fixture.source,
        source: source.pbs,
        files: source.fixture.files,
        nativeCatalog: catalog,
        requestedTrainers: [second, first, first]);
  });

  test('shared qualification rejects catalog and source bytes changing',
      () async {
    final source = await _source([_roster()]);
    final qualification = await _prepare(source);
    final keys = [_key(source.pbs.logicalProjectNamespace)];
    await expectLater(
        qualification.validateContext(
            normalizedSource: source.fixture.source,
            source: source.pbs,
            files: source.fixture.files,
            nativeCatalog: NativePsdkCatalogManifest.builtin(),
            requestedTrainers: keys),
        _error('native_trainer.context_binding'));
    source.fixture.files.overrides['PBS/trainers.txt'] = [
      ...source.fixture.files.bytes['PBS/trainers.txt']!,
      10,
    ];
    await expectLater(
        qualification.validateContext(
            normalizedSource: source.fixture.source,
            source: source.pbs,
            files: source.fixture.files,
            nativeCatalog: NativePsdkTrainerBundle.builtin(),
            requestedTrainers: keys),
        _error('native_trainer.source_changed'));
  });

  test('shared context rejects a native catalog changing during source reads',
      () async {
    final source = await _source([_roster()]);
    final catalog = NativePsdkTrainerBundle.builtin();
    final qualification = await _prepare(source, catalog: catalog);
    source.fixture.files.onRead = (_) {
      catalog.speciesById['rattata']!.names['en'] =
          'Altered during source read';
    };
    await expectLater(
        qualification.validateContext(
            normalizedSource: source.fixture.source,
            source: source.pbs,
            files: source.fixture.files,
            nativeCatalog: catalog,
            requestedTrainers: [_key(source.pbs.logicalProjectNamespace)]),
        _error('native_trainer.catalog_changed'));
  });

  test('a duplicated Grunt40 PBS identity is a local refusal', () async {
    final source = await _source([
      _roster(),
      _roster(name: 'Grunt', version: 40),
      _roster(name: 'Grunt', version: 40)
    ], compiled: [
      _roster(),
      _roster(name: 'Grunt', version: 40)
    ]);
    final result = await _prepare(source, requested: [
      _key(source.pbs.logicalProjectNamespace),
      _key(source.pbs.logicalProjectNamespace, name: 'Grunt', version: 40)
    ]);
    expect(result.trainers, hasLength(1));
    expect(result.refusals.single.code, 'native_trainer.pbs_ambiguous');
  });

  test('PBS and compiled species, level and party order must agree', () async {
    final source = await _source([
      _roster()
    ], compiled: [
      _roster(party: [_member(level: 17)])
    ]);
    final result = await _prepare(source);
    expect(result.trainers, isEmpty);
    expect(result.refusals.single.code, 'native_trainer.roster_changed');
  });

  test('levels outside 1 through 100 are refused', () async {
    final source = await _source([
      _roster(party: [_member(level: 101)])
    ]);
    expect((await _prepare(source)).refusals.single.code,
        'native_trainer.member_invalid');
  });

  for (final override in {
    'Moves': 'TACKLE',
    'Item': 'ORANBERRY',
    'Form': '1',
    'Gender': 'Male',
    'Ability': 'GUTS',
    'AbilityIndex': '1',
    'Nature': 'HARDY',
    'IV': '31',
    'EV': '4',
    'Happiness': '255',
    'Name': 'Custom',
    'Shiny': 'true',
    'SuperShiny': 'true',
    'Shadow': 'true',
    'Ball': 'POKEBALL'
  }.entries) {
    test('authored ${override.key} refuses rather than using native defaults',
        () async {
      final source = await _source([_roster()],
          pbs:
              '[ARBITRARY,Joey]\nPokemon = RATTATA,16\n${override.key} = ${override.value}\n');
      final result = await _prepare(source);
      expect(result.trainers, isEmpty);
      expect(
          result.refusals.single.code,
          override.key == 'Moves'
              ? 'native_trainer.roster_changed'
              : 'native_trainer.party_override');
    });
  }

  test('compiled-only overrides refuse even when PBS does not author them',
      () async {
    final source = await _source([
      _roster()
    ], compiled: [
      _roster(party: [
        _member(fields: {
          'moves': [const _Symbol('TACKLE')]
        })
      ])
    ]);
    expect((await _prepare(source)).refusals.single.code,
        'native_trainer.roster_changed');
  });

  test('compiled identities remain exact and duplicate records refuse locally',
      () async {
    final source = await _source([
      _roster(),
      _roster(name: 'Duplicate')
    ], compiled: [
      _roster(),
      _roster(name: 'Duplicate'),
      _roster(name: 'Duplicate')
    ]);
    final result = await _prepare(source, requested: [
      _key(source.pbs.logicalProjectNamespace),
      _key(source.pbs.logicalProjectNamespace, name: 'Duplicate'),
      _key(source.pbs.logicalProjectNamespace, type: 'arbitrary')
    ]);
    expect(result.trainers, hasLength(1));
    expect(result.refusals.map((row) => row.code),
        ['native_trainer.compiled_ambiguous', 'native_trainer.pbs_missing']);
  });

  for (final malformed in <String, Object?>{
    'string': 'Broken',
    'null': null,
    'array': [const _Symbol('ARBITRARY'), 'Broken']
  }.entries) {
    test(
        'malformed internal ${malformed.key} identity stays local to its external key',
        () async {
      final source = await _source([_roster(), _roster(name: 'Broken')],
          transformCompiledRecord: (row, object) => row.name == 'Broken'
              ? LiteralFixtureObject(
                  object.name, {...object.fields, '@id': malformed.value})
              : object);
      final alone = await _prepare(source);
      expect(alone.trainers.single.name, 'Joey');
      expect(alone.refusals, isEmpty);
      final together = await _prepare(source, requested: [
        _key(source.pbs.logicalProjectNamespace),
        _key(source.pbs.logicalProjectNamespace, name: 'Broken')
      ]);
      expect(together.trainers.single.name, 'Joey');
      expect(together.refusals.single.identity.trainerName, 'Broken');
      expect(together.refusals.single.code, 'native_trainer.compiled_identity');
      expect(together.refusals.single.message, contains('Data/trainers.dat:'));
      final packed = together.artifacts();
      final restored = await NativeTrainerCatalogQualification.fromArtifacts(
          evidence: packed.evidence,
          artifacts: packed.artifacts,
          normalizedSource: source.fixture.source,
          files: source.fixture.files,
          nativeCatalog: NativePsdkTrainerBundle.builtin());
      expect(restored.evidenceHash, together.evidenceHash);
    });
  }

  for (final duplicate in ['record', 'member']) {
    test('duplicated $duplicate properties stay an exact local refusal',
        () async {
      final source = await _source([_roster(), _roster(name: 'Broken')],
          transformCompiledRecord: (row, object) {
        if (row.name != 'Broken') return object;
        if (duplicate == 'record') {
          return _objectWithFields(object.name,
              [...object.fields.entries, const MapEntry('@version', 0)]);
        }
        final party = _hashWithFields([
          const MapEntry(_Symbol('species'), _Symbol('RATTATA')),
          const MapEntry(_Symbol('level'), 16),
          const MapEntry(_Symbol('level'), 17)
        ]);
        return LiteralFixtureObject(object.name, {
          ...object.fields,
          '@pokemon': [party]
        });
      });
      final alone = await _prepare(source);
      expect(alone.trainers.single.name, 'Joey');
      expect(alone.refusals, isEmpty);
      final together = await _prepare(source, requested: [
        _key(source.pbs.logicalProjectNamespace),
        _key(source.pbs.logicalProjectNamespace, name: 'Broken')
      ]);
      expect(together.trainers.single.name, 'Joey');
      expect(together.refusals.single.identity.trainerName, 'Broken');
      expect(together.refusals.single.code, 'native_trainer.compiled_shape');
      expect(together.refusals.single.message, contains('Data/trainers.dat:'));
      final packed = together.artifacts();
      final restored = await NativeTrainerCatalogQualification.fromArtifacts(
          evidence: packed.evidence,
          artifacts: packed.artifacts,
          normalizedSource: source.fixture.source,
          files: source.fixture.files,
          nativeCatalog: NativePsdkTrainerBundle.builtin());
      expect(restored.evidenceHash, together.evidenceHash);
    });
  }

  for (final malformed in <String, Object>{
    'nil': const _EncodedMarshal([48]),
    'wrong class': const LiteralFixtureObject('GameData::Other', {})
  }.entries) {
    test('a ${malformed.key} value under a valid external key stays local',
        () async {
      final source = await _source([_roster(), _roster(name: 'Broken')],
          transformCompiledRecord: (row, object) =>
              row.name == 'Broken' ? malformed.value : object);
      expect((await _prepare(source)).trainers.single.name, 'Joey');
      final together = await _prepare(source, requested: [
        _key(source.pbs.logicalProjectNamespace),
        _key(source.pbs.logicalProjectNamespace, name: 'Broken')
      ]);
      expect(together.trainers.single.name, 'Joey');
      expect(together.refusals.single.identity.trainerName, 'Broken');
      expect(together.refusals.single.code, 'native_trainer.compiled_shape');
      expect(together.refusals.single.message, contains('Data/trainers.dat:'));
      final packed = together.artifacts();
      final restored = await NativeTrainerCatalogQualification.fromArtifacts(
          evidence: packed.evidence,
          artifacts: packed.artifacts,
          normalizedSource: source.fixture.source,
          files: source.fixture.files,
          nativeCatalog: NativePsdkTrainerBundle.builtin());
      expect(restored.evidenceHash, together.evidenceHash);
    });
  }

  test(
      'corrupt containers and unattributable external keys remain global failures',
      () async {
    for (final bytes in [
      [4, 8, ..._encode([])],
      [
        4,
        8,
        ..._encode({'not-an-identity': null})
      ],
      [4, 8, 123, 6]
    ]) {
      final source =
          await _source([_roster()], extraFiles: {'Data/trainers.dat': bytes});
      await expectLater(_prepare(source), throwsA(isA<ContractError>()));
    }
  });

  test(
      'canonical projection governs native defaults rather than raw support labels',
      () async {
    final source = await _source([_roster()]);
    NativePsdkTrainerBundle changed(void Function(Map) mutate) {
      final raw =
          (jsonDecode(jsonEncode(NativePsdkTrainerBundle.builtin().toJson()))
                  as Map)
              .cast<String, dynamic>();
      mutate(raw);
      return NativePsdkTrainerBundle.fromJson(raw);
    }

    final supported = changed((raw) {
      final moves = (raw['catalogs'] as List)
          .cast<Map>()
          .singleWhere((row) => row['catalog'] == 'moves')['entries'] as List;
      for (final move in moves.cast<Map>()) {
        move['engineSupportLevel'] = 'catalog_only';
      }
    });
    expect((await _prepare(source, catalog: supported)).trainers, hasLength(1));
    final unsupported = changed((raw) {
      final moves = (raw['catalogs'] as List)
          .cast<Map>()
          .singleWhere((row) => row['catalog'] == 'moves')['entries'] as List;
      for (final move in moves.cast<Map>()) {
        move['unsupportedReasons'] = ['psdk_method:s_not_a_real_method'];
      }
    });
    final result = await _prepare(source, catalog: unsupported);
    expect(result.trainers, isEmpty);
    expect(
        result.refusals.single.code, 'native_trainer.native_move_projection');
    final missing = changed((raw) {
      for (final row in (raw['sourceLearnsets'] as List).cast<Map>()) {
        row['startingMoves'] = ['missing_native_move'];
        row['relearnMoves'] = <Object>[];
        row['levelUp'] = <Object>[];
      }
    });
    expect((await _prepare(source, catalog: missing)).refusals.single.code,
        'native_trainer.native_move_closure');
  });

  test('compiled-only nonempty bags refuse only their exact identity',
      () async {
    final source = await _source([
      _roster(),
      _roster(name: 'Bag')
    ], compiled: [
      _roster(),
      _roster(name: 'Bag', items: [const _Symbol('POTION')])
    ]);
    final result = await _prepare(source, requested: [
      _key(source.pbs.logicalProjectNamespace),
      _key(source.pbs.logicalProjectNamespace, name: 'Bag')
    ]);
    expect(result.trainers, hasLength(1));
    expect(result.refusals.single.code, 'native_trainer.roster_changed');
  });

  test('source LoseText is preserved as evidence and must match compiled text',
      () async {
    final source = await _source([_roster()]);
    expect(
        (await _prepare(source)).rows.single['sourceLoseText'], 'Good game!');
    final mismatch =
        await _source([_roster()], compiled: [_roster(loseText: 'Changed')]);
    expect((await _prepare(mismatch)).refusals.single.code,
        'native_trainer.roster_changed');
  });

  test('portable proof requires the identical active shared native catalog',
      () async {
    final source = await _source([_roster()]);
    final result = await _prepare(source);
    final packed = result.artifacts();
    final raw =
        (jsonDecode(jsonEncode(NativePsdkTrainerBundle.builtin().toJson()))
                as Map)
            .cast<String, dynamic>();
    ((raw['species'] as List).first['names'] as Map)['en'] = 'Different';
    final other = NativePsdkTrainerBundle.fromJson(raw);
    await expectLater(
        NativeTrainerCatalogQualification.fromArtifacts(
            evidence: packed.evidence,
            artifacts: packed.artifacts,
            normalizedSource: source.fixture.source,
            files: source.fixture.files,
            nativeCatalog: other),
        _error('native_trainer.portable_context'));
    source.fixture.files.overrides['Data/trainers.dat'] = [4, 8, 48];
    await expectLater(
        NativeTrainerCatalogQualification.fromArtifacts(
            evidence: packed.evidence,
            artifacts: packed.artifacts,
            normalizedSource: source.fixture.source,
            files: source.fixture.files,
            nativeCatalog: NativePsdkTrainerBundle.builtin()),
        _error('native_trainer.compiled_changed'));
  });

  test('trainer battle bags are not silently dropped', () async {
    final source = await _source([_roster()],
        pbs: '[ARBITRARY,Joey]\nItems = POTION\nPokemon = RATTATA,16\n');
    expect((await _prepare(source)).refusals.single.code,
        'native_trainer.roster_changed');
  });

  test('compiled witness hash and length are verified before decode', () async {
    final source = await _source([_roster()]);
    source.fixture.files.overrides['Data/trainers.dat'] = [4, 8, 48];
    await expectLater(
        _prepare(source), _error('native_trainer.compiled_changed'));
  });

  test('cancellation and request limits do not produce partial authority',
      () async {
    final source = await _source([_roster()]);
    final cancellation = ScanCancellation()..cancel();
    await expectLater(
        _prepare(source, cancellation: cancellation), throwsA(anything));
    await expectLater(
        _prepare(source,
            requested: [
              _key(source.pbs.logicalProjectNamespace),
              _key(source.pbs.logicalProjectNamespace, version: 1)
            ],
            limits: const NativeTrainerQualificationLimits(
                maxRequestedTrainers: 1)),
        _error('native_trainer.request_quota'));
  });

  test('duplicate input traversal is itself bounded', () async {
    final source = await _source([_roster()]);
    await expectLater(
        _prepare(source,
            requested:
                List.filled(9000, _key(source.pbs.logicalProjectNamespace))),
        _error('native_trainer.request_quota'));
  });

  test('species refusal remains local and compiled files are read once',
      () async {
    final source = await _source([
      _roster(),
      _roster(name: 'Unknown', party: [_member(symbol: 'UNKNOWN')])
    ]);
    final result = await _prepare(source, requested: [
      _key(source.pbs.logicalProjectNamespace),
      _key(source.pbs.logicalProjectNamespace, name: 'Unknown')
    ]);
    expect(result.trainers, hasLength(1));
    expect(result.refusals.single.code, 'native_trainer.species_binding');
    for (final path in ['Data/trainers.dat', 'Data/species.dat']) {
      final id = source.fixture.snapshot.entries
          .singleWhere((row) => row.relativePath == path)
          .fileId;
      expect(
          source.fixture.files.reads.where((read) => read == id), hasLength(1));
    }
  });

  test('cancellation during an owned source read is propagated', () async {
    final source = await _source([_roster()]);
    final cancellation = ScanCancellation();
    source.fixture.files.onRead = (path) {
      if (path == 'Data/trainers.dat') cancellation.cancel();
    };
    await expectLater(_prepare(source, cancellation: cancellation),
        _error('source.cancelled'));
  });

  test('evidence and caller artifact quotas are enforced', () async {
    final source = await _source([_roster()]);
    await expectLater(
        _prepare(source,
            limits:
                const NativeTrainerQualificationLimits(maxEvidenceBytes: 1)),
        _error('native_trainer.evidence_quota'));
    await expectLater(
        _prepare(source,
            limits:
                const NativeTrainerQualificationLimits(maxCompiledBytes: 1)),
        _error('native_trainer.compiled_witness'));
    final result = await _prepare(source);
    expect(
        () => result.artifacts(
            limits: const NativeWriteLimits(maxTotalArtifactBytes: 1)),
        _error('native_trainer.artifact_quota'));
  });

  test(
      'snapshot and contradictory profiles cannot borrow another PBS authority',
      () async {
    final source = await _source([_roster()]);
    final another = await _source([_roster(version: 1)]);
    await expectLater(
        NativeTrainerCatalogQualification.prepare(
            normalizedSource: another.fixture.source,
            source: source.pbs,
            files: source.fixture.files,
            nativeCatalog: NativePsdkTrainerBundle.builtin(),
            requestedTrainers: [_key(source.pbs.logicalProjectNamespace)]),
        _error('native_trainer.source_binding'));
  });

  test('a fully rehashed portable roster or policy cannot grant qualification',
      () async {
    final source = await _source([_roster()]);
    final result = await _prepare(source);
    final mutations = <void Function(Map<String, Object?>)>[
      (proof) => proof['policy'] = 'forged',
      (proof) => proof['sourcePbsHash'] = '0' * 64,
      (proof) => proof['normalizationHash'] = '0' * 64,
      (proof) => proof['sourceProfileHash'] = '0' * 64,
      (proof) => proof['compiledTrainerWitness'] = {'sha256': '0' * 64},
      (proof) => proof['runtimeBattleBuilderQualified'] = true,
      (proof) => ((proof['trainers'] as List).single['members'] as List)
          .single['level'] = 99,
      (proof) => ((proof['trainers'] as List).single['nativeTrainer']
          as Map)['name'] = 'Forged',
      (proof) =>
          ((proof['requestedTrainers'] as List).single as Map)['version'] = 7,
    ];
    for (final change in mutations) {
      final packed = _forge(result, change);
      await expectLater(
          NativeTrainerCatalogQualification.fromArtifacts(
              evidence: packed.evidence,
              artifacts: packed.artifacts,
              normalizedSource: source.fixture.source,
              files: source.fixture.files,
              nativeCatalog: NativePsdkTrainerBundle.builtin()),
          _error('native_trainer.portable_requalification'));
    }
  });

  test(
      'artifact replacement, omission, duplication and extra chunks are refused',
      () async {
    final source = await _source([_roster()]);
    final result = await _prepare(source);
    final packed = result.artifacts();
    final extra = NativeArtifact(
        bytes: utf8.encode('{"kind":"unrelated"}'),
        mediaType: 'application/json');
    for (final artifacts in [
      <NativeArtifact>[],
      [packed.artifacts.first, packed.artifacts.first],
      [extra],
      [...packed.artifacts, extra]
    ]) {
      await expectLater(
          NativeTrainerCatalogQualification.fromArtifacts(
              evidence: packed.evidence,
              artifacts: artifacts,
              normalizedSource: source.fixture.source,
              files: source.fixture.files,
              nativeCatalog: NativePsdkTrainerBundle.builtin()),
          _error('native_trainer.portable_artifacts'));
    }
    expect(
        () => (result.rows.single['nativeTrainer'] as Map)['name'] = 'Mutated',
        throwsUnsupportedError);
    expect(() => result.trainers.clear(), throwsUnsupportedError);
    expect(() => result.trainers.single.team.clear(), throwsUnsupportedError);
    expect(() => result.trainers.single.team.single.moves.clear(),
        throwsUnsupportedError);
  });

  test(
      'portable proof restores by requalification and rejects any forged context',
      () async {
    final source = await _source([_roster()]);
    final result = await _prepare(source);
    final packed = result.artifacts();
    final restored = await NativeTrainerCatalogQualification.fromArtifacts(
        evidence: packed.evidence,
        artifacts: packed.artifacts,
        normalizedSource: source.fixture.source,
        files: source.fixture.files,
        nativeCatalog: NativePsdkTrainerBundle.builtin());
    expect(restored.evidenceHash, result.evidenceHash);
    for (final field in [
      'qualificationHash',
      'nativeCatalogHash',
      'sourceSnapshotHash',
      'policy'
    ]) {
      await expectLater(
          NativeTrainerCatalogQualification.fromArtifacts(
              evidence: {...packed.evidence, field: 'forged'},
              artifacts: packed.artifacts,
              normalizedSource: source.fixture.source,
              files: source.fixture.files,
              nativeCatalog: NativePsdkTrainerBundle.builtin()),
          throwsA(isA<ContractError>()));
    }
    expect(() => (result.rows.single['members'] as List).clear(),
        throwsUnsupportedError);
  });
}
