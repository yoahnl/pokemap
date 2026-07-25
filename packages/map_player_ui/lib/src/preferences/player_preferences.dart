import 'package:flutter/material.dart';

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
    final masterVolume = read<num>('masterVolume').toDouble();
    final musicVolume = read<num>('musicVolume').toDouble();
    final effectsVolume = read<num>('effectsVolume').toDouble();
    final textScale = read<num>('textScale').toDouble();
    if (<double>[masterVolume, musicVolume, effectsVolume]
            .any((value) => !value.isFinite || value < 0 || value > 1) ||
        !textScale.isFinite ||
        textScale < 0.8 ||
        textScale > 1.6) {
      throw const FormatException('Player preference value out of range.');
    }
    return PlayerPreferences(
      language: language,
      theme: theme,
      masterVolume: masterVolume,
      musicVolume: musicVolume,
      effectsVolume: effectsVolume,
      textScale: textScale,
      reducedMotion: read<bool>('reducedMotion'),
      highContrast: read<bool>('highContrast'),
      hapticsEnabled: read<bool>('hapticsEnabled'),
      showInputHints: read<bool>('showInputHints'),
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
  }) =>
      PlayerPreferences(
        language: language ?? this.language,
        theme: theme ?? this.theme,
        masterVolume: masterVolume ?? this.masterVolume,
        musicVolume: musicVolume ?? this.musicVolume,
        effectsVolume: effectsVolume ?? this.effectsVolume,
        textScale: textScale ?? this.textScale,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        highContrast: highContrast ?? this.highContrast,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        showInputHints: showInputHints ?? this.showInputHints,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'language': language.name,
        'theme': theme.name,
        'masterVolume': masterVolume,
        'musicVolume': musicVolume,
        'effectsVolume': effectsVolume,
        'textScale': textScale,
        'reducedMotion': reducedMotion,
        'highContrast': highContrast,
        'hapticsEnabled': hapticsEnabled,
        'showInputHints': showInputHints,
      };

  @override
  bool operator ==(Object other) =>
      other is PlayerPreferences &&
      schemaVersion == other.schemaVersion &&
      language == other.language &&
      theme == other.theme &&
      masterVolume == other.masterVolume &&
      musicVolume == other.musicVolume &&
      effectsVolume == other.effectsVolume &&
      textScale == other.textScale &&
      reducedMotion == other.reducedMotion &&
      highContrast == other.highContrast &&
      hapticsEnabled == other.hapticsEnabled &&
      showInputHints == other.showInputHints;

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        language,
        theme,
        masterVolume,
        musicVolume,
        effectsVolume,
        textScale,
        reducedMotion,
        highContrast,
        hapticsEnabled,
        showInputHints,
      );
}
