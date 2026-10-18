import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/native_source_event_atlas_admission.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/source_external_original_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_EXTERNAL_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_EXTERNAL_SOURCE_SNAPSHOT'];
  group('regenerated original event atlas admission', () {
    late NativeProjectDraft regenerated;
    late List<NativeMutation> imports;
    setUpAll(() async {
      final original = await readExternalOriginalSource(root!, snapshot!);
      final source = original.source;
      final analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      final warps = (await const SourceExternalWarpBindingResolver().read(
          source: source,
          analysis: analysis,
          files: original.files,
          policy:
              SourceExternalWarpPolicy.nativeTransitionsWithoutEscapeState))!;
      final healing = (await const SourceHealingDisplayBindingResolver()
          .read(sourceMapId: 102, sourceEventId: 4, source: source, analysis: analysis, files: original.files))!;
      expect(warps.artifacts, hasLength(2));
      expect(healing.artifacts, hasLength(2));
      regenerated = NativeProjectDraft(
          source: source,
          projectName: 'Canonical original event atlases',
          parentPath: Directory.systemTemp.path,
          folderName: 'canonical-event-atlas-admission',
          mapIds: const {},
          artifacts: [...warps.artifacts, ...healing.artifacts],
          mutations: [...warps.mutations, ...healing.mutations]);
      imports = regenerated.mutations
          .where((entry) => entry.actionId == 'tileset.import_image')
          .toList();
      expect(imports, hasLength(4));
      expect(
          imports.map((entry) =>
              (entry.parameters['tileWidth'], entry.parameters['tileHeight'])),
          [(512, 384), (512, 384), (64, 48), (64, 48)]);
    });

    NativeArtifact artifactFor(NativeMutation mutation) =>
        regenerated.artifacts.singleWhere((artifact) =>
            artifact.handle == mutation.parameters['artifactHandle']);
    bool matches(NativeMutation mutation,
            {NativeArtifact? artifact, NativeProjectDraft? expected}) =>
        matchesRegeneratedSourceEventAtlasImport(
            mutation: mutation,
            artifact: artifact ?? artifactFor(mutation),
            regeneratedEvents: expected ?? regenerated);

    for (var index = 0; index < 4; index++) {
      test('admits exact canonical original event atlas $index', () {
        final mutation = imports[index];
        expect(matches(mutation), isTrue);
      });
    }

    test('same grid without regenerated binding remains refused', () {
      for (final mutation in imports) {
        expect(
            matchesRegeneratedSourceEventAtlasImport(
                mutation: mutation,
                artifact: artifactFor(mutation),
                regeneratedEvents: null),
            isFalse);
        expect(
            matches(mutation,
                expected:
                    copyNativeFixtureDraft(regenerated, mutations: const [])),
            isFalse);
      }
    });

    test('exact geometry cannot substitute operation, identity or parameters',
        () {
      for (final mutation in imports) {
        for (final forged in [
          copyNativeFixtureMutation(mutation,
              operationId: ConverterId('foreign-operation')),
          copyNativeFixtureMutation(mutation, actionId: 'asset.import'),
          copyNativeFixtureMutation(mutation, actionVersion: 2),
          copyNativeFixtureMutation(mutation,
              sourceEntityIds: [ConverterId('foreign-source')]),
          copyNativeFixtureMutation(mutation,
              targetEntityIds: [ConverterId('foreign-target')]),
          copyNativeFixtureMutation(mutation, parameters: {
            ...mutation.parameters,
            'tilesetId': 'foreign-atlas'
          }),
          copyNativeFixtureMutation(mutation, parameters: {
            ...mutation.parameters,
            'name': 'Changed presentation'
          }),
          copyNativeFixtureMutation(mutation, parameters: {
            ...mutation.parameters,
            'tileWidth': 32,
            'tileHeight': 32
          }),
          copyNativeFixtureMutation(mutation, parameters: {
            ...mutation.parameters,
            'tileWidth': 512,
            'tileHeight': 384
          }),
          copyNativeFixtureMutation(mutation, parameters: {
            ...mutation.parameters,
            'tileWidth': 64,
            'tileHeight': 48
          }),
          copyNativeFixtureMutation(mutation,
              parameters: {...mutation.parameters, 'unknown': true}),
        ]) {
          if (canonicalJsonOf(forged.toJson(0)) ==
              canonicalJsonOf(mutation.toJson(0))) {
            continue;
          }
          expect(matches(forged, artifact: artifactFor(mutation)), isFalse,
              reason: canonicalJsonOf(forged.toJson(0)));
        }
      }
    });

    test('missing, swapped or changed artifact remains refused', () {
      for (final mutation in imports) {
        final artifact = artifactFor(mutation);
        final bytes = List<int>.of(artifact.bytes)..last ^= 1;
        expect(
            matches(mutation, artifact: NativeArtifact(bytes: bytes)), isFalse);
        expect(
            matchesRegeneratedSourceEventAtlasImport(
                mutation: mutation,
                artifact: null,
                regeneratedEvents: regenerated),
            isFalse);
        expect(
            matches(mutation,
                artifact: regenerated.artifacts.firstWhere(
                    (candidate) => candidate.handle != artifact.handle)),
            isFalse);
        expect(
            matches(mutation,
                expected: copyNativeFixtureDraft(regenerated,
                    artifacts: regenerated.artifacts
                        .where((entry) => entry.handle != artifact.handle)
                        .toList())),
            isFalse);
      }
    });

    test('duplicate regenerated operation cannot attest an atlas', () {
      for (final mutation in imports) {
        expect(
            matches(mutation,
                expected: copyNativeFixtureDraft(regenerated,
                    mutations: [...regenerated.mutations, mutation])),
            isFalse);
      }
    });
  },
      skip: root == null || snapshot == null
          ? 'Requires the sealed completed Kanto source and snapshot.'
          : false);

  for (final grid in [(512, 384), (64, 48), (16, 16)]) {
    test('unbound ${grid.$1}x${grid.$2} atlas fails before native staging',
        () async {
      final output =
          await Directory.systemTemp.createTemp('unbound-event-atlas-');
      addTearDown(() => output.delete(recursive: true));
      final fixture = await NativeWriterFixture.create(output.path);
      final raster = image.Image(width: 512, height: 384, numChannels: 4);
      final artifact = NativeArtifact(bytes: image.encodePng(raster));
      final original = fixture.draft.mutations.first;
      final draft = copyNativeFixtureDraft(fixture.draft, artifacts: [
        artifact
      ], mutations: [
        copyNativeFixtureMutation(original, parameters: {
          ...original.parameters,
          'artifactHandle': artifact.handle,
          'tileWidth': grid.$1,
          'tileHeight': grid.$2
        }),
        ...fixture.draft.mutations.skip(1)
      ]);
      final approved = approveNativeFixtureDraft(draft);
      var stages = 0;
      await expectLater(
          NativeProjectWriter(stagingFactory: () async {
            stages++;
            throw StateError('An unbound atlas must not reach staging');
          }).write(approved.plan, approved.context, draft),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.tileset.invalid')));
      expect(stages, 0);
      expect(await Directory('${output.path}/${draft.folderName}').exists(),
          isFalse);
    });
  }
}
