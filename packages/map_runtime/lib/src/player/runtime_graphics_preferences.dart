import 'package:map_core/map_core.dart';

final class RuntimeGraphicsPreferences {
  const RuntimeGraphicsPreferences({
    this.renderScalePercent,
    this.depthOfField = true,
    this.shadows = true,
    this.fogAndHalos = true,
    this.ambientAnimation = true,
  }) : assert(
         renderScalePercent == null ||
             renderScalePercent == 50 ||
             renderScalePercent == 67 ||
             renderScalePercent == 75 ||
             renderScalePercent == 100,
         'renderScalePercent must be a supported render scale',
       );

  factory RuntimeGraphicsPreferences.fromJson(Map<String, Object?> json) {
    const keys = {
      'renderScalePercent',
      'depthOfField',
      'shadows',
      'fogAndHalos',
      'ambientAnimation',
    };
    final scale = json['renderScalePercent'];
    bool flag(String key) => switch (json[key]) {
      null => true,
      final bool value => value,
      _ => throw FormatException('Invalid graphics preference: $key.'),
    };
    if (json.keys.any((key) => !keys.contains(key)) ||
        scale != null && !renderScaleChoices.contains(scale)) {
      throw const FormatException('Invalid graphics preferences.');
    }
    return RuntimeGraphicsPreferences(
      renderScalePercent: scale as int?,
      depthOfField: flag('depthOfField'),
      shadows: flag('shadows'),
      fogAndHalos: flag('fogAndHalos'),
      ambientAnimation: flag('ambientAnimation'),
    );
  }

  static const renderScaleChoices = [50, 67, 75, 100];

  final int? renderScalePercent;
  final bool depthOfField;
  final bool shadows;
  final bool fogAndHalos;
  final bool ambientAnimation;

  double? get renderScale => switch (renderScalePercent) {
    final percent? => percent / 100,
    _ => null,
  };

  SpatialVisualPatch get visualOverrides => SpatialVisualPatch({
    if (!depthOfField) SpatialVisualParameter.depthOfFieldEnabled: false,
    if (!fogAndHalos) ...{
      SpatialVisualParameter.halosEnabled: false,
      SpatialVisualParameter.depthFogEnabled: false,
    },
    if (!ambientAnimation) ...{
      SpatialVisualParameter.waterAnimated: false,
      SpatialVisualParameter.windowsLit: false,
      SpatialVisualParameter.fireflies: false,
      SpatialVisualParameter.fireflyLighting: false,
      SpatialVisualParameter.weatherEnabled: false,
    },
  });

  RuntimeGraphicsPreferences copyWith({
    int? Function()? renderScalePercent,
    bool? depthOfField,
    bool? shadows,
    bool? fogAndHalos,
    bool? ambientAnimation,
  }) => RuntimeGraphicsPreferences(
    renderScalePercent: renderScalePercent == null
        ? this.renderScalePercent
        : renderScalePercent(),
    depthOfField: depthOfField ?? this.depthOfField,
    shadows: shadows ?? this.shadows,
    fogAndHalos: fogAndHalos ?? this.fogAndHalos,
    ambientAnimation: ambientAnimation ?? this.ambientAnimation,
  );

  Map<String, Object?> toJson() => {
    if (renderScalePercent != null) 'renderScalePercent': renderScalePercent,
    if (!depthOfField) 'depthOfField': false,
    if (!shadows) 'shadows': false,
    if (!fogAndHalos) 'fogAndHalos': false,
    if (!ambientAnimation) 'ambientAnimation': false,
  };

  @override
  bool operator ==(Object other) =>
      other is RuntimeGraphicsPreferences &&
      renderScalePercent == other.renderScalePercent &&
      depthOfField == other.depthOfField &&
      shadows == other.shadows &&
      fogAndHalos == other.fogAndHalos &&
      ambientAnimation == other.ambientAnimation;

  @override
  int get hashCode => Object.hash(
    renderScalePercent,
    depthOfField,
    shadows,
    fogAndHalos,
    ambientAnimation,
  );
}
