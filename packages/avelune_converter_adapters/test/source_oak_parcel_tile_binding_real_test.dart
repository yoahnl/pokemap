import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_oak_parcel_tile_binding.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final enabled = root != null &&
      snapshot != null &&
      Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'] != null;
  group('attested parcel tile actors', () {
    late NormalizedSourceProject source;
    late SourceFilePort files;
    late SourceEventAnalysis analysis;
    late SourceOakParcelProgram program;
    late Map<ConverterId, SourceOakParcelTileBinding> props;
    const resolver = SourceOakParcelTileBindingResolver();
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {9},
          supplementalRoots:
              (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                      '')
                  .split('|')
                  .where((s) => s.isNotEmpty)
                  .toList());
      source = fixture.source;
      files = fixture.files;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source))
          .analyze();
      program = _program(source);
      props = await resolver.read(
          source: source, analysis: analysis, program: program, files: files);
    });
    test(
        'imports only the two declared props and preserves exact source pixels',
        () {
      expect(props, hasLength(2));
      expect(props.values.map((b) => b.event.sourceEventId),
          unorderedEquals([12, 15]));
      for (final binding in props.values) {
        expect(binding.isBoundTo(source, analysis), isTrue);
        expect(binding.sourceTileId, 1718);
        expect(binding.character.frameWidth, 2);
        expect(binding.character.frameHeight, 2);
        expect(binding.character.animations, hasLength(4));
        expect(binding.mutations, hasLength(7));
        expect(binding.mutations.first.actionId, 'tileset.import_image');
        expect(binding.toJson()['sourcePixelsResampled'], isFalse);
        expect(binding.toJson()['sourceRenderedPixelsPreserved'], isTrue);
        _expectPixels(binding);
      }
      expect(props.values.map((b) => b.character.id).toSet(), hasLength(1));
      expect(props.values.map((b) => b.artifact.handle).toSet(), hasLength(1));
    });
    test('regenerates deterministic artifacts and canonical mutations',
        () async {
      final repeated = await resolver.read(
          source: source, analysis: analysis, program: program, files: files);
      for (final id in props.keys) {
        expect(repeated[id]!.artifact.bytes, props[id]!.artifact.bytes);
        expect(repeated[id]!.toJson(), props[id]!.toJson());
        expect(
            repeated[id]!
                .mutations
                .indexed
                .map((m) => m.$2.toJson(m.$1))
                .toList(),
            props[id]!
                .mutations
                .indexed
                .map((m) => m.$2.toJson(m.$1))
                .toList());
      }
    });
    test('refuses a missing companion without publishing half the cutscene',
        () async {
      final missing = SourceEventAnalysis(
          profile: analysis.profile,
          diagnostics: analysis.diagnostics,
          events: analysis.events.where((e) => e.sourceEventId != 15).toList());
      await expectLater(
          resolver.read(
              source: source,
              analysis: missing,
              program: program,
              files: files),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'events.oak_tile.companion')));
      expect(props.values.first.isBoundTo(source, missing),
          props.values.first.event.sourceEventId != 15);
    });
    test('refuses a falsified source position and rejects a stale binding',
        () async {
      final target = props.values.first.event;
      final altered = _replaceEvent(analysis, target, x: target.x + 1);
      await expectLater(
          resolver.read(
              source: source,
              analysis: altered,
              program: program,
              files: files),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'events.oak_tile.companion')));
      expect(props[target.identity]!.isBoundTo(source, altered), isFalse);
    });
    test('refuses an additional source effect in the supposedly blank page',
        () async {
      final target = props.values.first.event,
          page = props.values.first.event.pages.last;
      final altered = _replaceEvent(analysis, target,
          lastBody: SourceEventBlock(span: page.body.span, nodes: [
            ...page.body.nodes,
            SourceScriptNode(page.body.span, 'arbitrary_call()')
          ]));
      await expectLater(
          resolver.read(
              source: source,
              analysis: altered,
              program: program,
              files: files),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'events.oak_tile.companion')));
      expect(props[target.identity]!.isBoundTo(source, altered), isFalse);
    });
    test('refuses changed atlas bytes before decoding or importing', () async {
      final binding = props.values.first;
      final bytes = List<int>.from(binding.sourceBytes);
      bytes[bytes.length - 1] ^= 1;
      await expectLater(
          resolver.read(
              source: source,
              analysis: analysis,
              program: program,
              files: _ChangedBytes(files, binding.sourceImage.fileId, bytes)),
          throwsA(isA<NativeWriteException>().having(
              (e) => e.code, 'code', 'events.oak_tile.source_changed')));
    });
    test('refuses an insufficient canonical mutation budget', () async {
      await expectLater(
          resolver.read(
              source: source,
              analysis: analysis,
              program: program,
              files: files,
              limits: const NativeWriteLimits(maxMutations: 6)),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'events.oak_tile.quota')));
    });
    test('preserves palette transparency and semitransparent source pixels',
        () async {
      final original = props.values.first;
      final height =
          image.decodePng(Uint8List.fromList(original.sourceBytes))!.height;
      final indexed = image.Image(
          width: 256, height: height, withPalette: true, numChannels: 4);
      indexed.palette!.setRgba(0, 17, 29, 43, 0);
      indexed.palette!.setRgba(1, 200, 31, 18, 255);
      indexed.palette!.setRgba(2, 51, 117, 211, 83);
      indexed.setPixelIndex(original.cropX, original.cropY, 1);
      indexed.setPixelIndex(original.cropX + 1, original.cropY + 1, 2);
      final bytes = image.encodePng(indexed);
      final old = source.snapshot, entry = original.sourceImage;
      final nextSnapshot = SourceSnapshot(
          logicalProjectNamespace: old.logicalProjectNamespace,
          policyHash: old.policyHash,
          entries: [
            for (final current in old.entries)
              if (current.fileId != entry.fileId)
                current
              else
                SourceFileEntry(
                    fileId: entry.fileId,
                    relativePath: entry.relativePath,
                    kind: entry.kind,
                    byteLength: bytes.length,
                    sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
                    format: entry.format,
                    family: entry.family)
          ],
          diagnostics: old.diagnostics,
          excludedPaths: old.excludedPaths,
          profileEvidence: old.profileEvidence,
          state: old.state);
      final changedFiles = _ChangedBytes(files, entry.fileId, bytes);
      final next = await const RmxpSourceNormalizer().normalize(
          snapshot: nextSnapshot,
          files: changedFiles,
          selectedMapIds: {9},
          includeEventSystem: true,
          interpretationProfile: source.interpretationProfile);
      final nextAnalysis = SourceEventAnalyzer.forProject(next,
              profile: SourceEventProfile.forProject(next))
          .analyze();
      final nextProps = await resolver.read(
          source: next,
          analysis: nextAnalysis,
          program: _program(next),
          files: changedFiles);
      for (final binding in nextProps.values) {
        _expectPixels(binding);
        final native =
            image.decodePng(Uint8List.fromList(binding.artifact.bytes))!;
        expect(native.getPixel(16, 32).a, 255);
        expect(native.getPixel(17, 33).a, 83);
        expect(native.getPixel(18, 34).a, 0);
      }
      expect(original.isBoundTo(next, nextAnalysis), isFalse);
    });
  }, skip: enabled ? false : 'Requires immutable source and attested profile.');
}

SourceOakParcelProgram _program(NormalizedSourceProject source) =>
    SourceOakParcelProgram.read(
        source: source,
        profile: SourceEventProfile.forProject(source),
        sourceMapId: 9,
        event: source.maps.single.map.events
            .singleWhere((e) => e.sourceEventId == 1))!;
void _expectPixels(SourceOakParcelTileBinding binding) {
  final source = image.decodePng(Uint8List.fromList(binding.sourceBytes))!;
  final native = image.decodePng(Uint8List.fromList(binding.artifact.bytes))!;
  expect((native.width, native.height), (64, 256));
  for (final clip in binding.character.animations) {
    final frame = clip.frames.single.source;
    for (var y = 0; y < 64; y++) {
      for (var x = 0; x < 64; x++) {
        final actual = native.getPixel(frame.x + x, frame.y + y);
        if (x < 16 || x >= 48 || y < 32) {
          expect(actual.a, 0);
        } else {
          final expected =
              source.getPixel(binding.cropX + x - 16, binding.cropY + y - 32);
          final alpha =
              source.palette?.getAlpha(expected.index.toInt()) ?? expected.a;
          expect([
            actual.r,
            actual.g,
            actual.b,
            actual.a
          ], [
            expected.r,
            expected.g,
            expected.b,
            alpha
          ], reason: 'source pixel ($x,$y) ${clip.direction.name}');
        }
      }
    }
  }
}

SourceEventAnalysis _replaceEvent(
        SourceEventAnalysis analysis, SourceEventDefinition target,
        {int? x, SourceEventBlock? lastBody}) =>
    SourceEventAnalysis(
        profile: analysis.profile,
        diagnostics: analysis.diagnostics,
        events: [
          for (final event in analysis.events)
            if (event.identity != target.identity)
              event
            else
              SourceEventDefinition(
                  sourceMapId: event.sourceMapId,
                  sourceEventId: event.sourceEventId,
                  sourceFileId: event.sourceFileId,
                  identity: event.identity,
                  name: event.name,
                  x: x ?? event.x,
                  y: event.y,
                  locator: event.locator,
                  pages: [
                    event.pages.first,
                    if (lastBody == null)
                      event.pages.last
                    else
                      SourceEventPageAnalysis(
                          sourcePage: event.pages.last.sourcePage,
                          locator: event.pages.last.locator,
                          condition: event.pages.last.condition,
                          graphic: event.pages.last.graphic,
                          body: lastBody,
                          rawDataRef: event.pages.last.rawDataRef,
                          diagnostics: event.pages.last.diagnostics),
                  ]),
        ]);

final class _ChangedBytes implements SourceFilePort {
  const _ChangedBytes(this.delegate, this.id, this.bytes);
  final SourceFilePort delegate;
  final ConverterId id;
  final List<int> bytes;
  @override
  Future<List<int>> read(ConverterId fileId) => fileId == id
      ? Future.value(List<int>.from(bytes))
      : delegate.read(fileId);
}
