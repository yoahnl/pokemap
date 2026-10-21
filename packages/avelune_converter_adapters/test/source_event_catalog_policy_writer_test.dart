import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as image;

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  test(
      'strict event replay preserves an absent catalogue instead of injecting one',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('event-catalogue-policy-');
    addTearDown(() => temporary.delete(recursive: true));
    final f = await LiteralTileFixture.create(
        interpretationProfile: syntheticSourceInterpretationProfile,
        scriptsBytes: syntheticInterpretationArchive,
        includeEventSystem: true,
        extraFiles: {
          'PBS/metadata.txt':
              utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
          'Graphics/Characters/OriginalPlayer.png': image
              .encodePng(image.Image(width: 128, height: 192, numChannels: 4))
        },
        commonEvents: const {
          1: [
            LiteralFixtureEventCommand(355, ['pbAddPokemon(:PIKACHU,5)'])
          ]
        },
        maps: [
          LiteralFixtureMap(id: 1, events: const [
            LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [
              LiteralFixtureEventPage(commands: [
                LiteralFixtureEventCommand(117, [1])
              ])
            ])
          ])
        ]);
    final literal = await const LiteralTileComposer().compose(
        source: f.source,
        files: f.files,
        selectedSourceMapIds: [1],
        projectName: 'Catalogue policy',
        parentPath: temporary.path,
        folderName: 'native');
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: f.source, base: literal, files: f.files))!;
    final events = (await const SourceEventStudyComposer()
        .compose(source: f.source, base: semantic, files: f.files))!;
    final draft = events.draft;
    final evidence = draft.compositionEvidence['sourceEvents'] as Map;
    expect(evidence.containsKey('nativeCatalogHash'), isTrue);
    expect(evidence['nativeCatalogHash'], isNull);
    final approval = approveNativeFixtureDraft(draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, draft);
    expect(receipt.verified, isTrue);
    await Directory(receipt.stagingRoot).delete(recursive: true);
    for (final unknown in [false, true]) {
      final changed = Map<String, Object?>.from(evidence);
      if (unknown) {
        changed['nativeCatalogHash'] = '0' * 64;
      } else {
        changed.remove('nativeCatalogHash');
      }
      final forged = NativeProjectDraft(
          source: draft.source,
          projectName: draft.projectName,
          parentPath: draft.parentPath,
          folderName: draft.folderName,
          mapIds: draft.mapIds,
          artifacts: draft.artifacts,
          sourceArtifacts: draft.sourceArtifacts,
          mutations: draft.mutations,
          compositionEvidence: {
            ...draft.compositionEvidence,
            'sourceEvents': changed
          });
      final a = approveNativeFixtureDraft(forged);
      await expectLater(
          NativeProjectWriter().write(a.plan, a.context, forged),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'native.semantics.regeneration')));
      expect(await Directory('${temporary.path}/native').exists(), isFalse);
    }
  });
}
