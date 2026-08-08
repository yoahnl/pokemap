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
              onAddGame: onAddGame,
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
    return Stack(
      key: const ValueKey<String>('avelune-console-ledge'),
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color.lerp(colors.surfaceRaised, finish, 0.2)!,
                colors.surfaceInset,
              ],
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
        Opacity(
          opacity: 0.12,
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
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  colors.warning.withValues(alpha: 0),
                  colors.warning.withValues(alpha: 0.34),
                  colors.warning.withValues(alpha: 0),
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.warning.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ],
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
