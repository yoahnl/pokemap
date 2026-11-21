import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../domain/repositories/package_asset_port.dart';

final class InstalledGen5BattleSourceLoader {
  InstalledGen5BattleSourceLoader({
    required GamePackageManifest manifest,
    required this.assets,
  }) : _files = Map.unmodifiable({
         for (final file in manifest.content.files)
           if (file.path.startsWith(
             'project/data/pokemon/gen5_battle_sources/',
           ))
             file.path: file,
       });

  final PackageAssetPort assets;
  final Map<String, GamePackageFileEntry> _files;

  Future<Gen5BattleSourceBundle?> load({
    required String projectSpeciesId,
    required int projectNationalDex,
    bool Function()? isCurrent,
  }) {
    final bindingPath = Gen5BattleSourceBinding.bindingPathFor(
      projectSpeciesId,
    );
    return loadRuntimeGen5BattleSource(
      openAsset: _open,
      projectSpeciesId: projectSpeciesId,
      projectNationalDex: projectNationalDex,
      expectedBindingSha256: _files['project/$bindingPath']?.sha256,
      isCurrent: isCurrent,
    );
  }

  Future<Stream<List<int>>?> _open(String projectRelativePath) async {
    final path = 'project/$projectRelativePath';
    if (!_files.containsKey(path)) return null;
    final file = await assets.resolveFile(path);
    return file.openRead();
  }
}
