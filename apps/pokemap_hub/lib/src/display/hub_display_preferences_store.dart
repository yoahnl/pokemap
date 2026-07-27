import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import 'hub_display_preferences.dart';

final class HubDisplayPreferencesStorageException implements Exception {
  const HubDisplayPreferencesStorageException(this.message);

  final String message;

  @override
  String toString() => 'HubDisplayPreferencesStorageException: $message';
}

abstract interface class HubDisplayPreferencesGateway {
  Future<HubDisplayPreferences> load(HubDesktopPlatform platform);

  Future<void> save(
    HubDesktopPlatform platform,
    HubDisplayPreferences preferences,
  );
}

/// Atomic per-platform display preference storage.
final class HubDisplayPreferencesStore implements HubDisplayPreferencesGateway {
  HubDisplayPreferencesStore({required this.supportRoot});

  final Directory supportRoot;
  final Random _random = Random.secure();

  @override
  Future<HubDisplayPreferences> load(HubDesktopPlatform platform) async {
    final document = await _readBestDocument();
    return document[platform] ?? const HubDisplayPreferences();
  }

  @override
  Future<void> save(
    HubDesktopPlatform platform,
    HubDisplayPreferences preferences,
  ) async {
    await _assertSafeRoot(create: true);
    final current = _current;
    final backup = _backup;
    final nonce =
        '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
    final temporary =
        File(p.join(supportRoot.path, 'display-preferences.json.tmp.$nonce'));
    final nextBackup = File(
      p.join(
        supportRoot.path,
        'display-preferences.backup.json.next.$nonce',
      ),
    );
    try {
      await _assertSafeFile(current);
      await _assertSafeFile(backup);
      final previous = await _readBestDocument();
      final next = <HubDesktopPlatform, HubDisplayPreferences>{
        ...previous,
        platform: preferences,
      };
      await temporary.writeAsString(
        jsonEncode(_encodeDocument(next)),
        flush: true,
      );
      await _decodeDocument(temporary);
      if (await current.exists()) {
        try {
          await _decodeDocument(current);
          await current.copy(nextBackup.path);
          final sink = await nextBackup.open(mode: FileMode.append);
          try {
            await sink.flush();
          } finally {
            await sink.close();
          }
          await nextBackup.rename(backup.path);
        } on Object {
          if (await nextBackup.exists()) await nextBackup.delete();
        }
      }
      await temporary.rename(current.path);
      final confirmed = await _decodeDocument(current);
      if (confirmed[platform] != preferences) {
        throw const FormatException(
          'Display preference confirmation mismatch.',
        );
      }
    } on HubDisplayPreferencesStorageException {
      rethrow;
    } on Object {
      throw const HubDisplayPreferencesStorageException(
        'Display preferences could not be saved atomically.',
      );
    } finally {
      if (await temporary.exists()) await temporary.delete();
      if (await nextBackup.exists()) await nextBackup.delete();
    }
  }

  File get _current =>
      File(p.join(supportRoot.path, 'display-preferences.json'));
  File get _backup =>
      File(p.join(supportRoot.path, 'display-preferences.backup.json'));

  Future<Map<HubDesktopPlatform, HubDisplayPreferences>>
      _readBestDocument() async {
    await _assertSafeRoot(create: false);
    await _assertSafeFile(_current);
    await _assertSafeFile(_backup);
    if (await _current.exists()) {
      try {
        return await _decodeDocument(_current);
      } on Object {
        // The validated backup remains the recovery source.
      }
    }
    if (await _backup.exists()) {
      try {
        return await _decodeDocument(_backup);
      } on Object {
        // Corrupt display preferences safely fall back to defaults.
      }
    }
    return const <HubDesktopPlatform, HubDisplayPreferences>{};
  }

  Future<Map<HubDesktopPlatform, HubDisplayPreferences>> _decodeDocument(
    File file,
  ) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.toSet().difference(
          const <String>{'schemaVersion', 'platforms'},
        ).isNotEmpty ||
        decoded['schemaVersion'] != 1 ||
        decoded['platforms'] is! Map) {
      throw const FormatException(
        'Display preferences must be a supported JSON object.',
      );
    }
    final rawPlatforms = Map<String, dynamic>.from(decoded['platforms'] as Map);
    final result = <HubDesktopPlatform, HubDisplayPreferences>{};
    for (final entry in rawPlatforms.entries) {
      final platform = HubDesktopPlatform.values
          .where((value) => value.name == entry.key)
          .firstOrNull;
      if (platform == null || entry.value is! Map) {
        throw const FormatException('Invalid desktop platform preferences.');
      }
      result[platform] = HubDisplayPreferences.fromJson(
        Map<String, Object?>.from(entry.value as Map),
      );
    }
    return result;
  }

  Map<String, Object?> _encodeDocument(
    Map<HubDesktopPlatform, HubDisplayPreferences> document,
  ) =>
      <String, Object?>{
        'schemaVersion': 1,
        'platforms': <String, Object?>{
          for (final entry in document.entries)
            entry.key.name: entry.value.toJson(),
        },
      };

  Future<void> _assertSafeRoot({required bool create}) async {
    final type = await FileSystemEntity.type(
      supportRoot.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.link ||
        (type != FileSystemEntityType.notFound &&
            type != FileSystemEntityType.directory)) {
      throw const HubDisplayPreferencesStorageException(
        'The display preference storage root is unsafe.',
      );
    }
    if (type == FileSystemEntityType.notFound && create) {
      await supportRoot.create(recursive: true);
    }
  }

  Future<void> _assertSafeFile(File file) async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const HubDisplayPreferencesStorageException(
        'A display preference storage entry is unsafe.',
      );
    }
  }
}
