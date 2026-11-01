import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flame/game.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_stage_3d_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_layer_component.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

var qaRoot = '/Users/karim/Library/Caches/AveluneQA/battle-camera-consolidation';
var projectRoot = '/Users/karim/Project/Pokemon HeartGold/jeu';
BattleOverlayComponent Function(Vector2, ValueChanged<BattleCommandOverlaySnapshot?>)? qaOverlayFactory;
final errors = <String>[];
final appKey = GlobalKey<QaState>();
Map<String, double>? qaRectData(Rect? rect) => rect == null ? null : {'left': rect.left, 'top': rect.top, 'right': rect.right, 'bottom': rect.bottom, 'width': rect.width, 'height': rect.height};
void main() {
  MarionetteBinding.ensureInitialized();
  FlutterError.onError = (details) { errors.add(details.toString()); FlutterError.presentError(details); };
  developer.registerExtension('ext.flutter.battle.qaContext', (_, __) async => developer.ServiceExtensionResponse.result(jsonEncode(appKey.currentState!.contextData())));
  developer.registerExtension('ext.flutter.battle.qaAction', (_, parameters) async => developer.ServiceExtensionResponse.result(jsonEncode(await appKey.currentState!.action(parameters))));
  runApp(MaterialApp(debugShowCheckedModeBanner: false, theme: PokeMapPlayerTheme.dark(reducedMotion: true), locale: const Locale('fr'), supportedLocales: PokeMapPlayerLocalizations.supportedLocales, localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates, home: Qa(key: appKey)));
}
class Qa extends StatefulWidget {
  const Qa({super.key});
  @override
  State<Qa> createState() => QaState();
}
class QaState extends State<Qa> {
  final boundaryKey = GlobalKey();
  Size viewport = const Size(390, 844);
  late QaGame game;
  BattleCommandOverlaySnapshot? snapshot;
  @override
  void initState() {
    super.initState();
    game = QaGame(viewport, (value) {
      if (!mounted) return;
      snapshot = value;
      scheduleMicrotask(() { if (mounted) setState(() {}); });
    });
  }
  Future<void> tick(int frames) async {
    for (var i = 0; i < frames; i++) {
      game.stepEngine(stepTime: 1 / 60);
      WidgetsBinding.instance.drawFrame();
      await Future<void>.delayed(const Duration(milliseconds: 17));
    }
  }
  Future<void> applyQaViewport(Size next) async {
    if (!mounted) return;
    setState(() => viewport = next);
    await WidgetsBinding.instance.endOfFrame;
    if (game.loadedCompleter.isCompleted) {
      game.overlay.onGameResize(Vector2(next.width, next.height));
    }
  }
  Map<String, Object?> contextData() {
    final overlay = game.isLoaded ? game.overlay : null;
    final camera = overlay?.children.whereType<BattleStage3DComponent>().firstOrNull?.camera;
    final player = overlay?.debugPlayerCombatant;
    final actors = overlay?.children.whereType<BattleSceneCombatantComponent>().toList() ?? <BattleSceneCombatantComponent>[];
    final gpuActors = actors.where((actor) => actor.renderedBy3DStage).length;
    return {'qaRoot': qaRoot, 'readOnlyAssets': projectRoot, 'ready': game.loadedCompleter.isCompleted, 'actorCount': actors.length, 'gpuActors': gpuActors, 'allActorsGpu': actors.isNotEmpty && gpuActors == actors.length, 'actors': [for (final (index, actor) in actors.indexed) {'index': index, 'playerSide': actor.isPlayerSide, 'renderedBy3DStage': actor.renderedBy3DStage, 'hasImage': actor.stageImage != null, 'rect': qaRectData(actor.currentRenderedSpriteRect)}], 'viewport': '${viewport.width}x${viewport.height}', 'errors': errors, 'gpu': overlay?.children.whereType<BattleStage3DComponent>().firstOrNull?.isReady, 'framePresented': overlay?.children.whereType<BattleStage3DComponent>().firstOrNull?.currentFramePresented, 'fxCount': overlay?.children.whereType<BattleFxLayerComponent>().firstOrNull?.activeFxCount, 'speed': overlay?.motionPolicy.playbackSpeed, 'reduced': overlay?.motionPolicy.reducedMotion, 'gpuPlayer': player?.renderedBy3DStage, 'playerRect': qaRectData(player?.currentRenderedSpriteRect), 'enemyRect': qaRectData(overlay?.debugEnemyCombatant?.currentRenderedSpriteRect), 'eye': camera == null ? null : [camera.eye.x, camera.eye.y, camera.eye.z], 'aim': camera == null ? null : [camera.aim.x, camera.aim.y, camera.aim.z], 'moving': camera?.isMoving, 'prompt': snapshot?.prompt, 'hudVisible': snapshot?.playerHud.isVisible};
  }
  Future<Map<String, Object?>> action(Map<String, String> args) async {
    for (var i = 0; i < 600 && !game.loadedCompleter.isCompleted; i++) { await tick(1); }
    await game.loadedCompleter.future.timeout(const Duration(seconds: 5));
    game.pauseEngine();
    if (args.containsKey('speed') || args.containsKey('reduced') || args.containsKey('intensity')) {
      final current = game.overlay.motionPolicy;
      game.overlay.applyMotionPolicy(BattleMotionPolicy(
        playbackSpeed: double.tryParse(args['speed'] ?? '') ?? current.playbackSpeed,
        reducedMotion: args['reduced'] == null ? current.reducedMotion : args['reduced'] == 'true',
        effectIntensity: double.tryParse(args['intensity'] ?? '') ?? current.effectIntensity,
      ));
    }
    if (args['size'] != null) {
      final values = args['size']!.split('x').map(double.parse).toList();
      setState(() => viewport = Size(values[0], values[1]));
      WidgetsBinding.instance.drawFrame();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      game.overlay.onGameResize(Vector2(viewport.width, viewport.height));
    }
    if (args['command'] == 'fight') { game.overlay.selectRootEntry(0); await tick(3); }
    if (args['command'] == 'attack') { game.overlay.selectChoiceEntry(0); await game.overlay.waitForPendingVisualSync(); }
    if (args['command'] == 'fx') {
      game.overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [
        AnimationGroupStep(mode: BattleAnimationGroupMode.parallel, steps: [
          CameraFocusStep(target: BattleCameraFocusTarget.target, side: BattleSideId.enemy, durationSeconds: 1.5),
          SpawnFxStep(effectId: 'fireball', attackerSide: BattleSideId.player, defenderSide: BattleSideId.enemy, from: BattleVisualAnchor.attackerCenter, to: BattleVisualAnchor.defenderCenter, durationSeconds: 2, playAsAccent: true, curve: BattleFxMotionCurve.linear, afterEffect: BattleFxAfterEffect.none),
        ]),
        WaitStep(durationSeconds: .2),
        BattleCameraResetStep(durationSeconds: .3),
      ]));
    }
    await tick(int.parse(args['frames'] ?? '1'));
    if (args['capture'] != null) {
      WidgetsBinding.instance.drawFrame();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$qaRoot/${args['capture']}.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      await File('$qaRoot/${args['capture']}.json').writeAsString(const JsonEncoder.withIndent('  ').convert(contextData()));
    }
    return contextData();
  }
  void command(BattlePresentationCommand command) {
    final overlay = game.overlay;
    if (command is BattleSetCommandPanelPlacementCommand) {
      overlay.setCommandPanelPlacement(command.placement, controllerLayout: command.controllerLayout, portraitTouchLayout: command.portraitTouchLayout, rootCommandOrder: command.rootCommandOrder, collectionColumns: command.collectionColumns);
    } else if (command is BattleSelectEntryCommand) {
      if (snapshot?.mode == BattleCommandOverlayMode.root) { overlay.selectRootEntry(command.entryIndex); }
      else { overlay.selectChoiceEntry(command.entryIndex); }
    } else if (command is BattleBackCommand) { overlay.handleEscape(); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: RepaintBoundary(key: boundaryKey, child: SizedBox(width: viewport.width, height: viewport.height, child: MediaQuery(data: MediaQueryData(size: viewport, devicePixelRatio: 1), child: Stack(children: [GameWidget(game: game), if (snapshot != null) Positioned.fill(child: PlayerBattleOverlay(snapshot: snapshot!, onCommand: command))]))))));
}
class QaGame extends FlameGame {
  QaGame(this.viewportSize, this.onSnapshot);
  final Size viewportSize;
  final ValueChanged<BattleCommandOverlaySnapshot?> onSnapshot;
  final loadedCompleter = Completer<void>();
  late BattleOverlayComponent overlay;
  @override
  Future<void> onLoad() async {
    final factory = qaOverlayFactory;
    if (factory != null) {
      overlay = factory(Vector2(viewportSize.width, viewportSize.height), onSnapshot);
      add(overlay);
      await overlay.loaded;
      await overlay.waitForPendingVisualSync();
      loadedCompleter.complete();
      return;
    }
    final session = createBattleSession(BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: const BattleCombatantData(speciesId: 'totodile', level: 7, maxHp: 25, currentHp: 25, stats: BattleStatsSnapshot(attack: 25, defense: 25, specialAttack: 20, specialDefense: 20, speed: 10), moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 40)]),
      enemyPokemon: const BattleCombatantData(speciesId: 'rattata', level: 3, maxHp: 19, currentHp: 19, stats: BattleStatsSnapshot(attack: 15, defense: 10, specialAttack: 10, specialDefense: 10, speed: 40), moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 40)]), isTrainerBattle: false, trainerId: null,
    ));
    overlay = BattleOverlayComponent(session: session, viewportSize: Vector2(viewportSize.width, viewportSize.height), onPlayerChoice: (choice) => overlay.updateState(overlay.debugSession.applyChoice(choice)), onCommandOverlaySnapshotChanged: onSnapshot, resolveSpeciesDisplayName: (id) => id == 'totodile' ? 'Kaiminus' : 'Rattata', backgroundSpec: BattleBackgroundSpec.explicitImage(fallbackKey: BattleBackgroundKey.wildOutdoor, absolutePath: '$projectRoot/assets/battle/backgrounds/clairiere-johto-v1.png'), spriteResolver: BattlePokemonSpriteResolver(manifest: ProjectManifest(name: 'QA', maps: [], tilesets: []), projectRootDirectory: projectRoot));
    add(overlay);
    unawaited(overlay.loaded.then((_) async { await overlay.waitForPendingVisualSync(); loadedCompleter.complete(); }));
  }
}
