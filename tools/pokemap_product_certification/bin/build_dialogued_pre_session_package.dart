import 'dart:io';

import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

/// Builds the installable BETA-CIN-083 fixture package for BETA-CIN-085.
///
/// CIN-085 has to certify the journey "on the real Hub", and what the Hub plays
/// is an installed copy. So the fixture has to leave the test suite and become
/// a file: this authors it through the canonical action sequence, exports it,
/// and prints the hashes the receipt will have to match.
///
/// It writes nothing into the Hub. `library.json` is owned by the Hub app, not
/// by GamePackageInstaller, so an install performed from a script would leave
/// the library index pointing at the previous version — the package is handed
/// over and the Hub installs it.
Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help')) {
    stdout.writeln(
      'Usage: flutter test --plain-name build '
      'test/build_dialogued_pre_session_package_test.dart\n'
      'or: dart run bin/build_dialogued_pre_session_package.dart '
      '--output <path.avelunegame>',
    );
    return;
  }
  final outputIndex = arguments.indexOf('--output');
  if (outputIndex < 0 || outputIndex + 1 >= arguments.length) {
    stderr.writeln('Missing --output <path.avelunegame>');
    exitCode = 2;
    return;
  }
  final output = File(p.absolute(arguments[outputIndex + 1]));
  final artifact = await buildDialoguedPreSessionPackage(outputFile: output);
  stdout.writeln('certified=${artifact.certification.isCertified}');
  stdout.writeln('gameId=${artifact.manifest.gameId}');
  stdout.writeln('gameVersion=${artifact.manifest.gameVersion}');
  stdout.writeln('treeSha256=${artifact.manifest.content.treeSha256}');
  stdout.writeln('packageSha256=${artifact.packageSha256}');
  stdout.writeln('path=${output.path}');
  if (!artifact.certification.isCertified) exitCode = 1;
}

/// Authors the fixture and exports it, in one place, so the package the Hub
/// installs and the project the parity suite compares are built from the same
/// declared action sequence rather than from two similar-looking scripts.
Future<GamePackageExportArtifact> buildDialoguedPreSessionPackage({
  required File outputFile,
  Directory? workRoot,
}) async {
  final root = workRoot ??
      await Directory.systemTemp.createTemp('cin085-fixture-package-');
  final run = await const DialoguedPreSessionTransportParity().run(
    DialoguedPreSessionTransport.directApi,
    workRoot: root,
  );
  if (run.appliedActionIds.length !=
      const DialoguedPreSessionFixture().steps.length) {
    throw StateError(
      'The fixture did not apply its whole sequence: '
      '${run.appliedActionIds.length} of '
      '${const DialoguedPreSessionFixture().steps.length}.',
    );
  }
  final projectRoot = Directory(
    p.join(root.path, DialoguedPreSessionTransport.directApi.wireName),
  );
  await outputFile.parent.create(recursive: true);
  return const GamePackageExportService().exportToFile(
    projectRoot: projectRoot,
    profile: const NeutralCertificationGameFixture(
      dialoguedPreSession: true,
    ).exportProfile,
    outputFile: outputFile,
  );
}
