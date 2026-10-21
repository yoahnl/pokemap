import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_event_item_bindings.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_adapters/src/source_oak_parcel_binding.dart';
import 'package:avelune_converter_adapters/src/source_pickup_feedback_binding.dart';
import 'package:avelune_converter_adapters/src/source_map_music_binding.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final enabled = root != null &&
      snapshot != null &&
      Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'] != null;
  group('complete Oak parcel source bindings', () {
    late NormalizedSourceProject source;
    late SourceFilePort files;
    late SourceEventAnalysis analysis;
    late SourceEventDefinition event;
    late Map<String, SourceEventItemBinding> items;
    const resolver = SourceOakParcelBindingResolver();
    Future<SourceOakParcelBinding?> bind(
            {SourceEventAnalysis? withAnalysis,
            SourceEventDefinition? withEvent,
            SourceFilePort? withFiles,
            Map<String, SourceEventItemBinding>? withItems}) =>
        resolver.read(
            source: source,
            analysis: withAnalysis ?? analysis,
            event: withEvent ?? event,
            files: withFiles ?? files,
            items: withItems ?? items);
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
      event = analysis.eventAt(9, 1)!;
      items = (await const SourceEventItemBindingResolver().read(
              snapshot: source.snapshot,
              files: files,
              symbols: ['OAKPARCEL', 'POKEBALL'],
              eventProfile: analysis.profile))
          .bindings;
    });
    test('attests the actual region, all companions, items and original media',
        () async {
      final binding = await bind();
      expect(binding, isNotNull);
      expect(binding!.isBoundTo(source, analysis, event), isTrue);
      expect(binding.tileActors, hasLength(2));
      expect(binding.companionHashes.keys, unorderedEquals([12, 15, 25]));
      expect(binding.items.keys, unorderedEquals(['OAKPARCEL', 'POKEBALL']));
      expect(binding.dexSpecies, isNotEmpty);
      expect(binding.dexSpecies.toSet(), hasLength(binding.dexSpecies.length));
      expect(binding.hasPokedexSourceFactId, endsWith(':player:has_pokedex'));
      expect(binding.unlockedDexSourceFactId,
          endsWith(':player:pokedex:unlocked:1'));
      expect(
          binding.audio.values
              .where((a) => a.kind == SourceEventAudioKind.music),
          hasLength(1));
      expect(
          binding.audio.values
              .where((a) => a.kind == SourceEventAudioKind.musicEffect),
          hasLength(2));
      expect(
          binding.audio.entries.every((a) =>
              a.value.sourceSnapshotHash == source.snapshot.canonicalHash),
          isTrue);
      final proof = binding.toJson();
      expect((proof['regionalDex'] as Map)['regionalCatalogPresentationParity'],
          isFalse);
      expect(proof['allSourcePageMasksRequired'], isTrue);
      expect(proof['unsupportedPageIndices'], [4, 5]);
      expect(proof['staticSemanticsQualified'], isFalse);
    });
    test(
        'attests inherited through without concurrent map or common-event writers',
        () async {
      final binding = await bind();
      expect(binding, isNotNull);
      final proof = binding!.inheritedThroughEvidence;
      expect(proof['sourcePageThrough'], isTrue);
      expect(proof['parallelMapPages'], 0);
      expect(proof['backgroundCommonEvents'], 0);
      expect(proof['sourceThroughToggleCommands'], 0);
      expect(proof['nativeRoutePrefix'], 'through(true)');
      expect(proof['sourceActorRouteCensus'], hasLength(19));
    });
    for (final pageIndex in [0, 1]) {
      test(
          'refuses a freshly normalized false inherited through page $pageIndex',
          () async {
        final entry = source.archive.files.values.singleWhere(
            (file) => file.entry.relativePath == 'Data/Map009.rxdata');
        final document = entry.document;
        final events = document
            .node(_field(document, document.node(document.rootId), '@events'));
        final actor = document.node(events.pairs
            .singleWhere(
                (pair) => document.node(pair.key).integerValue!.toInt() == 25)
            .value);
        final pages = document.node(_field(document, actor, '@pages'));
        final page = document.node(pages.elements[pageIndex]);
        final through = document.node(_field(document, page, '@through'));
        expect(through.booleanValue, isTrue);
        final bytes = List<int>.from(entry.rawBytes)
          ..[through.location.byteOffset] = 70;
        await _expectSourceRefusal(source, files, entry.entry, bytes);
      });
    }
    for (final code in [37, 38]) {
      test('refuses a freshly normalized external through opcode $code',
          () async {
        final entry = source.archive.files.values.singleWhere(
            (file) => file.entry.relativePath == 'Data/Map009.rxdata');
        final document = entry.document;
        final events = document
            .node(_field(document, document.node(document.rootId), '@events'));
        final actor = document.node(events.pairs
            .singleWhere(
                (pair) => document.node(pair.key).integerValue!.toInt() == 29)
            .value);
        final pages = document.node(_field(document, actor, '@pages'));
        final page = document.node(pages.elements.first);
        final commands = document.node(_field(document, page, '@list'));
        final command = document.node(commands.elements[44]);
        final parameters =
            document.node(_field(document, command, '@parameters'));
        expect(
            document.node(parameters.elements.first).integerValue!.toInt(), 25);
        final route = document.node(parameters.elements[1]);
        final steps = document.node(_field(document, route, '@list'));
        final step = document.node(steps.elements.first);
        final original = document.node(_field(document, step, '@code'));
        expect(original.integerValue!.toInt(), 4);
        final bytes = List<int>.from(entry.rawBytes)
          ..[original.location.byteOffset + 1] = code + 5;
        await _expectSourceRefusal(source, files, entry.entry, bytes);
      });
    }
    test('refuses a freshly normalized background common-event interpreter',
        () async {
      final entry = source.archive.files.values.singleWhere(
          (file) => file.entry.relativePath == 'Data/CommonEvents.rxdata');
      final document = entry.document;
      final event = document.node(document.node(document.rootId).elements[1]);
      final trigger = document.node(_field(document, event, '@trigger'));
      expect(trigger.integerValue!.toInt(), 0);
      final bytes = List<int>.from(entry.rawBytes)
        ..[trigger.location.byteOffset + 1] = 7;
      await _expectSourceRefusal(source, files, entry.entry, bytes);
    });
    test('refuses either missing business item before publication', () async {
      for (final missing in items.keys) {
        expect(await bind(withItems: {...items}..remove(missing)), isNull);
      }
    });
    test('preserves the plural source feedback for the five Poké Balls',
        () async {
      final music = await const SourceMapMusicResolver()
          .read(source: source, sourceMapId: 9, files: files);
      final feedback = await const SourcePickupFeedbackResolver().read(
          source: source,
          files: files,
          item: items['POKEBALL']!,
          sourceMapId: 9,
          helper: SourceItemGrantHelper.receiveItem,
          quantity: 5,
          music: music);
      expect(feedback.quantity, 5);
      expect(feedback.evidence['sourceQuantity'], 5);
      expect(feedback.foundFeedback(cueId: 'five-balls').plainText,
          'You obtained 5 ${items['POKEBALL']!.portionNamePlural}!');
      expect(feedback.bagFeedback.plainText,
          contains('You put the ${items['POKEBALL']!.portionNamePlural} in'));
      expect(feedback.evidence['sourceGrantOrder'],
          ['obtainedFeedback', 'bagAdd', 'bagFeedbackOnSuccess']);
      for (final quantity in [0, 1000]) {
        await expectLater(
            const SourcePickupFeedbackResolver().read(
                source: source,
                files: files,
                item: items['POKEBALL']!,
                sourceMapId: 9,
                helper: SourceItemGrantHelper.receiveItem,
                quantity: quantity,
                music: music),
            throwsA(isA<SourcePickupBindingUnavailable>().having(
                (e) => e.reason,
                'reason',
                'pickup.feedback.quantity_unsupported')));
      }
      await expectLater(
          const SourcePickupFeedbackResolver().read(
              source: source,
              files: files,
              item: items['POKEBALL']!,
              sourceMapId: 9,
              quantity: 5,
              music: music),
          throwsA(isA<SourcePickupBindingUnavailable>().having((e) => e.reason,
              'reason', 'pickup.feedback.quantity_unsupported')));
    });
    test(
        'refuses each missing companion and never publishes a partial cutscene',
        () async {
      final binding = await bind();
      expect(binding, isNotNull);
      for (final id in [12, 15, 25]) {
        final altered = SourceEventAnalysis(
            profile: analysis.profile,
            diagnostics: analysis.diagnostics,
            events:
                analysis.events.where((e) => e.sourceEventId != id).toList());
        expect(await bind(withAnalysis: altered), isNull);
        expect(binding!.isBoundTo(source, altered, event), isFalse);
      }
    });
    test('refuses a changed higher page condition rather than falling back',
        () async {
      final page = event.pages[4];
      final changed = SourceEventPageAnalysis(
          sourcePage: page.sourcePage,
          condition:
              SourceEventCondition(kind: SourceEventConditionKind.always),
          body: page.body,
          locator: page.locator,
          rawDataRef: page.rawDataRef,
          graphic: page.graphic,
          diagnostics: page.diagnostics);
      final altered = _replaceEvent(event, pages: [
        ...event.pages.take(4),
        changed,
        event.pages.last,
      ]);
      expect(await bind(withEvent: altered), isNull);
    });
    test('refuses the original raw page body without its closed core wrapper',
        () async {
      final wrapped = event.pages[2];
      final node = wrapped.body.nodes.single as SourceOakParcelProgramNode;
      final page = SourceEventPageAnalysis(
          sourcePage: wrapped.sourcePage,
          condition: wrapped.condition,
          body: node.body,
          locator: wrapped.locator,
          rawDataRef: wrapped.rawDataRef,
          graphic: wrapped.graphic,
          diagnostics: wrapped.diagnostics);
      expect(
          await bind(
              withEvent: _replaceEvent(event, pages: [
            ...event.pages.take(2),
            page,
            ...event.pages.skip(3),
          ])),
          isNull);
    });
    test(
        'refuses changed live common-event bytes with an intact declared census hash',
        () async {
      final binding = await bind();
      expect(binding, isNotNull);
      final file = binding!.throughCommonEventsFile;
      final bytes = List<int>.from(await files.read(file.fileId));
      bytes[bytes.length - 1] ^= 1;
      await expectLater(
          bind(withFiles: _ChangedBytes(files, file.fileId, bytes)),
          throwsA(isA<NativeWriteException>().having((error) => error.code,
              'code', 'events.oak_parcel.concurrency_changed')));
    });
    test('refuses changed regional dex bytes with intact declared hash',
        () async {
      final binding = await bind();
      expect(binding, isNotNull);
      final bytes = List<int>.from(await files.read(binding!.dexFile.fileId));
      bytes[bytes.length - 1] ^= 1;
      await expectLater(
          bind(withFiles: _ChangedBytes(files, binding.dexFile.fileId, bytes)),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'events.oak_parcel.dex_changed')));
    });
  },
      skip: enabled
          ? false
          : 'Requires the attested external source and interpretation profile.');
}

SourceEventDefinition _replaceEvent(SourceEventDefinition event,
        {required List<SourceEventPageAnalysis> pages}) =>
    SourceEventDefinition(
      identity: event.identity,
      sourceMapId: event.sourceMapId,
      sourceEventId: event.sourceEventId,
      name: event.name,
      x: event.x,
      y: event.y,
      pages: pages,
      locator: event.locator,
      sourceFileId: event.sourceFileId,
    );

final class _ChangedBytes implements SourceFilePort {
  const _ChangedBytes(this.base, this.id, this.bytes);
  final SourceFilePort base;
  final ConverterId id;
  final List<int> bytes;
  @override
  Future<List<int>> read(ConverterId fileId) =>
      fileId == id ? Future.value(bytes) : base.read(fileId);
}

int _field(MarshalDocument document, MarshalNode object, String name) =>
    object.instanceVariables
        .singleWhere((pair) => document.node(pair.key).name == name)
        .value;

Future<void> _expectSourceRefusal(NormalizedSourceProject original,
    SourceFilePort files, SourceFileEntry changed, List<int> bytes) async {
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: original.snapshot.logicalProjectNamespace,
      policyHash: original.snapshot.policyHash,
      entries: [
        for (final entry in original.snapshot.entries)
          if (entry.fileId != changed.fileId)
            entry
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
      diagnostics: original.snapshot.diagnostics,
      excludedPaths: original.snapshot.excludedPaths,
      profileEvidence: original.snapshot.profileEvidence,
      state: SourceScanState.complete);
  final changedFiles = _ChangedBytes(files, changed.fileId, bytes);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: changedFiles,
      interpretationProfile: original.interpretationProfile,
      selectedMapIds: {9},
      includeEventSystem: true,
      includeConnections: true);
  final analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  final owner = analysis.eventAt(9, 1)!;
  expect(
      owner.pages.take(4).every(
          (page) => page.body.nodes.single is SourceOakParcelProgramNode),
      isTrue);
  final items = (await const SourceEventItemBindingResolver().read(
          snapshot: snapshot,
          files: changedFiles,
          symbols: ['OAKPARCEL', 'POKEBALL'],
          eventProfile: analysis.profile))
      .bindings;
  expect(items, hasLength(2));
  expect(
      await const SourceOakParcelBindingResolver().read(
          source: source,
          analysis: analysis,
          event: owner,
          files: changedFiles,
          items: items),
      isNull);
}
