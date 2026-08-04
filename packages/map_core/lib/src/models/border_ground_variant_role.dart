/// Canonical visual role of a cell in a published Border ground snapshot.
///
/// The role describes topology only. It does not identify a Smart Tile,
/// animation, atlas entry, or gameplay material.
enum BorderGroundVariantRole {
  isolated,
  endNorth,
  endEast,
  endSouth,
  endWest,
  horizontal,
  vertical,
  cornerNE,
  cornerSE,
  cornerSW,
  cornerNW,
  innerCornerNE,
  innerCornerSE,
  innerCornerSW,
  innerCornerNW,
  teeNorth,
  teeEast,
  teeSouth,
  teeWest,
  cross,
}

/// Stable wire and publication order for Border ground snapshots.
///
/// Keep this explicit instead of relying on [BorderGroundVariantRole.values]
/// so reordering the enum cannot silently change persisted Border data.
const List<BorderGroundVariantRole> standardBorderGroundVariantRoleOrder = [
  BorderGroundVariantRole.isolated,
  BorderGroundVariantRole.endNorth,
  BorderGroundVariantRole.endEast,
  BorderGroundVariantRole.endSouth,
  BorderGroundVariantRole.endWest,
  BorderGroundVariantRole.horizontal,
  BorderGroundVariantRole.vertical,
  BorderGroundVariantRole.cornerNE,
  BorderGroundVariantRole.cornerSE,
  BorderGroundVariantRole.cornerSW,
  BorderGroundVariantRole.cornerNW,
  BorderGroundVariantRole.innerCornerNE,
  BorderGroundVariantRole.innerCornerSE,
  BorderGroundVariantRole.innerCornerSW,
  BorderGroundVariantRole.innerCornerNW,
  BorderGroundVariantRole.teeNorth,
  BorderGroundVariantRole.teeEast,
  BorderGroundVariantRole.teeSouth,
  BorderGroundVariantRole.teeWest,
  BorderGroundVariantRole.cross,
];
