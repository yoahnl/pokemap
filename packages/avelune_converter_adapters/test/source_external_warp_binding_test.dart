import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/source_external_original_fixture.dart';

final class _WitnessFiles implements SourceFilePort {
  _WitnessFiles(this.source, this.delegate, {this.changedPath});
  final NormalizedSourceProject source;
  final SourceFilePort delegate;
  final String? changedPath;
  final reads = <String>[];
  @override
  Future<List<int>> read(ConverterId id) async {
    final file =
        source.snapshot.entries.singleWhere((entry) => entry.fileId == id);
    reads.add(file.relativePath);
    final bytes = List<int>.of(await delegate.read(id));
    if (file.relativePath == changedPath) bytes[bytes.length - 1] ^= 1;
    return bytes;
  }
}

void main() {
  final root = Platform.environment['AVELUNE_EXTERNAL_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_EXTERNAL_SOURCE_SNAPSHOT'];
  group('closed original Kanto transfer artwork', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late ExternalOriginalFiles originalFiles;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!);
      source = fixture.source;
      originalFiles = fixture.files;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
    });
    Future<SourceExternalWarpBinding?> resolve(_WitnessFiles files,
            {SourceExternalWarpPolicy policy =
                SourceExternalWarpPolicy.nativeTransitionsWithoutEscapeState,
            NativeWriteLimits limits = const NativeWriteLimits()}) =>
        const SourceExternalWarpBindingResolver().read(
            source: source,
            analysis: analysis,
            files: files,
            policy: policy,
            limits: limits);

    test(
        'strict source policy requires the cave state adaptation before reading images',
        () async {
      final files = _WitnessFiles(source, originalFiles);
      await expectLater(
          resolve(files, policy: SourceExternalWarpPolicy.strictSource),
          throwsA(isA<SourceExternalWarpBindingUnavailable>().having(
              (error) => error.reason,
              'reason',
              'native_escape_state_decision_required')));
      expect(files.reads, isEmpty);
    });
    test(
        'explicit policy retains six transfers and imports two exact editable native images once',
        () async {
      final files = _WitnessFiles(source, originalFiles);
      final binding = (await resolve(files))!;
      expect(binding.programs, hasLength(6));
      expect(binding.artifacts, hasLength(2));
      expect(binding.illustrations, hasLength(2));
      expect(binding.mutations.map((mutation) => mutation.actionId), [
        'tileset.import_image',
        'tileset.import_image',
        'element_category.upsert',
        'element.upsert',
        'element.upsert'
      ]);
      expect(binding.artifacts.map((artifact) => artifact.rawSha256.value), [
        '59363afc47d23f051b18ae471e9d6670790316f0ad0140a3fa16c1e1d8646c13',
        '0348feae8e4da3cd8f9e7948c029c84198df1e59931a6f27cad9657f4148cdc8'
      ]);
      expect(files.reads, [
        'Graphics/Pictures/dpic_powerplant.png',
        'Graphics/Pictures/dpic_rocktunnel.png'
      ]);
      expect(
          binding.illustrations.values.every((element) =>
              element.frames.length == 1 &&
              element.frames.single.durationMs == null),
          isTrue);
      expect(binding.evidence['sourceEscapePoint'], 'notImported');
      expect(binding.evidence['fullSourceParityQualified'], isFalse);
      for (final event in analysis.events
          .where((event) => binding.programs.containsKey(event.identity))) {
        expect(
            binding.isBoundToEvent(
                source: source, analysis: analysis, event: event),
            isTrue);
      }
      final regenerated =
          SourceEventAnalyzer.forProject(source, profile: analysis.profile)
              .analyze();
      expect(
          binding.isBoundToEvent(
              source: source,
              analysis: regenerated,
              event: regenerated.eventAt(100, 6)!),
          isTrue);
      final evidence = binding.evidence;
      evidence['nativeExecutionQualified'] = true;
      expect(binding.evidence['nativeExecutionQualified'], isFalse);
    });
    test(
        'rejects forged analyzed graphics, guards and autorun bodies even with exact source IR',
        () async {
      final binding = (await resolve(_WitnessFiles(source, originalFiles)))!;
      final original = analysis.eventAt(100, 7)!;
      SourceEventDefinition replace(int index, SourceEventPageAnalysis page) =>
          SourceEventDefinition(
              sourceMapId: original.sourceMapId,
              sourceEventId: original.sourceEventId,
              sourceFileId: original.sourceFileId,
              identity: original.identity,
              name: original.name,
              x: original.x,
              y: original.y,
              locator: original.locator,
              pages: [
                for (final (i, old) in original.pages.indexed)
                  i == index ? page : old
              ]);
      final first = original.pages.first, second = original.pages[1];
      final forged = [
        replace(
            0,
            SourceEventPageAnalysis(
                sourcePage: first.sourcePage,
                locator: first.locator,
                condition: first.condition,
                graphic: null,
                body: first.body,
                rawDataRef: first.rawDataRef,
                diagnostics: [])),
        replace(
            0,
            SourceEventPageAnalysis(
                sourcePage: first.sourcePage,
                locator: first.locator,
                condition: first.condition,
                graphic: first.graphic,
                body: first.body,
                rawDataRef: null,
                diagnostics: [])),
        replace(
            1,
            SourceEventPageAnalysis(
                sourcePage: second.sourcePage,
                locator: second.locator,
                condition:
                    SourceEventCondition(kind: SourceEventConditionKind.always),
                graphic: second.graphic,
                body: second.body,
                rawDataRef: second.rawDataRef,
                diagnostics: [])),
        replace(
            1,
            SourceEventPageAnalysis(
                sourcePage: second.sourcePage,
                locator: second.locator,
                condition: second.condition,
                graphic: second.graphic,
                body: SourceEventBlock(span: second.body.span, nodes: []),
                rawDataRef: second.rawDataRef,
                diagnostics: [])),
      ];
      for (final event in forged) {
        expect(
            binding.isBoundToEvent(
                source: source, analysis: analysis, event: event),
            isFalse);
      }
    });
    test(
        'refuses missing source identities and duplicated programs before image I/O',
        () async {
      final original = analysis.eventAt(100, 6)!;
      SourceEventDefinition forged(int mapId, int eventId) =>
          SourceEventDefinition(
              sourceMapId: mapId,
              sourceEventId: eventId,
              sourceFileId: original.sourceFileId,
              identity: original.identity,
              name: original.name,
              x: original.x,
              y: original.y,
              locator: original.locator,
              pages: original.pages);
      for (final events in [
        [forged(999, 6)],
        [forged(100, 999)],
        [original, original]
      ]) {
        final files = _WitnessFiles(source, originalFiles);
        await expectLater(
            const SourceExternalWarpBindingResolver().read(
                source: source,
                analysis: SourceEventAnalysis(
                    profile: analysis.profile, events: events, diagnostics: []),
                files: files,
                policy: SourceExternalWarpPolicy
                    .nativeTransitionsWithoutEscapeState),
            throwsA(isA<SourceExternalWarpBindingUnavailable>().having(
                (error) => error.reason, 'reason', 'program_binding_invalid')));
        expect(files.reads, isEmpty);
      }
    });
    for (final limits in [
      const NativeWriteLimits(maxArtifacts: 1),
      const NativeWriteLimits(maxMutations: 4),
      const NativeWriteLimits(maxTotalImagePixels: 393215),
      const NativeWriteLimits(maxImagePixels: 196607),
      const NativeWriteLimits(maxArtifactBytes: 9000),
      const NativeWriteLimits(maxTotalArtifactBytes: 20048),
    ].indexed) {
      test('refuses quota ${limits.$1} before image import', () async {
        final files = _WitnessFiles(source, originalFiles);
        await expectLater(
            resolve(files, limits: limits.$2),
            throwsA(isA<NativeWriteException>().having(
                (error) => error.code, 'code', 'events.external_warp.quota')));
        expect(files.reads, isEmpty);
      });
    }
    test('split image budget admits both illustrations at the exact individual limit', () async {
      final files = _WitnessFiles(source, originalFiles);
      final result = await resolve(files, limits: const NativeWriteLimits(
        maxImagePixels: 196608, maxTotalImagePixels: 393216));
      expect(result!.artifacts, hasLength(2));
    });
    for (final name in ['dpic_powerplant', 'dpic_rocktunnel']) {
      test('rejects stale bytes for $name without changing the source',
          () async {
        await expectLater(
            resolve(_WitnessFiles(source, originalFiles,
                changedPath: 'Graphics/Pictures/$name.png')),
            throwsA(isA<NativeWriteException>().having((error) => error.code,
                'code', 'events.external_warp.image_changed')));
      });
    }
  },
      skip: root == null || snapshot == null
          ? 'Original complete source required.'
          : false);
}
