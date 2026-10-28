import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../support/project_audio_test_driver.dart';
import 'spatial_exploration_game_session_runtime_test.dart' as support;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final kind in [
    FieldObstacleKind.cutTree,
    FieldObstacleKind.rockSmashRock,
  ]) {
    for (final scenario in [
      'no',
      'yes',
      'cancel',
      'stale',
      'hidden',
      'stop',
      'pause',
    ]) {
      final confirmed = scenario == 'yes' || scenario == 'pause';
      final startsAnimation = confirmed || scenario == 'stop';
      test(
        '$kind $scenario removes only after animation and sounds once',
        () async {
          final root = await Directory.systemTemp.createTemp(
            'field-obstacle-runtime-',
          );
          addTearDown(() => root.delete(recursive: true));
          final image = '${root.path}/hero.png';
          await File(image)
              .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
          final ability = MapEntityFieldObstacleData(kind: kind).ability!;
          final cue = ProjectSoundCueCatalog.forFieldAbilityId(ability.moveId);
          final model = ProjectModel3dEntry(
            id: 'obstacle',
            name: 'Obstacle',
            sourceAssetId: 'model',
            relativePath: 'assets/models3d/obstacle.glb',
            inspection: Model3dInspection(
              bounds: Model3dBounds(
                min: Model3dVector3(x: -.3, y: 0, z: -.3),
                max: Model3dVector3(x: .3, y: 1, z: .3),
              ),
              meshCount: 1,
              triangleCount: 1,
            ),
          );
          final map = MapData(
            id: 'field',
            name: 'Field',
            version: ProjectVersion.v9,
            size: const GridSize(width: 8, height: 8),
            entities: [
              MapEntity(
                id: 'obstacle',
                kind: MapEntityKind.custom,
                pos: const GridPos(x: 3, y: 3),
                fieldObstacle: MapEntityFieldObstacleData(
                  kind: kind,
                  resetPolicy: FieldObstacleResetPolicy.persistent,
                ),
              ),
            ],
            spatialScene: MapSpatialScene(
              width: 8,
              depth: 8,
              instances: [
                SpatialModelInstance(
                  id: 'instance',
                  modelId: model.id,
                  entityId: 'obstacle',
                  position: Model3dVector3(x: 3.5, y: 0, z: 3.5),
                ),
              ],
            ),
          );
          final project = ProjectManifest(
            version: ProjectVersion.v9,
            name: 'Field actions',
            newGame: const ProjectNewGameConfig(
              enabled: true,
              startMapId: 'field',
            ),
            settings: ProjectSettings(
              dimension: ProjectDimension.threeD,
              defaultPlayerCharacterId: 'hero',
              audio: ProjectAudioSettings(
                cues: {
                  cue: const ProjectSoundBinding(
                    source: ProjectSoundSource.builtin,
                  ),
                },
              ),
            ),
            maps: const [
              ProjectMapEntry(
                id: 'field',
                name: 'Field',
                relativePath: 'maps/field.json',
              ),
            ],
            tilesets: const [],
            models3d: [model],
            characters: [
              ProjectCharacterEntry(
                id: 'hero',
                name: 'Hero',
                tilesetId: 'unused',
                animations: [
                  for (final facing in EntityFacing.values)
                    for (final state in [
                      CharacterAnimationState.walk,
                      CharacterAnimationState.cut,
                      CharacterAnimationState.rockSmash,
                    ])
                      CharacterAnimation(
                        state: state,
                        direction: facing,
                        sourceAssetId: 'hero',
                        frames: const [
                          CharacterAnimationFrame(
                            source: TilesetSourceRect(
                              x: 0,
                              y: 0,
                              width: 32,
                              height: 32,
                            ),
                            durationMs: 200,
                          ),
                        ],
                      ),
                ],
              ),
            ],
          );
          final state = support.descriptor().initialGameState!.copyWith(
            playerPosition: const GridPos(x: 2, y: 3),
            playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 3.5),
            playerFacing: EntityFacing.east,
            progression: PlayerProgression(unlockedFieldAbilities: [ability]),
            party: PlayerParty(
              members: [
                PlayerPokemon(
                  speciesId: 'machop',
                  natureId: 'hardy',
                  abilityId: 'guts',
                  level: 20,
                  currentHp: 30,
                  knownMoveIds: [ability.moveId],
                ),
              ],
            ),
            mapInstanceWorldState: MapInstanceWorldState(
              instancesByMapId: const {},
            ),
          );
          final driver = ProjectAudioTestDriver();
          final audio = RuntimeProjectAudioController(
            mixer: RuntimeAudioMixer(),
            driver: driver,
            settings: project.settings.audio,
          );
          final runtime = SpatialExplorationGameSessionRuntime(
            descriptor: support.descriptor(
              initialState: state,
              additionalCapabilities: {
                FieldObstacleCapabilities.capabilityId,
                ProjectAudioCapabilities.capabilityId,
                ProjectAudioCapabilities.extendedCapabilityId,
              },
            ),
            projectFilePath: () async => '${root.path}/project.json',
            projectAudio: audio,
            preloadedInitialMap:
                ({
                  required projectFilePath,
                  required descriptor,
                  required initialSave,
                }) async => RuntimeInitialMapPreloadResult(
                  bundle: RuntimeMapBundle(
                    manifest: project,
                    map: map,
                    projectRootDirectory: root.path,
                    tilesetAbsolutePathsById: const {},
                    characterAnimationAbsolutePathsByAssetId: {'hero': image},
                  ),
                ),
            mountSession: (_) async {},
            unmountSession: (_) async {},
          );
          addTearDown(runtime.dispose);
          await runtime.load((_) {});
          final session = runtime.session!;
          expect(
            runtime.gameStateSnapshot.mapInstanceWorldState.instanceRef(
              'field',
            ),
            isNotNull,
          );
          if (scenario == 'hidden') {
            session.entityIsPresent = (_, _) => false;
            session.frames(0);
            expect(runtime.overworldInteractions.value.primaryAction, isNull);
            return;
          }
          final request =
              runtime.overworldInteractions.value.primaryAction!.request;
          expect(request.actionId, 'field-obstacle');
          expect(runtime.dispatchOverworldInteraction(request), isTrue);
          expect(runtime.dispatchOverworldInteraction(request), isFalse);
          for (
            var tick = 0;
            tick < 10 && runtime.dialoguePresentationListenable.value == null;
            tick++
          ) {
            await Future<void>.delayed(Duration.zero);
          }
          for (var tick = 0; tick < 3; tick++) {
            final line = runtime.dialoguePresentationListenable.value!;
            if (line.choices.isNotEmpty) break;
            runtime.dispatchDialoguePresentationCommand(
              DialogueAdvanceCommand(snapshotRevision: line.revision),
            );
            await Future<void>.delayed(Duration.zero);
          }
          final choice = runtime.dialoguePresentationListenable.value!;
          expect(choice.choices, hasLength(2));
          if (scenario == 'cancel') {
            session.cancelDialogue();
          } else {
            if (scenario == 'stale')
              session.movement.setNativeTraversalPose(
                x: 1.5,
                z: 3.5,
                facing: EntityFacing.east,
                moving: false,
                animationSeconds: 0,
              );
            runtime.dispatchDialoguePresentationCommand(
              DialogueSelectChoiceCommand(
                snapshotRevision: choice.revision,
                choiceIndex: startsAnimation || scenario == 'stale' ? 0 : 1,
              ),
            );
          }
          await Future<void>.delayed(Duration.zero);
          if (startsAnimation) {
            for (
              var tick = 0;
              tick < 100 &&
                  !session.fieldActionActive &&
                  session.interactionError.value == null;
              tick++
            ) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
            expect(session.interactionError.value, isNull);
            expect(session.fieldActionActive, isTrue);
          }
          if (scenario == 'stop') {
            await runtime.stop(GameSessionExitReason.title);
            expect(session.fieldActionActive, isFalse);
          }
          if (scenario == 'pause') {
            await runtime.pause();
            session.frames(1);
            expect(session.fieldActionActive, isTrue);
            expect(session.modelIsPresent('field', 'instance'), isTrue);
            await runtime.resume();
          }
          expect(session.modelIsPresent('field', 'instance'), isTrue);
          expect(driver.paths, isEmpty);
          session.frames(.1);
          expect(session.modelIsPresent('field', 'instance'), isTrue);
          session.frames(.11);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          expect(session.modelIsPresent('field', 'instance'), !confirmed);
          expect(
            session.movement.canTraverseActor(2.5, 3.5, 3.5, 3.5),
            confirmed,
          );
          expect(driver.paths, hasLength(confirmed ? 1 : 0));
          if (confirmed) {
            final restored = const GameStateSaveEnvelopeMapper().restore(
              support.spatialSave(runtime.gameStateSnapshot),
            );
            expect(
              restored
                  .mapInstanceWorldState
                  .persistentClearedObstacles['field'],
              {'obstacle'},
            );
            expect(runtime.dispatchOverworldInteraction(request), isFalse);
            expect(map.spatialScene!.instances, hasLength(1));
          }
        },
      );
    }
  }
}
