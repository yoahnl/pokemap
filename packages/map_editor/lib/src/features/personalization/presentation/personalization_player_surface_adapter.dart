import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:path/path.dart' as p;

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/personalization_character_preview_source.dart';
import '../application/personalization_preview_fixtures.dart';
import '../application/personalization_inspector_target.dart';
import '../application/personalization_preview_surface_descriptor.dart';
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
    this.mapContext,
    this.dialogueData,
    this.battleData,
    this.useProjectContent = false,
    this.projectManifest,
    this.resolveTilesetPath,
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
  final MapData? mapContext;
  final PlayerDialogueViewData? dialogueData;
  final PlayerBattleViewData? battleData;
  final bool useProjectContent;
  final ProjectManifest? projectManifest;
  final String? Function(String tilesetId)? resolveTilesetPath;
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
      PersonalizationStudioScene.globalStyle => GestureDetector(
        key: const ValueKey<String>(
          'personalization-preview-target-global-colors',
        ),
        behavior: HitTestBehavior.opaque,
        onTap: () => _target(const GlobalColorsTarget()),
        child: _globalStyle(presentation, editorColors, editorTheme),
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
        actions: PersonalizationPreviewFixtures.pauseActions,
        presentation: presentation.pausePresentation,
        details: PersonalizationPreviewFixtures.pauseDetails,
        onSelected: (action) =>
            _target(PauseLabelsTarget(actionName: action.name)),
      ),
      PersonalizationStudioScene.dialogue => PlayerDialogueSurface(
        key: const ValueKey<String>('personalization-dialogue-composition'),
        data:
            dialogueData ??
            (dialogueCharacter == null && !showDialogueChoices
                ? PersonalizationPreviewFixtures.dialogue
                : PersonalizationPreviewFixtures.dialogueFor(
                    speaker:
                        dialogueCharacter?.displayName ??
                        'Personnage de démonstration',
                    showChoices: showDialogueChoices,
                  )),
        showSpeakerName: showDialogueName,
        portraitBuilder: showDialoguePortrait && dialogueCharacter != null
            ? (_) => _dialoguePortrait()
            : null,
        onAction: (_) => _target(const DialogueAppearanceTarget()),
      ),
      PersonalizationStudioScene.battle => PlayerBattleSurface(
        key: const ValueKey<String>('personalization-battle-composition'),
        data:
            battleData ?? PersonalizationPreviewFixtures.battleFor(battleState),
        onAction: (_) => _target(const BattleCommandsTarget()),
      ),
      PersonalizationStudioScene.globalStyle => throw StateError(
        'Global style is a composition, not one player surface.',
      ),
    };
    final unavailable = switch (target) {
      PersonalizationStudioScene.dialogue
          when useProjectContent && dialogueData == null =>
        _unavailable(
          'Aucun dialogue exploitable pour cet aperçu.',
          const ValueKey<String>('personalization-dialogue-unavailable'),
        ),
      PersonalizationStudioScene.battle
          when useProjectContent && battleData == null =>
        _unavailable(
          'Aucune rencontre exploitable pour cet aperçu.',
          const ValueKey<String>('personalization-battle-unavailable'),
        ),
      _ => surface,
    };
    if (mapContext == null ||
        target == PersonalizationStudioScene.title ||
        target == PersonalizationStudioScene.intro) {
      return unavailable;
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
        ),
        unavailable,
      ],
    );
  }

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
          data: PersonalizationPreviewFixtures.title(
            projectName,
            presentation,
            backgroundContent: _titleMotion(profile.titleMotion?.menuLoop),
          ),
          onSelected: (_) => _target(const TitlePresentationTarget()),
        ),
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
