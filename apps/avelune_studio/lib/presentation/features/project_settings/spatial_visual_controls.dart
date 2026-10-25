import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../theme/studio_tokens.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_slider.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class SpatialVisualControls extends StatelessWidget {
  const SpatialVisualControls({
    super.key,
    required this.patch,
    required this.inherited,
    required this.onChanged,
    this.camera = true,
    this.clock = true,
    this.onEditStart, this.onEditEnd,
  });
  final SpatialVisualPatch patch, inherited;
  final ValueChanged<SpatialVisualPatch>? onChanged;
  final bool camera, clock;
  final VoidCallback? onEditStart, onEditEnd;
  SpatialVisualPatch get effective => inherited.overriddenBy(patch);
  double number(SpatialVisualParameter p) => effective.number(p) ?? p.minimum;
  bool flag(SpatialVisualParameter p) => effective.enabled(p) ?? false;
  void change(SpatialVisualParameter p, Object value) {
    var next = (p == SpatialVisualParameter.fogStart || p == SpatialVisualParameter.fogEnd)
        ? patch.set(SpatialVisualParameter.fogStart, null).set(SpatialVisualParameter.fogEnd, null).set(p, value)
        : patch.set(p, value);
    if (p == SpatialVisualParameter.fieldOfViewDegrees) {
      final before = number(p) * math.pi / 360;
      final after = (value as double) * math.pi / 360;
      next = next.set(
        SpatialVisualParameter.cameraDistance,
        (number(SpatialVisualParameter.cameraDistance) *
                math.tan(before) /
                math.tan(after))
            .clamp(.01, 10000),
      );
    }
    if (p == SpatialVisualParameter.fogStart &&
        (value as double) >= number(SpatialVisualParameter.fogEnd)) {
      next = next.set(SpatialVisualParameter.fogEnd, value + 1);
    }
    if (p == SpatialVisualParameter.fogEnd &&
        (value as double) <= number(SpatialVisualParameter.fogStart)) {
      next = next.set(SpatialVisualParameter.fogStart, math.max(0, value - 1));
    }
    if (p == SpatialVisualParameter.fogStart && next.value(SpatialVisualParameter.fogEnd) == null && patch.value(SpatialVisualParameter.fogEnd) != null) next = next.set(SpatialVisualParameter.fogEnd, patch.value(SpatialVisualParameter.fogEnd));
    if (p == SpatialVisualParameter.fogEnd && next.value(SpatialVisualParameter.fogStart) == null && patch.value(SpatialVisualParameter.fogStart) != null) next = next.set(SpatialVisualParameter.fogStart, patch.value(SpatialVisualParameter.fogStart));
    onChanged?.call(next);
  }

  Widget inherit(SpatialVisualParameter p) => StudioButton(
    key: ValueKey('inherit-${p.name}'),
    label: patch.value(p) == null ? 'Hérité' : 'Rétablir l’héritage',
    icon: Icons.link,
    variant: StudioButtonVariant.quiet,
    onPressed: onChanged == null || patch.value(p) == null
        ? null
        : () => onChanged!(patch.set(p, null)),
  );
  Widget slider(
    SpatialVisualParameter p,
    String label,
    double min,
    double max, {
    String Function(double)? format,
  }) {
    final value = number(p);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          StudioSlider(
            key: ValueKey('visual-${p.name}'),
            label: label,
            value: value,
            min: min,
            max: max,
            valueLabel: format?.call(value) ?? value.toStringAsFixed(1),
            onChangeStart: onEditStart == null ? null : (_) => onEditStart!(),
            onChangeEnd: onEditEnd == null ? null : (_) => onEditEnd!(),
            onChanged: onChanged == null ? null : (value) => change(p, value),
          ),
          Align(alignment: Alignment.centerRight, child: inherit(p)),
        ],
      ),
    );
  }

  Widget toggle(
    SpatialVisualParameter p,
    String label,
    IconData icon,
    StudioAccent accent,
  ) => Column(
    children: [
      StudioToggleRow(
        key: ValueKey('visual-${p.name}'),
        label: label,
        icon: icon,
        accent: accent,
        value: flag(p),
        onChanged: onChanged == null ? null : (value) => change(p, value),
      ),
      Align(alignment: Alignment.centerRight, child: inherit(p)),
    ],
  );
  Widget group(
    String title,
    IconData icon,
    StudioAccent accent,
    List<Widget> children,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: StudioPanel(
      title: title,
      icon: icon,
      accent: accent,
      children: children,
    ),
  );
  @override
  Widget build(BuildContext context) {
    const p = SpatialVisualParameter.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (camera)
          group('Caméra', Icons.photo_camera_outlined, StudioAccent.water, [
            slider(
              p[0],
              'Inclinaison',
              15,
              75,
              format: (v) => '${v.toStringAsFixed(1)}°',
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final angle in [30.0, 34.0, 38.0, 42.0, 48.7])
                  StudioButton(
                    label: '$angle°',
                    secondary: true,
                    onPressed: onChanged == null
                        ? null
                        : () => change(p[0], angle),
                  ),
              ],
            ),
            slider(
              p[1],
              'Orientation',
              -180,
              180,
              format: (v) => '${v.toStringAsFixed(0)}°',
            ),
            slider(
              p[2],
              'Champ de vision',
              8,
              60,
              format: (v) => '${v.toStringAsFixed(1)}°',
            ),
            slider(
              p[3],
              'Distance',
              3,
              150,
              format: (v) => '${v.toStringAsFixed(2)} cases',
            ),
            toggle(
              p[4],
              'Conserver le cadrage vertical sur mobile',
              Icons.stay_current_portrait,
              StudioAccent.water,
            ),
          ]),
        if (clock)
          group(
            'Jour et nuit',
            Icons.wb_twilight_outlined,
            StudioAccent.daylight,
            [
              toggle(
                p[5],
                'Animer le cycle',
                Icons.timelapse,
                StudioAccent.daylight,
              ),
              slider(
                p[6],
                'Durée d’une journée',
                60,
                7200,
                format: (v) => '${(v / 60).toStringAsFixed(1)} min',
              ),
              slider(
                p[7],
                'Heure de départ / heure fixe',
                0,
                1439,
                format: (v) =>
                    '${(v ~/ 60).toString().padLeft(2, '0')}:${(v.round() % 60).toString().padLeft(2, '0')}',
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (final hour in <int, String>{
                    360: 'Aube',
                    720: 'Midi',
                    1110: 'Soir',
                    1320: 'Nuit',
                  }.entries)
                    StudioButton(
                      label: hour.value,
                      secondary: true,
                      onPressed: onChanged == null
                          ? null
                          : () => change(p[7], hour.key.toDouble()),
                    ),
                ],
              ),
            ],
          ),
        group('Profondeur de champ', Icons.camera, StudioAccent.fog, [
          toggle(p[8], 'Activer le flou', Icons.camera, StudioAccent.fog),
          slider(
            p[9],
            'Intensité du flou',
            0,
            1,
            format: (v) => '${(v * 100).round()} %',
          ),
          slider(
            p[10],
            'Largeur de la zone nette',
            2,
            40,
            format: (v) => '${v.toStringAsFixed(1)} cases',
          ),
        ]),
        group('Halos lumineux', Icons.flare, StudioAccent.halo, [
          toggle(
            p[11],
            'Diffuser les lumières',
            Icons.flare,
            StudioAccent.halo,
          ),
          slider(p[12], 'Intensité', 0, 2),
          slider(p[13], 'Diffusion', .1, 3),
        ]),
        group('Brume en profondeur', Icons.cloud_outlined, StudioAccent.fog, [
          toggle(
            p[14],
            'Activer la brume',
            Icons.cloud_outlined,
            StudioAccent.fog,
          ),
          slider(
            p[15],
            'Opacité',
            0,
            .5,
            format: (v) => '${(v * 100).round()} %',
          ),
          slider(p[16], 'Début de la brume', 0, 150),
          slider(p[17], 'Fin de la brume', .1, 200),
        ]),
        group('Eau animée', Icons.water, StudioAccent.water, [
          toggle(
            p[18],
            'Animer les surfaces d’eau',
            Icons.water,
            StudioAccent.water,
          ),
          slider(p[19], 'Intensité', 0, 2),
          slider(p[20], 'Vitesse', 0, 3),
        ]),
        group('Fenêtres éclairées', Icons.window, StudioAccent.window, [
          toggle(
            p[21],
            'Éclairer les fenêtres le soir',
            Icons.window,
            StudioAccent.window,
          ),
          slider(p[22], 'Intensité', 0, 2),
        ]),
        group('Lucioles', Icons.auto_awesome, StudioAccent.firefly, [
          toggle(
            p[23],
            'Allumer les lucioles le soir',
            Icons.auto_awesome,
            StudioAccent.firefly,
          ),
          slider(p[24], 'Densité', 0, 2),
        ]),
        const Text(
          'L’eau, les fenêtres et les lucioles utilisent les sources placées sur chaque carte. Les ombres restent réglables sur les ressources et sur chaque élément 3D.',
        ),
      ],
    );
  }
}
