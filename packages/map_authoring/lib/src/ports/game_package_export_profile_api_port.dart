import '../domains/distribution/game_package_export_profile.dart';

export '../domains/distribution/game_package_export_profile.dart'
    show GamePackageExportProfile, GamePackageExportException;

final class GamePackageExportProfileSnapshot {
  const GamePackageExportProfileSnapshot(
      {required this.profile,
      required this.profileRevision,
      required this.contextRevision});

  final GamePackageExportProfile? profile;
  final String profileRevision;
  final String contextRevision;

  Map<String, Object?> toJson() => {
        'profile': profile?.toJson(),
        'profileRevision': profileRevision,
        'contextRevision': contextRevision,
        'contextGuarantee':
            'freshPreimageCheckBeforeProfileRename;notMultiFileAtomic',
        'contextScope':
            'project.json, enabled new-game start map, declared profile assets',
      };
}

abstract interface class GamePackageExportProfileApiPort {
  Future<GamePackageExportProfileSnapshot> read({required String projectRoot});
  Future<GamePackageExportProfileSnapshot> validate(
      {required String projectRoot, required GamePackageExportProfile profile});
  Future<GamePackageExportProfileSnapshot> save(
      {required String projectRoot,
      required GamePackageExportProfile profile,
      required String expectedProfileRevision,
      required String expectedContextRevision});
}
