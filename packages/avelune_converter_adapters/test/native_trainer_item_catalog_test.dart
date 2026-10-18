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
