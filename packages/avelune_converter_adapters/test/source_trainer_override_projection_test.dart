import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_trainer_fixture.dart';

void main() {
  for (final hidden in [false, true]) {
    test('native global trainer override cannot launch battle hidden=$hidden',
        () async {
      const roster = (type: 'FRLG_BUGCATCHER', name: 'Brent', version: 0);
      final trainer = nativeTrainerFixtureEvent(roster, 1);
      final after = trainer.pages[1];
      final fixture = await LiteralTileFixture.create(
          interpretationProfile: syntheticSourceInterpretationProfile,
          scriptsBytes: syntheticInterpretationArchive,
          includeEventSystem: true,
          extraFiles: {
            ...nativeTrainerFixtureFiles([roster]),
            'PBS/pokemon.txt': utf8.encode('[RATTATA]\nName = Rattata\n'),
            'Data/species.dat': literalFixtureMarshal({
              const LiteralFixtureSymbol('RATTATA'):
                  const LiteralFixtureObject('GameData::Species', {
                '@id': LiteralFixtureSymbol('RATTATA'),
                '@species': LiteralFixtureSymbol('RATTATA'),
                '@form': 0,
                '@real_name': 'Rattata',
              }),
            }),
            'Graphics/Characters/OriginalTrainer.png':
                image.encodePng(image.Image(width: 128, height: 192)),
          },
          maps: [
            LiteralFixtureMap(id: 1, width: 4, height: 3, layers: [
              List.filled(12, 384),
              List.filled(12, 0),
              List.filled(12, 0)
            ], events: [
              LiteralFixtureEvent(
                  id: 1,
                  x: 1,
                  y: 1,
                  name: trainer.name,
                  pages: [
                    ...trainer.pages,
                    LiteralFixtureEventPage(
                        globalSwitch: 1,
                        through: hidden,
                        characterName: hidden ? '' : 'OriginalTrainer',
                        commands: hidden
                            ? const [LiteralFixtureEventCommand(0, [])]
                            : [
                                const LiteralFixtureEventCommand(
                                    101, ['The tournament has ended.']),
                                ...after.commands.skip(1)
                              ]),
                  ])
            ])
          ]);
      final source = await const RmxpSourceNormalizer().normalize(
          snapshot: fixture.snapshot,
          files: fixture.files,
          interpretationProfile: syntheticSourceInterpretationProfile,
          includeEventSystem: true);
      final analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source))
          .analyze();
      expect(analysis.events.single.isQuarantined, isFalse);
      final bindings = await const SourceTrainerEventBindingResolver()
          .read(source: source, analysis: analysis, files: fixture.files);
      expect(bindings.byEventIdentity, hasLength(1),
          reason: '${bindings.refusals}');
      final binding = bindings.byEventIdentity.values.single;
      expect(
          binding.isBoundToEvent(
              source: source,
              analysis: analysis,
              event: analysis.events.single),
          isTrue);
      expect(binding.nativeTrainer.team.single.speciesId, 'rattata');
      expect(binding.nativeTrainer.team.single.level, 16);
      final charset = source.snapshot.entries.singleWhere((entry) =>
          entry.relativePath == 'Graphics/Characters/OriginalTrainer.png');
      final projection = const SourceEventProjector().project(
          source: source,
          analysis: analysis,
          nativeMaps: {
            1: const MapData(
                id: 'native_1',
                name: 'Arena',
                size: GridSize(width: 4, height: 3),
                layers: [])
          },
          characterBindings: {
            sourceEventCharacterBindingKey(
                    characterName: 'OriginalTrainer', pattern: 0, direction: 2):
                SourceEventCharacterBinding(
                    characterId: 'native_trainer',
                    sourceSnapshotHash: source.snapshot.canonicalHash,
                    sourceFileId: charset.fileId,
                    sourceFileHash: charset.sha256!,
                    sourcePattern: 0,
                    sourceDirection: 2)
          },
          trainerBindings: bindings.byEventIdentity);
      final row = (projection.semanticEvidence['events'] as List).single as Map;
      expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
      final map = projection.nativeMaps[1]!;
      final entity = map.entities.single;
      SceneAsset scene(int page) => projection.scenes
          .singleWhere((scene) => scene.metadata['sourcePageIndex'] == '$page');
      expect(
          scene(0)
              .graph
              .nodes
              .where((node) => node.payload is SceneBattlePayload),
          hasLength(1));
      expect(
          scene(1)
              .graph
              .nodes
              .where((node) => node.payload is SceneBattlePayload),
          isEmpty);
      expect(
          scene(2)
              .graph
              .nodes
              .where((node) => node.payload is SceneBattlePayload),
          isEmpty);
      final project = ProjectManifest(
          name: 'Trainer override',
          tilesets: const [],
          maps: [
            ProjectMapEntry(
                id: map.id, name: map.name, relativePath: 'maps/native_1.json')
          ],
          eventRegistry: projection.registry,
          facts: projection.facts,
          scenes: projection.scenes,
          dialogues: projection.dialogues,
          trainers: [binding.nativeTrainer]);
      final authority = NarrativeEventDispatchAuthority.prepare(
          registryResult:
              EventRegistryDecodeResult.decoded(projection.registry),
          occurrence: NarrativeEventOccurrence(
              source:
                  NarrativeEventSourceRef.entityInteract(map.id, entity.id)),
          factResolver:
              NarrativeFactRuntimeResolver.fromFacts(projection.facts),
          projectCatalog:
              buildNarrativeEventProjectCatalog(project: project, maps: [map]),
          project: project,
          maps: [map]);
      expect(authority, isA<NarrativeEventDispatchAuthorityReady>());
      final analyzer =
          SourceEventAnalyzer.forProject(source, profile: analysis.profile);
      for (final won in [false, true]) {
        for (final global in [false, true]) {
          final state = GameState.fromJson(GameState(
              saveId: 'trainer',
              narrativeFactRuntimeState:
                  NarrativeFactRuntimeState(overridesByFactId: {
                sourceEventFactBindingId(analyzer.selfFactId(1, 1, 'A')): won,
                sourceEventFactBindingId(analyzer.globalFactId(1)): global,
              })).toJson());
          final decision = (authority as NarrativeEventDispatchAuthorityReady)
              .plan(gameState: state);
          final variant = resolveMapEntityPresentation(
              project: project, gameState: state, map: map, entity: entity);
          expect(variant, isNotNull);
          if (global && hidden) {
            expect(variant!.characterId, isNull);
            expect(variant.blocksMovement, isFalse);
            expect(decision, isA<NarrativeEventDispatchHandled>());
            expect((decision as NarrativeEventDispatchHandled).sceneId,
                scene(2).id);
          } else {
            expect(variant!.characterId, 'native_trainer');
            expect(decision, isA<NarrativeEventDispatchHandled>());
            expect(
                (decision as NarrativeEventDispatchHandled).sceneId,
                scene(global
                        ? 2
                        : won
                            ? 1
                            : 0)
                    .id);
          }
        }
      }
    });
  }
}
