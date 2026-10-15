import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

void main() {
  late LiteralTileFixture fixture;
  late SourcePbsProject source;
  late SourcePbsIdentity trainer;
  late NativePsdkTrainerBundle bundle;

  setUpAll(() async {
    bundle = NativePsdkTrainerBundle.builtin();
    final png =
        image.encodePng(image.Image(width: 3, height: 3, numChannels: 4));
    fixture = await LiteralTileFixture.create(extraFiles: {
      'PBS/trainers.txt': utf8.encode(
          '[FRLG_BUGCATCHER,Brent]\nPokemon = BEEDRILL,19\nPokemon = BEEDRILL,19\n'),
      'PBS/items.txt': utf8.encode(
          '[SOURCEVALID]\nName = Source valid\nPocket = 1\nPrice = 50\n'),
      for (final species in bundle.speciesById.values
          .where((species) => species.forms.isBaseForm))
        for (final side in ['Front', 'Back'])
          'Graphics/Pokemon/$side/${species.id.toUpperCase()}.png': png,
    });
    source = await const SourcePbsParser()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    trainer = source.entries
        .singleWhere((entry) => entry.family == SourcePbsFamily.trainers)
        .identity!;
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
          nativeTrainerKeys: bindNative ? [trainer] : [],
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
}
