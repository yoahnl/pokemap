import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

Sha256Hash _hash(List<int> bytes) =>
    Sha256Hash(crypto.sha256.convert(bytes).toString());

final class _Files implements SourceFilePort {
  _Files(Map<String, List<int>> input,
      {String version = '21.1',
      SourceScanState state = SourceScanState.complete})
      : bytes = Map.of(input) {
    bytes['README.txt'] = utf8.encode('Pokemon Essentials v$version');
    snapshot = SourceSnapshot(
      logicalProjectNamespace: ConverterId('pbs-fixture'),
      policyHash: _hash([1, 2, 3]),
      entries: [
        for (final entry in bytes.entries)
          SourceFileEntry(
            fileId: ConverterId('file-${_hash(utf8.encode(entry.key)).value}'),
            relativePath: entry.key,
            kind: SourceNodeKind.file,
            byteLength: entry.value.length,
            sha256: _hash(entry.value),
            format: 'text',
            family: 'pbs',
          ),
      ],
      diagnostics: [],
      excludedPaths: [],
      profileEvidence: [
        SourceProfileEvidence(
          relativePath: 'README.txt',
          fileHash: _hash(bytes['README.txt']!),
          version: version,
          line: 1,
          excerpt: 'Pokemon Essentials v$version',
        ),
      ],
      state: state,
    );
  }
  final Map<String, List<int>> bytes;
  late final SourceSnapshot snapshot;
  final reads = <String>[];
  final replacements = <String, List<int>>{};
  void Function()? afterRead;
  @override
  Future<List<int>> read(ConverterId id) async {
    final file = snapshot.entries.singleWhere((entry) => entry.fileId == id);
    reads.add(file.relativePath);
    afterRead?.call();
    return replacements[file.relativePath] ?? bytes[file.relativePath]!;
  }
}

_Files _text(Map<String, String> files, {String version = '21.1'}) => _Files(
    {for (final entry in files.entries) entry.key: utf8.encode(entry.value)},
    version: version);

Future<SourcePbsProject> _read(_Files files,
        {SourcePbsLimits limits = const SourcePbsLimits(),
        Set<SourcePbsFamily>? families,
        ScanCancellation? cancellation}) =>
    const SourcePbsParser().read(
      snapshot: files.snapshot,
      files: files,
      limits: limits,
      cancellation: cancellation,
      families: families ?? SourcePbsFamily.values.toSet(),
    );

Matcher _contract(String code) =>
    isA<ContractError>().having((error) => error.code, 'code', code);

void main() {
  test('PBS01 preserves BOM CRLF comments q values unknown fields and locators',
      () async {
    final text = '\uFEFF# Essentials PBS\r\n'
        ' [POTION] # identité\r\n'
        ' Name = "Potion, petite"\r\n'
        ' Description = "Texte, brut" # commentaire\r\n'
        ' FutureRule = a, "b,c" # inconnu\r\n'
        ' Description = "Hash # dans texte"\r\n';
    final files = _text({'PBS/items.txt': text});
    final result = await _read(files);
    final entry = result.entries.single;
    expect(entry.header, 'POTION');
    expect(entry.headerLocator.file, 'PBS/items.txt');
    expect(entry.headerLocator.line, 2);
    expect(entry.field('Name')!.values, ['"Potion, petite"']);
    expect(entry.fieldsNamed('Description').first.values, ['"Texte, brut"']);
    expect(entry.field('Description')!.values, ['"Hash']);
    expect(entry.field('FutureRule')!.isKnown, isFalse);
    expect(entry.field('FutureRule')!.rawValue, 'a, "b,c"');
    expect(entry.field('FutureRule')!.locator.line, 5);
    expect(entry.field('FutureRule')!.rawLine, contains('# inconnu'));
    expect(result.documents.single.rawBytes, utf8.encode(text));
    expect(result.documents.single.rawLines.first, startsWith('\uFEFF'));
    expect(result.diagnostics.where((item) => item.blocking), isEmpty);
    expect(result.diagnostics.map((item) => item.code),
        contains('pbs.unknown_field'));
  });

  test('21.1 tokenization retains ordinary quotes and literal escape quirks',
      () async {
    final result = await _read(_text({
      'PBS/items.txt': '[POTION]\n'
          'Flags = "A,B", C\n'
          'Flags = \\"A\\", B\n'
          'Flags = \\"A,B\\"\n'
          'Name = \\"Solo\\"\n',
    }));
    final entry = result.entries.single;
    expect(entry.fieldsNamed('Flags')[0].values, ['"A,B"', 'C']);
    expect(entry.fieldsNamed('Flags')[1].values, ['A', 'B']);
    expect(entry.fieldsNamed('Flags')[2].values, ['\\"A,B\\"']);
    expect(entry.field('Name')!.values, ['\\"Solo\\"']);
  });

  test('root suffix matching uses longest base and ignores nested backups',
      () async {
    final files = _text({
      'PBS/pokemon.txt': '[ONE]\nName = Same\n',
      'PBS/pokemon_forms_pack.txt': '[ONE,2]\nFormName = Same\n',
      'PBS/pokemon_pack.txt': '[TWO]\nName = Same\n',
      'PBS/pokemon_metrics.txt': '[ONE]\nBackSprite = 1,2\n',
      'PBS/pokemon_metrics_forms.txt': '[ONE,2]\nBackSprite = 3,4\n',
      'PBS/Gen9 backup/pokemon.txt': '[SHADOW]\n',
      'PBS/Plugins/items_pack.txt': '[OTHER]\n',
      'PBS/notes.txt': '[NOTE]\n',
    });
    final result = await _read(files);
    expect(result.documents.map((document) => document.family), [
      SourcePbsFamily.species,
      SourcePbsFamily.forms,
      SourcePbsFamily.species
    ]);
    expect(result.documents.map((document) => document.suffix),
        ['', 'pack', 'pack']);
    expect(result.entries.map((entry) => entry.identity!.sourceSymbol),
        ['ONE', 'ONE', 'TWO']);
    expect(files.reads, [
      'PBS/pokemon.txt',
      'PBS/pokemon_forms_pack.txt',
      'PBS/pokemon_pack.txt'
    ]);
  });

  test(
      'PBS02 identities distinguish symbols forms trainer versions and map versions',
      () async {
    final files = _text({
      'PBS/pokemon.txt': '[ONE]\nName = Identique\n[TWO]\nName = Identique\n',
      'PBS/pokemon_forms.txt':
          '[ONE,1]\nFormName = Identique\n[ONE,2]\nFormName = Identique\n',
      'PBS/trainers.txt':
          '[RIVAL,Blue]\nPokemon = ONE,5\n[RIVAL,Blue,1]\nPokemon = TWO,5\n',
      'PBS/encounters.txt':
          '[098]\nLand,11\n100,ONE,5\n[098,1]\nLand,11\n100,TWO,5\n',
    });
    final result = await _read(files);
    expect(
        result.entries.map((entry) => entry.identity!.key).toSet().length, 8);
    final identity = SourcePbsIdentity(
      namespace: files.snapshot.logicalProjectNamespace,
      family: SourcePbsFamily.forms,
      sourceSymbol: 'ONE',
      form: 2,
    );
    expect(result.lookup(identity)!.identity!.family, SourcePbsFamily.species);
    expect(result.lookup(identity)!.field('FormName')!.values, ['Identique']);
    expect(
        result.entries
            .where((entry) => entry.family == SourcePbsFamily.species)
            .every((entry) => entry.field('NationalDex') == null),
        isTrue);
  });

  test('trainer Pokemon repeats keep their own ordered subfields', () async {
    final result = await _read(_text({
      'PBS/trainers.txt': '[RIVAL,Blue,2]\nItems = POTION\n'
          'Pokemon = ONE,5\n Moves = A,B\n Name = Premier\n'
          'Pokemon = TWO,8\n Moves = C\n Form = 2\n'
          'LoseText = "Moi, jamais!"\n',
    }));
    final entry = result.entries.single;
    expect(entry.party.length, 2);
    expect(entry.party[0].headerField.values, ['ONE', '5']);
    expect(entry.party[0].field('Moves')!.values, ['A', 'B']);
    expect(entry.party[1].field('Moves')!.values, ['C']);
    expect(entry.party[1].field('Form')!.values, ['2']);
    expect(entry.party[0].field('Form'), isNull);
    expect(entry.field('LoseText')!.values, ['"Moi, jamais!"']);
    expect(entry.isBlocked, isFalse);
  });

  test('repeated schema permits the missing trailing string accepted by 21.1',
      () async {
    final files = _text({
      'PBS/pokemon.txt': '[BAT]\nEvolutions = CROBAT,Happiness,\n'
          'Moves = 1,A,2\n',
    });
    final result = await _read(files);
    final failures = result.diagnostics.where((item) => item.blocking).toList();
    expect(failures.length, 1);
    expect(failures.single.locator.line, 3);
    expect(result.entries.single.field('Evolutions')!.values,
        ['CROBAT', 'Happiness']);
  });

  test('encounter methods repeats and slots preserve order and optional max',
      () async {
    final result = await _read(_text({
      'PBS/encounters.txt': '[098]\nLand,11\n60,ONE,5,7\n40,TWO,8\n'
          'OldRod\n100,ONE,5\nLand,20\n100,TWO,9\n',
    }));
    final methods = result.entries.single.methods;
    expect(methods.map((method) => method.name), ['Land', 'OldRod', 'Land']);
    expect(methods.map((method) => method.stepChance), [11, null, 20]);
    expect(methods[0].slots.map((slot) => slot.species), ['ONE', 'TWO']);
    expect(methods[0].slots[1].maximumLevel, 8);
    expect(methods[1].slots.single.locator.line, 6);
  });

  test(
      'duplicate identities block every definition and lookup never chooses a winner',
      () async {
    final files = _text({
      'PBS/items.txt': '[POTION]\nName = A\n',
      'PBS/items_pack.txt': '[POTION]\nName = B\n',
    });
    final result = await _read(files);
    final identity = result.entries.first.identity!;
    expect(result.entries.every((entry) => entry.isBlocked), isTrue);
    expect(result.lookup(identity), isNull);
    expect(
        result.diagnostics
            .where((item) => item.code == 'pbs.duplicate_identity')
            .length,
        2);
    expect(
        result.documents.map((document) => document.rawBytes),
        files.bytes.entries
            .where((entry) => entry.key.startsWith('PBS/'))
            .map((entry) => entry.value));
  });

  test(
      'malformed records remain preserved and diagnostics identify their lines',
      () async {
    final result = await _read(_text({
      'PBS/trainers.txt':
          'Moves = A\n[RIVAL,Blue]\nMoves = A\nPokemon = ONE,0\n',
      'PBS/pokemon_forms.txt': '[ONE,0]\nBaseStats = 1,2,3\ninvalid line\n',
      'PBS/encounters.txt': '[098]\n100,ONE,5\nLand\n100,ONE,8,5\n',
    }));
    expect(result.entries.every((entry) => entry.isBlocked), isTrue);
    expect(
        result.diagnostics
            .where((item) => item.blocking)
            .map((item) => item.code),
        containsAll([
          'pbs.before_section',
          'pbs.trainer_scope',
          'pbs.field_value',
          'pbs.header',
          'pbs.syntax',
          'pbs.encounter_scope',
          'pbs.encounter_level'
        ]));
    expect(result.documents.every((document) => document.rawBytes.isNotEmpty),
        isTrue);
    expect(result.diagnostics.every((item) => item.locator.line! > 0), isTrue);
  });

  test(
      'invalid UTF8 is preserved as an unavailable document without replacement characters',
      () async {
    final files = _Files({
      'PBS/items.txt': [0xff, 0x5b, 0x41, 0x5d]
    });
    final result = await _read(files);
    expect(result.documents.single.rawBytes, [0xff, 0x5b, 0x41, 0x5d]);
    expect(result.documents.single.rawLines, isEmpty);
    expect(result.entries, isEmpty);
    expect(result.diagnostics.single.code, 'pbs.encoding');
    expect(result.diagnostics.single.blocking, isTrue);
  });

  test('the explicit grammar profile is separate from source scan evidence',
      () async {
    final result =
        await _read(_text({'PBS/items.txt': '[A]\n'}, version: '20.1'));
    expect(result.profile, SourcePbsProfile.essentials21_1);
    expect(result.entries.single.identity!.sourceSymbol, 'A');
  });

  test('an incomplete source inventory cannot produce a parsed project',
      () async {
    final files = _Files({'PBS/items.txt': utf8.encode('[A]\n')},
        state: SourceScanState.partial);
    expect(_read(files), throwsA(_contract('pbs.snapshot')));
  });

  test(
      'selected families avoid unrelated reads and empty selection is deterministic',
      () async {
    final files = _text({'PBS/items.txt': '[A]\n', 'PBS/moves.txt': '[B]\n'});
    final result = await _read(files, families: {SourcePbsFamily.items});
    expect(result.entries.single.family, SourcePbsFamily.items);
    expect(files.reads, ['PBS/items.txt']);
    final empty = await _read(files, families: {});
    expect(empty.documents, isEmpty);
  });

  test('source hash changes throw globally rather than publishing stale data',
      () async {
    final files = _text({'PBS/items.txt': '[A]\n'});
    files.replacements['PBS/items.txt'] = utf8.encode('[B]\n');
    expect(_read(files), throwsA(_contract('pbs.source_changed')));
  });

  test('all collection and byte quotas are cumulative across documents',
      () async {
    final files = _text({
      'PBS/items.txt': '[A]\nName = a,b\n',
      'PBS/items_more.txt': '[B]\nName = c,d\n'
    });
    for (final limits in [
      const SourcePbsLimits(maxDocuments: 1),
      const SourcePbsLimits(maxFileBytes: 2),
      const SourcePbsLimits(maxTotalBytes: 20),
      const SourcePbsLimits(maxLines: 3),
      const SourcePbsLimits(maxLineCodeUnits: 3),
      const SourcePbsLimits(maxEntries: 1),
      const SourcePbsLimits(maxFields: 1),
      const SourcePbsLimits(maxTokens: 3),
    ]) {
      await expectLater(
          _read(files, limits: limits), throwsA(_contract('pbs.quota')));
    }
    expect(_read(files, limits: const SourcePbsLimits(maxLines: 0)),
        throwsA(_contract('pbs.limits')));
    final unknown = _text({'PBS/items.txt': '[A]\nX = 1\nY = 2\n'});
    expect(_read(unknown, limits: const SourcePbsLimits(maxDiagnostics: 1)),
        throwsA(_contract('pbs.quota')));
  });

  test('cancellation after source read produces no project', () async {
    final files = _text({'PBS/items.txt': '[A]\nName = A\n'});
    final cancel = ScanCancellation();
    files.afterRead = cancel.cancel;
    expect(_read(files, cancellation: cancel),
        throwsA(_contract('source.cancelled')));
  });

  test('raw buffers and all nested collections are immutable and hash stable',
      () async {
    final files = _text({'PBS/items.txt': '[A]\nName = Same\n'});
    final first = await _read(files);
    final second = await _read(files);
    expect(first.canonicalHash, second.canonicalHash);
    expect(
        () => first.documents.single.rawBytes[0] = 0, throwsUnsupportedError);
    expect(
        () => first.documents.single.rawLines.clear(), throwsUnsupportedError);
    expect(() => first.entries.single.field('Name')!.values.add('new'),
        throwsUnsupportedError);
    expect(() => first.entries.clear(), throwsUnsupportedError);
    files.bytes['PBS/items.txt']![0] = 0;
    expect(first.canonicalHash, second.canonicalHash);
  });

  test('item binding identity exactly reuses the AC13 source item namespace',
      () async {
    final namespace = ConverterId('pbs-fixture');
    final expected = 'source-item-${canonicalHashOf({
          'namespace': namespace.value,
          'sourceSymbol': 'BURNHEAL',
        }).value.substring(0, 24)}';
    expect(sourcePbsItemBindingId(namespace, 'BURNHEAL').value, expected);
    expect(
        sourcePbsItemBindingId(namespace, 'burnheal').value, isNot(expected));
  });
}
