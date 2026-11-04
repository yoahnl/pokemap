import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui show Image, instantiateImageCodec;

import 'package:flame/components.dart';
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
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_sfx_player.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_emitter.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_program_playback.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_emitter_motion.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_camera_projection.dart';
import 'workshop_reference_pokemon.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_verified_spl_loader.dart';
import 'package:map_runtime/src/presentation/flutter/battle_command_overlay_snapshot.dart';
import 'package:path/path.dart' as p;

import 'workshop_move_audio.dart';

class PreviewMove {
  const PreviewMove(
    this.id,
    this.label,
    this.referenceUrl,
    this.type,
    this.category, {
    this.particle,
    this.bundleAsset,
    this.approximations = const [],
    this.sourceVariant,
    this.unavailableReason,
  });

  static const tackle = PreviewMove(
    'tackle',
    'Charge',
    'https://archives.bulbagarden.net/media/upload/e/ec/Tackle_V.png',
    'normal',
    PsdkBattleMoveCategory.physical,
  );
  static const waterGun = PreviewMove(
    'water_gun',
    'Pistolet à O',
    'https://archives.bulbagarden.net/media/upload/a/a7/Water_Gun_V.png',
    'water',
    PsdkBattleMoveCategory.special,
  );
  static const acid = PreviewMove(
    'acid',
    'Acide',
    'https://archives.bulbagarden.net/media/upload/2/2d/Acid_V.png',
    'poison',
    PsdkBattleMoveCategory.special,
  );
  static const flamethrower = PreviewMove(
    'flamethrower',
    'Lance-Flammes',
    'https://archives.bulbagarden.net/media/upload/c/c9/Flamethrower_V.png',
    'fire',
    PsdkBattleMoveCategory.special,
  );
  static const surf = PreviewMove(
    'surf',
    'Surf',
    'https://archives.bulbagarden.net/media/upload/d/d4/Surf_V.png',
    'water',
    PsdkBattleMoveCategory.special,
  );
  static const quickAttack = PreviewMove(
    'quick_attack',
    'Vive-Attaque',
    'https://archives.bulbagarden.net/media/upload/e/ec/Quick_Attack_V.png',
    'normal',
    PsdkBattleMoveCategory.physical,
    particle: 270,
    approximations: ['projection orthographique expérimentale'],
  );
  static const hydroPump = PreviewMove(
    'hydro_pump',
    'Hydrocanon',
    'https://archives.bulbagarden.net/media/upload/7/75/Hydro_Pump_V.png',
    'water',
    PsdkBattleMoveCategory.special,
    particle: 221,
    bundleAsset: 'assets/bw2/batch/hydro-pump.json',
    approximations: ['transition de décor approximative'],
  );
  static const fireBlast = PreviewMove(
    'fire_blast',
    'Déflagration',
    'https://archives.bulbagarden.net/media/upload/e/e4/Fire_Blast_BW.png',
    'fire',
    PsdkBattleMoveCategory.special,
    particle: 295,
    bundleAsset: 'assets/bw2/batch/fire-blast.json',
    approximations: [
      'background-palette-animation:timing-experimental',
      'background-palette-fade:layer-approximation',
      'particle-field:polygonReferencePlane',
      'particle-field:polygonRotAxis',
      'particle-spin:trigonometry-experimental',
    ],
  );
  static const fly = PreviewMove(
    'fly',
    'Vol',
    'https://archives.bulbagarden.net/media/upload/7/7f/Fly_V.png',
    'flying',
    PsdkBattleMoveCategory.physical,
    particle: 184,
    bundleAsset: 'assets/bw2/batch/fly.json',
    approximations: [
      'actor-visibility:shadow-hidden',
      'camera:relative-adapted-to-workshop',
      'source-variant:first-only',
    ],
  );
  static const shadowBall = PreviewMove(
    'shadow_ball',
    'Ball’Ombre',
    'https://archives.bulbagarden.net/media/upload/2/22/Shadow_Ball_V.png',
    'ghost',
    PsdkBattleMoveCategory.special,
    particle: 418,
    bundleAsset: 'assets/bw2/batch/shadow-ball.json',
    approximations: [
      'camera:relative-adapted-to-workshop',
      'particle-field:lifeTimeVariance',
      'particle-spin:trigonometry-experimental',
      'source-emitter:field-coordinate-calibration',
      'source-emitter:field-motion-calibration',
    ],
  );
  static const psychic = PreviewMove(
    'psychic',
    'Psyko',
    'https://archives.bulbagarden.net/media/upload/f/fc/Psychic_BW.png',
    'psychic',
    PsdkBattleMoveCategory.special,
    bundleAsset: 'assets/bw2/batch/psychic.json',
    approximations: [
      'background-palette-fade:layer-approximation',
      'background-wave:trigonometry-experimental',
      'scene-palette-fade:layer-approximation',
    ],
  );
  static const thief = PreviewMove(
    'thief',
    'Larcin',
    'https://archives.bulbagarden.net/media/upload/4/43/Thief_V.png',
    'dark',
    PsdkBattleMoveCategory.physical,
    particle: 338,
    bundleAsset: 'assets/bw2/batch/thief.json',
    approximations: [
      'particle-field:lifeTimeVariance',
      'source-variant:first-only',
    ],
  );
  static const charm = PreviewMove(
    'charm',
    'Charme',
    'https://archives.bulbagarden.net/media/upload/9/93/Charm_V.png',
    'normal',
    PsdkBattleMoveCategory.status,
    particle: 374,
    bundleAsset: 'assets/bw2/batch/charm.json',
    approximations: ['particle-spin:trigonometry-experimental'],
  );
  static const roar = PreviewMove(
    'roar',
    'Hurlement',
    'https://archives.bulbagarden.net/media/upload/d/dc/Roar_V.png',
    'normal',
    PsdkBattleMoveCategory.status,
    particle: 211,
    bundleAsset: 'assets/bw2/batch/roar.json',
    approximations: [
      'actor-position:screen-space-approximation',
      'source-audio:cry-and-timing-unavailable',
      'source-gauge:preview-restored',
    ],
  );
  static const mirrorMove = PreviewMove(
    'mirror-move',
    'Mimique',
    'https://archives.bulbagarden.net/media/upload/a/ad/Mirror_Move_V.png',
    'flying',
    PsdkBattleMoveCategory.status,
    particle: 192,
    bundleAsset: 'assets/bw2/batch/jump-kick.json',
    approximations: ['source-context:copied-jump-kick'],
  );
  static const naturePower = PreviewMove(
    'nature-power',
    'Force Nature',
    'https://archives.bulbagarden.net/media/upload/b/bc/Nature_Power_V.png',
    'normal',
    PsdkBattleMoveCategory.status,
    particle: 325,
    bundleAsset: 'assets/bw2/batch/rock-slide.json',
    approximations: [
      'particle-axis:source-basis-experimental',
      'source-context:cave-rock-slide',
    ],
  );
  static const transform = PreviewMove(
    'transform',
    'Morphing',
    'https://archives.bulbagarden.net/media/upload/7/78/Transform_V.png',
    'normal',
    PsdkBattleMoveCategory.status,
    approximations: [
      'source-effect:prelude-unavailable',
      'rendering:software-during-mosaic',
    ],
  );
  static const allySwitch = PreviewMove(
    'ally-switch',
    'Interversion',
    'https://archives.bulbagarden.net/media/upload/1/1f/Ally_Switch_V.png',
    'psychic',
    PsdkBattleMoveCategory.status,
    bundleAsset: 'assets/bw2/batch/ally-switch.json',
    approximations: [
      'actor-position:screen-space-approximation',
      'source-audio:unavailable',
      'preview:simulated-position-swap',
    ],
  );

  static const values = [
    tackle,
    waterGun,
    acid,
    flamethrower,
    surf,
    quickAttack,
    hydroPump,
    fireBlast,
    fly,
    shadowBall,
    psychic,
    thief,
    charm,
    roar,
    mirrorMove,
    naturePower,
    transform,
    allySwitch,
  ];
  final String id;
  final String label;
  final String? referenceUrl;
  final String type;
  final PsdkBattleMoveCategory category;
  final int? particle;
  final String? bundleAsset;
  final String? sourceVariant;
  final List<String> approximations;
  final String? unavailableReason;
}

class BattlePreviewGame extends FlameGame {
  BattlePreviewGame({
    required this.projectRoot,
    required this.move,
    required this.status,
    this.referencePokemon,
    Future<Uint8List?> Function(String)? loadMoveAudio,
    FlameAudioBattleSfxPlayer? soundPlayer,
  }) : _loadMoveAudio = loadMoveAudio ??
           ((id) => WorkshopMoveAudio().load(id, sourceVariant: move.sourceVariant)),
       _sound = soundPlayer ?? FlameAudioBattleSfxPlayer();
  final String projectRoot;
  final PreviewMove move;
  final ValueNotifier<String> status;
  final PreparedReferencePair? referencePokemon;
  final Future<Uint8List?> Function(String) _loadMoveAudio;
  final Completer<void> _ready = Completer<void>();
  final FlameAudioBattleSfxPlayer _sound;
  late final RuntimePsdkBattleSessionAdapter _adapter;
  late final BattlePokemonSpriteResolver _spriteResolver;
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
  BattleSceneCombatantComponent? _transformActor;
  BattleCombatantSpriteSpec? _transformSprite;
  String? _transformLabel;
  Object? _transformOwner;
  Completer<void>? _transformCompletion;
  int _transformTick = 0;
  double _transformElapsed = 0;
  bool _transformLoading = false;

  @override
  Future<void> onLoad() async {
    _adapter = _makeAdapter(move, referencePokemon: referencePokemon);
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
    _spriteResolver = resolver;
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
                onError: (Object error) {
                  debugPrint('[compare] source attack failed: $error');
                  final completion = _sourceCompletion;
                  if (completion != null && !completion.isCompleted) {
                    completion.complete(BattleGen5SourcePlaybackStatus.failed);
                  }
                  fail();
                },
              ),
            );
            return overlay.cancelExperimentalGen5Attack;
          } catch (error) {
            debugPrint('[compare] source attack could not start: $error');
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
      resolveSpeciesDisplayName: (species) {
        final pair = referencePokemon;
        if (pair?.attacker.id == species) return pair!.attacker.name;
        if (pair?.target.id == species) return pair!.target.name;
        return switch (species) {
          'totodile' => 'Kaiminus',
          'pidgey' => 'Roucool',
          'herdier' => 'Ponchien',
          'trubbish' => 'Miamiasme',
          _ => species,
        };
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
        status.value = move.unavailableReason == null
            ? 'Combat prêt · appuie sur Lancer'
            : '${move.label} : aperçu Avelune à construire';
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

  Future<bool> _waitForStart(FutureOr<bool> Function()? onStart) async {
    final allowed = onStart == null ? true : await onStart();
    return allowed && !_closed;
  }

  Future<void> play({FutureOr<bool> Function()? onStart}) async {
    if (played) return;
    played = true;
    try {
      await _ready.future;
      if (_closed) return;
      status.value = 'Chargement de ${move.label}…';
      if (move == PreviewMove.transform) {
        await _playTransform(onStart: onStart);
        return;
      }
      if (move == PreviewMove.allySwitch) {
        await _playAllySwitch(onStart: onStart);
        return;
      }
      if (move == PreviewMove.tackle ||
          move == PreviewMove.surf ||
          move == PreviewMove.waterGun ||
          move == PreviewMove.acid ||
          move == PreviewMove.flamethrower ||
          move == PreviewMove.quickAttack ||
          move.bundleAsset != null) {
        await _playSourceAttack(onStart: onStart);
        return;
      }
      _overlay.beginTurnPreparation();
      _adapter.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final turn = _attackPreviewSession();
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
      if (!await _waitForStart(onStart)) return;
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

  Future<void> _playAllySwitch({FutureOr<bool> Function()? onStart}) async {
    final bundle = jsonDecode(await rootBundle.loadString(move.bundleAsset!)) as Map;
    if (_closed) return;
    final program = Map<String, dynamic>.from(bundle['program'] as Map);
    if (!await _waitForStart(onStart)) return;
    status.value = 'Interversion · programme BW2 expérimental · sans son source';
    final result = await _overlay.presentExperimentalGen5Attack(
      program: program,
      variant: program['variant'] as String,
      hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {},
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
      allowSourceVisibility: true,
      adaptSourceCamera: true,
    );
    if (_closed) return;
    if (result != BattleGen5SourcePlaybackStatus.finished) {
      status.value = 'Interversion interrompue : ${result.name}';
      return;
    }
    final swapped = _makeAdapter(move, allySwapped: true);
    _overlay.updateState(
      swapped.createLegacyDisplaySession(isTrainerBattle: false),
      presentation: swapped.presentation,
    );
    await _overlay.waitForPendingVisualSync();
    if (!_closed) {
      status.value = 'Interversion terminée · échange simulé · sans son source';
    }
  }

  Future<void> _playTransform({FutureOr<bool> Function()? onStart}) async {
    final target = _adapter.presentation.combatantAt(
      const BattleSlotRef.active(BattleSideId.enemy),
    );
    if (target == null) throw StateError('Cible indisponible');
    final identity = target.currentVisualIdentity;
    final species = identity?.speciesId ?? target.combatant.speciesId;
    final sprite = await _spriteResolver.resolve(
      speciesId: species,
      isPlayerSide: true,
      visualIdentity: identity,
    );
    if (_closed) return;
    if (sprite.gen5Source == null &&
        sprite.explicitAnimatedImageAbsolutePath == null &&
        sprite.explicitImageAbsolutePath == null) {
      throw StateError('Sprite de la cible indisponible');
    }
    if (!await _waitForStart(onStart)) return;
    final actor = _overlay.children
        .whereType<BattleSceneCombatantComponent>()
        .singleWhere((value) => value.isPlayerSide);
    final owner = Object();
    _transformActor = actor;
    _transformSprite = sprite;
    _transformLabel = species;
    _transformOwner = owner;
    _transformTick = 0;
    _transformElapsed = 0;
    _transformLoading = false;
    final completion = Completer<void>();
    _transformCompletion = completion;
    try {
      actor.setBattleScriptAlpha(16, owner: owner);
      actor.setBattleScriptMosaic(0, owner: owner);
      actor.pauseBattleSpriteAnimation(owner: owner);
      await completion.future;
      if (!_closed) {
        status.value = 'Morphing terminée · mosaïque expérimentale · sans son source';
      }
    } catch (_) {
      _finishTransform();
      rethrow;
    }
  }

  void _advanceTransform(double dt) {
    final actor = _transformActor;
    final owner = _transformOwner;
    if (actor == null || owner == null || _transformLoading ||
        !dt.isFinite || dt <= 0) {
      return;
    }
    _transformElapsed += dt;
    const frame = 1 / 60;
    while (_transformElapsed >= frame && _transformActor != null) {
      _transformElapsed -= frame;
      _transformTick++;
      actor.setBattleScriptMosaic(
        _transformTick <= 8 ? _transformTick : 16 - _transformTick,
        owner: owner,
      );
      if (_transformTick == 8) {
        _transformLoading = true;
        unawaited(_swapTransformSprite(actor));
        return;
      }
      if (_transformTick == 16) {
        _finishTransform();
        return;
      }
    }
  }

  Future<void> _swapTransformSprite(BattleSceneCombatantComponent actor) async {
    try {
      await actor.sync(speciesLabel: _transformLabel!, spriteSpec: _transformSprite!);
      if (_closed || !identical(actor, _transformActor)) return;
      if (!actor.hasBattleSpriteImage) {
        throw StateError('Impossible de charger le sprite de la cible');
      }
      _transformLoading = false;
    } catch (error, stack) {
      if (!_closed && identical(actor, _transformActor)) {
        _finishTransform(error: error, stack: stack);
      }
    }
  }

  void _finishTransform({Object? error, StackTrace? stack}) {
    final actor = _transformActor;
    final owner = _transformOwner;
    if (actor != null && owner != null) {
      actor.clearBattleScriptMosaic(owner: owner);
      actor.clearBattleScriptAlpha(owner: owner);
      actor.resumeBattleSpriteAnimation(owner: owner);
    }
    _transformActor = null;
    _transformSprite = null;
    _transformLabel = null;
    _transformOwner = null;
    _transformLoading = false;
    final completion = _transformCompletion;
    _transformCompletion = null;
    if (completion != null && !completion.isCompleted) {
      if (error == null) {
        completion.complete();
      } else {
        completion.completeError(error, stack);
      }
    }
  }

  Future<void> _playSourceAttack({FutureOr<bool> Function()? onStart}) async {
    final isSurf = move == PreviewMove.surf;
    final isWaterGun = move == PreviewMove.waterGun;
    final isAcid = move == PreviewMove.acid;
    final isFlamethrower = move == PreviewMove.flamethrower;
    final isQuickAttack = move == PreviewMove.quickAttack;
    final isBatch = move.bundleAsset != null;
    final isMovingExample = isWaterGun || isAcid || isFlamethrower ||
        isQuickAttack || isBatch;
    final particle = isSurf
        ? 222
        : isWaterGun
        ? 220
        : isAcid
        ? 216
        : isFlamethrower
        ? 218
        : move.particle ?? 199;
    final particleDir = 'assets/bw2/particle$particle';
    final budget = RuntimeResourceBudget();
    final loaders = <BattleExperimentalSplLoader>[];
    final prepared =
        <
          ({Map<String, dynamic> args, BattleExperimentalSplPreparation result,
            BattleSplCameraProjection? screenAnchor})
        >[];
    final active = <BattleSplStaticComponent>{};
    final backgrounds = <int, ui.Image>{};
    final backgroundFrames = <ui.Image>[];
    final backgroundAnimations =
        <int, ({int background, List<ui.Image> frames, List<int> durations})>{};
    Object? failure;
    var disposed = false;
    BattleRecipeSoundPreparation? soundPreparation;
    var soundRequested = false;
    var soundStarted = false;
    Future<BattlePreparedRecipeSound?> prepareSound() async {
      try {
        final bytes = await _loadMoveAudio(move.id);
        if (bytes == null || _closed || disposed) return null;
        final preparation = _sound.beginRecipeSound(bytes, 'audio/mpeg');
        soundPreparation = preparation;
        final sound = await preparation.ready;
        if (_closed || disposed) {
          await sound.dispose();
          return null;
        }
        return sound;
      } on Object catch (error) {
        debugPrint('[compare] move audio unavailable: $error');
        return null;
      }
    }
    final preparedSound = isSurf
        ? Future<BattlePreparedRecipeSound?>.value()
        : prepareSound();
    void playPreparedSound(Map<String, dynamic> _) {
      if (soundRequested) return;
      soundRequested = true;
      unawaited(preparedSound.then((sound) async {
        if (sound == null || _closed || disposed) return;
        try {
          await sound.start();
          soundStarted = true;
        } on Object catch (error) {
          debugPrint('[compare] move audio failed: $error');
        }
      }));
    }
    void dispose() {
      if (disposed) return;
      disposed = true;
      final pendingSound = soundPreparation;
      if (pendingSound != null) unawaited(pendingSound.cancel());
      for (final entry in prepared) {
        entry.result.component?.removeFromParent();
        entry.result.dispose();
      }
      for (final loader in loaders) {
        loader.cancel();
      }
      active.clear();
      for (final image in backgrounds.values) {
        image.dispose();
      }
      backgrounds.clear();
      for (final image in backgroundFrames) {
        image.dispose();
      }
      backgroundFrames.clear();
      backgroundAnimations.clear();
      budget.dispose();
    }

    try {
      _overlay.beginTurnPreparation();
      final batch = isBatch
          ? jsonDecode(await rootBundle.loadString(move.bundleAsset!))
                as Map<String, dynamic>
          : null;
      final program = batch == null
          ? jsonDecode(
              await rootBundle.loadString('assets/bw2/${move.id}.json'),
            ) as Map<String, dynamic>
          : batch['program'] as Map<String, dynamic>;
      final backgroundData = batch?['backgrounds'] as Map? ?? const {};
      for (final entry in backgroundData.entries) {
        final id = int.parse(entry.key as String);
        final codec = await ui.instantiateImageCodec(base64Decode(entry.value as String));
        try {
          backgrounds[id] = (await codec.getNextFrame()).image;
        } finally {
          codec.dispose();
        }
      }
      final animationData = batch?['backgroundAnimations'] as Map? ?? const {};
      for (final entry in animationData.entries) {
        final animation = entry.value as Map;
        final frames = <ui.Image>[];
        for (final encoded in animation['frames'] as List) {
          final codec = await ui.instantiateImageCodec(base64Decode(encoded as String));
          try {
            final frame = (await codec.getNextFrame()).image;
            frames.add(frame);
            backgroundFrames.add(frame);
          } finally {
            codec.dispose();
          }
        }
        backgroundAnimations[int.parse(entry.key as String)] = (
          background: animation['background'] as int,
          frames: frames,
          durations: (animation['durations'] as List).cast<int>(),
        );
      }
      final originalDefinition = batch == null
          ? jsonDecode(
              await rootBundle.loadString('$particleDir/definition.json'),
            ) as Map<String, dynamic>
          : batch['definition'] as Map<String, dynamic>?;
      final manifest = isMovingExample && !isBatch
          ? jsonDecode(
              await rootBundle.loadString('$particleDir/manifest.json'),
            ) as Map<String, dynamic>
          : null;
      final indices = batch != null
          ? (batch['sourceEmitterIndices'] as List? ?? const []).cast<int>()
          : manifest == null
          ? (isSurf ? const [3, 1, 4, 5, 2] : const [0, 1])
          : (manifest['sourceEmitterIndices'] as List).cast<int>();
      final hashes = batch != null
          ? (batch['textureSha256'] as Map? ?? const {}).cast<String, String>()
          : manifest != null
          ? <String, String>{
              for (final texture in manifest['textures'] as List)
                texture['name'] as String: texture['sha256'] as String,
            }
          : isSurf
          ? const {
              'texture00': '93949a859e9770ad42aa1c728d157cf9d48f55b12bfad45264db1f0989575cae',
              'texture01': '1017acef39e89b4848ee5cbac3342d95100917734a2a60d5e7f312b3dd7bda22',
              'texture02': '0dbb771d83475a2d3a1ee16f6036d1c906bcb70e20e06dc933bdcfe6944763ef',
              'texture03': '627979d1de8f1963b913216ea4dfe2c76fe71993196b679c0c1c00cb4756379a',
            }
          : const {
              'texture00': '93949a859e9770ad42aa1c728d157cf9d48f55b12bfad45264db1f0989575cae',
              'texture01': '43f48ed0f5ac422b13287f9ec164825e184a9335dda497ffbc1a38c33f472e85',
              'texture02': '93ced19a99ab479e47dc9493885b064ec2f173b6b678b99b7e4c735612f5fd6e',
              'texture03': '1b467f4c3e2079b0997af43f43bbc7a0d4d01a983cb924e2cfcea01f7262f80a',
              'texture04': 'ff3981a5f0a6df5dd2204a5ad560a13e82e13ea2d145324d00585f7448f55c87',
            };
      final commands = <({Map<String, dynamic> args, bool orthographic, bool orbit})>[];
      final instructions = program['instructions'] as List;
      for (
        var index = program['entryIndex'] as int;
        index < instructions.length;
        index++
      ) {
        final instruction = instructions[index] as Map;
        if (instruction['op'] == 'end') break;
        if (instruction['op'] == 'startEmitter' ||
            instruction['op'] == 'startFieldEmitter' ||
            instruction['op'] == 'startOrthoEmitter' ||
            instruction['op'] == 'startMovingEmitter' ||
            instruction['op'] == 'startMovingOrthoEmitter' ||
            instruction['op'] == 'startMovingFieldEmitter' ||
            instruction['op'] == 'startOrbitEmitter') {
          commands.add((
            args: Map<String, dynamic>.from(instruction['args'] as Map),
            orthographic: instruction['op'] == 'startOrthoEmitter' ||
                instruction['op'] == 'startMovingOrthoEmitter',
            orbit: instruction['op'] == 'startOrbitEmitter',
          ));
        }
      }
      final textures = <String, Uint8List>{};
      for (final id in hashes.keys) {
        if (batch != null) {
          textures[id] = base64Decode((batch['textures'] as Map)[id] as String);
        } else if (isSurf || isMovingExample) {
          textures[id] = base64Decode(
            (await rootBundle.loadString('$particleDir/$id.b64')).trim(),
          );
        } else {
          final data = await rootBundle.load('$particleDir/$id.png');
          textures[id] = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
        }
      }
      final groupDefinitions = <int, Map<String, dynamic>>{};
      final groupIndices = <int, List<int>>{};
      final groupHashes = <int, Map<String, String>>{};
      final groupTextures = <int, Map<String, Uint8List>>{};
      for (final entry in (batch?['particleGroups'] as Map? ?? const {}).entries) {
        final id = int.parse(entry.key as String);
        final group = entry.value as Map;
        groupDefinitions[id] = (group['definition'] as Map).cast<String, dynamic>();
        groupIndices[id] = (group['sourceEmitterIndices'] as List).cast<int>();
        groupHashes[id] = (group['textureSha256'] as Map).cast<String, String>();
        groupTextures[id] = {
          for (final texture in (group['textures'] as Map).entries)
            texture.key as String: base64Decode(texture.value as String),
        };
      }
      for (final command in commands) {
        if (_closed) return;
        final args = command.args;
        final index = args['emitter'] as int;
        final particleId = args['particle'] as int;
        if (groupDefinitions.isNotEmpty && !groupDefinitions.containsKey(particleId)) {
          throw StateError('Groupe de particules $particleId indisponible');
        }
        final selectedIndices = groupIndices[particleId] ?? indices;
        final selectedHashes = groupHashes[particleId] ?? hashes;
        final selectedTextures = groupTextures[particleId] ?? textures;
        final definitionJson =
            jsonDecode(jsonEncode(groupDefinitions[particleId] ?? originalDefinition))
                as Map<String, dynamic>;
        final emitter = (definitionJson['emitters'] as List)[selectedIndices.indexOf(index)] as Map;
        final movingOrthographic = command.orthographic && args.containsKey('motion');
        final fieldPositioned = args.containsKey('fromX');
        final towardOpponent = !command.orbit && !fieldPositioned &&
            args['from'] != 8 && args['to'] != 8 && args['to'] != args['from'] &&
            !(args['from'] == 0 && args['to'] == 'EFFVM_EMIT_ATTACKER');
        applyGen5SourceEmitterParameters(
          emitter,
          movingOrthographic ? {...args, 'radiusScale': 3072, 'scaleScale': 3072} : args,
          orthographic: command.orthographic && !movingOrthographic,
          aimAtOpponent: towardOpponent && !command.orthographic,
        );
        final definition = {5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19}.contains(definitionJson['schemaVersion'])
            ? BattleSplParticleDefinition.fromExperimentalJson(definitionJson)
            : BattleSplParticleDefinition.fromJson(definitionJson);
        final loader = BattleExperimentalSplLoader(resourceBudget: budget);
        loaders.add(loader);
        final orbitEnemy = command.orbit && (args['type'] as int) >= 2;
        final projection = fieldPositioned
            ? _overlay.experimentalGen5FieldProjection()
            : _overlay.experimentalGen5Projection(
          attacker: command.orbit ? !orbitEnemy :
              args['from'] == 0 || args['from'] == 'EFFVM_EMIT_ATTACKER',
          towardOpponent: towardOpponent,
          matchBattleSpacing: isSurf || isMovingExample,
          anchorAtFoot: isSurf || isMovingExample,
        );
        final pixelsPerUnit = command.orthographic
            ? math.min(projection.camera.viewport.width / 8,
                projection.camera.viewport.height / 6)
            : isSurf || isMovingExample
            ? projection.worldTransform!.worldUnitsPerUnit /
                  projection.capture()!.single.unit
            : 25.0;
        late final BattleExperimentalSplPreparation result;
        result = await loader.create(
          definition: definition,
          sourceEmitterIndices: selectedIndices,
          textureBytes: {
            for (final id in definition.textureIds) id: selectedTextures[id]!,
          },
          textureSha256: {
            for (final id in definition.textureIds) id: selectedHashes[id]!,
          },
          emitters: [
            BattleSplStaticEmitter(
              emitterIndex: index,
              startTick: 0,
              position: fieldPositioned
                  ? gen5SourceFieldEmitterOffset(args)
                  : (x: 0, y: command.orthographic ? 0 : args['offsetY'] as int, z: 0),
            ),
          ],
          seed: 0,
          poolCapacity: isSurf || isBatch ? 256 : 128,
          maxTicks: isSurf || isBatch ? 300 : 180,
          origin: Offset.zero,
          pixelsPerUnit: pixelsPerUnit,
          projection: command.orthographic ? null : projection,
          onComplete: () => active.remove(result.component),
          onFailure: (reason) {
            failure = reason;
            debugPrint('[compare] emitter $index failed: $reason');
            active.remove(result.component);
          },
          isCurrent: () => !_closed && !disposed,
        );
        if (result.component == null) {
          throw StateError('Émetteur $index indisponible : ${result.failure}');
        }
        result.component!.clipOutOfViewParticles = true;
        result.component!.priority = isSurf && (index == 1 || index == 2)
            ? 13
            : 12;
        result.component!.clipBounds = () => Rect.fromLTWH(
          command.orthographic ? -result.component!.position.x : 0,
          command.orthographic ? -result.component!.position.y : 0,
          _overlay.size.x,
          _overlay.size.y,
        );
        if (command.orbit) {
          final motion = BattleGen5OrbitEmitterMotion(
            radiusX: args['radiusX'] as int,
            radiusZ: args['radiusZ'] as int,
            offsetY: args['offsetY'] as int,
            frames: args['frames'] as int,
            wait: args['wait'] as int,
            delay: args['delay'] as int,
            reverse: (args['type'] as int).isOdd,
            enemySide: orbitEnemy,
          );
          result.component!.advanceEmitterPosition = motion.advance;
        } else if (args.containsKey('motion')) {
          final endpoints = fieldPositioned
              ? gen5SourceFieldMotionEndpoints(args)
              : (from: (x: 0, y: 0, z: 0), to: (x: 0, y: 0, z: 17 * 4096));
          final motion = BattleGen5EmitterMotion(
            from: endpoints.from,
            to: endpoints.to,
            motionType: args['motion'] as int,
            motionFramesFx32: args['motionFramesFx32'] as int,
            offsetYFx32: args['offsetY'] as int,
            heightFx32: args['height'] as int,
            turnsFx32: args['turns'] as int,
          );
          if (movingOrthographic) {
            result.component!.advanceEmitterPosition = () {
              final anchors = projection.capture();
              final transform = projection.worldTransform;
              if (anchors == null || anchors.length != 1 || transform == null) {
                throw StateError('Point de départ de l’effet indisponible');
              }
              final anchor = anchors.single;
              final base = BattleCameraPoint(anchor.x, anchor.y, anchor.z);
              final origin = projection.camera.tryProject(base);
              final point = projection.camera.tryProject(base + transform.apply(motion.advance()));
              if (origin == null || point == null) {
                throw StateError('Projection de l’effet indisponible');
              }
              result.component!.position = Vector2(origin.position.dx, origin.position.dy);
              return (
                x: ((point.position.dx - origin.position.dx) * 4096 / pixelsPerUnit).round(),
                y: ((origin.position.dy - point.position.dy) * 4096 / pixelsPerUnit).round(),
                z: 0,
              );
            };
          } else {
            result.component!.advanceEmitterPosition = motion.advance;
          }
        }
        prepared.add((args: args, result: result,
            screenAnchor: command.orthographic ? projection : null));
      }
      if (_closed) return;
      if (!await _waitForStart(onStart)) return;
      final completion = Completer<BattleGen5SourcePlaybackStatus>();
      _sourceCompletion = completion;
      var nextInvocation = 0;
      _startSourceAttack = () {
        if (isSurf) {
          _sound.playProjectFile(
            p.join(
              projectRoot,
              'data/pokemon/battle_recipes/blobs/0199311728be829918c18b5f1486d315ba690ed58b69b4c8236a16416130bcd2/2d1a632346536649a0f9aa36226c43ff7a1d97527bc001b4688ce9ac7b20114c.mp3',
            ),
          );
        }
        status.value = isSurf
            ? 'Surf · programme BW2 expérimental · son approximatif'
            : '${move.label} · programme BW2 expérimental';
        return _overlay.presentExperimentalGen5Attack(
          program: program,
          variant: program['variant'] as String,
          hasEmitter: (id, emitter) => prepared.any((entry) =>
              entry.args['particle'] == id && entry.args['emitter'] == emitter),
          startEmitter: (_, _, _) {},
          deleteSourceParticle: (particle) {
            for (final entry in prepared) {
              if (entry.args['particle'] == particle &&
                  active.remove(entry.result.component)) {
                entry.result.dispose();
              }
            }
          },
          startSourceEmitter: (args) {
            if (nextInvocation >= prepared.length ||
                jsonEncode(args) != jsonEncode(prepared[nextInvocation].args)) {
              throw StateError('Invocation de particules invalide');
            }
            final entry = prepared[nextInvocation++];
            final component = entry.result.component!;
            final screenAnchor = entry.screenAnchor;
            if (screenAnchor != null) {
              final anchors = screenAnchor.capture();
              final transform = screenAnchor.worldTransform;
              if (anchors == null || anchors.length != 1 || transform == null) {
                throw StateError('Point de départ de l’effet indisponible');
              }
              final anchor = anchors.single;
              final point = BattleCameraPoint(anchor.x, anchor.y, anchor.z) +
                  transform.apply((x: (args['offsetX'] as int?) ?? 0,
                      y: args.containsKey('motion') ? 0 : args['offsetY'] as int,
                      z: (args['offsetZ'] as int?) ?? 0));
              final projected = screenAnchor.camera.tryProject(point);
              if (projected == null) {
                throw StateError('Projection de l’effet indisponible');
              }
              component.position = Vector2(projected.position.dx, projected.position.dy);
            }
            active.add(component);
            _overlay.add(component);
          },
          particlesBusy: () {
            if (failure != null) {
              throw StateError('Effet BW2 interrompu : $failure');
            }
            return active.isNotEmpty;
          },
          detachParticles: dispose,
          allowSilentAudio: true,
          onSourceSound: isSurf ? null : playPreparedSound,
          onSourceCry: isSurf ? null : playPreparedSound,
          sourceBackgrounds: backgrounds,
          sourceBackgroundAnimations: backgroundAnimations,
          allowUnmappedAudioControls: isSurf || isMovingExample,
          allowOrthographicEmitters: commands.any((command) => command.orthographic),
          allowFieldEmitters: commands.any((command) => command.args.containsKey('fromX')),
          allowSourceVisibility: true,
          allowSourceGauge: true,
          allowApproximateFlatActors: isMovingExample,
          adaptSourceCamera: isSurf || isMovingExample,
          duringTrackedEffect: true,
        );
      };
      _adapter.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final turn = _attackPreviewSession();
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
            ? '${move.label} terminée · programme BW2 expérimental · ${isSurf || soundStarted ? 'son approximatif' : 'sans son source'}'
            : '${move.label} interrompue : ${result.name}';
      }
    } finally {
      _startSourceAttack = null;
      _sourceCompletion = null;
      dispose();
    }
  }

  BattleSession _attackPreviewSession() {
    final session = _adapter.createLegacyDisplaySession(isTrainerBattle: false);
    final turn = session.state.currentTurn!;
    final timeline = turn.timeline.takeWhile(
      (event) => event is! BattleTurnExecutionEvent ||
          event.execution.attackerSide != BattleSideId.enemy,
    ).toList(growable: false);
    return session.withRuntimeDisplayState(
      currentTurn: BattleTurnResult(
        playerAction: turn.playerAction,
        enemyAction: turn.enemyAction,
        executions: [
          for (final event in timeline.whereType<BattleTurnExecutionEvent>())
            event.execution,
        ],
        statusEvents: [
          for (final event in timeline.whereType<BattleTurnStatusEvent>()) event.event,
        ],
        volatileEvents: [
          for (final event in timeline.whereType<BattleTurnVolatileEvent>()) event.event,
        ],
        fieldEvents: [
          for (final event in timeline.whereType<BattleTurnFieldEvent>()) event.event,
        ],
        stealthRockEvents: [
          for (final event in timeline.whereType<BattleTurnStealthRockEvent>()) event.event,
        ],
        spikesEvents: [
          for (final event in timeline.whereType<BattleTurnSpikesEvent>()) event.event,
        ],
        bagHpHealItemEvents: [
          for (final event in timeline.whereType<BattleTurnBagHpHealItemEvent>()) event.event,
        ],
        switchEvents: [
          for (final event in timeline.whereType<BattleTurnSwitchEvent>()) event.event,
        ],
        captureAttemptEvents: [
          for (final event in timeline.whereType<BattleTurnCaptureAttemptEvent>()) event.event,
        ],
        timeline: timeline,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _advanceTransform(dt);
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
    _finishTransform();
    if (_overlayCreated) _overlay.cancelExperimentalGen5Attack();
    final completion = _sourceCompletion;
    if (completion != null && !completion.isCompleted) {
      completion.complete(BattleGen5SourcePlaybackStatus.cancelled);
    }
    unawaited(_sound.dispose());
    super.onRemove();
  }
}

RuntimePsdkBattleSessionAdapter _makeAdapter(
  PreviewMove move, {
  bool allySwapped = false,
  PreparedReferencePair? referencePokemon,
}) {
  final isSurf = move == PreviewMove.surf;
  final specialPreview = isSurf || move.id == 'transform' || move.id == 'ally-switch';
  final pair = specialPreview ? null : referencePokemon;
  final playerSpecies = pair?.attacker.id ?? (isSurf ? 'herdier' : 'totodile');
  final enemySpecies = pair?.target.id ?? (isSurf ? 'trubbish' : 'pidgey');
  PsdkBattleMoveData attack(PreviewMove move, int power) => PsdkBattleMoveData(
    id: move.id,
    dbSymbol: move.id.replaceAll('-', '_'),
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
    int speed, {
    int level = 25,
    int maxHp = 500,
    PsdkBattleGender gender = PsdkBattleGender.male,
  }) => PsdkBattleCombatantSetup(
    id: id,
    speciesId: species,
    displayName: name,
    level: level,
    maxHp: maxHp,
    currentHp: maxHp,
    types: PsdkBattleTypes(
      primary: species == 'totodile'
          ? 'water'
          : species == 'trubbish'
          ? 'poison'
          : 'normal',
    ),
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
  final player = pokemon(
    'player', playerSpecies, pair?.attacker.name ?? (isSurf ? 'Ponchien' : 'Kaiminus'),
    attack(move, 40), 100, level: isSurf ? 20 : 25,
    maxHp: isSurf ? 57 : 500,
  );
  final partner = pokemon('player_ally', 'pidgey', 'Roucool',
      attack(PreviewMove.tackle, 1), 90);
  final opponent = pokemon(
    'enemy', enemySpecies, pair?.target.name ?? (isSurf ? 'Miamiasme' : 'Roucool'),
    attack(PreviewMove.tackle, 0), 10,
    level: isSurf ? 19 : 25,
    gender: isSurf ? PsdkBattleGender.female : PsdkBattleGender.male,
  );
  const seeds = PsdkBattleRngSeeds(
    moveDamage: 1, moveCritical: 99999, moveAccuracy: 1, generic: 1,
  );
  final setup = move == PreviewMove.allySwitch ? PsdkBattleSetup.doubles(
    ruleset: PokemonRulesetProfile.standardV1,
    player: allySwapped ? [partner, player] : [player, partner],
    opponent: [opponent, pokemon('enemy_ally', 'totodile', 'Kaiminus',
        attack(PreviewMove.tackle, 1), 9)],
    rngSeeds: seeds,
  ) : PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: player,
    opponent: opponent,
    rngSeeds: seeds,
  );
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    setup,
    visualIdentitiesByBank: {
      0: [
        for (final species in move == PreviewMove.allySwitch
            ? (allySwapped ? ['pidgey', playerSpecies] : [playerSpecies, 'pidgey'])
            : [playerSpecies])
        RuntimeBattleVisualIdentity(
          speciesId: species,
          formId: 'base',
          genderId: 'male',
          isShiny: false,
        ),
      ],
      1: [
        for (final species in move == PreviewMove.allySwitch
            ? [enemySpecies, 'totodile'] : [enemySpecies])
        RuntimeBattleVisualIdentity(
          speciesId: species,
          formId: 'base',
          genderId: isSurf ? 'female' : 'male',
          isShiny: false,
        ),
      ],
    },
  );
}
