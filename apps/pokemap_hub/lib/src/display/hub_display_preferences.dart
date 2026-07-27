import 'package:flutter/widgets.dart';

enum HubDesktopPlatform { macos, windows, linux }

enum HubDisplayMode { windowed, fullscreen }

enum HubWindowSizePreset {
  compact(Size(1024, 640)),
  balanced(Size(1280, 800)),
  spacious(Size(1440, 900));

  const HubWindowSizePreset(this.logicalSize);

  final Size logicalSize;
}

@immutable
final class HubDisplayPreferences {
  const HubDisplayPreferences({
    this.schemaVersion = 1,
    this.mode = HubDisplayMode.windowed,
    this.windowSize = HubWindowSizePreset.balanced,
  });

  factory HubDisplayPreferences.fromJson(Map<String, Object?> json) {
    const keys = <String>{'schemaVersion', 'mode', 'windowSize'};
    if (json.keys.toSet().difference(keys).isNotEmpty ||
        json['schemaVersion'] != 1 ||
        json['mode'] is! String ||
        json['windowSize'] is! String) {
      throw const FormatException('Unsupported display preferences.');
    }
    final mode = HubDisplayMode.values
        .where((value) => value.name == json['mode'])
        .firstOrNull;
    final windowSize = HubWindowSizePreset.values
        .where((value) => value.name == json['windowSize'])
        .firstOrNull;
    if (mode == null || windowSize == null) {
      throw const FormatException('Invalid display preference enum.');
    }
    return HubDisplayPreferences(mode: mode, windowSize: windowSize);
  }

  final int schemaVersion;
  final HubDisplayMode mode;
  final HubWindowSizePreset windowSize;

  HubDisplayPreferences copyWith({
    HubDisplayMode? mode,
    HubWindowSizePreset? windowSize,
  }) =>
      HubDisplayPreferences(
        mode: mode ?? this.mode,
        windowSize: windowSize ?? this.windowSize,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'mode': mode.name,
        'windowSize': windowSize.name,
      };

  @override
  bool operator ==(Object other) =>
      other is HubDisplayPreferences &&
      schemaVersion == other.schemaVersion &&
      mode == other.mode &&
      windowSize == other.windowSize;

  @override
  int get hashCode => Object.hash(schemaVersion, mode, windowSize);
}
