import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';

void main() {
  for (final claimCatalog in [false, true]) {
    test(
        'rejects an unqualified PNG import before staging with catalog claim $claimCatalog',
        () async {
      final temporary =
          await Directory.systemTemp.createTemp('native-media-admission-');
      try {
        final fixture = await NativeWriterFixture.create(temporary.path);
        final artifact = NativeArtifact(
            bytes: image
                .encodePng(image.Image(width: 3, height: 3, numChannels: 4)));
        final mutation = NativeMutation(
            operationId: ConverterId('forged-pokemon-media'),
            actionId: 'asset.import',
            sourceEntityIds: [
              fixture.source.snapshot.entries.first.fileId
            ],
            targetEntityIds: [
              ConverterId('forged_media')
            ],
            parameters: {
              'artifactHandle': artifact.handle,
              'assetId': 'forged_media',
              'logicalPath': 'assets/pokemon/native/forged_front.png',
              'tags': ['native-pokemon-battle-media'],
              'usages': ['pokemon.battleMedia']
            });
        final draft = copyNativeFixtureDraft(fixture.draft, artifacts: [
          ...fixture.draft.artifacts,
          artifact
        ], mutations: [
          ...fixture.draft.mutations,
          mutation
        ], compositionEvidence: {
          ...fixture.draft.compositionEvidence,
          if (claimCatalog)
            'sourceCatalogs': {'kind': 'sourceCatalogStudy', 'version': 1}
        });
        final approval = approveNativeFixtureDraft(draft);
        final stages = <NativeWriteStage>[];
        await expectLater(
            NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
                .write(approval.plan, approval.context, draft),
            throwsA(isA<NativeWriteException>()));
        expect(stages, isEmpty);
      } finally {
        await temporary.delete(recursive: true);
      }
    });
  }

  test('refuses invalid PNG bytes independently of a claimed media path', () {
    expect(
        () => const NativePngValidator().validate([137, 80, 78, 71]),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.png.header')));
  });
}
