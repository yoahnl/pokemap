import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../theme/studio_tokens.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_slider.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_color_picker.dart';
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
    this.onEditStart,
    this.onEditEnd,
  });
  final SpatialVisualPatch patch, inherited;
  final ValueChanged<SpatialVisualPatch>? onChanged;
  final bool camera, clock;
  final VoidCallback? onEditStart, onEditEnd;
  SpatialVisualPatch get effective => inherited.overriddenBy(patch);
  double number(SpatialVisualParameter p) => effective.number(p) ?? (p == SpatialVisualParameter.weatherIntervalSeconds ? 600 : p.minimum);
  String get timeMode => effective.choice(SpatialVisualParameter.timeMode) ?? (flag(SpatialVisualParameter.dayNightEnabled) ? 'cycle' : 'fixed');
  bool get automaticWeather => const ['automatic', 'real'].contains(effective.choice(SpatialVisualParameter.weatherMode));
  List<String> get weatherSequence => effective.value(SpatialVisualParameter.weatherSequence) as List<String>? ?? const ['clear', 'cloudy', 'rain'];
  void selectWeather(SpatialWeatherKind kind) {
    if (onChanged == null) return;
    if (automaticWeather) {
      final sequence = [...weatherSequence];
      if (sequence.contains(kind.name)) {
        if (sequence.length == 1) return;
        sequence.remove(kind.name);
      } else {
        sequence.add(kind.name);
      }
      onChanged!(patch.set(SpatialVisualParameter.weatherSequence, sequence));
    } else {
      onChanged!(patch.set(SpatialVisualParameter.weatherKind, kind.name).set(SpatialVisualParameter.weatherEnabled, kind != SpatialWeatherKind.clear));
    }
  }
  bool flag(SpatialVisualParameter p) => effective.enabled(p) ?? false;
  void change(SpatialVisualParameter p, Object value) {
    var next =
        (p == SpatialVisualParameter.fogStart ||
            p == SpatialVisualParameter.fogEnd)
        ? patch
              .set(SpatialVisualParameter.fogStart, null)
              .set(SpatialVisualParameter.fogEnd, null)
              .set(p, value)
        : patch.set(p, value);
    if (p.isClock && p != SpatialVisualParameter.timeMode && next.choice(SpatialVisualParameter.timeMode) == null) {
      next = next.set(SpatialVisualParameter.timeMode, timeMode);
    }
    if (p == SpatialVisualParameter.weatherMode && (value == 'automatic' || value == 'real')) {
      next = next.set(SpatialVisualParameter.weatherEnabled, true);
    }
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
    if (p == SpatialVisualParameter.fogStart &&
        next.value(SpatialVisualParameter.fogEnd) == null &&
        patch.value(SpatialVisualParameter.fogEnd) != null) {
      next = next.set(
        SpatialVisualParameter.fogEnd,
        patch.value(SpatialVisualParameter.fogEnd),
      );
    }
    if (p == SpatialVisualParameter.fogEnd &&
        next.value(SpatialVisualParameter.fogStart) == null &&
        patch.value(SpatialVisualParameter.fogStart) != null) {
      next = next.set(
        SpatialVisualParameter.fogStart,
        patch.value(SpatialVisualParameter.fogStart),
      );
    }
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
  static const weatherPresets = [
    (SpatialWeatherKind.clear, 'Ciel dégagé', Icons.wb_sunny_outlined),
    (SpatialWeatherKind.partlyCloudy, 'Éclaircies', Icons.wb_cloudy_outlined),
    (SpatialWeatherKind.windy, 'Vent soutenu', Icons.air),
    (SpatialWeatherKind.heavySnow, 'Forte neige', Icons.ac_unit),
    (SpatialWeatherKind.sleet, 'Pluie et neige', Icons.cloudy_snowing),
    (SpatialWeatherKind.tempest, 'Tempête violente', Icons.thunderstorm),
    (SpatialWeatherKind.cloudy, 'Couvert', Icons.cloud_outlined),
    (SpatialWeatherKind.drizzle, 'Bruine', Icons.grain),
    (SpatialWeatherKind.rain, 'Pluie', Icons.water_drop_outlined),
    (SpatialWeatherKind.downpour, 'Averse', Icons.water_drop),
    (SpatialWeatherKind.storm, 'Orage', Icons.thunderstorm_outlined),
    (SpatialWeatherKind.snow, 'Neige', Icons.ac_unit),
    (SpatialWeatherKind.blizzard, 'Blizzard', Icons.severe_cold_outlined),
    (SpatialWeatherKind.hail, 'Grêle', Icons.blur_on),
    (SpatialWeatherKind.mist, 'Brume légère', Icons.cloud_queue),
    (SpatialWeatherKind.fog, 'Brouillard', Icons.foggy),
    (SpatialWeatherKind.dust, 'Poussières', Icons.air),
    (SpatialWeatherKind.sandstorm, 'Tempête de sable', Icons.tornado),
    (SpatialWeatherKind.petals, 'Pétales', Icons.local_florist_outlined),
    (SpatialWeatherKind.leaves, 'Feuilles d’automne', Icons.eco_outlined),
  ];

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
              StudioSelect(
                key: const ValueKey('visual-timeMode'),
                label: 'Source de l’heure',
                value: timeMode,
                options: const {'cycle': 'Cycle du jeu', 'real': 'Heure réelle de l’appareil', 'fixed': 'Heure fixe'},
                onChanged: onChanged == null ? null : (value) => change(SpatialVisualParameter.timeMode, value),
              ),
              inherit(SpatialVisualParameter.timeMode),
              if (timeMode == 'real') const Text('Suit l’heure de l’appareil, ou celle de la ville météo lorsque la météo réelle est active. Les scènes et les faits du monde peuvent imposer temporairement une autre heure.'),
              if (timeMode == 'cycle')
              slider(
                p[6],
                'Durée d’une journée',
                60,
                math.max(7200, number(p[6])),
                format: (v) => '${(v / 60).toStringAsFixed(1)} min',
              ),
              if (timeMode != 'real') slider(
                p[7],
                timeMode == 'cycle' ? 'Heure de départ du cycle' : 'Heure imposée',
                0,
                1439,
                format: (v) =>
                    '${(v ~/ 60).toString().padLeft(2, '0')}:${(v.round() % 60).toString().padLeft(2, '0')}',
              ),
              if (timeMode != 'real') Wrap(
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
        group('Météo et saisons', Icons.cloud_outlined, StudioAccent.water, [
          StudioSelect(
            key: const ValueKey('visual-weatherMode'),
            label: 'Fonctionnement de la météo',
            value: effective.choice(SpatialVisualParameter.weatherMode) ?? 'fixed',
            options: const {'fixed': 'Météo fixe', 'automatic': 'Météo automatique', 'real': 'Météo réelle du joueur'},
            onChanged: onChanged == null ? null : (value) => change(SpatialVisualParameter.weatherMode, value),
          ),
          inherit(SpatialVisualParameter.weatherMode),
          if (effective.requiresRealWeather) const Text('Le joueur peut activer la localisation approximative par IP ou choisir une ville dans les options du Player. Sans réseau ou sans activation, le jeu utilise la météo de repli. Sources : Open-Meteo et GeoJS.'),
          if (automaticWeather) ...[
            slider(SpatialVisualParameter.weatherIntervalSeconds, 'Durée de chaque météo', 10, math.max(7200, number(SpatialVisualParameter.weatherIntervalSeconds)), format: (value) => '${(value / 60).toStringAsFixed(1)} min'),
            Text(effective.requiresRealWeather ? 'Choisissez les météos de repli utilisées si le joueur désactive le service ou si les données sont indisponibles.' : 'Choisissez les temps autorisés. Le jeu les alterne dans la liste enregistrée et conserve sa progression entre les cartes.'),
            inherit(SpatialVisualParameter.weatherSequence),
          ],
          toggle(
            SpatialVisualParameter.weatherEnabled,
            'Activer la météo',
            Icons.cloud_outlined,
            StudioAccent.water,
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final preset in weatherPresets)
                StudioButton(
                  key: ValueKey('weather-preset-${preset.$1.name}'),
                  label: preset.$2,
                  icon: preset.$3,
                  secondary:
                      automaticWeather ? !weatherSequence.contains(preset.$1.name) : effective.choice(SpatialVisualParameter.weatherKind) !=
                      preset.$1.name,
                  onPressed: onChanged == null
                      ? null
                      : () => selectWeather(preset.$1),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: inherit(SpatialVisualParameter.weatherKind),
          ),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final level in const [('Très léger', .15), ('Léger', .35), ('Marqué', .55), ('Fort', .8), ('Extrême', 1.0)])
              StudioButton(
                key: ValueKey('weather-intensity-${level.$2}'),
                label: level.$1,
                secondary: effective.number(SpatialVisualParameter.weatherIntensity) != level.$2,
                onPressed: onChanged == null ? null : () => change(SpatialVisualParameter.weatherIntensity, level.$2),
              ),
          ]),
          slider(SpatialVisualParameter.weatherIntensity, 'Intensité', 0, 1),
          slider(
            SpatialVisualParameter.weatherDensity,
            'Quantité de particules',
            0,
            1,
          ),
          slider(SpatialVisualParameter.weatherSpeed, 'Vitesse', .1, 3),
          slider(
            SpatialVisualParameter.weatherWindStrength,
            'Force du vent',
            0,
            2,
          ),
          slider(
            SpatialVisualParameter.weatherWindDirection,
            'Direction du vent',
            -180,
            180,
            format: (v) => '${v.round()}°',
          ),
          slider(
            SpatialVisualParameter.weatherParticleSize,
            'Taille des particules',
            .25,
            2,
          ),
          slider(
            SpatialVisualParameter.weatherOpacity,
            'Visibilité des particules',
            0,
            1,
          ),
          slider(
            SpatialVisualParameter.weatherCloudCover,
            'Assombrissement du ciel',
            0,
            1,
          ),
          slider(
            SpatialVisualParameter.weatherFogStrength,
            'Voile atmosphérique',
            0,
            1,
          ),
          slider(
            SpatialVisualParameter.weatherTransitionSeconds,
            'Transition',
            0,
            5,
            format: (v) => '${v.toStringAsFixed(1)} s',
          ),
          toggle(
            SpatialVisualParameter.weatherLightning,
            'Éclairs dans le ciel',
            Icons.bolt_outlined,
            StudioAccent.daylight,
          ),
          toggle(
            SpatialVisualParameter.weatherSoundEnabled,
            'Ambiance sonore',
            Icons.volume_up_outlined,
            StudioAccent.water,
          ),
          slider(SpatialVisualParameter.weatherRainVolume, 'Volume de la pluie', 0, 1),
          slider(SpatialVisualParameter.weatherWindVolume, 'Volume du vent', 0, 1),
          toggle(
            SpatialVisualParameter.weatherIndoors,
            'Autoriser dans les intérieurs',
            Icons.home_outlined,
            StudioAccent.fog,
          ),
          const Text(
            'La météo reste locale à la scène et suit le joueur. Les intérieurs sont protégés par défaut. Les éclairs sont désactivés par défaut.',
          ),
        ]),
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
          const Text(
            'Répartition des couleurs pastel. La densité totale reste plafonnée.',
          ),
          for (final entry in [
            (
              SpatialVisualParameter.fireflyYellowAmount,
              SpatialFireflyColor.yellow,
              'Jaune pâle',
            ),
            (
              SpatialVisualParameter.fireflyGreenAmount,
              SpatialFireflyColor.green,
              'Vert menthe',
            ),
            (
              SpatialVisualParameter.fireflyBlueAmount,
              SpatialFireflyColor.blue,
              'Bleu doux',
            ),
            (
              SpatialVisualParameter.fireflyPinkAmount,
              SpatialFireflyColor.pink,
              'Rose tendre',
            ),
          ])
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, right: 10),
                  child: StudioColorSwatch(colorRgb: entry.$2.rgb),
                ),
                Expanded(child: slider(entry.$1, entry.$3, 0, 1)),
              ],
            ),
          toggle(
            SpatialVisualParameter.fireflyLighting,
            'Éclairer légèrement les alentours',
            Icons.lightbulb_outline,
            StudioAccent.firefly,
          ),
          slider(
            SpatialVisualParameter.fireflyLightStrength,
            'Intensité de la lueur',
            0,
            1,
          ),
          slider(
            SpatialVisualParameter.fireflyLightRadius,
            'Portée en cases',
            .25,
            2.5,
          ),
        ]),
        const Text(
          'L’eau, les fenêtres et les lucioles utilisent les sources placées sur chaque carte. Les ombres restent réglables sur les ressources et sur chaque élément 3D.',
        ),
      ],
    );
  }
}
