import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_presentation.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:map_runtime/src/infrastructure/gen5_battle_source_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_recipe_compiler.dart';
import 'package:map_runtime/src/presentation/flame/battle_offline_grouped_turn.dart';
import 'package:map_runtime/src/presentation/flame/battle_offline_move_recipe_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_sfx_player.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_program_playback.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_verified_spl_loader.dart';
import 'package:map_runtime/src/presentation/flutter/battle_command_overlay_snapshot.dart';
import 'package:path/path.dart' as p;

enum PreviewMove {
  tackle(
    'tackle',
    'Charge',
    'https://archives.bulbagarden.net/media/upload/e/ec/Tackle_V.png',
    'normal',
    PsdkBattleMoveCategory.physical,
  ),
  waterGun(
    'water_gun',
    'Pistolet à O',
    'https://archives.bulbagarden.net/media/upload/a/a7/Water_Gun_V.png',
    'water',
    PsdkBattleMoveCategory.special,
  ),
  surf(
    'surf',
    'Surf',
    'https://archives.bulbagarden.net/media/upload/d/d4/Surf_V.png',
    'water',
    PsdkBattleMoveCategory.special,
  );

  const PreviewMove(
    this.id,
    this.label,
    this.referenceUrl,
    this.type,
    this.category,
  );
  final String id;
  final String label;
  final String referenceUrl;
  final String type;
  final PsdkBattleMoveCategory category;
}

class BattlePreviewGame extends FlameGame {
  BattlePreviewGame({
    required this.projectRoot,
    required this.move,
    required this.status,
  });
  final String projectRoot;
  final PreviewMove move;
  final ValueNotifier<String> status;
  final Completer<void> _ready = Completer<void>();
  final FlameAudioBattleSfxPlayer _sound = FlameAudioBattleSfxPlayer();
  late final RuntimePsdkBattleSessionAdapter _adapter;
  late final BattleOverlayComponent _overlay;
  final ValueNotifier<BattleCommandOverlaySnapshot?> snapshot = ValueNotifier(
    null,
  );
  bool _overlayCreated = false;
  bool _reportedParticles = false;
  String? _reportedViewport;
  bool played = false;
  bool _closed = false;
  Future<BattleGen5SourcePlaybackStatus> Function()? _startSourceAttack;
  Completer<BattleGen5SourcePlaybackStatus>? _sourceCompletion;

  @override
  Future<void> onLoad() async {
    _adapter = _makeAdapter(move);
    final session = _adapter.createLegacyDisplaySession(isTrainerBattle: false);
    final resolver = BattlePokemonSpriteResolver(
      manifest: const ProjectManifest(
        name: 'Comparateur',
        maps: [],
        tilesets: [],
      ),
      projectRootDirectory: projectRoot,
      gen5SourceLoader:
          ({
            required projectSpeciesId,
            required projectNationalDex,
            isCurrent,
          }) {
            const hashes = {
              'totodile': 'a86ee1e3ef44187cccfddca343796a540ece07134cf5bef593fb576bc6e20af6',
              'pidgey': 'd42751015572eb5faf6802ac81eebb79ee995a2e9545155a35b10a557667e946',
            };
            return loadRuntimeGen5BattleSource(
              projectSpeciesId: projectSpeciesId,
              projectNationalDex: projectNationalDex,
              expectedBindingSha256: hashes[projectSpeciesId],
              isCurrent: isCurrent,
              openAsset: (path) async {
                final file = File(p.join(projectRoot, path));
                return await file.exists() ? file.openRead() : null;
              },
            );
          },
    );
    late final BattleOverlayComponent overlay;
    overlay = BattleOverlayComponent(
      session: session,
      presentation: _adapter.presentation,
      viewportSize: size.clone(),
      spriteResolver: resolver,
      backgroundSpec: BattleBackgroundSpec.explicitImage(
        fallbackKey: BattleBackgroundKey.wildOutdoor,
        absolutePath: p.join(
          projectRoot,
          'assets/battle/backgrounds/clairiere-johto-v1.png',
        ),
      ),
      playSfx: _sound.play,
      onStartRecoverableTrackedEffect: (step, done, fail) {
        if (step.effectId == 'experimental-source-attack') {
          final start = _startSourceAttack;
          if (start == null) {
            fail();
            return () {};
          }
          try {
            final result = start();
            unawaited(
              result.then(
                (status) {
                  final completion = _sourceCompletion;
                  if (completion != null && !completion.isCompleted) {
                    completion.complete(status);
                  }
                  if (status == BattleGen5SourcePlaybackStatus.finished) {
                    done();
                  } else {
                    fail();
                  }
                },
                onError: (Object _) {
                  final completion = _sourceCompletion;
                  if (completion != null && !completion.isCompleted) {
                    completion.complete(BattleGen5SourcePlaybackStatus.failed);
                  }
                  fail();
                },
              ),
            );
            return overlay.cancelExperimentalGen5Attack;
          } catch (_) {
            final completion = _sourceCompletion;
            if (completion != null && !completion.isCompleted) {
              completion.complete(BattleGen5SourcePlaybackStatus.failed);
            }
            fail();
            return () {};
          }
        }
        debugPrint('[compare] start ${move.id} ${step.effectId}');
        return overlay.startGroupedSplEffect(
          step,
          () {
            debugPrint('[compare] completed ${move.id}');
            done();
          },
          () {
            debugPrint('[compare] failed ${move.id}');
            fail();
          },
        );
      },
      onCommandOverlaySnapshotChanged: (value) {
        if (value != null) {
          final viewport =
              '${value.viewportSize.width}x${value.viewportSize.height} '
              'panel=${value.panelRect} portraitTouch=${value.portraitTouchLayout}';
          if (_reportedViewport != viewport) {
            _reportedViewport = viewport;
            debugPrint('[compare] viewport $viewport');
          }
        }
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!_closed) snapshot.value = value;
        });
      },
      resolveSpeciesDisplayName: (species) => switch (species) {
        'totodile' => 'Kaiminus',
        'pidgey' => 'Roucool',
        'herdier' => 'Ponchien',
        'trubbish' => 'Miamiasme',
        _ => species,
      },
      onPlayerChoice: (_) {},
    );
    _overlay = overlay;
    _overlayCreated = true;
    add(overlay);
    unawaited(() async {
      try {
        await overlay.mounted;
        await overlay.waitForPendingVisualSync();
        if (_closed) return;
        status.value = 'Combat prêt · appuie sur Lancer';
        _ready.complete();
      } catch (error, stack) {
        if (!_ready.isCompleted) _ready.completeError(error, stack);
        if (!_closed) {
          status.value = 'Impossible de préparer le combat : $error';
        }
      }
    }());
  }

  void handlePresentationCommand(BattlePresentationCommand command) {
    final current = snapshot.value;
    if (_closed ||
        !_overlayCreated ||
        !_overlay.isMounted ||
        current == null ||
        !validateBattlePresentationCommand(current, command).accepted) {
      return;
    }
    if (command is BattleSetCommandPanelPlacementCommand) {
      _overlay.setCommandPanelPlacement(
        command.placement,
        controllerLayout: command.controllerLayout,
        portraitTouchLayout: command.portraitTouchLayout,
        rootCommandOrder: command.rootCommandOrder,
        collectionColumns: command.collectionColumns,
      );
      debugPrint(
        '[compare] placement ${command.placement} portraitTouch=${command.portraitTouchLayout}',
      );
    }
  }

  Future<void> play({void Function()? onStart}) async {
    if (played) return;
    played = true;
    try {
      await _ready.future;
      if (_closed) return;
      status.value = 'Chargement de ${move.label}…';
      if (move == PreviewMove.tackle || move == PreviewMove.surf) {
        await _playSourceAttack(onStart: onStart);
        return;
      }
      _overlay.beginTurnPreparation();
      _adapter.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final turn = _adapter.createLegacyDisplaySession(isTrainerBattle: false);
      final loader = BattleOfflineMoveRecipeLoader(
        projectRootDirectory: projectRoot,
      );
      final result = await loader.load(move.id, isCurrent: () => !_closed);
      if (_closed) return;
      final results = <String, BattleOfflineMoveRecipeResult>{move.id: result};
      final requests = await prepareOfflineGroupedSplTurn(
        session: turn,
        loader: loader,
        results: results,
        overlay: _overlay,
        player: _sound,
        isCurrent: () => !_closed,
      );
      debugPrint(
        '[compare] ${move.id} fallback=${result.fallbackReason} requests=${requests.length}',
      );
      if (_closed) return;
      onStart?.call();
      final applied = await _overlay.prepareTurnAudioAndUpdateState(
        turn,
        audioRequests: requests,
        presentation: _adapter.presentation,
        importedRecipes: <String, PreparedBattleMoveRecipe>{
          if (result.prepared != null) move.id: result.prepared!,
        },
        isCurrent: () => !_closed,
      );
      if (!_closed) {
        status.value = !applied
            ? 'Lecture interrompue.'
            : result.fallbackReason != null
            ? 'Recette complète indisponible · repli générique du moteur'
            : requests.isNotEmpty
            ? 'Recette BW2 v2 approximative · effets SPL groupés'
            : 'Recette BW2 v2 approximative chargée dans le moteur Avelune';
      }
    } catch (error) {
      if (!_closed) status.value = 'Impossible de lancer l’attaque : $error';
    }
  }

  Future<void> _playSourceAttack({void Function()? onStart}) async {
    final isSurf = move == PreviewMove.surf;
    final particle = isSurf ? 222 : 199;
    final indices = isSurf ? const [3, 1, 4, 5, 2] : const [0, 1];
    final particleDir = 'assets/bw2/particle$particle';
    final budget = RuntimeResourceBudget();
    final loaders = <BattleExperimentalSplLoader>[];
    final prepared = <int, BattleExperimentalSplPreparation>{};
    final active = <int>{};
    Object? failure;
    var disposed = false;
    void dispose() {
      if (disposed) return;
      disposed = true;
      for (final result in prepared.values) {
        result.component?.removeFromParent();
        result.dispose();
      }
      for (final loader in loaders) {
        loader.cancel();
      }
      active.clear();
      budget.dispose();
    }

    try {
      _overlay.beginTurnPreparation();
      final program = jsonDecode(
        await rootBundle.loadString('assets/bw2/${move.id}.json'),
      ) as Map<String, dynamic>;
      final originalDefinition = jsonDecode(
        await rootBundle.loadString('$particleDir/definition.json'),
      ) as Map<String, dynamic>;
      final hashes = isSurf ? const {
        'texture00': '93949a859e9770ad42aa1c728d157cf9d48f55b12bfad45264db1f0989575cae',
        'texture01': '1017acef39e89b4848ee5cbac3342d95100917734a2a60d5e7f312b3dd7bda22',
        'texture02': '0dbb771d83475a2d3a1ee16f6036d1c906bcb70e20e06dc933bdcfe6944763ef',
        'texture03': '627979d1de8f1963b913216ea4dfe2c76fe71993196b679c0c1c00cb4756379a',
      } : const {
        'texture00':
            '93949a859e9770ad42aa1c728d157cf9d48f55b12bfad45264db1f0989575cae',
        'texture01':
            '43f48ed0f5ac422b13287f9ec164825e184a9335dda497ffbc1a38c33f472e85',
        'texture02':
            '93ced19a99ab479e47dc9493885b064ec2f173b6b678b99b7e4c735612f5fd6e',
        'texture03':
            '1b467f4c3e2079b0997af43f43bbc7a0d4d01a983cb924e2cfcea01f7262f80a',
        'texture04':
            'ff3981a5f0a6df5dd2204a5ad560a13e82e13ea2d145324d00585f7448f55c87',
      };
      final commands = <int, Map<String, dynamic>>{
        for (final instruction in program['instructions'] as List)
          if (instruction['op'] == 'startEmitter')
            instruction['args']['emitter'] as int:
                Map<String, dynamic>.from(instruction['args'] as Map),
      };
      final textures = <String, Uint8List>{};
      for (final id in hashes.keys) {
        if (isSurf) {
          textures[id] = base64Decode((await rootBundle.loadString('$particleDir/$id.b64')).trim());
        } else {
          final data = await rootBundle.load('$particleDir/$id.png');
          textures[id] = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        }
      }
      for (final index in indices) {
        if (_closed) return;
        final args = commands[index];
        if (args == null) throw StateError('Instruction émetteur $index absente');
        final definitionJson = jsonDecode(jsonEncode(originalDefinition)) as Map<String, dynamic>;
        final appearance = ((definitionJson['emitters'] as List)[indices.indexOf(index)]
            as Map)['appearance'] as Map;
        appearance['baseScale'] = ((appearance['baseScale'] as int) *
            (args['scaleScale'] as int)) >> 12;
        final definition = isSurf
            ? BattleSplParticleDefinition.fromExperimentalJson(definitionJson)
            : BattleSplParticleDefinition.fromJson(definitionJson);
        final loader = BattleExperimentalSplLoader(resourceBudget: budget);
        loaders.add(loader);
        final projection = _overlay.experimentalGen5Projection(
          attacker: args['from'] == 'EFFVM_EMIT_ATTACKER',
          towardOpponent: args['to'] != 8,
          matchBattleSpacing: isSurf,
          anchorAtFoot: isSurf,
        );
        final pixelsPerUnit = isSurf
            ? projection.worldTransform!.worldUnitsPerUnit /
                projection.capture()!.single.unit
            : 25.0;
        final result = await loader.create(
          definition: definition,
          sourceEmitterIndices: indices,
          textureBytes: {
            for (final id in definition.textureIds) id: textures[id]!,
          },
          textureSha256: {
            for (final id in definition.textureIds) id: hashes[id]!,
          },
          emitters: [
            BattleSplStaticEmitter(
              emitterIndex: index,
              startTick: 0,
              position: (x: 0, y: args['offsetY'] as int, z: 0),
            ),
          ],
          seed: 0,
          poolCapacity: isSurf ? 256 : 128,
          maxTicks: isSurf ? 300 : 180,
          origin: Offset.zero,
          pixelsPerUnit: pixelsPerUnit,
          projection: projection,
          onComplete: () => active.remove(index),
          onFailure: (reason) {
            failure = reason;
            debugPrint('[compare] emitter $index failed: $reason');
            active.remove(index);
          },
          isCurrent: () => !_closed && !disposed,
        );
        if (result.component == null) {
          throw StateError('Émetteur $index indisponible : ${result.failure}');
        }
        result.component!.priority = isSurf && (index == 1 || index == 2)
            ? 13
            : 12;
        result.component!.clipBounds = () =>
            Rect.fromLTWH(0, 0, _overlay.size.x, _overlay.size.y);
        prepared[index] = result;
      }
      if (_closed) return;
      final completion = Completer<BattleGen5SourcePlaybackStatus>();
      _sourceCompletion = completion;
      _startSourceAttack = () {
        onStart?.call();
        if (isSurf) {
          _sound.playProjectFile(p.join(projectRoot,
            'data/pokemon/battle_recipes/blobs/0199311728be829918c18b5f1486d315ba690ed58b69b4c8236a16416130bcd2/2d1a632346536649a0f9aa36226c43ff7a1d97527bc001b4688ce9ac7b20114c.mp3'));
        }
        status.value = isSurf
            ? 'Surf · programme BW2 expérimental · son approximatif'
            : 'Charge · programme BW2 expérimental · sans son source';
        return _overlay.presentExperimentalGen5Attack(
          program: program,
          variant: isSurf ? 'Surf' : 'Tackle',
          hasEmitter: (id, emitter) =>
              id == particle && prepared.containsKey(emitter),
          startEmitter: (_, _, _) {},
          startSourceEmitter: (args) {
            final emitter = args['emitter'] as int;
            if (jsonEncode(args) != jsonEncode(commands[emitter]) ||
                !active.add(emitter)) {
              throw StateError('Invocation de particules invalide');
            }
            _overlay.add(prepared[emitter]!.component!);
          },
          particlesBusy: () {
            if (failure != null) {
              throw StateError('Effet BW2 interrompu : $failure');
            }
            return active.isNotEmpty;
          },
          detachParticles: dispose,
          allowSilentAudio: true,
          allowUnmappedAudioControls: isSurf,
          adaptSourceCamera: isSurf,
          duringTrackedEffect: true,
        );
      };
      _adapter.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final turn = _adapter.createLegacyDisplaySession(isTrainerBattle: false);
      final event = turn.state.currentTurn!.timeline
          .whereType<BattleTurnExecutionEvent>()
          .firstWhere(
            (event) => event.execution.attackerSide == BattleSideId.player,
          );
      _overlay.updateState(
        turn,
        presentation: _adapter.presentation,
        experimentalSourceEffects: {event: 'experimental-source-attack'},
      );
      final result = await completion.future;
      if (!_closed) {
        status.value = result == BattleGen5SourcePlaybackStatus.finished
            ? '${move.label} terminée · programme BW2 expérimental · ${isSurf ? 'son approximatif' : 'sans son source'}'
            : '${move.label} interrompue : ${result.name}';
      }
    } finally {
      _startSourceAttack = null;
      _sourceCompletion = null;
      dispose();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_overlayCreated && !_reportedParticles) {
      for (final effect
          in _overlay.children.whereType<BattleSplStaticComponent>()) {
        if (effect.playback.activeParticles > 0) {
          _reportedParticles = true;
          debugPrint(
            '[compare] visible-particles ${move.id} count=${effect.playback.activeParticles} tick=${effect.playback.tick}',
          );
        }
      }
    }
  }

  @override
  void onRemove() {
    _closed = true;
    final completion = _sourceCompletion;
    if (completion != null && !completion.isCompleted) {
      completion.complete(BattleGen5SourcePlaybackStatus.cancelled);
    }
    unawaited(_sound.dispose());
    super.onRemove();
  }
}

RuntimePsdkBattleSessionAdapter _makeAdapter(PreviewMove move) {
  final referencePair = move == PreviewMove.surf;
  final playerSpecies = referencePair ? 'herdier' : 'totodile';
  final enemySpecies = referencePair ? 'trubbish' : 'pidgey';
  PsdkBattleMoveData attack(PreviewMove move, int power) => PsdkBattleMoveData(
    id: move.id,
    dbSymbol: move.id,
    name: move.label,
    type: move.type,
    category: move.category,
    power: power,
    accuracy: 100,
    pp: 20,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
  PsdkBattleCombatantSetup pokemon(
    String id,
    String species,
    String name,
    PsdkBattleMoveData attack,
    int speed,
    {int level = 25, int maxHp = 500, PsdkBattleGender gender = PsdkBattleGender.male}
  ) => PsdkBattleCombatantSetup(
    id: id,
    speciesId: species,
    displayName: name,
    level: level,
    maxHp: maxHp,
    currentHp: maxHp,
    types: PsdkBattleTypes(primary: species == 'totodile' ? 'water' : species == 'trubbish' ? 'poison' : 'normal'),
    gender: gender,
    stats: PsdkBattleStats(
      attack: 40,
      defense: 100,
      specialAttack: 50,
      specialDefense: 100,
      speed: speed,
    ),
    moves: [attack],
  );
  final setup = PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: pokemon('player', playerSpecies, referencePair ? 'Ponchien' : 'Kaiminus',
      attack(move, 40), 100, level: referencePair ? 20 : 25, maxHp: referencePair ? 57 : 500),
    opponent: pokemon(
      'enemy',
      enemySpecies,
      referencePair ? 'Miamiasme' : 'Roucool',
      attack(PreviewMove.tackle, 1),
      10,
      level: referencePair ? 19 : 25,
      gender: referencePair ? PsdkBattleGender.female : PsdkBattleGender.male,
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 1,
      generic: 1,
    ),
  );
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    setup,
    visualIdentitiesByBank: {
      0: [
        RuntimeBattleVisualIdentity(
          speciesId: playerSpecies,
          formId: 'base',
          genderId: 'male',
          isShiny: false,
        ),
      ],
      1: [
        RuntimeBattleVisualIdentity(
          speciesId: enemySpecies,
          formId: 'base',
          genderId: referencePair ? 'female' : 'male',
          isShiny: false,
        ),
      ],
    },
  );
}
