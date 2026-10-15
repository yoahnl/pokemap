import 'dart:convert';
import 'package:avelune_converter_adapters/src/source_event_item_bindings.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

final class _Symbol {
  const _Symbol(this.value);
  final String value;
}

final class _Object {
  const _Object(this.className, this.fields);
  final String className;
  final Map<String, Object?> fields;
}

List<int> _packed(int value) {
  if (value == 0) return [0];
  if (value > 0 && value < 123) return [value + 5];
  if (value < 0 && value > -124) return [(value - 5) & 255];
  var width = 1;
  while (value >= (1 << (width * 8)) || value < -(1 << (width * 8))) {
    width++;
  }
  return [
    value >= 0 ? width : (-width) & 255,
    for (var i = 0; i < width; i++) (value >> (i * 8)) & 255
  ];
}

List<int> _value(Object? v) {
  if (v == null) return [0x30];
  if (v is bool) return [v ? 0x54 : 0x46];
  if (v is int) return [0x69, ..._packed(v)];
  if (v is _Symbol) {
    final s = utf8.encode(v.value);
    return [0x3a, ..._packed(s.length), ...s];
  }
  if (v is String) {
    final s = utf8.encode(v);
    return [0x22, ..._packed(s.length), ...s];
  }
  if (v is List) {
    return [0x5b, ..._packed(v.length), for (final x in v) ..._value(x)];
  }
  if (v is Map) {
    return [
      0x7b,
      ..._packed(v.length),
      for (final p in v.entries) ...[..._value(p.key), ..._value(p.value)]
    ];
  }
  if (v is _Object) {
    return [
      0x6f,
      ..._value(_Symbol(v.className)),
      ..._packed(v.fields.length),
      for (final p in v.fields.entries) ...[
        ..._value(_Symbol(p.key)),
        ..._value(p.value)
      ]
    ];
  }
  throw StateError('$v');
}

Map<String, Object?> _item(String symbol,
        {Map<String, Object?> patch = const {}}) =>
    {
      '@id': _Symbol(symbol),
      '@real_name': symbol == 'BURNHEAL'
          ? 'Burn Heal'
          : symbol == 'ETHER'
              ? 'Ether'
              : symbol,
      '@real_name_plural': symbol == 'BURNHEAL'
          ? 'Burn Heals'
          : symbol == 'ETHER'
              ? 'Ethers'
              : '${symbol}s',
      '@real_portion_name': null,
      '@real_portion_name_plural': null,
      '@pocket': 2,
      '@price': symbol == 'BURNHEAL' ? 200 : 600,
      '@sell_price': symbol == 'BURNHEAL' ? 50 : 300,
      '@bp_price': 1,
      '@field_use': 1,
      '@battle_use': symbol == 'ETHER' ? 2 : 1,
      '@flags': ['Fling_30'],
      '@consumable': true,
      '@show_quantity': null,
      '@move': null,
      '@real_description': 'Source description',
      '@pbs_file_suffix': '',
      ...patch
    };

final class _Files implements SourceFilePort {
  _Files(this.bytes);
  final Map<ConverterId, List<int>> bytes;
  final reads = <ConverterId>[];
  @override
  Future<List<int>> read(ConverterId id) async {
    reads.add(id);
    return bytes[id]!;
  }
}

({SourceSnapshot snapshot, _Files files, SourceEventProfile profile}) _fixture(
    {Map<String, Map<String, Object?>>? items,
    List<int>? raw,
    bool missing = false,
    bool duplicate = false,
    String? movePbs,
    String namespace = 'item-source'}) {
  final data = raw ??
      [
        4,
        8,
        ..._value({
          for (final p in (items ??
                  {'BURNHEAL': _item('BURNHEAL'), 'ETHER': _item('ETHER')})
              .entries)
            _Symbol(p.key): _Object('GameData::Item', p.value),
          if (duplicate)
            const _Symbol('ETHER'): _Object('GameData::Item', _item('ETHER'))
        })
      ];
  final entry = SourceFileEntry(
      fileId: ConverterId('source-items'),
      relativePath: 'Data/items.dat',
      kind: SourceNodeKind.file,
      byteLength: data.length,
      sha256: Sha256Hash(crypto.sha256.convert(data).toString()),
      format: 'marshal',
      family: 'data');
  final moveBytes = movePbs == null ? null : utf8.encode(movePbs);
  final moveEntry = moveBytes == null
      ? null
      : SourceFileEntry(
          fileId: ConverterId('source-moves'),
          relativePath: 'PBS/moves.txt',
          kind: SourceNodeKind.file,
          byteLength: moveBytes.length,
          sha256: Sha256Hash(crypto.sha256.convert(moveBytes).toString()),
          format: 'pbs',
          family: 'pbs');
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: ConverterId(namespace),
      policyHash: SourceScanPolicy().canonicalHash,
      entries: missing ? [] : [entry, if (moveEntry != null) moveEntry],
      diagnostics: [],
      excludedPaths: [],
      profileEvidence: [],
      state: SourceScanState.complete);
  final profile = SourceEventProfile.kanto(
      scriptsArchiveHash:
          Sha256Hash(SourceEventProfile.kantoScriptsArchiveSha256),
      sourceSnapshotHash: snapshot.canonicalHash,
      normalizationHash:
          canonicalHashOf({'fixture': 'static-oracle-contract'}));
  return (
    snapshot: snapshot,
    files: _Files({
      entry.fileId: data,
      if (moveEntry != null) moveEntry.fileId: moveBytes!
    }),
    profile: profile
  );
}

Future<SourceEventItemBindings> _read(
        ({SourceSnapshot snapshot, _Files files, SourceEventProfile profile}) f,
        {Iterable<String> symbols = const ['BURNHEAL', 'ETHER'],
        bool qualified = true,
        SourceEventItemBindingLimits limits =
            const SourceEventItemBindingLimits(),
        ScanCancellation? cancellation}) =>
    const SourceEventItemBindingResolver().read(
        snapshot: f.snapshot,
        files: f.files,
        symbols: symbols,
        eventProfile: qualified ? f.profile : null,
        limits: limits,
        cancellation: cancellation);
Matcher _code(String code) =>
    isA<ContractError>().having((e) => e.code, 'code', code);
void main() {
  test(
      'binds Burn Heal and Ether to exact catalog fields and qualified native uses',
      () async {
    final f = _fixture();
    final r = await _read(f);
    final b = r.bindings['BURNHEAL']!, e = r.bindings['ETHER']!;
    expect(r.bindings.keys, ['BURNHEAL', 'ETHER']);
    expect(b.definition.id, isNot('burn-heal'));
    expect(e.definition.id, isNot('ether'));
    expect(b.definition.aliases, isEmpty);
    expect(b.definition.displayName, 'Burn Heal');
    expect(b.definition.pocketId, 'medicine');
    expect(b.definition.buyPrice, 200);
    expect(b.definition.sellPrice, 50);
    expect(b.sourcePocketIndex, 2);
    expect(b.portionName, 'Burn Heal');
    expect(e.portionName, 'Ether');
    expect(e.portionNamePlural, 'Ethers');
    expect(b.flags, ['Fling_30']);
    expect(b.pickupQualified, isTrue);
    expect(b.fullPickupParityQualified, isFalse);
    expect(b.useParity, SourceEventItemUseParity.qualified);
    expect(b.definition.uses.single.contexts,
        {ProjectItemUseContext.overworld, ProjectItemUseContext.battle});
    final cure = b.definition.uses.single.effect
        as ProjectItemCureStatusEffectDefinition;
    expect(cure.statusIds, {'burn'});
    expect(e.useParity, SourceEventItemUseParity.partial);
    expect(e.useGaps, contains('item.use.battle_restore_pp'));
    expect(
        e.definition.uses.single.contexts, {ProjectItemUseContext.overworld});
    expect(
        (e.definition.uses.single.effect
                as ProjectItemRestorePpEffectDefinition)
            .amount,
        10);
    expect(
        validateProjectItemCatalog(
                ProjectItemCatalog(
                    schemaVersion: 1,
                    entries:
                        r.bindings.values.map((b) => b.definition).toList()),
                capabilityTruth: itemSystemV1CapabilityTruth)
            .hasBlockingDiagnostics,
        isFalse);
    expect(r.archive.isSealed, isTrue);
    expect(r.archive.files[b.itemReference.fileId]!.contentHash,
        b.itemReference.contentHash);
    expect(b.fieldReferences.keys, contains('@flags'));
    expect(f.files.reads, [ConverterId('source-items')]);
    expect(r.evidence['sourceScriptsExecuted'], 0);
    expect(r.evidence['fullPickupParityQualified'], isFalse);
  });
  test('preserves unsupported item identity while separating use qualification',
      () async {
    final f = _fixture(items: {
      'RARECANDY': _item('RARECANDY', patch: {'@battle_use': 0}),
      'TM101': _item('TM101', patch: {
        '@pocket': 4,
        '@field_use': 3,
        '@battle_use': 0,
        '@move': const _Symbol('AERIALACE'),
        '@consumable': false
      })
    });
    final r = await _read(f, symbols: ['TM101', 'RARECANDY']);
    final tm = r.bindings['TM101']!;
    expect(tm.isMachine, isTrue);
    expect(tm.moveSymbol, 'AERIALACE');
    expect(tm.sourceConsumable, isFalse);
    expect(tm.definition.machine, isNull);
    expect(tm.definition.uses, isEmpty);
    expect(tm.useParity, SourceEventItemUseParity.unqualified);
    expect(tm.pickupQualified, isTrue);
    expect(r.bindings['RARECANDY']!.useGaps,
        contains('item.use.source_handler_unqualified'));
  });
  test('binds TM101 pickup name to its attested AERIALACE source entry',
      () async {
    final f = _fixture(items: {
      'TM101': _item('TM101', patch: {
        '@pocket': 4,
        '@field_use': 3,
        '@battle_use': 0,
        '@move': const _Symbol('AERIALACE'),
        '@consumable': false
      })
    }, movePbs: '[AERIALACE]\nName = Aerial Ace\n');
    final result = await _read(f, symbols: ['TM101']);
    final tm = result.bindings['TM101']!;
    final witness = tm.toJson()['sourceMachineMove'] as Map?;
    expect(witness, isNotNull);
    expect(witness!['sourceSymbol'], 'AERIALACE');
    expect(witness['name'], 'Aerial Ace');
    expect((witness['file'] as Map)['sha256'],
        f.snapshot.entries.last.sha256!.value);
    expect((witness['nameLocator'] as Map)['line'], 2);
    expect(tm.definition.machine, isNull);
    expect(tm.definition.uses, isEmpty);
    expect(tm.useParity, SourceEventItemUseParity.unqualified);
    expect(tm.useGaps, contains('item.use.machine_not_projected'));
    expect(tm.fullPickupParityQualified, isFalse);
    expect(tm.toJson()['nativeProjectMoveMachine'], isNull);
  });
  test('does not bind a missing, ambiguous or controlled machine move name',
      () async {
    for (final source in <String?>[
      null,
      '[FLY]\nName = Fly\n',
      '[AERIALACE]\nName = Aerial Ace\n[AERIALACE]\nName = Other\n',
      r'[AERIALACE]' '\n' r'Name = Aerial Ace\c[1]' '\n',
      '[AERIALACE]\nName = <command>\n',
    ]) {
      final f = _fixture(items: {
        'TM101': _item('TM101', patch: {
          '@pocket': 4,
          '@field_use': 3,
          '@battle_use': 0,
          '@move': const _Symbol('AERIALACE'),
          '@consumable': false
        })
      }, movePbs: source);
      final result = await _read(f, symbols: ['TM101']);
      expect(result.bindings['TM101']!.toJson()['sourceMachineMove'], isNull,
          reason: '$source');
      expect(result.bindings['TM101']!.definition.machine, isNull);
    }
  });
  test('refuses changed or over-quota machine move witnesses', () async {
    final item = _item('TM101', patch: {
      '@pocket': 4,
      '@field_use': 3,
      '@battle_use': 0,
      '@move': const _Symbol('AERIALACE'),
      '@consumable': false
    });
    final changed = _fixture(
        items: {'TM101': item}, movePbs: '[AERIALACE]\nName = Aerial Ace\n');
    changed.files.bytes[ConverterId('source-moves')] =
        utf8.encode('[AERIALACE]\nName = Counterfeit\n');
    await expectLater(_read(changed, symbols: ['TM101']),
        throwsA(_code('pbs.source_changed')));
    final oversized = _fixture(
        items: {'TM101': item},
        movePbs: '[AERIALACE]\nName = Aerial Ace\n#${'x' * 2048}\n');
    await expectLater(
        _read(oversized,
            symbols: ['TM101'],
            limits: const SourceEventItemBindingLimits(maxCatalogBytes: 1024)),
        throwsA(_code('pbs.quota')));
    expect(oversized.files.reads, [ConverterId('source-items')]);
  });
  test(
      'unknown requested symbol is quarantined without selecting another object',
      () async {
    final r = await _read(_fixture(), symbols: ['UNKNOWN', 'ETHER']);
    expect(r.bindings.keys, ['ETHER']);
    expect(r.quarantinedSymbols, {
      'UNKNOWN': ['item.symbol_missing']
    });
  });
  test('sorts and deduplicates requests and produces stable immutable evidence',
      () async {
    final f = _fixture();
    final a = await _read(f, symbols: ['ETHER', 'BURNHEAL', 'ETHER']);
    final b = await _read(f, symbols: ['BURNHEAL', 'ETHER']);
    expect(a.canonicalHash, b.canonicalHash);
    expect(a.evidence, b.evidence);
    expect(() => a.bindings.clear(), throwsUnsupportedError);
    expect(() => a.bindings['ETHER']!.flags.clear(), throwsUnsupportedError);
    expect(() => a.bindings['ETHER']!.fieldReferences.clear(),
        throwsUnsupportedError);
  });
  test('catalog changes preserve symbol identity while updating witnesses',
      () async {
    final a = await _read(_fixture());
    final b = await _read(_fixture(items: {
      'BURNHEAL': _item('BURNHEAL', patch: {'@price': 201}),
      'ETHER': _item('ETHER')
    }));
    expect(a.bindings['BURNHEAL']!.definition.id,
        b.bindings['BURNHEAL']!.definition.id);
    expect(a.bindings['BURNHEAL']!.itemReference.contentHash,
        isNot(b.bindings['BURNHEAL']!.itemReference.contentHash));
    expect(a.canonicalHash, isNot(b.canonicalHash));
  });
  test(
      'an unqualified profile preserves identity and exposes no executable use',
      () async {
    final r = await _read(_fixture(), qualified: false);
    expect(r.bindings['ETHER']!.pickupQualified, isFalse);
    expect(r.bindings['ETHER']!.definition.uses, isEmpty);
    expect(
        r.bindings['ETHER']!.useParity, SourceEventItemUseParity.unqualified);
    expect(r.bindings['ETHER']!.useGaps, contains('item.profile_unqualified'));
  });
  test('a profile from another snapshot is rejected before reading', () async {
    final f = _fixture();
    final other = _fixture(items: {
      'ETHER': _item('ETHER', patch: {'@price': 601})
    });
    await expectLater(
        const SourceEventItemBindingResolver().read(
            snapshot: f.snapshot,
            files: f.files,
            symbols: ['ETHER'],
            eventProfile: other.profile),
        throwsA(_code('source.event_items.profile_binding')));
    expect(f.files.reads, isEmpty);
  });
  test('changed source bytes are rejected against the snapshot hash', () async {
    final f = _fixture();
    f.files.bytes[ConverterId('source-items')] = [4, 8, 0x30];
    await expectLater(
        _read(f), throwsA(_code('source.event_items.source_changed')));
  });
  test('the catalog byte quota rejects the read before I/O', () async {
    final f = _fixture();
    await expectLater(
        _read(f,
            limits: const SourceEventItemBindingLimits(maxCatalogBytes: 32)),
        throwsA(_code('source.event_items.catalog_limit')));
    expect(f.files.reads, isEmpty);
  });
  test('a missing catalog is rejected with a stable error', () async {
    await expectLater(_read(_fixture(missing: true)),
        throwsA(_code('source.event_items.catalog_missing')));
  });
  test('a malformed catalog root is rejected after inert decoding', () async {
    await expectLater(_read(_fixture(raw: [4, 8, 0x30])),
        throwsA(_code('source.event_items.catalog_shape')));
  });
  test('malformed selected item fields quarantine the entire binding',
      () async {
    final r = await _read(
        _fixture(items: {
          'ETHER': _item('ETHER', patch: {'@pocket': '2'})
        }),
        symbols: ['ETHER']);
    expect(r.bindings, isEmpty);
    expect(r.quarantinedSymbols['ETHER'], ['item.field_invalid:@pocket']);
  });
  test('explicit portion names and key item flags retain their source meaning',
      () async {
    final r = await _read(
        _fixture(items: {
          'TESTKEY': _item('TESTKEY', patch: {
            '@real_portion_name': 'Token',
            '@real_portion_name_plural': 'Tokens',
            '@pocket': 8,
            '@flags': ['KeyItem'],
            '@consumable': false
          })
        }),
        symbols: ['TESTKEY']);
    final b = r.bindings['TESTKEY']!;
    expect(b.portionName, 'Token');
    expect(b.portionNamePlural, 'Tokens');
    expect(b.isKeyItem, isTrue);
    expect(b.isMachine, isFalse);
    expect(b.sourcePocketIndex, 8);
    expect(b.definition.pocketId, 'key-items');
  });
  test('unknown fields remain referenced and prevent qualification', () async {
    final r = await _read(
        _fixture(items: {
          'ETHER': _item('ETHER', patch: {'@unknown_effect': 'script payload'})
        }),
        symbols: ['ETHER']);
    final b = r.bindings['ETHER']!;
    expect(b.fieldReferences.keys, contains('@unknown_effect'));
    expect(b.pickupQualified, isFalse);
    expect(b.definition.uses, isEmpty);
    expect(
        r.quarantinedSymbols['ETHER'], ['item.field_unknown:@unknown_effect']);
  });
  test('ambiguous duplicate symbols are quarantined deterministically',
      () async {
    final r = await _read(_fixture(duplicate: true), symbols: ['ETHER']);
    expect(r.bindings, isEmpty);
    expect(r.quarantinedSymbols['ETHER'], ['item.symbol_ambiguous']);
  });
  test('empty requests require no source file reads', () async {
    final f = _fixture(missing: true);
    final r = await _read(f, symbols: []);
    expect(r.bindings, isEmpty);
    expect(r.archive.isSealed, isTrue);
    expect(f.files.reads, isEmpty);
  });
  test('invalid symbols and request quota are rejected before I/O', () async {
    final f = _fixture();
    await expectLater(_read(f, symbols: ['../ETHER']),
        throwsA(_code('source.event_items.symbol_invalid')));
    await expectLater(
        _read(f,
            limits: const SourceEventItemBindingLimits(maxRequestedSymbols: 1)),
        throwsA(_code('source.event_items.symbol_limit')));
    expect(f.files.reads, isEmpty);
  });
  test('cancellation prevents reading the source catalog', () async {
    final f = _fixture();
    final cancel = ScanCancellation()..cancel();
    await expectLater(
        _read(f, cancellation: cancel), throwsA(_code('source.cancelled')));
    expect(f.files.reads, isEmpty);
  });
  test('bounds duplicate request streams before reading the source', () async {
    final f = _fixture();
    await expectLater(_read(f, symbols: List.filled(257, 'ETHER')),
        throwsA(_code('source.event_items.symbol_limit')));
    expect(f.files.reads, isEmpty);
  });
  test('a source symbol cannot qualify a different compiled usage contract',
      () async {
    final r = await _read(
        _fixture(items: {
          'ETHER': _item('ETHER', patch: {'@battle_use': 1})
        }),
        symbols: ['ETHER']);
    expect(r.bindings['ETHER']!.definition.uses, isEmpty);
    expect(
        r.bindings['ETHER']!.useParity, SourceEventItemUseParity.unqualified);
    expect(r.bindings['ETHER']!.pickupQualified, isTrue);
  });
}
