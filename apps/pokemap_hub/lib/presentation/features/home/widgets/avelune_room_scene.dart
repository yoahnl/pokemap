import 'package:flutter/material.dart';

import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_catalog.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_geometry.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_cartridge.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_console.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_game_shelf.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/presentation/shared/artwork/appearance_asset_path.dart';
import 'package:pokemap_hub/presentation/shared/artwork/local_artwork_image.dart';

@immutable
final class AveluneRoomSceneLayout {
  const AveluneRoomSceneLayout._({
    required this.windowRect,
    required this.consoleLedgeRect,
    required this.librarySheetRect,
    required this.shelfRect,
    required this.consoleSupportY,
    required this.shelfBaselineY,
  });

  factory AveluneRoomSceneLayout.resolve(AveluneHomeGeometry geometry) =>
      AveluneRoomSceneLayout._(
        windowRect: geometry.cabinWindowRect,
        consoleLedgeRect: geometry.consoleLedgeRect,
        librarySheetRect: geometry.librarySheetRect,
        shelfRect: geometry.shelfRect,
        consoleSupportY: geometry.consoleFootlineY,
        shelfBaselineY: geometry.anchors.shelfBaseline.dy,
      );

  final Rect windowRect;
  final Rect consoleLedgeRect;
  final Rect librarySheetRect;
  final Rect shelfRect;
  final double consoleSupportY;
  final double shelfBaselineY;
}

class AveluneRoomScene extends StatelessWidget {
  const AveluneRoomScene({
    super.key,
    required this.geometry,
    required this.appearance,
    required this.games,
    required this.selectedGame,
    this.customBackground,
    this.consoleState,
    this.insertionProgress = 0,
    this.onGameSelected,
    this.onShelfGameLongPress,
    this.onAddGame,
    this.onHeroPressed,
    this.onHeroLongPress,
    this.heroAnchorKey,
    this.heroArtworkHeroTag,
    this.shelfCartridgeKeyFor,
    this.shelfArtworkHeroGameId,
    this.hiddenShelfGameIds = const <String>{},
    this.showHero = true,
    this.insertionOverlay,
    this.foregroundOverlay,
    this.heroSemanticsLabel,
    this.showPlayHint = false,
    this.referenceTime,
  });

  final AveluneHomeGeometry geometry;
  final AveluneAppearancePreferences appearance;
  final List<AveluneGameViewData> games;
  final AveluneGameViewData? selectedGame;
  final ImageProvider<Object>? customBackground;
  final AveluneConsoleState? consoleState;
  final double insertionProgress;
  final ValueChanged<AveluneGameViewData>? onGameSelected;
  final ValueChanged<AveluneGameViewData>? onShelfGameLongPress;
  final VoidCallback? onAddGame;
  final VoidCallback? onHeroPressed;
  final VoidCallback? onHeroLongPress;
  final GlobalKey? heroAnchorKey;
  final Object? heroArtworkHeroTag;
  final GlobalKey Function(String gameId)? shelfCartridgeKeyFor;
  final String? shelfArtworkHeroGameId;
  final Set<String> hiddenShelfGameIds;
  final bool showHero;
  final Widget? insertionOverlay;
  final Widget? foregroundOverlay;
  final String? heroSemanticsLabel;
  final bool showPlayHint;
  final DateTime? referenceTime;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final roomLayout = AveluneRoomSceneLayout.resolve(geometry);
    final selected = selectedGame;
    final guideBeamWidth = geometry.heroCartridgeSize.width * 0.18;
    final guideBeamRect = Rect.fromLTRB(
      geometry.viewportSize.width / 2 - guideBeamWidth / 2,
      geometry.heroCartridgeRect.bottom - 3,
      geometry.viewportSize.width / 2 + guideBeamWidth / 2,
      geometry.consoleSlotMouthY + 2,
    );
    // [games] contains only shelf games: the selected cartridge is removed by
    // the home controller so it cannot appear twice. A one-game library is
    // therefore empty here while still having a real selected hero.
    final libraryEmpty = selected == null && games.isEmpty;

    return SizedBox.expand(
      key: const ValueKey<String>('avelune-room-scene'),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          ColoredBox(color: colors.canvas),
          Positioned.fromRect(
            rect: roomLayout.windowRect.inflate(8),
            child: _AveluneCabinWindow(
              background: _backgroundFor(appearance, customBackground),
              finishId: appearance.furnitureId,
            ),
          ),
          Positioned.fromRect(
            rect: roomLayout.consoleLedgeRect,
            child: _AveluneConsoleLedge(finishId: appearance.furnitureId),
          ),
          Positioned.fromRect(
            rect: roomLayout.librarySheetRect,
            child: const _AveluneLibrarySheetSurface(),
          ),
          Positioned(
            left: geometry.contentRect.left,
            right: geometry.viewportSize.width - geometry.contentRect.right,
            top: roomLayout.consoleSupportY - 0.5,
            height: 1,
            child: const SizedBox(
              key: ValueKey<String>('avelune-console-support-anchor'),
            ),
          ),
          Positioned.fromRect(
            rect: geometry.consoleRect,
            child: AveluneConsole(
              state: consoleState,
              insertionProgress: insertionProgress,
            ),
          ),
          if (insertionOverlay != null)
            Positioned.fill(
              child: ClipRect(
                key: const ValueKey<String>('avelune-slot-mouth-clip'),
                clipper: _AveluneSlotMouthClipper(geometry.consoleSlotMouthY),
                child: insertionOverlay!,
              ),
            ),
          if (selected != null)
            Positioned.fromRect(
              rect: guideBeamRect,
              child: AnimatedOpacity(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : context.aveluneMotion.detailsReveal,
                curve: Curves.easeOutCubic,
                opacity: showHero ? 1 : 0,
                child: const _AveluneCartridgeSlotGuideBeam(),
              ),
            ),
          if (selected != null) ...<Widget>[
            Positioned.fromRect(
              rect: geometry.heroCartridgeRect.inflate(
                geometry.heroCartridgeSize.width * 0.25,
              ),
              child: Visibility(
                visible: showHero,
                maintainAnimation: true,
                maintainSize: true,
                maintainState: true,
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey<String>('avelune-room-hero-glow'),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: <Color>[
                          colors.glow.withValues(alpha: 0.36),
                          colors.glow.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: geometry.heroCartridgeRect,
              child: KeyedSubtree(
                key: heroAnchorKey,
                child: Visibility(
                  visible: showHero,
                  maintainAnimation: true,
                  maintainSize: true,
                  maintainState: true,
                  child: AveluneCartridge(
                    key: const ValueKey<String>(
                      'avelune-room-hero-cartridge',
                    ),
                    gameId: selected.id,
                    title: selected.title,
                    subtitle: selected.subtitle,
                    artwork: _artworkFor(selected.artwork),
                    shellColor: selected.shellColor,
                    selected: true,
                    invalid: !selected.isValid,
                    displaySize: AveluneCartridgeDisplaySize.hero,
                    artworkHeroTag: heroArtworkHeroTag,
                    onPressed: onHeroPressed,
                    onLongPress: onHeroLongPress,
                    semanticsLabel: heroSemanticsLabel,
                  ),
                ),
              ),
            ),
          ],
          if (libraryEmpty) ...<Widget>[
            Positioned.fromRect(
              rect: geometry.heroCartridgeRect.inflate(
                geometry.heroCartridgeSize.width * 0.25,
              ),
              child: IgnorePointer(
                child: DecoratedBox(
                  key: const ValueKey<String>('avelune-room-hero-add-glow'),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: <Color>[
                        colors.glow.withValues(alpha: 0.26),
                        colors.glow.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: geometry.heroCartridgeRect,
              child: AveluneCartridge.addGame(
                key: const ValueKey<String>(
                  'avelune-room-hero-add-cartridge',
                ),
                displaySize: AveluneCartridgeDisplaySize.hero,
                onPressed: onAddGame,
              ),
            ),
          ],
          Positioned.fromRect(
            rect: Rect.fromLTRB(
              roomLayout.librarySheetRect.left,
              roomLayout.librarySheetRect.top,
              roomLayout.librarySheetRect.right,
              roomLayout.shelfRect.top,
            ),
            child: _AveluneLibraryHeader(
              hasSelectedGame: selected != null,
              showPlayHint: showPlayHint,
              onAddGame: libraryEmpty ? null : onAddGame,
            ),
          ),
          Positioned.fromRect(
            rect: roomLayout.shelfRect,
            child: AveluneGameShelf(
              geometry: geometry,
              games: games,
              selectedGameId: selected?.id,
              onGameSelected: onGameSelected,
              onGameLongPress: onShelfGameLongPress,
              onAddGame: onAddGame,
              includeAddGame: !libraryEmpty,
              cartridgeKeyFor: shelfCartridgeKeyFor,
              artworkHeroGameId: shelfArtworkHeroGameId,
              hiddenGameIds: hiddenShelfGameIds,
            ),
          ),
          if (foregroundOverlay != null)
            Positioned.fill(child: foregroundOverlay!),
        ],
      ),
    );
  }
}

class _AveluneCabinWindow extends StatelessWidget {
  const _AveluneCabinWindow({
    required this.background,
    required this.finishId,
  });

  final ImageProvider<Object> background;
  final String finishId;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final finish = aveluneCabinFinishColor(colors, finishId);
    return DecoratedBox(
      key: const ValueKey<String>('avelune-cabin-frame'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AveluneShapes.radiusXl + 10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(colors.surfaceRaised, finish, 0.18)!,
            colors.canvas,
            Color.lerp(colors.surface, finish, 0.1)!,
          ],
        ),
        border: Border.all(color: colors.outline.withValues(alpha: 0.62)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.canvas.withValues(alpha: 0.86),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AveluneShapes.radiusXl + 9),
            child: Opacity(
              opacity: 0.16,
              child: Image.asset(
                kAveluneMatteAbsTextureAssetPath,
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
                filterQuality: FilterQuality.low,
                excludeFromSemantics: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              key: const ValueKey<String>('avelune-cabin-window'),
              borderRadius: AveluneShapes.xl,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image(
                    key: const ValueKey<String>(
                      'avelune-room-background-layer',
                    ),
                    image: background,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                    errorBuilder: (_, __, ___) =>
                        ColoredBox(color: colors.room),
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      key: const ValueKey<String>('avelune-room-light-layer'),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const <double>[0, 0.5, 1],
                          colors: <Color>[
                            colors.canvas.withValues(alpha: 0.02),
                            colors.canvas.withValues(alpha: 0.09),
                            colors.canvas.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AveluneShapes.xl,
                      border: Border.all(
                        color: colors.focus.withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AveluneConsoleLedge extends StatelessWidget {
  const _AveluneConsoleLedge({required this.finishId});

  final String finishId;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final finish = aveluneCabinFinishColor(colors, finishId);
    final furnitureAsset = appearanceAssetPath(
      AveluneAppearanceCatalog.furnitureFinish(finishId),
    )!;
    return ClipRect(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          const sourceAspectRatio = 768 / 700;
          const sourceTopOffset = 198 / 700;
          final renderedHeight = constraints.maxWidth / sourceAspectRatio;
          return Stack(
            key: const ValueKey<String>('avelune-console-ledge'),
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                key: const ValueKey<String>(
                  'avelune-console-ledge-finish-surface',
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color.lerp(colors.surfaceRaised, finish, 0.44)!,
                      Color.lerp(colors.surface, finish, 0.5)!,
                      Color.lerp(finish, colors.warning, 0.18)!,
                    ],
                    stops: const <double>[0, 0.58, 1],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: colors.ivoryHighlight.withValues(alpha: 0.32),
                    ),
                    bottom: BorderSide(
                      color: colors.warning.withValues(alpha: 0.36),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -renderedHeight * sourceTopOffset),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    furnitureAsset,
                    key: const ValueKey<String>(
                      'avelune-room-furniture-layer',
                    ),
                    width: constraints.maxWidth,
                    height: renderedHeight,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              Opacity(
                opacity: 0.07,
                child: Image.asset(
                  kAveluneMatteAbsTextureAssetPath,
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeat,
                  filterQuality: FilterQuality.low,
                  excludeFromSemantics: true,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        colors.warning.withValues(alpha: 0),
                        colors.warning.withValues(alpha: 0.4),
                        colors.warning.withValues(alpha: 0),
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.warning.withValues(alpha: 0.22),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AveluneCartridgeSlotGuideBeam extends StatelessWidget {
  const _AveluneCartridgeSlotGuideBeam();

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Stack(
            key: const ValueKey<String>(
              'avelune-cartridge-slot-guide-beam',
            ),
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      colors.glow.withValues(alpha: 0),
                      colors.glow.withValues(alpha: 0.32),
                      colors.glow.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: colors.ivoryHighlight.withValues(alpha: 0.88),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.glow.withValues(alpha: 0.9),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AveluneLibrarySheetSurface extends StatelessWidget {
  const _AveluneLibrarySheetSurface();

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return DecoratedBox(
      key: const ValueKey<String>('avelune-library-sheet'),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AveluneShapes.radiusXl + 10),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[colors.ivoryHighlight, colors.ivory],
        ),
        border: Border(
          top: BorderSide(
            color: colors.ivoryHighlight.withValues(alpha: 0.96),
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.canvas.withValues(alpha: 0.46),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AveluneShapes.radiusXl + 10),
        ),
        child: Opacity(
          opacity: 0.025,
          child: Image.asset(
            kAveluneMatteAbsTextureAssetPath,
            fit: BoxFit.cover,
            repeat: ImageRepeat.repeat,
            filterQuality: FilterQuality.low,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

class _AveluneLibraryHeader extends StatelessWidget {
  const _AveluneLibraryHeader({
    required this.hasSelectedGame,
    required this.showPlayHint,
    required this.onAddGame,
  });

  final bool hasSelectedGame;
  final bool showPlayHint;
  final VoidCallback? onAddGame;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.maybeLocaleOf(context)?.languageCode == 'fr';
    final foreground = colors.room;
    final muted = colors.surfaceRaised.withValues(alpha: 0.64);

    return Stack(
      key: const ValueKey<String>('avelune-library-header'),
      children: <Widget>[
        Align(
          alignment: const Alignment(0, -0.82),
          child: Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: colors.wood.withValues(alpha: 0.34),
              borderRadius: AveluneShapes.pill,
            ),
          ),
        ),
        Positioned(
          left: AveluneSpacing.xl,
          right: AveluneSpacing.lg,
          top: 17,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  french ? 'Bibliothèque' : 'Library',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (onAddGame case final callback?)
                AvelunePressable(
                  key: const ValueKey<String>('avelune-library-header-add'),
                  semanticLabel: french ? 'Ajouter un jeu' : 'Add a game',
                  onPressed: callback,
                  borderRadius: AveluneShapes.pill,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AveluneSpacing.xs,
                      vertical: AveluneSpacing.xxs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          french ? 'Ajouter' : 'Add',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colors.accent,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(width: AveluneSpacing.xs),
                        Icon(
                          AveluneIcons.addGame,
                          color: colors.accent,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.86),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AveluneSpacing.lg),
            child: Row(
              key: showPlayHint
                  ? const ValueKey<String>('avelune-library-play-hint')
                  : const ValueKey<String>('avelune-library-status-hint'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (showPlayHint) ...<Widget>[
                  Icon(
                    AveluneIcons.motionOn,
                    size: 12,
                    color: colors.accent.withValues(alpha: 0.64),
                  ),
                  const SizedBox(width: AveluneSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    showPlayHint
                        ? (french
                            ? 'Touchez la cartouche pour jouer'
                            : 'Tap the cartridge to play')
                        : (!hasSelectedGame
                            ? (french
                                ? 'Ajoutez votre première cartouche'
                                : 'Add your first cartridge')
                            : (french
                                ? 'Jeu indisponible'
                                : 'Game unavailable')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: showPlayHint ? muted : foreground,
                          letterSpacing: 0.15,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AveluneSlotMouthClipper extends CustomClipper<Rect> {
  const _AveluneSlotMouthClipper(this.mouthY);

  final double mouthY;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width, mouthY);

  @override
  bool shouldReclip(_AveluneSlotMouthClipper oldClipper) =>
      oldClipper.mouthY != mouthY;
}

ImageProvider<Object> aveluneRoomBackgroundImage(
  AveluneAppearancePreferences appearance,
  ImageProvider<Object>? customBackground,
) =>
    _backgroundFor(appearance, customBackground);

ImageProvider<Object> _backgroundFor(
  AveluneAppearancePreferences appearance,
  ImageProvider<Object>? customBackground,
) {
  if (appearance.backgroundId == AveluneAppearanceCatalog.customBackgroundId &&
      customBackground != null) {
    return customBackground;
  }
  final id =
      appearance.backgroundId == AveluneAppearanceCatalog.customBackgroundId
          ? AveluneAppearanceCatalog.defaultBackgroundId
          : appearance.backgroundId;
  return AssetImage(
    appearanceAssetPath(AveluneAppearanceCatalog.background(id))!,
  );
}

ImageProvider<Object>? _artworkFor(AveluneArtworkViewData artwork) {
  final path = artwork.path;
  if (path == null || path.trim().isEmpty) return null;
  return requireLocalArtworkImage(path);
}
