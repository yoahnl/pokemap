import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/original_autotile_fixture.dart';

void main() {
  for (final hasTransparency in [false, true]) {
    test(
        'AUTO-04 indexed 4-bit ${hasTransparency ? 'RGBA transparency' : 'RGB opacity'} survives every frame and variant',
        () async {
      final png = originalIndexedAutotilePng(hasTransparency: hasTransparency);
      expect(png[24], 4);
      expect(png[25], 3);
      final decodedSource = image.decodePng(Uint8List.fromList(png))!;
      expect(decodedSource.palette!.numChannels, hasTransparency ? 4 : 3);
      final source = await _Source.open(png);
      addTearDown(source.close);
      final result = await _compose(source);
      final output = image.decodePng(Uint8List.fromList(result.artifact.bytes))!;
      expect(result.sourceFrameCount, 5);
      expect(result.sourceArtifact.bytes, png);
      for (var frame = 0; frame < 5; frame++) {
        for (var variant = 0; variant < 48; variant++) {
          for (var y = 0; y < 32; y++) {
            for (var x = 0; x < 32; x++) {
              final sourceX = frame * 32 + x;
              final index = (sourceX + y * 3 + frame) % 16;
              final pixel = output.getPixel(
                  variant % 8 * 32 + x, (frame * 6 + variant ~/ 8) * 32 + y);
              expect([
                pixel.r,
                pixel.g,
                pixel.b,
                pixel.a
              ], [
                17 + index * 13,
                239 - index * 11,
                31 + index * 7,
                hasTransparency ? [0, 73, 255][index % 3] : 255
              ], reason: 'frame=$frame variant=$variant x=$x y=$y');
            }
          }
        }
      }
      await source.files.verifyUnchanged();
    }, skip: !Platform.isMacOS);
  }
  test('AUTO-02 common attested clock helper derives bounded source duration',
      () {
    expect(
        LiteralAutotileComposer.attestedFrameDurationMs('OriginalWater'), 250);
    expect(
        LiteralAutotileComposer.attestedFrameDurationMs('OriginalWater[ 4 ] '),
        200);
    expect(LiteralAutotileComposer.attestedFrameDurationMs('OriginalWater[0]'),
        isNull);
    expect(
        LiteralAutotileComposer.attestedFrameDurationMs(
            'OriginalWater[368934881474191033]'),
        isNull);
    expect(
        LiteralAutotileComposer.attestedFrameDurationMs(
            'OriginalWater[42949672]'),
        2147483600);
    expect(
        LiteralAutotileComposer.attestedFrameDurationMs(
            'OriginalWater[42949673]'),
        isNull);
  });
  final scriptsPath = Platform.environment['AVELUNE_AUTOTILE_SCRIPTS_PATH'];
  for (final format in [
    OriginalAutotileFormat.standard,
    OriginalAutotileFormat.simple
  ]) {
    test('AUTO-01 independent 48 variant oracle ${format.name}', () async {
      final fixture = format == OriginalAutotileFormat.standard
          ? OriginalAutotileFixture.standard()
          : OriginalAutotileFixture.simple();
      final source = await _Source.open(fixture.pngBytes);
      addTearDown(source.close);
      final result = await _compose(source);
      _expectOracle(result, fixture);
      expect(result.firstFrameOnly, isTrue);
      expect(result.degraded, isTrue);
      expect(result.diagnostics.map((value) => value.code),
          contains('autotile.clock.unverified'));
      final repeated = await _compose(source);
      expect(repeated.compositionHash, result.compositionHash);
      expect(repeated.artifact.bytes, result.artifact.bytes);
      expect(
          () => result.provenance['format'] = 'forged', throwsUnsupportedError);
      expect(() => result.artifact.bytes[0] = 0, throwsUnsupportedError);
      expect(() => result.localTileId(variant: 48), throwsRangeError);
      expect(() => result.localTileId(frame: 3, variant: 0), throwsRangeError);
      await source.files.verifyUnchanged();
    }, skip: !Platform.isMacOS);
  }
  test('AUTO-01 extended geometry requires exact renderer attestation',
      () async {
    final source =
        await _Source.open(OriginalAutotileFixture.extended().pngBytes);
    addTearDown(source.close);
    await expectLater(
        _compose(source),
        throwsA(isA<LiteralAutotileFailure>().having(
            (value) => value.code, 'code', 'autotile.extended.unverified')));
  }, skip: !Platform.isMacOS);
  test('AUTO-02 snapshot foreign profile rejected before source read',
      () async {
    final source =
        await _Source.open(OriginalAutotileFixture.simple().pngBytes);
    addTearDown(source.close);
    await expectLater(
        const LiteralAutotileComposer().compose(
            source: source.project,
            files: source.files,
            sourceTilesetId: 1,
            autotileSlot: 0,
            profile: LiteralAutotileProfile.unverified(
                sourceSnapshotHash: Sha256Hash('0' * 64))),
        throwsA(isA<LiteralAutotileFailure>().having(
            (value) => value.code, 'code', 'autotile.profile.snapshot')));
  }, skip: !Platform.isMacOS);
  test('split image budget admits a bounded autotile PNG below its separate total', () async {
    final fixture = OriginalAutotileFixture.simple();
    final source = await _Source.open(fixture.pngBytes);
    addTearDown(source.close);
    final result = await _compose(source, limits: const NativeWriteLimits(
      maxImagePixels: 147456,
      maxTotalImagePixels: 150528,
    ));
    expect(result.pixelWidth * result.pixelHeight, 147456);
    expect(result.sourcePixelWidth * result.sourcePixelHeight, 3072);
  }, skip: !Platform.isMacOS);

  test('split image budget refuses a generated PNG above the individual cap', () async {
    final source = await _Source.open(OriginalAutotileFixture.simple().pngBytes);
    addTearDown(source.close);
    await expectLater(_compose(source, limits: const NativeWriteLimits(
      maxImagePixels: 147455,
      maxTotalImagePixels: 150528,
    )), throwsA(isA<LiteralAutotileFailure>().having(
      (value) => value.code, 'code', 'autotile.quota.pixels')));
  }, skip: !Platform.isMacOS);

  test('AUTO-04 generated plus source pixels checked before allocation',
      () async {
    final fixture = OriginalAutotileFixture.simple();
    final source = await _Source.open(fixture.pngBytes);
    addTearDown(source.close);
    await expectLater(
        _compose(source,
            limits: const NativeWriteLimits(maxTotalImagePixels: 147456)),
        throwsA(isA<LiteralAutotileFailure>()
            .having((value) => value.code, 'code', 'autotile.quota.pixels')));
  }, skip: !Platform.isMacOS);
  test('AUTO-04 generated raw output bound checked before allocation',
      () async {
    final fixture = OriginalAutotileFixture.simple();
    final source = await _Source.open(fixture.pngBytes);
    addTearDown(source.close);
    await expectLater(
        _compose(source,
            limits: const NativeWriteLimits(maxArtifactBytes: 20000)),
        throwsA(isA<LiteralAutotileFailure>()
            .having((value) => value.code, 'code', 'autotile.quota.output')));
  }, skip: !Platform.isMacOS);
  test('AUTO-04 cancellation exits before raster allocation', () async {
    final source =
        await _Source.open(OriginalAutotileFixture.simple().pngBytes);
    addTearDown(source.close);
    final cancellation = ScanCancellation()..cancel();
    await expectLater(
        _compose(source, cancellation: cancellation),
        throwsA(isA<ContractError>()
            .having((value) => value.code, 'code', 'source.cancelled')));
  }, skip: !Platform.isMacOS);
  test('AUTO-02 unverified scripts remain unverified without execution',
      () async {
    final source = await _Source.open(OriginalAutotileFixture.simple().pngBytes,
        scriptsBytes: [4, 8, 48]);
    addTearDown(source.close);
    final profile = await const LiteralAutotileComposer()
        .inspectProfile(snapshot: source.snapshot, files: source.files);
    expect(profile.clockAttested, isFalse);
    expect(profile.extendedAttested, isFalse);
    expect(profile.sourceSnapshotHash, source.snapshot.canonicalHash);
  }, skip: !Platform.isMacOS);
  test('AUTO-02 incomplete selected autotile profile is rejected', () async {
    final source = await _Source.open(OriginalAutotileFixture.simple().pngBytes,
        scriptsBytes: [4, 8, 48]);
    addTearDown(source.close);
    await expectLater(
        const LiteralAutotileComposer().inspectProfile(
            interpretationProfile: fixtureSourceInterpretationProfile,
            snapshot: source.snapshot,
            files: source.files),
        throwsA(isA<LiteralAutotileFailure>().having(
            (failure) => failure.code, 'code', 'autotile.profile.sections')));
  }, skip: !Platform.isMacOS);
  test('AUTO-02 large full conversion keeps bounded script decoding', () async {
    final source = await _Source.open(OriginalAutotileFixture.simple().pngBytes,
        scriptsBytes: syntheticInterpretationArchive);
    addTearDown(source.close);
    final interpretation = SourceInterpretationProfile.fromJson({
      ...syntheticSourceInterpretationProfile.toJson(),
      'capabilities': ['autotiles'],
      'sections': {
        for (final role in ['TilemapRenderer', 'AutotileExpander', 'TileDrawingHelper'])
          'autotiles.$role': syntheticSourceInterpretationProfile.sections['events.Interpreter'],
      },
    });
    final profile = await const LiteralAutotileComposer().inspectProfile(
        snapshot: source.snapshot,
        files: source.files,
        interpretationProfile: interpretation,
        limits: sourceCatalogStudyWriteLimitsFor(383,
            includeNativeCatalog: true, fullGameContent: true));
    expect(profile.clockAttested, isTrue);
    expect(profile.extendedAttested, isTrue);
    expect(profile.sourceSnapshotHash, source.snapshot.canonicalHash);
  }, skip: !Platform.isMacOS);
  for (final format in OriginalAutotileFormat.values) {
    test('AUTO-02 exact Kanto profile ${format.name} three frame clock',
        () async {
      final fixture = switch (format) {
        OriginalAutotileFormat.standard => OriginalAutotileFixture.standard(),
        OriginalAutotileFormat.extended => OriginalAutotileFixture.extended(),
        OriginalAutotileFormat.simple => OriginalAutotileFixture.simple()
      };
      final source = await _Source.open(fixture.pngBytes,
          scriptsBytes: await File(scriptsPath!).readAsBytes());
      addTearDown(source.close);
      final profile = await const LiteralAutotileComposer()
          .inspectProfile(interpretationProfile: fixtureSourceInterpretationProfile, snapshot: source.snapshot, files: source.files);
      expect(profile.clockAttested, isTrue);
      expect(profile.extendedAttested, isTrue);
      expect(profile.baseFrameDurationMs, 250);
      final result = await _compose(source, profile: profile);
      _expectOracle(result, fixture);
      expect(result.animationVerified, isTrue);
      expect(result.tileAnimations.length, 48);
      final atlas = ProjectTilesetSource.regularAtlas(
          tileWidth: 32,
          tileHeight: 32,
          assetId: 'original_atlas',
          pixelWidth: result.pixelWidth,
          pixelHeight: result.pixelHeight,
          tileAnimations: result.tileAnimations);
      final timeline = const ProjectTilesetVisualResolver().resolve(
          source: atlas,
          selection: const ProjectTilesetVisualSelection.regularAtlas(
              source: TilesetSourceRect(x: 7, y: 5, width: 1, height: 1)),
          cellWidth: 32,
          cellHeight: 32);
      for (final sample in [
        (0, 0),
        (249, 0),
        (250, 1),
        (499, 1),
        (500, 2),
        (749, 2),
        (750, 0),
        (1000, 1)
      ]) {
        final rect = timeline.frameAt(sample.$1).slices.single.sourceRect;
        expect(rect.x, 224);
        expect(rect.y, sample.$2 * 192 + 160);
      }
      final degraded = await _compose(source,
          profile: profile, nativeAnimationAvailable: false);
      expect(degraded.tileAnimations, isEmpty);
      expect(degraded.firstFrameOnly, isTrue);
      expect(degraded.degraded, isTrue);
      expect(degraded.artifact.bytes, result.artifact.bytes);
      expect(degraded.compositionHash, isNot(result.compositionHash));
      await source.files.verifyUnchanged();
    }, skip: !Platform.isMacOS || scriptsPath == null);
  }
  test('AUTO-02 Kanto suffix four gives source 200ms explicit base clock',
      () async {
    final source = await _Source.open(
        OriginalAutotileFixture.standard().pngBytes,
        name: 'Water[4]',
        scriptsBytes: await File(scriptsPath!).readAsBytes());
    addTearDown(source.close);
    final profile = await const LiteralAutotileComposer()
        .inspectProfile(interpretationProfile: fixtureSourceInterpretationProfile, snapshot: source.snapshot, files: source.files);
    final result = await _compose(source, profile: profile);
    expect(result.frameDurationMs, 200);
    expect(
        result.tileAnimations.every(
            (value) => value.frames.every((frame) => frame.durationMs == 200)),
        isTrue);
  }, skip: !Platform.isMacOS || scriptsPath == null);
  test('AUTO-02 source clock suffix integer overflow is degraded explicitly',
      () async {
    final source = await _Source.open(OriginalAutotileFixture.simple().pngBytes,
        name: 'Water[368934881474191033]',
        scriptsBytes: await File(scriptsPath!).readAsBytes());
    addTearDown(source.close);
    final profile = await const LiteralAutotileComposer()
        .inspectProfile(interpretationProfile: fixtureSourceInterpretationProfile, snapshot: source.snapshot, files: source.files);
    final result = await _compose(source, profile: profile);
    expect(result.frameDurationMs, isNull);
    expect(result.tileAnimations, isEmpty);
    expect(result.degraded, isTrue);
    expect(result.diagnostics.map((value) => value.code),
        contains('autotile.clock.invalid'));
  }, skip: !Platform.isMacOS || scriptsPath == null);
  for (final name in ['Water[ 4 ]', 'Water[4] ']) {
    test(
        'AUTO-02 source clock accepts attested suffix whitespace ${name.codeUnits}',
        () async {
      final source = await _Source.open(
          OriginalAutotileFixture.simple().pngBytes,
          name: name,
          scriptsBytes: await File(scriptsPath!).readAsBytes());
      addTearDown(source.close);
      final profile = await const LiteralAutotileComposer()
          .inspectProfile(interpretationProfile: fixtureSourceInterpretationProfile, snapshot: source.snapshot, files: source.files);
      final result = await _compose(source, profile: profile);
      expect(result.frameDurationMs, 200);
      expect(result.animationVerified, isTrue);
    }, skip: !Platform.isMacOS || scriptsPath == null);
  }
  test(
      'AUTO-04 PNG RGBA16 retains every channel exactly including transparent RGB',
      () async {
    final original = image.Image(
        width: 32, height: 32, format: image.Format.uint16, numChannels: 4);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        original.setPixelRgba(x, y, 517 + x * 1501, 1027 + y * 137, 63217,
            x % 2 == 0 ? 0 : 33791);
      }
    }
    final source = await _Source.open(image.encodePng(original));
    addTearDown(source.close);
    final result = await _compose(source);
    expect(result.degraded, isFalse);
    expect(result.artifact.bytes[24], 16);
    final output = image.decodePng(Uint8List.fromList(result.artifact.bytes))!;
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        final pixel = output.getPixel(x + 224, y + 160);
        expect([pixel.r, pixel.g, pixel.b, pixel.a],
            [517 + x * 1501, 1027 + y * 137, 63217, x % 2 == 0 ? 0 : 33791]);
      }
    }
  }, skip: !Platform.isMacOS);
  test('AUTO-01 simple atlas retains three frames and all stored variants',
      () async {
    final original = image.Image(width: 96, height: 32, numChannels: 4);
    for (var y = 0; y < original.height; y++) {
      for (var x = 0; x < original.width; x++) {
        original.setPixelRgba(
            x, y, x ~/ 32 * 53 + 11, x % 32, y, (x + y) % 3 == 0 ? 0 : 127);
      }
    }
    final source = await _Source.open(image.encodePng(original));
    addTearDown(source.close);
    final result = await const LiteralAutotileComposer().compose(
      source: source.project,
      files: source.files,
      sourceTilesetId: 1,
      autotileSlot: 0,
      profile: LiteralAutotileProfile.unverified(
          sourceSnapshotHash: source.snapshot.canonicalHash),
    );
    expect(result.sourceFrameCount, 3);
    expect(result.pixelWidth, 256);
    expect(result.pixelHeight, 576);
    expect(result.tileAnimations, isEmpty);
    expect(result.firstFrameOnly, isTrue);
    expect(result.degraded, isTrue);
    final output = image.decodePng(Uint8List.fromList(result.artifact.bytes))!;
    for (var frame = 0; frame < 3; frame++) {
      for (var variant = 0; variant < 48; variant++) {
        expect(result.localTileId(frame: frame, variant: variant),
            frame * 48 + variant);
        for (var y = 0; y < 32; y++) {
          for (var x = 0; x < 32; x++) {
            final pixel = output.getPixel(
                variant % 8 * 32 + x, (frame * 6 + variant ~/ 8) * 32 + y);
            expect([
              pixel.r,
              pixel.g,
              pixel.b,
              pixel.a
            ], [
              frame * 53 + 11,
              x,
              y,
              (frame * 32 + x + y) % 3 == 0 ? 0 : 127
            ]);
          }
        }
      }
    }
    await source.files.verifyUnchanged();
  }, skip: !Platform.isMacOS);
}

Future<LiteralAutotileComposition> _compose(_Source source,
        {LiteralAutotileProfile? profile,
        NativeWriteLimits limits = const NativeWriteLimits(),
        ScanCancellation? cancellation,
        bool nativeAnimationAvailable = true}) =>
    const LiteralAutotileComposer().compose(
        source: source.project,
        files: source.files,
        sourceTilesetId: 1,
        autotileSlot: 0,
        profile: profile ??
            LiteralAutotileProfile.unverified(
                sourceSnapshotHash: source.snapshot.canonicalHash),
        limits: limits,
        cancellation: cancellation,
        nativeAnimationAvailable: nativeAnimationAvailable);

void _expectOracle(
    LiteralAutotileComposition result, OriginalAutotileFixture fixture) {
  expect(result.sourceArtifact.bytes, fixture.pngBytes);
  expect(result.sourceArtifact.rawSha256.value, fixture.pngSha256);
  expect(result.sourceFrameCount, fixture.frameCount);
  expect(result.sourcePixelWidth, fixture.width);
  expect(result.sourcePixelHeight, fixture.height);
  final output = image.decodePng(Uint8List.fromList(result.artifact.bytes))!;
  final oracle = OriginalAutotileOracle.load();
  final format = OriginalAutotileFormat.values
      .singleWhere((format) => format.name == result.format.name);
  for (var frame = 0; frame < fixture.frameCount; frame++) {
    for (var variant = 0; variant < 48; variant++) {
      final parts = result.sourceParts(frame: frame, variant: variant);
      final rectangles = oracle.sourceRects[format]![variant];
      expect(parts.length, 4);
      for (var index = 0; index < 4; index++) {
        expect([
          parts[index].x,
          parts[index].y,
          parts[index].width,
          parts[index].height,
          parts[index].destinationX,
          parts[index].destinationY
        ], [
          frame * fixture.frameWidth + rectangles[index].x,
          rectangles[index].y,
          16,
          16,
          index % 2 * 16,
          index ~/ 2 * 16
        ]);
      }
      expect(() => parts.clear(), throwsUnsupportedError);
      final rgba = Uint8List(32 * 32 * 4);
      var position = 0;
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          final pixel = output.getPixel(
              variant % 8 * 32 + x, (frame * 6 + variant ~/ 8) * 32 + y);
          rgba[position++] = pixel.r.toInt();
          rgba[position++] = pixel.g.toInt();
          rgba[position++] = pixel.b.toInt();
          rgba[position++] = pixel.a.toInt();
        }
      }
      expect(rgba, fixture.expectedRgba(frame: frame, variant: variant),
          reason:
              '${fixture.width}x${fixture.height} frame=$frame variant=$variant');
    }
  }
}

final class _Source {
  _Source(this.directory, this.tree, this.snapshot, this.files, this.project);

  final Directory directory;
  final MacOsSourceTree tree;
  final SourceSnapshot snapshot;
  final SnapshotSourceFiles files;
  final NormalizedSourceProject project;

  static Future<_Source> open(List<int> pngBytes,
      {String name = 'Water', List<int>? scriptsBytes}) async {
    final directory =
        await Directory.systemTemp.createTemp('ac07-original-autotile-');
    MacOsSourceTree? tree;
    try {
      await LiteralTileFixture.create(
        sourceRootPath: directory.path,
        maps: [
          LiteralFixtureMap(id: 1, layers: const [
            [48, 95, 48],
            [0, 0, 0],
            [0, 0, 0]
          ])
        ],
        tilesets: [
          LiteralFixtureTileset(id: 1, png: pngBytes, autotileNames: [name])
        ],
      );
      if (scriptsBytes != null) {
        await File('${directory.path}/Data/Scripts.rxdata')
            .writeAsBytes(scriptsBytes, flush: true);
      }
      tree = await MacOsSourceTree.open(directory.path);
      final snapshot = await SourceScanner().scan(
          source: tree,
          logicalProjectNamespace: ConverterId('ac07-original-autotile'));
      final files =
          await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
      final project = await const RmxpSourceNormalizer()
          .normalize(snapshot: snapshot, files: files, selectedMapIds: {1});
      expect(project.canPlan, isTrue);
      return _Source(directory, tree, snapshot, files, project);
    } catch (_) {
      await tree?.close();
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> close() async {
    await tree.close();
    await directory.delete(recursive: true);
  }
}
