import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

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
    List<int>? compiled}) async {
  final fixture = await LiteralTileFixture.create(extraFiles: {
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
}
