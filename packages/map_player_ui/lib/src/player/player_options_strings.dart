import 'package:flutter/widgets.dart';
import 'package:map_runtime/map_runtime.dart';

import '../localization/player_localizations.dart';

enum PlayerOptionsCategory {
  general,
  display,
  audio,
  controls,
  language,
  weather,
  time,
  accessibility,
}

final class PlayerOptionsStrings {
  const PlayerOptionsStrings._(this._strings);

  factory PlayerOptionsStrings.of(BuildContext context) =>
      PlayerOptionsStrings._(context.playerL10n);

  final PokeMapPlayerLocalizations _strings;

  String category(PlayerOptionsCategory value) => switch (value) {
    PlayerOptionsCategory.general => _strings.optionsCategoryGeneral,
    PlayerOptionsCategory.weather => _strings.optionsCategoryWeather,
    PlayerOptionsCategory.time => _strings.optionsCategoryTime,
    PlayerOptionsCategory.display => _strings.optionsCategoryDisplay,
    PlayerOptionsCategory.audio => _strings.optionsCategoryAudio,
    PlayerOptionsCategory.controls => _strings.optionsCategoryControls,
    PlayerOptionsCategory.language => _strings.language,
    PlayerOptionsCategory.accessibility => _strings.accessibility,
  };

  String speed(RuntimeDialogueTextSpeed value) => switch (value) {
    RuntimeDialogueTextSpeed.slow => _strings.optionsSpeedSlow,
    RuntimeDialogueTextSpeed.normal => _strings.optionsSpeedNormal,
    RuntimeDialogueTextSpeed.fast => _strings.optionsSpeedFast,
    RuntimeDialogueTextSpeed.instant => _strings.optionsSpeedInstant,
  };

  String effects(RuntimePlayerMenuEffects value) => switch (value) {
    RuntimePlayerMenuEffects.full => _strings.optionsEffectsFull,
    RuntimePlayerMenuEffects.reduced => _strings.optionsEffectsReduced,
    RuntimePlayerMenuEffects.opaque => _strings.optionsEffectsOpaque,
  };

  String help(PlayerOptionsCategory value) => switch (value) {
    PlayerOptionsCategory.weather => _strings.optionsHelpWeather,
    PlayerOptionsCategory.time => _strings.optionsHelpTime,
    PlayerOptionsCategory.general => _strings.optionsHelpGeneral,
    PlayerOptionsCategory.display => _strings.optionsHelpDisplay,
    PlayerOptionsCategory.audio => _strings.optionsHelpAudio,
    PlayerOptionsCategory.controls => _strings.optionsHelpControls,
    PlayerOptionsCategory.language => _strings.optionsHelpLanguage,
    PlayerOptionsCategory.accessibility => _strings.optionsHelpAccessibility,
  };

  String get scope => _strings.optionsScope;
  String get back => _strings.back;
  String get categories => _strings.optionsCategories;
  String get defaults => _strings.optionsDefaults;
  String get cancel => _strings.cancel;
  String get restore => _strings.optionsRestore;
  String get saving => _strings.optionsSaving;
  String get error => _strings.optionsError;
  String get returnToTitle => _strings.optionsReturnToTitle;
  String get textSpeed => _strings.optionsTextSpeed;
  String get battleSpeed => _strings.optionsBattleSpeed;
  String get battleEffectIntensity => _strings.optionsBattleEffectIntensity;
  String get menuEffects => _strings.optionsMenuEffects;
  String get frameRateLimit => _strings.optionsFrameRateLimit;
  String get renderScale => _strings.optionsRenderScale;
  String renderScaleValue(int? percent) => switch (percent) {
    final value? => _strings.optionsRenderScalePercent(percent: value),
    _ => _strings.optionsRenderScaleValue,
  };
  String get upscaling => _strings.optionsUpscaling;
  String upscalingValue(RuntimeUpscaling value) => switch (value) {
    RuntimeUpscaling.nearest => _strings.optionsUpscalingValueNearest,
    RuntimeUpscaling.fsr1 => _strings.optionsFsr,
  };
  String get depthOfField => _strings.optionsDepthOfField;
  String get shadows => _strings.optionsShadows;
  String get fogAndHalos => _strings.optionsFogAndHalos;
  String get ambientAnimation => _strings.optionsAmbientAnimation;
  String get worldTime => _strings.optionsWorldTime;
  String worldTimeValue(
    RuntimeWorldTimePreferences value,
  ) => switch (value.chosenMinuteOfDay) {
    final minute? =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}',
    _ => _strings.optionsWorldTimeValue,
  };
  String frameRate(int value) => _strings.optionsFrameRateValue(rate: value);
  String get master => _strings.optionsMaster;
  String get music => _strings.music;
  String get soundEffects => _strings.optionsSoundEffects;
  String get interfaceLanguage => _strings.optionsInterfaceLanguage;
  String get followApplicationLanguage =>
      _strings.optionsFollowApplicationLanguage;
  String get textSize => _strings.textSize;
  String get reducedMotion => _strings.reducedMotion;
  String get highContrast => _strings.optionsHighContrast;
  String get haptics => _strings.optionsHaptics;
  String get hints => _strings.optionsHints;
  String get touchOpacity => _strings.touchControlsOpacity;
  String get leftHandedTouchControls => _strings.optionsLeftHandedTouchControls;
  String get touchRunMode => _strings.optionsTouchRunMode;
  String runningMode(RuntimePlayerTouchRunMode mode) => switch (mode) {
    RuntimePlayerTouchRunMode.gesture => _strings.optionsRunningModeGesture,
    RuntimePlayerTouchRunMode.walkOnly => _strings.optionsRunningModeWalkOnly,
    RuntimePlayerTouchRunMode.automatic => _strings.optionsRunningModeAutomatic,
  };
  String resetTitle(PlayerOptionsCategory value) =>
      _strings.optionsResetTitle(category: category(value));
  String resetMessage(PlayerOptionsCategory value) =>
      value == PlayerOptionsCategory.controls
      ? _strings.optionsResetControlsMessage
      : _strings.optionsResetMessage(category: category(value));
}
