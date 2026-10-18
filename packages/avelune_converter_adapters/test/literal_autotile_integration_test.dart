import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';
import 'support/original_autotile_fixture.dart';

void main() {
  late Directory root;
  late LiteralTileFixture source;
  late OriginalAutotileFixture raster;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ac07-literal-integration-');
    raster = OriginalAutotileFixture.standard();
    source = await LiteralTileFixture.create(
      sourceRootPath: '${root.path}/source',
      maps: [
        LiteralFixtureMap(id: 1, layers: const [
          [384, 79, 0],
          [0, 0, 79],
          [0, 0, 0],
        ]),
      ],
      tilesets: [
        LiteralFixtureTileset(id: 1, autotileNames: const ['OriginalWater']),
      ],
      autotilePngs: {'OriginalWater': raster.pngBytes},
    );
  });

  tearDown(() async => root.delete(recursive: true));

  Future<LiteralTileComposition> compose({bool firstFrame = false}) =>
      const LiteralTileComposer().compose(
        source: source.source,
        files: source.files,
        selectedSourceMapIds: const [1],
        projectName: 'Original forced variant study',
        parentPath: root.path,
        folderName: 'native-study',
        sourceRootPath: source.sourceRootPath,
        allowFirstFrameAutotiles: firstFrame,
      );

  test(
      'unattested multiframe animation blocks without an explicit study choice',
      () async {
    final composition = await compose();
    expect(composition.canWrite, isFalse);
    expect(
        composition.diagnostics.any((value) =>
            value.code == 'literal.autotile.animation_unverified' &&
            value.blocksPlanning),
        isTrue);
  });

  test(
      'AUTO-03 stored variant survives mixed layers without neighbor inference',
      () async {
    final composition = await compose(firstFrame: true);
    expect(composition.canWrite, isTrue);
    final native = composition.nativeMaps[1]!;
    final layers = native.layers.reversed.cast<TileLayer>().toList();
    final forced = layers.first.palette[layers.first.cells[1] - 1];
    final upper = layers[1].palette[layers[1].cells[2] - 1];
    expect(forced.localTileId, 31);
    expect(upper, forced);
    expect(layers.first.cells[2], 0);
    final regular = layers.first.palette[layers.first.cells[0] - 1];
    expect(regular.localTileId, 0);
    expect(regular.tilesetId, isNot(forced.tilesetId));
    final import = composition.draft!.mutations.singleWhere((value) =>
        value.actionId == 'tileset.import_image' &&
        value.parameters['tilesetId'] == forced.tilesetId);
    final artifact = composition.draft!.artifacts.singleWhere(
        (value) => value.handle == import.parameters['artifactHandle']);
    final generated = image.decodePng(Uint8List.fromList(artifact.bytes))!;
    final expected = raster.expectedRgba(frame: 0, variant: 31);
    final actual = <int>[];
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        final pixel = generated.getPixel(7 * 32 + x, 3 * 32 + y);
        actual.addAll([
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          pixel.a.toInt()
        ]);
      }
    }
    expect(actual, expected);
  });

  test('AUTO-04 first frame study is visibly degraded and has no fake timeline',
      () async {
    final composition = await compose(firstFrame: true);
    expect(composition.canWrite, isTrue);
    expect(
        composition.diagnostics.any((value) =>
            value.code == 'literal.autotile.animation_unverified' &&
            !value.blocksPlanning),
        isTrue);
    expect(
        composition.draft!.mutations
            .where((value) => value.actionId == 'tileset.upsert'),
        isEmpty);
    expect(composition.playableCertified, isFalse);
    final approval = approveNativeFixtureDraft(composition.draft!);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, composition.draft!);
    expect(receipt.verified, isTrue);
    expect(receipt.published, isFalse);
    for (final entry in source.sourceBytes.entries) {
      expect(await File('${source.sourceRootPath}/${entry.key}').readAsBytes(),
          entry.value);
    }
  });

  for (final field in const [
    'compositionHash',
    'sourceSnapshotHash',
    'generatedImageHash',
    'tileAnimations',
    'sourceProfile'
  ]) {
    test('contradictory autotile $field refuses staging after new approval',
        () async {
      final composition = await compose(firstFrame: true);
      final original = composition.draft!;
      final evidence = jsonDecode(jsonEncode(original.compositionEvidence))
          as Map<String, Object?>;
      final body = evidence['composition'] as Map<String, dynamic>;
      final row = (body['autotiles'] as List).single as Map<String, dynamic>;
      final provenance = row['provenance'] as Map<String, dynamic>;
      if (field == 'compositionHash') {
        row['compositionHash'] = 'f' * 64;
      } else {
        provenance[field] = switch (field) {
          'tileAnimations' => [
              {'tileId': 31, 'frames': []}
            ],
          'sourceProfile' => {
              'state': 'unverified',
              'sourceSnapshotHash': 'f' * 64
            },
          _ => 'f' * 64,
        };
        row['compositionHash'] = canonicalHashOf(provenance).value;
      }
      evidence['compositionHash'] = canonicalHashOf(body).value;
      final forged =
          copyNativeFixtureDraft(original, compositionEvidence: evidence);
      final approval = approveNativeFixtureDraft(forged);
      final stages = <NativeWriteStage>[];
      await expectLater(
          NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
              .write(approval.plan, approval.context, forged),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.composition.autotiles')));
      expect(stages, isEmpty);
      expect(await Directory('${root.path}/native-study').exists(), isFalse);
    });
  }

  final scriptsPath = Platform.environment['AVELUNE_AUTOTILE_SCRIPTS_PATH'];
  test('AUTO-02 attested native pipeline writes all 48 three-frame timelines',
      () async {
    final attested = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

        sourceRootPath: '${root.path}/attested-source',
        maps: [
          LiteralFixtureMap(id: 1, width: 8, height: 6, layers: [
            List.generate(48, (index) => index + 48),
            List.filled(48, 0),
            List.filled(48, 0)
          ])
        ],
        tilesets: [
          LiteralFixtureTileset(
              id: 1, autotileNames: const ['OriginalWater[ 4 ] '])
        ],
        autotilePngs: {'OriginalWater[ 4 ] ': raster.pngBytes},
        scriptsBytes: await File(scriptsPath!).readAsBytes());
    final composition = await const LiteralTileComposer().compose(
        source: attested.source,
        files: attested.files,
        selectedSourceMapIds: const [1],
        projectName: 'Attested original animation',
        parentPath: root.path,
        folderName: 'attested-native',
        sourceRootPath: attested.sourceRootPath);
    expect(composition.canWrite, isTrue);
    final auto = composition.autotiles.single;
    expect(auto.degraded, isFalse);
    expect(auto.animationVerified, isTrue);
    expect(auto.frameDurationMs, 200);
    expect(auto.tileAnimations, hasLength(48));
    for (var variant = 0; variant < 48; variant++) {
      final animation = auto.tileAnimations[variant];
      expect(animation.tileId, variant);
      expect(animation.frames.map((value) => value.tileId),
          [variant, variant + 48, variant + 96]);
      expect(
          animation.frames.map((value) => value.durationMs), [200, 200, 200]);
    }
    final approval = approveNativeFixtureDraft(composition.draft!);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, composition.draft!);
    expect(receipt.verified, isTrue);
    final manifest = ProjectManifest.fromJson(jsonDecode(
            await File('${receipt.projectPath}/project.json').readAsString())
        as Map<String, dynamic>);
    final native = manifest.tilesets
        .singleWhere((value) => value.id == auto.nativeTilesetId)
        .source as ProjectRegularAtlasTilesetSource;
    expect(native.tileAnimations.map((value) => value.toJson()).toList(),
        auto.tileAnimations.map((value) => value.toJson()).toList());
    for (final spoofName in [false, true]) {
      final draft = composition.draft!;
      final evidence = jsonDecode(jsonEncode(draft.compositionEvidence))
          as Map<String, Object?>;
      final body = evidence['composition'] as Map<String, dynamic>;
      final row = (body['autotiles'] as List).single as Map<String, dynamic>;
      final provenance = row['provenance'] as Map<String, dynamic>;
      final timelines = row['tileAnimations'] as List;
      for (final animation in timelines) {
        for (final frame in animation['frames'] as List) {
          frame['durationMs'] = 500;
        }
      }
      provenance['tileAnimations'] = timelines;
      provenance['frameDurationMs'] = 500;
      if (spoofName) provenance['sourceName'] = 'OriginalWater[10]';
      row['compositionHash'] = canonicalHashOf(provenance).value;
      evidence['compositionHash'] = canonicalHashOf(body).value;
      final mutations = draft.mutations.map((mutation) {
        if (mutation.actionId != 'tileset.upsert') return mutation;
        final parameters =
            jsonDecode(jsonEncode(mutation.parameters)) as Map<String, Object?>;
        ((parameters['tileset'] as Map)['source'] as Map)['tileAnimations'] =
            timelines;
        return copyNativeFixtureMutation(mutation, parameters: parameters);
      }).toList();
      final forged = copyNativeFixtureDraft(draft,
          mutations: mutations, compositionEvidence: evidence);
      final forgedApproval = approveNativeFixtureDraft(forged);
      final stages = <NativeWriteStage>[];
      await expectLater(
          NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
              .write(forgedApproval.plan, forgedApproval.context, forged),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.composition.autotiles')));
      expect(stages, isEmpty);
    }
    for (final entry in attested.sourceBytes.entries) {
      expect(
          await File('${attested.sourceRootPath}/${entry.key}').readAsBytes(),
          entry.value);
    }
  },
      skip: scriptsPath == null
          ? 'Local Kanto clock qualification requires AVELUNE_AUTOTILE_SCRIPTS_PATH'
          : false);
}
