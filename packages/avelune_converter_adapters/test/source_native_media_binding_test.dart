import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_media_source_fixture.dart';

const _symbols = {
  'farfetch_d': 'FARFETCHD',
  'mr_mime': 'MRMIME',
  'nidoranf': 'NIDORANfE',
  'nidoranm': 'NIDORANmA',
  'porygon_z': 'PORYGONZ',
};

void main() {
  late NativePsdkCatalogManifest catalog;
  setUpAll(() => catalog = NativePsdkCatalogManifest.builtin());

  Future<SourceCatalogProjection> project(LiteralTileFixture fixture) async {
    final pbs = await const SourcePbsParser()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    return const SourceCatalogProjector().read(
        source: fixture.source,
        pbs: pbs,
        files: fixture.files,
        nativeMapIds: {1: 'native-one'},
        nativeTrainerBundle: catalog);
  }

  test(
      'native media resolves all five special names through exact source identity and case',
      () async {
    final fixture = await LiteralTileFixture.create(
        extraFiles: nativeMediaSourceFiles(catalog, sourceSymbols: _symbols));
    final projection = await project(fixture);
    final binding = projection.evidence['nativeMediaSpeciesBindings'] as Map;
    final rows = (binding['mappings'] as List).cast<Map>();
    for (final entry in _symbols.entries) {
      final row = rows.singleWhere((row) => row['nativeBaseId'] == entry.key);
      expect(row['sourceSymbol'], entry.value);
      expect(row['sourceForm'], 0);
      for (final side in ['front', 'back']) {
        final target = nativePsdkMediaTarget(entry.key, side);
        final mutation = projection.assetMutations.singleWhere(
            (mutation) => mutation.parameters['logicalPath'] == target);
        final sourcePath =
            'Graphics/Pokemon/${side == 'front' ? 'Front' : 'Back'}/${entry.value}.png';
        final sourceFile = fixture.snapshot.entries
            .singleWhere((file) => file.relativePath == sourcePath);
        expect(mutation.sourceEntityIds, [sourceFile.fileId]);
        final artifact = projection.artifacts.singleWhere((artifact) =>
            artifact.handle == mutation.parameters['artifactHandle']);
        expect(artifact.rawSha256, sourceFile.sha256);
      }
    }
    expect(projection.assetMutations, hasLength(600));
  }, timeout: const Timeout(Duration(minutes: 2)));

  for (final failure in [
    'ambiguous',
    'identityMissing',
    'mediaMissing',
    'mediaChanged'
  ]) {
    test('native media refuses $failure source evidence', () async {
      final files = nativeMediaSourceFiles(catalog,
          sourceSymbols: _symbols,
          extraSpecies: failure == 'ambiguous'
              ? {'SECOND_SOURCE': "Farfetch'd"}
              : const {});
      if (failure == 'identityMissing') {
        files['PBS/pokemon.txt'] = utf8.encode(utf8
            .decode(files['PBS/pokemon.txt']!)
            .replaceFirst(RegExp(r'\[FARFETCHD\]\nName = [^\n]+\n'), ''));
      }
      const path = 'Graphics/Pokemon/Back/FARFETCHD.png';
      if (failure == 'mediaMissing') files.remove(path);
      final fixture = await LiteralTileFixture.create(extraFiles: files);
      if (failure == 'mediaChanged') fixture.files.overrides[path] = [1, 2, 3];
      final code = switch (failure) {
        'ambiguous' ||
        'identityMissing' =>
          'native_species.native_base_source_identity',
        'mediaMissing' => 'native_trainer.media_missing',
        _ => 'native_trainer.media_changed',
      };
      await expectLater(
          project(fixture),
          throwsA(isA<ContractError>()
              .having((error) => error.code, 'code', code)));
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
}
