import 'dart:convert';
import 'dart:io';

import '../../features/settings/studio_appearance_preferences.dart';
import 'studio_preferences.dart';

StudioAppearanceStore studioAppearanceStore() {
  final directory = studioPreferencesDirectory();
  return directory == null
      ? MemoryStudioAppearanceStore()
      : LocalStudioAppearanceStore('$directory/appearance-preferences.json');
}

final class LocalStudioAppearanceStore implements StudioAppearanceStore {
  LocalStudioAppearanceStore(this.filePath);

  final String filePath;

  @override
  Future<StudioAppearance?> load() async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    final data = jsonDecode(await file.readAsString());
    if (data is! Map<String, dynamic> ||
        data['schemaVersion'] != 1 ||
        data.length != 2) {
      throw const FormatException('Invalid appearance preferences');
    }
    return switch (data['appearance']) {
      'dark' => StudioAppearance.dark,
      'light' => StudioAppearance.light,
      _ => throw const FormatException('Invalid Studio appearance'),
    };
  }

  @override
  Future<void> save(StudioAppearance appearance) async {
    final destination = File(filePath);
    await destination.parent.create(recursive: true);
    final temporary = await destination.parent.createTemp('.appearance-');
    try {
      final pending = File('${temporary.path}/pending.json');
      await pending.writeAsString(
        jsonEncode({'schemaVersion': 1, 'appearance': appearance.name}),
        flush: true,
      );
      await pending.rename(destination.path);
    } finally {
      await temporary.delete(recursive: true);
    }
  }
}
