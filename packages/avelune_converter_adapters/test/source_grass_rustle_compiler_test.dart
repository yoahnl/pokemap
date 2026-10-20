import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  final scriptsPath = Platform.environment['AVELUNE_GRASS_SOURCE_SCRIPTS'];
  test('automatic semantic conversion writes and reopens native grass effects',
      () async {
    final root = await Directory.systemTemp.createTemp('source-grass-write-');
    try {
      final fixture = await _fixture(await File(scriptsPath!).readAsBytes());
      final profile =
          detectBuiltinSourceInterpretationProfile(fixture.snapshot)!;
      final source = await const RmxpSourceNormalizer().normalize(
          snapshot: fixture.snapshot,
          files: fixture.files,
          interpretationProfile: profile);
      final base = await const LiteralTileComposer().compose(
          source: source,
          files: fixture.files,
          selectedSourceMapIds: [1, 2],
          projectName: 'Grass conversion fixture',
          parentPath: await root.resolveSymbolicLinks(),
          folderName: 'grass-native');
      final draft = (await const SourceSemanticStudyComposer()
          .compose(source: source, base: base, files: fixture.files))!;
      final projected = sourceSemanticNativeProject(
          draft: draft,
          maps: {
            for (final mutation
                in draft.mutations.where((m) => m.actionId == 'map.save'))
              draft.mapIds.entries
                      .singleWhere(
                          (entry) =>
                              entry.value ==
                              (mutation.parameters['map'] as Map)['id'])
                      .key:
                  MapData.fromJson(Map<String, dynamic>.from(
                      mutation.parameters['map'] as Map))
          },
          mutations: draft.mutations);
      expect(projected.smartTileCatalog.animations.single.loop,
          SmartTileAnimationLoop.once);
      final semantic = draft.compositionEvidence['sourceSemantics'] as Map;
      expect(
          semantic['projection']['grassRustle']['sourceTerrainTags'], [2, 14]);
      final originalAnimation = draft.mutations.singleWhere(
          (mutation) => mutation.actionId == 'smart_tile.animation.upsert');
      final changedAnimation = Map<String, Object?>.from(
          originalAnimation.parameters['animation'] as Map);
      final changedFrames = (changedAnimation['frames'] as List)
          .map((frame) => Map<String, Object?>.from(frame as Map))
          .toList();
      changedFrames[1]['durationMs'] = 999;
      changedAnimation['frames'] = changedFrames;
      final tampered = NativeProjectDraft(
          source: draft.source,
          projectName: draft.projectName,
          parentPath: draft.parentPath,
          folderName: draft.folderName,
          sourceRootPath: draft.sourceRootPath,
          mapIds: draft.mapIds,
          artifacts: draft.artifacts,
          sourceArtifacts: draft.sourceArtifacts,
          compositionEvidence: draft.compositionEvidence,
          defaultMapWidth: draft.defaultMapWidth,
          defaultMapHeight: draft.defaultMapHeight,
          mutations: [
            for (final mutation in draft.mutations)
              if (mutation == originalAnimation)
                copyNativeFixtureMutation(mutation,
                    parameters: {'animation': changedAnimation})
              else
                mutation
          ]);
      final tamperedApproval = approveNativeFixtureDraft(tampered);
      await expectLater(
          NativeProjectWriter()
              .write(tamperedApproval.plan, tamperedApproval.context, tampered),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.semantics.regeneration')));
      final approval = approveNativeFixtureDraft(draft);
      final receipt = await NativeProjectWriter()
          .write(approval.plan, approval.context, draft);
      expect(receipt.verified, isTrue);
      final manifest = ProjectManifest.fromJson(jsonDecode(
          await File('${receipt.projectPath}/project.json').readAsString()));
      expect(manifest.smartTileCatalog.animations, hasLength(1));
      final first = MapData.fromJson(jsonDecode(
          await File('${receipt.projectPath}/maps/${draft.mapIds[1]}.json')
              .readAsString()));
      final second = MapData.fromJson(jsonDecode(
          await File('${receipt.projectPath}/maps/${draft.mapIds[2]}.json')
              .readAsString()));
      final layer = first.layers.whereType<SmartTileLayer>().single;
      expect(layer.animationActivation, SmartTileAnimationActivation.onEnter);
      expect([
        for (var y = 0; y < 3; y++)
          for (var x = 0; x < 3; x++)
            (smartTileMaterialIdAt(layer, mapSize: first.size, x: x, y: y)
                        ?.isNotEmpty ??
                    false)
                ? 1
                : 0
      ], [
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0
      ]);
      expect(second.layers.whereType<SmartTileLayer>(), isEmpty);
      final animation = manifest.smartTileCatalog.animations.single;
      expect(animation.frames.map((frame) => frame.durationMs),
          [1, ...List.filled(9, 50), 1]);
      final atlas = manifest.tilesets.singleWhere((entry) =>
          entry.id == manifest.smartTileCatalog.atlases.single.tilesetId);
      expect(
          await File('${receipt.projectPath}/${atlas.relativePath}').exists(),
          isTrue);
      expect(first.gameplayZones, isEmpty);
      final changed = fixture
          .files.bytes['Graphics/Animations/Original grass atlas.png']!
          .toList()
        ..[0] ^= 1;
      fixture.files.overrides['Graphics/Animations/Original grass atlas.png'] =
          changed;
      await expectLater(
          const SourceGrassRustleCompiler().compile(
              source: source, files: fixture.files, nativeMapIds: draft.mapIds),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'grass_rustle.source.changed')));
    } finally {
      await root.delete(recursive: true);
    }
  },
      skip: scriptsPath == null
          ? 'Explicit attested script archive required'
          : false);

  test(
      'unqualified source does not invent a grass effect or read animation files',
      () async {
    final fixture = await _fixture([4, 8, 48]);
    final before = fixture.files.reads.length;
    expect(
        await const SourceGrassRustleCompiler().compile(
            source: fixture.source,
            files: fixture.files,
            nativeMapIds: {1: 'native-1', 2: 'native-2'}),
        isNull);
    expect(fixture.files.reads.length, before);
  });
  test(
      'compiles source cells into native 32px frames with exact RGSS placement',
      () {
    final source = image.Image(width: 768, height: 384, numChannels: 4);
    source.setPixelRgba(3 * 192 + 82, 84, 10, 20, 30, 255);
    source.setPixelRgba(82, 192 + 90, 50, 60, 70, 127);
    final compiled = SourceGrassRustleRaster.compile(
      animationArchiveBytes: _archive(),
      animationPngBytes: image.encodePng(source),
    );
    final raster = image.decodePng(compiled.imageBytes)!;
    expect(compiled.frameCount, 9);
    expect(compiled.animationName, 'Original grass');
    expect(compiled.animationImageName, 'Original grass atlas');
    expect(raster.width, 10 * 32);
    expect(raster.height, 32);
    expect(raster.getPixel(2, 4).a, 0);
    expect(_rgba(raster.getPixel(32 + 2, 4)), [10, 20, 30, 255]);
    expect(_rgba(raster.getPixel(4 * 32 + 2, 10)), [50, 60, 70, 127]);
  });

  for (final entry in <String, Map<String, Object?>>{
    'rotation': {'rotation': 15},
    'zoom': {'zoom': 110},
    'timing': {'timing': true},
    'hue': {'hue': 40},
    'screen anchoring': {'position': 3},
    'multiple cells': {'cellMax': 2},
  }.entries) {
    test('rejects unsupported source ${entry.key} instead of approximating',
        () {
      expect(
        () => SourceGrassRustleRaster.compile(
          animationArchiveBytes: _archive(options: entry.value),
          animationPngBytes: image
              .encodePng(image.Image(width: 768, height: 384, numChannels: 4)),
        ),
        throwsA(isA<NativeWriteException>()),
      );
    });
  }

  test('rejects opaque pixels outside the native cell instead of cropping them',
      () {
    final source = image.Image(width: 768, height: 384, numChannels: 4);
    source.setPixelRgba(3 * 192, 0, 100, 100, 100, 255);
    expect(
      () => SourceGrassRustleRaster.compile(
        animationArchiveBytes: _archive(),
        animationPngBytes: image.encodePng(source),
      ),
      throwsA(isA<NativeWriteException>()),
    );
  });

  test('rejects compiled frame pixels exceeding one image budget', () {
    expect(
        () => SourceGrassRustleRaster.compile(
            animationArchiveBytes:
                _archive(options: {'frameCount': 256, 'pattern': 0}),
            animationPngBytes: image.encodePng(
                image.Image(width: 192, height: 192, numChannels: 4)),
            limits: const NativeWriteLimits(maxImagePixels: 40000)),
        throwsA(isA<NativeWriteException>()));
  });

  test('rejects bounded image quota before decoding its raster', () {
    expect(
      () => SourceGrassRustleRaster.compile(
        animationArchiveBytes: _archive(),
        animationPngBytes: image
            .encodePng(image.Image(width: 768, height: 384, numChannels: 4)),
        limits: const NativeWriteLimits(maxImagePixels: 1024),
      ),
      throwsA(isA<NativeWriteException>()),
    );
  });
}

List<num> _rgba(image.Pixel p) => [p.r, p.g, p.b, p.a];

List<int> _archive({Map<String, Object?> options = const {}}) =>
    literalFixtureMarshal([
      null,
      LiteralFixtureObject('RPG::Animation', {
        '@id': 1,
        '@name': 'Original grass',
        '@animation_name': 'Original grass atlas',
        '@animation_hue': options['hue'] ?? 0,
        '@position': options['position'] ?? 1,
        '@frame_max': options['frameCount'] ?? 9,
        '@timings': options['timing'] == true ? [1] : <Object?>[],
        '@frames': [
          for (var i = 0; i < ((options['frameCount'] ?? 9) as int); i++)
            LiteralFixtureObject('RPG::Animation::Frame', {
              '@cell_max': options['cellMax'] ?? 1,
              '@cell_data': LiteralFixtureUserDefined(
                  'Table',
                  _table([
                    (options['pattern'] ??
                        (i < 3
                            ? 3
                            : i < 6
                                ? 5
                                : 6)) as int,
                    0,
                    -16,
                    (options['zoom'] ?? 100) as int,
                    (options['rotation'] ?? 0) as int,
                    0,
                    255,
                    0
                  ])),
            }),
        ],
      }),
    ]);

Uint8List _table(List<int> values) {
  final data = ByteData(20 + values.length * 2)
    ..setInt32(0, 2, Endian.little)
    ..setInt32(4, 1, Endian.little)
    ..setInt32(8, 8, Endian.little)
    ..setInt32(12, 1, Endian.little)
    ..setInt32(16, 8, Endian.little);
  for (var i = 0; i < values.length; i++) {
    data.setInt16(20 + i * 2, values[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

Future<LiteralTileFixture> _fixture(List<int> scriptsBytes) async {
  final png = image.Image(width: 768, height: 384, numChannels: 4);
  png.setPixelRgba(3 * 192 + 82, 84, 10, 20, 30, 255);
  return LiteralTileFixture.create(scriptsBytes: scriptsBytes, maps: [
    LiteralFixtureMap(id: 1, width: 3, height: 3, layers: [
      [384, 385, 384, 384, 385, 384, 384, 384, 384],
      [0, 386, 0, 0, 0, 0, 0, 0, 0],
      List.filled(9, 0)
    ]),
    LiteralFixtureMap(
        id: 2,
        width: 3,
        height: 3,
        layers: [List.filled(9, 384), List.filled(9, 0), List.filled(9, 0)])
  ], tilesets: [
    LiteralFixtureTileset(id: 1, terrainTags: {385: 2, 386: 3})
  ], extraFiles: {
    'Data/Animations.rxdata': _archive(),
    'Graphics/Animations/Original grass atlas.png': image.encodePng(png),
    'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
    'Graphics/Characters/OriginalPlayer.png':
        image.encodePng(image.Image(width: 128, height: 192, numChannels: 4))
  });
}
