import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

enum _PlayerSurface { globalStyle, title, intro, pause, dialogue, battle }

enum _PlayerVariant {
  dialogueText2x,
  dialogueChoices,
  battleCommands,
  battleMoves,
  battleTarget,
  battleMessage,
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFixtureFont();
    await _seedFixtureImages();
  });

  for (final orientation in <String>['landscape', 'portrait']) {
    for (final surface in _PlayerSurface.values) {
      testWidgets('certifies player ${surface.name} in $orientation', (
        tester,
      ) async {
        final size = orientation == 'landscape'
            ? const Size(960, 540)
            : const Size(540, 960);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fixture = await tester.runAsync(_readGoldenFixture);
        final presentation = RuntimePlayerPresentation.fromProfile(
          fixture!.profile,
          author: 'POKÉMAP',
          description: 'Une aventure ferroviaire à travers Hanazuki.',
        );

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('fr'),
            supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
            localizationsDelegates:
                PokeMapPlayerLocalizations.localizationsDelegates,
            theme: presentation.applyTo(
              PokeMapPlayerTheme.dark(reducedMotion: true),
            ),
            home: RepaintBoundary(
              key: const ValueKey<String>('player-personalization-golden'),
              child: _surface(surface, presentation, fixture),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey<String>('player-personalization-golden')),
          matchesGoldenFile(
            'goldens/player_personalization/${orientation}_${surface.name}.png',
          ),
        );
      });
    }
  }

  for (final variant in _PlayerVariant.values) {
    testWidgets('certifies player ${variant.name} variant', (tester) async {
      const size = Size(960, 540);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = await tester.runAsync(_readGoldenFixture);
      final presentation = RuntimePlayerPresentation.fromProfile(
        fixture!.profile,
        author: 'POKÉMAP',
        description: 'Une aventure ferroviaire à travers Hanazuki.',
      );

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('fr'),
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          theme: presentation.applyTo(
            PokeMapPlayerTheme.dark(reducedMotion: true),
          ),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: variant == _PlayerVariant.dialogueText2x
                  ? const TextScaler.linear(2)
                  : TextScaler.noScaling,
            ),
            child: RepaintBoundary(
              key: const ValueKey<String>(
                'player-personalization-variant-golden',
              ),
              child: _variant(variant, presentation, fixture),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(
          const ValueKey<String>('player-personalization-variant-golden'),
        ),
        matchesGoldenFile(
          'goldens/player_personalization/variant_${variant.name}.png',
        ),
      );
    });
  }
}

Widget _variant(
  _PlayerVariant variant,
  RuntimePlayerPresentation presentation,
  ({ProjectPresentationProfile profile, String projectName}) fixture,
) =>
    switch (variant) {
      _PlayerVariant.dialogueText2x => _surface(
          _PlayerSurface.dialogue,
          presentation,
          fixture,
        ),
      _PlayerVariant.dialogueChoices => PlayerDialogueSurface(
          data: _dialogueChoices,
          portraitBuilder: (_) => Image(
            image: _fixtureImage('assets/characters/leo-happy.png'),
            fit: BoxFit.contain,
          ),
          onAction: (_) {},
        ),
      _PlayerVariant.battleCommands => PlayerBattleSurface(
          data: _battle(
            fixture.profile,
            panelKind: PlayerBattlePanelKind.commands,
          ),
          onAction: (_) {},
        ),
      _PlayerVariant.battleMoves => PlayerBattleSurface(
          data: _battle(
            fixture.profile,
            panelKind: PlayerBattlePanelKind.moves,
          ),
          onAction: (_) {},
        ),
      _PlayerVariant.battleTarget => PlayerBattleSurface(
          data: _battle(
            fixture.profile,
            panelKind: PlayerBattlePanelKind.target,
          ),
          onAction: (_) {},
        ),
      _PlayerVariant.battleMessage => PlayerBattleSurface(
          data: _battle(
            fixture.profile,
            panelKind: PlayerBattlePanelKind.message,
          ),
          onAction: (_) {},
        ),
    };

Widget _surface(
  _PlayerSurface surface,
  RuntimePlayerPresentation presentation,
  ({ProjectPresentationProfile profile, String projectName}) fixture,
) =>
    switch (surface) {
      _PlayerSurface.globalStyle => PlayerSurfacePaletteScope(
          role: ProjectPresentationSurfaceRole.pauseMenu,
          paintBackground: true,
          child: PlayerSurface(
            child: Center(
              child: Builder(
                builder: (context) => PlayerPanel(
                  surfaceRole: ProjectPresentationSurfaceRole.pauseMenu,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        fixture.projectName,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      const Text('Couleurs, fenêtres et typographie du projet'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      _PlayerSurface.title => PlayerTitleSurface(
          data: PlayerTitleSurfaceData(
            gameTitle: presentation.title.resolveTitle(fixture.projectName),
            author: 'PokeMap',
            description: 'Projet d’acceptation visuelle',
            background: _fixtureImage('assets/presentation/hero.png'),
            logo: _fixtureImage('assets/presentation/icon.png'),
            accentColor: presentation.title.accentColor,
            layoutVariant: presentation.title.layoutVariant,
            actions: <PlayerTitleMenuAction, PlayerActionAvailability>{
              for (final action in PlayerTitleMenuAction.values)
                action: PlayerActionAvailability.enabled,
            },
            actionLabels: presentation.title.actionLabels,
            actionIcons: presentation.title.actionIcons,
            initialSelection: PlayerTitleMenuAction.newGame,
          ),
          onSelected: (_) {},
        ),
      _PlayerSurface.intro => PlayerIntroVideoSurface(
          media: Image(
            image: _fixtureImage('assets/presentation/intro/poster.png'),
            fit: BoxFit.cover,
          ),
          isPoster: true,
          caption: 'Bienvenue à Vermeil.',
          onSkip: () {},
          onReplay: () {},
          onContinue: () {},
        ),
      _PlayerSurface.pause => RuntimePlayerPauseShell.root(
          gameTitle: fixture.projectName,
          labels: presentation.pauseMenuLabels,
          actions: <PlayerPauseAction, PlayerActionAvailability>{
            for (final action in PlayerPauseAction.values)
              action: PlayerActionAvailability.enabled,
          },
          presentation: presentation.pausePresentation,
          onSelected: (_) {},
          detail: const Center(child: Text('Sélectionnez une section')),
        ),
      _PlayerSurface.dialogue => PlayerDialogueSurface(
          data: _dialogue,
          portraitBuilder: (_) => Image(
            image: _fixtureImage('assets/characters/leo-happy.png'),
            fit: BoxFit.contain,
          ),
          onAction: (_) {},
        ),
      _PlayerSurface.battle => PlayerBattleSurface(
          data: _battle(fixture.profile),
          onAction: (_) {},
        ),
    };

const _dialogue = PlayerDialogueViewData(
  revision: 1,
  mode: PlayerDialogueMode.line,
  speaker: 'Léo',
  text: 'Bienvenue à Vermeil. Le sentier mène aux hautes herbes.',
  fullText: 'Bienvenue à Vermeil. Le sentier mène aux hautes herbes.',
  isCurrentLineFullyRevealed: true,
  isLastContent: false,
  choices: <PlayerDialogueChoiceViewData>[],
);

const _dialogueChoices = PlayerDialogueViewData(
  revision: 2,
  mode: PlayerDialogueMode.choices,
  speaker: 'Léo',
  text: 'Quel chemin veux-tu emprunter ?',
  fullText: 'Quel chemin veux-tu emprunter ?',
  isCurrentLineFullyRevealed: true,
  isLastContent: false,
  choices: <PlayerDialogueChoiceViewData>[
    PlayerDialogueChoiceViewData(
      index: 0,
      label: 'Le sentier des hautes herbes',
      selected: true,
    ),
    PlayerDialogueChoiceViewData(
      index: 1,
      label: 'La route de la gare',
      selected: false,
    ),
  ],
);

PlayerBattleViewData _battle(
  ProjectPresentationProfile profile, {
  PlayerBattlePanelKind panelKind = PlayerBattlePanelKind.commands,
}) =>
    PlayerBattleViewData(
      revision: 1,
      enemy: const PlayerBattleHudViewData(
        ownerLabel: 'SAUVAGE',
        speciesLabel: 'Roucool',
        level: 7,
        currentHp: 31,
        maxHp: 31,
      ),
      player: const PlayerBattleHudViewData(
        ownerLabel: 'JOUEUR',
        speciesLabel: 'Brindibou',
        level: 8,
        currentHp: 24,
        maxHp: 24,
      ),
      battleLabel: 'Herbes de Vermeil',
      title: switch (panelKind) {
        PlayerBattlePanelKind.commands => 'Que doit faire Brindibou ?',
        PlayerBattlePanelKind.moves => 'Choisissez une capacité',
        PlayerBattlePanelKind.target => 'Choisissez une cible',
        PlayerBattlePanelKind.message => 'Le combat continue',
      },
      prompt: switch (panelKind) {
        PlayerBattlePanelKind.commands => 'Choisissez une action.',
        PlayerBattlePanelKind.moves => 'Choisissez une capacité.',
        PlayerBattlePanelKind.target => 'Sélectionnez la cible.',
        PlayerBattlePanelKind.message => 'Appuyez pour continuer.',
      },
      narrationLines: panelKind == PlayerBattlePanelKind.message
          ? const <String>['Brindibou utilise Feuillage !']
          : const <String>[],
      commands: _battleEntries(profile, panelKind),
      interactionsEnabled: panelKind != PlayerBattlePanelKind.message,
      canGoBack: panelKind != PlayerBattlePanelKind.commands,
      panelKind: panelKind,
    );

List<PlayerBattleCommandViewData> _battleEntries(
  ProjectPresentationProfile profile,
  PlayerBattlePanelKind panelKind,
) =>
    switch (panelKind) {
      PlayerBattlePanelKind.commands => <PlayerBattleCommandViewData>[
          for (var index = 0;
              index < profile.battle!.effectiveCommands.length;
              index++)
            PlayerBattleCommandViewData(
              index: index,
              primaryLabel: profile.battle!.effectiveCommands[index].label ??
                  profile.battle!.effectiveCommands[index].id.name
                      .toUpperCase(),
              secondaryLabel: 'Commande du projet',
              enabled: true,
              selected: index == 0,
              tone: PlayerBattleEntryTone.attack,
              commandId: profile.battle!.effectiveCommands[index].id,
              commandIcon: profile.battle!.effectiveCommands[index].icon,
            ),
        ],
      PlayerBattlePanelKind.moves => const <PlayerBattleCommandViewData>[
          PlayerBattleCommandViewData(
            index: 0,
            primaryLabel: 'Feuillage',
            secondaryLabel: 'Plante',
            trailingLabel: 'PP 40/40',
            enabled: true,
            selected: true,
            tone: PlayerBattleEntryTone.attack,
          ),
          PlayerBattleCommandViewData(
            index: 1,
            primaryLabel: 'Picpic',
            secondaryLabel: 'Vol',
            trailingLabel: 'PP 35/35',
            enabled: true,
            selected: false,
            tone: PlayerBattleEntryTone.special,
          ),
        ],
      PlayerBattlePanelKind.target => const <PlayerBattleCommandViewData>[
          PlayerBattleCommandViewData(
            index: 0,
            primaryLabel: 'Roucool sauvage',
            secondaryLabel: 'PV 31/31',
            enabled: true,
            selected: true,
            tone: PlayerBattleEntryTone.neutral,
          ),
        ],
      PlayerBattlePanelKind.message => const <PlayerBattleCommandViewData>[],
    };

FileImage _fixtureImage(String relativePath) => FileImage(
      File(
        '${Directory.current.path}/../../examples/playable_runtime_host/'
        'golden_personalization_v3/$relativePath',
      ),
    );

Future<void> _seedFixtureImages() async {
  for (final relativePath in <String>[
    'assets/presentation/hero.png',
    'assets/presentation/icon.png',
    'assets/presentation/intro/poster.png',
    'assets/characters/leo-happy.png',
  ]) {
    final provider = _fixtureImage(relativePath);
    final codec = await ui.instantiateImageCodec(
      await provider.file.readAsBytes(),
    );
    final frame = await codec.getNextFrame();
    PaintingBinding.instance.imageCache.putIfAbsent(
      provider,
      () => OneFrameImageStreamCompleter(
        SynchronousFuture<ImageInfo>(ImageInfo(image: frame.image)),
      ),
    );
    codec.dispose();
  }
}

Future<({ProjectPresentationProfile profile, String projectName})>
    _readGoldenFixture() async {
  final file = File(
    '${Directory.current.path}/../../examples/playable_runtime_host/'
    'golden_personalization_v3/project.json',
  );
  final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  return (
    profile: ProjectPresentationProfile.fromJson(
      Map<String, dynamic>.from(decoded['presentation'] as Map),
    ),
    projectName: decoded['name']! as String,
  );
}

Future<void> _loadFixtureFont() async {
  final bytes = await File(
    '${Directory.current.path}/../../examples/playable_runtime_host/'
    'golden_personalization_v3/assets/presentation/fonts/display.ttf',
  ).readAsBytes();
  await _loadFont('Aube Display', bytes);
  await _loadFont('Avenir Next', bytes);
  final flutterCache = _flutterCacheDirectory();
  final iconBytes = await File(
    '${flutterCache.path}/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytes();
  await _loadFont('MaterialIcons', iconBytes);
}

Future<void> _loadFont(String family, Uint8List bytes) async {
  await (FontLoader(family)
        ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes))))
      .load();
}

Directory _flutterCacheDirectory() {
  var current = File(Platform.resolvedExecutable).parent;
  while (current.parent.path != current.path) {
    if (current.path.endsWith('${Platform.pathSeparator}cache')) return current;
    current = current.parent;
  }
  throw StateError('Flutter cache directory not found.');
}
