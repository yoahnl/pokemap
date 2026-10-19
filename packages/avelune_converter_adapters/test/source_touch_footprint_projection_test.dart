import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<SourceEventProjection> _project({
  int width = 2,
  String? name,
  bool blocked = false,
  bool mixedSource = false,
  bool mismatchedNative = false,
  bool overlap = false,
  int trigger = 1,
  int? missingSourceCell,
  bool attestContact = true,
  String? suppliedName,
  int? suppliedX,
}) async {
  bool sourceBlocked(int index) => index >= 18 && index < 18 + width &&
      (blocked || mixedSource && index == 19) && index != missingSourceCell;
  final fixture = await LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    tilesets: [LiteralFixtureTileset(id: 1, passages: const {400: 15})],
    maps: [
      for (final id in [1, 2])
        LiteralFixtureMap(
          id: id,
          width: 8,
          height: 6,
          layers: [
            List.filled(48, 384),
            List.filled(48, 0),
            List.generate(48, (index) => id == 1 && sourceBlocked(index) ? 400 : 0),
          ],
          events: id == 1 ? [
            LiteralFixtureEvent(
              id: 1,
              x: 2,
              y: 2,
              name: name ?? 'Gate entrance size($width,1)',
              pages: [LiteralFixtureEventPage(trigger: trigger, commands: const [
                LiteralFixtureEventCommand(201, [0, 2, 5, 3, 2, 0]),
              ])],
            ),
            if (overlap)
              const LiteralFixtureEvent(
                id: 2,
                x: 3,
                y: 2,
                name: 'Overlapping actor',
                pages: [LiteralFixtureEventPage(characterName: 'Actor', commands: [])],
              ),
          ] : [],
        ),
    ],
  );
  final full = SourceEventAnalyzer.forProject(fixture.source,
      profile: SourceEventProfile.forProject(fixture.source)).analyze();
  final original = full.eventAt(1, 1)!;
  final event = attestContact && suppliedName == null && suppliedX == null ? original : SourceEventDefinition(
      sourceMapId: original.sourceMapId, sourceEventId: original.sourceEventId,
      sourceFileId: original.sourceFileId, identity: original.identity,
      name: suppliedName ?? original.name, x: suppliedX ?? original.x,
      y: original.y, locator: original.locator,
      pages: [for (final page in original.pages) SourceEventPageAnalysis(
        sourcePage: page.sourcePage, locator: page.locator,
        condition: page.condition, graphic: page.graphic, body: page.body,
        rawDataRef: attestContact ? page.rawDataRef : null,
        diagnostics: page.diagnostics)]);
  return const SourceEventProjector().project(
    source: fixture.source,
    analysis: SourceEventAnalysis(profile: full.profile,
        events: [event], diagnostics: const []),
    nativeMaps: {
      for (final id in [1, 2])
        id: MapData(id: 'native_$id', name: 'Map $id',
          size: const GridSize(width: 8, height: 6),
          layers: [MapLayer.collision(id: 'collision_$id', name: 'Collision',
            collisions: List.generate(48, (index) => id == 1 &&
              (mismatchedNative && index == 19 ? !sourceBlocked(index) : sourceBlocked(index))))]),
    },
  );
}

Map _evidence(SourceEventProjection projection) =>
    (projection.semanticEvidence['events'] as List).single as Map;

void main() {
  test('supplied three-cell declaration cannot enlarge a source two-cell gate', () async {
    final result = await _project(width: 2, suppliedName: 'Gate size(3,1)');
    expect(_evidence(result)['status'], 'quarantinedWholeEvent');
    expect(result.nativeMaps[1]!.triggers, isEmpty);
  });
  test('supplied contact position cannot move a source two-cell gate', () async {
    final result = await _project(width: 2, suppliedX: 1);
    expect(_evidence(result)['status'], 'quarantinedWholeEvent');
    expect(result.nativeMaps[1]!.triggers, isEmpty);
  });
  test('three-cell touch requires source proof for the third cell', () async {
    final result = await _project(width: 3, blocked: true, missingSourceCell: 20);
    expect(_evidence(result)['status'], 'quarantinedWholeEvent');
    expect(result.nativeMaps[1]!.triggers, isEmpty);
  });
  test('three-cell touch refuses a page without raw source attestation', () async {
    final result = await _project(width: 3, attestContact: false);
    expect(_evidence(result)['status'], 'quarantinedWholeEvent');
    expect(result.nativeMaps[1]!.triggers, isEmpty);
  });
  test('event touch trigger two is not silently converted into trigger one', () async {
    final result = await _project(width: 3, trigger: 2);
    expect(_evidence(result)['status'], 'quarantinedWholeEvent');
    expect(result.nativeMaps[1]!.triggers, isEmpty);
  });
  for (final width in [2, 3]) {
    for (final blocked in [false, true]) {
      test('$width-cell gate preserves every native ${blocked ? 'bump' : 'enter'} contact', () async {
        final result = await _project(width: width, blocked: blocked);
        expect(_evidence(result)['status'], 'adaptedStaticSemantics',
            reason: '${_evidence(result)['gaps']}');
        final map = result.nativeMaps[1]!;
        final trigger = map.triggers.single;
        expect(trigger.area, MapRect(pos: const GridPos(x: 2, y: 2),
            size: GridSize(width: width, height: 1)));
        expect(map.entities.single.size, GridSize(width: width, height: 1));
        expect(result.registry.records.single.definitionOrNull!.source.kind,
            blocked ? NarrativeEventSourceKind.triggerBump : NarrativeEventSourceKind.triggerEnter);
        for (var x = 2; x < 2 + width; x++) {
          if (blocked) {
            final step = stepGameplayWorld(GameplayWorldState.initial(
                map: map, playerPos: GridPos(x: x, y: 3),
                playerFacing: Direction.north),
                const MoveIntent(Direction.north, pixelsPerStep: 16));
            expect(step, isA<Blocked>());
            expect((step as Blocked).triggerBumpContacts.map((contact) => contact.triggerId),
                contains(trigger.id));
          } else {
            expect(resolveNarrativeTriggerEnterFronts(map: map,
                currentPosition: GridPos(x: x, y: 2),
                previousOccupiedTriggerIds: const []).enteredTriggerIds,
                [trigger.id]);
          }
        }
      });
    }
  }

  for (final sample in [
    (name: 'mixed source', width: 2, blocked: false, mixed: true, mismatch: false, overlap: false, directive: null),
    (name: 'native second cell blocked', width: 2, blocked: false, mixed: false, mismatch: true, overlap: false, directive: null),
    (name: 'native second cell passable', width: 3, blocked: true, mixed: false, mismatch: true, overlap: false, directive: null),
    (name: 'overlapping actor', width: 3, blocked: false, mixed: false, mismatch: false, overlap: true, directive: null),
    (name: 'duplicate directives', width: 2, blocked: false, mixed: false, mismatch: false, overlap: false, directive: 'Gate size(2,1) size(3,1)'),
    (name: 'unsupported width', width: 4, blocked: false, mixed: false, mismatch: false, overlap: false, directive: null),
    (name: 'zero height', width: 2, blocked: false, mixed: false, mismatch: false, overlap: false, directive: 'Gate size(2,0)'),
  ]) {
    test('multi-cell touch refuses ${sample.name}', () async {
      final result = await _project(width: sample.width, name: sample.directive,
          blocked: sample.blocked, mixedSource: sample.mixed,
          mismatchedNative: sample.mismatch, overlap: sample.overlap);
      expect(_evidence(result)['status'], 'quarantinedWholeEvent');
      expect(result.nativeMaps[1]!.triggers, isEmpty);
      expect(result.scenes, isEmpty);
    });
  }
}
