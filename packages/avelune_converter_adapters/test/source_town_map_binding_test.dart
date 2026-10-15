import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_town_map_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

void main() {
  test('Town Map refuses an unqualified source before reading data', () async {
    final fixture =
        await LiteralTileFixture.create(maps: [LiteralFixtureMap(id: 102)]);
    fixture.files.reads.clear();
    await expectLater(
        const SourceTownMapBindingResolver().read(
            source: fixture.source,
            files: fixture.files,
            nativeMapIds: const {102: 'native-center'}),
        throwsA(isA<SourceTownMapBindingUnavailable>()
            .having((error) => error.reason, 'reason', 'source_unqualified')));
    expect(fixture.files.reads, isEmpty);
  });

  final root = Platform.environment['AVELUNE_KANTO_TOWN_MAP_SOURCE_ROOT'];
  if (root == null) {
    test('Town Map real compiled Kanto data binding', () {},
        skip: 'AVELUNE_KANTO_TOWN_MAP_SOURCE_ROOT is required');
    return;
  }
  late LiteralTileFixture fixture;
  setUpAll(() async {
    fixture = await LiteralTileFixture.create(
        namespace: 'town-map-binding',
        maps: [LiteralFixtureMap(id: 102)],
        includeEventSystem: true,
        scriptsBytes: await File('$root/Data/Scripts.rxdata').readAsBytes(),
        extraFiles: {
          for (final path in [
            'Data/town_map.dat',
            'Data/map_metadata.dat',
            'Graphics/UI/Town Map/map_Kanto.png',
          ])
            path: await File('$root/$path').readAsBytes(),
        });
  });
  setUp(() {
    fixture.files.overrides.clear();
    fixture.files.reads.clear();
  });

  Future<SourceTownMapBinding> read(
          {NativeWriteLimits limits = const NativeWriteLimits(),
          Map<int, String> mapIds = const {102: 'native-center'}}) =>
      const SourceTownMapBindingResolver().read(
          source: fixture.source,
          files: fixture.files,
          nativeMapIds: mapIds,
          limits: limits);

  test('Town Map binds all ninety source points and the exact original PNG',
      () async {
    final binding = await read();
    expect(binding.catalog.regions.single.label, 'Kanto');
    expect(binding.catalog.regions.single.sampling,
        ProjectMenuImageSampling.pixelArt);
    expect(binding.catalog.pointsOfInterest, hasLength(90));
    expect(
        binding.catalog.pointsOfInterest.every((point) =>
            point.destination == null &&
            point.discovery == ProjectRegionPointDiscovery.always &&
            point.visibility == ProjectRegionPointVisibility.always),
        isTrue);
    final current = binding.catalog.pointsOfInterest
        .singleWhere((point) => point.mapIds.contains('native-center'));
    expect(current.u, 296 / 480);
    expect(current.v, 72 / 320);
    expect(
        binding.catalog.pointsOfInterest
            .where((point) => point.mapIds.isNotEmpty),
        hasLength(1));
    expect(binding.artifact.rawSha256.value,
        'f19d2088161ba0a77adc4db085e7a7ff4362fff48ec7b335057253e857c4f033');
    expect(binding.artifact.bytes,
        fixture.sourceBytes['Graphics/UI/Town Map/map_Kanto.png']);
    expect(binding.mutations, hasLength(92));
    expect(binding.mutations.first.actionId, 'asset.import');
    expect(binding.mutations[1].actionId, 'regionalMap.region.upsert');
    expect(
        binding.mutations
            .skip(2)
            .every((mutation) => mutation.actionId == 'regionalMap.poi.upsert'),
        isTrue);
    expect(
        validateProjectRegionalMap(
            catalog: binding.catalog, projectMapIds: ['native-center']),
        isEmpty);
    expect(
        binding.isBoundTo(
            fixture.source,
            SourceEventProfile.kantoForProject(fixture.source),
            const {102: 'native-center'}),
        isTrue);
    expect(
        binding.isBoundTo(
            fixture.source,
            SourceEventProfile.kantoForProject(fixture.source),
            const {102: 'another-center'}),
        isFalse);
    expect(binding.evidence['sourceWallMap'], isTrue);
    expect(binding.evidence['flyEnabled'], isFalse);
    expect(binding.evidence['sourceCursorParityQualified'], isFalse);
    expect(jsonDecode(canonicalJsonOf(binding.evidence)), isA<Map>());
  });

  test('Town Map refuses missing native map and image drift', () async {
    await expectLater(
        read(mapIds: const {}),
        throwsA(isA<SourceTownMapBindingUnavailable>()
            .having((error) => error.reason, 'reason', 'native_map_unbound')));
    const path = 'Graphics/UI/Town Map/map_Kanto.png';
    final bytes = List<int>.of(fixture.sourceBytes[path]!);
    bytes[bytes.length - 1] ^= 1;
    fixture.files.overrides[path] = bytes;
    await expectLater(
        read(),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.town_map.changed')));
  });

  test('Town Map keeps mutation and image pixel budgets', () async {
    await expectLater(
        read(limits: const NativeWriteLimits(maxMutations: 91)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'source.town_map.quota')));
    await expectLater(read(limits: const NativeWriteLimits(maxImagePixels: 1)),
        throwsA(isA<NativeWriteException>()));
  });

  test('Town Map refuses attested text controls and missing illustration',
      () async {
    final changed = List<int>.of(fixture.sourceBytes['Data/town_map.dat']!);
    final text = utf8.encode('Pallet Town');
    final at = List.generate(changed.length - text.length + 1, (index) => index)
        .firstWhere((index) => text.indexed
            .every((entry) => changed[index + entry.$1] == entry.$2));
    changed[at] = 27;
    for (final missingImage in [false, true]) {
      final forged = await LiteralTileFixture.create(
          namespace: 'attested-town-map-negative',
          maps: [LiteralFixtureMap(id: 102)],
          includeEventSystem: true,
          scriptsBytes: fixture.sourceBytes['Data/Scripts.rxdata'],
          extraFiles: {
            'Data/town_map.dat': missingImage
                ? fixture.sourceBytes['Data/town_map.dat']!
                : changed,
            'Data/map_metadata.dat':
                fixture.sourceBytes['Data/map_metadata.dat']!,
            if (!missingImage)
              'Graphics/UI/Town Map/map_Kanto.png':
                  fixture.sourceBytes['Graphics/UI/Town Map/map_Kanto.png']!,
          });
      await expectLater(
          const SourceTownMapBindingResolver().read(
              source: forged.source,
              files: forged.files,
              nativeMapIds: const {102: 'native-center'}),
          throwsA(isA<SourceTownMapBindingUnavailable>().having(
              (error) => error.reason,
              'reason',
              missingImage
                  ? 'source_file_missing'
                  : 'source_data_invalid_plain_text')));
    }
  });
}
