import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  test(
      'inert PNG witnesses preserve exact bytes as bounded chunks while image defaults stay unchanged',
      () async {
    final bytes =
        image.encodePng(image.Image(width: 3, height: 3, numChannels: 4));
    final fixture = await LiteralTileFixture.create(
        extraFiles: {'Graphics/Pokemon/Test.png': bytes});
    final file = fixture.snapshot.entries.singleWhere(
        (file) => file.relativePath == 'Graphics/Pokemon/Test.png');
    final imageWitness = SourceSemanticWitnessFiles(
        fixture.snapshot, fixture.files, const NativeWriteLimits(), null);
    expect(await imageWitness.read(file.fileId), bytes);
    expect(imageWitness.evidence.single['encoding'], 'png');
    final inert = SourceSemanticWitnessFiles(
        fixture.snapshot, fixture.files, const NativeWriteLimits(), null,
        preservePngAsByteChunks: true);
    expect(await inert.read(file.fileId), bytes);
    expect(inert.evidence.single['encoding'], 'canonicalJsonBase64Chunks');
    expect(
        inert.artifacts.values.every(
            (artifact) => artifact.reference.mediaType == 'application/json'),
        isTrue);
    final restored = <int>[];
    for (final chunk in (inert.evidence.single['chunks'] as List).cast<Map>()) {
      final payload = jsonDecode(
          utf8.decode(inert.artifacts[chunk['artifactHandle']]!.bytes)) as Map;
      restored.addAll(base64Decode(payload['bytesBase64'] as String));
    }
    expect(restored, bytes);
    final bounded = SourceSemanticWitnessFiles(fixture.snapshot, fixture.files,
        const NativeWriteLimits(maxArtifactBytes: 128), null,
        preservePngAsByteChunks: true);
    await expectLater(
        bounded.read(file.fileId),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'semantics.witness.quota')));
    fixture.files.overrides[file.relativePath] = [...bytes, 0];
    final changed = SourceSemanticWitnessFiles(
        fixture.snapshot, fixture.files, const NativeWriteLimits(), null,
        preservePngAsByteChunks: true);
    await expectLater(
        changed.read(file.fileId),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'semantics.witness.changed')));
  });

  final sourceRoot =
      Platform.environment['AVELUNE_KANTO_NATIVE_TRAINER_SOURCE_ROOT'];
  test(
      'composes the eleven attested source teams with a complete native catalogue closure',
      () async {
    final limits = sourceCatalogStudyWriteLimitsFor(1);
    final bundle = NativePsdkTrainerBundle.builtin();
    final extra = <String, List<int>>{};
    for (final name in [
      'pokemon',
      'pokemon_forms',
      'types',
      'abilities',
      'moves',
      'items',
      'trainer_types',
      'trainers',
      'metadata'
    ]) {
      final path = 'PBS/$name.txt';
      extra[path] = await File('$sourceRoot/$path').readAsBytes();
    }
    const oraclePath =
        'Plugins/[DBK_009] Animated Pokemon System/[008] Deluxe Bitmap.rb';
    extra[oraclePath] = await File('$sourceRoot/$oraclePath').readAsBytes();
    extra['Data/species.dat'] =
        await File('$sourceRoot/Data/species.dat').readAsBytes();
    extra['Graphics/Characters/player_M.png'] =
        await File('$sourceRoot/Graphics/Characters/player_M.png')
            .readAsBytes();
    final roster = bundle.evidence['sourceRosterFile'] as Map;
    expect(crypto.sha256.convert(extra['PBS/trainers.txt']!).toString(),
        roster['sha256']);
    for (final species in bundle.speciesById.values
        .where((species) => species.forms.isBaseForm)) {
      for (final side in ['Front', 'Back']) {
        final path = 'Graphics/Pokemon/$side/${species.id.toUpperCase()}.png';
        extra[path] = await File('$sourceRoot/$path').readAsBytes();
      }
    }
    final keys = (bundle.evidence['sourceTrainerKeys'] as List).cast<String>();
    final fixture = await LiteralTileFixture.create(
        namespace: 'native-kanto-trainer-composition',
        scriptsBytes:
            await File('$sourceRoot/Data/Scripts.rxdata').readAsBytes(),
        includeEventSystem: true,
        maps: [
          LiteralFixtureMap(id: 98, width: 13, height: 2, layers: [
            List.filled(26, 384),
            List.filled(26, 0),
            List.filled(26, 0)
          ], events: [
            for (var index = 0; index < keys.length; index++)
              LiteralFixtureEvent(id: index + 1, x: index, y: 0, pages: [
                LiteralFixtureEventPage(commands: [
                  LiteralFixtureEventCommand(111, [
                    12,
                    'TrainerBattle.start(:${keys[index].split(',').first}, "${keys[index].split(',').last}")'
                  ])
                ])
              ])
          ])
        ],
        extraFiles: extra);
    final temporary =
        await Directory.systemTemp.createTemp('native-trainer-composition-');
    try {
      final literal = await const LiteralTileComposer().compose(
          source: fixture.source,
          files: fixture.files,
          selectedSourceMapIds: [98],
          projectName: 'Native trainer catalogue closure',
          parentPath: temporary.path,
          folderName: 'converted',
          limits: limits);
      final semantics = await const SourceSemanticStudyComposer().compose(
          source: fixture.source,
          base: literal,
          files: fixture.files,
          limits: limits);
      expect(semantics, isNotNull);
      final composition = await const SourceCatalogStudyComposer().compose(
          source: fixture.source,
          base: semantics!,
          files: fixture.files,
          limits: limits);
      expect(composition, isNotNull);
      final projection = composition!.projection;
      final trainers = projection.trainers
          .where((trainer) => trainer.tags.contains('native-roster-bound'))
          .toList();
      expect(trainers, hasLength(11));
      final team = trainers.expand((trainer) => trainer.team).toList();
      expect(team, hasLength(27));
      expect(team.map((member) => member.speciesId).toSet(), hasLength(19));
      expect(team.expand((member) => member.moves).toSet(), hasLength(60));
      expect(
          composition.draft.mutations.where(
              (mutation) => mutation.actionId == 'campaign.trainer.upsert'),
          hasLength(11));
      final marker = projection.evidence['nativeTrainerBindings'] as Map;
      expect(marker['movePolicy'], 'nativeAveluneDefaults');
      expect(marker['sourceDefaultMovePolicyUsed'], isFalse);
      expect(marker['globalCatalogComplete'], isFalse);
      expect(marker['nativeClosureComplete'], isTrue);
      final speciesDocs = projection.documents
          .where(
              (document) => document.kind == SourceCatalogDocumentKind.species)
          .toList();
      expect(
          speciesDocs.where((document) =>
              bundle.speciesById.containsKey(document.document['id'])),
          hasLength(68));
      final movesDoc = projection.documents
          .singleWhere((document) => document.document['catalog'] == 'moves');
      final moves = (movesDoc.document['entries'] as List).cast<Map>();
      expect(moves.where((move) => bundle.movesById.containsKey(move['id'])),
          hasLength(396));
      expect(
          moves
              .where((move) => (move['id'] as String).startsWith('source-'))
              .every((move) => move['engineSupportLevel'] == 'catalog_only'),
          isTrue);
      final media = projection.assetMutations
          .where((mutation) => mutation.actionId == 'asset.import')
          .toList();
      expect(media, hasLength(136));
      final assetStatus = {
        for (final mutation in media)
          mutation.parameters['logicalPath'] as String:
              PokemonAssetProbeStatus.exists
      };
      expect(projection.mergedItemCatalog, isNotNull,
          reason: jsonEncode(projection.diagnostics
              .where((diagnostic) => diagnostic.blocking)
              .map((diagnostic) => diagnostic.toJson())
              .toList()));
      expect(projection.mergedItemCatalog!.entries, isEmpty);
      expect(projection.evidence['itemCatalogMerge'], {
        'preservedExistingIds': [],
        'conflicted': true,
        'sourceMergeApplied': false,
        'nativeCatalogPolicy': 'initializeEmptyNative',
        'effectsImported': false,
      });
      final coherence = const PokemonCatalogCoherenceValidator()
          .validate(PokemonCatalogCoherenceSnapshot(
              ruleset: PokemonRulesetProfile.pokeMapBetaV1,
              catalogs: [
                PokemonCatalogDocument(
                    path: 'data/pokemon/catalogs/items.json',
                    value: PokemonCatalogFile(
                        schemaVersion: 1,
                        kind: 'items',
                        catalog: 'items',
                        meta: const PokemonDataMeta(
                            description: 'Projected source items'),
                        entries: projection.mergedItemCatalog!.entries
                            .map((entry) =>
                                Map<String, dynamic>.from(entry.toJson()))
                            .toList())),
                for (final document in projection.documents.where((document) =>
                    document.kind == SourceCatalogDocumentKind.catalog))
                  PokemonCatalogDocument(
                      path: document.relativePath,
                      value: PokemonCatalogFile.fromJson(
                          Map<String, dynamic>.from(document.document)))
              ],
              species: [
                for (final document in speciesDocs)
                  PokemonCatalogDocument(
                      path: document.relativePath,
                      value: PokemonSpeciesFile.fromJson(
                          Map<String, dynamic>.from(document.document)))
              ],
              learnsets: [
                for (final document in projection.documents.where((document) =>
                    document.kind == SourceCatalogDocumentKind.learnset))
                  PokemonCatalogDocument(
                      path: document.relativePath,
                      value: PokemonLearnsetFile.fromJson(
                          Map<String, dynamic>.from(document.document)))
              ],
              evolutions: [
                for (final document in projection.documents.where((document) =>
                    document.kind == SourceCatalogDocumentKind.evolution))
                  PokemonCatalogDocument(
                      path: document.relativePath,
                      value: PokemonEvolutionFile.fromJson(
                          Map<String, dynamic>.from(document.document)))
              ],
              media: [
                for (final document in projection.documents.where((document) =>
                    document.kind == SourceCatalogDocumentKind.media))
                  PokemonCatalogDocument(
                      path: document.relativePath,
                      value: PokemonMediaFile.fromJson(
                          Map<String, dynamic>.from(document.document)))
              ],
              assetProbeStatuses: assetStatus));
      expect(coherence.errorCount, 0,
          reason: jsonEncode(coherence.diagnostics
              .map((diagnostic) => diagnostic.toJson())
              .toList()));
      for (final mutation in media) {
        final artifact = projection.artifacts.singleWhere((artifact) =>
            artifact.handle == mutation.parameters['artifactHandle']);
        expect(artifact.bytes, isNotEmpty);
        final witness = (marker['media'] as List).cast<Map>().singleWhere(
            (witness) =>
                witness['targetPath'] == mutation.parameters['logicalPath']);
        if (witness['provider'] == 'essentialsSourceMedia') {
          final original = image
              .decodePng(Uint8List.fromList(extra[witness['sourcePath']]!))!;
          final output = image.decodePng(Uint8List.fromList(artifact.bytes))!;
          expect((output.width, output.height),
              (original.height, original.height));
          for (var y = 0; y < output.height; y++) {
            for (var x = 0; x < output.width; x++) {
              final a = original.getPixel(x, y), b = output.getPixel(x, y);
              if (a.r != b.r || a.g != b.g || a.b != b.b || a.a != b.a) {
                fail('Static frame pixels changed at $x,$y.');
              }
            }
          }
        }
        try {
          const NativePngValidator().validate(artifact.bytes);
        } catch (error) {
          throw StateError('${mutation.parameters['logicalPath']}: $error');
        }
      }
      final approval = approveNativeFixtureDraft(composition.draft);
      stdout.writeln(jsonEncode({
        'preparedNativeDraft': true,
        'artifacts': composition.draft.artifacts.length,
        'sourceArtifacts': composition.draft.sourceArtifacts.length,
        'mutations': composition.draft.mutations.length
      }));
      var appliedMutations = 0;
      final receipt = await NativeProjectWriter(checkpoint: (stage, _, __) {
        if (stage == NativeWriteStage.afterMutation &&
            ++appliedMutations % 50 == 0) {
          stdout
              .writeln('Native catalogue applied $appliedMutations mutations.');
        }
      }).write(approval.plan, approval.context, composition.draft,
          limits: limits);
      expect(receipt.verified, isTrue);
      const reader = LocalProjectFileReader();
      final handles = WorkspaceHandleStore();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(receipt.projectPath);
      try {
        final loader = ProjectSnapshotLoader(handles: handles);
        final snapshot = await loader.load(opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        expect(snapshot.loadDiagnostics, isEmpty);
        expect(snapshot.manifest.trainers, projection.trainers);
        final validation =
            await AuthoringReadApi(openService: opener, snapshotLoader: loader)
                .validateProject(snapshot.projectHandle);
        expect(validation.valid, isTrue,
            reason: jsonEncode(validation.toJson()));
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
      stdout.writeln(jsonEncode({
        'nativeTeams': trainers.length,
        'members': team.length,
        'nativeSpecies': bundle.speciesById.length,
        'nativeMoves': bundle.movesById.length,
        'importedMedia': media.length,
        'draftArtifacts': composition.draft.artifacts.length,
        'sourceArtifacts': composition.draft.sourceArtifacts.length,
        'mutations': composition.draft.mutations.length,
        'catalogErrors': coherence.errorCount,
        'catalogWarnings': coherence.warningCount,
        'nativeWriteVerified': receipt.verified
      }));
    } finally {
      await temporary.delete(recursive: true);
    }
  },
      timeout: const Timeout(Duration(minutes: 20)),
      skip: sourceRoot == null
          ? 'Requires the optional read-only exact Kanto source.'
          : false);
}
