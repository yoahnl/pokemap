import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/personalization_preview.dart';
import 'package:path/path.dart' as p;

import '../../../theme/theme.dart';
import '../../../ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/personalization_character_preview_source.dart';
import '../application/personalization_capability_descriptor.dart';
import '../application/personalization_inspector_target.dart';
import '../application/personalization_preview_surface_descriptor.dart';
import '../application/personalization_visual_target_graph.dart';
import 'personalization_project_map_backdrop.dart';
import 'personalization_title_preview_controls.dart';

class PersonalizationPlayerSurfaceAdapter extends StatelessWidget {
  const PersonalizationPlayerSurfaceAdapter({
    super.key,
    required this.profile,
    required this.projectName,
    required this.projectRootPath,
    required this.scene,
    this.aspectRatio = 16 / 9,
    this.reducedMotion = false,
    this.onTargeted,
    this.dialogueCharacter,
    this.showDialoguePortrait = true,
    this.showDialogueName = true,
    this.showDialogueChoices = false,
    this.battleState = PersonalizationBattlePreviewState.commands,
    this.contentSource = PersonalizationPreviewContentSource.project,
    this.mapContext,
    this.dialogueData,
    this.battleData,
    this.battleBackdropPath,
    this.enemyBattleSpritePath,
    this.playerBattleSpritePath,
    this.projectManifest,
    this.resolveTilesetPath,
    this.mapBackdropPlanLoader,
    this.titleStage = PersonalizationTitlePreviewStage.menu,
    this.titleMotionController,
    this.titleMotionDriverFactory,
    this.introPreviewController,
    this.introDriverFactory,
    this.allowMediaPlayback = true,
  });

  final ProjectPresentationProfile profile;
  final String projectName;
  final String projectRootPath;
  final PersonalizationStudioScene scene;
  final double aspectRatio;
  final bool reducedMotion;
  final ValueChanged<PersonalizationInspectorTarget>? onTargeted;
  final PersonalizationCharacterPreviewOption? dialogueCharacter;
  final bool showDialoguePortrait;
  final bool showDialogueName;
  final bool showDialogueChoices;
  final PersonalizationBattlePreviewState battleState;
  final PersonalizationPreviewContentSource contentSource;
  final MapData? mapContext;
  final PlayerDialogueViewData? dialogueData;
  final PlayerBattleViewData? battleData;
  final String? battleBackdropPath;
  final String? enemyBattleSpritePath;
  final String? playerBattleSpritePath;
  final ProjectManifest? projectManifest;
  final String? Function(String tilesetId)? resolveTilesetPath;
  final CinematicMapBackdropLayerPlanLoader? mapBackdropPlanLoader;
  final PersonalizationTitlePreviewStage titleStage;
  final PlayerTitleMotionController? titleMotionController;
  final PlayerIntroPlaybackFactory? titleMotionDriverFactory;
  final PlayerIntroVideoPreviewController? introPreviewController;
  final PlayerIntroPlaybackFactory? introDriverFactory;
  final bool allowMediaPlayback;

  @override
  Widget build(BuildContext context) {
    final editorColors = context.pokeMapColors;
    final editorTheme = Theme.of(context);
    final presentation = RuntimePlayerPresentation.fromProfile(
      profile,
      author: 'Créé avec PokeMap',
      description: 'Votre aventure commence ici.',
      imageForPath: _imageForPath,
    );
    final theme = presentation.applyTo(
      PokeMapPlayerTheme.dark(reducedMotion: reducedMotion),
    );
    final surface = switch (scene) {
      PersonalizationStudioScene.globalStyle => _globalTargetSurface(
        _globalStyle(presentation, editorColors, editorTheme),
      ),
      _ => _surface(scene, presentation, editorColors),
    };
    return Theme(
      data: theme,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRect(child: surface),
      ),
    );
  }

  Widget _globalTargetSurface(Widget child) => LayoutBuilder(
    builder: (context, constraints) => GestureDetector(
      key: const ValueKey<String>(
        'personalization-preview-target-global-style',
      ),
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final node = PersonalizationVisualTargetGraph.standard().hitTest(
          scene: PersonalizationStudioScene.globalStyle,
          normalizedPosition: Offset(
            details.localPosition.dx / constraints.maxWidth,
            details.localPosition.dy / constraints.maxHeight,
          ),
        );
        if (node != null) _target(node.target);
      },
      child: child,
    ),
  );

  Widget _surface(
    PersonalizationStudioScene target,
    RuntimePlayerPresentation presentation,
    PokeMapColorTokens editorColors,
  ) {
    final surface = switch (target) {
      PersonalizationStudioScene.title => _titleSurface(presentation),
      PersonalizationStudioScene.intro => _introSurface(),
      PersonalizationStudioScene.pause => PlayerPausePreviewShell(
        key: const ValueKey<String>('personalization-pause-composition'),
        gameTitle: projectName,
        actions: _pauseActions,
        presentation: presentation.pausePresentation,
        details: _pauseDetails,
        onSelected: (action) =>
            _target(PauseLabelsTarget(actionName: action.name)),
      ),
      PersonalizationStudioScene.dialogue =>
        dialogueData == null
            ? _unavailable(
                'Sélectionnez un dialogue du projet pour afficher cette scène.',
                const ValueKey<String>('personalization-dialogue-unavailable'),
              )
            : PlayerDialogueSurface(
                key: const ValueKey<String>(
                  'personalization-dialogue-composition',
                ),
                data: dialogueData!,
                showSpeakerName: showDialogueName,
                portraitBuilder:
                    showDialoguePortrait &&
                        (dialogueCharacter != null ||
                            contentSource ==
                                PersonalizationPreviewContentSource
                                    .demonstration)
                    ? (_) => _dialoguePortrait()
                    : null,
                onAction: (_) => _target(const DialogueAppearanceTarget()),
              ),
      PersonalizationStudioScene.battle =>
        battleData == null
            ? _unavailable(
                'Sélectionnez une rencontre du projet pour afficher cette scène.',
                const ValueKey<String>('personalization-battle-unavailable'),
              )
            : PlayerBattleScene(
                key: const ValueKey<String>(
                  'personalization-battle-composition',
                ),
                data: battleData!,
                onAction: (_) => _target(_battleTarget(battleState)),
                onHudTargeted: () => _target(const BattleHudTarget()),
                onPanelTargeted: (kind) => _target(switch (kind) {
                  PlayerBattlePanelKind.commands =>
                    const BattleCommandsTarget(),
                  PlayerBattlePanelKind.moves => const BattleMovesTarget(),
                  PlayerBattlePanelKind.target => const BattleTargetsTarget(),
                  PlayerBattlePanelKind.message => const BattleMessageTarget(),
                }),
                stage: _battleStage(editorColors),
              ),
      PersonalizationStudioScene.globalStyle => throw StateError(
        'Global style is a composition, not one player surface.',
      ),
    };
    if (target == PersonalizationStudioScene.battle && battleData != null) {
      return surface;
    }
    if (mapContext == null ||
        target == PersonalizationStudioScene.title ||
        target == PersonalizationStudioScene.intro) {
      return surface;
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        PersonalizationProjectMapBackdrop(
          map: mapContext!,
          colors: editorColors,
          projectRootPath: projectRootPath,
          manifest: projectManifest,
          resolveTilesetPath: resolveTilesetPath,
          planLoader: mapBackdropPlanLoader,
        ),
        surface,
      ],
    );
  }

  Widget _battleStage(PokeMapColorTokens editorColors) {
    final file = battleBackdropPath == null
        ? null
        : _fileForPath(battleBackdropPath!);
    final fallback = mapContext == null
        ? Builder(
            builder: (context) =>
                ColoredBox(color: context.playerColors.background),
          )
        : PersonalizationProjectMapBackdrop(
            map: mapContext!,
            colors: editorColors,
            projectRootPath: projectRootPath,
            manifest: projectManifest,
            resolveTilesetPath: resolveTilesetPath,
            planLoader: mapBackdropPlanLoader,
          );
    final background = file == null || !file.existsSync()
        ? battleBackdropPath == null
              ? fallback
              : _missingBattleStage(fallback)
        : Image.file(
            file,
            key: const ValueKey<String>('personalization-battle-project-stage'),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _missingBattleStage(fallback),
          );
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        background,
        _battleCreature(
          path: enemyBattleSpritePath,
          alignment: const Alignment(.58, -.34),
          key: const ValueKey<String>('personalization-battle-enemy-sprite'),
        ),
        _battleCreature(
          path: playerBattleSpritePath,
          alignment: const Alignment(-.58, .18),
          key: const ValueKey<String>('personalization-battle-player-sprite'),
        ),
      ],
    );
  }

  Widget _battleCreature({
    required String? path,
    required Alignment alignment,
    required Key key,
  }) {
    final file = path == null ? null : _fileForPath(path);
    if (file == null || !file.existsSync()) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: .28,
        heightFactor: .28,
        child: Image.file(
          file,
          key: key,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }

  Widget _missingBattleStage(Widget fallback) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      fallback,
      const Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.all(PlayerSpacing.sm),
          child: PlayerBadge(
            key: ValueKey<String>('personalization-battle-stage-missing'),
            label: 'Décor de combat introuvable',
            icon: Icons.warning_amber_rounded,
            tone: PlayerBadgeTone.warning,
          ),
        ),
      ),
    ],
  );

  Widget _globalStyle(
    RuntimePlayerPresentation presentation,
    PokeMapColorTokens editorColors,
    ThemeData editorTheme,
  ) => ColoredBox(
    key: const ValueKey<String>('personalization-global-style-composition'),
    color: presentation
        .applyTo(PokeMapPlayerTheme.dark(reducedMotion: reducedMotion))
        .scaffoldBackgroundColor,
    child: GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: aspectRatio,
      children: <Widget>[
        _miniature(
          'title',
          'Écran titre',
          _surface(
            PersonalizationStudioScene.title,
            presentation,
            editorColors,
          ),
          editorTheme,
        ),
        _miniature(
          'dialogue',
          'Dialogue',
          _surface(
            PersonalizationStudioScene.dialogue,
            presentation,
            editorColors,
          ),
          editorTheme,
        ),
        _miniature(
          'pause',
          'Menu Pause',
          _surface(
            PersonalizationStudioScene.pause,
            presentation,
            editorColors,
          ),
          editorTheme,
        ),
        _miniature(
          'battle',
          'Combat',
          _surface(
            PersonalizationStudioScene.battle,
            presentation,
            editorColors,
          ),
          editorTheme,
        ),
      ],
    ),
  );

  Widget _miniature(
    String id,
    String label,
    Widget child,
    ThemeData editorTheme,
  ) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      IgnorePointer(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: aspectRatio < 1 ? 450 : 960,
            height: aspectRatio < 1 ? 800 : 540,
            child: child,
          ),
        ),
      ),
      Positioned(
        top: 8,
        left: 8,
        child: Theme(
          data: editorTheme,
          child: PokeMapBadge(
            key: ValueKey<String>('personalization-global-preview-$id'),
            label: label,
            variant: PokeMapBadgeVariant.info,
          ),
        ),
      ),
    ],
  );

  Widget _introSurface() {
    final intro = profile.intro;
    if (intro == null) {
      return PlayerIntroVideoSurface(
        key: const ValueKey<String>('personalization-intro-composition'),
        media: null,
        isPoster: true,
        failureMessage: 'Aucune introduction configurée',
        onSkip: () => _target(const IntroPresentationTarget()),
        onContinue: () => _target(const IntroPresentationTarget()),
      );
    }
    final variant = _introVariant;
    final video = _fileForPath(variant.videoPath);
    final poster = _fileForPath(variant.posterPath);
    final captions = variant.captionsPath == null
        ? null
        : _fileForPath(variant.captionsPath!);
    return PlayerIntroVideoPreview(
      key: const ValueKey<String>('personalization-intro-composition'),
      controller: introPreviewController,
      source: video == null || !video.existsSync()
          ? null
          : PlayerIntroVideoSource(
              videoUri: video.uri,
              captionsLoader: captions == null || !captions.existsSync()
                  ? null
                  : captions.readAsString,
              aspectRatio: variant.width / variant.height,
              focalX: variant.focalX,
              focalY: variant.focalY,
            ),
      poster: poster == null || !poster.existsSync() ? null : FileImage(poster),
      driverFactory: introDriverFactory,
      reducedMotion: reducedMotion || !allowMediaPlayback,
      reducedMotionBehavior:
          allowMediaPlayback && intro.reducedMotionBehavior == 'skip'
          ? PlayerIntroPreviewReducedMotionBehavior.skip
          : PlayerIntroPreviewReducedMotionBehavior.poster,
      allowReplay: intro.allowReplay,
      onInteraction: () => _target(const IntroPresentationTarget()),
    );
  }

  ProjectVideoVariantProfile get _introVariant {
    final intro = profile.intro!;
    return aspectRatio < 1
        ? intro.media.portrait ?? intro.media.landscape
        : intro.media.landscape;
  }

  Widget _titleSurface(RuntimePlayerPresentation presentation) =>
      switch (titleStage) {
        PersonalizationTitlePreviewStage.prompt => PlayerTitlePromptSurface(
          key: const ValueKey<String>(
            'personalization-title-prompt-composition',
          ),
          gameTitle: presentation.title.resolveTitle(projectName),
          background: presentation.title.background,
          logo: presentation.title.logo,
          backgroundContent: _titleMotion(profile.titleMotion?.promptLoop),
          eyebrow: presentation.title.author,
          footer: projectName,
          onStart: () => _target(const TitlePresentationTarget()),
        ),
        PersonalizationTitlePreviewStage.menu => PlayerTitleSurface(
          key: const ValueKey<String>('personalization-title-composition'),
          data: _titleData(
            presentation,
            _titleMotion(profile.titleMotion?.menuLoop),
          ),
          onSelected: (_) => _target(const TitlePresentationTarget()),
        ),
      };

  PlayerTitleSurfaceData _titleData(
    RuntimePlayerPresentation presentation,
    Widget? backgroundContent,
  ) => PlayerTitleSurfaceData(
    gameTitle: presentation.title.resolveTitle(projectName),
    author: presentation.title.author,
    description: presentation.title.description,
    background: presentation.title.background,
    backgroundContent: backgroundContent,
    logo: presentation.title.logo,
    accentColor: presentation.title.accentColor,
    layoutVariant: presentation.title.layoutVariant,
    actions: presentation.title
        .projectActions(<PlayerTitleMenuAction, PlayerActionAvailability>{
          for (final action in PlayerTitleMenuAction.values)
            action: PlayerActionAvailability.enabled,
        }),
    actionLabels: presentation.title.actionLabels,
    actionIcons: presentation.title.actionIcons,
    initialSelection: PlayerTitleMenuAction.newGame,
  );

  static Map<PlayerPauseAction, PlayerActionAvailability> get _pauseActions =>
      <PlayerPauseAction, PlayerActionAvailability>{
        for (final action in PlayerPauseAction.values)
          action: PlayerActionAvailability.enabled,
      };

  static Map<PlayerPauseAction, PlayerPausePreviewDetailData>
  get _pauseDetails => <PlayerPauseAction, PlayerPausePreviewDetailData>{
    for (final action in PlayerPauseAction.values)
      action: PlayerPausePreviewDetailData(
        action: action,
        title: _pauseActionTitle(action),
        message:
            'Le contenu de cette section dépend de la sauvegarde en cours.',
      ),
  };

  static String _pauseActionTitle(PlayerPauseAction action) => switch (action) {
    PlayerPauseAction.resume => 'Reprendre la partie',
    PlayerPauseAction.party => 'Équipe',
    PlayerPauseAction.bag => 'Sac',
    PlayerPauseAction.pokedex => 'Pokédex',
    PlayerPauseAction.map => 'Carte',
    PlayerPauseAction.save => 'Sauvegarder',
    PlayerPauseAction.options => 'Options',
    PlayerPauseAction.returnToTitle => 'Retour au titre',
  };

  Widget? _titleMotion(ProjectResponsiveVideoProfile? media) {
    if (media == null) return null;
    final variant = aspectRatio < 1
        ? media.portrait ?? media.landscape
        : media.landscape;
    final video = _fileForPath(variant.videoPath);
    final poster = _fileForPath(variant.posterPath);
    return PlayerTitleMotion(
      controller: titleMotionController,
      source: video == null || !video.existsSync()
          ? null
          : PlayerIntroVideoSource(
              videoUri: video.uri,
              looping: true,
              aspectRatio: variant.width / variant.height,
              focalX: variant.focalX,
              focalY: variant.focalY,
            ),
      poster: poster == null || !poster.existsSync() ? null : FileImage(poster),
      driverFactory: titleMotionDriverFactory,
      reducedMotion: reducedMotion || !allowMediaPlayback,
    );
  }

  Widget _dialoguePortrait() {
    if (contentSource == PersonalizationPreviewContentSource.demonstration) {
      return Builder(
        builder: (context) => DecoratedBox(
          key: const ValueKey<String>('personalization-dialogue-demo-portrait'),
          decoration: BoxDecoration(
            color: context.playerColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.playerColors.outline),
          ),
          child: Icon(
            Icons.person_rounded,
            color: context.playerColors.primary,
            size: 42,
          ),
        ),
      );
    }
    final bytes = dialogueCharacter?.portraitBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return ClipRRect(
        key: const ValueKey<String>('personalization-dialogue-portrait'),
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover),
      );
    }
    final path = dialogueCharacter?.portraitPath;
    final file = path == null ? null : _fileForPath(path);
    if (file != null && file.existsSync()) {
      return ClipRRect(
        key: const ValueKey<String>('personalization-dialogue-portrait'),
        borderRadius: BorderRadius.circular(12),
        child: Image.file(file, fit: BoxFit.cover),
      );
    }
    return Builder(
      builder: (context) => DecoratedBox(
        key: const ValueKey<String>('personalization-dialogue-portrait'),
        decoration: BoxDecoration(
          color: context.playerColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.playerColors.outline),
        ),
        child: Icon(
          Icons.person_rounded,
          color: context.playerColors.primary,
          size: 42,
        ),
      ),
    );
  }

  void _target(PersonalizationInspectorTarget target) =>
      onTargeted?.call(target);

  PersonalizationInspectorTarget _battleTarget(
    PersonalizationBattlePreviewState state,
  ) => switch (state) {
    PersonalizationBattlePreviewState.commands => const BattleCommandsTarget(),
    PersonalizationBattlePreviewState.moves => const BattleMovesTarget(),
    PersonalizationBattlePreviewState.target => const BattleTargetsTarget(),
    PersonalizationBattlePreviewState.message => const BattleMessageTarget(),
  };

  Widget _unavailable(String message, Key key) => Center(
    key: key,
    child: PlayerPanel(
      elevated: true,
      padding: const EdgeInsets.all(PlayerSpacing.lg),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );

  ImageProvider? _imageForPath(String assetPath) {
    final file = _fileForPath(assetPath);
    return file == null || !file.existsSync() ? null : FileImage(file);
  }

  File? _fileForPath(String assetPath) {
    final value = assetPath.trim();
    if (value.isEmpty) return null;
    return File(p.isAbsolute(value) ? value : p.join(projectRootPath, value));
  }
}
