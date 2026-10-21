import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_external_original_fixture.dart';

final class _ChangedIllustrationFiles implements SourceFilePort {
  const _ChangedIllustrationFiles(this.files, this.fileId);
  final SourceFilePort files;
  final ConverterId fileId;

  @override
  Future<List<int>> read(ConverterId id) async {
    final bytes = List<int>.of(await files.read(id));
    if (id == fileId) bytes[bytes.length - 1] ^= 1;
    return bytes;
  }
}

Future<LiteralTileFixture> _fixture({String defect = ''}) {
  List<int> tone(double channel) {
    final data = ByteData(32);
    for (var i = 0; i < 3; i++) {
      data.setFloat64(i * 8, channel, Endian.little);
    }
    return data.buffer.asUint8List();
  }

  const down = LiteralFixtureObject('RPG::MoveCommand', {
    '@code': 1,
    '@parameters': <Object?>[],
  });
  const end = LiteralFixtureObject('RPG::MoveCommand', {
    '@code': 0,
    '@parameters': <Object?>[],
  });
  return LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    switchNames: const [null, 'StartingOver'],
    maps: [
      LiteralFixtureMap(id: 58, events: [
        LiteralFixtureEvent(id: 9, x: 1, y: 0, pages: [
          LiteralFixtureEventPage(
            trigger: 1,
            pattern: 3,
            moveType: defect == 'autonomousMovement' ? 1 : 0,
            characterName: defect == 'visibleGraphic' ? 'Original NPC' : '',
            commands: [
              const LiteralFixtureEventCommand(250, [
                LiteralFixtureObject('RPG::AudioFile', {
                  '@name': 'Exit Door',
                  '@volume': 80,
                  '@pitch': 100,
                }),
              ]),
              LiteralFixtureEventCommand(223, [
                LiteralFixtureUserDefined('Tone', tone(-255)),
                6,
              ]),
              const LiteralFixtureEventCommand(106, [8]),
              LiteralFixtureEventCommand(231, [
                1,
                defect == 'unknownIllustration'
                    ? 'dpic_unknown'
                    : 'dpic_pokemonmansion',
                0,
                0,
                0,
                0,
                100,
                100,
                255,
                0,
              ]),
              LiteralFixtureEventCommand(355, [
                defect == 'opaqueScript'
                    ? 'pbCaveEntrance; unknown_call'
                    : 'pbCaveEntrance',
              ]),
              LiteralFixtureEventCommand(201, [
                0,
                197,
                defect == 'invalidDestination' ? 900 : 0,
                0,
                8,
                1,
              ]),
              const LiteralFixtureEventCommand(106, [20]),
              LiteralFixtureEventCommand(223, [
                LiteralFixtureUserDefined('Tone', tone(0)),
                6,
              ]),
              const LiteralFixtureEventCommand(
                  232, [1, 30, 0, 0, 0, 0, 100, 100, 0, 0]),
              const LiteralFixtureEventCommand(106, [30]),
              if (defect != 'missingErase')
                const LiteralFixtureEventCommand(235, [1]),
              const LiteralFixtureEventCommand(0, []),
            ],
          ),
          LiteralFixtureEventPage(
            trigger: 3,
            globalSwitch: 1,
            pattern: 3,
            commands: [
              const LiteralFixtureEventCommand(111, [12, 'get_self.onEvent?']),
              const LiteralFixtureEventCommand(
                  209,
                  [
                    -1,
                    LiteralFixtureObject('RPG::MoveRoute', {
                      '@repeat': false,
                      '@skippable': true,
                      '@list': [down, end],
                    }),
                  ],
                  indent: 1),
              const LiteralFixtureEventCommand(509, [down], indent: 1),
              const LiteralFixtureEventCommand(210, [], indent: 1),
              const LiteralFixtureEventCommand(0, [], indent: 1),
              const LiteralFixtureEventCommand(412, []),
              LiteralFixtureEventCommand(355, [
                defect == 'opaqueArrival'
                    ? 'setTempSwitchOn("A"); unknown_call'
                    : 'setTempSwitchOn("A")',
              ]),
              const LiteralFixtureEventCommand(0, []),
            ],
          ),
        ]),
      ]),
      LiteralFixtureMap(id: 197),
    ],
  );
}

void main() {
  test(
      'discovers a complete illustrated cave entrance without a declared template',
      () async {
    final fixture = await _fixture();
    final profile = SourceEventProfile.forProject(fixture.source);
    final analysis =
        SourceEventAnalyzer.forProject(fixture.source, profile: profile)
            .analyze();
    final event = analysis.eventAt(58, 9)!;
    expect(event.isQuarantined, isFalse);
    final warp = event.pages.first.body.nodes.single as SourceWarpNode;
    final program = warp.originalProgram!;
    expect((warp.targetSourceMapId, warp.x, warp.y, warp.direction),
        (197, 0, 0, 8));
    expect(program.illustrationName, 'dpic_pokemonmansion');
    expect(program.presentation, SourceExternalWarpPresentation.caveEntrance);
    expect(
        program.declaredProgram.toJson()['mode'], 'automaticSourceStructure');
    expect(program.toJson()['sourceScriptsExecuted'], 0);
    expect(
        program.isBoundToSourceEvent(
            source: fixture.source,
            profile: profile,
            event: fixture.source.maps.first.map.events.single),
        isTrue);
    final forgedMap = jsonDecode(jsonEncode(fixture.source.maps.first.toJson()))
        as Map<String, dynamic>;
    (forgedMap['map']['events'] as List).single['name'] = 'Borrowed entrance';
    expect(
        program.isBoundToSourceEvent(
            source: fixture.source,
            profile: profile,
            event: SourceMapIr.fromJson(forgedMap).map.events.single),
        isFalse);
    expect(event.pages.last.body.nodes.whereType<SourceWarpNode>(), isEmpty);
    await expectLater(
        const SourceExternalWarpBindingResolver().read(
          source: fixture.source,
          analysis: analysis,
          files: fixture.files,
          policy: SourceExternalWarpPolicy.nativeTransitionsWithoutEscapeState,
        ),
        throwsA(isA<SourceExternalWarpBindingUnavailable>().having(
            (error) => error.reason,
            'reason',
            'source_illustration_unqualified')));
  });

  for (final defect in [
    'autonomousMovement',
    'visibleGraphic',
    'unknownIllustration',
    'opaqueScript',
    'invalidDestination',
    'missingErase',
    'opaqueArrival'
  ]) {
    test('does not admit an incomplete or unknown entrance: $defect', () async {
      final fixture = await _fixture(defect: defect);
      final analysis = SourceEventAnalyzer.forProject(fixture.source,
              profile: SourceEventProfile.forProject(fixture.source))
          .analyze();
      expect(
          analysis
              .eventAt(58, 9)!
              .pages
              .expand((page) => page.body.nodes)
              .whereType<SourceWarpNode>()
              .any((warp) => warp.originalProgram != null),
          isFalse);
    });
  }

  final sourceRoot = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  test(
      'original Mansion entrance imports sealed artwork and rejects changed bytes',
      () async {
    final fixture = await readExternalOriginalSource(sourceRoot!, snapshot!,
        selectedMapIds: {58, 197},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((value) => value.isNotEmpty)
                .toList());
    final source = fixture.source;
    final analysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();
    final event = analysis.eventAt(58, 9)!;
    expect(event.isQuarantined, isFalse);
    final warp = event.pages.first.body.nodes.single as SourceWarpNode;
    expect((warp.targetSourceMapId, warp.x, warp.y, warp.direction),
        (197, 10, 35, 8));
    expect(warp.originalProgram!.declaredProgram.toJson()['mode'],
        'automaticSourceStructure');
    final binding = (await const SourceExternalWarpBindingResolver().read(
      source: source,
      analysis: analysis,
      files: fixture.files,
      policy: SourceExternalWarpPolicy.nativeTransitionsWithoutEscapeState,
    ))!;
    expect(binding.programs, contains(event.identity));
    expect(
        binding.isBoundToEvent(
            source: source, analysis: analysis, event: event),
        isTrue);
    expect(
        binding.illustrations['dpic_pokemonmansion']!.name, 'Manoir Pokémon');
    expect(binding.artifacts.single.rawSha256.value,
        'feadec774ce9560976d6d6ec552ed5e45bc9e51fb8bbb009ae7e6b0a12f06fa9');
    expect(binding.mutations.map((mutation) => mutation.actionId),
        ['tileset.import_image', 'element_category.upsert', 'element.upsert']);
    expect(binding.evidence['sourceEscapePoint'], 'notImported');
    await expectLater(
        const SourceExternalWarpBindingResolver()
            .read(source: source, analysis: analysis, files: fixture.files),
        throwsA(isA<SourceExternalWarpBindingUnavailable>().having(
            (error) => error.reason,
            'reason',
            'native_escape_state_decision_required')));
    final picture = source.snapshot.entries.singleWhere((entry) =>
        entry.relativePath == 'Graphics/Pictures/dpic_pokemonmansion.png');
    await expectLater(
        const SourceExternalWarpBindingResolver().read(
          source: source,
          analysis: analysis,
          files: _ChangedIllustrationFiles(fixture.files, picture.fileId),
          policy: SourceExternalWarpPolicy.nativeTransitionsWithoutEscapeState,
        ),
        throwsA(isA<NativeWriteException>().having((error) => error.code,
            'code', 'events.external_warp.image_changed')));
  },
      skip: sourceRoot == null || snapshot == null
          ? 'Original complete source required.'
          : false);
}
