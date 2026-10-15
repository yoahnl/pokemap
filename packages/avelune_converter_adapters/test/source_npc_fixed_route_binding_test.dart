import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_npc_fixed_route_binding.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'package:crypto/crypto.dart' as crypto;

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final sourceRoot = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('original source autonomous fixed routes', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late SourceNpcFixedRouteBindingResolver resolver;
    setUpAll(() async {
      source = await _readSource(archive!, sourceRoot!);
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      resolver = SourceNpcFixedRouteBindingResolver.forProject(source);
    });

    for (final row in <(int, int, List<int>, EntityFacing, int)>[
      (
        102,
        11,
        [3, 2, 2, 3, 2, 3, 2, 3, 3, 2, 3, 2, 3, 2],
        EntityFacing.west,
        2550
      ),
      (
        102,
        15,
        [2, 3, 2, 3, 2, 3, 2, 3, 3, 2, 3, 2, 3, 2],
        EntityFacing.west,
        1600
      ),
      (98, 6, [17, 19], EntityFacing.north, 1600),
      (
        98,
        8,
        [2, 3, 2, 2, 3, 3, 3, 2, 3, 3, 3, 2, 2, 3, 2, 2],
        EntityFacing.west,
        1600
      ),
      (98, 11, [24], EntityFacing.south, 1600),
    ]) {
      test('binds exact raw route ${row.$1}:${row.$2} on every source page',
          () {
        final event = analysis.eventAt(row.$1, row.$2)!;
        for (final page in event.pages) {
          final binding = resolver.resolve(
              sourceMapId: row.$1,
              sourceEventId: row.$2,
              sourcePageIndex: page.originalPageIndex);
          expect(binding.initialFacing, row.$4);
          expect(
              binding.nativeMovement.mode, MapEntityNpcMovementMode.fixedRoute);
          expect(binding.nativeMovement.pauseDurationMs, row.$5);
          expect(binding.nativeMovement.stepDurationMs, 250);
          expect(binding.nativeMovement.loop, isTrue);
          expect(binding.nativeMovement.waypoints, isEmpty);
          expect(binding.nativeMovement.routeSteps.map((step) => step.toJson()),
              row.$3.map(_expectedStep));
          expect(
              binding.isBoundToPage(
                  source: source,
                  profile: analysis.profile,
                  event: event,
                  page: page),
              isTrue);
          expect(binding.rawDataRef.id, page.rawDataRef!.id);
          expect(binding.toJson()['sourceParity'], isFalse);
          expect(binding.toJson()['sourceProgramQualified'], isFalse);
          expect(binding.toJson()['sourceScriptsExecuted'], 0);
          expect(() => binding.nativeMovement.routeSteps.clear(),
              throwsUnsupportedError);
        }
      });
    }

    test(
        'binding rejects forged event position, missing raw page and foreign profile',
        () {
      final event = analysis.eventAt(102, 11)!;
      final page = event.pages.single;
      final binding = resolver.resolve(
          sourceMapId: 102, sourceEventId: 11, sourcePageIndex: 0);
      final shifted = SourceEventDefinition(
          sourceMapId: event.sourceMapId,
          sourceEventId: event.sourceEventId,
          sourceFileId: event.sourceFileId,
          identity: event.identity,
          name: event.name,
          x: event.x + 1,
          y: event.y,
          locator: event.locator,
          pages: event.pages);
      final noRaw = SourceEventPageAnalysis(
          sourcePage: page.sourcePage,
          locator: page.locator,
          condition: page.condition,
          graphic: page.graphic,
          body: page.body,
          rawDataRef: null,
          diagnostics: page.diagnostics);
      expect(
          binding.isBoundToPage(
              source: source,
              profile: analysis.profile,
              event: shifted,
              page: page),
          isFalse);
      expect(
          binding.isBoundToPage(
              source: source,
              profile: analysis.profile,
              event: event,
              page: noRaw),
          isFalse);
      expect(
          binding.isBoundToPage(
              source: source,
              profile: SourceEventProfile.kantoForProject(source,
                  scriptsArchiveHash: Sha256Hash('0' * 64)),
              event: event,
              page: page),
          isFalse);
      expect(
          binding.isBoundToPage(
              source: source,
              profile: analysis.profile,
              event: analysis.eventAt(102, 15)!,
              page: analysis.eventAt(102, 15)!.pages.single),
          isFalse);
    });

    test('binding refuses a stripped or forged source dialogue body', () {
      final event = analysis.eventAt(102, 11)!;
      final page = event.pages.single;
      final binding = resolver.resolve(
          sourceMapId: 102, sourceEventId: 11, sourcePageIndex: 0);
      final stripped = SourceEventPageAnalysis(
          sourcePage: page.sourcePage,
          locator: page.locator,
          condition: page.condition,
          graphic: page.graphic,
          body: SourceEventBlock(nodes: [], span: page.body.span),
          rawDataRef: page.rawDataRef,
          diagnostics: page.diagnostics);
      expect(
          binding.isBoundToPage(
              source: source,
              profile: analysis.profile,
              event: event,
              page: stripped),
          isFalse);
      final text = page.body.nodes.whereType<SourceTextNode>().first;
      final forgedText = SourceEventPageAnalysis(
          sourcePage: page.sourcePage,
          locator: page.locator,
          condition: page.condition,
          graphic: page.graphic,
          body: SourceEventBlock(nodes: [
            SourceTextNode(text.span, 'Forged dialogue'),
            ...page.body.nodes.where((node) => node is! SourceTextNode)
          ], span: page.body.span),
          rawDataRef: page.rawDataRef,
          diagnostics: page.diagnostics);
      expect(
          binding.isBoundToPage(
              source: source,
              profile: analysis.profile,
              event: event,
              page: forgedText),
          isFalse);
    });

    test('reattested raw skippable and script routes remain unavailable',
        () async {
      final page = analysis.eventAt(102, 11)!.pages.single;
      final original = source.archive.files[page.rawDataRef!.fileId]!;
      final doc = original.document;
      final route = doc.node(page.graphic!.moveRouteNodeId);
      final skippable = _field(doc, route, '@skippable');
      final routeList = _field(doc, route, '@list');
      final firstCode =
          _field(doc, doc.node(routeList.elements.first), '@code');
      final oldBinding = resolver.resolve(
          sourceMapId: 102, sourceEventId: 11, sourcePageIndex: 0);
      for (final patch in [
        (skippable.location.byteOffset, 70, 84, 'skippable_unsupported'),
        (firstCode.location.byteOffset + 1, 8, 50, 'route_command_unsupported'),
      ]) {
        final bytes = original.rawBytes.toList();
        expect(bytes[patch.$1], patch.$2);
        bytes[patch.$1] = patch.$3;
        final changed = await _readSource(archive!, sourceRoot!, overrides: {
          original.entry.relativePath: bytes,
        });
        final changedAnalysis = SourceEventAnalyzer.forProject(changed,
                profile: SourceEventProfile.kantoForProject(changed))
            .analyze();
        expect(
            oldBinding.isBoundToPage(
                source: changed,
                profile: changedAnalysis.profile,
                event: changedAnalysis.eventAt(102, 11)!,
                page: changedAnalysis.eventAt(102, 11)!.pages.single),
            isFalse);
        expect(
            () => SourceNpcFixedRouteBindingResolver.forProject(changed)
                .resolve(
                    sourceMapId: 102, sourceEventId: 11, sourcePageIndex: 0),
            throwsA(isA<SourceNpcFixedRouteBindingUnavailable>()
                .having((error) => error.reason, 'reason', patch.$4)));
      }
    });

    test('unknown maps, pages and stationary routes remain unavailable', () {
      for (final row in [
        (999, 1, 0),
        (102, 999, 0),
        (102, 11, 1),
        (98, 1, 0)
      ]) {
        expect(
            () => resolver.resolve(
                sourceMapId: row.$1,
                sourceEventId: row.$2,
                sourcePageIndex: row.$3),
            throwsA(isA<SourceNpcFixedRouteBindingUnavailable>()));
      }
    });
  },
      skip: archive == null || sourceRoot == null
          ? 'Requires the pinned original source inventory and read-only source tree.'
          : false);
}

Map<String, Object?> _expectedStep(int code) => switch (code) {
      2 => {'kind': 'move', 'direction': 'west'},
      3 => {'kind': 'move', 'direction': 'east'},
      17 => {'kind': 'face', 'direction': 'west'},
      19 => {'kind': 'face', 'direction': 'north'},
      24 => {'kind': 'randomFacing'},
      _ => throw StateError('Unexpected source oracle code.'),
    };

Future<NormalizedSourceProject> _readSource(String archive, String sourceRoot,
    {Map<String, List<int>> overrides = const {}}) async {
  final data = jsonDecode(await File('$archive/snapshot.json').readAsString())
      as Map<String, dynamic>;
  final snapshot = SourceSnapshot(
      logicalProjectNamespace:
          ConverterId(data['logicalProjectNamespace'] as String),
      policyHash: Sha256Hash(data['policyHash'] as String),
      entries: [
        for (final dynamic row in data['entries'])
          SourceFileEntry(
              fileId: ConverterId(row['fileId'] as String),
              relativePath: row['relativePath'] as String,
              kind: SourceNodeKind.values.byName(row['kind'] as String),
              byteLength: overrides[row['relativePath']]?.length ??
                  row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(overrides.containsKey(row['relativePath'])
                      ? crypto.sha256
                          .convert(overrides[row['relativePath']]!)
                          .toString()
                      : row['sha256'] as String),
              format: row['format'] as String,
              family: row['family'] as String)
      ],
      diagnostics: const [],
      excludedPaths: (data['excludedPaths'] as List).cast<String>(),
      profileEvidence: [
        for (final dynamic row in data['profileEvidence'])
          SourceProfileEvidence(
              relativePath: row['relativePath'] as String,
              fileHash: Sha256Hash(row['fileHash'] as String),
              version: row['version'] as String,
              line: row['line'] as int,
              excerpt: row['excerpt'] as String)
      ],
      state: SourceScanState.values.byName(data['state'] as String));
  if (overrides.isEmpty) {
    expect(snapshot.canonicalHash.value, data['canonicalHash']);
  } else {
    expect(snapshot.canonicalHash.value, isNot(data['canonicalHash']));
  }
  return const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: _Files(snapshot, sourceRoot, overrides),
      selectedMapIds: {98, 102},
      includeEventSystem: true);
}

final class _Files implements SourceFilePort {
  _Files(this.snapshot, this.root, this.overrides);
  final SourceSnapshot snapshot;
  final String root;
  final Map<String, List<int>> overrides;
  @override
  Future<List<int>> read(ConverterId id) async {
    final relative = snapshot.entries
        .singleWhere((entry) => entry.fileId == id)
        .relativePath;
    return overrides[relative] ?? await File('$root/$relative').readAsBytes();
  }
}

MarshalNode _field(MarshalDocument doc, MarshalNode node, String name) =>
    doc.node(node.instanceVariables
        .singleWhere((pair) => doc.node(pair.key).name == name)
        .value);
