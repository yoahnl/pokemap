import 'dart:convert';
import 'dart:io';

import 'package:map_player_ui/map_player_ui.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/features/session/domain/repositories/control_profile_repository_interface.dart';

/// Stores controls separately from general preferences so malformed remapping
/// data can fall back without invalidating accessibility or audio settings.
final class HubControlProfileStore
    implements ControlProfileRepositoryInterface {
  const HubControlProfileStore({required this.supportRoot});

  final Directory supportRoot;

  File get _file => File(p.join(supportRoot.path, 'control-profile.json'));

  @override
  Future<PlayerControlProfile> load() async {
    try {
      if (!await _file.exists()) return PlayerControlProfile.standard;
      final decoded = jsonDecode(await _file.readAsString());
      return PlayerControlProfile.fromJson(decoded);
    } on Object {
      return PlayerControlProfile.standard;
    }
  }

  @override
  Future<void> save(PlayerControlProfile profile) async {
    await supportRoot.create(recursive: true);
    final temporary = File('${_file.path}.tmp');
    try {
      await temporary.writeAsString(
        jsonEncode(profile.toJson()),
        flush: true,
      );
      PlayerControlProfile.fromJson(
        jsonDecode(await temporary.readAsString()),
      );
      await temporary.rename(_file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }
}
