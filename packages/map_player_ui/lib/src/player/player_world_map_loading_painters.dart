part of 'player_world_map_loading_scene.dart';

const _chartWidth = 360.0;
const _chartHeight = 244.0;
const _routeLight = Color(0xffa0efdb);
const _beaconLight = Color(0xffffd6a1);
const _waypoints = <double>[0, .24, .49, .76, 1];

final _route =
    (Path()
          ..moveTo(47, 183)
          ..cubicTo(67, 181, 89, 160, 105, 141)
          ..cubicTo(125, 111, 144, 154, 174, 146)
          ..cubicTo(204, 144, 198, 98, 226, 94)
          ..cubicTo(253, 88, 255, 122, 279, 110)
          ..cubicTo(302, 97, 295, 69, 318, 61))
        .computeMetrics()
        .single;

Offset _pointOnRoute(double fraction) =>
    _route.getTangentForOffset(_route.length * fraction)!.position;

class _ChartPainter extends CustomPainter {
  const _ChartPainter();

  static final _islands = [
    (
      const Offset(83, 154),
      Path()
        ..moveTo(19, 176)
        ..cubicTo(32, 143, 40, 129, 64, 124)
        ..cubicTo(83, 118, 68, 103, 100, 102)
        ..cubicTo(133, 102, 143, 123, 124, 143)
        ..cubicTo(114, 157, 87, 151, 81, 171)
        ..cubicTo(69, 205, 32, 210, 19, 192)
        ..close(),
    ),
    (
      const Offset(194, 128),
      Path()
        ..moveTo(144, 140)
        ..cubicTo(153, 123, 172, 128, 177, 110)
        ..cubicTo(181, 89, 196, 86, 220, 83)
        ..cubicTo(246, 80, 249, 106, 230, 120)
        ..cubicTo(209, 132, 224, 159, 196, 170)
        ..cubicTo(170, 180, 132, 162, 144, 140)
        ..close(),
    ),
    (
      const Offset(295, 78),
      Path()
        ..moveTo(255, 67)
        ..cubicTo(249, 41, 277, 39, 291, 46)
        ..cubicTo(316, 50, 328, 34, 337, 51)
        ..cubicTo(345, 70, 326, 84, 316, 91)
        ..cubicTo(306, 101, 306, 122, 283, 127)
        ..cubicTo(264, 130, 250, 110, 265, 96)
        ..cubicTo(274, 86, 259, 83, 255, 67)
        ..close(),
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _chartWidth, size.height / _chartHeight);
    const bounds = Rect.fromLTWH(0, 0, _chartWidth, _chartHeight);
    canvas.drawRect(bounds, Paint()..color = const Color(0xff112730));
    final grid = Paint()..color = const Color(0xff2b4750);
    for (var x = 12.0; x < _chartWidth; x += 12) {
      for (var y = 12.0; y < _chartHeight; y += 12) {
        canvas.drawCircle(Offset(x, y), .58, grid);
      }
    }
    final land = Paint()..color = const Color(0xff1d3940);
    final coast = Paint()
      ..color = const Color(0xff638781)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final contour = Paint()
      ..color = const Color(0xff3b5e61)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    for (final (center, island) in _islands) {
      canvas.drawPath(island, land);
      canvas.drawPath(island, coast);
      for (final scale in [.84, .66, .48]) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(scale);
        canvas.translate(-center.dx, -center.dy);
        canvas.drawPath(island, contour);
        canvas.restore();
      }
    }
    final dotted = Paint()
      ..color = const Color(0xff719398)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0.0; i < _route.length; i += 7) {
      canvas.drawPath(_route.extractPath(i, i + 2), dotted);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds.deflate(1), const Radius.circular(16)),
      coast..color = const Color(0xff3b5b62),
    );
    final compass = Path()
      ..moveTo(324, 194)
      ..lineTo(328, 204)
      ..lineTo(338, 208)
      ..lineTo(328, 212)
      ..lineTo(324, 222)
      ..lineTo(320, 212)
      ..lineTo(310, 208)
      ..lineTo(320, 204)
      ..close();
    canvas.drawPath(compass, contour);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.ambient, this.fraction) : super(repaint: ambient);

  final Animation<double> ambient;
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _chartWidth, size.height / _chartHeight);
    final time = ambient.value * 2 * math.pi;
    final light = Paint();
    for (final (index, point) in const [
      Offset(44, 54),
      Offset(112, 48),
      Offset(200, 50),
      Offset(248, 157),
      Offset(95, 205),
      Offset(176, 203),
      Offset(273, 179),
    ].indexed) {
      final twinkle = .5 + .5 * math.sin(time + index * 1.9);
      canvas.drawCircle(
        point,
        .8 + twinkle,
        light..color = _routeLight.withValues(alpha: .15 + twinkle * .6),
      );
    }
    final line = _route.extractPath(0, _route.length * fraction);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..color = _routeLight.withValues(alpha: .18);
    canvas.drawPath(line, stroke);
    canvas.drawPath(
      line,
      stroke
        ..strokeWidth = 2.1
        ..color = _routeLight,
    );
    for (final waypoint in _waypoints) {
      final passed = waypoint <= fraction;
      final point = _pointOnRoute(waypoint);
      canvas.drawCircle(point, 5, light..color = const Color(0xff163039));
      canvas.drawCircle(
        point,
        4.4,
        stroke
          ..strokeWidth = 1.2
          ..color = passed ? _beaconLight : const Color(0xff719398),
      );
      if (passed) canvas.drawCircle(point, 1.8, light..color = _beaconLight);
    }
    final head = _pointOnRoute(fraction);
    final pulse = .5 + .5 * math.sin(time * 3);
    canvas.drawCircle(
      head,
      7 + pulse * 3,
      light..color = _beaconLight.withValues(alpha: .13),
    );
    canvas.drawCircle(head, 3.1, light..color = _beaconLight);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) =>
      fraction != oldDelegate.fraction;
}
