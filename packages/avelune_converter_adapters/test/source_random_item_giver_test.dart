import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';

Future<SourceEventProjection> _project({String defect = ''}) async {
  final skin =
      image.encodePng(image.Image(width: 96, height: 48, numChannels: 4));
  final icon =
      image.encodePng(image.Image(width: 18, height: 32, numChannels: 4));
  final audio = sourceMapMusicFixtureWav();
  Map<String, Object?> pin(String path, List<int> bytes) => {
        'relativePath': path,
        'sha256': literalFixtureHash(bytes).value,
      };
  const skinPath = 'Graphics/Windowskins/tea.png';
  const iconPath = 'Graphics/Icons/key-items.png';
  const audioPath = 'Audio/ME/key-item.wav';
  final profile = SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
    'presentationBindings': {
      'characterSubstitutions': [],
      'routedDoorPatterns': [],
      'pickupFeedbackByRegion': [
        {
          'regionId': 1,
          'windowskinPinnedAsset': pin(skinPath, skin),
          'iconsByPocket': {'8': pin(iconPath, icon)},
          'audioByItemKind': {'keyItem': pin(audioPath, audio)},
        }
      ],
    },
  });
  List<LiteralFixtureEventCommand> face() {
    final step = LiteralFixtureObject('RPG::MoveCommand', {
      '@code': 25,
      '@parameters': <Object?>[],
    });
    return [
      LiteralFixtureEventCommand(209, [
        defect == 'foreignFacing' ? -1 : 0,
        LiteralFixtureObject('RPG::MoveRoute', {
          '@repeat': false,
          '@skippable': false,
          '@list': [
            step,
            const LiteralFixtureObject(
                'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})
          ],
        })
      ]),
      LiteralFixtureEventCommand(509, [step]),
    ];
  }

  LiteralFixtureEventPage page(bool complete) => LiteralFixtureEventPage(
        characterName: 'Giver',
        moveType: complete && defect == 'changedMovement' ? 3 : 1,
        through: defect == 'through',
        directionFix: defect == 'fixed',
        autonomousRouteCodes: defect == 'opaqueUnusedRoute' ? [45, 0] : [24, 0],
        selfSwitch: complete ? 'A' : null,
        commands: [
          const LiteralFixtureEventCommand(101, ['A gift for you.']),
          if (!complete) ...[
            const LiteralFixtureEventCommand(111, [12, r'!$bag.has?(:TEA)']),
            const LiteralFixtureEventCommand(355, ['pbReceiveItem(:TEA)'],
                indent: 1),
            const LiteralFixtureEventCommand(0, [], indent: 1),
            const LiteralFixtureEventCommand(412, []),
          ],
          ...face(),
          if (!complete) const LiteralFixtureEventCommand(123, ['A', 0]),
          if (defect == 'opaqueBody')
            const LiteralFixtureEventCommand(355, ['Kernel.eval("x")']),
          const LiteralFixtureEventCommand(0, []),
        ],
      );
  final fixture = await LiteralTileFixture.create(
    interpretationProfile: profile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    maps: [
      LiteralFixtureMap(id: 125, width: 7, height: 7, layers: [
        List.filled(49, 384),
        List.filled(49, 0),
        List.filled(49, 0),
      ], events: [
        LiteralFixtureEvent(
            id: 11,
            x: 3,
            y: 3,
            name: 'Source giver',
            pages: [page(false), page(true)])
      ])
    ],
    extraFiles: {
      'Graphics/Characters/Giver.png':
          image.encodePng(image.Image(width: 128, height: 192)),
      skinPath: skin,
      iconPath: icon,
      audioPath: audio,
      'Data/map_metadata.dat': literalFixtureMarshal({
        125: const LiteralFixtureObject('GameData::MapMetadata', {
          '@id': 125,
          '@town_map_position': [1, 0, 0],
          '@real_name': 'Gift house',
        }),
      }),
      'Data/items.dat': literalFixtureMarshal({
        const LiteralFixtureSymbol('TEA'):
            const LiteralFixtureObject('GameData::Item', {
          '@id': LiteralFixtureSymbol('TEA'),
          '@real_name': 'Tea',
          '@real_name_plural': 'Tea',
          '@real_portion_name': null,
          '@real_portion_name_plural': null,
          '@pocket': 8,
          '@price': 0,
          '@sell_price': 0,
          '@bp_price': 1,
          '@field_use': 0,
          '@battle_use': 0,
          '@flags': ['KeyItem'],
          '@consumable': false,
          '@show_quantity': null,
          '@move': null,
          '@real_description': 'A source gift.',
          '@pbs_file_suffix': '',
        }),
      }),
    },
  );
  final source = fixture.source;
  var analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  if (defect == 'forgedPosition') {
    final original = analysis.events.single;
    analysis = SourceEventAnalysis(
        profile: analysis.profile,
        diagnostics: analysis.diagnostics,
        events: [
          SourceEventDefinition(
            identity: original.identity,
            sourceFileId: original.sourceFileId,
            sourceMapId: original.sourceMapId,
            sourceEventId: original.sourceEventId,
            name: original.name,
            x: original.x + 1,
            y: original.y,
            locator: original.locator,
            pages: original.pages,
          )
        ]);
  }
  final items = await const SourceEventItemBindingResolver().read(
      snapshot: source.snapshot,
      files: fixture.files,
      symbols: ['TEA'],
      eventProfile: analysis.profile);
  final pickup = await const SourcePickupFeedbackResolver().read(
      source: source,
      files: fixture.files,
      item: items.bindings['TEA']!,
      sourceMapId: 125,
      helper: SourceItemGrantHelper.receiveItem);
  final character = await const SourceEventCharacterImporter().read(
      snapshot: source.snapshot,
      files: fixture.files,
      charsetName: 'Giver',
      sourcePattern: 0,
      sourceDirection: 2);
  return const SourceEventProjector().project(
      source: source,
      analysis: analysis,
      nativeMaps: {
        125: MapData(
            id: 'house',
            name: 'House',
            size: const GridSize(width: 7, height: 7),
            layers: [
              if (defect == 'changedCollision')
                MapLayer.collision(
                    id: 'collision',
                    name: 'Collision',
                    collisions: List.generate(49, (index) => index == 0))
            ])
      },
      itemBindings: items.bindings,
      pickupBindings: {
        sourcePickupFeedbackBindingKey(
            sourceMapId: 125,
            sourceSymbol: 'TEA',
            helper: SourceItemGrantHelper.receiveItem): pickup
      },
      characterBindings: {character.bindingKey: character.binding});
}

void main() {
  test(
      'random walking gift giver retains movement, grant and source completion',
      () async {
    final result = await _project();
    final row = (result.semanticEvidence['events'] as List).cast<Map>().single;
    expect(row['gaps'], isEmpty);
    expect(row['status'], 'adaptedStaticSemantics');
    final npc = result.nativeMaps[125]!.entities.single;
    expect(npc.npc!.movement.mode, MapEntityNpcMovementMode.fixedRoute);
    expect(npc.npc!.movement.routeSteps.map((x) => x.toJson()), [
      {'kind': 'randomMove'}
    ]);
    expect(result.registry.records, hasLength(2));
    expect(
        result.registry.records
            .every((record) => record.definitionOrNull != null),
        isTrue);
    expect(
        result.scenes
            .expand((scene) => scene.graph.nodes)
            .map((node) => node.payload)
            .whereType<SceneActionPayload>()
            .map((payload) => payload.interactiveCommand)
            .whereType<SceneGiveItemInteractiveCommand>(),
        hasLength(1));
    expect((row['nativeFixedRoute'] as Map)['sourceParity'], isFalse);
  });
  for (final defect in [
    'foreignFacing',
    'changedMovement',
    'through',
    'fixed',
    'opaqueUnusedRoute',
    'opaqueBody',
    'forgedPosition',
    'changedCollision'
  ]) {
    test('random walking giver refuses $defect without an enabled event',
        () async {
      final result = await _project(defect: defect);
      final row =
          (result.semanticEvidence['events'] as List).cast<Map>().single;
      expect(row['gaps'], isNotEmpty);
      expect(
          result.registry.records
              .every((record) => record.definitionOrNull == null),
          isTrue);
    });
  }
}
