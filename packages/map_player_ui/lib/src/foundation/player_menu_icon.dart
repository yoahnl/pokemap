import 'package:flutter/material.dart';

enum PlayerMenuGlyph {
  party,
  bag,
  dex,
  map,
  journal,
  phone,
  profile,
  options,
  play,
  save,
  back,
  exit,
  chevron,
  info,
}

class PlayerMenuIcon extends StatelessWidget {
  const PlayerMenuIcon(this.glyph, {super.key, this.size = 20, this.color});
  final PlayerMenuGlyph glyph;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MenuIconPainter(glyph, color ?? IconTheme.of(context).color!),
      ),
    ),
  );
}

class _MenuIconPainter extends CustomPainter {
  _MenuIconPainter(this.glyph, this.color);
  final PlayerMenuGlyph glyph;
  final Color color;
  static final _paths = <PlayerMenuGlyph, List<Path>>{
    PlayerMenuGlyph.party: [
      Path()..addOval(Rect.fromCircle(center: Offset(11, 4), radius: 2)),
      Path()..addOval(Rect.fromCircle(center: Offset(18, 8), radius: 2)),
      Path()..addOval(Rect.fromCircle(center: Offset(20, 16), radius: 2)),
      Path()
        ..moveTo(9, 10)
        ..arcToPoint(
          Offset(14, 15),
          radius: Radius.elliptical(5, 5),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(14, 18.5)
        ..arcToPoint(
          Offset(7.16, 19.545),
          radius: Radius.elliptical(3.5, 3.5),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..quadraticBezierTo(6.52, 17.48, 4.46, 16.84)
        ..arcToPoint(
          Offset(5.5, 10),
          radius: Radius.elliptical(3.5, 3.5),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..close(),
    ],
    PlayerMenuGlyph.bag: [
      Path()
        ..moveTo(4, 10)
        ..arcToPoint(
          Offset(8, 6),
          radius: Radius.elliptical(4, 4),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(16, 6)
        ..arcToPoint(
          Offset(20, 10),
          radius: Radius.elliptical(4, 4),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(20, 20)
        ..arcToPoint(
          Offset(18, 22),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(6, 22)
        ..arcToPoint(
          Offset(4, 20),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..close(),
      Path()
        ..moveTo(8, 10)
        ..lineTo(16, 10),
      Path()
        ..moveTo(8, 18)
        ..lineTo(16, 18),
      Path()
        ..moveTo(8, 22)
        ..lineTo(8, 16)
        ..arcToPoint(
          Offset(10, 14),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(14, 14)
        ..arcToPoint(
          Offset(16, 16),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(16, 22),
      Path()
        ..moveTo(9, 6)
        ..lineTo(9, 4)
        ..arcToPoint(
          Offset(11, 2),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(13, 2)
        ..arcToPoint(
          Offset(15, 4),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(15, 6),
    ],
    PlayerMenuGlyph.dex: [
      Path()
        ..moveTo(3, 7)
        ..lineTo(3, 5)
        ..arcToPoint(
          Offset(5, 3),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(7, 3),
      Path()
        ..moveTo(17, 3)
        ..lineTo(19, 3)
        ..arcToPoint(
          Offset(21, 5),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(21, 7),
      Path()
        ..moveTo(21, 17)
        ..lineTo(21, 19)
        ..arcToPoint(
          Offset(19, 21),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(17, 21),
      Path()
        ..moveTo(7, 21)
        ..lineTo(5, 21)
        ..arcToPoint(
          Offset(3, 19),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(3, 17),
      Path()..addOval(Rect.fromCircle(center: Offset(12, 12), radius: 3)),
      Path()
        ..moveTo(16, 16)
        ..lineTo(14.1, 14.1),
    ],
    PlayerMenuGlyph.map: [
      Path()
        ..moveTo(14.106, 5.553)
        ..arcToPoint(
          Offset(15.894, 5.553),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: false,
        )
        ..lineTo(19.553, 3.723)
        ..arcToPoint(
          Offset(21, 4.619),
          radius: Radius.elliptical(1, 1),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(21, 17.383)
        ..arcToPoint(
          Offset(20.447, 18.276999999999997),
          radius: Radius.elliptical(1, 1),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(15.893999999999998, 20.554)
        ..arcToPoint(
          Offset(14.105999999999998, 20.554),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(9.893999999999998, 18.448)
        ..arcToPoint(
          Offset(8.105999999999998, 18.448),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: false,
        )
        ..lineTo(4.446999999999998, 20.278)
        ..arcToPoint(
          Offset(3, 19.381),
          radius: Radius.elliptical(1, 1),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(3, 6.618)
        ..arcToPoint(
          Offset(3.553, 5.724),
          radius: Radius.elliptical(1, 1),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(8.106, 3.447)
        ..arcToPoint(
          Offset(9.894, 3.447),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..close(),
      Path()
        ..moveTo(15, 5.764)
        ..lineTo(15, 20.764),
      Path()
        ..moveTo(9, 3.236)
        ..lineTo(9, 18.236),
    ],
    PlayerMenuGlyph.journal: [
      Path()
        ..moveTo(12, 7)
        ..lineTo(12, 21),
      Path()
        ..moveTo(3, 18)
        ..arcToPoint(
          Offset(2, 17),
          radius: Radius.elliptical(1, 1),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(2, 4)
        ..arcToPoint(
          Offset(3, 3),
          radius: Radius.elliptical(1, 1),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(8, 3)
        ..arcToPoint(
          Offset(12, 7),
          radius: Radius.elliptical(4, 4),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..arcToPoint(
          Offset(16, 3),
          radius: Radius.elliptical(4, 4),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(21, 3)
        ..arcToPoint(
          Offset(22, 4),
          radius: Radius.elliptical(1, 1),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(22, 17)
        ..arcToPoint(
          Offset(21, 18),
          radius: Radius.elliptical(1, 1),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(15, 18)
        ..arcToPoint(
          Offset(12, 21),
          radius: Radius.elliptical(3, 3),
          rotation: 0,
          largeArc: false,
          clockwise: false,
        )
        ..arcToPoint(
          Offset(9, 18),
          radius: Radius.elliptical(3, 3),
          rotation: 0,
          largeArc: false,
          clockwise: false,
        )
        ..close(),
    ],
    PlayerMenuGlyph.phone: [
      Path()
        ..moveTo(13.832, 16.568)
        ..arcToPoint(
          Offset(15.045000000000002, 16.265),
          radius: Radius.elliptical(1, 1),
          rotation: 0,
          largeArc: false,
          clockwise: false,
        )
        ..lineTo(15.400000000000002, 15.8)
        ..arcToPoint(
          Offset(17, 15),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(20, 15)
        ..arcToPoint(
          Offset(22, 17),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(22, 20)
        ..arcToPoint(
          Offset(20, 22),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..arcToPoint(
          Offset(2, 4),
          radius: Radius.elliptical(18, 18),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..arcToPoint(
          Offset(4, 2),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(7, 2)
        ..arcToPoint(
          Offset(9, 4),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(9, 7)
        ..arcToPoint(
          Offset(8.2, 8.6),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(7.731999999999999, 8.951)
        ..arcToPoint(
          Offset(7.4399999999999995, 10.184000000000001),
          radius: Radius.elliptical(1, 1),
          rotation: 0,
          largeArc: false,
          clockwise: false,
        )
        ..arcToPoint(
          Offset(13.832, 16.568),
          radius: Radius.elliptical(14, 14),
          rotation: 0,
          largeArc: false,
          clockwise: false,
        ),
    ],
    PlayerMenuGlyph.profile: [
      Path()
        ..moveTo(16, 2)
        ..lineTo(16, 4),
      Path()
        ..moveTo(17.915, 22)
        ..arcToPoint(
          Offset(5.914999999999999, 22),
          radius: Radius.elliptical(6, 6),
          rotation: 0,
          largeArc: false,
          clockwise: false,
        ),
      Path()
        ..moveTo(8, 2)
        ..lineTo(8, 4),
      Path()..addOval(Rect.fromCircle(center: Offset(12, 12), radius: 4)),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(3, 4, 18, 18),
          Radius.circular(2),
        ),
      ),
    ],
    PlayerMenuGlyph.options: [
      Path()
        ..moveTo(14, 17)
        ..lineTo(5, 17),
      Path()
        ..moveTo(19, 7)
        ..lineTo(10, 7),
      Path()..addOval(Rect.fromCircle(center: Offset(17, 17), radius: 3)),
      Path()..addOval(Rect.fromCircle(center: Offset(7, 7), radius: 3)),
    ],
    PlayerMenuGlyph.play: [
      Path()
        ..moveTo(5, 5)
        ..arcToPoint(
          Offset(8.008, 3.2720000000000002),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(20.005, 10.27)
        ..arcToPoint(
          Offset(20.008, 13.728),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(8.008, 20.728)
        ..arcToPoint(
          Offset(5, 19),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..close(),
    ],
    PlayerMenuGlyph.save: [
      Path()
        ..moveTo(15.2, 3)
        ..arcToPoint(
          Offset(16.599999999999998, 3.6),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(20.4, 7.4)
        ..arcToPoint(
          Offset(21, 8.8),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(21, 19)
        ..arcToPoint(
          Offset(19, 21),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(5, 21)
        ..arcToPoint(
          Offset(3, 19),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(3, 5)
        ..arcToPoint(
          Offset(5, 3),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..close(),
      Path()
        ..moveTo(17, 21)
        ..lineTo(17, 14)
        ..arcToPoint(
          Offset(16, 13),
          radius: Radius.elliptical(1, 1),
          rotation: 0,
          largeArc: false,
          clockwise: false,
        )
        ..lineTo(8, 13)
        ..arcToPoint(
          Offset(7, 14),
          radius: Radius.elliptical(1, 1),
          rotation: 0,
          largeArc: false,
          clockwise: false,
        )
        ..lineTo(7, 21),
      Path()
        ..moveTo(7, 3)
        ..lineTo(7, 7)
        ..arcToPoint(
          Offset(8, 8),
          radius: Radius.elliptical(1, 1),
          rotation: 0,
          largeArc: false,
          clockwise: false,
        )
        ..lineTo(15, 8),
    ],
    PlayerMenuGlyph.back: [
      Path()
        ..moveTo(12, 19)
        ..lineTo(5, 12)
        ..lineTo(12, 5),
      Path()
        ..moveTo(19, 12)
        ..lineTo(5, 12),
    ],
    PlayerMenuGlyph.exit: [
      Path()
        ..moveTo(16, 17)
        ..lineTo(21, 12)
        ..lineTo(16, 7),
      Path()
        ..moveTo(21, 12)
        ..lineTo(9, 12),
      Path()
        ..moveTo(9, 21)
        ..lineTo(5, 21)
        ..arcToPoint(
          Offset(3, 19),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(3, 5)
        ..arcToPoint(
          Offset(5, 3),
          radius: Radius.elliptical(2, 2),
          rotation: 0,
          largeArc: false,
          clockwise: true,
        )
        ..lineTo(9, 3),
    ],
    PlayerMenuGlyph.chevron: [
      Path()
        ..moveTo(9, 18)
        ..lineTo(15, 12)
        ..lineTo(9, 6),
    ],
    PlayerMenuGlyph.info: [
      Path()..addOval(Rect.fromCircle(center: Offset(12, 12), radius: 10)),
      Path()
        ..moveTo(12, 16)
        ..lineTo(12, 12),
      Path()
        ..moveTo(12, 8)
        ..lineTo(12.01, 8),
    ],
  };
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final path in _paths[glyph]!) {
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MenuIconPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}
