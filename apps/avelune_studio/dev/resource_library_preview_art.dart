import 'dart:math' as math;

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

part 'resource_library_preview_terrain.dart';

enum LibraryDemoMotif { mill, oak, grass, path, house, water, flowers, cliff }

class LibraryDemoArt extends StatelessWidget {
  const LibraryDemoArt(this.motif, {super.key});

  final LibraryDemoMotif motif;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _LibraryDemoPainter(motif, Theme.of(context).colorScheme, [
      StudioAccent.firefly.color(context),
      StudioAccent.water.color(context),
      StudioAccent.daylight.color(context),
      StudioAccent.window.color(context),
      StudioAccent.fog.color(context),
    ]),
    child: const SizedBox.expand(),
  );
}

class _LibraryDemoPainter extends CustomPainter {
  const _LibraryDemoPainter(this.motif, this.colors, this.accents);

  final LibraryDemoMotif motif;
  final ColorScheme colors;
  final List<Color> accents;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final art = _LibraryDrawing(canvas, colors.surfaceContainerLowest);
    final [green, blue, gold, peach, lilac] = accents;
    final tint = switch (motif) {
      LibraryDemoMotif.mill => blue,
      LibraryDemoMotif.oak ||
      LibraryDemoMotif.grass ||
      LibraryDemoMotif.flowers => green,
      LibraryDemoMotif.path => gold,
      LibraryDemoMotif.house => peach,
      LibraryDemoMotif.water => blue,
      LibraryDemoMotif.cliff => lilac,
    };
    final background = Offset.zero & size;
    canvas.drawRect(
      background,
      Paint()
        ..shader = RadialGradient(
          radius: .9,
          colors: [art.shade(tint, .23), art.shade(tint, .05)],
        ).createShader(background),
    );
    final grid = Paint()..color = colors.outline.withValues(alpha: .26);
    for (var x = size.width / 2 % 16; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = size.height / 2 % 16; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final scale = math.min(size.width / 132, size.height / 94);
    canvas.save();
    canvas.translate(
      (size.width - 128 * scale) / 2,
      (size.height - 90 * scale) / 2,
    );
    canvas.scale(scale);
    art.oval(
      64,
      76,
      90,
      12,
      colors.surfaceContainerLowest.withValues(alpha: .66),
    );
    switch (motif) {
      case LibraryDemoMotif.mill:
        art.polygon([
          (46, 73),
          (58, 34),
          (71, 35),
          (82, 73),
          (67, 79),
        ], art.shade(peach, .77));
        art.polygon([
          (64, 36),
          (71, 35),
          (82, 73),
          (67, 79),
        ], art.shade(peach, .50));
        art.polygon([
          (58, 69),
          (68, 68),
          (69, 77),
          (57, 75),
        ], art.shade(peach, .29));
        canvas.save();
        canvas.translate(64, 35);
        for (var blade = 0; blade < 3; blade++) {
          canvas.rotate(2 * math.pi / 3);
          art.polygon([
            (-2, -1),
            (-6, -30),
            (2, -34),
            (8, -23),
            (4, -3),
          ], colors.onSurface);
          art.polygon([
            (2, -34),
            (8, -23),
            (4, -3),
            (2, -3),
          ], art.shade(blue, .67));
        }
        art.oval(0, 0, 12, 12, art.shade(blue, .60));
        art.oval(0, 0, 5, 5, colors.onSurface);
        canvas.restore();
      case LibraryDemoMotif.oak:
        art.polygon([
          (56, 72),
          (59, 46),
          (72, 46),
          (75, 72),
          (64, 78),
        ], art.shade(peach, .66));
        art.polygon([
          (65, 52),
          (72, 46),
          (75, 72),
          (64, 78),
        ], art.shade(peach, .45));
        art.polygon([
          (18, 43),
          (24, 30),
          (39, 26),
          (44, 16),
          (64, 8),
          (82, 12),
          (94, 23),
          (105, 31),
          (111, 47),
          (97, 58),
          (78, 55),
          (62, 65),
          (42, 59),
          (29, 58),
        ], art.shade(green, .40));
        art.polygon([
          (27, 40),
          (48, 23),
          (58, 14),
          (76, 15),
          (90, 24),
          (99, 35),
          (94, 45),
          (76, 40),
          (63, 53),
          (50, 47),
          (32, 49),
        ], art.shade(green, .69));
        art.polygon([
          (48, 29),
          (58, 19),
          (75, 20),
          (82, 27),
          (72, 25),
          (63, 29),
          (54, 36),
        ], art.shade(green, .87));
      case LibraryDemoMotif.grass ||
          LibraryDemoMotif.path ||
          LibraryDemoMotif.water:
        _paintTerrain(art, motif, green, gold, blue, colors.onSurface);
      case LibraryDemoMotif.house:
        art.polygon([
          (34, 37),
          (73, 45),
          (73, 76),
          (34, 68),
        ], art.shade(peach, .81));
        art.polygon([
          (73, 45),
          (99, 34),
          (99, 65),
          (73, 76),
        ], art.shade(peach, .58));
        art.polygon([
          (26, 40),
          (54, 13),
          (80, 43),
          (74, 48),
        ], art.shade(blue, .62));
        art.polygon([
          (54, 13),
          (79, 5),
          (106, 32),
          (80, 43),
        ], art.shade(blue, .76));
        art.polygon([
          (47, 69),
          (47, 50),
          (59, 53),
          (59, 72),
        ], art.shade(peach, .41));
        art.polygon([(80, 49), (92, 44), (92, 56), (80, 61)], gold);
      case LibraryDemoMotif.flowers:
        art.oval(63, 74, 70, 9, art.shade(green, .48));
        for (final (x, y, color) in [
          (40.0, 43.0, peach),
          (66.0, 28.0, gold),
          (88.0, 47.0, lilac),
        ]) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x, 72),
            Paint()
              ..strokeWidth = 3.4
              ..color = art.shade(green, .76),
          );
          art.oval(x, y, 20, 19, color);
          art.oval(x, y, 6, 6, colors.onSurface);
          art.oval(x + 5, 62, 13, 5, art.shade(green, .67));
        }
      case LibraryDemoMotif.cliff:
        art.polygon([
          (23, 35),
          (47, 22),
          (80, 18),
          (102, 31),
          (74, 46),
        ], art.shade(lilac, .80));
        art.polygon([
          (23, 35),
          (74, 46),
          (74, 81),
          (30, 65),
        ], art.shade(lilac, .45));
        art.polygon([
          (74, 46),
          (102, 31),
          (97, 62),
          (74, 81),
        ], art.shade(lilac, .64));
        art.polygon([
          (41, 47),
          (48, 48),
          (52, 61),
          (49, 66),
          (48, 71),
          (43, 68),
          (45, 61),
        ], art.shade(lilac, .25));
        art.polygon([
          (69, 46),
          (79, 47),
          (80, 57),
          (73, 62),
          (69, 73),
          (66, 74),
          (69, 60),
          (75, 56),
        ], art.shade(lilac, .32));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LibraryDemoPainter old) =>
      old.motif != motif || old.colors != colors;
}

class _LibraryDrawing {
  const _LibraryDrawing(this.canvas, this.base);

  final Canvas canvas;
  final Color base;

  Color shade(Color color, double amount) => Color.lerp(base, color, amount)!;

  void polygon(List<(double, double)> points, Color color) {
    final (x, y) = points.first;
    final path = Path()..moveTo(x, y);
    for (final (x, y) in points.skip(1)) {
      path.lineTo(x, y);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  void oval(double x, double y, double width, double height, Color color) =>
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: width, height: height),
        Paint()..color = color,
      );
}
