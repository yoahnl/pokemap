import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/spatial/spatial_cinematic_runtime_playback_sink.dart';

import '../support/project_audio_test_driver.dart';
import 'spatial_exploration_game_session_runtime_test.dart' as support;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final kind in [
    FieldObstacleKind.cutTree,
    FieldObstacleKind.rockSmashRock,
    FieldObstacleKind.strengthBoulder,
  ]) {
    for (final scenario in [
      'no',
      'yes',
      'cancel',
      'stale',
      'hidden',
      'stop',
      'pause',
      if (kind == FieldObstacleKind.strengthBoulder) 'push',
      if (kind == FieldObstacleKind.strengthBoulder) 'push-pause',
      if (kind == FieldObstacleKind.strengthBoulder) 'push-stop',
      if (kind == FieldObstacleKind.strengthBoulder) 'push-lifecycle',
      if (kind == FieldObstacleKind.strengthBoulder) 'push-obstructed',
    ]) {
      final pushing = scenario.startsWith('push');
      final confirmed = scenario == 'yes' || scenario == 'pause' || pushing;
      final startsAnimation = confirmed || scenario == 'stop';
      final strength = kind == FieldObstacleKind.strengthBoulder;
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
              if (scenario == 'push-obstructed') const MapEntity(id: 'guard',
                kind: MapEntityKind.npc, pos: GridPos(x: 6, y: 6), npc: MapEntityNpcData(characterId: 'hero')),
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
                  if (strength) ProjectSoundCue.fieldStrengthPush: const ProjectSoundBinding(
                    source: ProjectSoundSource.builtin),
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
                      CharacterAnimationState.strength,
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
            repelState: RepelState.active(itemId: 'repel', steps: 20),
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
          final recorded = <RuntimeCommittedMovement>[];
          final runtime = SpatialExplorationGameSessionRuntime(
            onCommittedMovement: recorded.add,
            descriptor: support.descriptor(
              initialState: state,
              additionalCapabilities: {
                FieldObstacleCapabilities.capabilityId,
                FieldObstacleCapabilities.extendedCapabilityId,
                ProjectAudioCapabilities.capabilityId,
                ProjectAudioCapabilities.extendedCapabilityId,
                ProjectAudioCapabilities.fieldMovementCapabilityId,
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
          if (strength) {
            expect(choice.fullText, contains('Force'));
            expect(choice.fullText, contains('poussé'));
          }
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
          expect(session.modelIsPresent('field', 'instance'), strength || !confirmed);
          expect(
            session.movement.canTraverseActor(2.5, 3.5, 3.5, 3.5),
            confirmed && !strength,
          );
          expect(driver.paths, hasLength(confirmed ? 1 : 0));
          if (confirmed) {
            final restored = const GameStateSaveEnvelopeMapper().restore(
              support.spatialSave(runtime.gameStateSnapshot),
            );
            if (strength) {
              expect(restored.mapInstanceWorldState.isStrengthActive(
                restored.mapInstanceWorldState.instanceRef('field')!), isTrue);
              expect(restored.mapInstanceWorldState.persistentClearedObstacles, isEmpty);
            } else {
              expect(restored.mapInstanceWorldState.persistentClearedObstacles['field'], {'obstacle'});
              expect(runtime.dispatchOverworldInteraction(request), isFalse);
            }
            expect(map.spatialScene!.instances, hasLength(1));
          }
          if (pushing) {
            final before = runtime.gameStateSnapshot;
            session.movement.setInput(x: 1, z: 0, run: false);
            session.frames(.01);
            expect(session.fieldMotionActive, isTrue);
            expect(recorded, isEmpty);
            expect(runtime.gameStateSnapshot.mapInstanceWorldState.fieldObstaclePositionForMap('field', 'obstacle'), isNull);
            session.frames(.1);
            final visual = session.frame(0);
            expect(visual.x, session.movement.x);
            expect(visual.z, session.movement.z);
            if (scenario == 'push-lifecycle') {
              final pose = session.movement.spatialPosition;
              session.setLifecyclePaused(true);
              session.frames(1);
              expect(session.movement.spatialPosition, pose);
              session.setLifecyclePaused(false);
            }
            if (scenario == 'push-obstructed') {
              session.npcAutonomousPose = (_) => const SpatialCinematicActorPose(x: 4.5, z: 3.5, facing: EntityFacing.west);
            }
            if (scenario == 'push-pause') {
              final pose = session.movement.spatialPosition;
              await runtime.pause();
              session.frames(1);
              expect(session.movement.spatialPosition, pose);
              await runtime.resume();
            }
            if (scenario == 'push-stop') {
              await runtime.stop(GameSessionExitReason.title);
              expect(session.fieldMotionActive, isFalse);
              expect(session.movement.spatialPosition, before.playerSpatialPosition);
              expect(driver.paths, hasLength(1));
              expect(recorded, isEmpty);
              return;
            }
            session.frames(.3);
            await Future<void>.delayed(const Duration(milliseconds: 10));
            expect(session.interactionError.value, isNull);
            expect(session.fieldMotionActive, isFalse);
            final pushed = runtime.gameStateSnapshot;
            if (scenario == 'push-obstructed') {
              expect(pushed.playerSpatialPosition, before.playerSpatialPosition);
              expect(pushed.mapInstanceWorldState.fieldObstaclePositionForMap('field', 'obstacle'), isNull);
              expect(recorded, hasLength(1));
              expect(pushed.repelState.remainingSteps, 19);
              expect(driver.paths, hasLength(1));
              return;
            }
            expect(pushed.mapInstanceWorldState.fieldObstaclePositionForMap('field', 'obstacle'), const GridPos(x: 4, y: 3));
            expect(pushed.playerSpatialPosition!.x, before.playerSpatialPosition!.x + 1);
            expect(session.modelRuntimeState('field', 'instance')!.translationX, 1);
            expect(driver.paths, hasLength(2));
            expect(recorded, hasLength(1));
            expect(recorded.single.movement.fromCell, before.playerPosition);
            expect(recorded.single.movement.toCell, pushed.playerPosition);
            expect(pushed.repelState.remainingSteps, 19);
            final saved = const GameStateSaveEnvelopeMapper().restore(support.spatialSave(pushed));
            expect(saved.mapInstanceWorldState.fieldObstaclePositionForMap('field', 'obstacle'), const GridPos(x: 4, y: 3));
          }
        },
      );
    }
  }
}
