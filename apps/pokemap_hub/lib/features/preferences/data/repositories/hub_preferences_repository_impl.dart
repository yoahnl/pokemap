import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:map_player_ui/map_player_ui.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/features/preferences/domain/entities/hub_preferences_read.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';

final class HubPreferencesStore
    implements PlayerPreferencesRepositoryInterface {
  HubPreferencesStore({required this.supportRoot});

  final Directory supportRoot;
  final Random _random = Random.secure();

  @override
  Future<HubPreferencesRead> load() async {
    await _assertSafeRoot(create: false);
    var currentCorrupt = false;
    var backupCorrupt = false;
    final current = File(p.join(supportRoot.path, 'preferences.json'));
    final backup = File(p.join(supportRoot.path, 'preferences.backup.json'));
    await _assertSafeFile(current);
    await _assertSafeFile(backup);
    if (await current.exists()) {
      try {
        return HubPreferencesRead(
          preferences: await _decode(current),
          source: HubPreferencesSource.current,
          currentCorrupt: false,
          backupCorrupt: false,
        );
      } on Object {
        currentCorrupt = true;
      }
    }
    if (await backup.exists()) {
      try {
        return HubPreferencesRead(
          preferences: await _decode(backup),
          source: HubPreferencesSource.backup,
          currentCorrupt: currentCorrupt,
          backupCorrupt: false,
        );
      } on Object {
        backupCorrupt = true;
      }
    }
    return HubPreferencesRead(
      preferences: const PlayerPreferences(),
      source: HubPreferencesSource.defaults,
      currentCorrupt: currentCorrupt,
      backupCorrupt: backupCorrupt,
    );
  }

  @override
  Future<void> save(PlayerPreferences preferences) async {
    await _assertSafeRoot(create: true);
    final current = File(p.join(supportRoot.path, 'preferences.json'));
    final backup = File(p.join(supportRoot.path, 'preferences.backup.json'));
    final nonce =
        '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
    final temporary =
        File(p.join(supportRoot.path, 'preferences.json.tmp.$nonce'));
    final nextBackup =
        File(p.join(supportRoot.path, 'preferences.backup.json.next.$nonce'));
    try {
      await _assertSafeFile(current);
      await _assertSafeFile(backup);
      await temporary.writeAsString(
        jsonEncode(preferences.toJson()),
        flush: true,
      );
      await _decode(temporary);
      if (await current.exists()) {
        try {
          await _decode(current);
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
      final confirmed = await _decode(current);
      if (confirmed != preferences) {
        throw const FormatException('Preference confirmation mismatch.');
      }
    } on HubPreferencesStorageException {
      rethrow;
    } on Object {
      throw const HubPreferencesStorageException(
        'Player preferences could not be saved atomically.',
      );
    } finally {
      if (await temporary.exists()) await temporary.delete();
      if (await nextBackup.exists()) await nextBackup.delete();
    }
  }

  Future<PlayerPreferences> _decode(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Preferences must be a JSON object.');
    }
    return PlayerPreferences.fromJson(
      Map<String, Object?>.from(decoded),
    );
  }

  Future<void> _assertSafeRoot({required bool create}) async {
    final type = await FileSystemEntity.type(
      supportRoot.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.link ||
        (type != FileSystemEntityType.notFound &&
            type != FileSystemEntityType.directory)) {
      throw const HubPreferencesStorageException(
        'The preference storage root is unsafe.',
      );
    }
    if (type == FileSystemEntityType.notFound && create) {
      await supportRoot.create(recursive: true);
      if (await FileSystemEntity.type(
            supportRoot.path,
            followLinks: false,
          ) !=
          FileSystemEntityType.directory) {
        throw const HubPreferencesStorageException(
          'The preference storage root could not be created.',
        );
      }
    }
  }

  Future<void> _assertSafeFile(File file) async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const HubPreferencesStorageException(
        'A preference storage entry is unsafe.',
      );
    }
  }
}
