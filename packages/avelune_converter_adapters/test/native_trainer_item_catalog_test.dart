import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_media_source_fixture.dart';
import 'support/native_trainer_fixture.dart';

void main() {
  late LiteralTileFixture fixture;
  late SourcePbsProject source;
  late SourcePbsIdentity trainer;
  late NativePsdkTrainerBundle bundle;
  late NativeTrainerCatalogQualification qualification;

  setUpAll(() async {
    bundle = NativePsdkTrainerBundle.builtin();
    fixture = await LiteralTileFixture.create(extraFiles: {
      ...nativeMediaSourceFiles(bundle),
      ...nativeTrainerFixtureFiles([
        (type: 'FRLG_BUGCATCHER', name: 'Brent', version: 0)
      ], team: const [
        (species: 'BEEDRILL', level: 19),
        (species: 'BEEDRILL', level: 19)
      ]),
      'PBS/items.txt': utf8.encode(
          '[SOURCEVALID]\nName = Source valid\nPocket = 1\nPrice = 50\n'),
    });
    source = await const SourcePbsParser()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    trainer = source.entries
        .singleWhere((entry) => entry.family == SourcePbsFamily.trainers)
        .identity!;
    qualification = await NativeTrainerCatalogQualification.prepare(
        normalizedSource: fixture.source,
        source: source,
        files: fixture.files,
        nativeCatalog: bundle,
        requestedTrainers: [trainer]);
  });

  Future<SourceCatalogProjection> project(
          {ProjectItemCatalog? existing, bool bindNative = true}) =>
      const SourceCatalogProjector().read(
          source: fixture.source,
          pbs: source,
          files: fixture.files,
          nativeMapIds: {1: 'native_map'},
          existingItemCatalog: existing,
          requestedItemSymbols: ['MISSING', 'SOURCEVALID'],
          requestedTrainerKeys: [trainer],
          nativeTrainerQualification: bindNative ? qualification : null,
          nativeTrainerBundle: bindNative ? bundle : null,
          nativeTrainerMovePolicy:
              NativeTrainerMovePolicy.nativeAveluneDefaults);

  Future<SourceCatalogProjection> medicineProject(
      ({LiteralTileFixture fixture, SourcePbsProject source,
        NativePsdkTrainerBundle bundle, List<SourcePbsIdentity> trainers,
        NativeTrainerCatalogQualification qualification}) input,
      {ProjectItemCatalog? existing, List<String> items = const []}) =>
      const SourceCatalogProjector().read(
          source: input.fixture.source, pbs: input.source,
          files: input.fixture.files, nativeMapIds: {1: 'native_map'},
          existingItemCatalog: existing, requestedItemSymbols: items,
          requestedTrainerKeys: input.trainers,
          nativeTrainerQualification: input.qualification,
          nativeTrainerBundle: input.bundle,
          nativeTrainerMovePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults);

  test('global qualified trainer medicines are published without event bindings',
      () async {
    final input = await _medicineFixture();
    final projection = await medicineProject(input);
    expect(projection.trainers.single.battleItems,
        {'full-heal': 1, 'hyper-potion': 1});
    expect(projection.mergedItemCatalog!.entries.map((item) => item.id),
        ['full-heal', 'hyper-potion']);
    for (final item in input.qualification.battleItemDefinitions) {
      expect(projection.mergedItemCatalog!.entries
          .singleWhere((entry) => entry.id == item.id).toJson(), item.toJson());
      expect(isEligibleTrainerBattleItem(item), isTrue);
    }
    ProjectValidator.validateTrainerBattleItemReferences(projection.trainers,
        itemCatalog: projection.mergedItemCatalog);
  });

  test('qualified medicines survive a blocked source item merge', () async {
    final input = await _medicineFixture();
    final projection = await medicineProject(input, items: ['MISSING']);
    expect(projection.hasBlockingDiagnostics, isTrue);
    expect((projection.evidence['itemCatalogMerge'] as Map)['sourceMergeApplied'],
        isFalse);
    expect(projection.mergedItemCatalog!.entries.map((item) => item.id),
        ['full-heal', 'hyper-potion']);
    ProjectValidator.validateTrainerBattleItemReferences(projection.trainers,
        itemCatalog: projection.mergedItemCatalog);
  });

  test('qualified medicines preserve identical existing definitions', () async {
    final input = await _medicineFixture();
    final previous = ProjectItemCatalog(schemaVersion: 1,
        entries: input.qualification.battleItemDefinitions);
    final projection = await medicineProject(input,
        existing: previous, items: ['MISSING']);
    expect(projection.mergedItemCatalog, same(previous));
    expect(projection.mergedItemCatalog!.toJson(), previous.toJson());
  });

  test('a conflicting canonical medicine cannot be replaced by qualification',
      () async {
    final input = await _medicineFixture();
    final fullHeal = input.qualification.battleItemDefinitions
        .singleWhere((item) => item.id == 'full-heal');
    await expectLater(medicineProject(input,
        existing: ProjectItemCatalog(schemaVersion: 1,
            entries: [fullHeal.copyWith(displayName: 'Conflicting medicine')]),
        items: ['MISSING']), throwsA(isA<ContractError>().having(
            (error) => error.code, 'code',
            'native_trainer.item_definition_conflict')));
  });

  test('compiled medicine tampering invalidates qualification before projection',
      () async {
    final input = await _medicineFixture();
    final file = input.fixture.snapshot.entries.singleWhere(
        (entry) => entry.relativePath == 'Data/items.dat');
    input.fixture.files.overrides[file.relativePath] =
        [...await input.fixture.files.read(file.fileId), 0];
    await expectLater(medicineProject(input), throwsA(isA<ContractError>()
        .having((error) => error.code, 'code', 'native_trainer.source_changed')));
  });

  test('unsupported authored medicines remain refused and unpublished', () async {
    final input = await _medicineFixture(includeUnsupported: true);
    expect(input.qualification.refusals, hasLength(1));
    expect(input.qualification.refusals.single.code,
        'native_trainer.authored_item_identity');
    final projection = await medicineProject(input);
    expect(projection.trainers, hasLength(1));
    expect(projection.mergedItemCatalog!.entries.map((item) => item.id),
        ['full-heal', 'hyper-potion']);
  });

  test('source-only item identities retain no effects beside native medicines',
      () async {
    final input = await _medicineFixture();
    final projection = await medicineProject(input,
        items: ['FULLHEAL', 'HYPERPOTION']);
    for (final symbol in ['FULLHEAL', 'HYPERPOTION']) {
      final sourceId = sourcePbsItemBindingId(
          input.fixture.snapshot.logicalProjectNamespace, symbol).value;
      final item = projection.mergedItemCatalog!.entries
          .singleWhere((item) => item.id == sourceId);
      expect(item.uses, isEmpty);
      expect(isEligibleTrainerBattleItem(item), isFalse);
    }
    ProjectValidator.validateTrainerBattleItemReferences(projection.trainers,
        itemCatalog: projection.mergedItemCatalog);
  });

  test(
      'initializes an empty native item catalogue while source merge stays blocked',
      () async {
    final projection = await project();
    expect(projection.mergedItemCatalog!.entries, isEmpty);
    expect(projection.hasBlockingDiagnostics, isTrue);
    expect(projection.evidence['itemCatalogMerge'], {
      'preservedExistingIds': [],
      'conflicted': true,
      'sourceMergeApplied': false,
      'nativeCatalogPolicy': 'initializeEmptyNative',
      'effectsImported': false,
    });
  });

  test(
      'retains the exact native item catalogue and uses without partial source merge',
      () async {
    const previous = ProjectItemCatalog(schemaVersion: 1, entries: [
      ProjectItemDefinition(
          id: 'native_item',
          displayName: 'Native item',
          pocketId: 'medicine',
          uses: [
            ProjectItemUseDefinition(
                contexts: {ProjectItemUseContext.overworld},
                target: ProjectItemTargetKind.partyMember,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.cureStatus(
                    mode: ProjectItemStatusCureMode.listed,
                    statusIds: {'burn'}))
          ])
    ]);
    final projection = await project(existing: previous);
    expect(projection.mergedItemCatalog, same(previous));
    expect(projection.mergedItemCatalog!.entries, previous.entries);
    expect(projection.evidence['itemCatalogMerge'], {
      'preservedExistingIds': ['native_item'],
      'conflicted': true,
      'sourceMergeApplied': false,
      'nativeCatalogPolicy': 'preserveExistingNative',
      'effectsImported': false,
    });
    expect(projection.hasBlockingDiagnostics, isTrue);
  });

  test('keeps a blocked source merge unavailable without a native binding',
      () async {
    final projection = await project(bindNative: false);
    expect(projection.mergedItemCatalog, isNull);
    expect(
        (projection.evidence['itemCatalogMerge'] as Map)['nativeCatalogPolicy'],
        'sourceMergeBlocked');
  });

  test('refuses obsolete native trainer keys without a compiled qualification',
      () async {
    await expectLater(
        const SourceCatalogProjector().read(
            source: fixture.source,
            pbs: source,
            files: fixture.files,
            nativeMapIds: {1: 'native_map'},
            requestedTrainerKeys: [trainer],
            nativeTrainerKeys: [trainer],
            nativeTrainerBundle: bundle,
            nativeTrainerMovePolicy:
                NativeTrainerMovePolicy.nativeAveluneDefaults),
        throwsA(isA<ContractError>().having((error) => error.code, 'code',
            'native_trainer.projection_binding')));
  });
}

Future<({LiteralTileFixture fixture, SourcePbsProject source,
    NativePsdkTrainerBundle bundle, List<SourcePbsIdentity> trainers,
    NativeTrainerCatalogQualification qualification})> _medicineFixture(
        {bool includeUnsupported = false}) async {
  final bundle = NativePsdkTrainerBundle.builtin();
  final medicines = [
    (symbol: 'FULLHEAL', name: 'Full Heal', price: 400, sell: 100),
    (symbol: 'HYPERPOTION', name: 'Hyper Potion', price: 1200, sell: 600),
    if (includeUnsupported)
      (symbol: 'FULLRESTORE', name: 'Full Restore', price: 3000, sell: 1500)
  ];
  final names = ['Brent', if (includeUnsupported) 'Unqualified'];
  final fixture = await LiteralTileFixture.create(extraFiles: {
    ...nativeMediaSourceFiles(bundle),
    ...nativeTrainerFixtureFiles([
      for (final name in names)
        (type: 'FRLG_BUGCATCHER', name: name, version: 0)
    ]),
    'PBS/trainers.txt': utf8.encode([
      for (final name in names)
        '[FRLG_BUGCATCHER,$name,0]\nLoseText = Good game!\n'
        'Items = ${name == 'Brent' ? 'FULLHEAL,HYPERPOTION' : 'FULLRESTORE'}\n'
        'Pokemon = RATTATA,16\n'
    ].join()),
    'Data/trainers.dat': literalFixtureMarshal({
      for (final name in names)
        [const LiteralFixtureSymbol('FRLG_BUGCATCHER'), name, 0]:
            LiteralFixtureObject('GameData::Trainer', {
          '@id': [const LiteralFixtureSymbol('FRLG_BUGCATCHER'), name, 0],
          '@trainer_type': const LiteralFixtureSymbol('FRLG_BUGCATCHER'),
          '@real_name': name, '@version': 0,
          '@items': [for (final symbol in name == 'Brent'
              ? ['FULLHEAL', 'HYPERPOTION'] : ['FULLRESTORE'])
            LiteralFixtureSymbol(symbol)],
          '@real_lose_text': 'Good game!',
          '@pokemon': [{const LiteralFixtureSymbol('species'):
              const LiteralFixtureSymbol('RATTATA'),
            const LiteralFixtureSymbol('level'): 16}],
          '@pbs_file_suffix': '',
        })
    }),
    'PBS/items.txt': utf8.encode([
      for (final item in medicines)
        '[${item.symbol}]\nName = ${item.name}\nNamePlural = ${item.name}s\n'
        'Pocket = 2\nPrice = ${item.price}\nSellPrice = ${item.sell}\n'
        'FieldUse = OnPokemon\nBattleUse = OnPokemon\nFlags = Fling_30\n'
    ].join()),
    'Data/items.dat': literalFixtureMarshal({
      for (final item in medicines)
        LiteralFixtureSymbol(item.symbol): LiteralFixtureObject('GameData::Item', {
          '@id': LiteralFixtureSymbol(item.symbol), '@real_name': item.name,
          '@real_name_plural': '${item.name}s', '@pocket': 2,
          '@price': item.price, '@sell_price': item.sell, '@bp_price': 1,
          '@field_use': 1, '@battle_use': 1, '@flags': ['Fling_30'],
          '@consumable': true, '@move': null, '@real_description': '',
          '@pbs_file_suffix': '',
        })
    })
  });
  final source = await const SourcePbsParser().read(
      snapshot: fixture.snapshot, files: fixture.files);
  final trainers = source.entries.where(
      (entry) => entry.family == SourcePbsFamily.trainers)
      .map((entry) => entry.identity!).toList();
  final qualification = await NativeTrainerCatalogQualification.prepare(
      normalizedSource: fixture.source, source: source, files: fixture.files,
      nativeCatalog: bundle, requestedTrainers: trainers);
  return (fixture: fixture, source: source, bundle: bundle,
      trainers: trainers, qualification: qualification);
}
