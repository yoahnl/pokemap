import 'dart:convert';
import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_encounter_terrain_binding.dart';
import 'package:avelune_converter_adapters/src/source_encounter_consumers.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

List<int> _integer(int value) => value == 0
    ? [0]
    : value > 0 && value < 123
        ? [value + 5]
        : value < 0 && value > -124
            ? [(value - 5) & 255]
            : [2, value & 255, (value >> 8) & 255];
List<int> _text(String value, int marker) {
  final bytes = utf8.encode(value);
  return [marker, ..._integer(bytes.length), ...bytes];
}

List<int> _symbol(String value) => _text(value, 58);
List<int> _string(String value) => _text(value, 34);

final class _Record {
  const _Record(this.id, this.base, this.name, {this.form = 0, this.formName});
  final String id;
  final String base;
  final String name;
  final int form;
  final String? formName;
}

List<int> _compiled(List<_Record> records) => [
      4,
      8,
      123,
      ..._integer(records.length),
      for (final row in records) ...[
        ..._symbol(row.id),
        111,
        ..._symbol('GameData::Species'),
        ..._integer(4 + (row.formName == null ? 0 : 1)),
        ..._symbol('@id'),
        ..._symbol(row.id),
        ..._symbol('@species'),
        ..._symbol(row.base),
        ..._symbol('@form'),
        105,
        ..._integer(row.form),
        ..._symbol('@real_name'),
        ..._string(row.name),
        if (row.formName != null) ...[
          ..._symbol('@real_form_name'),
          ..._string(row.formName!),
        ],
      ],
    ];

Future<({LiteralTileFixture fixture, SourcePbsProject pbs})> _source(
    List<_Record> records,
    {String? pbs,
    String forms = '',
    List<LiteralFixtureMap>? maps,
    List<LiteralFixtureTileset>? tilesets,
    List<int>? scriptsBytes,
    String encounters = '[001]\nLand,11\n100,RATTATA,14,17\n',
    List<int>? compiled}) async {
  final fixture = await LiteralTileFixture.create(
      maps: maps,
      tilesets: tilesets,
      interpretationProfile: scriptsBytes == null ? null : fixtureSourceInterpretationProfile,
      scriptsBytes: scriptsBytes,
      extraFiles: {
        'PBS/encounters.txt': utf8.encode(encounters),
        'Data/species.dat': compiled ?? _compiled(records),
        'PBS/pokemon.txt': utf8.encode(pbs ??
            [
              for (final row in records.where((r) => r.form == 0))
                '[${row.base}]\nName = ${row.name}\n',
            ].join()),
        if (forms.isNotEmpty) 'PBS/pokemon_forms.txt': utf8.encode(forms),
      });
  final source = await const SourcePbsParser()
      .read(snapshot: fixture.snapshot, files: fixture.files);
  return (fixture: fixture, pbs: source);
}

NativePsdkTrainerBundle _catalog(
    List<({String id, String base, int form, String name, String? label})>
        rows) {
  final builtin = NativePsdkTrainerBundle.builtin();
  final raw =
      (jsonDecode(jsonEncode(builtin.toJson())) as Map).cast<String, dynamic>();
  final original = (raw['species'] as List).first as Map;
  final originalId = original['id'];
  final learnset = (raw['sourceLearnsets'] as List)
      .cast<Map>()
      .singleWhere((row) => row['speciesId'] == originalId);
  raw['species'] = [
    for (final row in rows)
      {
        ...original,
        'id': row.id,
        'names': {'en': row.name},
        'forms': {
          'baseFormId': row.base,
          'formId': '${row.form}',
          'isBaseForm': row.form == 0,
          'otherForms': [
            for (final other in rows)
              if (other.base == row.base && other.form != 0) '${other.form}'
          ]
        },
      }
  ];
  raw['sourceLearnsets'] = [
    for (final row in rows) {...learnset, 'speciesId': row.id}
  ];
  raw['evolutions'] = [
    for (final row in rows)
      {'schemaVersion': 1, 'speciesId': row.id, 'evolutions': <Object>[]}
  ];
  raw['media'] = [
    for (final row in rows)
      {
        'schemaVersion': 1,
        'speciesId': row.id,
        'defaultFormId': '${row.form}',
        'variants': {
          '${row.form}': {
            'frontStatic': nativePsdkMediaTarget(row.id, 'front'),
            'backStatic': nativePsdkMediaTarget(row.id, 'back')
          }
        }
      }
  ];
  raw['fallbackMedia'] = <Object>[];
  final evidence = raw['evidence'] as Map;
  evidence['catalogRequests'] = [
    for (final row in rows) {'baseId': row.base, 'form': row.form, 'level': 1}
  ];
  evidence['nativeRequestMoveBindings'] = [
    for (final row in rows)
      {
        'baseId': row.base,
        'form': row.form,
        'level': 1,
        'movePolicy': 'nativeDefaults',
        'moveIds': nativeTrainerDefaultMoveIds(
            builtin.learnsetsBySpeciesId[originalId]!, 1)
      }
  ];
  evidence['nativeFormNamesBySpeciesId'] = {
    for (final row in rows)
      if (row.label != null) row.id: {'en': row.label}
  };
  return NativePsdkTrainerBundle.fromJson(raw);
}

({String id, String base, int form, String name, String? label}) _native(
        String id, String name,
        {String? base, int form = 0, String? label}) =>
    (id: id, base: base ?? id, form: form, name: name, label: label);

Future<NativeEncounterCatalogQualification> _prepare(
        ({LiteralTileFixture fixture, SourcePbsProject pbs}) source,
        {NativePsdkCatalog? catalog,
        Iterable<int> maps = const [1],
        ScanCancellation? cancellation}) =>
    NativeEncounterCatalogQualification.prepare(
        snapshot: source.fixture.snapshot,
        source: source.pbs,
        files: source.fixture.files,
        nativeCatalog: catalog ?? _catalog([_native('rattata', 'Rattata')]),
        selectedSourceMapIds: maps,
        cancellation: cancellation);

Future<({NormalizedSourceProject source, SourceFilePort files})>
    _profileProject(LiteralTileFixture fixture) async {
  final hasScripts = fixture.sourceBytes.containsKey('Data/Scripts.rxdata');
  final bytes = {...fixture.sourceBytes,
    if (!hasScripts) 'Data/Scripts.rxdata': syntheticInterpretationArchive};
  final profile = hasScripts ? fixtureSourceInterpretationProfile : syntheticSourceInterpretationProfile;
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: fixture.snapshot.logicalProjectNamespace,
      policyHash: fixture.snapshot.policyHash,
      entries: [
        ...fixture.snapshot.entries,
        if (!hasScripts) SourceFileEntry(fileId: ConverterId('profile-scripts'),
          relativePath: 'Data/Scripts.rxdata', kind: SourceNodeKind.file,
          byteLength: syntheticInterpretationArchive.length, sha256: profile.scriptsArchiveHash,
          format: 'ruby-marshal', family: 'data')
      ], diagnostics: [], excludedPaths: [],
      profileEvidence: fixture.snapshot.profileEvidence, state: SourceScanState.complete);
  final files = LiteralFixtureFiles(snapshot, bytes);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: files,
      interpretationProfile: profile,
      selectedMapIds:
          fixture.source.maps.map((map) => map.map.sourceMapId).toSet());
  return (source: source, files: files);
}

Matcher _code(String code) =>
    throwsA(isA<ContractError>().having((e) => e.code, 'code', code));

Future<NativeEncounterCatalogBindingResult> _bindPrepared(
        ({LiteralTileFixture fixture, SourcePbsProject pbs}) source,
        NativeEncounterCatalogQualification qualification,
        {Map<int, String> maps = const {1: 'native-one'}}) =>
    const NativeEncounterCatalogBindings().bind(
        snapshot: source.fixture.snapshot,
        source: source.pbs,
        files: source.fixture.files,
        nativeMapIds: maps,
        qualification: qualification,
        ratePolicy: NativeEncounterRatePolicy
            .adaptSourceBasePercentToNativeConstantChance);

NativePsdkTrainerBundle _changedCatalog(
    void Function(Map<String, dynamic>) change) {
  final raw = (jsonDecode(
              jsonEncode(_catalog([_native('rattata', 'Rattata')]).toJson()))
          as Map)
      .cast<String, dynamic>();
  change(raw);
  return NativePsdkTrainerBundle.fromJson(raw);
}

NativeEncounterReleaseArtifacts _rewritePortableFile(
    NativeEncounterReleaseArtifacts release,
    String target,
    void Function(Map<String, dynamic>) change) {
  final envelope =
      (jsonDecode(jsonEncode(release.evidence)) as Map).cast<String, Object?>();
  final descriptors = (envelope['files'] as List).cast<Map>();
  final descriptor = descriptors.singleWhere((row) => row['file'] == target);
  final handles = (descriptor['chunks'] as List).cast<String>().toSet();
  final bytes = <int>[];
  for (final artifact in release.artifacts
      .where((artifact) => handles.contains(artifact.handle))) {
    final chunk = jsonDecode(utf8.decode(artifact.bytes)) as Map;
    bytes.addAll(base64Decode(chunk['bytesBase64'] as String));
  }
  final json = (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>();
  change(json);
  final encoded = utf8
      .encode(canonicalJsonOf(json, limits: nativePsdkCatalogShardJsonLimits));
  final hash = crypto.sha256.convert(encoded).toString();
  final chunks = <NativeArtifact>[];
  for (var offset = 0; offset < encoded.length; offset += 131072) {
    chunks.add(NativeArtifact(
        bytes: utf8.encode(canonicalJsonOf({
          'kind': 'nativeEncounterGenericByteChunk',
          'version': 2,
          'file': target,
          'sha256': hash,
          'byteLength': encoded.length,
          'offset': offset,
          'bytesBase64': base64Encode(encoded.sublist(
              offset, (offset + 131072).clamp(0, encoded.length))),
        })),
        mediaType: 'application/json'));
  }
  descriptor['sha256'] = hash;
  descriptor['byteLength'] = encoded.length;
  descriptor['chunks'] = chunks.map((chunk) => chunk.handle).toList();
  return NativeEncounterReleaseArtifacts(evidence: envelope, artifacts: [
    ...release.artifacts
        .where((artifact) => !handles.contains(artifact.handle)),
    ...chunks
  ]);
}

void main() {
  test('consumers reject a different valid qualification fingerprint',
      () async {
    final fixture =
        await _source(const [_Record('RATTATA', 'RATTATA', 'Rattata')]);
    final project = await _profileProject(fixture.fixture);
    final pbs = await const SourcePbsParser()
        .read(snapshot: project.source.snapshot, files: project.files);
    Future<NativeEncounterCatalogQualification> qualify(List<int> maps) =>
        NativeEncounterCatalogQualification.prepare(
            snapshot: project.source.snapshot,
            source: pbs,
            files: project.files,
            nativeCatalog: _catalog([_native('rattata', 'Rattata')]),
            selectedSourceMapIds: maps);
    final first = await qualify([1]);
    final second = await qualify([1, 2]);
    expect(first.evidenceHash, isNot(second.evidenceHash));
    final catalog = await const NativeEncounterCatalogBindings().bind(
        snapshot: project.source.snapshot,
        source: pbs,
        files: project.files,
        nativeMapIds: {1: 'native-one'},
        qualification: first,
        ratePolicy: NativeEncounterRatePolicy
            .adaptSourceBasePercentToNativeConstantChance);
    expect(
        () => SourceEncounterConsumers.bind(
            source: project.source,
            nativeMapIds: {1: 'native-one'},
            tables: catalog.tables,
            catalogEvidence: catalog.evidence,
            qualification: second,
            pendingCompanions: [],
            precedingMutations: []),
        throwsA(isA<NativeWriteException>().having((error) => error.code,
            'code', 'encounter_consumers.catalog_binding')));
  });
  test(
      'automatic project reports unsupported source species instead of falling back to V1',
      () async {
    final fixture = await _source(
        const [_Record('REEDLING', 'REEDLING', 'Reedling')],
        encounters: '[1]\nLand,11\n100,REEDLING,14,14\n');
    final project = await _profileProject(fixture.fixture);
    await expectLater(
        NativeEncounterCatalogQualification.prepareAutomatic(
            source: project.source,
            files: project.files,
            selectedSourceMapIds: [1]),
        throwsA(isA<ContractError>().having(
            (error) => error.code, 'code', startsWith('native_species.'))));
  });
  test(
      'automatic project qualification skips unqualified and absent selected encounters',
      () async {
    final fixture =
        await _source(const [_Record('RATTATA', 'RATTATA', 'Rattata')]);
    expect(
        await NativeEncounterCatalogQualification.prepareAutomatic(
            source: fixture.fixture.source,
            files: fixture.fixture.files,
            selectedSourceMapIds: [1]),
        isNull);
    final project = await _profileProject(fixture.fixture);
    expect(
        await NativeEncounterCatalogQualification.prepareAutomatic(
            source: project.source,
            files: project.files,
            selectedSourceMapIds: [2]),
        isNull);
  });

  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  for (final fishing in [false, true]) {
    test(
        'automatic full PBS qualification binds nine maps to native terrain fishing=$fishing',
        () async {
      final fixture = await _source(
          const [_Record('RATTATA', 'RATTATA', 'Rattata')],
          scriptsBytes: fishing ? await File(scriptsPath!).readAsBytes() : null,
          maps: [
            for (var id = 1; id <= 9; id++)
              LiteralFixtureMap(id: id, layers: [
                [384, 385, 386],
                [0, 0, 0],
                [0, 0, 0]
              ])
          ],
          tilesets: [
            LiteralFixtureTileset(
                id: 1, terrainTags: {384: 2, 385: 7}, passages: {385: 15})
          ],
          encounters: [
            for (var id = 1; id <= 9; id++)
              '[$id]\nLand,11\n100,RATTATA,14,14\nWater,10\n100,RATTATA,14,14\n${fishing ? 'OldRod,100\n100,RATTATA,14,14\n' : ''}RockSmash,20\n100,RATTATA,14,14\n'
          ].join());
      final project = await _profileProject(fixture.fixture);
      final maps = {for (var id = 1; id <= 9; id++) id: 'native-$id'};
      final pbs = await const SourcePbsParser()
          .read(snapshot: project.source.snapshot, files: project.files);
      final qualification =
          (await NativeEncounterCatalogQualification.prepareAutomatic(
              source: project.source,
              files: project.files,
              selectedSourceMapIds: maps.keys))!;
      expect(qualification.isGeneric, isTrue);
      expect(qualification.evidence['sourcePbsHash'], pbs.canonicalHash.value);
      final binding = await const NativeEncounterCatalogBindings().bind(
          snapshot: project.source.snapshot,
          interpretationProfile: project.source.interpretationProfile,
          source: pbs,
          files: project.files,
          nativeMapIds: maps,
          qualification: qualification,
          ratePolicy: NativeEncounterRatePolicy
              .adaptSourceBasePercentToNativeConstantChance,
          fishingRatePolicy: NativeEncounterFishingRatePolicy
              .adaptSourceBaseFishingBiteChanceToNativeTable);
      expect(binding.tables, hasLength(fishing ? 36 : 27));
      final terrain = const SourceEncounterTerrainBinding().bind(
          source: project.source,
          nativeMapIds: maps,
          tableIdsBySourceMethod: binding.tableIdsBySourceMethod);
      expect(terrain.zonesBySourceMapId, hasLength(9));
      for (final zones in terrain.zonesBySourceMapId.values) {
        expect(
            zones
                .where((zone) => zone.kind == GameplayZoneKind.encounter)
                .map((zone) => zone.encounter!.encounterKind)
                .toSet(),
            {
              EncounterKind.walk,
              EncounterKind.surf,
              if (fishing) EncounterKind.oldRod
            });
      }
      expect(terrain.evidence['ignoredInteractiveMethods'], hasLength(9));
    },
        skip: fishing && scriptsPath == null
            ? 'Requires the exact inert source fishing oracle.'
            : false);
  }

  test('qualifies and binds more than eight selected original source maps',
      () async {
    final source = await _source(
        const [_Record('RATTATA', 'RATTATA', 'Rattata')],
        encounters: [
          for (var i = 1; i <= 9; i++) '[$i]\nLand,11\n100,RATTATA,14,17\n'
        ].join());
    final qualification =
        await _prepare(source, maps: List.generate(9, (i) => i + 1));
    expect(qualification.wildCases, hasLength(4));
    expect(qualification.evidence['pureNativeWildGeneratorQualified'], true);
    expect(qualification.evidence['completeBattleSetupQualified'], false);
    final result = await const NativeEncounterCatalogBindings().bind(
        snapshot: source.fixture.snapshot,
        source: source.pbs,
        files: source.fixture.files,
        nativeMapIds: {for (var i = 1; i <= 9; i++) i: 'native-$i'},
        qualification: qualification,
        ratePolicy: NativeEncounterRatePolicy
            .adaptSourceBasePercentToNativeConstantChance);
    expect(result.tables, hasLength(9));
    expect(result.tables.first.entries.single.pokemonOverrides?.abilityId,
        qualification.bundle.speciesById['rattata']!.abilities.primary);
    expect(qualification.wildCases.keys,
        ['rattata|0|14', 'rattata|0|15', 'rattata|0|16', 'rattata|0|17']);
  });

  test(
      'resolves arbitrary source form26 to native form7 with exact PBS locator',
      () async {
    final source = await _source(const [
      _Record('UNOWN', 'UNOWN', 'Unown'),
      _Record('UNOWN_26', 'UNOWN', 'Unown', form: 26, formName: 'Exclamation'),
    ],
        forms: '[UNOWN,26]\nFormName = Exclamation\n',
        encounters: '[001]\nRockSmash,10\n100,UNOWN_26,3,5\n');
    final catalog = _catalog([
      _native('unown', 'Unown'),
      _native('unown_form7', 'Unown',
          base: 'unown', form: 7, label: 'Exclamation'),
    ]);
    final qualification = await _prepare(source, catalog: catalog);
    final result = await _bindPrepared(source, qualification);
    expect(result.tables.single.entries.single.speciesId, 'unown_form7');
    expect(
        qualification.wildCases.keys, ['unown|7|3', 'unown|7|4', 'unown|7|5']);
    expect(qualification.sourceMappings.single['sourceForm'], 26);
    final table = (result.evidence['tables'] as List).single as Map;
    final slot = (table['entries'] as List).single as Map;
    expect((slot['sourceSpeciesHeaderLocator'] as Map)['file'],
        'PBS/pokemon_forms.txt');
  });

  test('retains multiple source witnesses for one cached native tuple',
      () async {
    final source = await _source(const [
      _Record('A', 'A', 'Rattata'),
      _Record('B', 'B', 'Rattata'),
    ], encounters: '[001]\nLand,11\n50,A,14\n50,B,14\n');
    final qualification = await _prepare(source);
    expect(qualification.wildCases, hasLength(1));
    expect(qualification.wildCases.values.single['sourceSymbols'], ['A', 'B']);
    expect((await _bindPrepared(source, qualification)).tables.single.entries,
        hasLength(2));
  });

  test('preserves every ordered native default and raw support diagnostic',
      () async {
    final source =
        await _source(const [_Record('RATTATA', 'RATTATA', 'Rattata')]);
    final qualification = await _prepare(source);
    for (final row in qualification.wildCases.values) {
      final defaults = nativeTrainerDefaultMoveIds(
          qualification.bundle.learnsetsBySpeciesId['rattata']!,
          row['level'] as int);
      expect(row['requestedMoveIds'], defaults);
      expect(row['returnedMoveIds'], defaults);
      expect((row['diagnostics'] as List).map((d) => (d as Map)['moveId']),
          defaults);
      for (final generation in row['generations'] as List) {
        final pokemon = (generation as Map)['pokemon'] as Map;
        expect(pokemon['knownMoveIds'], defaults);
        expect(pokemon['abilityId'],
            qualification.bundle.speciesById['rattata']!.abilities.primary);
        expect(pokemon['currentHp'], greaterThan(0));
        expect(generation['deterministicRepeatMatched'], true);
      }
    }
    expect(
        () => qualification.sourceMappings.single['nativeSpeciesId'] = 'forged',
        throwsUnsupportedError);
    expect(() => qualification.wildCases.clear(), throwsUnsupportedError);
    final escaped = qualification.bundle;
    escaped.speciesById['rattata']!.names['en'] = 'Escaped mutation';
    expect(qualification.bundle.speciesById['rattata']!.names['en'], 'Rattata');
  });

  for (final methods in [
    '[001]\nLand,11\n100,RATTATA,14\n[001]\nLand,11\n100,RATTATA,14\n',
    '[001,1]\nLand,11\n100,RATTATA,14\n',
    '[001]\nLand,11\n0,RATTATA,14\n',
    '[001]\nLand,11\n100,RATTATA,18,14\n',
    '[001]\nLand,11\n100,RATTATA,0,101\n',
    '[001]\nLand,11\n100,RATTATA,14\nLand,11\n100,RATTATA,14\n',
  ]) {
    test(
        'rejects malformed ambiguous blocked or nonzero encounter section $methods',
        () async {
      final source = await _source(
          const [_Record('RATTATA', 'RATTATA', 'Rattata')],
          encounters: methods);
      await expectLater(_prepare(source), throwsA(isA<ContractError>()));
    });
  }

  test('rejects missing learnsets and missing default moves', () async {
    final source =
        await _source(const [_Record('RATTATA', 'RATTATA', 'Rattata')]);
    expect(
        () => _changedCatalog((raw) {
              raw['sourceLearnsets'] = <Object>[];
            }),
        throwsA(isA<ContractError>()));
    final catalog = _changedCatalog((raw) {
      for (final learnset in (raw['sourceLearnsets'] as List).cast<Map>()) {
        learnset['startingMoves'] = ['missing_native_move'];
        learnset['relearnMoves'] = <Object>[];
        learnset['levelUp'] = <Object>[];
      }
    });
    await expectLater(_prepare(source, catalog: catalog),
        _code('native_encounter.native_move_missing'));
  });

  test(
      'executes canonical projection and rejects an incompatible native method',
      () async {
    final source =
        await _source(const [_Record('RATTATA', 'RATTATA', 'Rattata')]);
    final catalog = _changedCatalog((raw) {
      for (final move in (((raw['catalogs'] as List)
                  .cast<Map>()
                  .singleWhere((row) => row['catalog'] == 'moves')['entries'])
              as List)
          .cast<Map>()) {
        move['unsupportedReasons'] = ['psdk_method:s_not_a_real_method'];
      }
    });
    await expectLater(_prepare(source, catalog: catalog),
        _code('native_encounter.native_move_projection'));
  });

  test('requires exact source snapshot and bounded unique positive map scope',
      () async {
    final source =
        await _source(const [_Record('RATTATA', 'RATTATA', 'Rattata')]);
    for (final maps in [
      <int>[0],
      <int>[1, 1],
      List.generate(2049, (i) => i + 1)
    ]) {
      await expectLater(
          _prepare(source, maps: maps), _code('native_encounter.source_scope'));
    }
    final qualification = await _prepare(source, maps: [1, 2]);
    expect(
        qualification.admitsSourceScope(source.fixture.snapshot, [1],
            source: source.pbs),
        true);
    await expectLater(
        _bindPrepared(source, qualification, maps: {3: 'outside'}),
        _code('native_encounter.source_binding'));
    await expectLater(_bindPrepared(source, qualification, maps: {1: ''}),
        _code('native_encounter.source_binding'));
    final other = await _source(
        const [_Record('RATTATA', 'RATTATA', 'Rattata')],
        encounters: '[001]\nLand,12\n100,RATTATA,14,17\n');
    expect(qualification.admitsAutomaticSource(other.fixture.snapshot), false);
    await expectLater(_bindPrepared(other, qualification),
        _code('native_encounter.source_binding'));
    await expectLater(
        NativeEncounterCatalogQualification.prepare(
            snapshot: other.fixture.snapshot,
            source: source.pbs,
            files: source.fixture.files,
            nativeCatalog: qualification.bundle,
            selectedSourceMapIds: [1]),
        _code('native_encounter.source_binding'));
  });

  test('checks cancellation before and after source reads', () async {
    final source =
        await _source(const [_Record('RATTATA', 'RATTATA', 'Rattata')]);
    final cancellation = ScanCancellation()..cancel();
    source.fixture.files.reads.clear();
    await expectLater(_prepare(source, cancellation: cancellation),
        _code('source.cancelled'));
    expect(source.fixture.files.reads, isEmpty);
    final duringRead = ScanCancellation();
    source.fixture.files.onRead = (_) => duringRead.cancel();
    await expectLater(
        _prepare(source, cancellation: duringRead), _code('source.cancelled'));
  });

  for (final composed in [false, true]) {
    test('rejects mutable catalog contents during await composed=$composed',
        () async {
      final source =
          await _source(const [_Record('RATTATA', 'RATTATA', 'Rattata')]);
      final shard = _catalog([_native('rattata', 'Rattata')]);
      final NativePsdkCatalog catalog =
          composed ? NativePsdkCatalogManifest.compose([shard]) : shard;
      source.fixture.files.onRead =
          (_) => catalog.speciesById['rattata']!.names['en'] = 'Mutated';
      await expectLater(
          _prepare(source, catalog: catalog), throwsA(isA<ContractError>()));
    });
    test(
        'roundtrips exact portable catalog and recomputed tuple semantics composed=$composed',
        () async {
      final source =
          await _source(const [_Record('RATTATA', 'RATTATA', 'Rattata')]);
      final shard = _catalog([_native('rattata', 'Rattata')]);
      final NativePsdkCatalog catalog =
          composed ? NativePsdkCatalogManifest.compose([shard]) : shard;
      final qualification = await _prepare(source, catalog: catalog);
      final release = qualification.artifacts();
      final restored = NativeEncounterCatalogQualification.fromArtifacts(
          evidence: release.evidence, artifacts: release.artifacts);
      expect(restored.evidence, qualification.evidence);
      expect(restored.wildCases, qualification.wildCases);
      expect(restored.bundle.toJson(), qualification.bundle.toJson());
      expect(restored.evidenceHash, qualification.evidenceHash);
      expect((await _bindPrepared(source, restored)).evidence,
          (await _bindPrepared(source, qualification)).evidence);
      expect(
          () => NativeEncounterCatalogQualification.fromArtifacts(
              evidence: release.evidence, artifacts: release.artifacts.skip(1)),
          _code('native_encounter.release_artifacts'));
      expect(
          () => NativeEncounterCatalogQualification.fromArtifacts(
              evidence: release.evidence,
              artifacts: [...release.artifacts, release.artifacts.first]),
          _code('native_encounter.release_artifacts'));
      expect(
          () => qualification.artifacts(
              limits: const NativeWriteLimits(maxArtifacts: 1)),
          _code('native_encounter.release_quota'));
    });
  }

  test(
      'rejects changed compiled source bytes while preserving immutable PBS evidence',
      () async {
    final source =
        await _source(const [_Record('RATTATA', 'RATTATA', 'Rattata')]);
    expect(() => source.pbs.documents.first.rawBytes[0] = 0,
        throwsUnsupportedError);
    expect(
        () => source.pbs.entries
            .firstWhere((entry) => entry.fields.isNotEmpty)
            .fields
            .first
            .values
            .add('Mutated'),
        throwsUnsupportedError);
    source.fixture.files.overrides['Data/species.dat'] = [4, 8, 0];
    await expectLater(
        _prepare(source), _code('native_species.compiled_species_changed'));
  });

  test('rejects a forged portable source mapping using fresh resolver evidence',
      () async {
    final source =
        await _source(const [_Record('RATTATA', 'RATTATA', 'Rattata')]);
    final qualification = await _prepare(source);
    final forged =
        _rewritePortableFile(qualification.artifacts(), 'context', (context) {
      ((context['sourceMappings'] as List).single as Map)['sourceName'] =
          'Forged name';
    });
    final restored = NativeEncounterCatalogQualification.fromArtifacts(
        evidence: forged.evidence, artifacts: forged.artifacts);
    expect(restored.wildCases, qualification.wildCases);
    await expectLater(_bindPrepared(source, restored),
        _code('native_encounter.species_identity'));
  });

  test(
      'rejects missing tampered reordered duplicate oversized and extra generic chunks',
      () async {
    final source =
        await _source(const [_Record('RATTATA', 'RATTATA', 'Rattata')]);
    final qualification = await _prepare(source);
    final release = qualification.artifacts();
    Map<String, Object?> envelope() =>
        (jsonDecode(jsonEncode(release.evidence)) as Map)
            .cast<String, Object?>();
    final multi = (release.evidence['files'] as List)
        .cast<Map>()
        .firstWhere((row) => (row['chunks'] as List).length > 1);
    final reordered = envelope();
    final descriptor = (reordered['files'] as List)
        .cast<Map>()
        .singleWhere((row) => row['file'] == multi['file']);
    descriptor['chunks'] = (descriptor['chunks'] as List).reversed.toList();
    expect(
        () => NativeEncounterCatalogQualification.fromArtifacts(
            evidence: reordered, artifacts: release.artifacts),
        _code('native_encounter.release_artifacts'));
    final artifact = release.artifacts.first;
    for (final mutation in ['offset', 'file', 'bytesBase64']) {
      final chunk = (jsonDecode(utf8.decode(artifact.bytes)) as Map)
          .cast<String, Object?>();
      chunk[mutation] = switch (mutation) {
        'offset' => 1,
        'file' => 'forged',
        _ => base64Encode(List.filled(131073, 0))
      };
      final changed = NativeArtifact(
          bytes: utf8.encode(canonicalJsonOf(chunk)),
          mediaType: 'application/json');
      final modified = envelope();
      for (final row in (modified['files'] as List).cast<Map>()) {
        row['chunks'] = [
          for (final handle in row['chunks'] as List)
            handle == artifact.handle ? changed.handle : handle
        ];
      }
      expect(
          () => NativeEncounterCatalogQualification.fromArtifacts(
              evidence: modified,
              artifacts: [changed, ...release.artifacts.skip(1)]),
          _code('native_encounter.release_artifacts'));
    }
    final extraJson = (jsonDecode(utf8.decode(artifact.bytes)) as Map)
        .cast<String, Object?>()
      ..['file'] = 'excess';
    final extra = NativeArtifact(
        bytes: utf8.encode(canonicalJsonOf(extraJson)),
        mediaType: 'application/json');
    expect(
        () => NativeEncounterCatalogQualification.fromArtifacts(
            evidence: release.evidence,
            artifacts: [...release.artifacts, extra]),
        _code('native_encounter.release_artifacts'));
    expect(
        () => NativeEncounterCatalogQualification.fromArtifacts(
            evidence: release.evidence,
            artifacts: release.artifacts,
            limits: const NativeWriteLimits(maxTotalArtifactBytes: 1)),
        _code('native_encounter.release_artifacts'));
    final unrelated = NativeArtifact(
        bytes: utf8.encode('{"kind":"unrelatedNativeEvidence"}'),
        mediaType: 'application/json');
    expect(
        NativeEncounterCatalogQualification.fromArtifacts(
            evidence: release.evidence,
            artifacts: [...release.artifacts, unrelated]).wildCases,
        qualification.wildCases);
  });

  test(
      'preserves unused source field diagnostics without importing source mechanics',
      () async {
    final source = await _source(
        const [_Record('RATTATA', 'RATTATA', 'Rattata')],
        pbs: '[RATTATA]\nName = Rattata\nMoves = -1,BROKEN\n');
    final qualification = await _prepare(source);
    expect(qualification.sourceMappings.single['sourceEntryBlocked'], true);
    expect(qualification.sourceMappings.single['ignoredSourceFieldDiagnostics'],
        isNotEmpty);
    expect((await _bindPrepared(source, qualification)).tables, hasLength(1));
  });

  test('qualifies through the projector regardless of raw support labels',
      () async {
    final source =
        await _source(const [_Record('RATTATA', 'RATTATA', 'Rattata')]);
    final catalog = _changedCatalog((raw) {
      for (final move in (((raw['catalogs'] as List)
                  .cast<Map>()
                  .singleWhere((row) => row['catalog'] == 'moves')['entries'])
              as List)
          .cast<Map>()) {
        move['engineSupportLevel'] = 'catalog_only';
      }
    });
    final qualification = await _prepare(source, catalog: catalog);
    for (final row in qualification.wildCases.values) {
      for (final diagnostic in row['diagnostics'] as List) {
        expect((diagnostic as Map)['engineSupportLevel'], 'catalogOnly');
        expect(diagnostic['psdkBridgeable'], true);
      }
    }
  });

  test(
      'rebind rejects a portable context missing an unpublished time-method tuple',
      () async {
    final source = await _source(
        const [_Record('RATTATA', 'RATTATA', 'Rattata')],
        encounters:
            '[001]\nLand,11\n100,RATTATA,14\nLandDay,11\n100,RATTATA,15\n');
    final qualification = await _prepare(source);
    final result = await _bindPrepared(source, qualification);
    expect(result.unqualifiedMethods.single['method'], 'LandDay');
    expect(qualification.wildCases, hasLength(2));
    final forged =
        _rewritePortableFile(qualification.artifacts(), 'context', (context) {
      (context['requests'] as List)
          .removeWhere((row) => (row as Map)['level'] == 15);
    });
    final restored = NativeEncounterCatalogQualification.fromArtifacts(
        evidence: forged.evidence, artifacts: forged.artifacts);
    await expectLater(_bindPrepared(source, restored),
        _code('native_encounter.source_binding'));
  });
}
