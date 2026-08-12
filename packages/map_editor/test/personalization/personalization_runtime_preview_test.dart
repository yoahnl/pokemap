import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('PST-040 projects the current title screen contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          dialogueData: _dialogueData,
          battleData: _battleData,
          profile: ProjectPresentationProfile(
            branding: ProjectBrandingProfile(
              accentColor: '#224466',
              layoutVariant: 'cinematic',
            ),
            typography: ProjectTypographyProfile(
              display: ProjectTypographyRoleProfile(family: 'Aurore Display'),
            ),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('personalization-runtime-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('personalization-preview-title')),
      findsOneWidget,
    );
    expect(find.byType(PlayerTitleSurface), findsOneWidget);
    expect(find.text('Pokémon Aurore'), findsOneWidget);
    expect(find.text('Aurore Display'), findsOneWidget);
  });

  testWidgets('PST-041 composes dialogue and menu runtime surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          dialogueData: _dialogueData,
          battleData: _battleData,
          profile: ProjectPresentationProfile(
            typography: ProjectTypographyProfile(
              body: ProjectTypographyRoleProfile(family: 'Aurore Body'),
              dialogue: ProjectTypographyRoleProfile(family: 'Aurore Dialogue'),
            ),
            menuLabels: ProjectMenuLabelsProfile(
              pauseTitle: 'Interlude',
              pokedex: 'Carnet',
            ),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-dialogue')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('personalization-dialogue-composition'),
      ),
      findsOneWidget,
    );
    expect(find.text('Léo'), findsOneWidget);
    expect(find.textContaining('Bienvenue à Vermeil'), findsOneWidget);
    expect(find.byType(PlayerDialogueSurface), findsOneWidget);
    final dialogueText = tester.widget<Text>(find.text('Bienvenue à Vermeil.'));
    expect(dialogueText.style?.fontFamily, 'Aurore Dialogue');

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-pause')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('personalization-pause-composition')),
      findsOneWidget,
    );
    expect(find.byType(PlayerPauseSurface), findsOneWidget);
    expect(find.text('Interlude'), findsWidgets);
    final pause = tester.widget<RuntimePlayerPauseShell>(
      find.byType(RuntimePlayerPauseShell),
    );
    expect(pause.presentation?.title, 'Interlude');
    expect(
      pause.presentation?.actionLabels[PlayerPauseAction.pokedex],
      'Carnet',
    );
    final pauseContext = tester.element(find.byType(PlayerPauseSurface));
    expect(pauseContext.playerTypography.bodyFamily, 'Aurore Body');
  });

  testWidgets('PST-042 exposes global style and battle scenes', (tester) async {
    await tester.pumpWidget(
      _app(
        PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          dialogueData: _dialogueData,
          battleData: _battleData,
          profile: ProjectPresentationProfile(
            typography: ProjectTypographyProfile(
              body: ProjectTypographyRoleProfile(family: 'Aurore Body'),
              numbers: ProjectTypographyRoleProfile(family: 'Aurore Numbers'),
            ),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-globalStyle')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('personalization-global-style-composition'),
      ),
      findsOneWidget,
    );
    expect(find.byType(PlayerTitleSurface), findsOneWidget);
    expect(find.byType(PlayerDialogueSurface), findsOneWidget);
    expect(find.byType(PlayerPauseSurface), findsOneWidget);
    expect(find.byType(PlayerBattleSurface), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-battle')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('personalization-battle-composition')),
      findsOneWidget,
    );
    expect(find.byType(PlayerBattleSurface), findsOneWidget);
    final battle = tester.widget<PlayerBattleSurface>(
      find.byType(PlayerBattleSurface),
    );
    expect(battle.data.player.speciesLabel, 'Brindibou');
    expect(battle.data.player.currentHp, 24);
    expect(battle.data.player.maxHp, 24);
    final battleContext = tester.element(find.byType(PlayerBattleSurface));
    expect(battleContext.playerTypography.numbersFamily, 'Aurore Numbers');
  });

  testWidgets('window styling is visible on Dialogue and Pause previews', (
    tester,
  ) async {
    const windows = ProjectPresentationWindowsProfile(
      styles: <ProjectWindowStyleProfile>[
        ProjectWindowStyleProfile(
          id: 'default',
          fillToken: 'surface',
          borderToken: 'outline',
          borderWidth: 1,
          cornerRadius: 16,
          contentPadding: 24,
          shadowElevation: 8,
        ),
        ProjectWindowStyleProfile(
          id: 'pause-menu',
          fillToken: 'menuSurface',
          borderToken: 'primary',
          borderWidth: 3,
          cornerRadius: 24,
          contentPadding: 20,
          shadowElevation: 12,
        ),
        ProjectWindowStyleProfile(
          id: 'dialogue',
          fillToken: 'dialogueSurface',
          borderToken: 'warning',
          borderWidth: 2,
          cornerRadius: 8,
          contentPadding: 12,
          shadowElevation: 4,
        ),
      ],
      defaultStyleId: 'default',
      pauseMenuStyleId: 'pause-menu',
      dialogueStyleId: 'dialogue',
      pauseBackdropOpacity: .8,
    );
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          dialogueData: _dialogueData,
          battleData: _battleData,
          profile: ProjectPresentationProfile(
            theme: safeProjectSemanticTheme,
            windows: windows,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-dialogue')),
    );
    await tester.pumpAndSettle();
    final dialogueContext = tester.element(find.byType(PlayerDialogueSurface));
    final dialogueStyle = dialogueContext.playerWindowTheme!.style(
      ProjectWindowRole.dialogue,
    );
    expect(dialogueStyle.contentPadding, 12);
    expect(dialogueStyle.cornerRadius, 8);
    expect(dialogueStyle.borderWidth, 2);

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-pause')),
    );
    await tester.pumpAndSettle();
    final pauseContext = tester.element(find.byType(PlayerPauseSurface));
    final pauseStyle = pauseContext.playerWindowTheme!.style(
      ProjectWindowRole.pauseMenu,
    );
    expect(pauseStyle.contentPadding, 20);
    expect(pauseStyle.cornerRadius, 24);
    expect(pauseStyle.borderWidth, 3);
  });

  testWidgets('PST-043 previews portrait intro poster and reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
            intro: ProjectIntroVideoProfile.fromLandscape(
              videoPath: 'assets/presentation/intro/portrait.mp4',
              posterPath: 'assets/presentation/intro/portrait.png',
              durationMilliseconds: 12500,
              width: 1080,
              height: 1920,
              bitrateKbps: 2400,
              sizeBytes: 5000000,
              videoCodec: 'h264',
              reducedMotionBehavior: 'poster',
            ),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-intro')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('personalization-intro-composition')),
      findsOneWidget,
    );
    final intro = tester.widget<PlayerIntroVideoSurface>(
      find.byType(PlayerIntroVideoSurface),
    );
    expect(intro.isPoster, isTrue);
    expect(intro.media, isNull);
  });

  testWidgets('PST-044 simulates viewport text scale and reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
            intro: ProjectIntroVideoProfile.fromLandscape(
              videoPath: 'assets/presentation/intro/intro.mp4',
              posterPath: 'assets/presentation/intro/poster.png',
              durationMilliseconds: 12500,
              width: 1920,
              height: 1080,
              bitrateKbps: 2400,
              sizeBytes: 5000000,
              videoCodec: 'h264',
              reducedMotionBehavior: 'skip',
            ),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-viewport-portrait'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>(
          'personalization-preview-viewport-frame-portrait',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-text-scale-150'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Texte 150 %'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-reduced-motion'),
      ),
    );
    await tester.pump();
    final switcher = tester.widget<AnimatedSwitcher>(
      find
          .descendant(
            of: find.byKey(
              const ValueKey<String>(
                'personalization-preview-viewport-frame-portrait',
              ),
            ),
            matching: find.byType(AnimatedSwitcher),
          )
          .first,
    );
    expect(switcher.duration, Duration.zero);
    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-intro')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mouvement réduit actif'), findsOneWidget);
    expect(find.text('La vidéo ne peut pas être lue.'), findsOneWidget);
  });

  testWidgets('PST-045 compares baseline and draft with identical simulation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          baselineProfile: ProjectPresentationProfile(
            branding: ProjectBrandingProfile(layoutVariant: 'standard'),
            theme: safeProjectSemanticTheme,
          ),
          profile: ProjectPresentationProfile(
            branding: ProjectBrandingProfile(layoutVariant: 'centered'),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('personalization-preview-compare')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-viewport-portrait'),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-text-scale-150'),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-compare')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('personalization-preview-before')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('personalization-preview-after')),
      findsOneWidget,
    );
    expect(find.text('Avant'), findsOneWidget);
    expect(find.text('Maintenant'), findsOneWidget);
    expect(find.byType(PlayerTitleSurface), findsNWidgets(2));
    expect(find.text('Texte 150 %'), findsOneWidget);
  });

  testWidgets('preview controls expose 48 pixel interaction targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          baselineProfile: ProjectPresentationProfile(
            branding: ProjectBrandingProfile(layoutVariant: 'standard'),
            theme: safeProjectSemanticTheme,
          ),
          profile: ProjectPresentationProfile(
            branding: ProjectBrandingProfile(layoutVariant: 'cinematic'),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );

    for (final key in <String>[
      'personalization-preview-viewport-landscape',
      'personalization-preview-viewport-portrait',
      'personalization-preview-text-scale-100',
      'personalization-preview-text-scale-150',
      'personalization-preview-text-scale-200',
      'personalization-preview-reduced-motion',
      'personalization-preview-compare',
    ]) {
      expect(
        tester.getSize(find.byKey(ValueKey<String>(key))).height,
        greaterThanOrEqualTo(48),
      );
    }
  });

  testWidgets('PST-045 hides comparison when the draft is unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          baselineProfile: ProjectPresentationProfile(
            theme: safeProjectSemanticTheme,
          ),
          profile: ProjectPresentationProfile(theme: safeProjectSemanticTheme),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('personalization-preview-compare')),
      findsNothing,
    );
  });

  testWidgets('title motion follows the reduced-motion simulation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
            titleMotion: ProjectTitleMotionProfile(
              promptLoop: ProjectResponsiveVideoProfile(
                landscape: ProjectVideoVariantProfile(
                  videoPath: 'assets/presentation/title/prompt.mp4',
                  posterPath: 'assets/presentation/title/prompt.png',
                  durationMilliseconds: 4000,
                  width: 1280,
                  height: 720,
                  bitrateKbps: 1200,
                  sizeBytes: 4000,
                  videoCodec: 'h264',
                ),
              ),
            ),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );

    final titleContext = tester.element(find.byType(PlayerTitleSurface));
    expect(titleContext.playerMotion.fast, isNot(Duration.zero));

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-reduced-motion'),
      ),
    );
    await tester.pumpAndSettle();

    final reducedTitleContext = tester.element(find.byType(PlayerTitleSurface));
    expect(reducedTitleContext.playerMotion.fast, Duration.zero);
  });

  testWidgets('title stage waits for the active decoder to be released', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync('title-stage-release-');
    addTearDown(() => root.deleteSync(recursive: true));
    for (final path in <String>['menu.mp4', 'prompt.mp4']) {
      File('${root.path}/$path').writeAsBytesSync(<int>[0]);
    }
    final disposal = Completer<void>();
    final drivers = <_TitlePlaybackDriver>[];

    await tester.pumpWidget(
      _app(
        PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: root.path,
          profile: ProjectPresentationProfile(
            titleMotion: ProjectTitleMotionProfile(
              promptLoop: ProjectResponsiveVideoProfile(
                landscape: _titleLoop('prompt.mp4'),
              ),
              menuLoop: ProjectResponsiveVideoProfile(
                landscape: _titleLoop('menu.mp4'),
              ),
            ),
            theme: safeProjectSemanticTheme,
          ),
          titleMotionDriverFactory: (_) {
            final driver = _TitlePlaybackDriver(
              disposalGate: drivers.isEmpty ? disposal : null,
            );
            drivers.add(driver);
            return driver;
          },
        ),
      ),
    );
    await tester.pump();
    expect(drivers, hasLength(1));

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-title-preview-stage-prompt'),
      ),
    );
    await tester.pump();

    expect(drivers, hasLength(1));
    disposal.complete();
    await tester.pump();
    await tester.pump();

    expect(drivers, hasLength(2));
    expect(find.byType(PlayerTitlePromptSurface), findsOneWidget);
  });

  testWidgets('title preview switches between the real prompt and menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(theme: safeProjectSemanticTheme),
        ),
      ),
    );

    expect(find.byType(PlayerTitleSurface), findsOneWidget);
    expect(find.byType(PlayerTitlePromptSurface), findsNothing);

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-title-preview-stage-prompt'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PlayerTitleSurface), findsNothing);
    expect(find.byType(PlayerTitlePromptSurface), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-title-preview-stage-menu'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PlayerTitleSurface), findsOneWidget);
  });

  testWidgets('surface navigation is semantic and directly operable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(theme: safeProjectSemanticTheme),
        ),
      ),
    );

    expect(
      tester.getSemantics(
        find.byKey(const ValueKey<String>('personalization-preview-title')),
      ),
      matchesSemantics(
        isButton: true,
        hasTapAction: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-globalStyle')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('personalization-global-style-composition'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-title')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('personalization-title-composition')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-globalStyle')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('personalization-global-style-composition'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });
}

ProjectVideoVariantProfile _titleLoop(String path) =>
    ProjectVideoVariantProfile(
      videoPath: path,
      posterPath: '$path.png',
      durationMilliseconds: 1000,
      width: 1600,
      height: 900,
      bitrateKbps: 1200,
      sizeBytes: 1,
      videoCodec: 'h264',
    );

const _dialogueData = PlayerDialogueViewData(
  revision: 1,
  mode: PlayerDialogueMode.line,
  speaker: 'Léo',
  text: 'Bienvenue à Vermeil.',
  fullText: 'Bienvenue à Vermeil.',
  isCurrentLineFullyRevealed: true,
  isLastContent: true,
  choices: <PlayerDialogueChoiceViewData>[],
);

const _battleData = PlayerBattleViewData(
  revision: 1,
  enemy: PlayerBattleHudViewData(
    ownerLabel: 'SAUVAGE',
    speciesLabel: 'Roucool',
    level: 7,
    currentHp: 31,
    maxHp: 31,
  ),
  player: PlayerBattleHudViewData(
    ownerLabel: 'JOUEUR',
    speciesLabel: 'Brindibou',
    level: 8,
    currentHp: 24,
    maxHp: 24,
  ),
  battleLabel: 'Herbes de Vermeil',
  title: 'Que doit faire Brindibou ?',
  prompt: 'Choisissez une action.',
  narrationLines: <String>[],
  commands: <PlayerBattleCommandViewData>[
    PlayerBattleCommandViewData(
      index: 0,
      primaryLabel: 'ATTAQUER',
      secondaryLabel: 'Choisir une capacité',
      enabled: true,
      selected: true,
      tone: PlayerBattleEntryTone.attack,
      commandId: ProjectBattleCommandId.fight,
      commandIcon: ProjectBattleCommandIcon.fight,
    ),
  ],
  interactionsEnabled: true,
  canGoBack: false,
);

final class _TitlePlaybackDriver implements PlayerIntroPlaybackDriver {
  _TitlePlaybackDriver({this.disposalGate});

  final Completer<void>? disposalGate;
  final snapshot = ValueNotifier<PlayerIntroPlaybackSnapshot>(
    const PlayerIntroPlaybackSnapshot(),
  );

  @override
  ValueListenable<PlayerIntroPlaybackSnapshot> get snapshots => snapshot;

  @override
  Widget buildVideo() => const SizedBox.expand();

  @override
  Future<void> initialize() async {
    snapshot.value = const PlayerIntroPlaybackSnapshot(isInitialized: true);
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> dispose() async {
    await disposalGate?.future;
    snapshot.dispose();
  }
}

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
  localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
  theme: PokeMapTheme.light(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
