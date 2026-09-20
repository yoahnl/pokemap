import 'cinematic_transport_listenable.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/cinematics/application/cinematic_preview_transport.dart';

class CinematicTimelineGrid extends CustomPainter {
  CinematicTimelineGrid({
    required this.layout,
    required this.scale,
    required this.rowHeight,
    required this.color,
    required this.text,
    required this.textStyle,
  });
  final CinematicTimelineTimeLayoutReadModel layout;
  final double scale, rowHeight;
  final Color color, text;
  final TextStyle textStyle;
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (final tick in layout.ticks) {
      final x = tick.timeMs * scale;
      canvas.drawLine(Offset(x, 24), Offset(x, size.height), line);
      final label = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: tick.label,
          style: textStyle.copyWith(color: text, fontSize: 10),
        ),
      )..layout();
      label.paint(canvas, Offset(x + 3, 5));
    }
    for (var row = 0; row <= layout.lanes.length; row++) {
      final y = 30 + row * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CinematicTimelineGrid oldDelegate) =>
      layout != oldDelegate.layout ||
      scale != oldDelegate.scale ||
      color != oldDelegate.color;
}

class CinematicPlayhead extends CustomPainter {
  CinematicPlayhead({
    required this.transport,
    required this.scale,
    required this.color,
  }) : super(repaint: CinematicTransportListenable(transport));
  final CinematicPreviewTransport transport;
  final double scale;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final x = transport.timeMs * scale;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x, 23), Offset(x, size.height), paint);
    canvas.drawPath(
      Path()
        ..moveTo(x - 6, 20)
        ..lineTo(x + 6, 20)
        ..lineTo(x, 28)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CinematicPlayhead oldDelegate) =>
      scale != oldDelegate.scale ||
      transport != oldDelegate.transport ||
      color != oldDelegate.color;
}
