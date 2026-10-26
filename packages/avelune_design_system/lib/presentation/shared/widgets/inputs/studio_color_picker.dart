import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../buttons/studio_button.dart';
import 'studio_slider.dart';
import 'studio_draft_field.dart';

class StudioColorPicker extends StatefulWidget {
  const StudioColorPicker({
    super.key,
    required this.label,
    required this.colorRgb,
    required this.onChanged,
    this.presets = const [],
    this.onChangeStart,
    this.onChangeEnd,
  });
  final String label;
  final int colorRgb;
  final ValueChanged<int>? onChanged;
  final List<int> presets;
  final VoidCallback? onChangeStart, onChangeEnd;
  @override
  State<StudioColorPicker> createState() => _StudioColorPickerState();
}

class _StudioColorPickerState extends State<StudioColorPicker> {
  late HSVColor hsv;
  bool open = false;
  final recent = <int>[];
  @override
  void initState() {
    super.initState();
    hsv = HSVColor.fromColor(Color(0xff000000 | widget.colorRgb));
  }

  @override
  void didUpdateWidget(StudioColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.colorRgb != widget.colorRgb &&
        (hsv.toColor().toARGB32() & 0xffffff) != widget.colorRgb) {
      hsv = HSVColor.fromColor(Color(0xff000000 | widget.colorRgb));
    }
  }

  void choose(HSVColor value) {
    setState(() => hsv = value);
    widget.onChanged?.call(value.toColor().toARGB32() & 0xffffff);
  }

  void remember() {
    final color = hsv.toColor().toARGB32() & 0xffffff;
    setState(() {
      recent.remove(color);
      recent.insert(0, color);
      if (recent.length > 6) recent.removeLast();
    });
    widget.onChangeEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hex = widget.colorRgb.toRadixString(16).padLeft(6, '0').toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CustomPaint(
              size: const Size(28, 28),
              painter: _Swatch(
                Color(0xff000000 | widget.colorRgb),
                scheme.outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StudioButton(
                label: '${widget.label} · #$hex',
                secondary: true,
                icon: Icons.palette_outlined,
                onPressed: widget.onChanged == null
                    ? null
                    : () => setState(() => open = !open),
              ),
            ),
          ],
        ),
        if (open) ...[
          const SizedBox(height: 12),
          Center(
            child: SizedBox.square(
              dimension: 220,
              child: GestureDetector(
                key: const ValueKey('studio-color-wheel'),
                onPanStart: widget.onChanged == null
                    ? null
                    : (event) {
                        widget.onChangeStart?.call();
                        pick(event.localPosition);
                      },
                onPanUpdate: widget.onChanged == null
                    ? null
                    : (event) => pick(event.localPosition),
                onPanEnd: widget.onChanged == null ? null : (_) => remember(),
                onTapUp: widget.onChanged == null
                    ? null
                    : (event) {
                        widget.onChangeStart?.call();
                        pick(event.localPosition);
                        remember();
                      },
                child: CustomPaint(
                  painter: _ColorWheel(hsv, scheme.onSurface, scheme.surface),
                ),
              ),
            ),
          ),
          StudioSlider(
            label: 'Luminosité',
            value: hsv.value,
            min: 0,
            max: 1,
            valueLabel: '${(hsv.value * 100).round()} %',
            onChangeStart: (_) => widget.onChangeStart?.call(),
            onChangeEnd: (_) => remember(),
            onChanged: widget.onChanged == null
                ? null
                : (v) => choose(hsv.withValue(v)),
          ),
          StudioDraftField(
            key: ValueKey('studio-color-hex-${widget.label}'),
            label: 'Code couleur',
            value: hex,
            enabled: widget.onChanged != null,
            onChanged: (raw) {
              final value = int.tryParse(raw.replaceAll('#', ''), radix: 16);
              if (value == null ||
                  value < 0 ||
                  value > 0xffffff ||
                  raw.replaceAll('#', '').length != 6) {
                return;
              }
              widget.onChangeStart?.call();
              choose(HSVColor.fromColor(Color(0xff000000 | value)));
              remember();
            },
          ),
          if (widget.presets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Couleurs douces',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            palette(widget.presets),
          ],
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Couleurs récentes',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            palette(recent),
          ],
        ],
      ],
    );
  }

  void pick(Offset p) {
    final d = p - const Offset(110, 110);
    choose(
      HSVColor.fromAHSV(
        1,
        (math.atan2(d.dy, d.dx) * 180 / math.pi + 360) % 360,
        (d.distance / 104).clamp(0, 1),
        hsv.value,
      ),
    );
  }

  Widget palette(List<int> colors) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final color in colors)
        Semantics(
          label: 'Couleur #${color.toRadixString(16).padLeft(6, '0')}',
          button: true,
          child: InkWell(
            onTap: widget.onChanged == null
                ? null
                : () {
                    widget.onChangeStart?.call();
                    choose(HSVColor.fromColor(Color(0xff000000 | color)));
                    remember();
                  },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: CustomPaint(
                size: const Size(28, 28),
                painter: _Swatch(
                  Color(0xff000000 | color),
                  Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _Swatch extends CustomPainter {
  _Swatch(this.color, this.outline);
  final Color color, outline;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = color);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_Swatch old) =>
      old.color != color || old.outline != outline;
}

class _ColorWheel extends CustomPainter {
  _ColorWheel(this.hsv, this.foreground, this.background);
  final HSVColor hsv;
  final Color foreground, background;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero),
        rect = Rect.fromCircle(center: center, radius: 104);
    canvas.drawCircle(
      center,
      104,
      Paint()
        ..shader = SweepGradient(
          colors: [
            for (var i = 0; i <= 6; i++)
              HSVColor.fromAHSV(1, i * 60, 1, hsv.value).toColor(),
          ],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      104,
      Paint()
        ..shader = RadialGradient(
          colors: [
            HSVColor.fromAHSV(1, 0, 0, hsv.value).toColor(),
            HSVColor.fromAHSV(0, 0, 0, hsv.value).toColor(),
          ],
        ).createShader(rect),
    );
    final angle = hsv.hue * math.pi / 180,
        point =
            center +
            Offset(math.cos(angle), math.sin(angle)) * hsv.saturation * 104;
    canvas.drawCircle(point, 7, Paint()..color = background);
    canvas.drawCircle(
      point,
      7,
      Paint()
        ..color = foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ColorWheel old) =>
      hsv != old.hsv ||
      foreground != old.foreground ||
      background != old.background;
}

class StudioColorSwatch extends StatelessWidget {
  const StudioColorSwatch({super.key, required this.colorRgb, this.size = 24});
  final int colorRgb;
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _Swatch(
      Color(0xff000000 | colorRgb),
      Theme.of(context).colorScheme.outline,
    ),
  );
}
