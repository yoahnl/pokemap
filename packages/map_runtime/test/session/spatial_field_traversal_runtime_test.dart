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
  for (final ability in [FieldAbility.waterfall, FieldAbility.whirlpool]) {
    for (final scenario in [
      'success',
      'no',
      'cancel',
      'pause',
      'stop',
      'stop-after-step',
      'obstructed-after-step',
      'reset-after-step',
      'lifecycle',
    ]) {
      test(
        '${ability.name} $scenario follows the owned route without intermediate saves',
        () async {
          final root = await Directory.systemTemp.createTemp(
            'spatial-field-route-',
          );
          addTearDown(() => root.delete(recursive: true));
          final image = '${root.path}/hero.png';
          await File(image)
              .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
          final waterfall = ability == FieldAbility.waterfall;
          final map = MapData(
            id: 'field',
            name: 'Field',
            version: ProjectVersion.v9,
            size: const GridSize(width: 6, height: 4),
            entities: const [
              MapEntity(
                id: 'guard',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 5, y: 3),
                npc: MapEntityNpcData(characterId: 'hero'),
              ),
            ],
            spatialScene: MapSpatialScene(
              width: 6,
              depth: 4,
              heightLevels: [
                for (var z = 0; z < 4; z++)
                  for (var x = 0; x < 6; x++) waterfall && x >= 2 ? x - 1 : 0,
              ],
            ),
            gameplayZones: [
              MapGameplayZone(
                id: 'passage',
                kind: GameplayZoneKind.fieldAction,
                area: const MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 4, height: 1),
                ),
                fieldAction: FieldActionZonePayload(
                  actionKind: waterfall
                      ? FieldActionZoneKind.waterfall
                      : FieldActionZoneKind.whirlpool,
                  waterfall: waterfall
                      ? const WaterfallZonePayload(
                          entry: GridPos(x: 0, y: 0),
                          path: [GridPos(x: 1, y: 0), GridPos(x: 2, y: 0)],
                          exit: GridPos(x: 3, y: 0),
                          direction: MapConnectionDirection.east,
                        )
                      : null,
                  whirlpool: waterfall
                      ? null
                      : const WhirlpoolZonePayload(
                          entry: GridPos(x: 0, y: 0),
                          path: [GridPos(x: 1, y: 0), GridPos(x: 2, y: 0)],
                          exit: GridPos(x: 3, y: 0),
                          direction: MapConnectionDirection.east,
                        ),
                ),
              ),
              const MapGameplayZone(
                id: 'water',
                kind: GameplayZoneKind.movement,
                area: MapRect(
                  pos: GridPos(x: 0, y: 0),
                  size: GridSize(width: 6, height: 4),
                ),
                movement: MovementZonePayload(requiredMode: MovementMode.surf),
              ),
            ],
          );
          final cue = ProjectSoundCueCatalog.forFieldAbilityId(ability.moveId);
          final project = ProjectManifest(
            name: 'Routes',
            version: ProjectVersion.v9,
            newGame: const ProjectNewGameConfig(
              enabled: true,
              startMapId: 'field',
            ),
            maps: const [
              ProjectMapEntry(
                id: 'field',
                name: 'Field',
                relativePath: 'maps/field.json',
              ),
            ],
            tilesets: const [],
            settings: ProjectSettings(
              dimension: ProjectDimension.threeD,
              defaultPlayerCharacterId: 'hero',
              surf: const ProjectSurfSettings(
                requiresKnownMove: false,
                accessMode: ProjectSurfAccessMode.always,
              ),
              audio: ProjectAudioSettings(
                cues: {
                  cue: const ProjectSoundBinding(
                    source: ProjectSoundSource.builtin,
                  ),
                },
              ),
            ),
            characters: [
              ProjectCharacterEntry(
                id: 'hero',
                name: 'Hero',
                tilesetId: 'unused',
                animations: [
                  for (final facing in EntityFacing.values)
                    for (final motion in [
                      CharacterAnimationState.walk,
                      CharacterAnimationState.surf,
                    ])
                      CharacterAnimation(
                        state: motion,
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
                            durationMs: 100,
                          ),
                        ],
                      ),
                ],
              ),
            ],
          );
          final initial = support.descriptor().initialGameState!.copyWith(
            currentMapId: 'field',
            playerPosition: const GridPos(x: 1, y: 1),
            playerSpatialPosition: PlayerSpatialPosition(x: 1.5, z: 1.5),
            playerFacing: EntityFacing.east,
            playerMovementMode: MovementMode.surf,
            progression: PlayerProgression(unlockedFieldAbilities: [ability]),
            repelState: RepelState.active(itemId: 'repel', steps: 20),
            party: PlayerParty(
              members: [
                PlayerPokemon(
                  speciesId: 'golduck',
                  natureId: 'hardy',
                  abilityId: 'damp',
                  level: 30,
                  currentHp: 40,
                  knownMoveIds: [ability.moveId],
                ),
              ],
            ),
            mapInstanceWorldState: MapInstanceWorldState(
              instancesByMapId: const {},
            ),
          );
          final audioDriver = ProjectAudioTestDriver();
          final audio = RuntimeProjectAudioController(
            mixer: RuntimeAudioMixer(),
            driver: audioDriver,
            settings: project.settings.audio,
          );
          final movements = <RuntimeCommittedMovement>[];
          final runtime = SpatialExplorationGameSessionRuntime(
            descriptor: support.descriptor(
              initialState: initial,
              additionalCapabilities: {
                SpatialGameplayCapabilities.capabilityId,
                SpatialGameplayCapabilities.fieldTraversalCapabilityId,
                SurfGameplayCapabilities.capabilityId,
                ProjectAudioCapabilities.capabilityId,
                ProjectAudioCapabilities.extendedCapabilityId,
              },
            ),
            projectFilePath: () async => '${root.path}/project.json',
            projectAudio: audio,
            onCommittedMovement: movements.add,
            mountSession: (_) async {},
            unmountSession: (_) async {},
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
          );
          addTearDown(runtime.dispose);
          await runtime.load((_) {});
          final session = runtime.session!;
          final request =
              runtime.overworldInteractions.value.primaryAction!.request;
          expect(request.actionId, 'field-traversal');
          expect(runtime.dispatchOverworldInteraction(request), isTrue);
          for (
            var tick = 0;
            tick < 15 && runtime.dialoguePresentationListenable.value == null;
            tick++
          ) {
            await Future<void>.delayed(Duration.zero);
          }
          var prompt = runtime.dialoguePresentationListenable.value!;
          if (prompt.choices.isEmpty) {
            runtime.dispatchDialoguePresentationCommand(
              DialogueAdvanceCommand(snapshotRevision: prompt.revision),
            );
            await Future<void>.delayed(Duration.zero);
            prompt = runtime.dialoguePresentationListenable.value!;
          }
          expect(prompt.choices, hasLength(2));
          if (scenario == 'cancel') {
            session.cancelDialogue();
          } else {
            runtime.dispatchDialoguePresentationCommand(
              DialogueSelectChoiceCommand(
                snapshotRevision: prompt.revision,
                choiceIndex: scenario == 'no' ? 1 : 0,
              ),
            );
          }
          await Future<void>.delayed(Duration.zero);
          final confirmed = scenario != 'cancel' && scenario != 'no';
          expect(session.fieldMotionActive, confirmed);
          if (!confirmed) {
            expect(
              runtime.gameStateSnapshot.playerSpatialPosition,
              initial.playerSpatialPosition,
            );
            expect(audioDriver.paths, isEmpty);
            expect(movements, isEmpty);
            return;
          }
          session.frames(.1);
          final visual = session.frame(0);
          expect(visual.x, session.movement.x);
          expect(visual.y, session.movement.y);
          await expectLater(runtime.captureCheckpoint(), throwsStateError);
          expect(session.movement.x, greaterThan(1.5));
          if (waterfall) expect(session.movement.groundY, closeTo(.375, .0001));
          if (scenario == 'lifecycle') {
            final pose = session.movement.spatialPosition;
            session.setLifecyclePaused(true);
            session.frames(1);
            expect(session.movement.spatialPosition, pose);
            session.setLifecyclePaused(false);
          }
          expect(movements, isEmpty);
          if (scenario == 'pause') {
            final position = session.movement.spatialPosition;
            final height = session.movement.groundY;
            await runtime.pause();
            session.frames(1);
            expect(session.movement.spatialPosition, position);
            expect(session.movement.groundY, height);
            await runtime.resume();
          }
          if (scenario == 'stop') {
            await runtime.stop(GameSessionExitReason.title);
            await Future<void>.delayed(Duration.zero);
            expect(
              session.movement.spatialPosition,
              initial.playerSpatialPosition,
            );
            expect(movements, isEmpty);
            expect(audioDriver.paths, isEmpty);
            return;
          }
          if (scenario == 'stop-after-step' ||
              scenario == 'obstructed-after-step' ||
              scenario == 'reset-after-step') {
            session.frames(.15);
            await Future<void>.delayed(Duration.zero);
            expect(movements, hasLength(1));
            expect(runtime.gameStateSnapshot.repelState.remainingSteps, 19);
            if (scenario == 'reset-after-step') {
              session.frames(.05);
              session.resetPosition();
            } else if (scenario == 'stop-after-step') {
              session.frames(.05);
              await runtime.stop(GameSessionExitReason.title);
            } else {
              session.npcAutonomousPose = (_) =>
                  const SpatialCinematicActorPose(
                    x: 3.5,
                    z: 1.5,
                    facing: EntityFacing.west,
                  );
              session.frames(.25);
            }
            await Future<void>.delayed(const Duration(milliseconds: 5));
            expect(
              session.movement.spatialPosition,
              initial.playerSpatialPosition,
            );
            expect(
              runtime.gameStateSnapshot.playerSpatialPosition,
              initial.playerSpatialPosition,
            );
            expect(runtime.gameStateSnapshot.repelState.remainingSteps, 19);
            expect(movements, hasLength(1));
            expect(audioDriver.paths, isEmpty);
            return;
          }
          for (var tick = 0; tick < 3; tick++) {
            session.frames(.25);
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          expect(session.interactionError.value, isNull);
          expect(session.fieldMotionActive, isFalse);
          final result = runtime.gameStateSnapshot;
          expect(result.playerPosition, const GridPos(x: 4, y: 1));
          expect(
            result.playerSpatialPosition,
            PlayerSpatialPosition(x: 4.5, z: 1.5),
          );
          expect(result.playerMovementMode, MovementMode.surf);
          expect(movements, hasLength(3));
          expect(result.repelState.remainingSteps, 17);
          expect(audioDriver.paths, hasLength(1));
          final checkpoint = await runtime.captureCheckpoint();
          final restored = gameStateFromStrictSaveJson(
            Map<String, dynamic>.from(checkpoint!.state),
          );
          expect(restored.playerSpatialPosition, result.playerSpatialPosition);
          expect(restored.playerMovementMode, MovementMode.surf);
        },
      );
    }
  }
}
