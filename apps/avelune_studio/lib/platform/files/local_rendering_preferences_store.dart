import 'dart:convert';
import 'dart:io';

import 'package:avelune_rendering/avelune_rendering.dart';

import '../../features/rendering/application/studio_rendering_preferences.dart';

StudioRenderingPreferencesStore studioRenderingPreferencesStore() {
  final home = Platform.environment['HOME'];
  final base = Platform.isWindows
      ? Platform.environment['APPDATA']
      : Platform.isMacOS
      ? home == null
            ? null
            : '$home/Library/Application Support'
      : Platform.environment['XDG_CONFIG_HOME'] ??
            (home == null ? null : '$home/.config');
  return base == null
      ? MemoryRenderingPreferencesStore()
      : LocalRenderingPreferencesStore(
          '$base/Avelune Studio/rendering-preferences.json',
        );
}

class LocalRenderingPreferencesStore
    implements StudioRenderingPreferencesStore {
  LocalRenderingPreferencesStore(this.filePath);

  final String filePath;

  @override
  Future<int?> load() async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    final data = jsonDecode(await file.readAsString());
    if (data is! Map<String, dynamic> ||
        data['schemaVersion'] is! int ||
        data['schemaVersion'] != 1 ||
        data['targetFramesPerSecond'] is! int ||
        !AveluneFrameRate.supportedLimits.contains(
          data['targetFramesPerSecond'],
        ) ||
        data.keys.toSet().difference({
          'schemaVersion',
          'targetFramesPerSecond',
        }).isNotEmpty) {
      throw const FormatException('Invalid rendering preferences');
    }
    return data['targetFramesPerSecond'] as int;
  }

  @override
  Future<void> save(int limit) async {
    if (!AveluneFrameRate.supportedLimits.contains(limit)) {
      throw ArgumentError.value(limit, 'limit', 'Unsupported frame rate');
    }
    final destination = File(filePath);
    await destination.parent.create(recursive: true);
    final temporary = await destination.parent.createTemp('.rendering-');
    try {
      final pending = File('${temporary.path}/pending.json');
      await pending.writeAsString(
        jsonEncode({'schemaVersion': 1, 'targetFramesPerSecond': limit}),
        flush: true,
      );
      await pending.rename(destination.path);
    } finally {
      await temporary.delete(recursive: true);
    }
  }
}
