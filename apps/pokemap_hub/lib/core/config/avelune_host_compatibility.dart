import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';

GamePackageHostCompatibility aveluneHostCompatibility() =>
    GamePackageHostCompatibility(
      hubVersion: Version.parse('0.1.0'),
      runtimeApiVersion: Version.parse('1.4.0'),
      capabilities: const <String>{
        'dialogue.choices@1',
        'map@1',
        'overworld.menu@1',
        'world.shop@1',
      },
      supportedProjectFormats: <String>{ProjectVersion.v7.name},
      currentProjectFormat: ProjectVersion.v7.name,
      supportedSaveFormats: const <int>{1},
    );
