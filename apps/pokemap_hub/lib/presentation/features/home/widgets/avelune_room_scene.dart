import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_catalog.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_cartridge.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_console.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_game_shelf.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_game_presentation.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_geometry.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';
import 'package:pokemap_hub/presentation/shared/artwork/local_artwork_image.dart';
import 'package:pokemap_hub/presentation/shared/artwork/appearance_asset_path.dart';

/// How far the cartridges stand above the shelf board's front lip, as a
/// fraction of the alcove height.
///
/// The board recedes in perspective, so a cartridge resting toward the back of
/// the shelf reads as sitting higher than the lip. Without the lift its base
/// lands exactly on the alcove's bottom edge, which makes it look like it is
/// standing in front of the recess rather than inside it.
const double kAveluneShelfCartridgeLiftFraction = 0.09;

/// Front edge of the credenza's top surface, as a fraction of its canvas.
///
/// Together with [kAveluneCredenzaVisibleTopFraction] this bounds the tabletop
/// depth, which is where the console's contact shadow belongs.
const double kAveluneCredenzaTabletopFrontFraction = 262 / 700;

/// The open alcove, as fractions of the credenza canvas: the recess the shelf
/// cartridges stand in. Measured off `credenza_*.webp`, whose recess spans
/// x 171..589 and y 295..479 on a 768x700 canvas.
const Rect kAveluneCredenzaAlcove = Rect.fromLTRB(
  171 / 768,
  295 / 700,
  589 / 768,
  479 / 700,
);

/// Fraction of the credenza canvas at which its shelf board sits — the surface
/// the shelf cartridges stand on.
const double kAveluneCredenzaShelfBoardFraction = 0.68;

/// Fraction of the credenza canvas at which its art starts.
///
/// `room/furniture/credenza_*.webp` are 768x700 with the back edge of the top
/// surface as their first opaque row (y=199). The console is seated on that
/// edge, so the two fractions have to be read together.
const double kAveluneCredenzaVisibleTopFraction = 199 / 700;

@immutable
final class AveluneRoomSceneLayout {
  const AveluneRoomSceneLayout._({
    required this.furnitureRect,
    required this.furnitureSupportY,
    required this.furnitureShelfBaselineY,
  });

  /// The recess the shelf cartridges stand in, in screen coordinates.
  Rect get alcoveRect => Rect.fromLTRB(
        furnitureRect.left +
            (furnitureRect.width * kAveluneCredenzaAlcove.left),
        furnitureRect.top + (furnitureRect.height * kAveluneCredenzaAlcove.top),
        furnitureRect.left +
            (furnitureRect.width * kAveluneCredenzaAlcove.right),
        furnitureRect.top +
            (furnitureRect.height * kAveluneCredenzaAlcove.bottom),
      );

  /// How far the shelf cartridges stand above the board's front lip on screen.
  double get shelfCartridgeLift =>
      alcoveRect.height * kAveluneShelfCartridgeLiftFraction;

  /// Depth of the top surface on screen, from its back edge to its front lip.
  double get tabletopDepth =>
      furnitureRect.height *
      (kAveluneCredenzaTabletopFrontFraction -
          kAveluneCredenzaVisibleTopFraction);

  factory AveluneRoomSceneLayout.resolve(AveluneHomeGeometry geometry) =>
      AveluneRoomSceneLayout._(
        furnitureRect: geometry.credenzaRect,
        furnitureSupportY: geometry.consoleFootlineY,
        furnitureShelfBaselineY: geometry.anchors.shelfBaseline.dy,
      );

  final Rect furnitureRect;
  final double furnitureSupportY;
  final double furnitureShelfBaselineY;
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
    this.onAddGame,
    this.onHeroPressed,
    this.onHeroLongPress,
    this.heroAnchorKey,
    this.shelfCartridgeKeyFor,
    this.hiddenShelfGameIds = const <String>{},
    this.showHero = true,
    this.insertionOverlay,
    this.foregroundOverlay,
    this.heroSemanticsLabel,
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
  final VoidCallback? onAddGame;
  final VoidCallback? onHeroPressed;
  final VoidCallback? onHeroLongPress;
  final GlobalKey? heroAnchorKey;
  final GlobalKey Function(String gameId)? shelfCartridgeKeyFor;
  final Set<String> hiddenShelfGameIds;
  final bool showHero;

  /// Cartridge being inserted. Painted over the console and clipped at the slot
  /// mouth so it disappears into the cavity instead of behind the hardware.
  final Widget? insertionOverlay;
  final Widget? foregroundOverlay;
  final String? heroSemanticsLabel;

  /// Pinned clock for relative wording. Goldens and tests must supply it so
  /// the render does not drift with the calendar.
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
          Image(
            key: const ValueKey<String>('avelune-room-background-layer'),
            image: _backgroundFor(appearance, customBackground),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
          IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey<String>('avelune-room-light-layer'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const <double>[0, 0.38, 1],
                  colors: <Color>[
                    colors.warning.withValues(alpha: 0.12),
                    colors.room.withValues(alpha: 0.08),
                    colors.canvas.withValues(alpha: 0.56),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: roomLayout.furnitureRect,
            child: Image.asset(
              appearanceAssetPath(
                AveluneAppearanceCatalog.furnitureFinish(
                  appearance.furnitureId,
                ),
              )!,
              key: const ValueKey<String>('avelune-room-furniture-layer'),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
          Positioned(
            left: geometry.contentRect.left,
            right: geometry.viewportSize.width - geometry.contentRect.right,
            top: roomLayout.furnitureSupportY - 0.5,
            height: 1,
            child: const SizedBox(
              key: ValueKey<String>('avelune-furniture-support-anchor'),
            ),
          ),
          Positioned(
            left: geometry.contentRect.left,
            right: geometry.viewportSize.width - geometry.contentRect.right,
            top: roomLayout.furnitureShelfBaselineY - 0.5,
            height: 1,
            child: const SizedBox(
              key: ValueKey<String>('avelune-furniture-shelf-baseline'),
            ),
          ),
          Positioned.fromRect(
            rect: roomLayout.alcoveRect,
            child: const _AveluneAlcoveOcclusion(),
          ),
          Positioned.fromRect(
            // Confined to the recess. Spanning the content width instead put the
            // outer cartridges on the door faces, so nothing read as being in
            // the alcove. Only the sides are clamped: the shelf derives its own
            // bottom padding from `geometry.shelfRect`, so its vertical bounds
            // have to stay untouched or the cartridges leave the board.
            rect: Rect.fromLTRB(
              math.max(geometry.shelfRect.left, roomLayout.alcoveRect.left),
              geometry.shelfRect.top - roomLayout.shelfCartridgeLift,
              math.min(geometry.shelfRect.right, roomLayout.alcoveRect.right),
              geometry.shelfRect.bottom - roomLayout.shelfCartridgeLift,
            ),
            child: AveluneGameShelf(
              geometry: geometry,
              games: games,
              selectedGameId: selected?.id,
              onGameSelected: onGameSelected,
              onAddGame: onAddGame,
              cartridgeKeyFor: shelfCartridgeKeyFor,
              hiddenGameIds: hiddenShelfGameIds,
            ),
          ),
          Positioned.fromRect(
            rect: roomLayout.alcoveRect,
            child: const _AveluneAlcoveOverhang(),
          ),
          Positioned.fromRect(
            rect: Rect.fromCenter(
              center: Offset(
                geometry.consoleRect.center.dx,
                roomLayout.furnitureSupportY +
                    (roomLayout.tabletopDepth * 0.08),
              ),
              width: geometry.consoleRect.width * 1.08,
              height: roomLayout.tabletopDepth * 1.9,
            ),
            child: const _AveluneConsoleContactShadow(),
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
                geometry.heroCartridgeSize.width * 0.22,
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
                          colors.glow.withValues(alpha: 0.3),
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
                    artworkHeroTag: aveluneArtworkHeroTag(selected.id),
                    onPressed: onHeroPressed,
                    onLongPress: onHeroLongPress,
                    semanticsLabel: heroSemanticsLabel,
                  ),
                ),
              ),
            ),
          ],
          if (foregroundOverlay != null)
            Positioned.fill(child: foregroundOverlay!),
        ],
      ),
    );
  }
}

/// Ambient occlusion inside the credenza recess.
///
/// Without it the cartridges read as pasted onto a flat panel: the alcove is lit
/// evenly, so nothing says the shelf is set back into the furniture.
class _AveluneAlcoveOcclusion extends StatelessWidget {
  const _AveluneAlcoveOcclusion();

  @override
  Widget build(BuildContext context) {
    final shade = context.aveluneColors.canvas;
    return IgnorePointer(
      child: Stack(
        key: const ValueKey<String>('avelune-alcove-occlusion'),
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const <double>[0, 0.34, 1],
                colors: <Color>[
                  shade.withValues(alpha: 0.74),
                  shade.withValues(alpha: 0.26),
                  shade.withValues(alpha: 0.44),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                stops: const <double>[0, 0.18, 0.82, 1],
                colors: <Color>[
                  shade.withValues(alpha: 0.62),
                  shade.withValues(alpha: 0),
                  shade.withValues(alpha: 0),
                  shade.withValues(alpha: 0.54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The tabletop overhang falling across the tops of the cartridges. Painted over
/// them, so they sit under the lip rather than in front of it.
class _AveluneAlcoveOverhang extends StatelessWidget {
  const _AveluneAlcoveOverhang();

  @override
  Widget build(BuildContext context) {
    final shade = context.aveluneColors.canvas;
    return IgnorePointer(
      child: DecoratedBox(
        key: const ValueKey<String>('avelune-alcove-overhang'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const <double>[0, 0.3, 1],
            colors: <Color>[
              shade.withValues(alpha: 0.44),
              shade.withValues(alpha: 0.06),
              shade.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shadow the console drops onto the wood it stands on.
///
/// The console art carries its own contact band, but that band lives inside the
/// console's own box, which stops at its feet — so it fell on the wall behind
/// instead of on the surface, and the hardware read as floating in front of the
/// furniture rather than resting on it.
class _AveluneConsoleContactShadow extends StatelessWidget {
  const _AveluneConsoleContactShadow();

  @override
  Widget build(BuildContext context) {
    final shade = context.aveluneColors.canvas;
    return IgnorePointer(
      // Darkest right under the feet, fading forward across the wood, with
      // tapered ends from the stadium shape. A RadialGradient is wrong here:
      // Flutter scales its radius by the box's shortest side, so in a wide,
      // shallow band it collapses into a small blob in the middle.
      child: DecoratedBox(
        key: const ValueKey<String>('avelune-console-contact-shadow'),
        decoration: BoxDecoration(
          borderRadius: AveluneShapes.pill,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const <double>[0, 0.3, 1],
            colors: <Color>[
              shade.withValues(alpha: 0.55),
              shade.withValues(alpha: 0.3),
              shade.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cuts everything below the slot's near lip, so a descending cartridge is
/// swallowed by the opening rather than hidden by the console silhouette.
class _AveluneSlotMouthClipper extends CustomClipper<Rect> {
  const _AveluneSlotMouthClipper(this.mouthY);

  final double mouthY;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width, mouthY);

  @override
  bool shouldReclip(_AveluneSlotMouthClipper oldClipper) =>
      oldClipper.mouthY != mouthY;
}

/// Background the room paints, so surfaces around the scene can extend it
/// instead of falling back to flat black.
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
