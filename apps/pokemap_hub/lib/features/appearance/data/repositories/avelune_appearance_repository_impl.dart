import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_read.dart';
import 'package:pokemap_hub/features/appearance/domain/repositories/avelune_appearance_repository_interface.dart';

typedef AveluneAppearanceDocumentWriter = Future<void> Function(
  File file,
  String contents,
);

/// Atomic, app-private persistence for Avelune appearance IDs only.
///
/// Custom image bytes use a separate fixed-file storage; absolute picker paths
/// can therefore never leak into this JSON document.
final class AveluneAppearanceStore
    implements AveluneAppearanceRepositoryInterface {
  AveluneAppearanceStore({
    required this.supportRoot,
    AveluneAppearanceDocumentWriter? writeDocument,
  }) : _writeDocument = writeDocument ?? _writeDocumentToDisk;

  final Directory supportRoot;
  final AveluneAppearanceDocumentWriter _writeDocument;
  final Random _random = Random.secure();

  Directory get aveluneRoot => Directory(p.join(supportRoot.path, 'avelune'));

  Directory get appearanceRoot =>
      Directory(p.join(aveluneRoot.path, 'appearance'));

  File get preferencesFile =>
      File(p.join(appearanceRoot.path, 'preferences.json'));

  File get backupFile =>
      File(p.join(appearanceRoot.path, 'preferences.backup.json'));

  File get customBackgroundFile =>
      File(p.join(appearanceRoot.path, 'custom-background.jpg'));

  File get customBackgroundThumbnailFile => File(
        p.join(appearanceRoot.path, 'custom-background.thumbnail.jpg'),
      );

  @override
  Future<AveluneAppearanceRead> load() async {
    if (!await _assertSafeDirectories(create: false)) {
      return const AveluneAppearanceRead(
        preferences: AveluneAppearancePreferences(),
        source: AveluneAppearanceSource.defaults,
        currentCorrupt: false,
        backupCorrupt: false,
      );
    }
    await _assertSafeFile(preferencesFile);
    await _assertSafeFile(backupFile);
    var currentCorrupt = false;
    var backupCorrupt = false;
    if (await preferencesFile.exists()) {
      try {
        return AveluneAppearanceRead(
          preferences: await _decode(preferencesFile),
          source: AveluneAppearanceSource.current,
          currentCorrupt: false,
          backupCorrupt: false,
        );
      } on Object {
        currentCorrupt = true;
      }
    }
    if (await backupFile.exists()) {
      try {
        return AveluneAppearanceRead(
          preferences: await _decode(backupFile),
          source: AveluneAppearanceSource.backup,
          currentCorrupt: currentCorrupt,
          backupCorrupt: false,
        );
      } on Object {
        backupCorrupt = true;
      }
    }
    return AveluneAppearanceRead(
      preferences: const AveluneAppearancePreferences(),
      source: AveluneAppearanceSource.defaults,
      currentCorrupt: currentCorrupt,
      backupCorrupt: backupCorrupt,
    );
  }

  @override
  Future<void> save(AveluneAppearancePreferences preferences) async {
    await _assertSafeDirectories(create: true);
    await _assertSafeFile(preferencesFile);
    await _assertSafeFile(backupFile);
    final nonce =
        '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
    final temporary = File(
      p.join(appearanceRoot.path, 'preferences.json.tmp.$nonce'),
    );
    final nextBackup = File(
      p.join(appearanceRoot.path, 'preferences.backup.json.next.$nonce'),
    );
    try {
      await _writeDocument(temporary, jsonEncode(preferences.toJson()));
      final decodedTemporary = await _decode(temporary);
      if (decodedTemporary != preferences) {
        throw const FormatException('Temporary preference mismatch.');
      }

      if (await preferencesFile.exists()) {
        try {
          await _decode(preferencesFile);
          await preferencesFile.copy(nextBackup.path);
          await _flush(nextBackup);
          if (await backupFile.exists()) await backupFile.delete();
          await nextBackup.rename(backupFile.path);
        } on Object {
          if (await nextBackup.exists()) await nextBackup.delete();
        }
      }

      if (await preferencesFile.exists()) await preferencesFile.delete();
      await temporary.rename(preferencesFile.path);
      if (await _decode(preferencesFile) != preferences) {
        throw const FormatException('Preference confirmation mismatch.');
      }
    } on AveluneAppearanceStorageException {
      rethrow;
    } on Object {
      if (!await preferencesFile.exists() && await backupFile.exists()) {
        try {
          await backupFile.copy(preferencesFile.path);
        } on Object {
          // The valid backup remains the recovery source for the next load.
        }
      }
      throw const AveluneAppearanceStorageException(
        'Les préférences d’apparence n’ont pas pu être enregistrées.',
      );
    } finally {
      if (await temporary.exists()) await temporary.delete();
      if (await nextBackup.exists()) await nextBackup.delete();
    }
  }

  Future<AveluneAppearancePreferences> _decode(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      throw const FormatException('Appearance preferences must be an object.');
    }
    return AveluneAppearancePreferences.fromJson(
      Map<String, Object?>.from(decoded),
    );
  }

  Future<bool> _assertSafeDirectories({required bool create}) async {
    for (final directory in <Directory>[
      supportRoot,
      aveluneRoot,
      appearanceRoot,
    ]) {
      final type = await FileSystemEntity.type(
        directory.path,
        followLinks: false,
      );
      if (type == FileSystemEntityType.link ||
          (type != FileSystemEntityType.notFound &&
              type != FileSystemEntityType.directory)) {
        throw const AveluneAppearanceStorageException(
          'Le dossier de préférences Avelune n’est pas sûr.',
        );
      }
      if (type == FileSystemEntityType.notFound) {
        if (!create) return false;
        await directory.create();
        if (await FileSystemEntity.type(
              directory.path,
              followLinks: false,
            ) !=
            FileSystemEntityType.directory) {
          throw const AveluneAppearanceStorageException(
            'Le dossier de préférences Avelune n’a pas pu être créé.',
          );
        }
      }
    }
    return true;
  }

  Future<void> _assertSafeFile(File file) async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const AveluneAppearanceStorageException(
        'Un fichier de préférences Avelune n’est pas sûr.',
      );
    }
  }

  static Future<void> _writeDocumentToDisk(
    File file,
    String contents,
  ) async {
    await file.writeAsString(contents, flush: true);
  }

  Future<void> _flush(File file) async {
    final sink = await file.open(mode: FileMode.append);
    try {
      await sink.flush();
    } finally {
      await sink.close();
    }
  }
}
