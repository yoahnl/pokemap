import 'dart:convert';
import 'dart:io';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'support/literal_tile_fixture.dart';

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
  final profile = SourceEventProfile(
      scriptsArchiveHash:
          Sha256Hash(fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
      sourceSnapshotHash: snapshot.canonicalHash,
      normalizationHash:
          canonicalHashOf({'fixture': 'static-oracle-contract'}),
interpretationProfile: fixtureSourceInterpretationProfile,
);
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

Map<String, Object?> _explorationItem(String symbol) {
  final isKey =
      const {'BICYCLE', 'OLDROD', 'GOODROD', 'SUPERROD'}.contains(symbol);
  return _item(symbol, patch: {
    '@pocket': isKey ? 8 : 1,
    '@field_use': 2,
    '@battle_use': 0,
    '@consumable': !isKey,
    '@flags': isKey
        ? ['KeyItem']
        : symbol == 'ESCAPEROPE'
            ? <String>[]
            : ['Repel', 'Fling_30'],
  });
}

void main() {
  test('explicit missing symbols use genuine supplemental entries without overriding the canonical catalog', () async {
    final primary = _fixture(items: {'BURNHEAL': _item('BURNHEAL')});
    final donor = _fixture(items: {'ETHER': _item('ETHER'), 'BURNHEAL': _item('BURNHEAL')});
    final bytes = donor.files.bytes.values.single;
    final donorEntry = SourceFileEntry(fileId: ConverterId('donor-items'),
        relativePath: '_converter_sources/2/Data/items.dat', kind: SourceNodeKind.file,
        byteLength: bytes.length, sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
        format: 'unknown', family: 'project');
    final snapshot = SourceSnapshot(logicalProjectNamespace: primary.snapshot.logicalProjectNamespace,
        policyHash: primary.snapshot.policyHash, entries: [...primary.snapshot.entries, donorEntry],
        diagnostics: [], excludedPaths: [], profileEvidence: [], state: SourceScanState.complete);
    final files = _Files({...primary.files.bytes, donorEntry.fileId: bytes});
    final profile = SourceEventProfile(scriptsArchiveHash: primary.profile.scriptsArchiveHash,
        sourceSnapshotHash: snapshot.canonicalHash, normalizationHash: primary.profile.normalizationHash,
        interpretationProfile: primary.profile.interpretationProfile);
    SourceMissingItemBinding binding(String symbol) => SourceMissingItemBinding.fromJson({
      'kind': 'sourceMissingItemBinding', 'version': 1, 'sourceSymbol': symbol,
      'sourceSnapshotHash': snapshot.canonicalHash.value, 'sourceFileId': donorEntry.fileId.value,
      'sourceRelativePath': donorEntry.relativePath, 'sourceSha256': donorEntry.sha256!.value,
      'reason': 'Explicit test source selection', 'humanConfirmed': true,
    });
    final unresolved = await const SourceEventItemBindingResolver().read(snapshot: snapshot, files: files,
        symbols: ['ETHER'], eventProfile: profile);
    expect(unresolved.quarantinedSymbols['ETHER'], ['item.symbol_missing']);
    final options = await const SourceEventItemBindingResolver().suggestMissingBindings(snapshot: snapshot,
        files: files, symbols: ['ETHER', 'BURNHEAL'], eventProfile: profile);
    expect(options.keys, ['ETHER']);
    final resolved = await const SourceEventItemBindingResolver().read(snapshot: snapshot, files: files,
        symbols: ['ETHER', 'BURNHEAL'], eventProfile: profile, missingItemBindings: [binding('ETHER')]);
    expect(resolved.bindings['ETHER']!.pickupQualified, true);
    expect(resolved.bindings['ETHER']!.itemReference.fileId, donorEntry.fileId);
    expect(resolved.bindings['BURNHEAL']!.itemReference.fileId, primary.snapshot.entries.single.fileId);
    expect(resolved.archive.files[donorEntry.fileId]!.rawBytes, bytes);
    expect(resolved.archive.files, hasLength(2));
    await expectLater(const SourceEventItemBindingResolver().read(snapshot: snapshot, files: files,
        symbols: ['BURNHEAL'], eventProfile: profile, missingItemBindings: [binding('BURNHEAL')]),
        throwsA(isA<ContractError>().having((value) => value.code, 'code', 'source.event_items.binding_override')));
    await expectLater(const SourceEventItemBindingResolver().read(snapshot: snapshot, files: files,
        symbols: ['MISSING'], eventProfile: profile, missingItemBindings: [binding('MISSING')]),
        throwsA(isA<ContractError>().having((value) => value.code, 'code', 'source.event_items.binding_target_invalid')));
    for (final patch in [
      {'humanConfirmed': false}, {'sourceRelativePath': 'Data/items.dat'}, {'reason': ''}, {'extraPatch': {}},
    ]) {
      expect(() => SourceMissingItemBinding.fromJson({...binding('ETHER').toJson(), ...patch}), throwsA(isA<ContractError>()));
    }
    final stale = SourceMissingItemBinding.fromJson({...binding('ETHER').toJson(), 'sourceSha256': 'f' * 64});
    await expectLater(const SourceEventItemBindingResolver().read(snapshot: snapshot, files: files,
        symbols: ['ETHER'], eventProfile: profile, missingItemBindings: [stale]), throwsA(isA<ContractError>()));
  });

  for (final fieldUse in [3, 4, 5]) {
    test('shop important policy distinguishes TM HM and consumable TR: $fieldUse', () async {
      final fixture = _fixture(items: {'TM101': _item('TM101', patch: {
        '@field_use': fieldUse, '@battle_use': 0, '@pocket': 4, '@move': _Symbol('AERIALACE')})});
      final result = await const SourceEventItemBindingResolver().read(snapshot: fixture.snapshot,
          files: fixture.files, symbols: ['TM101'], eventProfile: fixture.profile);
      final item = result.bindings['TM101']!;
      expect(item.isMachine, isTrue);
      expect(item.isImportant, fieldUse != 5);
      expect(item.definition.sellPrice, fieldUse == 5 ? 300 : null);
    });
  }
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  final capacitySymbols = [for (var i = 0; i < 65; i++) 'ITEM$i'];
  final capacityCatalog = _fixture(items: {
    for (final symbol in capacitySymbols) symbol: _item(symbol),
  });

  test('default item quota resolves 64 symbols and refuses 65 before I/O',
      () async {
    final accepted =
        await _read(capacityCatalog, symbols: capacitySymbols.take(64));
    expect(accepted.bindings, hasLength(64));
    expect(accepted.quarantinedSymbols, isEmpty);
    capacityCatalog.files.reads.clear();
    await expectLater(_read(capacityCatalog, symbols: capacitySymbols),
        throwsA(_code('source.event_items.symbol_limit')));
    expect(capacityCatalog.files.reads, isEmpty);
  });

  test('expanded item quota still bounds the raw duplicate request stream',
      () async {
    final fixture = _fixture();
    const limits = SourceEventItemBindingLimits(maxRequestedSymbols: 256);
    final accepted = await _read(fixture,
        symbols: List.filled(1024, 'ETHER'), limits: limits);
    expect(accepted.bindings.keys, ['ETHER']);
    fixture.files.reads.clear();
    await expectLater(
        _read(fixture, symbols: List.filled(1025, 'ETHER'), limits: limits),
        throwsA(_code('source.event_items.symbol_limit')));
    expect(fixture.files.reads, isEmpty);
  });

  test('invalid custom item quotas remain rejected before source I/O',
      () async {
    final fixture = _fixture();
    for (final quota in [-1, 0, 4097]) {
      await expectLater(
          _read(fixture,
              limits: SourceEventItemBindingLimits(maxRequestedSymbols: quota)),
          throwsA(_code('source.event_items.limits_invalid')));
    }
    expect(fixture.files.reads, isEmpty);
  });

  group('item composition map scope', () {
    late LiteralTileFixture fixture;

    setUpAll(() async {
      fixture = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

          scriptsBytes: await File(scriptsPath!).readAsBytes(),
          includeEventSystem: true,
          extraFiles: {
            'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = ItemActor\n'),
            'Graphics/Characters/ItemActor.png': image.encodePng(
                image.Image(width: 128, height: 192, numChannels: 4)),
            'Data/items.dat':
                capacityCatalog.files.bytes[ConverterId('source-items')]!,
          },
          maps: [
            for (var mapId = 1; mapId <= 9; mapId++)
              LiteralFixtureMap(id: mapId, events: [
                if (mapId == 1 || mapId == 9)
                  LiteralFixtureEvent(id: 1, x: 0, y: 0, pages: [
                    LiteralFixtureEventPage(commands: [
                      for (final symbol in mapId == 1
                          ? capacitySymbols.take(64)
                          : capacitySymbols.skip(64)) ...[
                        LiteralFixtureEventCommand(
                            111, [12, '\$bag.has?(:$symbol)']),
                        const LiteralFixtureEventCommand(101, ['Item present'],
                            indent: 1),
                        const LiteralFixtureEventCommand(412, []),
                      ],
                    ]),
                  ]),
              ]),
          ]);
    });

    Future<SourceEventStudyComposition> compose(int count,
        {NativeWriteLimits limits = const NativeWriteLimits(
            maxArtifacts: 128, maxMutations: 1024)}) async {
      final literal = await const LiteralTileComposer().compose(
          source: fixture.source,
          files: fixture.files,
          selectedSourceMapIds: [for (var id = 1; id <= count; id++) id],
          projectName: 'Bounded item scope',
          parentPath: '/private/tmp',
          folderName: 'unused-item-scope',
          limits: limits);
      final semantic = (await const SourceSemanticStudyComposer().compose(
          source: fixture.source,
          base: literal,
          files: fixture.files,
          limits: limits))!;
      return (await const SourceEventStudyComposer().compose(
          source: fixture.source,
          base: semantic,
          files: fixture.files,
          limits: limits))!;
    }

    for (var count = 1; count <= 8; count++) {
      test('$count maps retain the 64-symbol selected-scope behavior',
          () async {
        final result = await compose(count);
        final evidence =
            result.draft.compositionEvidence['sourceEvents'] as Map;
        final items = evidence['items'] as Map;
        expect(items['bindings'], hasLength(64));
        expect(items['quarantinedSymbols'], isEmpty);
      });
    }

    test('nine maps resolve all 65 source-bound item symbols', () async {
      final result = await compose(9);
      final evidence = result.draft.compositionEvidence['sourceEvents'] as Map;
      final items = evidence['items'] as Map;
      final bindings = (items['bindings'] as Map).values.cast<Map>();
      expect(bindings, hasLength(65));
      expect(bindings.map((binding) => binding['sourceSymbol']).toSet(),
          capacitySymbols.toSet());
      expect(items['quarantinedSymbols'], isEmpty);
      final catalogEntry = fixture.snapshot.entries
          .singleWhere((entry) => entry.relativePath == 'Data/items.dat');
      for (final binding in bindings) {
        expect((binding['itemReference'] as Map)['contentHash'],
            catalogEntry.sha256!.value);
      }
      expect(items['sourceScriptsExecuted'], 0);
    });

    test('large map scopes refuse item requests beyond the write budget',
        () async {
      await expectLater(
          compose(9,
              limits:
                  const NativeWriteLimits(maxArtifacts: 128, maxMutations: 64)),
          throwsA(_code('source.event_items.symbol_limit')));
    });

    test('large map scopes accept the exact custom item write budget',
        () async {
      final result = await compose(9,
          limits: const NativeWriteLimits(maxArtifacts: 128, maxMutations: 65));
      final evidence = result.draft.compositionEvidence['sourceEvents'] as Map;
      expect((evidence['items'] as Map)['bindings'], hasLength(65));
    });
  }, skip: scriptsPath == null);

  final explorationEffects = <String, ProjectItemEffectDefinition>{
    'REPEL': const ProjectItemEffectDefinition.repel(steps: 100),
    'SUPERREPEL': const ProjectItemEffectDefinition.repel(steps: 200),
    'MAXREPEL': const ProjectItemEffectDefinition.repel(steps: 250),
    'ESCAPEROPE': const ProjectItemEffectDefinition.escapeRope(),
    'BICYCLE': const ProjectItemEffectDefinition.bicycle(),
    'OLDROD': const ProjectItemEffectDefinition.fishing(
        rodKind: ProjectFishingRodKind.oldRod),
    'GOODROD': const ProjectItemEffectDefinition.fishing(
        rodKind: ProjectFishingRodKind.goodRod),
    'SUPERROD': const ProjectItemEffectDefinition.fishing(
        rodKind: ProjectFishingRodKind.superRod),
  };
  final externalCatalog =
      Platform.environment['AVELUNE_ESSENTIALS_ITEM_CATALOG'];
  test('binds all eight exploration effects from an inventoried real catalog',
      () async {
    final fixture = _fixture(raw: await File(externalCatalog!).readAsBytes());
    final result = await _read(fixture, symbols: explorationEffects.keys);
    expect(result.quarantinedSymbols, isEmpty);
    expect(result.bindings.length, explorationEffects.length);
    for (final row in explorationEffects.entries) {
      final binding = result.bindings[row.key]!;
      expect(binding.definition.uses.single.effect, row.value);
      expect(binding.itemReference.contentHash,
          fixture.snapshot.entries.single.sha256);
    }
  },
      skip: externalCatalog == null
          ? 'Set AVELUNE_ESSENTIALS_ITEM_CATALOG for the private source witness.'
          : false);
  for (final row in explorationEffects.entries) {
    test('imports ${row.key} as an explicit native exploration adaptation',
        () async {
      final result = await _read(
          _fixture(items: {row.key: _explorationItem(row.key)}),
          symbols: [row.key]);
      final binding = result.bindings[row.key]!;
      final item = binding.definition;
      final use = item.uses.single;
      expect(use.effect, row.value);
      expect(use.contexts, {ProjectItemUseContext.overworld});
      expect(use.target, ProjectItemTargetKind.world);
      expect(
          use.consumption,
          binding.isKeyItem
              ? ProjectItemConsumptionPolicy.never
              : ProjectItemConsumptionPolicy.onApplied);
      expect(item.tags.contains('key-item'), binding.isKeyItem);
      expect(item.id, isNot(row.key.toLowerCase()));
      expect(item.aliases, isEmpty);
      expect(binding.pickupQualified, isTrue);
      expect(binding.useParity, SourceEventItemUseParity.partial);
      expect(
          binding.useGaps, contains('item.use.native_exploration_adaptation'));
      expect(binding.toJson()['fullUseParityQualified'], isFalse);
      expect(binding.useQualificationScope,
          'nativeOverworldEffectAndConsumptionOnly');
      expect(
          validateProjectItemCatalog(
                  ProjectItemCatalog(schemaVersion: 1, entries: [item]),
                  capabilityTruth: itemSystemV1CapabilityTruth)
              .hasBlockingDiagnostics,
          isFalse);
      expect(ProjectItemDefinition.fromJson(item.toJson()), item);
      if (row.key == 'BICYCLE') expect(isBicycleItem(item), isTrue);
      if (use.effect case ProjectItemFishingEffectDefinition effect) {
        expect(fishingRodKindForItem(item), effect.rodKind);
      }
    });
    test('refuses altered ${row.key} use signatures and unqualified profiles',
        () async {
      final original = _explorationItem(row.key);
      for (final patch in <Map<String, Object?>>[
        {'@pocket': 2},
        {'@field_use': 1},
        {'@battle_use': 1},
        {'@consumable': !(original['@consumable'] as bool)},
        {'@move': const _Symbol('CUT')},
        {
          '@flags': ['CustomHandler']
        },
        {
          '@flags': [...(original['@flags'] as List), 'CustomHandler']
        },
      ]) {
        final result = await _read(
            _fixture(items: {
              row.key: {...original, ...patch}
            }),
            symbols: [row.key]);
        expect(result.bindings[row.key]!.definition.uses, isEmpty,
            reason: '${row.key}: $patch');
      }
      final unqualified = await _read(_fixture(items: {row.key: original}),
          symbols: [row.key], qualified: false);
      expect(unqualified.bindings[row.key]!.definition.uses, isEmpty);
      expect(unqualified.bindings[row.key]!.useGaps,
          contains('item.profile_unqualified'));
    });
  }
  test('native repel imported from source consumes once and rejects battle use',
      () async {
    for (final symbol in ['REPEL', 'SUPERREPEL', 'MAXREPEL']) {
      final result = await _read(
          _fixture(items: {symbol: _explorationItem(symbol)}),
          symbols: [symbol]);
      final item = result.bindings[symbol]!.definition;
      final service = PlayerItemUseService(
          snapshot: ItemCatalogSnapshot.fromCatalog(
              ProjectItemCatalog(schemaVersion: 1, entries: [item])));
      final initial = GameState(
          saveId: 'source-repel',
          bag: Bag(entries: [BagEntry(itemId: item.id, quantity: 2)]));
      PlayerItemUseResult use(GameState state, ProjectItemUseContext context) =>
          service.use(PlayerItemUseRequest(
              state: state, itemId: item.id, context: context));
      final applied = use(initial, ProjectItemUseContext.overworld);
      expect(applied.isSuccess, isTrue);
      expect(
          applied.state.repelState.remainingSteps,
          (explorationEffects[symbol] as ProjectItemRepelEffectDefinition)
              .steps);
      expect(applied.state.bag.entries.single.quantity, 1);
      final duplicate = use(applied.state, ProjectItemUseContext.overworld);
      expect(duplicate.failure, PlayerItemUseFailure.noEffect);
      expect(duplicate.state, applied.state);
      final battle = use(initial, ProjectItemUseContext.battle);
      expect(battle.isSuccess, isFalse);
      expect(battle.state, initial);
    }
  });
  test('custom exploration item names cannot activate a native effect',
      () async {
    final result = await _read(
        _fixture(items: {
          'INFINIREPEL': _explorationItem('INFINIREPEL'),
          'CUSTOMROD': {
            ..._explorationItem('OLDROD'),
            '@id': const _Symbol('CUSTOMROD')
          },
        }),
        symbols: ['INFINIREPEL', 'CUSTOMROD']);
    expect(
        result.bindings.values.every((b) => b.definition.uses.isEmpty), isTrue);
  });
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
