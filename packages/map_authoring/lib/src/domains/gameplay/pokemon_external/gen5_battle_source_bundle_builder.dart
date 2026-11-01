import 'package:map_core/map_core.dart';

import 'avelune_gen5_battle_source.dart';

Gen5BattleSourceBundle gen5BattleSourceBundleFromSnapshot(
  AveluneGen5BattleSourceSnapshot snapshot,
) =>
    Gen5BattleSourceBundle(
      species: snapshot.species,
      nationalDex: snapshot.nationalDex,
      release: snapshot.release,
      sourceRepository: snapshot.sourceRepository,
      sourceRevision: snapshot.sourceRevision,
      sourceDirectory: snapshot.sourceDirectory,
      reconstruction: snapshot.reconstruction,
      redistributionStatus: snapshot.redistributionStatus,
      assets: snapshot.assets,
    );
