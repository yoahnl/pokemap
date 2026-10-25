import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_bag.dart';
import 'package:map_player_ui/src/player/runtime_player_party.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';
import 'package:path/path.dart' as p;

const _referenceRoot = String.fromEnvironment('LIGUE_REFERENCE_ROOT');
const _captureRoot = String.fromEnvironment('LIGUE_CAPTURE_ROOT');
const _screenFilter = String.fromEnvironment('LIGUE_CAPTURE_SCREENS');
const _modeFilter = String.fromEnvironment('LIGUE_CAPTURE_MODES');
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
  'landscape-touch': Size(844, 390),
  'landscape-controller': Size(844, 390),
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
late String _assets;

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
    await Directory(_captureRoot).create(recursive: true);
    final font = ByteData.sublistView(
      await File(p.join(_assets, 'dm-sans.ttf')).readAsBytes(),
    );
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final family in [
      'packages/map_player_ui/PokeMapSplashDMSans',
      'Aube Display',
      'Avenir Next',
    ]) {
      await (FontLoader(family)..addFont(Future.value(font))).load();
    }
  });
  tearDownAll(() async {
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
            RuntimePlayerPauseSection.options => 'options.categories',
            RuntimePlayerPauseSection.quests => 'quests.list',
            RuntimePlayerPauseSection.contacts => 'contacts.list',
          };
          if (!_includes(_screenFilter, screen) &&
              !(section == RuntimePlayerPauseSection.party &&
                  _includes(_screenFilter, 'pokemon.summary'))) {
            continue;
          }
          final harness = _Harness(section);
          try {
            await _mount(tester, mode.key, dark, _router(harness, mode.key));
            if (_includes(_screenFilter, screen)) {
              await _capture(
                tester,
                mode.key,
                theme,
                screen,
                source: 'RuntimePlayerSurfaceRouter',
              );
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
        for (final service in ['pc.box', 'shop.buy']) {
          if (!_includes(_screenFilter, service)) continue;
          await _mount(
            tester,
            mode.key,
            dark,
            mode.key == 'thor-primary'
                ? _image('world')
                : service == 'pc.box'
                ? PlayerPcOverlay(snapshot: _pcSnapshot(), onCommand: (_) {})
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
            source: service == 'pc.box'
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
                    fallbackText: 'Choisissez votre compagnon',
                  ),
                  options: [
                    for (final name in ['Bulbi', 'Salamèche', 'Carapuce'])
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
                if (mode.key != 'thor-companion')
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
                    'Dialogue remains owner-rendered; this fixture does not simulate a new remote dialogue protocol.',
                  ]
                : [],
          );
        }
        for (final screen in [
          'title.menu',
          'postbattle.victory',
          'postbattle.moveLearningPrompt',
        ]) {
          if (!_includes(_screenFilter, screen)) continue;
          final title = screen == 'title.menu';
          final decision = screen == 'postbattle.moveLearningPrompt';
          await _mount(
            tester,
            mode.key,
            dark,
            title
                ? PlayerTitleScreen(
                    data: PlayerTitleViewData(
                      gameTitle: 'Les Clairières',
                      author: 'Avelune',
                      description: 'Une aventure à votre rythme',
                      backgroundContent: _image('world'),
                      actions: {
                        for (final action in PlayerTitleMenuAction.values)
                          action: PlayerActionAvailability.enabled,
                      },
                    ),
                    onSelected: (_) {},
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      _image('battle-ligue'),
                      if (mode.key != 'thor-primary')
                        PlayerPostBattleOverlay(
                          snapshot: PostBattlePresentationSnapshot(
                            revision: 7,
                            messageIndex: 0,
                            messageCount: 1,
                            messageKind: decision
                                ? RuntimePostBattleMessageKind
                                      .moveLearningPrompt
                                : RuntimePostBattleMessageKind.victory,
                            message: decision
                                ? 'Bulbi souhaite apprendre Tranch’Herbe.'
                                : 'Vous avez remporté le combat !',
                            summaryMessages: decision
                                ? const []
                                : const [
                                    RuntimePostBattleMessage(
                                      kind: RuntimePostBattleMessageKind
                                          .experience,
                                      text: 'Bulbi gagne 84 EXP.',
                                    ),
                                    RuntimePostBattleMessage(
                                      kind: RuntimePostBattleMessageKind.money,
                                      text: 'Vous obtenez 120 ₽.',
                                    ),
                                  ],
                            choices: decision
                                ? const [
                                    PostBattlePresentationChoice(
                                      index: 0,
                                      label: 'Apprendre',
                                      selected: true,
                                    ),
                                    PostBattlePresentationChoice(
                                      index: 1,
                                      label: 'Ne pas apprendre',
                                      selected: false,
                                    ),
                                  ]
                                : const [],
                            completed: false,
                            hasFailure: false,
                          ),
                          onCommand: (_) {},
                        ),
                    ],
                  ),
          );
          await _capture(
            tester,
            mode.key,
            theme,
            screen,
            source: title ? 'PlayerTitleScreen' : 'PlayerPostBattleOverlay',
            limitations: mode.key.startsWith('thor')
                ? [
                    'Direct widget composition; remote title and post-battle ownership are not certified.',
                  ]
                : [],
          );
        }
        for (final screen in ['battle.root', 'battle.fight', 'battle.turn']) {
          if (!_includes(_screenFilter, screen)) continue;
          final moves = screen == 'battle.fight';
          final busy = screen == 'battle.turn';
          final placement = mode.key.startsWith('thor')
              ? BattleCommandPanelPlacement.detached
              : mode.key == 'landscape-controller'
              ? BattleCommandPanelPlacement.end
              : BattleCommandPanelPlacement.bottom;
          final size = mode.key == 'thor-companion'
              ? const Size(768, 432)
              : mode.value;
          final layout = BattleSceneLayout.forViewport(
            viewportSize: size,
            safePadding: _safePadding(mode.key),
            commandPanelPlacement: placement,
            commandPanelMode: busy
                ? BattleCommandOverlayMode.continueOnly
                : moves
                ? BattleCommandOverlayMode.fight
                : BattleCommandOverlayMode.root,
            controllerLayout: _controller(mode.key),
          );
          await _mount(
            tester,
            mode.key,
            dark,
            Stack(
              fit: StackFit.expand,
              children: [
                if (mode.key != 'thor-companion') ...[
                  _image('battle-ligue'),
                  Positioned.fromRect(
                    rect: layout.enemySpriteRect,
                    child: _image('pidgey-front', fit: BoxFit.contain),
                  ),
                  Positioned.fromRect(
                    rect: layout.playerSpriteRect,
                    child: _image('bulbasaur-back', fit: BoxFit.contain),
                  ),
                ],
                PlayerBattleOverlay(
                  snapshot: _battleSnapshot(
                    size,
                    layout,
                    moves,
                    busy: busy,
                    placement: placement,
                    controllerLayout: _controller(mode.key),
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
          );
          await _capture(
            tester,
            mode.key,
            theme,
            screen,
            source:
                'PlayerBattleOverlay > PlayerBattleSurface; BattleSceneLayout',
            limitations: [
              'The battle stage is reference art composited at runtime-published sprite rectangles; Flame scene execution is not exercised.',
            ],
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(_writeManifest);
      });
    }
  }
}

Widget _image(String name, {BoxFit fit = BoxFit.cover}) => RawImage(
  image: _images[p.join(_assets, '$name.png')]!.image,
  fit: fit,
  filterQuality: FilterQuality.none,
);

Future<void> _mount(
  WidgetTester tester,
  String mode,
  bool dark,
  Widget surface,
) async {
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
          child: child!,
        ),
      ),
      home: Scaffold(
        body: RepaintBoundary(
          key: const ValueKey('ligue-capture'),
          child: SizedBox.expand(child: body),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
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
          screen.startsWith('battle') ||
              screen.startsWith('pc') ||
              screen.startsWith('shop') ||
              screen.startsWith('dialogue')
          ? 7
          : 1,
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
  _Harness(RuntimePlayerPauseSection section, {bool empty = false})
    : snapshot = RuntimePlayerSnapshot(
        revision: 1,
        phase: RuntimePlayerPhase.paused,
        gameTitle: 'Les Clairières',
        pauseSection: section,
        activeSaveAddress: const RuntimePlayerSaveAddress(
          gameId: 'ligue26.reference',
          profileId: 'player',
          slotId: 'slot-1',
        ),
        preferences: const PlayerPreferencesSnapshot(
          locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(),
        ),
        favoriteItemIds: const {'item0'},
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
          ],
          RuntimePlayerPauseSection.contacts => [
            RuntimePlayerDetailEntrySnapshot(
              id: 'professor',
              title: 'Professeur',
              subtitle: 'Laboratoire de la Clairière',
            ),
            RuntimePlayerDetailEntrySnapshot(
              id: 'guard',
              title: 'Garde forestier',
              subtitle: 'Clairière des Sources',
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
                        u: (i % 6 + 1) / 7,
                        v: (i ~/ 6 + 1) / 4,
                        description: i == 0
                            ? 'Vous vous trouvez ici. Un village calme au bord de la forêt.'
                            : 'Le garde veille sur le passage de la forêt.',
                      ),
                    ),
            ),
          ],
        )
      : null,
);

RuntimeWorldServiceSnapshot _pcSnapshot() => RuntimeWorldServiceSnapshot(
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
    boxes: const <RuntimePcBoxSnapshot>[
      RuntimePcBoxSnapshot(
        boxId: 'box-a',
        label: 'Boîte 1',
        count: 0,
        capacity: 30,
      ),
    ],
    party: [
      for (final entry in _detail(
        RuntimePlayerPauseSection.party,
        empty: false,
      ).entries)
        RuntimePcPokemonSnapshot(
          targetId: entry.id,
          label: entry.pokemonSummary!.displayLabel,
          summary: entry.pokemonSummary,
          speciesId:
              _species[int.parse(
                entry.pokemonSummary!.individualId.substring(6),
              )],
          level: entry.pokemonSummary!.level,
          natureId: 'modest',
          abilityId: 'reference',
          currentHp: entry.pokemonSummary!.currentHp,
          nickname: entry.pokemonSummary!.nickname,
          friendship: entry.pokemonSummary!.friendship,
          canTransfer: true,
        ),
    ],
    stored: const <RuntimePcPokemonSnapshot>[],
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
  bool controllerLayout = false,
  BattleCommandPanelPlacement placement = BattleCommandPanelPlacement.bottom,
}) => BattleCommandOverlaySnapshot(
  commandPanelPlacement: placement,
  controllerLayout: controllerLayout,
  phase: busy
      ? BattlePresentationPhase.presentingTurn
      : BattlePresentationPhase.choosingCommand,
  revision: 7,
  mode: busy
      ? BattleCommandOverlayMode.continueOnly
      : moves
      ? BattleCommandOverlayMode.fight
      : BattleCommandOverlayMode.root,
  viewportSize: size,
  panelRect: layout.commandPanelRect,
  enemyHud: BattleCommandOverlayHudSnapshot(
    rect: layout.enemyHudRect,
    ownerLabel: 'ENNEMI',
    speciesLabel: 'Roucool',
    level: 12,
    currentHp: 27,
    maxHp: 36,
    genderSymbol: '♂',
    isPlayerSide: false,
  ),
  playerHud: BattleCommandOverlayHudSnapshot(
    rect: layout.playerHudRect,
    ownerLabel: 'JOUEUR',
    speciesLabel: 'Bulbi',
    level: 16,
    currentHp: 32,
    maxHp: 48,
    genderSymbol: '♂',
    isPlayerSide: true,
    experienceProgress: 0.62,
  ),
  battleLabel: 'COMBAT SAUVAGE',
  title: 'COMMANDES',
  prompt: 'Que doit faire Bulbi ?',
  narrationLines: <String>[
    busy ? 'Bulbi utilise Fouet Lianes !' : 'Un Roucool sauvage apparaît !',
  ],
  entries: busy
      ? const []
      : moves
      ? List.generate(
          4,
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
              'Statut',
            ][i],
            trailingLabel: [
              'PP 22 / 25',
              'PP 30 / 35',
              'PP 10 / 10',
              'PP 0 / 15',
            ][i],
            enabled: i != 3,
            selected: i == 0,
            tone: i == 3
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
  canGoBack: moves && !busy,
);
