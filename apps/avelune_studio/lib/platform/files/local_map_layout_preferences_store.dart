import 'dart:convert';
import 'dart:io';

import '../../features/map_workspace/application/map_layout_preferences.dart';

MapLayoutPreferencesStore studioMapLayoutPreferencesStore() {
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
      ? MemoryMapLayoutPreferencesStore()
      : LocalMapLayoutPreferencesStore(
          '$base/Avelune Studio/layout-preferences.json',
        );
}

final class LocalMapLayoutPreferencesStore
    implements MapLayoutPreferencesStore {
  LocalMapLayoutPreferencesStore(this.filePath);

  final String filePath;

  @override
  Future<MapLayoutSnapshot?> load() async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    final data = jsonDecode(await file.readAsString());
    if (data is! Map<String, dynamic> ||
        data['schemaVersion'] != 1 ||
        data['mapOnly'] is! bool ||
        data['navigatorCollapsed'] is! bool) {
      throw const FormatException('Unsupported layout preferences');
    }
    return (
      mapOnly: data['mapOnly'] as bool,
      navigatorCollapsed: data['navigatorCollapsed'] as bool,
    );
  }

  @override
  Future<void> save(MapLayoutSnapshot snapshot) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    final temporary = File('$filePath.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'mapOnly': snapshot.mapOnly,
        'navigatorCollapsed': snapshot.navigatorCollapsed,
      }),
      flush: true,
    );
    await temporary.rename(filePath);
  }
}
