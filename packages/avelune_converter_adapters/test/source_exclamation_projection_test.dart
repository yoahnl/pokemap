import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<LiteralTileFixture> _fixture(String script,
    {bool utilities = true, bool actor = true, bool badActor = false, bool ownerActor = false}) async {
  final profile = SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
    'sections': {
      ...syntheticSourceInterpretationProfile.sections,
      if (utilities)
        'events.Utilities':
            syntheticSourceInterpretationProfile.sections['events.Interpreter'],
    },
  });
  return LiteralTileFixture.create(
      interpretationProfile: profile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      extraFiles: {
        'Graphics/Characters/Clerk.png': literalFixtureAtlas()
      },
      maps: [
        LiteralFixtureMap(id: 1, width: 3, height: 3, layers: [
          List.filled(9, 384),
          List.filled(9, 0),
          List.filled(9, 0)
        ], events: [
          LiteralFixtureEvent(id: 1, x: 1, y: 2, pages: [
            LiteralFixtureEventPage(characterName: ownerActor ? 'Clerk' : '', commands: [
              LiteralFixtureEventCommand(355, [script]),
              const LiteralFixtureEventCommand(101, ['A delivery for you.']),
            ])
          ]),
          if (actor)
            LiteralFixtureEvent(id: 2, x: 1, y: 1, pages: [
              LiteralFixtureEventPage(characterName: 'Clerk', commands: [
                if (badActor)
                  const LiteralFixtureEventCommand(355, ['opaqueEffect()'])
                else
                  const LiteralFixtureEventCommand(101, ['Hello.']),
              ])
            ]),
        ])
      ]);
}

SourceEventAnalysis _analysis(LiteralTileFixture f) =>
    SourceEventAnalyzer.forProject(f.source,
            profile: SourceEventProfile.forProject(f.source))
        .analyze();
SourceEventProjection _project(LiteralTileFixture f,
    {List<SourceEventDefinition> Function(List<SourceEventDefinition>)?
        transform}) {
  final entry = f.snapshot.entries
      .singleWhere((e) => e.relativePath == 'Graphics/Characters/Clerk.png');
  final original = _analysis(f);
  final analysis = transform == null
      ? original
      : SourceEventAnalysis(
          profile: original.profile,
          events: transform(original.events),
          diagnostics: original.diagnostics);
  return const SourceEventProjector()
      .project(source: f.source, analysis: analysis, nativeMaps: {
    1: MapData(
        id: 'map',
        name: 'Delivery',
        size: const GridSize(width: 3, height: 3),
        layers: [])
  }, characterBindings: {
    sourceEventCharacterBindingKey(
            characterName: 'Clerk', pattern: 0, direction: 2):
        SourceEventCharacterBinding(
            characterId: 'clerk',
            sourceSnapshotHash: f.snapshot.canonicalHash,
            sourceFileId: entry.fileId,
            sourceFileHash: entry.sha256!,
            sourcePattern: 0,
            sourceDirection: 2)
  });
}

Map _row(SourceEventProjection p) => (p.semanticEvidence['events'] as List)
    .cast<Map>()
    .singleWhere((r) => r['locator']['eventId'] == 1);
void main() {
  for (final script in [
    r'pbExclaim($game_player)',
    'pbExclaim(get_character(2))',
    'pbExclaim(get_character(1))'
  ]) {
    test('closed exclamation becomes native cinematic: $script', () async {
      final f = await _fixture(script, ownerActor: script == 'pbExclaim(get_character(1))');
      expect(_analysis(f).eventAt(1, 1)!.isQuarantined, isFalse);
      expect(
          _analysis(f)
              .eventAt(1, 1)!
              .pages
              .single
              .body
              .nodes
              .first
              .runtimeType
              .toString(),
          'SourceExclamationNode');
      final p = _project(f);
      expect(_row(p)['gaps'], isEmpty);
      expect(p.cinematics, hasLength(1));
      final c = p.cinematics.single;
      expect(c.actorCompletionPolicy,CinematicActorCompletionPolicy.restoreInitial);
      expect(
          c.timeline.steps.single.kind, CinematicTimelineStepKind.actorEmote);
      expect(c.timeline.steps.single.durationMs, 500);
      expect(
          c.timeline.steps.single
              .metadata[cinematicTimelineActorEmoteEmoteIdMetadataKey],
          'exclamation');
      expect(
          p.scenes.any((s) =>
              s.graph.nodes.any((n) => n.payload is SceneCinematicPayload)),
          isTrue);
      expect(p.mutations.any((m) => m.actionId == 'cinematic.upsert'), isTrue);
      final mutation = p.mutations.singleWhere((m) => m.actionId == 'cinematic.upsert');
      expect(mutation.sourceEntityIds.toSet(), hasLength(mutation.sourceEntityIds.length));
      expect(mutation.sourceEntityIds, contains(_analysis(f).eventAt(1, 1)!.identity));
      expect(
          c.stageContext!.actorBindings.single.kind,
          script.contains('game_player')
              ? CinematicActorBindingKind.player
              : CinematicActorBindingKind.mapEntity);
    });
  }
  for (final script in [
    'pbExclaim(get_character(0))',
    'pbExclaim(get_character(-1))',
    'pbExclaim(get_character(2), false)',
    'pbExclaim(dynamicTarget)',
    'pbExclaim(get_character(2)); unsafeEffect()',
    'other.pbExclaim(get_character(2))'
  ]) {
    test('unknown syntax stays quarantined: $script', () async {
      final f = await _fixture(script);
      expect(_analysis(f).eventAt(1, 1)!.isQuarantined, isTrue);
      expect(_project(f).cinematics, isEmpty);
    });
  }
  test('Utilities oracle is mandatory', () async {
    final f = await _fixture(r'pbExclaim($game_player)', utilities: false);
    expect(_analysis(f).eventAt(1, 1)!.isQuarantined, isTrue);
    expect(_project(f).cinematics, isEmpty);
  });
  for (final badActor in [false, true]) {
    test('missing or quarantined target refuses publication: $badActor',
        () async {
      final f = await _fixture('pbExclaim(get_character(2))',
          actor: badActor, badActor: badActor);
      final p = _project(f);
      expect(_row(p)['gaps'], contains('sourceExclamationActorUnavailable'));
      expect(p.cinematics, isEmpty);
    });
  }
  for (final id in [1, 2]) {
    test('forged actor position cannot reuse source proof: $id', () async {
      final f = await _fixture('pbExclaim(get_character(2))');
      final p = _project(f,
          transform: (events) => [
                for (final e in events)
                  if (e.sourceEventId == id)
                    SourceEventDefinition(
                        sourceMapId: e.sourceMapId,
                        sourceEventId: e.sourceEventId,
                        sourceFileId: e.sourceFileId,
                        identity: e.identity,
                        name: e.name,
                        x: 0,
                        y: e.y,
                        locator: e.locator,
                        pages: e.pages)
                  else
                    e
              ]);
      expect(_row(p)['gaps'], contains('sourceExclamationActorUnavailable'));
      expect(p.cinematics, isEmpty);
    });
  }
  test('an altered source cannot reuse an exclamation proof', () async {
    final a = await _fixture('pbExclaim(get_character(2))');
    final b = await _fixture(r'pbExclaim($game_player)');
    final node = _analysis(a).eventAt(1, 1)!.pages.single.body.nodes.first
        as SourceExclamationNode;
    expect(
        node.isBoundToSourceEvent(
            source: b.source,
            profile: _analysis(b).profile,
            sourceMapId: 1,
            event: b.source.maps.single.map.events.first),
        isFalse);
  });
}
