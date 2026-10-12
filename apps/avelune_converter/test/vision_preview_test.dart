import 'dart:async';
import 'dart:typed_data';

import 'package:avelune_converter/vision_preview.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

final class PreviewFiles implements SourceFilePort {
  PreviewFiles(this.bytes, {this.gate, this.onRead});
  final List<int> bytes;
  final Future<void>? gate;
  final void Function()? onRead;
  final reads = <ConverterId>[];

  @override
  Future<List<int>> read(ConverterId fileId) async {
    reads.add(fileId);
    onRead?.call();
    if (gate case final pending?) await pending;
    return bytes;
  }
}

List<int> sourcePng() {
  final raster = image.Image(width: 6, height: 5, numChannels: 4);
  for (var y = 0; y < raster.height; y++) {
    for (var x = 0; x < raster.width; x++) {
      final label = y * 6 + x;
      raster.setPixelRgba(
        x,
        y,
        label,
        label + 40,
        label + 80,
        label % 3 == 0 ? 0 : 127,
      );
    }
  }
  return image.encodePng(raster);
}

AssetCandidate candidate(
  List<int> png, {
  String id = 'candidate-a',
  String partId = 'part-a',
  int turns = 0,
  bool reflected = false,
  int partCount = 1,
  int sourceWidth = 6,
}) => AssetCandidate.fromJson({
  'schemaVersion': '1.0',
  'kind': 'assetCandidate',
  'exampleOnly': false,
  'candidateId': id,
  'revision': 1,
  'logicalProjectNamespace': 'preview-test',
  'sourceSnapshotHash': 'a' * 64,
  'sources': [
    {
      'fileId': 'source-image',
      'contentHash': NativeArtifact(bytes: png).rawSha256.value,
      'pixelWidth': sourceWidth,
      'pixelHeight': 5,
    },
  ],
  'name': 'Objet source',
  'category': 'unclassified',
  'state': 'needsReview',
  'parts': [
    for (var i = 0; i < partCount; i++)
      {
        'partId': partCount == 1 ? partId : '$partId-$i',
        'sourceFileId': 'source-image',
        'sourceRect': {'x': 1, 'y': 1, 'width': 2, 'height': 3},
        'destinationOffset': {'x': 0, 'y': 0},
        'sourceLayer': null,
        'sourcePriority': null,
        'quarterTurns': turns,
        'reflected': reflected,
        'locator': {
          'file': 'Graphics/Tilesets/Preview.png',
          'mapId': null,
          'eventId': null,
          'pageIndex': null,
          'commandIndex': null,
          'tileId': null,
          'line': null,
        },
      },
  ],
  'canvasSize': {'width': 8, 'height': 8},
  'anchor': {'unit': 'pixel', 'x': 0, 'y': 0, 'convention': 'explicit'},
  'integrationMode': 'libraryOnly',
  'outputMode': 'standaloneObjects',
  'evidence': [
    {
      'type': 'test',
      'summary': 'Original pixels',
      'reference': 'test:vision-preview',
    },
  ],
  'uncertainties': [],
  'approvedRevision': null,
});

AssetReviewSession review(List<AssetCandidate> candidates) =>
    AssetReviewSession.create(
      sessionId: ConverterId('preview-session'),
      logicalProjectNamespace: ConverterId('preview-test'),
      sourceSnapshotHash: Sha256Hash('a' * 64),
      selectedSourceMapIds: const [98],
      outputMode: AssetOutputMode.standaloneObjects,
      proposalGenerationHash: canonicalHashOf('preview-generation'),
      candidates: candidates,
    );

Future<VisionMaterial> preview(
  AssetReviewSession session,
  PreviewFiles files, {
  Set<ConverterId>? ids,
  ScanCancellation? cancellation,
  String requestId = 'preview-request-1',
  VisionLimits limits = const VisionLimits(),
  Map<String, Object?> options = const {},
}) => buildVisionPreview(
  session: session,
  candidateIds:
      ids ?? session.activeCandidates.map((c) => c.candidateId).toSet(),
  sourceFiles: files,
  requestId: ConverterId(requestId),
  model: 'documented-model',
  promptVersion: 'prompt-1',
  options: options,
  limits: limits,
  cancellation: cancellation,
);

List<List<int>> labels(int turns, bool reflected) {
  var rows = <List<int>>[
    [7, 8],
    [13, 14],
    [19, 20],
  ];
  if (reflected) rows = rows.map((row) => row.reversed.toList()).toList();
  for (var i = 0; i < turns; i++) {
    rows = [
      for (var x = 0; x < rows.first.length; x++)
        [for (var y = rows.length - 1; y >= 0; y--) rows[y][x]],
    ];
  }
  return rows;
}

void main() {
  for (final turns in [0, 1, 2, 3]) {
    for (final reflected in [false, true]) {
      test(
        'lossless source crop with Hflip $reflected before clockwise rotation $turns',
        () async {
          final bytes = sourcePng();
          final current = candidate(bytes, turns: turns, reflected: reflected);
          final session = review([current]);
          final before = session.canonicalHash;
          final files = PreviewFiles(bytes);
          final material = await preview(session, files);
          final crop = material.crops.single;
          final decoded = image.decodePng(Uint8List.fromList(crop.pngBytes))!;
          final expected = labels(turns, reflected);
          expect(decoded.width, expected.first.length);
          expect(decoded.height, expected.length);
          for (var y = 0; y < decoded.height; y++) {
            for (var x = 0; x < decoded.width; x++) {
              final label = expected[y][x];
              final pixel = decoded.getPixel(x, y);
              expect(
                [pixel.r, pixel.g, pixel.b, pixel.a],
                [label, label + 40, label + 80, label % 3 == 0 ? 0 : 127],
              );
            }
          }
          expect(
            crop.regionId,
            visionRegionId(current.candidateId, current.parts.single.partId),
          );
          expect(crop.fileId, current.sources.single.fileId);
          expect(crop.sourceHash, current.sources.single.contentHash);
          expect(crop.sourceRect, current.parts.single.sourceRect.toJson());
          expect(crop.quarterTurns, turns);
          expect(crop.reflected, reflected);
          expect(crop.transformVersion, '1');
          expect(() => crop.pngBytes.add(0), throwsUnsupportedError);
          expect(session.canonicalHash, before);
          expect(files.reads, [current.sources.single.fileId]);
        },
      );
    }
  }

  test('material contains exact selected hashes and one source read for multiple parts', () async {
    final bytes = sourcePng();
    final first = candidate(bytes);
    final second = candidate(bytes, id: 'candidate-b', partId: 'part-b');
    final session = review([
      first,
      second,
      candidate(bytes, id: 'candidate-c', partId: 'part-c'),
    ]);
    final files = PreviewFiles(bytes);
    final material = await preview(
      session,
      files,
      ids: {second.candidateId, first.candidateId},
      options: {'detail': 'low', 'maxOutputTokens': 512},
    );
    expect(material.context.requestId, ConverterId('preview-request-1'));
    expect(material.context.sourceSnapshotHash, session.sourceSnapshotHash);
    expect(material.context.inputRevision, session.revision);
    expect(material.expectedSessionHash, session.canonicalHash);
    expect(material.context.candidateIds, {
      first.candidateId,
      second.candidateId,
    });
    expect(material.context.sourceRegionIds, {
      visionRegionId(first.candidateId, first.parts.single.partId),
      visionRegionId(second.candidateId, second.parts.single.partId),
    });
    expect(material.candidateHashes, {
      first.candidateId: first.canonicalHash,
      second.candidateId: second.canonicalHash,
    });
    expect(material.crops, hasLength(2));
    expect(material.model, 'documented-model');
    expect(material.promptVersion, 'prompt-1');
    expect(material.options, {'detail': 'low', 'maxOutputTokens': 512});
    expect(files.reads, hasLength(1));
    final reordered = await preview(
      session,
      PreviewFiles(bytes),
      ids: {first.candidateId, second.candidateId},
      requestId: 'preview-request-2',
      options: {'detail': 'low', 'maxOutputTokens': 512},
    );
    expect(reordered.selectionHash, material.selectionHash);
    expect(reordered.canonicalHash, isNot(material.canonicalHash));
  });

  test('empty, unknown and oversized candidate selections fail before reading sources', () async {
    final bytes = sourcePng();
    final candidates = [
      candidate(bytes),
      candidate(bytes, id: 'candidate-b', partId: 'part-b'),
      candidate(bytes, id: 'candidate-c', partId: 'part-c'),
    ];
    final session = review(candidates);
    for (final ids in <Set<ConverterId>>[
      {},
      {ConverterId('unknown')},
      candidates.map((c) => c.candidateId).toSet(),
    ]) {
      final files = PreviewFiles(bytes);
      await expectLater(
        preview(session, files, ids: ids),
        throwsFormatException,
      );
      expect(files.reads, isEmpty);
    }
  });

  test('more than eight selected parts fails before reading sources', () async {
    final bytes = sourcePng();
    final session = review([candidate(bytes, partCount: 9)]);
    final files = PreviewFiles(bytes);
    await expectLater(preview(session, files), throwsFormatException);
    expect(files.reads, isEmpty);
  });

  test('two local candidates sharing part:0 produce distinct controlled region IDs', () async {
    final bytes = sourcePng();
    final first = candidate(bytes, partId: 'part:0');
    final second = candidate(bytes, id: 'candidate-b', partId: 'part:0');
    final session = review([first, second]);
    final files = PreviewFiles(bytes);
    final material = await preview(session, files);
    final expected = {
      visionRegionId(first.candidateId, first.parts.single.partId),
      visionRegionId(second.candidateId, second.parts.single.partId),
    };
    expect(material.crops, hasLength(2));
    expect(material.crops.map((crop) => crop.regionId).toSet(), expected);
    expect(expected, hasLength(2));
    expect(material.context.sourceRegionIds, expected);
    expect(files.reads, hasLength(1));
    expect(first.parts.single.partId, second.parts.single.partId);
  });

  test('region identity hashes both exact local candidate and part IDs', () {
    final candidateId = ConverterId('candidate-a');
    final partId = ConverterId('part:0');
    final expected = ConverterId(
      'vision-region:${canonicalHashOf({'candidateId': candidateId.value, 'partId': partId.value}).value}',
    );
    expect(visionRegionId(candidateId, partId), expected);
    expect(
      visionRegionId(candidateId, partId),
      visionRegionId(candidateId, partId),
    );
    expect(visionRegionId(ConverterId('candidate-b'), partId), isNot(expected));
    expect(visionRegionId(candidateId, ConverterId('part:1')), isNot(expected));
  });

  test(
    'default prompt version matches the implemented provider contract',
    () async {
      final bytes = sourcePng();
      final session = review([candidate(bytes)]);
      final material = await buildVisionPreview(
        session: session,
        candidateIds: session.activeCandidates
            .map((candidate) => candidate.candidateId)
            .toSet(),
        sourceFiles: PreviewFiles(bytes),
        requestId: ConverterId('provider-default-request'),
        model: 'documented-model',
      );
      expect(material.promptVersion, '1');
    },
  );

  test(
    'changed source hash is rejected before pixels enter the preview',
    () async {
      final bytes = sourcePng();
      final session = review([candidate(bytes)]);
      final changed = [...bytes]..[bytes.length - 1] ^= 1;
      await expectLater(
        preview(session, PreviewFiles(changed)),
        throwsFormatException,
      );
    },
  );

  test('source PNG dimensions must equal the attested SourceImage', () async {
    final bytes = sourcePng();
    final session = review([candidate(bytes, sourceWidth: 7)]);
    await expectLater(
      preview(session, PreviewFiles(bytes)),
      throwsFormatException,
    );
  });

  test(
    'corrupt PNG CRC is rejected even when source dimensions and hash match',
    () async {
      final bytes = sourcePng();
      final corrupt = [...bytes]..[bytes.length - 1] ^= 1;
      final session = review([candidate(corrupt)]);
      final files = PreviewFiles(corrupt);
      await expectLater(preview(session, files), throwsFormatException);
      expect(files.reads, hasLength(1));
    },
  );

  test(
    'preview crop strips source PNG text metadata and preserves exact RGBA',
    () async {
      final source = image.decodePng(Uint8List.fromList(sourcePng()))!;
      source.textData = {'Script/LocalPath': 'PRIVATE-MARKER'};
      final bytes = image.encodePng(source);
      expect(String.fromCharCodes(bytes), contains('PRIVATE-MARKER'));
      final current = candidate(bytes, turns: 1, reflected: true);
      final session = review([current]);
      final files = PreviewFiles(bytes);
      final material = await preview(session, files);
      final crop = material.crops.single;
      expect(
        String.fromCharCodes(crop.pngBytes),
        isNot(contains('PRIVATE-MARKER')),
      );
      expect(
        String.fromCharCodes(crop.pngBytes),
        isNot(contains('Script/LocalPath')),
      );
      final decoded = image.decodePng(Uint8List.fromList(crop.pngBytes))!;
      expect(decoded.textData ?? const <String, String>{}, isEmpty);
      final expected = [
        for (final row in labels(1, true))
          for (final label in row) ...[
            label,
            label + 40,
            label + 80,
            label % 3 == 0 ? 0 : 127,
          ],
      ];
      expect(decoded.getBytes(order: image.ChannelOrder.rgba), expected);
      expect(crop.sourceHash, current.sources.single.contentHash);
      expect(files.reads, [current.sources.single.fileId]);
    },
  );

  test(
    'indexed PNG with RGBA palette and tRNS preserves exact crop pixels',
    () async {
      final source = image.Image(
        width: 6,
        height: 5,
        numChannels: 4,
        withPalette: true,
      );
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          final label = y * 6 + x;
          source.palette!.setRgba(
            label,
            label,
            label + 40,
            label + 80,
            label % 3 == 0 ? 0 : 127,
          );
          source.getPixel(x, y).index = label;
        }
      }
      final bytes = image.encodePng(source);
      expect(bytes[25], 3);
      expect(String.fromCharCodes(bytes), contains('tRNS'));
      expect(const NativePngValidator().validate(bytes), (6, 5));
      final decodedSource = image.decodePng(Uint8List.fromList(bytes))!;
      expect(decodedSource.hasPalette, isTrue);
      expect(decodedSource.numChannels, 4);
      final current = candidate(bytes);
      final files = PreviewFiles(bytes);
      final material = await preview(review([current]), files);
      final crop = material.crops.single;
      final decoded = image.decodePng(Uint8List.fromList(crop.pngBytes))!;
      final expected = [
        for (final row in labels(0, false))
          for (final label in row) ...[
            label,
            label + 40,
            label + 80,
            label % 3 == 0 ? 0 : 127,
          ],
      ];
      expect(decoded.getBytes(order: image.ChannelOrder.rgba), expected);
      expect(decoded.width, 2);
      expect(decoded.height, 3);
      expect(decoded.hasPalette, isFalse);
      expect(crop.sourceHash, current.sources.single.contentHash);
      expect(files.reads, [current.sources.single.fileId]);
    },
  );

  test('sixteen-bit source PNG is rejected before preview decoding', () async {
    final source = image.Image(
      width: 6,
      height: 5,
      numChannels: 4,
      format: image.Format.uint16,
    );
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final label = y * 6 + x;
        source.setPixelRgba(
          x,
          y,
          label * 257,
          (label + 40) * 257,
          (label + 80) * 257,
          label % 3 == 0 ? 0 : 32767,
        );
      }
    }
    final bytes = image.encodePng(source);
    expect(bytes[24], 16);
    expect(const NativePngValidator().validate(bytes), (6, 5));
    final current = candidate(bytes);
    final files = PreviewFiles(bytes);
    await expectLater(preview(review([current]), files), throwsFormatException);
    expect(files.reads, [current.sources.single.fileId]);
  });

  test('cancellation before read prevents any source IO', () async {
    final bytes = sourcePng();
    final files = PreviewFiles(bytes);
    final cancellation = ScanCancellation()..cancel();
    await expectLater(
      preview(review([candidate(bytes)]), files, cancellation: cancellation),
      throwsFormatException,
    );
    expect(files.reads, isEmpty);
  });

  test(
    'cancellation during source read prevents a completed material',
    () async {
      final bytes = sourcePng();
      final cancellation = ScanCancellation();
      final gate = Completer<void>();
      final files = PreviewFiles(bytes, gate: gate.future);
      final pending = preview(
        review([candidate(bytes)]),
        files,
        cancellation: cancellation,
      );
      final assertion = expectLater(pending, throwsFormatException);
      await Future<void>.delayed(Duration.zero);
      cancellation.cancel();
      gate.complete();
      await assertion;
      expect(files.reads, hasLength(1));
    },
  );

  test(
    'crop pixel budget is enforced before source IO and crop allocation',
    () async {
      final bytes = sourcePng();
      final session = review([candidate(bytes)]);
      final files = PreviewFiles(bytes);
      await expectLater(
        preview(session, files, limits: const VisionLimits(maxPixels: 1)),
        throwsFormatException,
      );
      expect(files.reads, isEmpty);
    },
  );

  test('crop quota is enforced by the material rather than truncating the selection', () async {
    final bytes = sourcePng();
    final session = review([candidate(bytes)]);
    await expectLater(
      preview(
        session,
        PreviewFiles(bytes),
        limits: const VisionLimits(maxImageBytes: 16),
      ),
      throwsFormatException,
    );
  });
}
