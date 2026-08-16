import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import 'game_package_export_profile.dart';

final class GamePackageExportProfileStore {
  const GamePackageExportProfileStore({required this.projectRoot});

  final Directory projectRoot;

  File get profileFile => File(
        p.join(projectRoot.path, '.pokemap', 'export-profile-v1.json'),
      );

  Future<GamePackageExportProfile?> load() async {
    final file = profileFile;
    if (!await file.exists()) return null;
    try {
      return GamePackageExportProfile.decodeUtf8(await file.readAsBytes());
    } on GamePackageExportException {
      rethrow;
    } on Object catch (error) {
      throw GamePackageExportException(
        code: 'exportProfileReadFailed',
        path: file.path,
        message: 'The saved export profile could not be read.',
        cause: error,
      );
    }
  }

  Future<void> save(GamePackageExportProfile profile) async {
    final target = profileFile;
    final parent = target.parent;
    await parent.create(recursive: true);
    final token = '${DateTime.now().microsecondsSinceEpoch}-$pid';
    final temporary = File('${target.path}.$token.tmp');
    final backup = File('${target.path}.backup');
    var backedUp = false;
    try {
      await temporary.writeAsBytes(
        CanonicalJson.encodeUtf8(profile.toJson()),
        flush: true,
      );
      final roundTrip =
          GamePackageExportProfile.decodeUtf8(await temporary.readAsBytes());
      if (roundTrip != profile) {
        throw const GamePackageExportException(
          code: 'exportProfileWriteFailed',
          message: 'The export profile changed during persistence.',
        );
      }
      if (await target.exists()) {
        if (await backup.exists()) await backup.delete();
        await target.rename(backup.path);
        backedUp = true;
      }
      await temporary.rename(target.path);
      if (backedUp && await backup.exists()) await backup.delete();
    } on Object catch (error) {
      if (!await target.exists() && backedUp && await backup.exists()) {
        await backup.rename(target.path);
      }
      if (await temporary.exists()) await temporary.delete();
      if (error is GamePackageExportException) rethrow;
      throw GamePackageExportException(
        code: 'exportProfileWriteFailed',
        path: target.path,
        message: 'The export profile could not be written atomically.',
        cause: error,
      );
    }
  }
}
