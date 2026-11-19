part of 'resource_library_preview_art.dart';

void _paintTerrain(
  _LibraryDrawing art,
  LibraryDemoMotif motif,
  Color green,
  Color gold,
  Color blue,
  Color highlight,
) {
  final tile = <(double, double)>[(18, 45), (64, 18), (111, 45), (64, 72)];
  art.polygon([
    (18, 45),
    (64, 72),
    (111, 45),
    (111, 53),
    (64, 81),
    (18, 54),
  ], art.shade(green, .35));
  art.polygon(tile, art.shade(green, .67));
  if (motif == LibraryDemoMotif.path) {
    art.polygon([
      (22, 43),
      (39, 34),
      (78, 51),
      (94, 55),
      (81, 63),
      (63, 59),
    ], art.shade(gold, .79));
    for (final (x, y) in [
      (32.0, 42.0),
      (47.0, 45.0),
      (61.0, 51.0),
      (74.0, 56.0),
    ]) {
      art.oval(x, y, 4, 1.5, art.shade(gold, .50));
    }
  } else if (motif == LibraryDemoMotif.water) {
    art.polygon([
      (30, 45),
      (48, 32),
      (65, 28),
      (87, 35),
      (99, 45),
      (78, 57),
      (61, 62),
      (41, 56),
    ], art.shade(gold, .67));
    art.polygon([
      (36, 45),
      (52, 35),
      (65, 32),
      (84, 39),
      (92, 45),
      (74, 54),
      (61, 57),
      (44, 53),
    ], art.shade(blue, .84));
    for (final (x, y) in [(53.0, 44.0), (70.0, 40.0), (72.0, 49.0)]) {
      art.oval(x, y, 12, 1.6, highlight.withValues(alpha: .65));
    }
  } else {
    for (final (x, y) in [
      (35.0, 46.0),
      (49.0, 40.0),
      (69.0, 59.0),
      (63.0, 28.0),
      (79.0, 46.0),
      (55.0, 53.0),
      (90.0, 44.0),
    ]) {
      art.polygon([
        (x - 4, y),
        (x + 1, y - 3),
        (x + 6, y),
        (x + 1, y + 3),
      ], art.shade(green, .87));
    }
  }
}
