import 'dart:io';

import '../../ports/project_file_reader.dart';
import '../../ports/game_package_export_profile_api_port.dart';
import '../../workspace/workspace_policy.dart';
import 'game_package_export_profile_store.dart';

export '../../ports/game_package_export_profile_api_port.dart';

final class LocalGamePackageExportProfileApi
    implements GamePackageExportProfileApiPort {
  const LocalGamePackageExportProfileApi({required WorkspacePolicy policy})
      : _policy = policy;

  static Future<LocalGamePackageExportProfileApi> create(
          {required Iterable<String> allowedProjectRoots}) async =>
      LocalGamePackageExportProfileApi(
          policy: await WorkspacePolicy.create(
              allowedRootPaths: allowedProjectRoots,
              fileReader: const LocalProjectFileReader()));

  final WorkspacePolicy _policy;

  Future<GamePackageExportProfileStore> _store(String projectRoot) async =>
      GamePackageExportProfileStore(
          projectRoot:
              Directory(await _policy.authorizeProjectRoot(projectRoot)));

  @override
  Future<GamePackageExportProfileSnapshot> read(
          {required String projectRoot}) async =>
      (await _store(projectRoot)).read();

  @override
  Future<GamePackageExportProfileSnapshot> validate(
          {required String projectRoot,
          required GamePackageExportProfile profile}) async =>
      (await _store(projectRoot)).validate(profile);

  @override
  Future<GamePackageExportProfileSnapshot> save(
      {required String projectRoot,
      required GamePackageExportProfile profile,
      required String expectedProfileRevision,
      required String expectedContextRevision}) async {
    final store = await _store(projectRoot);
    return store.save(profile,
        expectedProfileRevision: expectedProfileRevision,
        expectedContextRevision: expectedContextRevision);
  }
}
