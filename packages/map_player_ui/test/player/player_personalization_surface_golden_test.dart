import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

enum _Surface { intro, title, dialogue, menu, overworldHud, battleHud }

void main() {
  for (final orientation in <String>['landscape', 'portrait']) {
    for (final surface in _Surface.values) {
      testWidgets('certifies player ${surface.name} in $orientation', (
        tester,
      ) async {
        final size = orientation == 'landscape'
            ? const Size(960, 540)
            : const Size(540, 960);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final profile = await tester.runAsync(_readGoldenPresentation);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('fr'),
            supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
            localizationsDelegates:
                PokeMapPlayerLocalizations.localizationsDelegates,
            theme: _playerTheme(profile!),
            home: RepaintBoundary(
              key: const ValueKey<String>('player-personalization-golden'),
              child: _surface(surface, profile),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

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
}

Widget _surface(_Surface surface, ProjectPresentationProfile profile) =>
    switch (surface) {
      _Surface.intro => PlayerIntroVideoSurface(
        media: const ColoredBox(
          color: Color(0xffd9f4f6),
          child: Center(child: Icon(Icons.train_rounded, size: 96)),
        ),
        isPoster: true,
        caption: 'Le train entre en gare de Hanazuki.',
        onSkip: () {},
        onReplay: () {},
        onContinue: () {},
      ),
      _Surface.title => PlayerTitleScreen(
        data: PlayerTitleViewData(
          gameTitle: 'Le train de 17h42',
          author: 'POKÉMAP',
          description: 'Une aventure ferroviaire à travers Hanazuki.',
          accentColor: PokeMapPlayerProjectColorResolver.tryHex(
            profile.branding.accentColor,
          ),
          layoutVariant: PlayerTitleLayoutVariant.fromManifest(
            profile.branding.layoutVariant,
          ),
          actions: {
            for (final action in PlayerTitleMenuAction.values)
              action: PlayerActionAvailability.enabled,
          },
        ),
        onSelected: (_) {},
      ),
      _Surface.dialogue => PlayerDialogueOverlay(
        snapshot: _dialogueSnapshot,
        onCommand: (_) {},
      ),
      _Surface.menu => PlayerPauseMenu(
        gameTitle: 'Le train de 17h42',
        labels: _pauseLabels(profile.menuLabels),
        actions: {
          for (final action in PlayerPauseAction.values)
            action: PlayerActionAvailability.enabled,
        },
        onSelected: (_) {},
      ),
      _Surface.overworldHud => Scaffold(
        body: Stack(
          children: <Widget>[
            const ColoredBox(
              color: Color(0xffd9f4f6),
              child: Center(child: Icon(Icons.map_rounded, size: 160)),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(PlayerSpacing.md),
                  child: PlayerPanel(
                    role: PlayerPanelRole.overworldHud,
                    elevated: true,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Route des Brumes'),
                        SizedBox(height: PlayerSpacing.xs),
                        Text('Rejoins le quai avant 17h42.'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      _Surface.battleHud => PlayerBattleOverlay(
        snapshot: _battleSnapshot(),
        onCommand: (_) {},
      ),
    };

const _dialogueSnapshot = DialoguePresentationSnapshot(
  revision: 1,
  mode: DialoguePresentationMode.line,
  nodeTitle: 'gare',
  speaker: 'Cheffe de gare',
  text: 'Le dernier train pour Hanazuki part dans quelques minutes.',
  fullText: 'Le dernier train pour Hanazuki part dans quelques minutes.',
  isCurrentLineFullyRevealed: true,
  isLastContent: false,
  choices: <DialoguePresentationChoice>[],
);

BattleCommandOverlaySnapshot _battleSnapshot() => BattleCommandOverlaySnapshot(
  revision: 1,
  phase: BattlePresentationPhase.choosingCommand,
  forcedReplacement: false,
  mode: BattleCommandOverlayMode.fight,
  panelRect: const Rect.fromLTWH(12, 300, 366, 270),
  enemyHud: _hud('ENNEMI', 'ROUCARNAGE', 23, 80, false),
  playerHud: _hud('JOUEUR', 'BRINDIBOU', 42, 55, true),
  battleLabel: 'COMBAT SAUVAGE',
  title: 'CAPACITÉS',
  prompt: 'Choisissez une capacité.',
  narrationLines: const <String>[],
  entries: const <BattleCommandOverlayEntry>[
    BattleCommandOverlayEntry(
      index: 0,
      kind: BattleCommandOverlayEntryKind.move,
      primaryLabel: 'Feuillage',
      secondaryLabel: 'PLANTE · PP 12/15',
      enabled: true,
      selected: true,
      tone: BattleCommandOverlayEntryTone.special,
    ),
    BattleCommandOverlayEntry(
      index: 1,
      kind: BattleCommandOverlayEntryKind.move,
      primaryLabel: 'Picpic',
      secondaryLabel: 'VOL · PP 20/20',
      enabled: true,
      selected: false,
      tone: BattleCommandOverlayEntryTone.neutral,
    ),
  ],
  interactionsEnabled: true,
  canGoBack: true,
);

BattleCommandOverlayHudSnapshot _hud(
  String owner,
  String species,
  int hp,
  int maxHp,
  bool player,
) => BattleCommandOverlayHudSnapshot(
  rect: const Rect.fromLTWH(12, 12, 160, 64),
  ownerLabel: owner,
  speciesLabel: species,
  level: 18,
  currentHp: hp,
  maxHp: maxHp,
  isPlayerSide: player,
);

PlayerPauseMenuLabels _pauseLabels(ProjectMenuLabelsProfile? labels) =>
    PlayerPauseMenuLabels(
      pauseTitle: labels?.pauseTitle,
      resume: labels?.resume,
      party: labels?.party,
      bag: labels?.bag,
      pokedex: labels?.pokedex,
      map: labels?.map,
      save: labels?.save,
      options: labels?.options,
      returnToTitle: labels?.returnToTitle,
    );

ThemeData _playerTheme(ProjectPresentationProfile profile) {
  final typography = profile.typography;
  var theme = PokeMapPlayerTheme.withTypography(
    PokeMapPlayerTheme.light(),
    PokeMapPlayerTypography(
      displayFamily: typography?.display.family,
      displayFallback: typography?.display.fallbackFamilies ?? const <String>[],
      bodyFamily: typography?.body.family,
      bodyFallback: typography?.body.fallbackFamilies ?? const <String>[],
      dialogueFamily: typography?.dialogue.family,
      dialogueFallback:
          typography?.dialogue.fallbackFamilies ?? const <String>[],
      numbersFamily: typography?.numbers.family,
      numbersFallback: typography?.numbers.fallbackFamilies ?? const <String>[],
    ),
  );
  final semantic = profile.theme;
  if (semantic != null) {
    theme = PokeMapPlayerTheme.withSemanticTheme(
      theme,
      PokeMapPlayerSemanticTheme.tryFromHex(
        primary: semantic.primary,
        onPrimary: semantic.onPrimary,
        background: semantic.background,
        surface: semantic.surface,
        surfaceElevated: semantic.surfaceElevated,
        textPrimary: semantic.textPrimary,
        textSecondary: semantic.textSecondary,
        outline: semantic.outline,
        success: semantic.success,
        warning: semantic.warning,
        danger: semantic.danger,
        titleSurface: semantic.titleSurface,
        dialogueSurface: semantic.dialogueSurface,
        menuSurface: semantic.menuSurface,
        overworldHudSurface: semantic.overworldHudSurface,
        battleHudSurface: semantic.battleHudSurface,
      )!,
    );
  }
  return theme;
}

Future<ProjectPresentationProfile> _readGoldenPresentation() async {
  final file = File(
    '${Directory.current.path}/../../examples/playable_runtime_host/'
    'golden_personalization_slice/presentation.json',
  );
  final decoded = jsonDecode(await file.readAsString());
  return ProjectPresentationProfile.fromJson(
    Map<String, dynamic>.from(decoded as Map),
  );
}
