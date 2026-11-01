import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_presentation.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('chooses the exact form, shiny and female GIF for both sides', () async {
    final root = await Directory.systemTemp.createTemp('battle-variants-');
    addTearDown(() => root.delete(recursive: true));
    for (final filename in [
      'base-front.gif',
      'base-back.gif',
      'alt-front.gif',
      'alt-back.gif',
      'alt-shiny-front.gif',
      'alt-shiny-back.gif',
      'alt-female-front.gif',
      'alt-female-back.gif',
      'alt-shiny-female-front.gif',
      'alt-shiny-female-back.gif',
    ]) {
      await _write(root, 'assets/$filename', [1]);
    }
    await _media(root, {
      'base': {
        'frontAnimated': 'assets/base-front.gif',
        'backAnimated': 'assets/base-back.gif',
      },
      'alt': {
        'frontAnimated': 'assets/alt-front.gif',
        'backAnimated': 'assets/alt-back.gif',
        'frontShinyAnimated': 'assets/alt-shiny-front.gif',
        'backShinyAnimated': 'assets/alt-shiny-back.gif',
        'frontFemaleAnimated': 'assets/alt-female-front.gif',
        'backFemaleAnimated': 'assets/alt-female-back.gif',
        'frontShinyFemaleAnimated': 'assets/alt-shiny-female-front.gif',
        'backShinyFemaleAnimated': 'assets/alt-shiny-female-back.gif',
      },
    });
    final resolver = _resolver(root);
    const identity = RuntimeBattleVisualIdentity(
      speciesId: 'oshawott',
      formId: 'alt',
      genderId: 'female',
      isShiny: true,
    );

    final enemy = await resolver.resolve(
      speciesId: 'oshawott',
      isPlayerSide: false,
      visualIdentity: identity,
    );
    final player = await resolver.resolve(
      speciesId: 'oshawott',
      isPlayerSide: true,
      visualIdentity: identity,
    );

    expect(
      enemy.explicitAnimatedImageAbsolutePath,
      '${root.path}/assets/alt-shiny-female-front.gif',
    );
    expect(
      player.explicitAnimatedImageAbsolutePath,
      '${root.path}/assets/alt-shiny-female-back.gif',
    );
    final shinyMale = await resolver.resolve(
      speciesId: 'oshawott',
      isPlayerSide: false,
      visualIdentity: const RuntimeBattleVisualIdentity(
        speciesId: 'oshawott',
        formId: 'alt',
        genderId: 'male',
        isShiny: true,
      ),
    );
    final female = await resolver.resolve(
      speciesId: 'oshawott',
      isPlayerSide: true,
      visualIdentity: const RuntimeBattleVisualIdentity(
        speciesId: 'oshawott',
        formId: 'alt',
        genderId: 'female',
        isShiny: false,
      ),
    );
    final original = await resolver.resolve(
      speciesId: 'oshawott',
      isPlayerSide: false,
    );
    expect(
      shinyMale.explicitAnimatedImageAbsolutePath,
      '${root.path}/assets/alt-shiny-front.gif',
    );
    expect(
      female.explicitAnimatedImageAbsolutePath,
      '${root.path}/assets/alt-female-back.gif',
    );
    expect(
      original.explicitAnimatedImageAbsolutePath,
      '${root.path}/assets/base-front.gif',
    );
    expect(resolver.debugActualMediaReadCount, 1);
  });

  test('prefers shiny static artwork over an unrelated normal GIF', () async {
    final root = await Directory.systemTemp.createTemp('battle-variants-');
    addTearDown(() => root.delete(recursive: true));
    await _write(root, 'assets/normal.gif', [1]);
    await _write(root, 'assets/shiny.png', [1]);
    await _media(root, {
      'base': {
        'frontAnimated': 'assets/normal.gif',
        'frontShinyStatic': 'assets/shiny.png',
      },
    });
    final sprite = await _resolver(root).resolve(
      speciesId: 'oshawott',
      isPlayerSide: false,
      visualIdentity: const RuntimeBattleVisualIdentity(
        speciesId: 'oshawott',
        formId: 'base',
        genderId: null,
        isShiny: true,
      ),
    );
    expect(sprite.explicitImageAbsolutePath, '${root.path}/assets/shiny.png');
    expect(sprite.explicitAnimatedImageAbsolutePath, isNull);
  });

  test(
    'uses the historical default when identity or requested media is missing',
    () async {
      final root = await Directory.systemTemp.createTemp('battle-variants-');
      addTearDown(() => root.delete(recursive: true));
      await _write(root, 'assets/base.gif', [1]);
      await _write(root, 'assets/base-shiny.gif', [1]);
      await _media(root, {
        'base': {
          'frontAnimated': 'assets/base.gif',
          'frontShinyAnimated': 'assets/base-shiny.gif',
        },
        'alt': {'frontAnimated': 'assets/absent.gif'},
      });
      final resolver = _resolver(root);
      final noIdentity = await resolver.resolve(
        speciesId: 'oshawott',
        isPlayerSide: false,
      );
      final otherSpecies = await resolver.resolve(
        speciesId: 'oshawott',
        isPlayerSide: false,
        visualIdentity: const RuntimeBattleVisualIdentity(
          speciesId: 'pikachu',
          formId: 'alt',
          genderId: 'female',
          isShiny: true,
        ),
      );
      final missingForm = await resolver.resolve(
        speciesId: 'oshawott',
        isPlayerSide: false,
        visualIdentity: const RuntimeBattleVisualIdentity(
          speciesId: 'oshawott',
          formId: 'missing',
          genderId: null,
          isShiny: true,
        ),
      );
      final missingFormFile = await resolver.resolve(
        speciesId: 'oshawott',
        isPlayerSide: false,
        visualIdentity: const RuntimeBattleVisualIdentity(
          speciesId: 'oshawott',
          formId: 'alt',
          genderId: null,
          isShiny: false,
        ),
      );
      for (final sprite in [
        noIdentity,
        otherSpecies,
        missingForm,
        missingFormFile,
      ]) {
        expect(
          sprite.explicitAnimatedImageAbsolutePath,
          '${root.path}/assets/base.gif',
        );
      }
    },
  );

  test(
    'honors version 1 shiny static sprites without activating GIF fields',
    () async {
      final root = await Directory.systemTemp.createTemp('battle-variants-');
      addTearDown(() => root.delete(recursive: true));
      await _write(root, 'assets/shiny.png', [1]);
      await _write(root, 'assets/shiny.gif', [1]);
      await _media(root, {
        'base': {
          'frontShinyStatic': 'assets/shiny.png',
          'frontShinyAnimated': 'assets/shiny.gif',
        },
      }, schemaVersion: 1);
      final sprite = await _resolver(root).resolve(
        speciesId: 'oshawott',
        isPlayerSide: false,
        visualIdentity: const RuntimeBattleVisualIdentity(
          speciesId: 'oshawott',
          formId: 'base',
          genderId: null,
          isShiny: true,
        ),
      );
      expect(sprite.explicitImageAbsolutePath, '${root.path}/assets/shiny.png');
      expect(sprite.explicitAnimatedImageAbsolutePath, isNull);
    },
  );

  testWidgets(
    'displays each active identity and preserves the outgoing sprite during a switch',
    (tester) async {
      final root = await tester.runAsync(() => _animatedProject());
      addTearDown(() => root!.delete(recursive: true));
      final adapter = _adapter();
      final overlay = BattleOverlayComponent(
        session: adapter.createLegacyDisplaySession(isTrainerBattle: true),
        presentation: adapter.presentation,
        viewportSize: Vector2(960, 540),
        spriteResolver: _resolver(root!),
        onPlayerChoice: (_) {},
        playSfx: (_, {required volume, required pitch}) {},
      );
      final game = FlameGame()..world.add(overlay);
      try {
        await _mount(tester, game);
        await _until(
          tester,
          () =>
              overlay.debugPlayerCombatant?.currentSpriteSourcePath ==
                  '${root.path}/assets/base-back.gif' &&
              overlay.debugEnemyCombatant?.currentSpriteSourcePath ==
                  '${root.path}/assets/alt-shiny-front.gif',
        );
        expect(
          overlay.debugPlayerCombatant!.currentSpriteSourcePath,
          '${root.path}/assets/base-back.gif',
        );
        expect(
          overlay.debugEnemyCombatant!.currentSpriteSourcePath,
          '${root.path}/assets/alt-shiny-front.gif',
        );

        adapter.submitPlayerChoice(const PlayerBattleChoiceSwitch(0));
        overlay.updateState(
          adapter.createLegacyDisplaySession(isTrainerBattle: true),
          presentation: adapter.presentation,
        );
        await tester.pump();
        expect(
          overlay.debugPlayerCombatant!.currentSpriteSourcePath,
          '${root.path}/assets/base-back.gif',
        );
        await _until(
          tester,
          () =>
              overlay.debugPlayerCombatant?.currentSpriteSourcePath ==
              '${root.path}/assets/alt-shiny-female-back.gif',
        );
        expect(
          overlay.debugPlayerCombatant!.currentSpriteSourcePath,
          '${root.path}/assets/alt-shiny-female-back.gif',
        );
        expect(
          overlay.debugEnemyCombatant!.currentSpriteSourcePath,
          '${root.path}/assets/alt-shiny-front.gif',
        );
        game.pauseEngine();
        final player = overlay.debugPlayerCombatant!..renderedBy3DStage = false;
        final first = await tester.runAsync(() => _renderedCenter(player));
        player.update(.1);
        final second = await tester.runAsync(() => _renderedCenter(player));
        expect(
          [first, second],
          containsAll([
            [255, 0, 0, 255],
            [0, 0, 255, 255],
          ]),
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'a real Transform to the same species drops the uncertain original variant',
    (tester) async {
      final root = await tester.runAsync(() => _animatedProject());
      addTearDown(() => root!.delete(recursive: true));
      final adapter = _adapter(transform: true);
      final overlay = BattleOverlayComponent(
        session: adapter.createLegacyDisplaySession(isTrainerBattle: true),
        presentation: adapter.presentation,
        viewportSize: Vector2(960, 540),
        spriteResolver: _resolver(root!),
        onPlayerChoice: (_) {},
        playSfx: (_, {required volume, required pitch}) {},
      );
      final game = FlameGame()..world.add(overlay);
      try {
        await _mount(tester, game);
        await _until(
          tester,
          () =>
              overlay.debugPlayerCombatant?.currentSpriteSourcePath ==
              '${root.path}/assets/alt-shiny-female-back.gif',
        );
        expect(
          overlay.debugPlayerCombatant!.currentSpriteSourcePath,
          '${root.path}/assets/alt-shiny-female-back.gif',
        );
        adapter.submitPlayerChoice(const PlayerBattleChoiceFight(0));
        expect(
          adapter.presentation.activeCombatants.first.currentVisualIdentity,
          isNull,
        );
        overlay.updateState(
          adapter.createLegacyDisplaySession(isTrainerBattle: true),
          presentation: adapter.presentation,
        );
        await _until(
          tester,
          () =>
              overlay.debugPlayerCombatant?.currentSpriteSourcePath ==
              '${root.path}/assets/base-back.gif',
        );
        expect(
          overlay.debugPlayerCombatant!.currentSpriteSourcePath,
          '${root.path}/assets/base-back.gif',
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'an active illusion uses generic artwork instead of the original variant',
    (tester) async {
      final root = await tester.runAsync(() => _animatedProject());
      addTearDown(() => root!.delete(recursive: true));
      final adapter = _adapter(illusion: true);
      expect(
        adapter
            .presentation
            .activeCombatants
            .first
            .visualIdentityUnavailableReason,
        RuntimeBattleVisualIdentityUnavailableReason.illusion,
      );
      final overlay = BattleOverlayComponent(
        session: adapter.createLegacyDisplaySession(isTrainerBattle: true),
        presentation: adapter.presentation,
        viewportSize: Vector2(960, 540),
        spriteResolver: _resolver(root!),
        onPlayerChoice: (_) {},
        playSfx: (_, {required volume, required pitch}) {},
      );
      final game = FlameGame()..world.add(overlay);
      try {
        await _mount(tester, game);
        await _until(
          tester,
          () =>
              overlay.debugPlayerCombatant?.currentSpriteSourcePath ==
              '${root.path}/assets/base-back.gif',
        );
        expect(
          overlay.debugPlayerCombatant!.currentSpriteSourcePath,
          '${root.path}/assets/base-back.gif',
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'a real form change after switching does not show the original form variant',
    (tester) async {
      final root = await tester.runAsync(() => _animatedProject());
      addTearDown(() => root!.delete(recursive: true));
      final adapter = _formSwitchAdapter();
      final overlay = BattleOverlayComponent(
        session: adapter.createLegacyDisplaySession(isTrainerBattle: true),
        presentation: adapter.presentation,
        viewportSize: Vector2(960, 540),
        spriteResolver: _resolver(root!),
        onPlayerChoice: (_) {},
        playSfx: (_, {required volume, required pitch}) {},
      );
      final game = FlameGame()..world.add(overlay);
      try {
        await _mount(tester, game);
        await _until(
          tester,
          () =>
              overlay.debugPlayerCombatant?.currentSpriteSourcePath ==
              '${root.path}/assets/base-back.gif',
        );
        adapter.submitPlayerChoice(const PlayerBattleChoiceSwitch(0));
        expect(adapter.state.battlerAt(psdkPlayerSlot).form, 1);
        expect(
          adapter
              .presentation
              .activeCombatants
              .first
              .visualIdentityUnavailableReason,
          RuntimeBattleVisualIdentityUnavailableReason.appearanceChanged,
        );
        overlay.updateState(
          adapter.createLegacyDisplaySession(isTrainerBattle: true),
          presentation: adapter.presentation,
        );
        await _until(
          tester,
          () =>
              overlay.debugPlayerCombatant?.currentSpriteSourcePath ==
              '${root.path}/assets/groudon-base-back.gif',
        );
        expect(
          overlay.debugPlayerCombatant!.currentSpriteSourcePath,
          '${root.path}/assets/groudon-base-back.gif',
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'an opponent replacement switches to the incoming identity after the knockout',
    (tester) async {
      final root = await tester.runAsync(() => _animatedProject());
      addTearDown(() => root!.delete(recursive: true));
      final adapter = _enemySwitchAdapter();
      final overlay = BattleOverlayComponent(
        session: adapter.createLegacyDisplaySession(isTrainerBattle: true),
        presentation: adapter.presentation,
        viewportSize: Vector2(960, 540),
        spriteResolver: _resolver(root!),
        onPlayerChoice: (_) {},
        playSfx: (_, {required volume, required pitch}) {},
      );
      final game = FlameGame()..world.add(overlay);
      try {
        await _mount(tester, game);
        await _until(
          tester,
          () =>
              overlay.debugEnemyCombatant?.currentSpriteSourcePath ==
              '${root.path}/assets/base-front.gif',
        );
        expect(
          overlay.debugEnemyCombatant!.currentSpriteSourcePath,
          '${root.path}/assets/base-front.gif',
        );
        adapter.submitPlayerChoice(const PlayerBattleChoiceFight(0));
        expect(adapter.state.battlerAt(psdkOpponentSlot).id, 'enemy1');
        overlay.updateState(
          adapter.createLegacyDisplaySession(isTrainerBattle: true),
          presentation: adapter.presentation,
        );
        await tester.pump();
        expect(
          overlay.debugEnemyCombatant!.currentSpriteSourcePath,
          '${root.path}/assets/base-front.gif',
        );
        await _until(
          tester,
          () =>
              overlay.debugEnemyCombatant?.currentSpriteSourcePath ==
              '${root.path}/assets/alt-shiny-front.gif',
        );
        expect(
          overlay.debugEnemyCombatant!.currentSpriteSourcePath,
          '${root.path}/assets/alt-shiny-front.gif',
        );
        expect(
          overlay.debugPlayerCombatant!.currentSpriteSourcePath,
          '${root.path}/assets/base-back.gif',
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'doubles preserve four variant identities while both player slots switch',
    (tester) async {
      final root = await tester.runAsync(() => _animatedProject());
      addTearDown(() => root!.delete(recursive: true));
      final adapter = _doublesAdapter();
      final overlay = BattleOverlayComponent(
        session: adapter.createLegacyDisplaySession(isTrainerBattle: true),
        presentation: adapter.presentation,
        viewportSize: Vector2(960, 540),
        spriteResolver: _resolver(root!),
        onPlayerChoice: (_) {},
        playSfx: (_, {required volume, required pitch}) {},
      );
      final game = FlameGame()..world.add(overlay);
      List<String?> paths(bool player) => overlay.children
          .whereType<BattleSceneCombatantComponent>()
          .where((component) => component.belongsToPlayerSide == player)
          .map((component) => component.currentSpriteSourcePath)
          .toList();
      try {
        await _mount(tester, game);
        await _until(
          tester,
          () =>
              paths(true).toSet().containsAll({
                '${root.path}/assets/base-back.gif',
                '${root.path}/assets/alt-shiny-female-back.gif',
              }) &&
              paths(false).toSet().containsAll({
                '${root.path}/assets/base-front.gif',
                '${root.path}/assets/alt-shiny-front.gif',
              }),
        );
        expect(paths(true).toSet(), {
          '${root.path}/assets/base-back.gif',
          '${root.path}/assets/alt-shiny-female-back.gif',
        });
        expect(paths(false).toSet(), {
          '${root.path}/assets/base-front.gif',
          '${root.path}/assets/alt-shiny-front.gif',
        });
        adapter.submitDecision(
          const BattleDecision.switchPokemon(partyIndex: 2),
          request: adapter.decisionRequest,
        );
        adapter.submitDecision(
          const BattleDecision.switchPokemon(partyIndex: 3),
          request: adapter.decisionRequest,
        );
        overlay.updateState(
          adapter.createLegacyDisplaySession(isTrainerBattle: true),
          presentation: adapter.presentation,
        );
        await _until(
          tester,
          () =>
              paths(true).length == 2 &&
              paths(true).every(
                (path) =>
                    path == '${root.path}/assets/alt-shiny-female-back.gif',
              ),
        );
        expect(paths(true), hasLength(2));
        expect(
          paths(true),
          everyElement('${root.path}/assets/alt-shiny-female-back.gif'),
        );
        expect(paths(false).toSet(), {
          '${root.path}/assets/base-front.gif',
          '${root.path}/assets/alt-shiny-front.gif',
        });
      } finally {
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
}

Future<void> _mount(WidgetTester tester, FlameGame game) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(width: 960, height: 540, child: GameWidget(game: game)),
    ),
  );
}

Future<List<int>> _renderedCenter(
  BattleSceneCombatantComponent component,
) async {
  final recorder = ui.PictureRecorder();
  component.render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    component.size.x.ceil(),
    component.size.y.ceil(),
  );
  try {
    final center =
        component.currentRenderedSpriteRect.center -
        ui.Offset(component.position.x, component.position.y);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final offset = (center.dy.floor() * image.width + center.dx.floor()) * 4;
    return bytes!.buffer.asUint8List().sublist(offset, offset + 4);
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 360 && !ready(); i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 3)),
    );
  }
}

Future<Directory> _animatedProject() async {
  final root = await Directory.systemTemp.createTemp(
    'battle-variants-overlay-',
  );
  final red = img.Image(width: 2, height: 2);
  final blue = img.Image(width: 2, height: 2);
  img.fill(red, color: img.ColorRgb8(255, 0, 0));
  img.fill(blue, color: img.ColorRgb8(0, 0, 255));
  final encoder =
      img.GifEncoder(
          repeat: 0,
          dither: img.DitherKernel.none,
          quantizerType: img.QuantizerType.octree,
        )
        ..addFrame(red, duration: 10)
        ..addFrame(blue, duration: 10);
  final bytes = encoder.finish()!;
  for (final filename in [
    'base-front.gif',
    'base-back.gif',
    'alt-shiny-front.gif',
    'alt-shiny-female-back.gif',
    'groudon-base-back.gif',
    'groudon-alt-back.gif',
  ]) {
    await _write(root, 'assets/$filename', bytes);
  }
  await _media(root, {
    'base': {
      'frontAnimated': 'assets/base-front.gif',
      'backAnimated': 'assets/base-back.gif',
    },
    'alt': {
      'frontShinyAnimated': 'assets/alt-shiny-front.gif',
      'backShinyFemaleAnimated': 'assets/alt-shiny-female-back.gif',
    },
  });
  await _media(root, {
    'base': {'backAnimated': 'assets/groudon-base-back.gif'},
    'alt': {'backShinyFemaleAnimated': 'assets/groudon-alt-back.gif'},
  }, species: 'groudon');
  return root;
}

RuntimePsdkBattleSessionAdapter _adapter({
  bool transform = false,
  bool illusion = false,
}) {
  final wait = _move('wait');
  final special = transform || illusion;
  final setup = PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(
      'p0',
      transform ? _move('transform', method: 's_transform') : wait,
      transformState: illusion
          ? const PsdkBattleTransformState(illusionSpeciesId: 'unknown')
          : const PsdkBattleTransformState(),
    ),
    playerReserves: [_combatant('p1', wait)],
    opponent: _combatant('enemy', wait),
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
          speciesId: 'oshawott',
          formId: special ? 'alt' : 'base',
          genderId: special ? 'female' : 'male',
          isShiny: special,
        ),
        const RuntimeBattleVisualIdentity(
          speciesId: 'oshawott',
          formId: 'alt',
          genderId: 'female',
          isShiny: true,
        ),
      ],
      1: [
        const RuntimeBattleVisualIdentity(
          speciesId: 'oshawott',
          formId: 'alt',
          genderId: 'male',
          isShiny: true,
        ),
      ],
    },
  );
}

RuntimePsdkBattleSessionAdapter _formSwitchAdapter() {
  final wait = _move('wait');
  final setup = PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant('p0', wait),
    playerReserves: [
      _combatant('p1', wait, speciesId: 'groudon', heldItemId: 'red_orb'),
    ],
    opponent: _combatant('enemy', wait),
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
        const RuntimeBattleVisualIdentity(
          speciesId: 'oshawott',
          formId: 'base',
          genderId: 'male',
          isShiny: false,
        ),
        const RuntimeBattleVisualIdentity(
          speciesId: 'groudon',
          formId: 'alt',
          genderId: 'female',
          isShiny: true,
        ),
      ],
    },
  );
}

RuntimePsdkBattleSessionAdapter _enemySwitchAdapter() {
  final setup = PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant('p0', _attack()),
    opponent: _combatant('enemy0', _move('wait'), currentHp: 1),
    opponentReserves: [_combatant('enemy1', _move('wait'))],
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
        const RuntimeBattleVisualIdentity(
          speciesId: 'oshawott',
          formId: 'base',
          genderId: 'male',
          isShiny: false,
        ),
      ],
      1: [
        const RuntimeBattleVisualIdentity(
          speciesId: 'oshawott',
          formId: 'base',
          genderId: 'male',
          isShiny: false,
        ),
        const RuntimeBattleVisualIdentity(
          speciesId: 'oshawott',
          formId: 'alt',
          genderId: 'male',
          isShiny: true,
        ),
      ],
    },
  );
}

RuntimePsdkBattleSessionAdapter _doublesAdapter() {
  final wait = _move('wait');
  final setup = PsdkBattleSetup.doubles(
    ruleset: PokemonRulesetProfile.standardV1,
    player: [_combatant('p0', wait), _combatant('p1', wait)],
    playerReserves: [_combatant('p2', wait), _combatant('p3', wait)],
    opponent: [_combatant('e0', wait), _combatant('e1', wait)],
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 1,
      generic: 1,
    ),
  );
  const base = RuntimeBattleVisualIdentity(
    speciesId: 'oshawott',
    formId: 'base',
    genderId: 'male',
    isShiny: false,
  );
  const shinyFemale = RuntimeBattleVisualIdentity(
    speciesId: 'oshawott',
    formId: 'alt',
    genderId: 'female',
    isShiny: true,
  );
  const shinyMale = RuntimeBattleVisualIdentity(
    speciesId: 'oshawott',
    formId: 'alt',
    genderId: 'male',
    isShiny: true,
  );
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    setup,
    visualIdentitiesByBank: {
      0: [base, shinyFemale, shinyFemale, shinyFemale],
      1: [base, shinyMale],
    },
  );
}

PsdkBattleCombatantSetup _combatant(
  String id,
  PsdkBattleMoveData move, {
  int currentHp = 100,
  String speciesId = 'oshawott',
  String? heldItemId,
  PsdkBattleTransformState transformState = const PsdkBattleTransformState(),
}) => PsdkBattleCombatantSetup(
  id: id,
  speciesId: speciesId,
  displayName: id,
  level: 10,
  maxHp: 100,
  currentHp: currentHp,
  types: const PsdkBattleTypes(primary: 'normal'),
  heldItemId: heldItemId,
  transformState: transformState,
  stats: const PsdkBattleStats(
    attack: 10,
    defense: 10,
    specialAttack: 10,
    specialDefense: 10,
    speed: 10,
  ),
  moves: [move],
);

PsdkBattleMoveData _move(String id, {String method = 's_status'}) =>
    PsdkBattleMoveData(
      id: id,
      dbSymbol: id,
      name: id,
      type: 'normal',
      category: PsdkBattleMoveCategory.status,
      power: 0,
      accuracy: 100,
      pp: 10,
      currentPp: 10,
      priority: 0,
      battleEngineMethod: method,
      target: PsdkBattleMoveTarget.adjacentFoe,
    );

PsdkBattleMoveData _attack() => PsdkBattleMoveData(
  id: 'hit',
  dbSymbol: 'hit',
  name: 'hit',
  type: 'normal',
  category: PsdkBattleMoveCategory.physical,
  power: 200,
  accuracy: 100,
  pp: 10,
  currentPp: 10,
  priority: 0,
  battleEngineMethod: 's_basic',
  target: PsdkBattleMoveTarget.adjacentFoe,
);

BattlePokemonSpriteResolver _resolver(Directory root) =>
    BattlePokemonSpriteResolver(
      manifest: const ProjectManifest(name: 'variants', maps: [], tilesets: []),
      projectRootDirectory: root.path,
    );

Future<void> _media(
  Directory root,
  Map<String, Object?> variants, {
  int schemaVersion = 2,
  String species = 'oshawott',
}) => _write(
  root,
  'data/pokemon/media/$species.json',
  utf8.encode(
    jsonEncode({
      'schemaVersion': schemaVersion,
      'speciesId': species,
      'defaultFormId': 'base',
      'variants': variants,
    }),
  ),
);

Future<void> _write(
  Directory root,
  String relativePath,
  List<int> bytes,
) async {
  final file = File('${root.path}/$relativePath');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
}
