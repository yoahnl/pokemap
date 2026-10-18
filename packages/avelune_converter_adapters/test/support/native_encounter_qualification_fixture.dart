import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'literal_tile_fixture.dart';

Future<
        ({
          LiteralTileFixture fixture,
          SourcePbsProject pbs,
          NativeEncounterCatalogQualification qualification
        })>
    nativeEncounterQualificationFixture(
        {int mapId = 7,
        String namespace = 'synthetic-encounters',
        String symbol = 'FIELDLING',
        int firstLevel = 3,
        int lastLevel = 5}) async {
  final fixture = await LiteralTileFixture.create(namespace: namespace, maps: [
    LiteralFixtureMap(id: mapId)
  ], extraFiles: {
    'PBS/pokemon.txt': utf8.encode('[$symbol]\nName = Rattata\n'),
    'PBS/encounters.txt':
        utf8.encode('[$mapId]\nLand,11\n100,$symbol,$firstLevel,$lastLevel\n'),
    'Data/species.dat': literalFixtureMarshal({
      LiteralFixtureSymbol(symbol): LiteralFixtureObject('GameData::Species', {
        '@id': LiteralFixtureSymbol(symbol),
        '@species': LiteralFixtureSymbol(symbol),
        '@form': 0,
        '@real_name': 'Rattata'
      })
    })
  });
  final pbs = await const SourcePbsParser()
      .read(snapshot: fixture.snapshot, files: fixture.files);
  final qualification = await NativeEncounterCatalogQualification.prepare(
      snapshot: fixture.snapshot,
      source: pbs,
      files: fixture.files,
      nativeCatalog: NativePsdkTrainerBundle.builtin(),
      selectedSourceMapIds: [mapId]);
  return (fixture: fixture, pbs: pbs, qualification: qualification);
}

Future<NativeEncounterCatalogQualification>
    syntheticNativeEncounterQualification() async =>
        (await nativeEncounterQualificationFixture()).qualification;

Future<NativeEncounterCatalogQualification> qualifyFixtureEncounterSource({
  required NormalizedSourceProject source,
  required SourceFilePort files,
  required Iterable<int> selectedSourceMapIds,
}) async => NativeEncounterCatalogQualification.prepare(snapshot: source.snapshot,
    source: await const SourcePbsParser().read(snapshot: source.snapshot, files: files),
    files: files, nativeCatalog: NativePsdkTrainerBundle.builtin(),
    selectedSourceMapIds: selectedSourceMapIds);
