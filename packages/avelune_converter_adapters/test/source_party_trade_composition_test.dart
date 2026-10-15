import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_town_map_original_fixture.dart';

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('original self-trade complete composition', () {
    late SourceEventStudyComposition events;
    late SourceCatalogStudyComposition catalogs;
    late Directory output;
    setUpAll(() async {
      output = await Directory.systemTemp.createTemp('source-self-trade-');
      events = await composeOriginalTownMapSource(
          archivePath: archive!,
          sourceRoot: root!,
          outputParentPath: output.path,
          limits:
              const NativeWriteLimits(maxArtifacts: 512, maxMutations: 2048));
      final (_, files) = await readOriginalTownMapSource(
          archivePath: archive, sourceRoot: root);
      catalogs = (await const SourceCatalogStudyComposer().compose(
          source: events.draft.source,
          base: events.draft,
          files: files,
          limits:
              const NativeWriteLimits(maxArtifacts: 512, maxMutations: 2048)))!;
    });
    tearDownAll(() async {
      if (await output.exists()) await output.delete(recursive: true);
    });
    test('normal Map102 pipeline declares its bounded native visual adaptation',
        () {
      final source = events.draft.source;
      final id = source.eventIdentity(102, 7).value;
      final row = (events.projection.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['sourceIdentity'] == id);
      expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
      final visual =
          ((row['nativePartyTrade'] as Map)['visualAdaptation'] as Map);
      expect(visual['requestedGraphic'], 'NPC_FRLG_WOMAN_2_FORMAL');
      expect((visual['actualSourceFile'] as Map)['relativePath'],
          'Graphics/Characters/NPC_FRLG_WOMAN_2.png');
      expect((visual['actualSourceFile'] as Map)['sha256'],
          'a668f4c81d1605536afd1770adb6ef33d4d47eb12392ef9e9e323c8d9c076e95');
      expect(visual['sourceVisualParity'], false);
      expect(events.projection.semanticEvidence['usedPartyTrade'], true);
      expect(
          events.projection.scenes
              .where((scene) => scene.metadata['sourceEventIdentity'] == id),
          hasLength(1));
      expect(events.draft.compositionEvidence['sourceEvents'],
          contains('partyTrade'));
      expect(catalogs.projection.trainers, isEmpty);
      expect(
          catalogs.projection.documents.where((document) =>
              document.relativePath == 'data/pokemon/species/machoke.json'),
          hasLength(1));
      final evolution = catalogs.projection.documents.singleWhere((document) =>
          document.relativePath == 'data/pokemon/evolutions/machoke.json');
      expect(
          (evolution.document['evolutions'] as List).single['method'], 'trade');
    });
    test(
        'an explicit native bundle imports trade rules without requesting any trainer',
        () async {
      final source = events.draft.source;
      final (_, files) = await readOriginalTownMapSource(
          archivePath: archive!, sourceRoot: root!);
      final pbs = await const SourcePbsParser()
          .read(snapshot: source.snapshot, files: files);
      final projection = await const SourceCatalogProjector().read(
          source: source,
          pbs: pbs,
          files: files,
          nativeMapIds: events.draft.mapIds,
          existingItemCatalog: events.projection.itemCatalog,
          nativeTrainerBundle: NativePsdkTrainerBundle.builtin(),
          nativeTrainerMovePolicy:
              NativeTrainerMovePolicy.nativeAveluneDefaults);
      expect(projection.trainers, isEmpty);
      expect(
          projection.documents.where((document) =>
              document.relativePath == 'data/pokemon/species/machoke.json'),
          hasLength(1));
      final evolution = projection.documents.singleWhere((document) =>
          document.relativePath == 'data/pokemon/evolutions/machoke.json');
      expect(
          (evolution.document['evolutions'] as List).single['method'], 'trade');
      expect(
          (evolution.document['evolutions'] as List)
              .single['tradeRequirements'],
          isEmpty);
    });
    test(
        'source Everstone keeps its physical id and binds the explicit native held policy',
        () {
      final item = events.projection.itemCatalog!.entries
          .singleWhere((item) => item.displayName == 'Everstone');
      expect(item.heldEffectId, PokemonPassiveHeldEffect.preventEvolution.id);
      expect(item.id, startsWith('source-item-'));
      final merged = catalogs.projection.mergedItemCatalog!.entries
          .singleWhere((entry) => entry.id == item.id);
      expect(merged.heldEffectId, PokemonPassiveHeldEffect.preventEvolution.id);
    });
  },
      skip: archive == null || root == null
          ? 'Original source archive/root required.'
          : false);
}
