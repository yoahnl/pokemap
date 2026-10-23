import 'package:avelune_converter_adapters/src/source_picture_binding.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

void main() {
  test('STD08 pictures import exact image media in independent projects',
      () async {
    final ids = <String>{};
    for (final namespace in ['picture-first', 'picture-second']) {
      final bytes = literalFixtureAtlas();
      final fixture = await LiteralTileFixture.create(
          namespace: namespace,
          interpretationProfile: syntheticSourceInterpretationProfile,
          scriptsBytes: syntheticInterpretationArchive,
          extraFiles: {'Graphics/Pictures/Banner.png': bytes});
      final binding = await const SourcePictureBindingResolver()
          .read(source: fixture.source, files: fixture.files, name: 'Banner');
      expect(binding.artifact.bytes, bytes);
      expect(binding.mutation.actionId, 'presentationMedia.import');
      expect(binding.mutation.parameters['kind'], 'image');
      expect(binding.mutation.parameters['mediaId'], binding.mediaId);
      expect(binding.isBoundTo(fixture.source), isTrue);
      expect(binding.imageFile.relativePath, 'Graphics/Pictures/Banner.png');
      ids.add(binding.mediaId);
    }
    expect(ids, hasLength(2));
  });

  for (final name in ['../Banner', '/Banner', r'folder\Banner', ' Banner']) {
    test('STD08 rejects unsafe picture name $name', () async {
      final fixture = await LiteralTileFixture.create(
          interpretationProfile: syntheticSourceInterpretationProfile,
          scriptsBytes: syntheticInterpretationArchive);
      await expectLater(
          const SourcePictureBindingResolver()
              .read(source: fixture.source, files: fixture.files, name: name),
          throwsA(isA<SourcePictureBindingUnavailable>()
              .having((error) => error.reason, 'reason', 'name_unqualified')));
    });
  }

  test('STD08 missing and ambiguous pictures retain distinct refusals',
      () async {
    for (final ambiguous in [false, true]) {
      final fixture = await LiteralTileFixture.create(
          interpretationProfile: syntheticSourceInterpretationProfile,
          scriptsBytes: syntheticInterpretationArchive,
          extraFiles: {
            if (ambiguous) ...{
              'Graphics/Pictures/Banner.png': literalFixtureAtlas(),
              'Graphics/Pictures/Banner.jpg': [1, 2, 3],
            },
          });
      await expectLater(
          const SourcePictureBindingResolver().read(
              source: fixture.source, files: fixture.files, name: 'Banner'),
          throwsA(isA<SourcePictureBindingUnavailable>().having(
              (error) => error.reason,
              'reason',
              ambiguous ? 'picture_ambiguous' : 'picture_missing')));
    }
  });
}
