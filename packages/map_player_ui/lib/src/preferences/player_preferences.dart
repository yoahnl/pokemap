import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

enum PlayerLanguage { system, fr, en }

enum PlayerThemePreference { system, light, dark }

@immutable
final class PlayerPreferences {
  const PlayerPreferences({
    this.schemaVersion = 1,
    this.language = PlayerLanguage.system,
    this.theme = PlayerThemePreference.system,
    this.masterVolume = 1,
    this.musicVolume = 0.8,
    this.effectsVolume = 0.8,
    this.textScale = 1,
    this.reducedMotion = false,
    this.highContrast = false,
    this.hapticsEnabled = true,
    this.showInputHints = true,
    this.touchControlsOpacity = 0.82,
    this.launchMostRecentGameOnStartup = false,
    this.dialogueTextSpeed = RuntimeDialogueTextSpeed.normal,
    this.menuEffects = RuntimePlayerMenuEffects.full,
  });

  factory PlayerPreferences.fromJson(Map<String, Object?> json) {
    const keys = <String>{
      'schemaVersion',
      'language',
      'theme',
      'masterVolume',
      'musicVolume',
      'effectsVolume',
      'textScale',
      'reducedMotion',
      'highContrast',
      'hapticsEnabled',
      'showInputHints',
      'touchControlsOpacity',
      'launchMostRecentGameOnStartup',
      'dialogueTextSpeed',
      'menuEffects',
    };
    if (json.keys.toSet().difference(keys).isNotEmpty ||
        json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported player preferences.');
    }
    T read<T>(String key) {
      final value = json[key];
      if (value is! T) throw FormatException('Invalid preference: $key.');
      return value;
    }

    final language = PlayerLanguage.values
        .where((value) => value.name == read<String>('language'))
        .firstOrNull;
    final theme = PlayerThemePreference.values
        .where((value) => value.name == read<String>('theme'))
        .firstOrNull;
    if (language == null || theme == null) {
      throw const FormatException('Invalid player preference enum.');
    }
    final dialogueTextSpeed = RuntimeDialogueTextSpeed.values
        .where((value) => value.name == (json['dialogueTextSpeed'] ?? 'normal'))
        .firstOrNull;
    final menuEffects = RuntimePlayerMenuEffects.values
        .where((value) => value.name == (json['menuEffects'] ?? 'full'))
        .firstOrNull;
    if (dialogueTextSpeed == null || menuEffects == null) {
      throw const FormatException('Invalid player presentation preference.');
    }
    final masterVolume = read<num>('masterVolume').toDouble();
    final musicVolume = read<num>('musicVolume').toDouble();
    final effectsVolume = read<num>('effectsVolume').toDouble();
    final textScale = read<num>('textScale').toDouble();
    final rawTouchControlsOpacity = json['touchControlsOpacity'];
    if (rawTouchControlsOpacity != null && rawTouchControlsOpacity is! num) {
      throw const FormatException(
        'Invalid preference: touchControlsOpacity.',
      );
    }
    final touchControlsOpacity =
        (rawTouchControlsOpacity as num?)?.toDouble() ?? 0.82;
    final rawLaunchMostRecentGameOnStartup =
        json['launchMostRecentGameOnStartup'];
    if (rawLaunchMostRecentGameOnStartup != null &&
        rawLaunchMostRecentGameOnStartup is! bool) {
      throw const FormatException(
        'Invalid preference: launchMostRecentGameOnStartup.',
      );
    }
    if (<double>[masterVolume, musicVolume, effectsVolume]
            .any((value) => !value.isFinite || value < 0 || value > 1) ||
        !textScale.isFinite ||
        textScale < 0.8 ||
        textScale > 1.6 ||
        !touchControlsOpacity.isFinite ||
        touchControlsOpacity < 0.3 ||
        touchControlsOpacity > 1) {
      throw const FormatException('Player preference value out of range.');
    }
    return PlayerPreferences(
      language: language,
      theme: theme,
      dialogueTextSpeed: dialogueTextSpeed,
      menuEffects: menuEffects,
      masterVolume: masterVolume,
      musicVolume: musicVolume,
      effectsVolume: effectsVolume,
      textScale: textScale,
      reducedMotion: read<bool>('reducedMotion'),
      highContrast: read<bool>('highContrast'),
      hapticsEnabled: read<bool>('hapticsEnabled'),
      showInputHints: read<bool>('showInputHints'),
      touchControlsOpacity: touchControlsOpacity,
      launchMostRecentGameOnStartup:
          rawLaunchMostRecentGameOnStartup as bool? ?? false,
    );
  }

  final int schemaVersion;
  final PlayerLanguage language;
  final PlayerThemePreference theme;
  final double masterVolume;
  final double musicVolume;
  final double effectsVolume;
  final double textScale;
  final bool reducedMotion;
  final bool highContrast;
  final bool hapticsEnabled;
  final bool showInputHints;
  final double touchControlsOpacity;
  final bool launchMostRecentGameOnStartup;
  final RuntimeDialogueTextSpeed dialogueTextSpeed;
  final RuntimePlayerMenuEffects menuEffects;

  Locale? get locale => switch (language) {
        PlayerLanguage.system => null,
        PlayerLanguage.fr => const Locale('fr'),
        PlayerLanguage.en => const Locale('en'),
      };

  ThemeMode get themeMode => switch (theme) {
        PlayerThemePreference.system => ThemeMode.system,
        PlayerThemePreference.light => ThemeMode.light,
        PlayerThemePreference.dark => ThemeMode.dark,
      };

  PlayerPreferencesSnapshot toRuntimeSnapshot({required String fallbackLocale}) =>
      PlayerPreferencesSnapshot(
        locale: locale?.languageCode ?? fallbackLocale,
        accessibility: GameSessionAccessibilityOptions(
          reducedMotion: reducedMotion,
          textScale: textScale,
          hapticsEnabled: hapticsEnabled,
        ),
        touchControlsOpacity: touchControlsOpacity,
        audioMix: RuntimeAudioMix(
          masterVolume: masterVolume,
          musicVolume: musicVolume,
          effectsVolume: effectsVolume,
        ),
        highContrast: highContrast,
        showInputHints: showInputHints,
        dialogueTextSpeed: dialogueTextSpeed,
        menuEffects: menuEffects,
      );

  PlayerPreferences copyWithRuntimeSnapshot(PlayerPreferencesSnapshot snapshot) =>
      copyWith(
        language: switch (snapshot.locale.split(RegExp('[-_]')).first.toLowerCase()) {
          'fr' => PlayerLanguage.fr,
          'en' => PlayerLanguage.en,
          _ => PlayerLanguage.system,
        },
        reducedMotion: snapshot.accessibility.reducedMotion,
        textScale: snapshot.accessibility.textScale,
        hapticsEnabled: snapshot.accessibility.hapticsEnabled,
        touchControlsOpacity: snapshot.touchControlsOpacity,
        masterVolume: snapshot.audioMix.masterVolume,
        musicVolume: snapshot.audioMix.musicVolume,
        effectsVolume: snapshot.audioMix.effectsVolume,
        highContrast: snapshot.highContrast,
        showInputHints: snapshot.showInputHints,
        dialogueTextSpeed: snapshot.dialogueTextSpeed,
        menuEffects: snapshot.menuEffects,
      );

  PlayerPreferences copyWith({
    PlayerLanguage? language,
    PlayerThemePreference? theme,
    double? masterVolume,
    double? musicVolume,
    double? effectsVolume,
    double? textScale,
    bool? reducedMotion,
    bool? highContrast,
    bool? hapticsEnabled,
    bool? showInputHints,
    double? touchControlsOpacity,
    bool? launchMostRecentGameOnStartup,
    RuntimeDialogueTextSpeed? dialogueTextSpeed,
    RuntimePlayerMenuEffects? menuEffects,
  }) =>
      PlayerPreferences(
        language: language ?? this.language,
        dialogueTextSpeed: dialogueTextSpeed ?? this.dialogueTextSpeed,
        menuEffects: menuEffects ?? this.menuEffects,
        theme: theme ?? this.theme,
        masterVolume: masterVolume ?? this.masterVolume,
        musicVolume: musicVolume ?? this.musicVolume,
        effectsVolume: effectsVolume ?? this.effectsVolume,
        textScale: textScale ?? this.textScale,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        highContrast: highContrast ?? this.highContrast,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        showInputHints: showInputHints ?? this.showInputHints,
        touchControlsOpacity: touchControlsOpacity ?? this.touchControlsOpacity,
        launchMostRecentGameOnStartup:
            launchMostRecentGameOnStartup ?? this.launchMostRecentGameOnStartup,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'language': language.name,
        'dialogueTextSpeed': dialogueTextSpeed.name,
        'menuEffects': menuEffects.name,
        'theme': theme.name,
        'masterVolume': masterVolume,
        'musicVolume': musicVolume,
        'effectsVolume': effectsVolume,
        'textScale': textScale,
        'reducedMotion': reducedMotion,
        'highContrast': highContrast,
        'hapticsEnabled': hapticsEnabled,
        'showInputHints': showInputHints,
        'touchControlsOpacity': touchControlsOpacity,
        'launchMostRecentGameOnStartup': launchMostRecentGameOnStartup,
      };

  @override
  bool operator ==(Object other) =>
      other is PlayerPreferences &&
      schemaVersion == other.schemaVersion &&
      language == other.language &&
      dialogueTextSpeed == other.dialogueTextSpeed &&
      menuEffects == other.menuEffects &&
      theme == other.theme &&
      masterVolume == other.masterVolume &&
      musicVolume == other.musicVolume &&
      effectsVolume == other.effectsVolume &&
      textScale == other.textScale &&
      reducedMotion == other.reducedMotion &&
      highContrast == other.highContrast &&
      hapticsEnabled == other.hapticsEnabled &&
      showInputHints == other.showInputHints &&
      touchControlsOpacity == other.touchControlsOpacity &&
      launchMostRecentGameOnStartup == other.launchMostRecentGameOnStartup;

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        language,
        dialogueTextSpeed,
        menuEffects,
        theme,
        masterVolume,
        musicVolume,
        effectsVolume,
        textScale,
        reducedMotion,
        highContrast,
        hapticsEnabled,
        showInputHints,
        touchControlsOpacity,
        launchMostRecentGameOnStartup,
      );
}
