import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/std09_original_source_fixture.dart';

void main() {
  test(
      'STD09 original source attests its inert trainer policy and character before publication',
      () async {
    final root =
        await Directory.systemTemp.createTemp('std09-source-prequalification-');
    MacOsSourceTree? tree;
    try {
      final fixture = await Std09OriginalSourceFixture.create(
          '${root.path}/source',
          namespace: 'std09-prequalification-original');
      tree = await MacOsSourceTree.open(fixture.root);
      final snapshot = await SourceScanner().scan(
          source: tree,
          logicalProjectNamespace: ConverterId(fixture.namespace));
      final files =
          await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
      final source = await const RmxpSourceNormalizer().normalize(
          snapshot: snapshot,
          files: files,
          selectedMapIds: const {41, 83},
          interpretationProfile: fixture.profile,
          includeEventSystem: true,
          includeConnections: true);
      expect(source.canPlan, isTrue);
      final analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source))
          .analyze();
      final trainer = analysis.eventAt(41, 6)!;
      expect(trainer.isQuarantined, isFalse);
      final program =
          trainer.pages.first.body.nodes.single as SourceTrainerProgramNode;
      expect(program.defeatPolicy, isNotNull);
      expect(program.defeatPolicy!.canLose, isFalse);
      expect(fixture.engineProvenance['sourceScriptsExecuted'], 0);
      expect(fixture.engineProvenance['provider'],
          'attestedInertSourceTrainerEngineSections');
      for (final page in trainer.pages) {
        final graphic = page.graphic!;
        expect(graphic.direction, 2);
        final character = await const SourceEventCharacterImporter().read(
            snapshot: snapshot,
            files: files,
            charsetName: graphic.characterName,
            sourcePattern: graphic.pattern,
            sourceDirection: graphic.direction);
        expect(character.binding.sourceFileHash,
            fixture.sourceHashes['Graphics/Characters/OriginalTrainer.png']);
      }
      await files.verifyUnchanged();
    } finally {
      await tree?.close();
      await root.delete(recursive: true);
    }
  },
      skip: !Platform.isMacOS ||
          Platform.environment['AVELUNE_STD09_ENGINE_ARCHIVE'] == null);
}
