import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';
import 'support/source_external_original_fixture.dart';

Future<LiteralTileFixture> _fixture({String defect = ''}) {
  List<int> tone(double value) {
    final bytes = ByteData(32);
    for (var i = 0; i < 3; i++) {
      bytes.setFloat64(i * 8, value, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  return LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    maps: [
      LiteralFixtureMap(id: 1, events: [
        LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [
          LiteralFixtureEventPage(trigger: 1, commands: [
            const LiteralFixtureEventCommand(250, [
              LiteralFixtureObject('RPG::AudioFile', {
                '@name': 'Exit Door',
                '@volume': 80,
                '@pitch': 100,
              }),
            ]),
            LiteralFixtureEventCommand(223, [
              LiteralFixtureUserDefined('Tone', tone(-255)),
              defect == 'oversizeWorldFade' ? 201 : 6,
            ]),
            const LiteralFixtureEventCommand(106, [8]),
            const LiteralFixtureEventCommand(201, [0, 2, 0, 0, 0, 1]),
            LiteralFixtureEventCommand(231, [
              1,
              defect == 'unknownPicture'
                  ? 'dpic_unknown'
                  : 'dpic_viridianforest',
              0,
              0,
              0,
              0,
              100,
              100,
              defect == 'opaqueInitially' ? 255 : 0,
              0,
            ]),
            LiteralFixtureEventCommand(232, [
              1,
              defect == 'negativeFadeIn'
                  ? -1
                  : defect == 'unfinishedFadeIn'
                      ? 21
                      : 5,
              0,
              0,
              0,
              0,
              100,
              100,
              255,
              0,
            ]),
            const LiteralFixtureEventCommand(106, [20]),
            LiteralFixtureEventCommand(223, [
              LiteralFixtureUserDefined('Tone', tone(0)),
              6,
            ]),
            LiteralFixtureEventCommand(232, [
              1,
              defect == 'oversizePictureFade' ? 201 : 40,
              0,
              0,
              0,
              0,
              100,
              100,
              0,
              0,
            ]),
            LiteralFixtureEventCommand(106, [
              defect == 'shortFinalWait'
                  ? 0
                  : defect == 'longFinalWait'
                      ? 80
                      : 40,
            ]),
            if (defect != 'missingErase')
              const LiteralFixtureEventCommand(235, [1]),
            if (defect == 'businessCommand')
              const LiteralFixtureEventCommand(121, [1, 1, 0]),
            const LiteralFixtureEventCommand(0, []),
          ]),
        ]),
      ]),
      LiteralFixtureMap(id: 2),
    ],
  );
}

SourceEventAnalysis _analyze(NormalizedSourceProject source) =>
    SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();

Future<LiteralTileFixture> _directionalFixture({String defect = ''}) {
  List<int> tone(double value) {
    final data = ByteData(32);
    for (var i = 0; i < 3; i++) {
      data.setFloat64(i * 8, value, Endian.little);
    }
    return data.buffer.asUint8List();
  }

  return LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    maps: [
      LiteralFixtureMap(id: 1, events: [
        LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [
          LiteralFixtureEventPage(trigger: 1, commands: [
            LiteralFixtureEventCommand(
                111, [6, defect == 'foreignFacing' ? 0 : -1, 2]),
            const LiteralFixtureEventCommand(
                250,
                [
                  LiteralFixtureObject('RPG::AudioFile', {
                    '@name': 'Exit Door',
                    '@volume': 80,
                    '@pitch': 100,
                  }),
                ],
                indent: 1),
            LiteralFixtureEventCommand(
                223,
                [
                  LiteralFixtureUserDefined('Tone', tone(-255)),
                  6,
                ],
                indent: 1),
            const LiteralFixtureEventCommand(106, [8], indent: 1),
            const LiteralFixtureEventCommand(201, [0, 2, 0, 0, 0, 1],
                indent: 1),
            LiteralFixtureEventCommand(
                223,
                [
                  LiteralFixtureUserDefined('Tone', tone(0)),
                  6,
                ],
                indent: 1),
            if (defect == 'extraBusiness')
              const LiteralFixtureEventCommand(121, [1, 1, 0], indent: 1),
            const LiteralFixtureEventCommand(0, [], indent: 1),
            if (defect == 'falseBranch') ...[
              const LiteralFixtureEventCommand(411, []),
              const LiteralFixtureEventCommand(121, [1, 1, 0], indent: 1),
              const LiteralFixtureEventCommand(0, [], indent: 1),
            ],
            const LiteralFixtureEventCommand(412, []),
            const LiteralFixtureEventCommand(0, []),
          ]),
        ]),
      ]),
      LiteralFixtureMap(id: 2),
    ],
  );
}

void main() {
  test('attests the complete player-facing conditional transfer', () async {
    final fixture = await _directionalFixture();
    final analysis = _analyze(fixture.source);
    final event = analysis.eventAt(1, 1)!;
    final program = sourceStaticDoorPrograms(
        source: fixture.source, analysis: analysis)[event.identity];
    expect(program, isNotNull);
    expect(program!.targetSourceMapId, 2);
    expect(
        program.isBoundTo(
            source: fixture.source, analysis: analysis, event: event),
        isTrue);
    final branch =
        event.pages.single.body.nodes.single as SourceConditionalNode;
    expect(branch.condition.evaluate(playerFacing: 2), isTrue);
    expect(branch.condition.evaluate(playerFacing: 8), isFalse);
    final originalPage = event.pages.single;
    final forged = SourceEventDefinition(
        sourceMapId: event.sourceMapId,
        sourceEventId: event.sourceEventId,
        sourceFileId: event.sourceFileId,
        identity: event.identity,
        name: event.name,
        x: event.x,
        y: event.y,
        locator: event.locator,
        pages: [
          SourceEventPageAnalysis(
            sourcePage: originalPage.sourcePage,
            locator: originalPage.locator,
            condition: originalPage.condition,
            graphic: originalPage.graphic,
            rawDataRef: originalPage.rawDataRef,
            diagnostics: originalPage.diagnostics,
            body: SourceEventBlock(span: originalPage.body.span, nodes: [
              SourceConditionalNode(branch.span,
                  condition: branch.condition,
                  whenFalse: branch.whenFalse,
                  whenTrue:
                      SourceEventBlock(span: branch.whenTrue.span, nodes: [
                    for (final node in branch.whenTrue.nodes)
                      if (node is SourceWarpNode)
                        SourceWarpNode(node.span,
                            targetSourceMapId: node.targetSourceMapId,
                            x: node.x + 1,
                            y: node.y,
                            direction: node.direction,
                            fade: node.fade)
                      else
                        node,
                  ])),
            ]),
          )
        ]);
    expect(
        program.isBoundTo(
            source: fixture.source, analysis: analysis, event: forged),
        isFalse);
  });

  for (final defect in ['foreignFacing', 'extraBusiness', 'falseBranch']) {
    test('rejects an altered directional transfer: $defect', () async {
      final fixture = await _directionalFixture(defect: defect);
      final analysis = _analyze(fixture.source);
      expect(
          sourceStaticDoorPrograms(source: fixture.source, analysis: analysis),
          isEmpty);
    });
  }
  test(
      'recognizes the complete illustrated fade-in transfer without executing Ruby',
      () async {
    final fixture = await _fixture();
    final analysis = _analyze(fixture.source);
    final event = analysis.eventAt(1, 1)!;
    expect(event.isQuarantined, isFalse);
    final warp = event.pages.single.body.nodes.single as SourceWarpNode;
    final program = warp.originalProgram!;
    expect(
        (warp.targetSourceMapId, warp.x, warp.y, warp.direction), (2, 0, 0, 0));
    expect(program.presentation.name, 'illustratedFadeIn');
    expect(program.illustrationName, 'dpic_viridianforest');
    expect(program.illustrationHoldMs, 1000);
    expect(program.illustrationFadeMs, 2000);
    expect(program.toJson()['illustrationFadeInMs'], 250);
    expect(program.toJson()['nativeIllustrationFadeInMs'], 0);
    expect(program.toJson()['sourcePresentationParityQualified'], isFalse);
    expect(program.toJson()['sourceScriptsExecuted'], 0);
    expect(
        program.isBoundToSourceEvent(
            source: fixture.source,
            profile: analysis.profile,
            event: fixture.source.maps.first.map.events.single),
        isTrue);
  });

  for (final defect in [
    'unknownPicture',
    'opaqueInitially',
    'negativeFadeIn',
    'unfinishedFadeIn',
    'oversizeWorldFade',
    'oversizePictureFade',
    'shortFinalWait',
    'longFinalWait',
    'missingErase',
    'businessCommand',
  ]) {
    test('refuses the altered illustrated fade-in transfer: $defect', () async {
      final fixture = await _fixture(defect: defect);
      final event = _analyze(fixture.source).eventAt(1, 1)!;
      expect(event.isQuarantined, isTrue);
      expect(
          event.pages.single.body.nodes
              .whereType<SourceWarpNode>()
              .every((node) => node.originalProgram == null),
          isTrue);
    });
  }

  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  test(
      'binds both original forest entries, exact illustration and arrival page',
      () async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {148, 149},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((s) => s.isNotEmpty)
                .toList());
    final analysis = _analyze(fixture.source);
    final returnEvent = analysis.eventAt(149, 4)!;
    expect(
        sourceStaticDoorPrograms(source: fixture.source, analysis: analysis)
            .containsKey(returnEvent.identity),
        isTrue);
    for (final row in [(2, 34, 63), (5, 10, 11)]) {
      final event = analysis.eventAt(148, row.$1)!;
      expect(event.isQuarantined, isFalse);
      final warp = event.pages.first.body.nodes.single as SourceWarpNode;
      expect((warp.targetSourceMapId, warp.x, warp.y, warp.direction),
          (149, row.$2, row.$3, 0));
      expect(warp.originalProgram!.illustrationName, 'dpic_viridianforest');
    }
    final arrival = analysis.eventAt(148, 2)!.pages[1];
    expect(arrival.body.nodes.last, isA<SourceTempSwitchNode>());
    final binding = await const SourceExternalWarpBindingResolver().read(
        source: fixture.source,
        analysis: analysis,
        files: fixture.files,
        policy: SourceExternalWarpPolicy.nativeTransitionsWithoutEscapeState);
    expect(binding, isNotNull);
    expect(binding!.illustrations.keys, contains('dpic_viridianforest'));
    final file = binding.files
        .singleWhere((f) => f.relativePath.endsWith('dpic_viridianforest.png'));
    expect(
        binding.artifacts.single.bytes, await fixture.files.read(file.fileId));
    expect(jsonEncode(binding.evidence), contains(file.sha256!.value));
  }, skip: root == null || snapshot == null);

  test('automatic composition and strict writer publish both forest entries',
      () async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {148, 149},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((s) => s.isNotEmpty)
                .toList());
    final directory =
        await Directory.systemTemp.createTemp('source-forest-write-');
    addTearDown(() => directory.delete(recursive: true));
    final limits =
        sourceCatalogStudyWriteLimitsFor(2, includeNativeCatalog: true);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: fixture.source,
            files: fixture.files,
            selectedSourceMapIds: [148, 149],
            projectName: 'Forest entry qualification',
            parentPath: directory.path,
            folderName: 'native',
            limits: limits,
            dependencyDecisions: decisions);
    final probe = await literal([]);
    final base = await literal([
      for (final dependency in probe.dependencies)
        if (!const {148, 149}.contains(dependency.targetSourceMapId))
          LiteralDependencyDecision(
              sourceSnapshotHash: fixture.source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy),
    ]);
    final semantic = (await const SourceSemanticStudyComposer().compose(
        source: fixture.source,
        base: base,
        files: fixture.files,
        limits: limits))!;
    final events = (await const SourceEventStudyComposer().compose(
        source: fixture.source,
        base: semantic,
        files: fixture.files,
        limits: limits))!;
    final rows =
        (events.projection.semanticEvidence['events'] as List).cast<Map>();
    final returnRow = rows.singleWhere((r) =>
        r['sourceIdentity'] == fixture.source.eventIdentity(149, 4).value);
    expect(returnRow['status'], 'adaptedStaticSemantics',
        reason: '${returnRow['gaps']}');
    for (final id in [2, 5]) {
      final identity = fixture.source.eventIdentity(148, id).value;
      final row = rows.singleWhere((r) => r['sourceIdentity'] == identity);
      expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
      final evidence = row['nativeExternalWarp'] as Map;
      expect(evidence['fullSourceParity'], isFalse);
      expect((evidence['program'] as Map)['illustrationFadeInMs'], 250);
      final scenes = events.projection.scenes
          .where((s) => s.metadata['sourceEventIdentity'] == identity);
      final transfers = scenes
          .expand((s) => s.graph.nodes)
          .map((n) => n.payload)
          .whereType<SceneActionPayload>()
          .map((a) => a.interactiveCommand)
          .whereType<SceneWarpInteractiveCommand>()
          .toList();
      expect(transfers, hasLength(1));
      expect(transfers.single.presentation!.mode,
          SceneWarpPresentationMode.illustrated);
      expect(transfers.single.presentation!.illustrationHoldMs, 1000);
      expect(transfers.single.presentation!.illustrationFadeMs, 2000);
    }
    final catalogs = (await SourceCatalogStudyComposer(
      nativeTrainerCatalog: NativePsdkCatalogManifest.builtin(),
      nativeTrainerQualification: events.trainerQualification,
      automaticNativeEncounters: false,
    ).compose(
        source: fixture.source,
        base: events.draft,
        files: fixture.files,
        limits: limits))!;
    final approval = approveNativeFixtureDraft(catalogs.draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, catalogs.draft, limits: limits);
    expect(receipt.verified, isTrue);
  },
      skip: root == null || snapshot == null,
      timeout: const Timeout(Duration(minutes: 8)));
}
