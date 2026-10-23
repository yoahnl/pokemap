import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';

import 'source_converted_gym_reward_journey_test.dart'
    show
        ConvertedQaDiskSave,
        installConvertedQaHeadlessAudio,
        mountConvertedQaGame,
        waitConvertedQaIdle;

Future<void> _expectRenderedColor(
  OverworldActorComponent actor,
  List<int> rgb,
) async {
  final source = actor.debugAnimationSource;
  expect(source, isNotNull);
  expect(source!.usesLegacyGrid, isFalse);
  expect(actor.tileImages[source.imageId], isNotNull);
  expect(
    actor.tileImages[source.imageId]!.containsSourceRect(source.sourceRect),
    isTrue,
  );
  final recorder = ui.PictureRecorder();
  actor.render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final rendered = await picture.toImage(
    actor.size.x.ceil(),
    actor.size.y.ceil(),
  );
  try {
    final pixels = (await rendered.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    var colored = 0, transparent = 0;
    for (var offset = 0; offset < pixels.lengthInBytes; offset += 4) {
      if (pixels.getUint8(offset + 3) == 0) {
        transparent++;
      }
      if (pixels.getUint8(offset) == rgb[0] &&
          pixels.getUint8(offset + 1) == rgb[1] &&
          pixels.getUint8(offset + 2) == rgb[2] &&
          pixels.getUint8(offset + 3) == 255) {
        colored++;
      }
    }
    expect(
      colored,
      greaterThan(0),
      reason: 'The imported appearance must render its opaque source pixels.',
    );
    expect(
      transparent,
      greaterThan(0),
      reason: 'The source atlas has a transparent background.',
    );
  } finally {
    rendered.dispose();
    picture.dispose();
  }
}

void _primary(PlayableMapGame game) {
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    ),
    isTrue,
  );
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.primary),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(installConvertedQaHeadlessAudio);
  final referencePath =
      Platform.environment['AVELUNE_STD06_APPEARANCE_REFERENCE'];
  testWidgets(
    'converted appearance preloads a distinct skin, restores it and returns control before saving',
    (tester) async {
      await tester.runAsync(() async {
        final reference = jsonDecode(
          await File(referencePath!).readAsString(),
        ) as Map<String, dynamic>;
        expect(reference['kind'], 'std06ConvertedAppearanceFixture');
        expect(reference['nativeWriterVerified'], isTrue);
        expect(reference['strictReopenVerified'], isTrue);
        expect(reference['sourceScriptsExecuted'], 0);
        expect(reference['aiCalls'], 0);
        final root = reference['projectFilePath'] as String;
        final projectFile = await FileSystemEntity.isDirectory(root)
            ? '$root/project.json'
            : root;
        final mapId = reference['mapId'] as String;
        final actorId = reference['actorId'] as String;
        final baseId = reference['expectedBaseCharacterId'] as String;
        final costumeId = reference['expectedCostumeCharacterId'] as String;
        final spawn = GridPos.fromJson(
          reference['spawn'] as Map<String, dynamic>,
        );
        final end = GridPos.fromJson(
          reference['actorEnd'] as Map<String, dynamic>,
        );
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: projectFile,
          mapId: mapId,
        );
        final owner = bundle.map.entities.singleWhere(
          (entity) => entity.id == reference['ownerAnchorEntityId'],
        );
        final ownerPosition = GridPos.fromJson(
          reference['ownerPosition'] as Map<String, dynamic>,
        );
        expect(owner.pos, ownerPosition);
        expect(ownerPosition, GridPos(x: spawn.x, y: spawn.y - 1));
        expect(
          owner.presentation!.variants.single.interactionMode,
          MapEntityInteractionMode.overlap,
        );
        final event = bundle.manifest.eventRegistry!.records
            .singleWhere(
              (record) => record.definitionOrNull?.id == reference['eventId'],
            )
            .definitionOrNull!;
        expect(
          event.source,
          NarrativeEventSourceRef.entityInteract(mapId, owner.id),
        );
        expect(event.sceneId, reference['sceneId']);
        expect(
          bundle.manifest.characters.any(
            (character) => character.id == costumeId,
          ),
          isTrue,
          reason:
              'The real converted scene must demand its temporary character.',
        );
        expect(
          bundle.manifest.scenes.any(
            (scene) => scene.id == reference['sceneId'],
          ),
          isTrue,
        );
        final temporary = await Directory.systemTemp.createTemp(
          'std06-appearance-save-',
        );
        final saves = ConvertedQaDiskSave('${temporary.path}/save.json');
        PlayableMapGame? mounted;
        try {
          final game = await mountConvertedQaGame(
            tester,
            projectFile,
            saves,
            GameState(
              saveId: 'std06-converted-appearance',
              currentMapId: mapId,
              playerPosition: spawn,
              playerFacing: EntityFacing.north,
            ),
          );
          mounted = game;
          OverworldActorComponent actor(String characterId) => game
              .world
              .children
              .whereType<OverworldActorComponent>()
              .singleWhere((actor) => actor.character.id == characterId);
          await _expectRenderedColor(
            actor(baseId),
            (reference['expectedBaseRgb'] as List).cast<int>(),
          );
          expect(game.debugPlayerGridPosition, spawn);
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.up),
            ),
            isTrue,
          );
          try {
            for (var tick = 0; tick < 200; tick++) {
              game.update(.025);
              await game.ready();
              await Future<void>.delayed(const Duration(milliseconds: 1));
              if (game.debugPlayerGridPosition == ownerPosition) break;
            }
          } finally {
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.release(RuntimeInputControl.up),
            );
          }
          await waitConvertedQaIdle(game);
          expect(game.debugPlayerGridPosition, ownerPosition);
          expect(game.gameStateSnapshot.playerFacing, EntityFacing.north);
          expect(
            game.overworldInteractionSnapshot.primaryAction?.request.targetId,
            owner.id,
          );
          _primary(game);
          var sawCostume = false,
              sawCostumeWhileWaiting = false,
              sawLocked = false;
          for (var tick = 0; tick < 1200; tick++) {
            game.update(.025);
            await game.ready();
            await Future<void>.delayed(const Duration(milliseconds: 1));
            final temporaryActor = game.world.children
                .whereType<OverworldActorComponent>()
                .where((actor) => actor.character.id == costumeId)
                .firstOrNull;
            if (temporaryActor != null) {
              if (!sawCostume) {
                await _expectRenderedColor(
                  temporaryActor,
                  (reference['expectedCostumeRgb'] as List).cast<int>(),
                );
              }
              sawCostume = true;
              sawLocked |= !game.inputAuthoritySnapshot.acceptsOverworldInput;
              sawCostumeWhileWaiting |=
                  !temporaryActor.isStepping &&
                  game.debugNpcGridPosition(actorId) == end;
            }
            if (game.dialoguePresentationListenable.value?.fullText.contains(
                  'Everybody arrived.',
                ) ==
                true) {
              break;
            }
          }
          expect(sawCostume, isTrue);
          expect(sawCostumeWhileWaiting, isTrue);
          expect(sawLocked, isTrue);
          expect(
            game.dialoguePresentationListenable.value?.fullText,
            contains('Everybody arrived.'),
          );
          expect(game.debugNpcGridPosition(actorId), end);
          expect(
            game.world.children.whereType<OverworldActorComponent>().any(
              (actor) => actor.character.id == costumeId,
            ),
            isFalse,
          );
          await _expectRenderedColor(
            actor(baseId),
            (reference['expectedBaseRgb'] as List).cast<int>(),
          );
          for (var tick = 0; tick < 600; tick++) {
            if (game.inputAuthoritySnapshot.acceptsOverworldInput &&
                game.dialoguePresentationListenable.value == null) {
              break;
            }
            if (game.dialoguePresentationListenable.value != null) {
              _primary(game);
            }
            game.update(.025);
            await game.ready();
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          await waitConvertedQaIdle(game);
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          expect(game.debugPendingSceneWaitCount, 0);
          expect(game.debugIsPlayerVisible, isTrue);
          expect(await game.saveGame(), isTrue);
          final saved = (await saves.load())!;
          expect(saved.currentMapId, mapId);
          expect(saved.playerPosition, ownerPosition);
          expect(
            game.debugNpcVisualFacing(actorId)?.name,
            reference['expectedFinalFacing'],
          );
        } finally {
          mounted?.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          await temporary.delete(recursive: true);
        }
      });
    },
    skip: referencePath == null,
  );
}
