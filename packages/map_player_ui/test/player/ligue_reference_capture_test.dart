import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_bag.dart';
import 'package:map_player_ui/src/player/player_save_dialog.dart';
import 'package:map_player_ui/src/player/player_world_loading_surface.dart';
import 'package:map_player_ui/src/player/runtime_player_party.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_backdrop_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_visual_asset_cache.dart';
import 'package:path/path.dart' as p;

const _referenceRoot = String.fromEnvironment('LIGUE_REFERENCE_ROOT');
const _captureRoot = String.fromEnvironment('LIGUE_CAPTURE_ROOT');
const _screenFilter = String.fromEnvironment('LIGUE_CAPTURE_SCREENS');
const _modeFilter = String.fromEnvironment('LIGUE_CAPTURE_MODES');
const _captureVariants = bool.fromEnvironment('LIGUE_CAPTURE_VARIANTS');
const _widePhone = bool.fromEnvironment('LIGUE_CAPTURE_WIDE_PHONE');
const _threeMoves = bool.fromEnvironment('LIGUE_CAPTURE_THREE_MOVES');
const _battleMotion = bool.fromEnvironment('LIGUE_CAPTURE_BATTLE_MOTION');
const _enabled = _referenceRoot != '' && _captureRoot != '';
const _species = [
  'bulbasaur',
  'charmander',
  'squirtle',
  'pikachu',
  'eevee',
  'pidgey',
];
const _speciesLabels = [
  'Bulbizarre',
  'Salamèche',
  'Carapuce',
  'Pikachu',
  'Évoli',
  'Roucool',
];
const _types = <List<String>>[
  ['grass', 'poison'],
  ['fire'],
  ['water'],
  ['electric'],
  ['normal'],
  ['normal', 'flying'],
];
const _sections = [
  RuntimePlayerPauseSection.root,
  RuntimePlayerPauseSection.party,
  RuntimePlayerPauseSection.bag,
  RuntimePlayerPauseSection.map,
  RuntimePlayerPauseSection.pokedex,
  RuntimePlayerPauseSection.profile,
  RuntimePlayerPauseSection.options,
  RuntimePlayerPauseSection.quests,
  RuntimePlayerPauseSection.contacts,
];
const _accepted = RuntimePlayerCommandResult(
  status: RuntimePlayerCommandStatus.accepted,
);
const _modes = <String, Size>{
  'landscape-touch': _widePhone ? Size(1280, 590) : Size(844, 390),
  'landscape-controller': _widePhone ? Size(1280, 590) : Size(844, 390),
  'portrait-touch': Size(390, 844),
  'portrait-controller': Size(390, 844),
  'thor-primary': Size(768, 432),
  'thor-companion': Size(496, 432),
};
const _items = <({String label, int quantity, String description, int price})>[
  (
    label: 'Potion',
    quantity: 8,
    description: 'Restaure 20 PV à un Pokémon.',
    price: 300,
  ),
  (
    label: 'Super Potion',
    quantity: 3,
    description: 'Restaure 50 PV à un Pokémon.',
    price: 700,
  ),
  (
    label: 'Antidote',
    quantity: 4,
    description: 'Soigne l’empoisonnement d’un Pokémon.',
    price: 100,
  ),
  (
    label: 'Rappel',
    quantity: 1,
    description: 'Ranime un Pokémon K.O. avec la moitié de ses PV.',
    price: 1500,
  ),
  (
    label: 'Huile',
    quantity: 2,
    description: 'Restaure des PP à une capacité.',
    price: 0,
  ),
  (
    label: 'Baie Oran',
    quantity: 5,
    description: 'Une baie à donner ou à utiliser pour récupérer des PV.',
    price: 0,
  ),
];
final _images = <String, RuntimeUiImageLease>{};
final _manifest = <Map<String, Object?>>[];
final _runtimeStages = <_RuntimeStagePainter>[];
late String _assets;
late MemoryImage _brandLogo;

bool _includes(String filter, String value) =>
    filter.isEmpty ||
    filter.split(',').map((part) => part.trim()).contains(value);
bool _controller(String mode) =>
    mode.contains('controller') || mode.startsWith('thor');
EdgeInsets _safePadding(String mode) => mode.startsWith('portrait')
    ? const EdgeInsets.only(top: 32, bottom: 24)
    : mode.startsWith('landscape')
    ? const EdgeInsets.fromLTRB(44, 12, 44, 20)
    : EdgeInsets.zero;

void main() {
  if (!_enabled) {
    test(
      'Ligue reference capture is opt-in',
      () {},
      skip: 'Set both LIGUE_REFERENCE_ROOT and LIGUE_CAPTURE_ROOT to export local reference captures.',
    );
    return;
  }
  setUpAll(() async {
    if (!p.isAbsolute(_referenceRoot) || !p.isAbsolute(_captureRoot)) {
      throw ArgumentError('Ligue capture roots must be absolute paths.');
    }
    final root = Directory(_referenceRoot).resolveSymbolicLinksSync();
    _assets = File(p.join(root, 'world.png')).existsSync()
        ? root
        : p.join(root, 'assets');
    _brandLogo = MemoryImage(
      await File(p.join(_assets, 'eclipse.png')).readAsBytes(),
    );
    await Directory(_captureRoot).create(recursive: true);
    final font = ByteData.sublistView(
      await File(p.join(_assets, 'dm-sans.ttf')).readAsBytes(),
    );
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final family in ['packages/map_player_ui/PokeMapSplashDMSans']) {
      await (FontLoader(family)..addFont(Future.value(font))).load();
    }
  });
  tearDownAll(() async {
    for (final stage in _runtimeStages) {
      stage.dispose();
    }
    _runtimeStages.clear();
    for (final lease in _images.values) {
      lease.dispose();
    }
    _images.clear();
    await _writeManifest();
  });
  for (final mode in _modes.entries.where(
    (entry) => _includes(_modeFilter, entry.key),
  )) {
    for (final dark in [false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('Ligue reference ${mode.key} $theme', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = mode.value;
        addTearDown(tester.view.reset);
        if (_images.isEmpty) {
          for (final name in [
            'world',
            'region',
            'leo',
            'battle-ligue',
            for (final species in _species) '$species-front',
            'bulbasaur-back',
          ]) {
            final path = p.join(_assets, '$name.png');
            _images[path] = (await tester.runAsync(
              () => loadRuntimeUiImageFromFilePath(path),
            ))!;
          }
        }
        for (final section in _sections) {
          final screen = switch (section) {
            RuntimePlayerPauseSection.root => 'pause.root',
            RuntimePlayerPauseSection.party => 'party.list',
            RuntimePlayerPauseSection.bag => 'bag.list',
            RuntimePlayerPauseSection.pokedex => 'dex.list',
            RuntimePlayerPauseSection.map => 'map.view',
            RuntimePlayerPauseSection.profile => 'profile.card',
            RuntimePlayerPauseSection.options =>
              _captureVariants &&
                      _includes(_screenFilter, 'options.general-long')
                  ? 'options.general-long'
                  : 'options.categories',
            RuntimePlayerPauseSection.quests => 'quests.list',
            RuntimePlayerPauseSection.contacts => 'contacts.list',
          };
          if (!_includes(_screenFilter, screen) &&
              !(section == RuntimePlayerPauseSection.party &&
                  _includes(_screenFilter, 'pokemon.summary'))) {
            continue;
          }
          final harness = _Harness(
            section,
            instantDialogue: screen == 'options.general-long',
          );
          try {
            await _mount(tester, mode.key, dark, _router(harness, mode.key));
            if (_includes(_screenFilter, screen)) {
              if (section == RuntimePlayerPauseSection.options &&
                  screen == 'options.categories' &&
                  mode.key != 'thor-primary') {
                await _tap(tester, 'options-category-picker');
              }
              await _capture(
                tester,
                mode.key,
                theme,
                screen,
                source: 'RuntimePlayerSurfaceRouter',
              );
            }
            if (section == RuntimePlayerPauseSection.options &&
                (_includes(_screenFilter, 'options.general') ||
                    _includes(_screenFilter, 'options.dropdown'))) {
              if (mode.key != 'thor-primary') {
                await _tap(tester, 'options-category-general');
              }
              if (_includes(_screenFilter, 'options.general')) {
                await _capture(tester, mode.key, theme, 'options.general',
                    source: 'RuntimePlayerSurfaceRouter');
              }
              if (mode.key != 'thor-primary' &&
                  _includes(_screenFilter, 'options.dropdown')) {
                await _tap(tester, 'options-text-speed-choice');
                await _capture(tester, mode.key, theme, 'options.dropdown',
                    source: 'RuntimePlayerSurfaceRouter');
                await _tap(tester, 'options-choice-back');
              }
            }
            if (section == RuntimePlayerPauseSection.party &&
                _includes(_screenFilter, 'pokemon.summary')) {
              if (mode.key != 'thor-primary') {
                await _tap(tester, 'party-member-member0');
              }
              await _capture(
                tester,
                mode.key,
                theme,
                'pokemon.summary',
                source:
                    'RuntimePlayerSurfaceRouter > PlayerPokemonSummarySheet',
              );
            }
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
            harness.dispose();
          }
        }
        for (final service in [
          'pc.box',
          'shop.buy',
          if (_captureVariants) 'pc.box-filled',
        ]) {
          if (!_includes(_screenFilter, service)) continue;
          await _mount(
            tester,
            mode.key,
            dark,
            mode.key == 'thor-primary'
                ? _image('world')
                : service.startsWith('pc.box')
                ? PlayerPcOverlay(
                    snapshot: _pcSnapshot(filled: service == 'pc.box-filled'),
                    onCommand: (_) {},
                  )
                : PlayerShopOverlay(
                    snapshot: _shopSnapshot(),
                    onCommand: (_) {},
                  ),
          );
          await _capture(
            tester,
            mode.key,
            theme,
            service,
            source: service.startsWith('pc.box')
                ? 'PlayerPcOverlay'
                : 'PlayerShopOverlay',
          );
        }
        for (final screen in [
          'dialogue.line',
          'dialogue.choices',
          'interaction.confirmation',
          'interaction.text',
          'interaction.selection',
        ]) {
          if (!_includes(_screenFilter, screen)) continue;
          final choice = screen == 'dialogue.choices';
          final prompt = SceneInteractionPrompt(
            localizationKey: 'ligue.dialogue',
            fallbackText: 'Le sentier traverse la forêt. Prends le temps de préparer ton équipe avant de partir !',
          );
          final request = screen == 'interaction.confirmation'
              ? SceneInteractionRequest.confirmation(
                  requestId: screen,
                  revision: 7,
                  prompt: SceneInteractionPrompt(
                    localizationKey: screen,
                    fallbackText: 'Souhaitez-vous continuer ?',
                  ),
                )
              : screen == 'interaction.text'
              ? SceneInteractionRequest.text(
                  requestId: screen,
                  revision: 7,
                  prompt: SceneInteractionPrompt(
                    localizationKey: screen,
                    fallbackText: 'Comment vous appelez-vous ?',
                  ),
                  initialValue: 'Yoahn',
                  constraints: SceneTextInputConstraints(
                    minGraphemes: 1,
                    maxGraphemes: 12,
                  ),
                )
              : screen == 'interaction.selection'
              ? SceneInteractionRequest.selection(
                  requestId: screen,
                  revision: 7,
                  prompt: SceneInteractionPrompt(
                    localizationKey: screen,
                    fallbackText: 'Choisissez entre un et deux compagnons.',
                  ),
                  constraints: SceneSelectionConstraints(
                    minSelections: 1,
                    maxSelections: 2,
                  ),
                  options: [
                    for (final name in [
                      'Bulbi',
                      'Salamèche',
                      'Carapuce',
                      'Pikachu',
                    ])
                      SceneInteractionOption(
                        id: name,
                        label: SceneInteractionPrompt(
                          localizationKey: name,
                          fallbackText: name,
                        ),
                      ),
                  ],
                )
              : choice
              ? SceneInteractionRequest.choice(
                  requestId: screen,
                  revision: 7,
                  prompt: prompt,
                  options: [
                    SceneInteractionOption(
                      id: 'yes',
                      label: SceneInteractionPrompt(
                        localizationKey: 'ligue.yes',
                        fallbackText: 'Oui, allons-y !',
                      ),
                    ),
                    SceneInteractionOption(
                      id: 'no',
                      label: SceneInteractionPrompt(
                        localizationKey: 'ligue.no',
                        fallbackText: 'Pas maintenant',
                      ),
                    ),
                  ],
                )
              : SceneInteractionRequest.message(
                  requestId: screen,
                  revision: 7,
                  speakerName: 'Léa',
                  prompt: prompt,
                );
          await _mount(
            tester,
            mode.key,
            dark,
            Stack(
              fit: StackFit.expand,
              children: [
                _image('world'),
                if (mode.key != 'thor-primary')
                  if (choice)
                    PlayerDialogueSurface(
                      data: PlayerDialogueViewData(
                        revision: 7,
                        mode: PlayerDialogueMode.choices,
                        speaker: 'Léa',
                        text: prompt.fallbackText!,
                        fullText: prompt.fallbackText!,
                        isCurrentLineFullyRevealed: true,
                        isLastContent: true,
                        choices: const [
                          PlayerDialogueChoiceViewData(
                            index: 0,
                            label: 'Oui, allons-y !',
                            selected: true,
                          ),
                          PlayerDialogueChoiceViewData(
                            index: 1,
                            label: 'Pas maintenant',
                            selected: false,
                          ),
                        ],
                      ),
                      onAction: (_) {},
                    )
                  else
                    PlayerSceneInteractionSurface(
                      request: request,
                      onResult: (_) {},
                    ),
              ],
            ),
          );
          await tester.pump(const Duration(seconds: 6));
          await tester.pumpAndSettle();
          await _capture(
            tester,
            mode.key,
            theme,
            screen,
            source: 'PlayerSceneInteractionSurface',
            limitations: mode.key == 'thor-companion'
                ? [
                    'Narrative widgets are composed in ready companion ownership; transport acknowledgement and stale-command rejection are tested separately.',
                  ]
                : [],
          );
        }
        final titleScreen =
            _captureVariants && _includes(_screenFilter, 'title.continue-save')
            ? 'title.continue-save'
            : 'title.menu';
        if (_includes(_screenFilter, titleScreen)) {
          await _mount(
            tester,
            mode.key,
            dark,
            PlayerTitleScreen(
              sceneOnly: mode.key == 'thor-primary',
              data: PlayerTitleViewData(
                gameTitle: 'Les Clairières',
                author: 'Avelune',
                description: 'Une aventure à votre rythme',
                backgroundContent: _image('world'),
                continueSave: titleScreen == 'title.continue-save'
                    ? PlayerSaveSummary(
                        address: SaveSlotAddress(
                          gameId: 'com.avelune.clairieres',
                          profileId: 'yoahn',
                          slotId: '1',
                        ),
                        updatedAt: DateTime.utc(2026, 10, 25),
                        playTimeSeconds: 9240,
                        status: SaveStatus.active,
                        canContinue: true,
                        locationLabel: 'Clairière des Sources',
                      )
                    : null,
                actions: {
                  for (final action in const [
                    PlayerTitleMenuAction.continueGame,
                    PlayerTitleMenuAction.newGame,
                    PlayerTitleMenuAction.options,
                    PlayerTitleMenuAction.creditsAbout,
                    PlayerTitleMenuAction.returnToHub,
                  ])
                    action: PlayerActionAvailability.enabled,
                },
              ),
              onSelected: (_) {},
            ),
          );
          await _capture(
            tester,
            mode.key,
            theme,
            titleScreen,
            source: 'PlayerTitleScreen',
            limitations: [
              if (mode.key.startsWith('thor')) 'Direct widget composition; remote title ownership is tested separately.',
            ],
          );
        }
        for (final screen in const [
          'session.loading',
          'session.result',
          'session.credits',
          'session.error',
          'save.exit',
          'save.recovery',
          'heal.confirm',
          'heal.result',
          'trade.select-first',
          'trade.review',
          'gift.received',
        ]) {
          if (!_includes(_screenFilter, screen)) continue;
          final saveState = ValueNotifier(
            RuntimePlayerSnapshot(
              revision: 7,
              phase: RuntimePlayerPhase.paused,
              gameTitle: 'Les Clairières',
              activeSaveAddress: const RuntimePlayerSaveAddress(
                gameId: 'com.avelune.clairieres',
                profileId: 'yoahn',
                slotId: '1',
              ),
              actions: const [
                RuntimePlayerActionAvailability.enabled(
                  RuntimePlayerAction.save,
                ),
                RuntimePlayerActionAvailability.enabled(
                  RuntimePlayerAction.returnToTitle,
                ),
              ],
            ),
          );
          try {
            await _mount(
              tester,
              mode.key,
              dark,
              Stack(
                fit: StackFit.expand,
                children: [
                  _image('world'),
                  if (mode.key != 'thor-primary' && screen != 'save.exit')
                    _supplementalSurface(screen, saveState),
                ],
              ),
            );
            if (screen == 'save.exit' && mode.key != 'thor-primary') {
              unawaited(
                showDialog<void>(
                  context: tester.element(find.byType(Scaffold)),
                  builder: (context) => PlayerInputScope(
                    activeInputSource: _controller(mode.key)
                        ? PlayerInputSource.controller
                        : PlayerInputSource.touch,
                    child: _supplementalSurface(screen, saveState),
                  ),
                ),
              );
              await tester.pumpAndSettle();
            }
            if (screen == 'session.loading' && mode.key != 'thor-primary') {
              await tester.runAsync(
                () => precacheImage(
                  ResizeImage(_brandLogo, width: 256),
                  tester.element(find.byType(PlayerWorldLoadingSurface)),
                ),
              );
              await tester.pumpAndSettle();
            }
            await _capture(
              tester,
              mode.key,
              theme,
              screen,
              source: 'Public native session and world-service widgets',
              limitations: [
                'Synthetic service state; no save or service mutation is executed.',
                if (mode.key.startsWith('thor')) 'Direct widget composition; remote ownership for this service is not certified.',
                if (screen.startsWith('heal') || screen.startsWith('trade')) 'The canonical service exposes text identity without a sprite projection.',
              ],
            );
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
            saveState.dispose();
          }
        }
        for (final screen in [
          'battle.root',
          'battle.fight',
          'battle.turn',
          'postbattle.victory',
          'postbattle.moveLearningPrompt',
          'battle.bag',
          'battle.party',
          'battle.target',
          'battle.medicine-target',
          'battle.medicine-move',
          'battle.forced-replacement',
        ]) {
          if (!_includes(_screenFilter, screen)) continue;
          final collection = switch (screen) {
            'battle.bag' => BattleCommandOverlayMode.bag,
            'battle.party' ||
            'battle.forced-replacement' => BattleCommandOverlayMode.pokemon,
            'battle.target' => BattleCommandOverlayMode.moveTarget,
            'battle.medicine-target' =>
              BattleCommandOverlayMode.bagMedicineTarget,
            'battle.medicine-move' =>
              BattleCommandOverlayMode.bagMedicineMoveTarget,
            _ => null,
          };
          final forced = screen == 'battle.forced-replacement';
          final moves =
              screen == 'battle.fight' || screen == 'battle.medicine-move';
          final busy = screen == 'battle.turn';
          final afterBattle = screen.startsWith('postbattle.');
          final decision = screen == 'postbattle.moveLearningPrompt';
          final placement = mode.key.startsWith('thor')
              ? BattleCommandPanelPlacement.detached
              : mode.key == 'landscape-controller' ||
                    (mode.key == 'landscape-touch' &&
                        collection != null &&
                        !moves)
              ? BattleCommandPanelPlacement.end
              : BattleCommandPanelPlacement.bottom;
          final size = mode.key == 'thor-companion'
              ? const Size(768, 432)
              : mode.value;
          final layout = BattleSceneLayout.forViewport(
            viewportSize: size,
            safePadding: _safePadding(mode.key),
            commandPanelPlacement: placement,
            commandPanelMode:
                collection ??
                (decision
                    ? BattleCommandOverlayMode.decision
                    : busy || afterBattle
                    ? BattleCommandOverlayMode.continueOnly
                    : moves
                    ? BattleCommandOverlayMode.fight
                    : BattleCommandOverlayMode.root),
            controllerLayout:
                _controller(mode.key) || mode.key == 'portrait-touch',
            portraitTouchLayout: mode.key == 'portrait-touch',
          );
          final recordMotion =
              _battleMotion &&
              mode.key == 'portrait-touch' &&
              !dark &&
              (screen == 'battle.root' || screen == 'battle.fight');
          await _mount(
            tester,
            mode.key,
            dark,
            Stack(
              fit: StackFit.expand,
              children: [
                if (mode.key != 'thor-companion')
                  await _runtimeStage(
                    tester,
                    layout,
                    doubles: screen == 'battle.target',
                    hideEnemy: afterBattle,
                    hidePlayer: forced,
                  ),
                PlayerBattleOverlay(
                  controllerFamily: PlayerControllerFamily.xbox,
                  snapshot: _battleSnapshot(
                    size,
                    layout,
                    moves,
                    busy: busy,
                    forced: forced,
                    extraMode: collection,
                    postBattleKind: afterBattle
                        ? (decision ? 'decision' : 'victory')
                        : null,
                    placement: placement,
                    controllerLayout:
                        _controller(mode.key) || mode.key == 'portrait-touch',
                    portraitTouchLayout: mode.key == 'portrait-touch',
                  ),
                  display: mode.key == 'thor-primary'
                      ? PlayerBattleDisplay.hudOnly
                      : mode.key == 'thor-companion'
                      ? PlayerBattleDisplay.commandsOnly
                      : PlayerBattleDisplay.full,
                  onCommand: (_) {},
                ),
              ],
            ),
            settle: !recordMotion,
          );
          if (recordMotion) await _captureBattleMotion(tester, screen);
          await _capture(
            tester,
            mode.key,
            theme,
            screen,
            source:
                'PlayerBattleOverlay > PlayerBattleSurface; BattleSceneLayout',
            limitations: [
              if (_threeMoves && moves) 'Three-move fixture matching the entry count in the reported phone photos.',
              if (_widePhone && mode.key.startsWith('landscape')) 'Wide viewport of 1280 × 590 matching the supplied image proportions; this does not establish the phone logical viewport or device pixel ratio.',
              if (afterBattle) 'Uses the production in-scene narration and decision overlay path; the isolated PlayerPostBattleOverlay component is not used.',
              'Real Flame backdrop and combatant paint methods are composed with runtime layout, using reference assets; game loop, turn choreography and physical device execution are not exercised.',
            ],
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        for (final stage in _runtimeStages) {
          stage.dispose();
        }
        _runtimeStages.clear();
        await tester.runAsync(_writeManifest);
      });
    }
  }
}

Widget _supplementalSurface(
  String screen,
  ValueNotifier<RuntimePlayerSnapshot> saveState,
) {
  final healed = screen == 'heal.result';
  final tradeReview = screen == 'trade.review';
  final snapshot = RuntimeWorldServiceSnapshot(
    revision: 7,
    stage: healed
        ? RuntimeWorldServiceStage.completed
        : RuntimeWorldServiceStage.active,
    request: screen.startsWith('heal')
        ? const OpenHealService(interactionId: 'nurse')
        : const OpenPartyTradeService(interactionId: 'trade'),
    content: screen.startsWith('heal')
        ? RuntimeHealServiceContent(
            title: healed
                ? 'Votre équipe est en pleine forme !'
                : 'Soigner votre équipe ?',
            message: healed
                ? 'Les PV, les PP et les altérations de statut ont été restaurés.'
                : 'Nous pouvons restaurer les PV et les PP de vos compagnons.',
            wasHealed: healed,
            members: [
              for (var i = 0; i < 6; i++)
                RuntimeHealPartyMemberSnapshot(
                  partyIndex: i,
                  label: _speciesLabels[i],
                  currentHp: healed ? 48 : 32,
                  maxHp: 48,
                  hasStatus: !healed && i == 1,
                  depletedMoveCount: healed ? 0 : 1,
                ),
            ],
          )
        : RuntimePartyTradeServiceContent(
            phase: tradeReview
                ? RuntimePartyTradePhase.review
                : RuntimePartyTradePhase.selectFirst,
            firstIndividualId: tradeReview ? 'member0' : null,
            partnerIndividualId: tradeReview ? 'member1' : null,
            members: [
              for (var i = 0; i < 6; i++)
                RuntimePartyTradePokemonSnapshot(
                  individualId: 'member$i',
                  speciesId: _species[i],
                  label: _speciesLabels[i],
                  level: 16,
                ),
            ],
          ),
    actions: [
      RuntimeWorldServiceActionAvailability.enabled(
        healed
            ? RuntimeWorldServiceAction.close
            : screen == 'trade.select-first'
            ? RuntimeWorldServiceAction.select
            : RuntimeWorldServiceAction.confirm,
      ),
      if (!healed)
        const RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.cancel,
        ),
    ],
  );
  return switch (screen) {
    'session.loading' => PlayerWorldLoadingSurface(
      gameTitle: 'Les Clairières',
      logo: _brandLogo,
      stage: 'Préparation de votre aventure…',
      progress: .65,
      onCancel: () {},
    ),
    'session.result' => PlayerResultSurface(
      title: 'Fin de l’aventure',
      summary: 'Vous avez terminé cette aventure.',
      details: const ['Votre progression a été conservée.'],
      onShowCredits: () {},
    ),
    'session.credits' => PlayerCreditsSurface(
      title: 'Les Clairières',
      author: 'Avelune',
      contributors: const ['Création et développement · Yoahn'],
      licenses: const [
        'Les crédits des ressources sont fournis par le projet.',
      ],
      onReturnToTitle: () {},
      onReturnToHub: () {},
    ),
    'session.error' => PlayerErrorSurface(
      title: 'Le chargement a échoué',
      message: 'La partie n’a pas pu être ouverte.',
      recommendation: 'Réessayez ou revenez à votre bibliothèque.',
      onRetry: () {},
      onReturnToHub: () {},
    ),
    'save.exit' => PlayerMenuThemeScope(
      child: PlayerSaveDialog(
        snapshot: saveState,
        onSave: () async => _accepted,
        onReceiptShown: (_) {},
        returnToTitle: screen == 'save.exit',
        onDiscard: () async => _accepted,
      ),
    ),
    'save.recovery' => PlayerSaveRecoverySurface(
      diagnostic: const SaveLoadDiagnostic(
        code: SaveLoadFailureCode.unreadable,
        expectedSchemaVersion: 1,
        recommendedActions: [
          SaveRecoveryAction.retry,
          SaveRecoveryAction.returnToTitle,
          SaveRecoveryAction.deleteSave,
        ],
      ),
      onAction: (_) {},
    ),
    'heal.confirm' || 'heal.result' => PlayerHealConfirmation(
      snapshot: snapshot,
      onCommand: (_) {},
    ),
    'trade.select-first' || 'trade.review' => PlayerPartyTradeOverlay(
      snapshot: snapshot,
      onCommand: (_) {},
    ),
    'gift.received' => PlayerPokemonGiftOverlay(
      snapshot: _giftSnapshot(),
      onCommand: (_) {},
    ),
    _ => const SizedBox.shrink(),
  };
}

RuntimeWorldServiceSnapshot _giftSnapshot() {
  final interaction = SceneChoiceInteractionRequest(
    requestId: 'gift',
    revision: 7,
    prompt: SceneInteractionPrompt(localizationKey: 'pokemonGift.received'),
    options: [
      for (final id in ['continue', 'nickname'])
        SceneInteractionOption(
          id: id,
          label: SceneInteractionPrompt(localizationKey: 'pokemonGift.$id'),
        ),
    ],
  );
  return RuntimeWorldServiceSnapshot(
    revision: 7,
    stage: RuntimeWorldServiceStage.active,
    request: OpenPokemonGiftInteractionService(
      interactionId: 'gift',
      interaction: interaction,
      stage: PokemonGiftInteractionStage.received,
      pokemon: const PlayerPokemon(
        speciesId: 'bulbasaur',
        nickname: 'Bulbi',
        level: 16,
        natureId: 'hardy',
        abilityId: 'overgrow',
        currentHp: 48,
      ),
      projectedState: const GameState(saveId: 'gift'),
      speciesName: 'Bulbizarre',
      isNewPokedexEntry: true,
      pokedexDetail: _detail(RuntimePlayerPauseSection.pokedex, empty: false),
    ),
    content: interaction,
    actions: const [
      RuntimeWorldServiceActionAvailability.enabled(
        RuntimeWorldServiceAction.confirm,
      ),
      RuntimeWorldServiceActionAvailability.enabled(
        RuntimeWorldServiceAction.cancel,
      ),
    ],
  );
}

Widget _image(String name, {BoxFit fit = BoxFit.cover}) => RawImage(
  image: _images[p.join(_assets, '$name.png')]!.image,
  fit: fit,
  filterQuality: FilterQuality.none,
);

Future<Widget> _runtimeStage(
  WidgetTester tester,
  BattleSceneLayout layout, {
  bool doubles = false,
  bool hideEnemy = false,
  bool hidePlayer = false,
}) async {
  final playerGeometry = layout.combatantGeometry(
    const BattleSlotRef.active(BattleSideId.player),
    doubles: doubles,
  );
  final enemyGeometry = layout.combatantGeometry(
    const BattleSlotRef.active(BattleSideId.enemy),
    doubles: doubles,
  );
  final secondGeometry = layout.combatantGeometry(
    const BattleSlotRef(side: BattleSideId.enemy, slotIndex: 1),
    doubles: true,
  );
  final cache = BattleVisualAssetCache(
    imageLoader: (path) async => _images[path]!.image.clone(),
  );
  final player = BattleSceneCombatantComponent(
    sceneSpriteRect: playerGeometry.spriteRect,
    scenePlatformRect: playerGeometry.platformRect,
    sceneFootAnchor: playerGeometry.footAnchor,
    spriteFootXRatio: .68,
    isPlayerSide: true,
    speciesLabel: 'Bulbi',
    visualAssetCache: cache,
    initialSpriteSpec: BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.back,
      explicitImageAbsolutePath: p.join(_assets, 'bulbasaur-back.png'),
    ),
  );
  final enemy = BattleSceneCombatantComponent(
    sceneSpriteRect: enemyGeometry.spriteRect,
    scenePlatformRect: enemyGeometry.platformRect,
    sceneFootAnchor: enemyGeometry.footAnchor,
    spriteFootXRatio: .5,
    isPlayerSide: false,
    speciesLabel: 'Roucool',
    visualAssetCache: cache,
    initialSpriteSpec: BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
      explicitImageAbsolutePath: p.join(_assets, 'pidgey-front.png'),
    ),
  );
  final additional = <BattleSceneCombatantComponent>[
    if (doubles)
      BattleSceneCombatantComponent(
        sceneSpriteRect: secondGeometry.spriteRect,
        scenePlatformRect: secondGeometry.platformRect,
        sceneFootAnchor: secondGeometry.footAnchor,
        isPlayerSide: false,
        spriteFootXRatio: .5,
        speciesLabel: 'Pikachu',
        visualAssetCache: cache,
        initialSpriteSpec: BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.front,
          explicitImageAbsolutePath: p.join(_assets, 'pikachu-front.png'),
        ),
      ),
  ];
  final backdrop = BattleSceneBackdropComponent(
    size: player.size.clone()
      ..setValues(layout.viewportSize.width, layout.viewportSize.height),
    artworkRect: layout.backdropArtworkRect,
    visualAssetCache: cache,
    backgroundSpec: BattleBackgroundSpec.explicitImage(
      fallbackKey: BattleBackgroundKey.wildOutdoor,
      absolutePath: p.join(_assets, 'battle-ligue.png'),
    ),
  );
  await tester.runAsync(
    () => Future.wait([
      player.onLoad(),
      enemy.onLoad(),
      backdrop.onLoad(),
      for (final component in additional) component.onLoad(),
    ]),
  );
  expect(player.hasResolvedExplicitSprite, isTrue);
  expect(enemy.hasResolvedExplicitSprite, isTrue);
  expect(backdrop.hasResolvedExplicitImage, isTrue);
  if (hideEnemy) enemy.holdMaterializeHidden();
  if (hidePlayer) player.holdMaterializeHidden();
  final painter = _RuntimeStagePainter(
    cache,
    backdrop,
    player,
    enemy,
    additional,
  );
  _runtimeStages.add(painter);
  return CustomPaint(painter: painter);
}

class _RuntimeStagePainter extends CustomPainter {
  const _RuntimeStagePainter(
    this.cache,
    this.backdrop,
    this.player,
    this.enemy,
    this.additional,
  );
  final BattleVisualAssetCache cache;
  final BattleSceneBackdropComponent backdrop;
  final BattleSceneCombatantComponent player;
  final BattleSceneCombatantComponent enemy;
  final List<BattleSceneCombatantComponent> additional;

  @override
  void paint(Canvas canvas, Size size) {
    backdrop.renderTree(canvas);
    player.renderTree(canvas);
    enemy.renderTree(canvas);
    for (final component in additional) {
      component.renderTree(canvas);
    }
  }

  void dispose() {
    backdrop.onRemove();
    player.onRemove();
    enemy.onRemove();
    for (final component in additional) {
      component.onRemove();
    }
    cache.dispose();
  }

  @override
  bool shouldRepaint(_RuntimeStagePainter oldDelegate) => oldDelegate != this;
}

Future<void> _mount(
  WidgetTester tester,
  String mode,
  bool dark,
  Widget surface, {
  bool settle = true,
}) async {
  Widget body = PlayerInputScope(
    activeInputSource: _controller(mode)
        ? PlayerInputSource.controller
        : PlayerInputSource.touch,
    child: surface,
  );
  if (mode == 'thor-companion') body = PlayerCompanionScope(child: body);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: dark ? PokeMapPlayerTheme.dark() : PokeMapPlayerTheme.light(),
      builder: (context, child) => PlayerImageScope(
        identity: _images,
        loader: (path, {required isCurrent}) async {
          final image = _images[path]!.image.clone();
          return PlayerImageLease(image: image, onDispose: image.dispose);
        },
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: _safePadding(mode),
            viewPadding: _safePadding(mode),
          ),
          child: RepaintBoundary(
            key: const ValueKey('ligue-capture'),
            child: child!,
          ),
        ),
      ),
      home: Scaffold(body: SizedBox.expand(child: body)),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  }
}

Future<void> _captureBattleMotion(WidgetTester tester, String screen) async {
  final directory = Directory(p.join(_captureRoot, 'motion', screen));
  await tester.runAsync(() => directory.create(recursive: true));
  TestGesture? gesture;
  for (var frame = 0; frame < 45; frame++) {
    if (frame == 15) {
      gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('battle-entry-0'))),
      );
    }
    if (frame == 22) await gesture?.up();
    await tester.pump(const Duration(microseconds: 33333));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('ligue-capture')),
    );
    final image = (await tester.runAsync(
      () => boundary.toImage(pixelRatio: 1),
    ))!;
    try {
      final bytes = (await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      ))!;
      await tester.runAsync(
        () => File(
          p.join(directory.path, '${frame.toString().padLeft(3, '0')}.png'),
        ).writeAsBytes(bytes.buffer.asUint8List()),
      );
    } finally {
      image.dispose();
    }
  }
  expect(tester.takeException(), isNull);
}

Widget _router(_Harness harness, String mode) => RuntimePlayerSurfaceRouter(
  snapshot: harness.snapshot,
  showPlayerOverlay: mode != 'thor-primary',
  pauseRootActionsOnly: mode == 'thor-companion',
  titlePresentation: const RuntimePlayerTitlePresentation(author: ''),
  pausePresentation: PlayerPausePresentation(
    backgroundImage: MemoryImage(
      File(p.join(_assets, 'world.png')).readAsBytesSync(),
    ),
  ),
  partyNavigation: harness.party,
  bagNavigation: harness.bag,
  hardwareGamepadEnabled: _controller(mode),
  activeInputSource: _controller(mode)
      ? PlayerInputSource.controller
      : PlayerInputSource.touch,
  gameSceneBuilder: (_) => _image('world'),
  onAction: (action) async {
    harness.actions.add(action);
    return _accepted;
  },
  onPauseCommand: (_) {},
  onPreferencesChanged: harness.preferenceChanges.add,
  onFavoriteChanged: (_, _) async {},
  onControlProfileChanged: (_) {},
  onReturnToTitle: (_) async => _accepted,
);

Future<void> _capture(
  WidgetTester tester,
  String mode,
  String theme,
  String screen, {
  required String source,
  List<String> limitations = const [],
}) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
  final errors = <String>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    errors.add(error.toString());
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('ligue-capture')),
  );
  final image = (await tester.runAsync(() => boundary.toImage(pixelRatio: 1)))!;
  try {
    final data = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    ))!;
    final name = '$screen-$mode-$theme.png';
    await tester.runAsync(
      () =>
          File(p.join(_captureRoot, name))
              .writeAsBytes(data.buffer.asUint8List()),
    );
    final insets = _safePadding(mode);
    _manifest.add({
      'file': name,
      'screen': screen,
      'mode': mode,
      'theme': theme,
      'viewport': {
        'width': image.width,
        'height': image.height,
        'devicePixelRatio': 1,
        'safeInsets': {
          'top': insets.top,
          'right': insets.right,
          'bottom': insets.bottom,
          'left': insets.left,
        },
      },
      'source': source,
      'snapshotRevision':
          (screen.startsWith('title.') ||
              screen.startsWith('session.') ||
              screen == 'save.recovery'
          ? null
          : (screen == 'options.general-long' ||
                    const [
                      'pause.root',
                      'party.list',
                      'pokemon.summary',
                      'bag.list',
                      'map.view',
                      'dex.list',
                      'profile.card',
                      'options.categories',
                      'quests.list',
                      'contacts.list',
                    ].contains(screen)
                ? 1
                : 7)),
      'referenceRoot': _referenceRoot,
      'assetsRoot': _assets,
      'reference': 'Ligue 26 HTML atlas; synthetic public snapshots using its demo identities, inventory, health and provided artwork.',
      'provenance': 'Current real Flutter widgets mounted with WidgetTester; not a physical-device or running native-app capture.',
      'limits': [
        'Fixture commands are recorded or ignored; no gameplay mutation or save persistence is certified.',
        if (mode == 'thor-primary' &&
            !screen.startsWith('battle') &&
            !screen.startsWith('dialogue'))
          'Owner scene only while companion owns menu/service controls.',
        if (screen.startsWith('pc') || screen.startsWith('shop')) 'Service widgets are mounted directly; remote service transport is not exercised.',
        ...limitations,
      ],
      'exceptions': errors,
    });
    await tester.runAsync(_writeManifest);
    expect(
      errors,
      isEmpty,
      reason: '$screen $mode $theme capture raised Flutter exceptions',
    );
    expect(Size(image.width.toDouble(), image.height.toDouble()), _modes[mode]);
  } finally {
    image.dispose();
  }
}

Future<void> _writeManifest() => File(p.join(_captureRoot, 'manifest.json'))
    .writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schemaVersion': 1,
        'design': 'Ligue 26',
        'captureCount': _manifest.length,
        'captures': _manifest,
      }),
    );

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  for (
    var index = 0;
    index < 20 && finder.hitTestable().evaluate().isEmpty;
    index++
  ) {
    final next = find.byKey(const ValueKey('player-page-next')).hitTestable();
    if (next.evaluate().isEmpty) break;
    await tester.tap(next.first);
    await tester.pumpAndSettle();
  }
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

RuntimeWorldServiceSnapshot _shopSnapshot() => RuntimeWorldServiceSnapshot(
  revision: 7,
  request: const OpenShopService(
    interactionId: 'reference.merchant',
    shopId: 'reference.shop',
  ),
  stage: RuntimeWorldServiceStage.active,
  content: RuntimeShopServiceContent(
    title: 'Boutique',
    message: 'Que souhaitez-vous acheter ?',
    money: 3250,
    entries: [
      for (var i = 0; i < 4; i++)
        RuntimeShopEntrySnapshot(
          itemId: 'item$i',
          label: _items[i].label,
          unitPrice: _items[i].price,
          remainingStock: 99,
        ),
    ],
    selectedItemId: 'item0',
    quantity: 3,
    totalPrice: 900,
  ),
  actions: const [
    RuntimeWorldServiceActionAvailability.enabled(
      RuntimeWorldServiceAction.showPurchases,
    ),
    RuntimeWorldServiceActionAvailability.enabled(
      RuntimeWorldServiceAction.showSales,
    ),
    RuntimeWorldServiceActionAvailability.enabled(
      RuntimeWorldServiceAction.select,
    ),
    RuntimeWorldServiceActionAvailability.enabled(
      RuntimeWorldServiceAction.increaseQuantity,
    ),
    RuntimeWorldServiceActionAvailability.enabled(
      RuntimeWorldServiceAction.decreaseQuantity,
    ),
    RuntimeWorldServiceActionAvailability.enabled(
      RuntimeWorldServiceAction.confirm,
    ),
    RuntimeWorldServiceActionAvailability.enabled(
      RuntimeWorldServiceAction.close,
    ),
  ],
);

final class _Harness {
  _Harness(
    RuntimePlayerPauseSection section, {
    bool empty = false,
    bool instantDialogue = false,
  }) : snapshot = RuntimePlayerSnapshot(
         revision: 1,
         phase: RuntimePlayerPhase.paused,
         gameTitle: 'Les Clairières',
         pauseSection: section,
         activeSaveAddress: const RuntimePlayerSaveAddress(
           gameId: 'com.avelune.clairieres',
           profileId: 'player',
           slotId: 'slot-1',
         ),
         preferences: PlayerPreferencesSnapshot(
           locale: 'fr',
           accessibility: const GameSessionAccessibilityOptions(),
           dialogueTextSpeed: instantDialogue
               ? RuntimeDialogueTextSpeed.instant
               : RuntimeDialogueTextSpeed.normal,
         ),
         favoriteItemIds: const {'item0'},
         bagFavoritesAvailable: true,
         actions: [
           for (final action in RuntimePlayerAction.values)
             RuntimePlayerActionAvailability.enabled(action),
         ],
         pauseDetails: {
           for (final detailSection in _sections)
             if (detailSection != RuntimePlayerPauseSection.root &&
                 detailSection != RuntimePlayerPauseSection.options)
               detailSection: _detail(detailSection, empty: empty),
         },
       );

  final RuntimePlayerSnapshot snapshot;
  final actions = <RuntimePlayerAction>[];
  final preferenceChanges = <PlayerPreferencesSnapshot>[];
  final party = RuntimePlayerPartyNavigation();
  final bag = RuntimePlayerBagNavigation();

  void dispose() {
    party.dispose();
    bag.dispose();
  }
}

String _title(RuntimePlayerPauseSection section) => switch (section) {
  RuntimePlayerPauseSection.root => 'Menu',
  RuntimePlayerPauseSection.party => 'Équipe',
  RuntimePlayerPauseSection.bag => 'Sac',
  RuntimePlayerPauseSection.pokedex => 'Pokédex',
  RuntimePlayerPauseSection.map => 'Carte',
  RuntimePlayerPauseSection.profile => 'Profil',
  RuntimePlayerPauseSection.options => 'Options',
  RuntimePlayerPauseSection.quests => 'Journal',
  RuntimePlayerPauseSection.contacts => 'Contacts',
};

RuntimePlayerPauseDetailSnapshot _detail(
  RuntimePlayerPauseSection section, {
  required bool empty,
}) => RuntimePlayerPauseDetailSnapshot(
  section: section,
  title: _title(section),
  entries: empty
      ? []
      : switch (section) {
          RuntimePlayerPauseSection.party => List.generate(6, (i) {
            final summary = RuntimePokemonSummarySnapshot(
              targetId: 'pokemon.$i',
              individualId: 'member$i',
              speciesLabel: _speciesLabels[i],
              nickname: [
                'Bulbi',
                'Salamèche',
                'Carapuce',
                'Pikachu',
                'Évoli',
                'Roucool',
              ][i],
              media: RuntimePokemonSummaryMediaSnapshot(
                thumbnail: RuntimePokemonLocalImageSnapshot(
                  absoluteFilePath: '$_assets/${_species[i]}-front.png',
                  sampling: ProjectMenuImageSampling.pixelArt,
                ),
                illustration: RuntimePokemonLocalImageSnapshot(
                  absoluteFilePath: '$_assets/${_species[i]}-front.png',
                  sampling: ProjectMenuImageSampling.pixelArt,
                ),
              ),
              stats: const RuntimePokemonStatsSummarySnapshot(
                attack: 28,
                defense: 30,
                specialAttack: 36,
                specialDefense: 34,
                speed: 26,
              ),
              provenance: const RuntimePokemonProvenanceSummarySnapshot(
                originLabel: 'Capturé',
                metMapLabel: 'Route 2',
                metLevel: 5,
                ballLabel: 'Poké Ball',
              ),
              level: [16, 15, 14, 13, 12, 11][i],
              currentHp: [32, 41, 25, 18, 0, 35][i],
              maxHp: [48, 41, 43, 36, 39, 35][i],
              heldItemLabel: i == 0 ? 'Baie Oran' : 'Aucun',
              statusLabel: i == 3
                  ? 'PAR'
                  : i == 4
                  ? 'K.O.'
                  : null,
              natureLabel: 'Modeste',
              abilityLabel: [
                'Engrais',
                'Brasier',
                'Torrent',
                'Statik',
                'Fuite',
                'Regard Vif',
              ][i],
              friendship: 80,
              typeIds: _types[i],
              moves: List.generate(
                4,
                (move) => RuntimePokemonMoveSummarySnapshot(
                  moveId: 'move$move',
                  label: [
                    'Fouet Lianes',
                    'Charge',
                    'Vampigraine',
                    'Poudre Dodo',
                  ][move],
                  typeId: move == 1 ? 'normal' : 'grass',
                  currentPp: [22, 30, 10, 0][move],
                  maxPp: [25, 35, 10, 15][move],
                ),
              ),
            );
            return RuntimePlayerDetailEntrySnapshot(
              id: summary.targetId,
              title: summary.displayLabel,
              pokemonSummary: summary,
            );
          }),
          RuntimePlayerPauseSection.quests => [
            RuntimePlayerDetailEntrySnapshot(
              id: 'forest',
              title: 'Un passage dans la forêt',
              subtitle: 'En cours · Parler au garde',
              trailingLabel: 'En cours',
            ),
            RuntimePlayerDetailEntrySnapshot(
              id: 'first',
              title: 'Le premier compagnon',
              subtitle: 'Terminé · Rencontrer le professeur',
              trailingLabel: 'Terminé',
            ),
            RuntimePlayerDetailEntrySnapshot(
              id: 'river',
              title: 'Au bord du ruisseau',
              subtitle: 'En cours · Explorer les environs',
              trailingLabel: 'En cours',
            ),
          ],
          RuntimePlayerPauseSection.contacts => [
            RuntimePlayerDetailEntrySnapshot(
              id: 'lea',
              title: 'Léa',
              subtitle: 'Disponible',
            ),
            RuntimePlayerDetailEntrySnapshot(
              id: 'professor',
              title: 'Professeur Orme',
              subtitle: 'Disponible',
            ),
            RuntimePlayerDetailEntrySnapshot(
              id: 'guard',
              title: 'Garde du pont',
              subtitle: 'Le passage sera ouvert après votre prochaine visite.',
            ),
          ],
          RuntimePlayerPauseSection.bag => List.generate(
            _items.length,
            (i) => RuntimePlayerDetailEntrySnapshot(
              id: 'bag.item$i',
              title: _items[i].label,
              bagItem: RuntimePlayerBagItemSnapshot(
                itemId: 'item$i',
                quantity: _items[i].quantity,
                sortOrder: i,
                pocketId: 'medicine',
                description: _items[i].description,
              ),
              bagAction: RuntimePlayerBagItemActionSnapshot(
                itemTargetId: 'item$i',
                targetKind: RuntimePlayerBagUseTargetKind.partyMember,
                usability: ItemUsabilityState.usable,
                isEnabled: true,
              ),
            ),
          ),
          RuntimePlayerPauseSection.pokedex => [
            for (var i = 0; i < _species.length; i++)
              RuntimePlayerDetailEntrySnapshot(
                id: _species[i],
                title: _speciesLabels[i],
                pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
                  nationalDex: [1, 4, 7, 25, 133, 16][i],
                  knowledge: i < 4
                      ? RuntimePlayerPokedexKnowledge.caught
                      : RuntimePlayerPokedexKnowledge.seen,
                  typeIds: _types[i],
                  media: RuntimePokemonSummaryMediaSnapshot(
                    thumbnail: RuntimePokemonLocalImageSnapshot(
                      absoluteFilePath: '$_assets/${_species[i]}-front.png',
                      sampling: ProjectMenuImageSampling.pixelArt,
                    ),
                    illustration: RuntimePokemonLocalImageSnapshot(
                      absoluteFilePath: '$_assets/${_species[i]}-front.png',
                      sampling: ProjectMenuImageSampling.pixelArt,
                    ),
                  ),
                  description: i == 0
                      ? 'Il porte une graine sur son dos depuis sa naissance. Elle grandit avec lui.'
                      : 'Les observations de cette espèce sont consignées dans votre Pokédex.',
                ),
              ),
            RuntimePlayerDetailEntrySnapshot(
              id: 'unknown-152',
              title: '???',
              pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
                nationalDex: 152,
                knowledge: RuntimePlayerPokedexKnowledge.unknown,
              ),
            ),
          ],
          _ => [],
        },
  bagMoney: section == RuntimePlayerPauseSection.bag ? 3250 : null,
  bagPockets: section == RuntimePlayerPauseSection.bag
      ? const [
          RuntimePlayerBagPocketSnapshot(id: 'medicine', label: 'Soins'),
          RuntimePlayerBagPocketSnapshot(id: 'balls', label: 'Balls'),
          RuntimePlayerBagPocketSnapshot(id: 'items', label: 'Objets'),
          RuntimePlayerBagPocketSnapshot(id: 'key', label: 'Objets rares'),
        ]
      : const [],
  profile: section == RuntimePlayerPauseSection.profile
      ? RuntimePlayerProfileSnapshot(
          playerName: 'Yoahn',
          currentMapId: 'private_map_id',
          money: 3250,
          locationName: empty ? null : 'Clairière des Sources',
          playtimeSeconds: empty ? null : 9240,
          portraitFilePath: empty ? null : '$_assets/leo.png',
          badgeTotal: 8,
          badgeIds: const ['forest', 'stone'],
          badges: const [
            RuntimePlayerProfileBadgeSnapshot(
              id: 'forest',
              label: 'Badge Forêt',
            ),
            RuntimePlayerProfileBadgeSnapshot(
              id: 'stone',
              label: 'Badge Pierre',
            ),
          ],
          pokedex: empty
              ? null
              : const RuntimePlayerPokedexProgressSnapshot(
                  seen: 24,
                  caught: 12,
                  total: 151,
                ),
        )
      : null,
  regionalMap: section == RuntimePlayerPauseSection.map
      ? RuntimePlayerRegionMapSnapshot(
          regions: [
            RuntimePlayerRegionSnapshot(
              id: 'region',
              label: 'Les Clairières',
              imageFilePath: empty ? null : '$_assets/region.png',
              points: empty
                  ? []
                  : List.generate(
                      2,
                      (i) => RuntimePlayerMapPointSnapshot(
                        id: 'town$i',
                        label: i == 0
                            ? 'Clairière des Sources'
                            : 'Maison du garde',
                        status: i == 0
                            ? RuntimePlayerMapPointStatus.current
                            : RuntimePlayerMapPointStatus.discovered,
                        u: i == 0 ? .5 : .65,
                        v: i == 0 ? .5 : .45,
                        description: i == 0
                            ? 'Vous vous trouvez ici. Un village calme au bord de la forêt.'
                            : 'Le garde veille sur le passage de la forêt.',
                      ),
                    ),
            ),
            RuntimePlayerRegionSnapshot(
              id: 'highlands',
              label: 'Les Hautes Terres',
              imageFilePath: empty ? null : '$_assets/region.png',
              points: const [],
            ),
          ],
        )
      : null,
);

RuntimePcPokemonSnapshot _pcPokemon(RuntimePlayerDetailEntrySnapshot entry) =>
    RuntimePcPokemonSnapshot(
      targetId: entry.id,
      label: entry.pokemonSummary!.displayLabel,
      summary: entry.pokemonSummary,
      speciesId:
          _species[int.parse(entry.pokemonSummary!.individualId.substring(6))],
      level: entry.pokemonSummary!.level,
      natureId: 'modest',
      abilityId: 'reference',
      currentHp: entry.pokemonSummary!.currentHp,
      nickname: entry.pokemonSummary!.nickname,
      friendship: entry.pokemonSummary!.friendship,
      canTransfer: true,
    );

RuntimeWorldServiceSnapshot _pcSnapshot({bool filled = false}) =>
    RuntimeWorldServiceSnapshot(
      revision: 7,
      request: const OpenPcService(
        interactionId: 'terminal.harbor',
        storageId: 'box-a',
      ),
      stage: RuntimeWorldServiceStage.active,
      content: RuntimePcServiceContent(
        title: 'PC Pokémon',
        message: 'Organisez votre équipe.',
        selectedBoxId: 'box-a',
        boxes: <RuntimePcBoxSnapshot>[
          RuntimePcBoxSnapshot(
            boxId: 'box-a',
            label: 'Boîte 1',
            count: filled ? 3 : 0,
            capacity: 30,
          ),
        ],
        party: [
          for (final entry in _detail(
            RuntimePlayerPauseSection.party,
            empty: false,
          ).entries.take(filled ? 3 : 6))
            _pcPokemon(entry),
        ],
        stored: [
          if (filled)
            for (final entry in _detail(
              RuntimePlayerPauseSection.party,
              empty: false,
            ).entries.skip(3))
              _pcPokemon(entry),
        ],
      ),
      actions: const <RuntimeWorldServiceActionAvailability>[
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.select,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.deposit,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.withdraw,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.swap,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
      ],
    );

BattleCommandOverlaySnapshot _battleSnapshot(
  Size size,
  BattleSceneLayout layout,
  bool moves, {
  bool busy = false,
  String? postBattleKind,
  BattleCommandOverlayMode? extraMode,
  bool forced = false,
  bool controllerLayout = false,
  bool portraitTouchLayout = false,
  BattleCommandPanelPlacement placement = BattleCommandPanelPlacement.bottom,
}) => BattleCommandOverlaySnapshot(
  commandPanelPlacement: placement,
  controllerLayout: controllerLayout,
  portraitTouchLayout: portraitTouchLayout,
  rootCommandOrder: const [0, 2, 1, 3],
  forcedReplacement: forced,
  phase: forced
      ? BattlePresentationPhase.forcedReplacement
      : busy
      ? BattlePresentationPhase.presentingTurn
      : BattlePresentationPhase.choosingCommand,
  revision: 7,
  mode:
      extraMode ??
      (postBattleKind == 'decision'
          ? BattleCommandOverlayMode.decision
          : postBattleKind == 'victory'
          ? BattleCommandOverlayMode.continueOnly
          : busy
          ? BattleCommandOverlayMode.continueOnly
          : moves
          ? BattleCommandOverlayMode.fight
          : BattleCommandOverlayMode.root),
  viewportSize: size,
  panelRect: layout.commandPanelRect,
  enemyHud: BattleCommandOverlayHudSnapshot(
    rect: layout
        .combatantGeometry(
          const BattleSlotRef.active(BattleSideId.enemy),
          doubles: extraMode == BattleCommandOverlayMode.moveTarget,
        )
        .hudRect,
    ownerLabel: 'ENNEMI',
    speciesLabel: 'Roucool',
    level: 12,
    currentHp: postBattleKind == null ? 27 : 0,
    maxHp: 36,
    genderSymbol: '♂',
    isPlayerSide: false,
  ),
  playerHud: BattleCommandOverlayHudSnapshot(
    rect: layout
        .combatantGeometry(
          const BattleSlotRef.active(BattleSideId.player),
          doubles: extraMode == BattleCommandOverlayMode.moveTarget,
        )
        .hudRect,
    ownerLabel: 'JOUEUR',
    speciesLabel: 'Bulbi',
    level: 16,
    currentHp: forced ? 0 : 32,
    maxHp: 48,
    genderSymbol: '♂',
    isPlayerSide: true,
    experienceProgress: 0.62,
  ),
  additionalHuds: [
    if (extraMode == BattleCommandOverlayMode.moveTarget)
      BattleCommandOverlayHudSnapshot(
        rect: layout
            .combatantGeometry(
              const BattleSlotRef(side: BattleSideId.enemy, slotIndex: 1),
              doubles: true,
            )
            .hudRect,
        ownerLabel: 'ENNEMI',
        speciesLabel: 'Pikachu',
        level: 14,
        currentHp: 30,
        maxHp: 42,
        isPlayerSide: false,
        slot: const BattleSlotRef(side: BattleSideId.enemy, slotIndex: 1),
        combatantId: 'enemy.pikachu',
      ),
  ],
  battleLabel: 'COMBAT SAUVAGE',
  title: postBattleKind == 'decision' ? 'CHOIX' : 'COMMANDES',
  prompt: postBattleKind == 'decision'
      ? 'Bulbi souhaite apprendre Tranch’Herbe.'
      : postBattleKind == 'victory'
      ? 'Vous avez remporté le combat !'
      : 'Que doit faire Bulbi ?',
  narrationLines: <String>[
    postBattleKind == 'victory'
        ? 'Vous avez remporté le combat !'
        : busy
        ? 'Bulbi utilise Fouet Lianes !'
        : 'Un Roucool sauvage apparaît !',
  ],
  entries:
      extraMode != null &&
          extraMode != BattleCommandOverlayMode.bagMedicineMoveTarget
      ? _battleCollectionEntries(extraMode, forced)
      : postBattleKind == 'decision'
      ? const [
          BattleCommandOverlayEntry(
            index: 0,
            kind: BattleCommandOverlayEntryKind.decision,
            primaryLabel: 'Apprendre',
            secondaryLabel: '',
            enabled: true,
            selected: true,
            tone: BattleCommandOverlayEntryTone.neutral,
          ),
          BattleCommandOverlayEntry(
            index: 1,
            kind: BattleCommandOverlayEntryKind.decision,
            primaryLabel: 'Ne pas apprendre',
            secondaryLabel: '',
            enabled: true,
            selected: false,
            tone: BattleCommandOverlayEntryTone.neutral,
          ),
        ]
      : postBattleKind == 'victory'
      ? const [
          BattleCommandOverlayEntry(
            index: 0,
            kind: BattleCommandOverlayEntryKind.continueAction,
            primaryLabel: 'Suite',
            secondaryLabel: '',
            enabled: true,
            selected: true,
            tone: BattleCommandOverlayEntryTone.neutral,
          ),
        ]
      : busy
      ? const []
      : moves
      ? List.generate(
          _threeMoves ? 3 : 4,
          (i) => BattleCommandOverlayEntry(
            index: i,
            kind: BattleCommandOverlayEntryKind.move,
            primaryLabel: [
              'Fouet Lianes',
              'Charge',
              'Vampigraine',
              'Poudre Dodo',
            ][i],
            secondaryLabel: i == 1 ? 'normal' : 'grass',
            tertiaryLabel: [
              'Puissance 45 · Précision 100 %',
              'Puissance 40 · Précision 100 %',
              'Puissance — · Précision 90 %',
              'Puissance — · Précision 75 %',
            ][i],
            statusLabel: [
              'Peu efficace',
              'Efficacité normale',
              'Statut',
              extraMode == BattleCommandOverlayMode.bagMedicineMoveTarget
                  ? 'Statut'
                  : 'Épuisée',
            ][i],
            trailingLabel: [
              'PP 22 / 25',
              'PP 30 / 35',
              'PP 10 / 10',
              'PP 0 / 15',
            ][i],
            enabled: extraMode == BattleCommandOverlayMode.bagMedicineMoveTarget
                ? i != 2
                : i != 3,
            selected: i == 0,
            tone:
                (extraMode == BattleCommandOverlayMode.bagMedicineMoveTarget
                    ? i == 2
                    : i == 3)
                ? BattleCommandOverlayEntryTone.disabled
                : BattleCommandOverlayEntryTone.attack,
          ),
        )
      : const <BattleCommandOverlayEntry>[
          BattleCommandOverlayEntry(
            index: 0,
            kind: BattleCommandOverlayEntryKind.root,
            primaryLabel: 'ATTAQUER',
            secondaryLabel: 'Choisir une capacité',
            enabled: true,
            selected: true,
            tone: BattleCommandOverlayEntryTone.attack,
          ),
          BattleCommandOverlayEntry(
            index: 1,
            kind: BattleCommandOverlayEntryKind.root,
            primaryLabel: 'SAC',
            secondaryLabel: 'Utiliser un objet',
            enabled: true,
            selected: false,
            tone: BattleCommandOverlayEntryTone.medicine,
          ),
          BattleCommandOverlayEntry(
            index: 2,
            kind: BattleCommandOverlayEntryKind.root,
            primaryLabel: 'ÉQUIPE',
            secondaryLabel: 'Changer de Pokémon',
            enabled: true,
            selected: false,
            tone: BattleCommandOverlayEntryTone.switching,
          ),
          BattleCommandOverlayEntry(
            index: 3,
            kind: BattleCommandOverlayEntryKind.root,
            primaryLabel: 'FUITE',
            secondaryLabel: 'Quitter le combat',
            enabled: true,
            selected: false,
            tone: BattleCommandOverlayEntryTone.neutral,
          ),
        ],
  interactionsEnabled: !busy,
  canGoBack:
      !forced &&
      (moves || extraMode != null) &&
      !busy &&
      postBattleKind == null,
);

List<BattleCommandOverlayEntry> _battleCollectionEntries(
  BattleCommandOverlayMode mode,
  bool forced,
) {
  if (mode == BattleCommandOverlayMode.bag) {
    return [
      for (var i = 0; i < 6; i++)
        BattleCommandOverlayEntry(
          index: i,
          kind: BattleCommandOverlayEntryKind.bag,
          primaryLabel: _items[i].label,
          secondaryLabel: 'Soin',
          trailingLabel: '×${_items[i].quantity}',
          enabled: true,
          selected: i == 0,
          tone: BattleCommandOverlayEntryTone.medicine,
        ),
    ];
  }
  if (mode == BattleCommandOverlayMode.moveTarget) {
    return [
      for (var i = 0; i < 2; i++)
        BattleCommandOverlayEntry(
          index: i,
          kind: BattleCommandOverlayEntryKind.target,
          primaryLabel: i == 0 ? 'Roucool' : 'Pikachu',
          secondaryLabel: i == 0 ? '27/36 PV' : '30/42 PV',
          enabled: true,
          selected: i == 0,
          tone: BattleCommandOverlayEntryTone.neutral,
        ),
    ];
  }
  final medicine = mode == BattleCommandOverlayMode.bagMedicineTarget;
  return [
    for (var i = 0; i < 6; i++)
      BattleCommandOverlayEntry(
        index: i,
        kind: medicine
            ? BattleCommandOverlayEntryKind.medicineTarget
            : BattleCommandOverlayEntryKind.party,
        primaryLabel: _speciesLabels[i],
        secondaryLabel: forced && i == 0 ? '0/48 PV' : '32/48 PV',
        trailingLabel: 'Nv. 16',
        statusLabel: i == 0
            ? (forced
                  ? 'K.O.'
                  : medicine
                  ? null
                  : 'Déjà au combat')
            : null,
        enabled: medicine || i != 0,
        selected: i == (medicine ? 0 : 1),
        tone: medicine
            ? BattleCommandOverlayEntryTone.medicine
            : i == 0
            ? BattleCommandOverlayEntryTone.disabled
            : BattleCommandOverlayEntryTone.switching,
      ),
  ];
}
