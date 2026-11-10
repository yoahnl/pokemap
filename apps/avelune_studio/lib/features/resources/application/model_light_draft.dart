import 'package:map_core/map_core.dart';

class ModelLightDraft {
  late bool enabled, nightOnly, cycle, flame;
  late int color;
  late List<String> values;
  late List<int> colors;
  late double period, enter, exit, fade;
  late double flameHeight, flameFlicker;
  late double flameEmbers;
  late double flameCrackleVolume;
  late ModelLightFlameStyle flameStyle;
  String proximity = 'always';
  bool saving = false, _closed = false;
  String? error;
  ModelLightDraft(ProjectModel3dEntry model) {
    final light = model.light, bounds = model.inspection.bounds;
    enabled = light != null;
    nightOnly = light?.nightOnly ?? true;
    color = light?.colorRgb ?? 0xffd59a;
    values = [
      light?.localPosition.x ?? (bounds.min.x + bounds.max.x) / 2,
      light?.localPosition.y ?? bounds.min.y + bounds.size.y * .9,
      light?.localPosition.z ?? (bounds.min.z + bounds.max.z) / 2,
      light?.radius ?? 4,
      light?.intensity ?? 1,
    ].map((v) => '$v').toList();
    cycle = light?.colorCycle != null;
    colors =
        light?.colorCycle?.colors.toList() ??
        [
          color,
          color == SpatialFireflyColor.blue.rgb
              ? SpatialFireflyColor.pink.rgb
              : SpatialFireflyColor.blue.rgb,
        ];
    period = light?.colorCycle?.periodSeconds ?? 10;
    proximity = light?.proximity?.mode.name ?? 'always';
    enter = light?.proximity?.enterDistance ?? 3;
    exit = light?.proximity?.exitDistance ?? 4;
    fade = light?.proximity?.fadeSeconds ?? .35;
    flame = light?.flame != null;
    flameHeight = light?.flame?.height ?? .35;
    flameFlicker = light?.flame?.flicker ?? .12;
    flameEmbers = light?.flame?.embers ?? 0;
    flameCrackleVolume = light?.flame?.crackleVolume ?? 0;
    flameStyle = light?.flame?.style ?? ModelLightFlameStyle.candle;
    error = null;
  }

  Model3dPointLight? build() {
    if (!enabled) return null;
    final n = values
        .map((v) => double.tryParse(v.replaceAll(',', '.')))
        .toList();
    if (n.any((v) => v == null || !v.isFinite)) {
      throw const FormatException('Saisissez des nombres valides.');
    }
    return Model3dPointLight(
      localPosition: Model3dVector3(x: n[0]!, y: n[1]!, z: n[2]!),
      radius: n[3]!,
      intensity: n[4]!,
      colorRgb: color,
      nightOnly: nightOnly,
      flame: flame
          ? ModelLightFlame(
              height: flameHeight,
              flicker: flameFlicker,
              style: flameStyle,
              embers: flameEmbers,
              crackleVolume: flameCrackleVolume,
            )
          : null,
      colorCycle: cycle
          ? ModelLightColorCycle(colors: colors, periodSeconds: period)
          : null,
      proximity: proximity == 'always'
          ? null
          : ModelLightProximity(
              mode: ModelLightProximityMode.values.byName(proximity),
              enterDistance: enter,
              exitDistance: exit,
              fadeSeconds: fade,
            ),
    );
  }

  bool move(Model3dVector3 position) {
    final coordinates = [position.x, position.y, position.z];
    if (List.generate(
      3,
      (i) => double.tryParse(values[i]) == coordinates[i],
    ).every((same) => same)) {
      return false;
    }
    for (var i = 0; i < 3; i++) {
      values[i] = coordinates[i].toStringAsFixed(4);
    }
    return true;
  }

  Future<bool> save(
    Future<void> Function(Model3dPointLight?) publish, {
    required bool Function() canSave,
  }) async {
    if (_closed || saving || !canSave()) return false;
    saving = true;
    error = null;
    try {
      await publish(build());
      return !_closed;
    } on Object catch (failure) {
      if (!_closed) error = 'Éclairage non enregistré : $failure';
      return false;
    } finally {
      saving = false;
    }
  }

  void dispose() => _closed = true;
}
