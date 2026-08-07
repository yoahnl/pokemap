import 'package:flutter/widgets.dart';

/// Where things are inside the credenza artwork.
///
/// Measured off `room/furniture/credenza_*.webp`, which all share one 768x700
/// silhouette. These live here rather than in the room scene because the home
/// geometry needs them too: the shelf board's position on screen is derived
/// from the furniture, not from a band fraction.
abstract final class AveluneCredenzaMetrics {
  /// Canvas aspect ratio.
  static const double aspectRatio = 768 / 700;

  /// First opaque row: the back edge of the top surface, which is the line the
  /// console's feet rest on.
  static const double visibleTop = 199 / 700;

  /// Front lip of the top surface. With [visibleTop] this bounds the tabletop
  /// depth, which is where the console's contact shadow belongs.
  static const double tabletopFront = 262 / 700;

  /// The shelf board the cartridges stand on.
  static const double shelfBoard = 0.68;

  /// The open recess, as fractions of the canvas: x 171..589, y 295..479.
  static const Rect alcove = Rect.fromLTRB(
    171 / 768,
    295 / 700,
    589 / 768,
    479 / 700,
  );

  /// How far the cartridges stand above the board's front lip, as a fraction of
  /// the alcove height. The board recedes in perspective, so a cartridge resting
  /// toward the back reads as sitting higher than the lip.
  static const double shelfCartridgeLift = 0.09;

  /// Height at which the credenza's base lands on [bottomY], given the console
  /// foot line it has to meet at its [visibleTop].
  static double heightToReach({
    required double bottomY,
    required double consoleFootlineY,
  }) =>
      (bottomY - consoleFootlineY) / (1 - visibleTop);

  /// Top of the credenza rect for a given height, so its [visibleTop] lands on
  /// the console's feet.
  static double topFor({
    required double height,
    required double consoleFootlineY,
  }) =>
      consoleFootlineY - (height * visibleTop);
}
