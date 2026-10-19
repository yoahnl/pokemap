import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

void main() {
  for (final sample in [
    (through: false, x: 7, refused: true, owner: false, width: 1),
    (through: true, x: 7, refused: false, owner: false, width: 1),
    (through: false, x: 8, refused: false, owner: false, width: 1),
    (through: false, x: 6, refused: true, owner: true, width: 2),
    (through: false, x: 7, refused: false, owner: true, width: 2),
  ]) {
    test('Joyful arrival preserves conditional blocker admission $sample',
        () async {
      final charset =
          image.encodePng(image.Image(width: 128, height: 192, numChannels: 4));
      const turn = LiteralFixtureObject(
          'RPG::MoveCommand', {'@code': 16, '@parameters': <Object?>[]});
      const turnRoute = LiteralFixtureObject('RPG::MoveRoute', {
        '@repeat': false,
        '@skippable': true,
        '@list': [
          turn,
          LiteralFixtureObject(
              'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})
        ],
      });
      final fixture = await LiteralTileFixture.create(
          interpretationProfile: syntheticSourceInterpretationProfile,
          scriptsBytes: syntheticInterpretationArchive,
          includeEventSystem: true,
          extraFiles: {
            'Data/map_connections.dat': literalFixtureMarshal([]),
            'Data/map_metadata.dat': literalFixtureMarshal({}),
            'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Player\n'),
            'Graphics/Characters/Player.png': charset,
            'Graphics/Characters/Door.png': charset,
            'Graphics/Characters/Biker.png': charset,
          },
          maps: [
            for (final id in [229, 233])
              LiteralFixtureMap(
                  id: id,
                  width: 20,
                  height: 15,
                  layers: [
                    List.filled(300, 384),
                    List.filled(300, 0),
                    List.filled(300, 0)
                  ],
                  events: id == 229
                      ? const [
                          LiteralFixtureEvent(
                              id: 3,
                              x: 4,
                              y: 5,
                              name: 'Joyful Game Corner Door',
                              pages: [
                                LiteralFixtureEventPage(
                                    characterName: 'Door',
                                    commands: [
                                      LiteralFixtureEventCommand(
                                          201, [0, 233, 7, 10, 8, 1]),
                                    ]),
                              ]),
                        ]
                      : [
                          LiteralFixtureEvent(
                              id: 5,
                              x: 7,
                              y: 0,
                              name: 'Biker Cutscene Controller',
                              pages: const [
                                LiteralFixtureEventPage(
                                    through: true,
                                    trigger: 3,
                                    commands: [
                                      LiteralFixtureEventCommand(
                                          355, ['unsupported_cutscene()']),
                                    ]),
                              ]),
                          LiteralFixtureEvent(
                              id: 6,
                              x: sample.x,
                              y: 10,
                              name: 'Biker Cutscene size(${sample.width},1)',
                              pages: [
                                LiteralFixtureEventPage(
                                    characterName: 'Biker',
                                    selfSwitch: sample.owner ? null : 'A',
                                    through: sample.through,
                                    commands: sample.owner
                                        ? const [
                                            LiteralFixtureEventCommand(
                                                209, [0, turnRoute]),
                                            LiteralFixtureEventCommand(
                                                509, [turn]),
                                            LiteralFixtureEventCommand(210, []),
                                          ]
                                        : const [
                                            LiteralFixtureEventCommand(0, [])
                                          ]),
                              ]),
                        ]),
          ]);
      final source = await const RmxpSourceNormalizer().normalize(
          snapshot: fixture.snapshot,
          files: fixture.files,
          interpretationProfile: syntheticSourceInterpretationProfile,
          includeEventSystem: true,
          includeConnections: true);
      final literal = await const LiteralTileComposer().compose(
          source: source,
          files: fixture.files,
          selectedSourceMapIds: [229, 233],
          projectName: 'Joyful arrival admission',
          parentPath: '/private/tmp',
          folderName: 'unused-joyful-arrival');
      final semantic = (await const SourceSemanticStudyComposer()
          .compose(source: source, base: literal, files: fixture.files))!;
      final composition = (await const SourceEventStudyComposer()
          .compose(source: source, base: semantic, files: fixture.files))!;
      final events = (composition.projection.semanticEvidence['events'] as List)
          .cast<Map>();
      Map row(int mapId, int eventId) => events.singleWhere((entry) =>
          (entry['locator'] as Map)['mapId'] == mapId &&
          (entry['locator'] as Map)['eventId'] == eventId);
      final incoming = row(229, 3);
      expect(incoming['sourceIdentity'], source.eventIdentity(229, 3).value);
      expect(incoming['status'],
          sample.refused ? 'quarantinedWholeEvent' : 'adaptedStaticSemantics',
          reason: jsonEncode(events));
      expect(row(233, 5)['status'], 'quarantinedWholeEvent');
      expect(row(233, 6)['status'], 'adaptedStaticSemantics');
      if (sample.refused) {
        expect(incoming['gaps'],
            contains('warpArrivalSourceCharacterUnqualified'));
        expect(composition.projection.nativeMaps[233]!.warps, isEmpty);
        expect(
            composition.draft.mutations.any((entry) =>
                entry.sourceEntityIds.contains(source.eventIdentity(229, 3)) &&
                entry.actionId == 'scene.upsert'),
            isFalse);
      } else {
        expect(composition.projection.nativeMaps[233]!.warps.single.pos.x, 7);
        expect(composition.projection.nativeMaps[233]!.warps.single.pos.y, 10);
      }
      final project = sourceSemanticNativeProject(
              draft: composition.draft,
              maps: composition.projection.nativeMaps,
              mutations: composition.draft.mutations)
          .copyWith(
              facts: composition.projection.facts,
              scenes: composition.projection.scenes,
              eventRegistry: composition.projection.registry,
              worldRules: composition.projection.worldRules);
      final anchors =
          (composition.projection.semanticEvidence['arrivalAnchors'] as List)
              .cast<Map>();
      expect(
          () => const SourceEventArrivalValidator().validate(
                  manifest: project,
                  maps: composition.projection.nativeMaps.values.toList(),
                  arrivalAnchorIds:
                      anchors.map((entry) => entry['warpId'] as String),
                  arrivalCollisionOwners: {
                    for (final entry in anchors)
                      if (entry['arrivalCollisionOwnerEntityId'] != null)
                        entry['warpId'] as String:
                            entry['arrivalCollisionOwnerEntityId'] as String
                  }),
          returnsNormally);
    });
  }
}
