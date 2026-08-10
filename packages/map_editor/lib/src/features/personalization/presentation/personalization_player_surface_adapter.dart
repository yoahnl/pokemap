import 'dart:io';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:path/path.dart' as p;

import '../application/personalization_preview_fixtures.dart';
import '../application/personalization_preview_surface_descriptor.dart';

class PersonalizationPlayerSurfaceAdapter extends StatelessWidget {
  const PersonalizationPlayerSurfaceAdapter({
    super.key,
    required this.profile,
    required this.projectName,
    required this.projectRootPath,
    required this.scene,
    this.aspectRatio = 16 / 9,
    this.reducedMotion = false,
  });

  final ProjectPresentationProfile profile;
  final String projectName;
  final String projectRootPath;
  final PersonalizationStudioScene scene;
  final double aspectRatio;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final presentation = RuntimePlayerPresentation.fromProfile(
      profile,
      imageForPath: _imageForPath,
    );
    final theme = presentation.applyTo(
      PokeMapPlayerTheme.dark(reducedMotion: reducedMotion),
    );
    return Theme(
      data: theme,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRect(
          child: switch (scene) {
            PersonalizationStudioScene.globalStyle => _globalStyle(
              presentation,
            ),
            _ => _surface(scene, presentation),
          },
        ),
      ),
    );
  }

  Widget _surface(
    PersonalizationStudioScene target,
    RuntimePlayerPresentation presentation,
  ) => switch (target) {
    PersonalizationStudioScene.title => PlayerTitleSurface(
      key: const ValueKey<String>('personalization-title-composition'),
      data: PersonalizationPreviewFixtures.title(projectName, presentation),
      onSelected: (_) {},
    ),
    PersonalizationStudioScene.intro => PlayerIntroVideoSurface(
      key: const ValueKey<String>('personalization-intro-composition'),
      media: _introSkipped ? null : _introMedia(),
      isPoster: true,
      failureMessage: _introSkipped
          ? 'Intro ignorée avec les animations réduites'
          : profile.intro == null
          ? 'Aucune introduction configurée'
          : null,
      onSkip: () {},
      onContinue: () {},
    ),
    PersonalizationStudioScene.pause => RuntimePlayerPauseShell.root(
      key: const ValueKey<String>('personalization-pause-composition'),
      gameTitle: projectName,
      actions: PersonalizationPreviewFixtures.pauseActions,
      labels: presentation.pauseMenuLabels,
      onSelected: (_) {},
      detail: const Center(child: Text('Sélectionnez une section')),
    ),
    PersonalizationStudioScene.dialogue => PlayerDialogueSurface(
      key: const ValueKey<String>('personalization-dialogue-composition'),
      data: PersonalizationPreviewFixtures.dialogue,
      onAction: (_) {},
    ),
    PersonalizationStudioScene.battle => PlayerBattleSurface(
      key: const ValueKey<String>('personalization-battle-composition'),
      data: PersonalizationPreviewFixtures.battle,
      onAction: (_) {},
    ),
    PersonalizationStudioScene.globalStyle => throw StateError(
      'Global style is a composition, not one player surface.',
    ),
  };

  Widget _globalStyle(RuntimePlayerPresentation presentation) => ColoredBox(
    key: const ValueKey<String>('personalization-global-style-composition'),
    color: presentation
        .applyTo(PokeMapPlayerTheme.dark(reducedMotion: reducedMotion))
        .scaffoldBackgroundColor,
    child: GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: aspectRatio,
      children: <Widget>[
        _miniature(_surface(PersonalizationStudioScene.title, presentation)),
        _miniature(_surface(PersonalizationStudioScene.dialogue, presentation)),
        _miniature(_surface(PersonalizationStudioScene.pause, presentation)),
        _miniature(_surface(PersonalizationStudioScene.battle, presentation)),
      ],
    ),
  );

  Widget _miniature(Widget child) => IgnorePointer(
    child: FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(width: 960, height: 540, child: child),
    ),
  );

  Widget? _introMedia() {
    final intro = profile.intro;
    if (intro == null) return null;
    final variant = aspectRatio < 1
        ? intro.media.portrait ?? intro.media.landscape
        : intro.media.landscape;
    final poster = _fileForPath(variant.posterPath);
    if (poster == null || !poster.existsSync()) return null;
    return Image.file(poster, fit: BoxFit.cover);
  }

  bool get _introSkipped =>
      reducedMotion && profile.intro?.reducedMotionBehavior == 'skip';

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
