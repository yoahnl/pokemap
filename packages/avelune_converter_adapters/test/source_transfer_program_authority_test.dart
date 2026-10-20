import 'dart:typed_data';

import 'package:avelune_converter_adapters/src/source_transfer_program_authority.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/source_invisible_door_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<LiteralTileFixture> _staticAndStairFixture() {
  LiteralFixtureUserDefined tone(double value) {
    final bytes = ByteData(32);
    for (var axis = 0; axis < 3; axis++) {
      bytes.setFloat64(axis * 8, value, Endian.little);
    }
    return LiteralFixtureUserDefined('Tone', bytes.buffer.asUint8List());
  }

  LiteralFixtureObject step(int code) =>
      LiteralFixtureObject('RPG::MoveCommand', {
        '@code': code,
        '@parameters': <Object?>[],
      });
  List<LiteralFixtureEventCommand> route(List<int> codes,
          {bool barrier = true}) =>
      [
        LiteralFixtureEventCommand(209, [
          -1,
          LiteralFixtureObject('RPG::MoveRoute', {
            '@repeat': false,
            '@skippable': false,
            '@list': [...codes.map(step), step(0)],
          })
        ]),
        for (final code in codes) LiteralFixtureEventCommand(509, [step(code)]),
        if (barrier) const LiteralFixtureEventCommand(210, []),
      ];
  const sound = LiteralFixtureEventCommand(250, [
    LiteralFixtureObject('RPG::AudioFile', {
      '@name': 'Exit Door',
      '@volume': 80,
      '@pitch': 100,
    })
  ]);
  return LiteralTileFixture.create(
    scriptsBytes: syntheticInterpretationArchive,
    interpretationProfile: syntheticSourceInterpretationProfile,
    includeEventSystem: true,
    maps: [
      LiteralFixtureMap(id: 7, width: 5, height: 5, layers: [
        List.filled(25, 384),
        List.filled(25, 0),
        List.filled(25, 0),
      ], events: [
        LiteralFixtureEvent(id: 1, x: 1, y: 1, pages: [
          LiteralFixtureEventPage(trigger: 1, commands: [
            sound,
            LiteralFixtureEventCommand(223, [tone(-255), 6]),
            const LiteralFixtureEventCommand(106, [8]),
            const LiteralFixtureEventCommand(201, [0, 9, 1, 1, 2, 1]),
            LiteralFixtureEventCommand(223, [tone(0), 6]),
            const LiteralFixtureEventCommand(0, []),
          ]),
        ]),
        LiteralFixtureEvent(id: 2, x: 3, y: 3, pages: [
          LiteralFixtureEventPage(trigger: 1, commands: [
            ...route([37, 39, 17, 2]),
            sound,
            LiteralFixtureEventCommand(223, [tone(-255), 6]),
            const LiteralFixtureEventCommand(106, [8]),
            const LiteralFixtureEventCommand(201, [0, 9, 1, 1, 4, 1]),
            LiteralFixtureEventCommand(223, [tone(0), 6]),
            ...route([38, 40], barrier: false),
            const LiteralFixtureEventCommand(0, []),
          ]),
        ]),
      ]),
      LiteralFixtureMap(id: 9, width: 5, height: 5, layers: [
        List.filled(25, 384),
        List.filled(25, 0),
        List.filled(25, 0),
      ]),
    ],
  );
}

void main() {
  test('transfer authority reuses one owned authoritative analysis', () async {
    final fixture = await sourceInvisibleDoorFixture();
    final authority = SourceTransferProgramAuthority.forSource(fixture.source);
    final first = authority.analysis;
    expect(authority.analysisFor(source: fixture.source, analysis: first),
        same(first));
    expect(authority.analysis, same(first));
    expect(first.events, hasLength(1));
    expect(() => first.events.clear(), throwsUnsupportedError);
    expect(() => first.events.single.pages.clear(), throwsUnsupportedError);
    expect(
        () => first.events.single.pages.first.sourcePage
            .toJson()['triggerCode'] = 4,
        throwsUnsupportedError);
    expect(() => first.events.single.pages.first.body.nodes.clear(),
        throwsUnsupportedError);
  });

  test('six transfer families share one owned analysis and preserve outputs',
      () async {
    final fixture = await sourceInvisibleDoorFixture();
    final source = fixture.source;
    final authority = SourceTransferProgramAuthority.forSource(source);
    final analysis = authority.analysis;
    final legacy = sourceRoutedDoorPrograms(source: source, analysis: analysis);
    final shared = sourceRoutedDoorPrograms(
        source: source, analysis: analysis, authority: authority);
    expect(shared, hasLength(1));
    expect(shared.map((key, value) => MapEntry(key.value, value.toJson())),
        legacy.map((key, value) => MapEntry(key.value, value.toJson())));
    expect(
        sourceStaticDoorPrograms(
            source: source, analysis: analysis, authority: authority),
        isEmpty);
    expect(
        sourceStairPrograms(
            source: source, analysis: analysis, authority: authority),
        isEmpty);
    expect(
        sourceHoleNativePrograms(
            source: source, analysis: analysis, authority: authority),
        isEmpty);
    expect(
        sourceElevatorPrograms(
            source: source, analysis: analysis, authority: authority),
        isEmpty);
    expect(
        sourceWarpTileNativePrograms(
                source: source, analysis: analysis, authority: authority)
            .programs,
        isEmpty);
    expect(authority.analysisFor(source: source, analysis: analysis),
        same(analysis));
  });

  test(
      'static doors and stairs reuse the same authority without changing fingerprints',
      () async {
    final fixture = await _staticAndStairFixture();
    final source = fixture.source;
    final authority = SourceTransferProgramAuthority.forSource(source);
    final analysis = authority.analysis;
    final statics = sourceStaticDoorPrograms(
        source: source, analysis: analysis, authority: authority);
    final stairs = sourceStairPrograms(
        source: source, analysis: analysis, authority: authority);
    expect(statics, hasLength(1));
    expect(stairs, hasLength(1));
    expect(statics.values.single.sourceEventId, 1);
    expect(stairs.values.single.sourceEventId, 2);
    expect(
        statics.values.single.toJson(),
        sourceStaticDoorPrograms(source: source, analysis: analysis)
            .values
            .single
            .toJson());
    expect(
        stairs.values.single.toJson(),
        sourceStairPrograms(source: source, analysis: analysis)
            .values
            .single
            .toJson());
    expect(authority.analysisFor(source: source, analysis: analysis),
        same(analysis));
    for (final target in analysis.events) {
      final forged = SourceEventDefinition(
          sourceMapId: target.sourceMapId,
          sourceEventId: target.sourceEventId,
          sourceFileId: target.sourceFileId,
          identity: target.identity,
          name: target.name,
          x: target.x + 1,
          y: target.y,
          locator: target.locator,
          pages: target.pages);
      final modified = SourceEventAnalysis(
          profile: analysis.profile,
          events: [
            for (final event in analysis.events)
              if (identical(event, target)) forged else event
          ],
          diagnostics: analysis.diagnostics);
      final staticIds = sourceStaticDoorPrograms(
              source: source, analysis: modified, authority: authority)
          .keys;
      final stairIds = sourceStairPrograms(
              source: source, analysis: modified, authority: authority)
          .keys;
      expect(staticIds, isNot(contains(target.identity)));
      expect(stairIds, isNot(contains(target.identity)));
    }
  });

  test('foreign source cannot reuse an authority even with equal hashes',
      () async {
    final first = await sourceInvisibleDoorFixture();
    final second = await sourceInvisibleDoorFixture();
    expect(first.source.canonicalHash, second.source.canonicalHash);
    final authority = SourceTransferProgramAuthority.forSource(first.source);
    final foreign = SourceEventAnalyzer.forProject(second.source,
            profile: SourceEventProfile.forProject(second.source))
        .analyze();
    expect(
        () => sourceRoutedDoorPrograms(
            source: second.source, analysis: foreign, authority: authority),
        throwsA(isA<NativeWriteException>().having(
            (e) => e.code, 'code', 'events.transfer.authority_binding')));
  });

  test(
      'foreign settings or unqualified profile cannot acquire transfer authority',
      () async {
    final fixture = await sourceInvisibleDoorFixture();
    final source = fixture.source;
    final authority = SourceTransferProgramAuthority.forSource(source);
    final original = authority.analysis;
    for (final profile in [
      SourceEventProfile(
          scriptsArchiveHash: Sha256Hash('f' * 64),
          sourceSnapshotHash: source.snapshot.canonicalHash,
          normalizationHash: source.canonicalHash,
          interpretationProfile: syntheticSourceInterpretationProfile),
      SourceEventProfile(
          scriptsArchiveHash: original.profile.scriptsArchiveHash,
          sourceSnapshotHash: source.snapshot.canonicalHash,
          normalizationHash: source.canonicalHash),
    ]) {
      final foreign = SourceEventAnalysis(
          profile: profile,
          events: original.events,
          diagnostics: original.diagnostics);
      expect(
          () => authority.analysisFor(source: source, analysis: foreign),
          throwsA(isA<NativeWriteException>().having(
              (e) => e.code, 'code', 'events.transfer.authority_binding')));
      expect(
          sourceRoutedDoorPrograms(
              source: source, analysis: foreign, authority: authority),
          isEmpty);
    }
  });

  test(
      'forged analysis remains checked against raw authority event fingerprints',
      () async {
    final fixture = await sourceInvisibleDoorFixture();
    final source = fixture.source;
    final authority = SourceTransferProgramAuthority.forSource(source);
    final original = authority.analysis;
    final event = original.events.single;
    final forged = SourceEventDefinition(
        sourceMapId: event.sourceMapId,
        sourceEventId: event.sourceEventId,
        sourceFileId: event.sourceFileId,
        identity: event.identity,
        name: event.name,
        x: event.x + 1,
        y: event.y,
        locator: event.locator,
        pages: event.pages);
    final changed = SourceEventAnalysis(
        profile: original.profile,
        events: [forged],
        diagnostics: original.diagnostics);
    expect(
        sourceRoutedDoorPrograms(
            source: source, analysis: changed, authority: authority),
        isEmpty);
    expect(
        sourceRoutedDoorPrograms(source: source, analysis: changed), isEmpty);
    expect(
        sourceRoutedDoorPrograms(
            source: source, analysis: original, authority: authority),
        hasLength(1));
  });
}
