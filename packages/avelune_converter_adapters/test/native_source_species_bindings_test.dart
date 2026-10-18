import 'dart:convert';
import 'dart:io';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:image/image.dart' as image;
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

const _resolver = NativeSourceSpeciesBindings();

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
  const _Record(this.id, this.base, this.name,
      {this.form = 0,
      this.formName,
      this.key,
      this.type = 'GameData::Species',
      this.formIsString = false,
      this.duplicateId = false});
  final String id;
  final String base;
  final String name;
  final int form;
  final String? formName;
  final String? key;
  final String type;
  final bool formIsString;
  final bool duplicateId;
}

List<int> _compiled(List<_Record> records) => [
      4,
      8,
      123,
      ..._integer(records.length),
      for (final row in records) ...[
        ..._symbol(row.key ?? row.id),
        111,
        ..._symbol(row.type),
        ..._integer(
            4 + (row.formName == null ? 0 : 1) + (row.duplicateId ? 1 : 0)),
        ..._symbol('@id'),
        ..._symbol(row.id),
        ..._symbol('@species'),
        ..._symbol(row.base),
        ..._symbol('@form'),
        if (row.formIsString)
          ..._string('${row.form}')
        else ...[105, ..._integer(row.form)],
        ..._symbol('@real_name'),
        ..._string(row.name),
        if (row.formName != null) ...[
          ..._symbol('@real_form_name'),
          ..._string(row.formName!),
        ],
        if (row.duplicateId) ...[..._symbol('@id'), ..._symbol(row.id)],
      ],
    ];

Future<({LiteralTileFixture fixture, SourcePbsProject pbs})> _source(
    List<_Record> records,
    {String? pbs,
    String forms = '',
    List<int>? compiled,
    List<int>? scriptsBytes,
    List<LiteralFixtureMap>? maps}) async {
  final fixture = await LiteralTileFixture.create(
      interpretationProfile: scriptsBytes == null ? null : fixtureSourceInterpretationProfile,
      scriptsBytes: scriptsBytes,
      maps: maps,
      includeEventSystem: maps != null,
      extraFiles: {
        'Data/species.dat': compiled ?? _compiled(records),
        if (maps != null) ...{
          'Graphics/Characters/Original.png': literalFixtureAtlas(),
          'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Original\n'),
          'PBS/encounters.txt': utf8.encode('[17]\nLand,21\n100,CLOCKBIRD,7\n'),
          'Graphics/Pokemon/Front/CLOCKBIRD.png': image
              .encodePng(image.Image(width: 64, height: 64, numChannels: 4)),
          'Graphics/Pokemon/Back/CLOCKBIRD.png': image
              .encodePng(image.Image(width: 64, height: 64, numChannels: 4)),
        },
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
        'refs': {'learnset': row.id, 'evolution': row.id, 'media': row.id},
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

Future<NativeSourceSpeciesBindingResult> _bind(
        ({LiteralTileFixture fixture, SourcePbsProject pbs}) source,
        NativePsdkCatalog catalog,
        List<String> requested,
        {ScanCancellation? cancellation}) =>
    _resolver.bind(
        snapshot: source.fixture.snapshot,
        source: source.pbs,
        files: source.fixture.files,
        nativeCatalog: catalog,
        requestedSourceSymbols: requested,
        cancellation: cancellation);

Matcher _code(String value) => throwsA(isA<ContractError>()
    .having((e) => e.code, 'code', 'native_species.$value'));

void main() {
  test(
      'binds exact names independently from source symbol spelling with immutable evidence',
      () async {
    final source = await _source(const [
      _Record('MRMIME', 'MRMIME', 'Mr. Mime'),
      _Record('NIDORANmA', 'NIDORANmA', 'Nidoran♂'),
      _Record('NIDORANfE', 'NIDORANfE', 'Nidoran♀'),
    ]);
    final catalog = _catalog([
      _native('mr_mime', 'Mr. Mime'),
      _native('nidoran_m', 'Nidoran♂'),
      _native('nidoran_f', 'Nidoran♀')
    ]);
    final result =
        await _bind(source, catalog, ['NIDORANmA', 'MRMIME', 'NIDORANfE']);
    expect(result.mappings.keys, ['MRMIME', 'NIDORANfE', 'NIDORANmA']);
    final row = result.mappings['MRMIME']!;
    expect(row['nativeSpeciesId'], 'mr_mime');
    expect(row['sourceBaseSymbol'], 'MRMIME');
    expect(row['sourceForm'], 0);
    expect(row['nativeForm'], 0);
    expect((row['sourceLocator'] as Map)['file'], 'PBS/pokemon.txt');
    expect(
        (row['compiledWitness'] as Map)['sha256'],
        source.fixture.snapshot.entries
            .singleWhere((e) => e.relativePath == 'Data/species.dat')
            .sha256!
            .value);
    expect(result.evidence['sourceFieldDataUsed'], isFalse);
    expect(result.evidence['runtimeBattleBuilderQualified'], isFalse);
    expect(() => result.mappings.clear(), throwsUnsupportedError);
    expect(() => row['nativeForm'] = 9, throwsUnsupportedError);
    expect(() => (row['compiledWitness'] as Map)['sha256'] = 'changed',
        throwsUnsupportedError);
    catalog.speciesById['mr_mime']!.names['en'] = 'Changed later';
    expect(row['nativeName'], 'Mr. Mime');
  });

  test('allows only the visible generic right apostrophe orthography policy',
      () async {
    final source = await _source(const [_Record('BIRD', 'BIRD', "Farfetch'd")]);
    final result = await _bind(
        source, _catalog([_native('farfetchd', 'Farfetch’d')]), ['BIRD']);
    expect(result.mappings['BIRD']!['nativeSpeciesId'], 'farfetchd');
    expect(result.evidence['identityPolicy'],
        containsPair('apostrophe', 'U+2019-to-U+0027'));
    for (final name in [
      'farfetch’d',
      'Farfetch d',
      'Farfetch‘d',
      'Farfetch  d'
    ]) {
      await expectLater(
          _bind(source, _catalog([_native('bird', name)]), ['BIRD']),
          _code('native_base_identity'));
    }
  });

  test(
      'matches nonzero forms by attested English labels and arbitrary native numbering',
      () async {
    final source = await _source(const [
      _Record('UNOWN', 'UNOWN', 'Unown'),
      _Record('UNOWN_2', 'UNOWN', 'Unown', form: 2, formName: 'C')
    ], forms: '[UNOWN,2]\nFormName = C\n');
    final catalog = _catalog([
      _native('unown', 'Unown'),
      _native('unown_form17', 'Unown',
          base: 'unown', form: 17, label: 'Unown C')
    ]);
    final result = await _bind(source, catalog, ['UNOWN_2']);
    expect(result.mappings['UNOWN_2']!['nativeForm'], 17);
    expect(result.mappings['UNOWN_2']!['nativeSpeciesId'], 'unown_form17');
    expect((result.mappings['UNOWN_2']!['sourceLocator'] as Map)['file'],
        'PBS/pokemon_forms.txt');
  });

  test('supports a composed catalog through the same identity contract',
      () async {
    final source = await _source(const [_Record('A', 'A', 'Alpha')]);
    final catalog = NativePsdkCatalogManifest.compose([
      _catalog([_native('alpha', 'Alpha')])
    ]);
    expect((await _bind(source, catalog, ['A'])).mappings['A']!['nativeBaseId'],
        'alpha');
  });

  test(
      'rejects missing, duplicate and unbounded requested symbols before reading',
      () async {
    final source = await _source(const [_Record('A', 'A', 'Alpha')]);
    final catalog = _catalog([_native('alpha', 'Alpha')]);
    for (final request in [
      ['A', 'A'],
      [''],
      List.generate(2049, (i) => 'A$i')
    ]) {
      source.fixture.files.reads.clear();
      await expectLater(
          _bind(source, catalog, request), _code('requested_symbols'));
      expect(source.fixture.files.reads, isEmpty);
    }
    await expectLater(
        _bind(source, catalog, ['MISSING']), _code('compiled_identity'));
  });

  test('rejects wrong snapshot source binding', () async {
    final source = await _source(const [_Record('A', 'A', 'Alpha')]);
    final other = await _source(const [_Record('B', 'B', 'Beta')]);
    await expectLater(
        _resolver.bind(
            snapshot: source.fixture.snapshot,
            source: other.pbs,
            files: source.fixture.files,
            nativeCatalog: _catalog([_native('alpha', 'Alpha')]),
            requestedSourceSymbols: ['A']),
        _code('source_binding'));
  });

  test('rejects changed compiled witness bytes', () async {
    final source = await _source(const [_Record('A', 'A', 'Alpha')]);
    source.fixture.files.overrides['Data/species.dat'] =
        _compiled(const [_Record('B', 'B', 'Betaa')]);
    await expectLater(
        _bind(source, _catalog([_native('alpha', 'Alpha')]), ['A']),
        _code('compiled_species_changed'));
  });

  for (final row in [
    const _Record('A', 'A', 'Alpha', key: 'WRONG'),
    const _Record('A', '', 'Alpha'),
    const _Record('A', 'A', 'Alpha', form: -1),
    const _Record('A', 'A', 'Alpha', form: 2049),
    const _Record('A', 'A', 'Alpha', formIsString: true),
    const _Record('A', 'A', 'Alpha', duplicateId: true),
    const _Record('A', 'A', 'Alpha', type: 'Untrusted::Species'),
    const _Record('A', 'A', ''),
  ]) {
    test(
        'rejects malformed compiled identity ${row.key}/${row.base}/${row.form}/${row.type}/${row.duplicateId}/${row.formIsString}/${row.name}',
        () async {
      final source = await _source([row], pbs: '[A]\nName = Alpha\n');
      await expectLater(
          _bind(source, _catalog([_native('alpha', 'Alpha')]), ['A']),
          _code('compiled_species'));
    });
  }

  test('rejects duplicate compiled symbols and base/form tuples', () async {
    for (final rows in [
      const [_Record('A', 'A', 'Alpha'), _Record('A', 'A', 'Alpha')],
      const [
        _Record('A_1', 'A', 'Alpha', form: 1),
        _Record('A_2', 'A', 'Alpha', form: 1)
      ],
    ]) {
      final source = await _source(rows, pbs: '[A]\nName = Alpha\n');
      await expectLater(
          _bind(source, _catalog([_native('alpha', 'Alpha')]), [rows.first.id]),
          _code('compiled_species'));
    }
  });

  for (final pbs in [
    '[A]\nName = Alpha\n[A]\nName = Alpha\n',
    '[A]\nName = Alpha\nThis is malformed\n',
    '[B]\nName = Alpha\n'
  ]) {
    test('rejects ambiguous blocked or missing PBS identity $pbs', () async {
      final source =
          await _source(const [_Record('A', 'A', 'Alpha')], pbs: pbs);
      await expectLater(
          _bind(source, _catalog([_native('alpha', 'Alpha')]), ['A']),
          _code('pbs_identity'));
    });
  }

  test(
      'uses only witnessed identity from blocked unused source fields with visible diagnostics',
      () async {
    final source = await _source(const [_Record('A', 'A', 'Alpha')],
        pbs: '[A]\nName = Alpha\nMoves = -1,BROKEN\n');
    expect(source.pbs.entries.single.isBlocked, isTrue);
    final result =
        await _bind(source, _catalog([_native('alpha', 'Alpha')]), ['A']);
    final row = result.mappings['A']!;
    expect(row['sourceEntryBlocked'], isTrue);
    expect(row['ignoredSourceFieldDiagnostics'], hasLength(1));
    final diagnostic =
        (row['ignoredSourceFieldDiagnostics'] as List).single as Map;
    expect(diagnostic['code'], 'pbs.field_value');
    expect(diagnostic['field'], 'Moves');
    expect((diagnostic['locator'] as Map)['line'], 3);
    expect(result.evidence['ignoredSourceFieldDiagnostics'], hasLength(1));
    expect(source.pbs.entries.single.isBlocked, isTrue);
    expect(() => (row['ignoredSourceFieldDiagnostics'] as List).clear(),
        throwsUnsupportedError);
  });

  for (final pbs in [
    '[A]\nName = Alpha,Beta\nMoves = -1,BROKEN\n',
    'Unscoped = Broken\n[A]\nName = Alpha\nMoves = -1,BROKEN\n'
  ]) {
    test(
        'rejects identity or document diagnostics despite ignored source field: $pbs',
        () async {
      final source =
          await _source(const [_Record('A', 'A', 'Alpha')], pbs: pbs);
      await expectLater(
          _bind(source, _catalog([_native('alpha', 'Alpha')]), ['A']),
          _code(pbs.startsWith('[A]') ? 'source_name' : 'pbs_identity'));
    });
  }

  test(
      'reports unreadable compiled source through a typed species contract error',
      () async {
    final source = await _source(const [_Record('A', 'A', 'Alpha')]);
    source.fixture.files.readFailure = StateError('read unavailable');
    await expectLater(
        _bind(source, _catalog([_native('alpha', 'Alpha')]), ['A']),
        _code('compiled_species_read'));
  });

  test('rejects an already mutated composite before reading source files',
      () async {
    final source = await _source(const [_Record('A', 'A', 'Alpha')]);
    final catalog = NativePsdkCatalogManifest.compose([
      _catalog([_native('alpha', 'Alpha')])
    ]);
    catalog.speciesById['alpha']!.names['en'] = 'Mutated';
    source.fixture.files.reads.clear();
    await expectLater(
        _bind(source, catalog, ['A']), _code('catalog_integrity'));
    expect(source.fixture.files.reads, isEmpty);
  });

  test('rejects missing compiled witness and malformed Marshal bytes',
      () async {
    for (final bytes in [
      <int>[],
      <int>[4, 8, 48],
      <int>[4, 8, 123, 0]
    ]) {
      final source =
          await _source(const [_Record('A', 'A', 'Alpha')], compiled: bytes);
      await expectLater(
          _bind(source, _catalog([_native('alpha', 'Alpha')]), ['A']),
          _code(bytes.length == 4 ? 'compiled_identity' : 'compiled_species'));
    }
  });

  test('rejects authored source Name mismatch even when native could match',
      () async {
    final source = await _source(const [_Record('A', 'A', 'Alpha')],
        pbs: '[A]\nName = Beta\n');
    await expectLater(
        _bind(source, _catalog([_native('alpha', 'Alpha')]), ['A']),
        _code('source_name'));
  });

  test('rejects English native base ambiguity', () async {
    final source = await _source(const [_Record('A', 'A', 'Alpha')]);
    await expectLater(
        _bind(
            source,
            _catalog([_native('alpha', 'Alpha'), _native('other', 'Alpha')]),
            ['A']),
        _code('native_base_identity'));
  });

  test(
      'rejects missing or mismatched PBS form names and ambiguous native labels',
      () async {
    final rows = const [
      _Record('A', 'A', 'Alpha'),
      _Record('A_1', 'A', 'Alpha', form: 1, formName: 'Variant')
    ];
    for (final forms in ['[A,1]\nFormName = Wrong\n', '[A,1]\n', '']) {
      final source = await _source(rows, forms: forms);
      await expectLater(
          _bind(source, _catalog([_native('alpha', 'Alpha')]), ['A_1']),
          _code(forms.isEmpty ? 'pbs_identity' : 'source_form_name'));
    }
    final source = await _source(rows, forms: '[A,1]\nFormName = Variant\n');
    for (final catalog in [
      _catalog([_native('alpha', 'Alpha')]),
      _catalog([
        _native('alpha', 'Alpha'),
        _native('alpha_form1', 'Alpha', base: 'alpha', form: 1, label: 'Wrong')
      ]),
      _catalog([
        _native('alpha', 'Alpha'),
        _native('alpha_form7', 'Alpha',
            base: 'alpha', form: 7, label: 'Variant'),
        _native('alpha_form8', 'Alpha',
            base: 'alpha', form: 8, label: 'Alpha Variant')
      ]),
    ]) {
      await expectLater(
          _bind(source, catalog, ['A_1']), _code('native_form_identity'));
    }
  });

  test('rejects repeated authored FormName instead of using the last value',
      () async {
    final source = await _source(const [
      _Record('A', 'A', 'Alpha'),
      _Record('A_1', 'A', 'Alpha', form: 1, formName: 'Variant'),
    ], forms: '[A,1]\nFormName = Variant\nFormName = Variant\n');
    final catalog = _catalog([
      _native('alpha', 'Alpha'),
      _native('alpha_form9', 'Alpha', base: 'alpha', form: 9, label: 'Variant'),
    ]);
    await expectLater(
        _bind(source, catalog, ['A_1']), _code('source_form_name'));
  });

  test('checks cancellation before reading and after an asynchronous read',
      () async {
    final source = await _source(const [_Record('A', 'A', 'Alpha')]);
    final catalog = _catalog([_native('alpha', 'Alpha')]);
    final cancellation = ScanCancellation()..cancel();
    source.fixture.files.reads.clear();
    await expectLater(
        _bind(source, catalog, ['A'], cancellation: cancellation),
        throwsA(isA<ContractError>()
            .having((e) => e.code, 'code', 'source.cancelled')));
    expect(source.fixture.files.reads, isEmpty);
    final duringRead = ScanCancellation();
    source.fixture.files.onRead = (_) => duringRead.cancel();
    await expectLater(
        _bind(source, catalog, ['A'], cancellation: duringRead),
        throwsA(isA<ContractError>()
            .having((e) => e.code, 'code', 'source.cancelled')));
  });

  test('rejects catalog mutation during reads for single and composed catalogs',
      () async {
    for (final composite in [false, true]) {
      final source = await _source(const [_Record('A', 'A', 'Alpha')]);
      final shard = _catalog([_native('alpha', 'Alpha')]);
      final NativePsdkCatalog catalog =
          composite ? NativePsdkCatalogManifest.compose([shard]) : shard;
      source.fixture.files.onRead =
          (_) => catalog.speciesById['alpha']!.names['en'] = 'Mutated';
      await expectLater(
          _bind(source, catalog, ['A']), _code('catalog_integrity'));
    }
  });

  final giftArchive = Platform.environment['AVELUNE_GIFT_SCRIPT_ARCHIVE'];
  group('literal gift complete native binding', () {
    late ({LiteralTileFixture fixture, SourcePbsProject pbs}) source;
    late SourceEventAnalysis analysis;
    late SourceEventDefinition event;
    late NativePsdkTrainerBundle catalog;
    late SourcePokemonGiftBindings bindings;
    Future<({LiteralTileFixture fixture, SourcePbsProject pbs})> fixture(
            {bool extraPage = false,
            bool badSuffix = false,
            int mapId = 17}) async =>
        _source(
          const [_Record('CLOCKBIRD', 'CLOCKBIRD', 'Clockbird')],
          scriptsBytes: await File(giftArchive!).readAsBytes(),
          maps: [
            LiteralFixtureMap(id: mapId, events: [
              LiteralFixtureEvent(id: 9, x: 1, y: 0, pages: [
                LiteralFixtureEventPage(characterName: 'Original', commands: [
                  const LiteralFixtureEventCommand(101, ['Before']),
                  const LiteralFixtureEventCommand(
                      355, ['pbAddPokemon(:CLOCKBIRD,7)']),
                  const LiteralFixtureEventCommand(123, ['A', 0]),
                  if (badSuffix)
                    const LiteralFixtureEventCommand(355, ['danger()']),
                ]),
                const LiteralFixtureEventPage(
                    characterName: 'Original',
                    selfSwitch: 'A',
                    commands: [
                      LiteralFixtureEventCommand(101, ['After'])
                    ]),
                if (extraPage)
                  const LiteralFixtureEventPage(
                      characterName: 'Original',
                      selfSwitch: 'B',
                      commands: [
                        LiteralFixtureEventCommand(355, ['danger()'])
                      ]),
              ])
            ])
          ],
        );
    setUpAll(() async {
      source = await fixture();
      analysis = SourceEventAnalyzer.forProject(source.fixture.source,
              profile:
                  SourceEventProfile.forProject(source.fixture.source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      event = analysis.eventAt(17, 9)!;
      catalog = _catalog([_native('clockbird', 'Clockbird')]);
      bindings = await const SourcePokemonGiftBindingResolver().read(
          source: source.fixture.source,
          analysis: analysis,
          files: source.fixture.files,
          nativeCatalog: catalog);
    });
    test(
        'binds whole raw two-page stationary event independent of map and species',
        () async {
      expect(event.isQuarantined, false);
      final binding = bindings.byEventIdentity[event.identity.value]!;
      expect(binding.nativeSpeciesId, 'clockbird');
      expect(binding.nativeFormId, '0');
      expect(binding.program.level, 7);
      expect(
          binding.isBoundToEvent(
              source: source.fixture.source, analysis: analysis, event: event),
          true);
      expect(binding.evidence['sourceScriptsExecuted'], 0);
      expect(
          (binding.evidence['presentationAdaptation']
              as Map)['sourceDexFlagsMapped'],
          false);
      final other = await fixture(mapId: 59);
      final otherAnalysis = SourceEventAnalyzer.forProject(other.fixture.source,
              profile: SourceEventProfile.forProject(other.fixture.source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      final otherBindings = await const SourcePokemonGiftBindingResolver().read(
          source: other.fixture.source,
          analysis: otherAnalysis,
          files: other.fixture.files,
          nativeCatalog: catalog);
      expect(otherBindings.byEventIdentity, hasLength(1));
      expect(
          binding.isBoundToEvent(
              source: other.fixture.source,
              analysis: otherAnalysis,
              event: otherAnalysis.eventAt(59, 9)!),
          false);
    });
    test('never partially admits an unsupported suffix or a third page',
        () async {
      for (final variant in [
        await fixture(extraPage: true),
        await fixture(badSuffix: true)
      ]) {
        final a = SourceEventAnalyzer.forProject(variant.fixture.source,
                profile:
                    SourceEventProfile.forProject(variant.fixture.source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
            .analyze();
        final result = await const SourcePokemonGiftBindingResolver().read(
            source: variant.fixture.source,
            analysis: a,
            files: variant.fixture.files,
            nativeCatalog: catalog);
        expect(result.byEventIdentity, isEmpty);
        expect(a.eventAt(17, 9)!.isQuarantined, true);
      }
    });
    test('refuses missing native catalogue and changed helper source bytes',
        () async {
      final missing = await const SourcePokemonGiftBindingResolver().read(
          source: source.fixture.source,
          analysis: analysis,
          files: source.fixture.files);
      expect(missing.byEventIdentity, isEmpty);
      expect(missing.refusals, isNotEmpty);
      source.fixture.files.overrides['Data/Scripts.rxdata'] = [4, 8, 48];
      try {
        final changed = await const SourcePokemonGiftBindingResolver().read(
            source: source.fixture.source,
            analysis: analysis,
            files: source.fixture.files,
            nativeCatalog: catalog);
        expect(changed.byEventIdentity, isEmpty);
        expect(changed.refusals, isNotEmpty);
      } finally {
        source.fixture.files.overrides.clear();
      }
    });
    test('rejects forged event and stale profile even with a genuine gift node',
        () {
      final binding = bindings.byEventIdentity[event.identity.value]!;
      final forged = SourceEventDefinition(
          sourceMapId: event.sourceMapId,
          sourceEventId: event.sourceEventId,
          sourceFileId: event.sourceFileId,
          identity: event.identity,
          name: 'Forged',
          x: event.x,
          y: event.y,
          locator: event.locator,
          pages: event.pages);
      expect(
          binding.isBoundToEvent(
              source: source.fixture.source, analysis: analysis, event: forged),
          false);
      final page = event.pages.first;
      final wrongRawPage = SourceEventPageAnalysis(
          sourcePage: page.sourcePage,
          locator: page.locator,
          condition: page.condition,
          graphic: page.graphic,
          body: page.body,
          rawDataRef: event.pages.last.rawDataRef,
          diagnostics: page.diagnostics);
      final wrongRawEvent = SourceEventDefinition(
          sourceMapId: event.sourceMapId,
          sourceEventId: event.sourceEventId,
          sourceFileId: event.sourceFileId,
          identity: event.identity,
          name: event.name,
          x: event.x,
          y: event.y,
          locator: event.locator,
          pages: [wrongRawPage, event.pages.last]);
      expect(
          binding.isBoundToEvent(
              source: source.fixture.source,
              analysis: analysis,
              event: wrongRawEvent),
          false);
      final stale = SourceEventAnalysis(
          profile: SourceEventProfile(
              scriptsArchiveHash: analysis.profile.scriptsArchiveHash,
              sourceSnapshotHash: Sha256Hash('f' * 64),
              normalizationHash: source.fixture.source.canonicalHash,
interpretationProfile: fixtureSourceInterpretationProfile,
),
          events: [event],
          diagnostics: []);
      expect(
          binding.isBoundToEvent(
              source: source.fixture.source, analysis: stale, event: event),
          false);
    });

    test(
        'refuses native gift without default moves and protects evidence from aliases',
        () async {
      final raw = (jsonDecode(jsonEncode(catalog.toJson())) as Map)
          .cast<String, dynamic>();
      for (final row in (raw['sourceLearnsets'] as List).cast<Map>()) {
        row['startingMoves'] = [];
        row['relearnMoves'] = [];
        row['levelUp'] = [];
      }
      final empty = NativePsdkTrainerBundle.fromJson(raw);
      final result = await const SourcePokemonGiftBindingResolver().read(
          source: source.fixture.source,
          analysis: analysis,
          files: source.fixture.files,
          nativeCatalog: empty);
      expect(result.byEventIdentity, isEmpty);
      expect(result.refusals.values,
          contains('sourcePokemonGiftNativeMovesUnqualified'));
      final binding = bindings.byEventIdentity[event.identity.value]!;
      (binding.evidence['presentationAdaptation']
          as Map)['sourcePresentationParity'] = true;
      expect(
          (binding.evidence['presentationAdaptation']
              as Map)['sourcePresentationParity'],
          false);
    });
    test('gift catalogue publishes without native encounter activation',
        () async {
      final literal = await const LiteralTileComposer().compose(
          source: source.fixture.source,
          files: source.fixture.files,
          selectedSourceMapIds: [17],
          projectName: 'Gift only',
          parentPath: '/unused',
          folderName: 'gift');
      final semantic = (await const SourceSemanticStudyComposer().compose(
          source: source.fixture.source,
          base: literal,
          files: source.fixture.files))!;
      final composed =
          (await SourceEventStudyComposer(nativeTrainerCatalog: catalog)
              .compose(
                  source: source.fixture.source,
                  base: semantic,
                  files: source.fixture.files))!;
      expect(composed.projection.semanticEvidence['usedPokemonGifts'], true);
      final complete = (await SourceCatalogStudyComposer(
              automaticNativeEncounters: false,
              nativeTrainerCatalog: composed.pokemonGiftCatalog)
          .compose(
              source: source.fixture.source,
              base: composed.draft,
              files: source.fixture.files))!;
      expect(
          complete.draft.mutations.any((m) =>
              m.actionId == 'pokemon.configuration.set_enabled' &&
              m.parameters['enabled'] == true),
          true);
      expect(
          complete.draft.mutations
              .where((m) => m.actionId == 'pokemon.documents.write')
              .expand((m) => (m.parameters['documents'] as List).cast<Map>())
              .any((d) =>
                  d['actionId'] == 'pokemon.species.write' &&
                  (d['parameters'] as Map)['relativePath'] ==
                      'data/pokemon/species/clockbird.json'),
          true);
    });
    test('catalogue publication rejects a different native gift catalogue',
        () async {
      final literal = await const LiteralTileComposer().compose(
          source: source.fixture.source,
          files: source.fixture.files,
          selectedSourceMapIds: [17],
          projectName: 'Gift only',
          parentPath: '/unused',
          folderName: 'gift');
      final semantic = (await const SourceSemanticStudyComposer().compose(
          source: source.fixture.source,
          base: literal,
          files: source.fixture.files))!;
      final composed =
          (await SourceEventStudyComposer(nativeTrainerCatalog: catalog)
              .compose(
                  source: source.fixture.source,
                  base: semantic,
                  files: source.fixture.files))!;
      await expectLater(
          SourceCatalogStudyComposer(
                  automaticNativeEncounters: false,
                  nativeTrainerCatalog: _catalog([_native('other', 'Other')]))
              .compose(
                  source: source.fixture.source,
                  base: composed.draft,
                  files: source.fixture.files),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'catalogs.pokemon_gift.binding')));
    });
    test(
        'canonical composition typed write and strict reopen preserve both pages and gift',
        () async {
      final output =
          await Directory.systemTemp.createTemp('source-gift-writer-');
      addTearDown(() => output.delete(recursive: true));
      final literal = await const LiteralTileComposer().compose(
          source: source.fixture.source,
          files: source.fixture.files,
          selectedSourceMapIds: [17],
          projectName: 'Gift writer',
          parentPath: output.path,
          folderName: 'gift');
      final semantic = (await const SourceSemanticStudyComposer().compose(
          source: source.fixture.source,
          base: literal,
          files: source.fixture.files))!;
      final qualification = await NativeEncounterCatalogQualification.prepare(
          snapshot: source.fixture.snapshot,
          source: source.pbs,
          files: source.fixture.files,
          nativeCatalog: catalog,
          selectedSourceMapIds: [17]);
      final composed = (await SourceEventStudyComposer(
              nativeEncounterQualification: qualification)
          .compose(
              source: source.fixture.source,
              base: semantic,
              files: source.fixture.files))!;
      expect(composed.projection.semanticEvidence['usedPokemonGifts'], true);
      expect(canonicalHashOf(composed.pokemonGiftCatalog!.toJson()),
          canonicalHashOf(qualification.bundle.toJson()));
      final complete = (await SourceCatalogStudyComposer(
              nativeEncounterQualification: qualification,
              nativeTrainerCatalog: composed.pokemonGiftCatalog)
          .compose(
              source: source.fixture.source,
              base: composed.draft,
              files: source.fixture.files))!;
      final giftPublication = complete.draft.mutations.indexWhere((m) =>
          m.actionId == 'scene.upsert' &&
          jsonEncode(m.parameters).contains('receivePokemonFromCatalog'));
      final activation = complete.draft.mutations.indexWhere((m) =>
          m.actionId == 'pokemon.configuration.set_enabled' &&
          m.parameters['enabled'] == true);
      expect(giftPublication, greaterThanOrEqualTo(0));
      expect(activation, inInclusiveRange(0, giftPublication - 1),
          reason:
              'Catalogue activation must precede canonical gift Scene publication');
      final changedScene = (jsonDecode(jsonEncode(
              complete.draft.mutations[giftPublication].parameters)) as Map)
          .cast<String, Object?>();
      void alterGift(Object? value) {
        if (value is Map) {
          if (value['kind'] == 'receivePokemonFromCatalog') value['level'] = 8;
          for (final child in value.values) {
            alterGift(child);
          }
        } else if (value is List) {
          for (final child in value) {
            alterGift(child);
          }
        }
      }

      alterGift(changedScene);
      final draft = complete.draft;
      final altered = NativeProjectDraft(
          source: draft.source,
          projectName: draft.projectName,
          parentPath: draft.parentPath,
          folderName: draft.folderName,
          sourceRootPath: draft.sourceRootPath,
          mapIds: draft.mapIds,
          artifacts: draft.artifacts,
          sourceArtifacts: draft.sourceArtifacts,
          mutations: [
            for (var i = 0; i < draft.mutations.length; i++)
              i == giftPublication
                  ? copyNativeFixtureMutation(draft.mutations[i],
                      parameters: changedScene)
                  : draft.mutations[i]
          ],
          compositionEvidence: draft.compositionEvidence,
          defaultMapWidth: draft.defaultMapWidth,
          defaultMapHeight: draft.defaultMapHeight);
      final rejected = approveNativeFixtureDraft(altered);
      await expectLater(
          NativeProjectWriter().write(rejected.plan, rejected.context, altered),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'native.semantics.regeneration')));
      expect(await Directory('${output.path}/gift').exists(), false);
      final approval = approveNativeFixtureDraft(complete.draft);
      final receipt = await NativeProjectWriter()
          .write(approval.plan, approval.context, complete.draft);
      expect(receipt.verified, true);
      final handles = WorkspaceHandleStore();
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(receipt.projectPath);
      try {
        final reopened = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        expect(reopened.loadDiagnostics, isEmpty);
        final gifts = reopened.manifest.scenes
            .expand((s) => s.graph.nodes)
            .map((n) => n.payload)
            .whereType<SceneActionPayload>()
            .map((p) => p.interactiveCommand)
            .whereType<SceneReceivePokemonFromCatalogInteractiveCommand>()
            .toList();
        expect(gifts, hasLength(1));
        expect(gifts.single.speciesId, 'clockbird');
        expect(gifts.single.nicknameMaxGraphemes, 10);
        expect(
            reopened.manifest.eventRegistry!.records
                .where((r) => r.definitionOrNull != null),
            hasLength(2));
        expect(
            await File(
                    '${receipt.projectPath}/data/pokemon/species/clockbird.json')
                .exists(),
            true);
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
    });
    test('projection joins all three ports to the source self-switch suffix',
        () {
      final map = MapData(
          id: 'native-17',
          name: 'Native',
          size: const GridSize(width: 3, height: 1),
          layers: [
            MapLayer.collision(
                id: 'base', name: 'Base', collisions: [false, false, false])
          ]);
      final file = source.fixture.snapshot.entries.singleWhere(
          (e) => e.relativePath == 'Graphics/Characters/Original.png');
      final characters = {
        sourceEventCharacterBindingKey(
                characterName: 'Original', pattern: 0, direction: 2):
            SourceEventCharacterBinding(
                characterId: 'native-original',
                sourceSnapshotHash: source.fixture.snapshot.canonicalHash,
                sourceFileId: file.fileId,
                sourceFileHash: file.sha256!,
                sourcePattern: 0,
                sourceDirection: 2)
      };
      final projected = const SourceEventProjector().project(
          source: source.fixture.source,
          analysis: analysis,
          nativeMaps: {17: map},
          characterBindings: characters,
          pokemonGiftBindings: bindings.byEventIdentity);
      expect(projected.scenes, hasLength(2),
          reason: '${projected.semanticEvidence}');
      final scene = projected.scenes.singleWhere((s) => s.graph.nodes.any((n) =>
          n.payload is SceneActionPayload &&
          (n.payload as SceneActionPayload).interactiveCommand
              is SceneReceivePokemonFromCatalogInteractiveCommand));
      final node = scene.graph.nodes.singleWhere((n) =>
          n.payload is SceneActionPayload &&
          (n.payload as SceneActionPayload).interactiveCommand
              is SceneReceivePokemonFromCatalogInteractiveCommand);
      final command = (node.payload as SceneActionPayload).interactiveCommand!
          as SceneReceivePokemonFromCatalogInteractiveCommand;
      expect(command.nicknameMaxGraphemes, 10);
      expect(command.nicknamePolicy, ScenePokemonGiftNicknamePolicy.offer);
      final destinations =
          scene.graph.edges.where((e) => e.fromNodeId == node.id).toList();
      expect(destinations.map((e) => e.fromPortId).toSet(),
          {'party', 'pc', 'noCapacity'});
      expect(destinations.map((e) => e.toNodeId).toSet(), hasLength(1));
      final suffix = scene.graph.nodes
          .singleWhere((n) => n.id == destinations.first.toNodeId);
      final write = (suffix.payload as SceneActionPayload).consequence!
          as SceneSetFactConsequence;
      expect(projected.facts.map((fact) => fact.id), contains(write.factId));
      expect(write.value, true);
      final unbound = const SourceEventProjector().project(
          source: source.fixture.source,
          analysis: analysis,
          nativeMaps: {17: map},
          characterBindings: characters);
      expect(unbound.scenes, isEmpty);
    });
  },
      skip: giftArchive == null
          ? 'Exact source Scripts.rxdata oracle required'
          : false);
}
