import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_media_source_fixture.dart';
import 'support/native_trainer_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  final scripts = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  group('automatic trainer catalog integration', () {
    late Directory output;
    late LiteralTileFixture fixture;
    late NativePsdkCatalog catalog;
    late SourceEventStudyComposition events;
    late SourceCatalogStudyComposition catalogs;
    const limits = NativeWriteLimits(
        maxArtifacts: 2048,
        maxMutations: 2048,
        maxTotalImagePixels: 33554432,
        jsonLimits: ContractLimits(maxTextCodeUnits: 8388608));
    setUpAll(() async {
      output =
          await Directory.systemTemp.createTemp('native-trainers-integration-');
      catalog = NativePsdkCatalogManifest.builtin();
      final rosters = <NativeTrainerFixtureRoster>[
        for (var index = 1; index <= 70; index++)
          (type: 'ARBITRARY', name: 'Jóey $index', version: index),
        (type: 'ARBITRARY', name: 'Arthur', version: 3),
        (type: 'ARBITRARY', name: 'Blue', version: 4),
        (type: 'ARBITRARY', name: 'Grunt', version: 40),
      ];
      final trainerFiles = nativeTrainerFixtureFiles(rosters);
      final text = utf8.decode(trainerFiles['PBS/trainers.txt']!);
      final overridden = text.replaceFirst(
          '[ARBITRARY,Blue,4]\nLoseText = Good game!\nPokemon = RATTATA,16',
          '[ARBITRARY,Blue,4]\nLoseText = Good game!\nPokemon = RATTATA,16\nMoves = TACKLE');
      trainerFiles['PBS/trainers.txt'] = utf8
          .encode('$overridden\n[ARBITRARY,Grunt,40]\nPokemon = RATTATA,16\n');
      final sprite = image.Image(width: 128, height: 128, numChannels: 4);
      image.fill(sprite, color: image.ColorRgba8(80, 90, 110, 255));
      fixture = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

          scriptsBytes: await File(scripts!).readAsBytes(),
          includeEventSystem: true,
          maps: [
            LiteralFixtureMap(id: 98, width: 75, height: 3, layers: [
              List.filled(225, 384),
              List.filled(225, 0),
              List.filled(225, 0)
            ], events: [
              for (final (index, roster) in rosters.indexed)
                nativeTrainerFixtureEvent(
                    index == 70
                        ? (
                            type: roster.type,
                            name: 'ARTHUR',
                            version: roster.version
                          )
                        : roster,
                    index + 1)
            ])
          ],
          extraFiles: {
            ...nativeMediaSourceFiles(catalog, sourceSymbols: const {
              'farfetch_d': 'FARFETCHD',
              'mr_mime': 'MRMIME',
              'nidoranf': 'NIDORANfE',
              'nidoranm': 'NIDORANmA',
              'porygon_z': 'PORYGONZ',
            }),
            ...trainerFiles,
            'PBS/metadata.txt':
                utf8.encode('[1]\nWalkCharset = NativePlayer\n'),
            'Graphics/Characters/NativePlayer.png': image.encodePng(sprite),
            'Graphics/Characters/OriginalTrainer.png': image.encodePng(sprite),
            'Data/items.dat': await File.fromUri(
                    File(scripts).parent.uri.resolve('items.dat'))
                .readAsBytes(),
          });
      final literal = await const LiteralTileComposer().compose(
          source: fixture.source,
          files: fixture.files,
          selectedSourceMapIds: [98],
          projectName: 'Automatic native trainers',
          parentPath: output.path,
          folderName: 'native-trainers',
          limits: limits);
      final semantics = await const SourceSemanticStudyComposer().compose(
          source: fixture.source,
          base: literal,
          files: fixture.files,
          limits: limits);
      events = (await SourceEventStudyComposer(nativeTrainerCatalog: catalog)
          .compose(
              source: fixture.source,
              base: semantics!,
              files: fixture.files,
              limits: limits))!;
      catalogs = (await SourceCatalogStudyComposer(
              automaticNativeEncounters: false,
              nativeTrainerCatalog: catalog,
              nativeTrainerQualification: events.trainerQualification)
          .compose(
              source: fixture.source,
              base: events.draft,
              files: fixture.files,
              limits: limits))!;
    });
    tearDownAll(() async => output.delete(recursive: true));

    test(
        'shares more than 64 versioned rosters through complete programs and native actions',
        () {
      expect(events.trainerQualification!.trainers, hasLength(70));
      expect(
          catalogs.projection.trainers, events.trainerQualification!.trainers);
      final actions = catalogs.draft.mutations
          .where((row) => row.actionId == 'campaign.trainer.upsert');
      expect(actions, hasLength(70));
      final evidence = (events.draft.compositionEvidence['sourceEvents']
          as Map)['trainerBindings'] as Map;
      expect(evidence['bindings'] as List, hasLength(70));
      expect(
          (evidence['refusals'] as List).map((row) => (row as Map)['reason']),
          unorderedEquals([
            'native_trainer.pbs_missing',
            'native_trainer.party_override',
            'native_trainer.pbs_ambiguous'
          ]));
      expect(events.trainerQualification!.refusals.first.identity.trainerName,
          'ARTHUR');
      final rows = evidence['bindings'] as List;
      expect(
          rows.every((row) =>
              (row as Map)['qualificationHash'] ==
              events.trainerQualification!.evidenceHash.value),
          isTrue);
      final witnesses = (catalogs.draft.compositionEvidence['sourceCatalogs']
          as Map)['witnesses'] as List;
      expect(
          witnesses.map((row) => (row as Map)['relativePath']),
          containsAll([
            'PBS/trainers.txt',
            'PBS/pokemon.txt',
            'Data/trainers.dat',
            'Data/species.dat'
          ]));
      expect(catalogs.projection.trainers.first.name, startsWith('Jóey '));
    });

    test('restores portable qualification from exact sealed source witnesses',
        () async {
      final raw = catalogs.draft.compositionEvidence['sourceCatalogs'] as Map;
      final release =
          Map<String, Object?>.from(raw['nativeTrainerRelease'] as Map);
      final handles = (release['chunks'] as List)
          .map((row) => (row as Map)['handle'])
          .toSet();
      final restored = await NativeTrainerCatalogQualification.fromArtifacts(
          evidence: release,
          artifacts: catalogs.draft.artifacts
              .where((row) => handles.contains(row.handle)),
          normalizedSource: fixture.source,
          files: fixture.files,
          nativeCatalog: catalog,
          writeLimits: limits);
      expect(restored.evidenceHash, events.trainerQualification!.evidenceHash);
      expect(restored.trainers.map((row) => row.toJson()),
          catalogs.projection.trainers.map((row) => row.toJson()));
    });

    test(
        'composer refuses a valid qualification that omits selected trainer roots',
        () async {
      final pbs = await const SourcePbsParser()
          .read(snapshot: fixture.snapshot, files: fixture.files);
      final subset = await NativeTrainerCatalogQualification.prepare(
          normalizedSource: fixture.source,
          source: pbs,
          files: fixture.files,
          nativeCatalog: catalog,
          requestedTrainers: [
            SourcePbsIdentity(
                namespace: fixture.snapshot.logicalProjectNamespace,
                family: SourcePbsFamily.trainers,
                trainerType: 'ARBITRARY',
                trainerName: 'Jóey 1',
                version: 1)
          ]);
      await expectLater(
          SourceCatalogStudyComposer(
                  automaticNativeEncounters: false,
                  nativeTrainerCatalog: catalog,
                  nativeTrainerQualification: subset)
              .compose(
                  source: fixture.source,
                  base: events.draft,
                  files: fixture.files,
                  limits: limits),
          throwsA(isA<ContractError>().having((error) => error.code, 'code',
              'native_trainer.context_binding')));
    });

    test(
        'writer regenerates the exact event and catalog qualification before staging',
        () async {
      final approval = approveNativeFixtureDraft(catalogs.draft);
      final stages = <NativeWriteStage>[];
      final cancellation = ScanCancellation();
      await expectLater(
          NativeProjectWriter(checkpoint: (stage, _, __) {
            stages.add(stage);
            if (stage == NativeWriteStage.beforeStage) cancellation.cancel();
          }).write(approval.plan, approval.context, catalogs.draft,
              limits: limits, cancellation: cancellation),
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'native.cancelled')));
      expect(stages, [NativeWriteStage.beforeStage]);
    });

    for (final field in [
      'qualificationHash',
      'nativeCatalogHash',
      'sourceSnapshotHash'
    ]) {
      test('writer refuses altered release $field before creating staging',
          () async {
        final evidence =
            (jsonDecode(jsonEncode(catalogs.draft.compositionEvidence)) as Map)
                .cast<String, Object?>();
        ((evidence['sourceCatalogs'] as Map)['nativeTrainerRelease']
            as Map)[field] = '0' * 64;
        final original = catalogs.draft;
        final draft = NativeProjectDraft(
            source: original.source,
            projectName: original.projectName,
            parentPath: original.parentPath,
            folderName: original.folderName,
            sourceRootPath: original.sourceRootPath,
            mapIds: original.mapIds,
            artifacts: original.artifacts,
            sourceArtifacts: original.sourceArtifacts,
            mutations: original.mutations,
            compositionEvidence: evidence,
            defaultMapWidth: original.defaultMapWidth,
            defaultMapHeight: original.defaultMapHeight,
            limits: limits);
        final approval = approveNativeFixtureDraft(draft);
        final stages = <NativeWriteStage>[];
        await expectLater(
            NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
                .write(approval.plan, approval.context, draft, limits: limits),
            throwsA(isA<NativeWriteException>().having((error) => error.code,
                'code', 'native.semantics.regeneration')));
        expect(stages, isEmpty);
      });
    }
  }, skip: scripts == null, timeout: const Timeout(Duration(minutes: 3)));
}
