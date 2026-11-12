import 'dart:convert';
import 'dart:io';

import '../../features/language/application/studio_language_preferences.dart';

StudioLanguageStore studioLanguageStore() {
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
      ? MemoryStudioLanguageStore()
      : LocalStudioLanguageStore(
          '$base/Avelune Studio/language-preferences.json',
        );
}

final class LocalStudioLanguageStore implements StudioLanguageStore {
  LocalStudioLanguageStore(this.filePath);

  final String filePath;

  @override
  Future<String?> load() async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    final data = jsonDecode(await file.readAsString());
    final code = data is Map<String, dynamic> ? data['languageCode'] : null;
    if (data is! Map<String, dynamic> ||
        data['schemaVersion'] != 1 ||
        (code != null && (code is! String || !_valid.hasMatch(code))) ||
        data.keys.toSet().difference({
          'schemaVersion',
          'languageCode',
        }).isNotEmpty) {
      throw const FormatException('Invalid language preferences');
    }
    return code as String?;
  }

  @override
  Future<void> save(String? languageCode) async {
    if (languageCode != null && !_valid.hasMatch(languageCode)) {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
    final destination = File(filePath);
    await destination.parent.create(recursive: true);
    final temporary = await destination.parent.createTemp('.language-');
    try {
      final pending = File('${temporary.path}/pending.json');
      await pending.writeAsString(
        jsonEncode({'schemaVersion': 1, 'languageCode': languageCode}),
        flush: true,
      );
      await pending.rename(destination.path);
    } finally {
      await temporary.delete(recursive: true);
    }
  }

  static final _valid = RegExp(r'^[a-z]{2,3}$');
}
