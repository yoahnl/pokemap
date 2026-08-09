import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/pokemap_hub.dart';

import '../support/game_package_fixture.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) {
    stderr.writeln(
      'usage: atomic_install_crash_writer <support-root> <package> <stage>',
    );
    exitCode = 64;
    return;
  }
  final supportRoot = Directory(arguments[0]);
  final package = File(arguments[1]);
  final stage = GameInstallFaultStage.values.byName(arguments[2]);
  final installer = GamePackageInstaller(
    supportRoot: supportRoot,
    inspector: GamePackageInspector(
      hostCompatibility: testHostCompatibility(),
    ),
    availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
    loadSmoke: (_, _) async {},
    prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
    faultHook: (current) async {
      if (current == stage) {
        exit(86);
      }
    },
  );
  await installer.install(
    package,
    source: GamePackageInstallSource.localFile,
  );
}
