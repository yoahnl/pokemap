import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

typedef NarrativeSuiteRunner = Future<bool> Function(
  String suiteId,
  String testPath,
);

const _suitePaths = <String, String>{
  'selbrume-lighthouse-retry':
      'test/selbrume_lighthouse_retry_integration_test.dart',
  'selbrume-player-journey': 'test/selbrume_player_journey_e2e_test.dart',
};

Future<void> main(List<String> args) async {
  final parsed = _Arguments.parse(args);
  if (parsed == null) {
    stderr.writeln(
      'Usage: dart run tool/verify_narrative_project.dart '
      '--project-root <path> --profile selbrume-release-v1 --write-receipt',
    );
    exitCode = 64;
    return;
  }
  final profile = narrativeRuntimeSmokeProfileById(parsed.profileId);
  if (profile == null) {
    stderr.writeln('Unknown runtime smoke profile "${parsed.profileId}".');
    exitCode = 64;
    return;
  }
  final receipt = await verifyNarrativeProject(
    projectRoot: parsed.projectRoot,
    profile: profile,
    suiteRunner: _runFlutterSuite,
  );
  if (receipt == null) {
    stderr.writeln('Runtime smoke failed; the previous receipt is preserved.');
    exitCode = 1;
    return;
  }
  if (parsed.writeReceipt) {
    await writeNarrativeRuntimeSmokeReceiptAtomically(
      projectRoot: parsed.projectRoot,
      receipt: receipt,
    );
  }
  stdout.writeln(jsonEncode(receipt.toJson()));
}

Future<NarrativeRuntimeSmokeReceipt?> verifyNarrativeProject({
  required String projectRoot,
  required NarrativeRuntimeSmokeProfile profile,
  required NarrativeSuiteRunner suiteRunner,
  DateTime? completedAt,
}) async {
  final executed = <String>[];
  for (final suiteId in profile.requiredSuiteIds) {
    final testPath = _suitePaths[suiteId];
    if (testPath == null || !await suiteRunner(suiteId, testPath)) return null;
    executed.add(suiteId);
  }
  final fingerprint = await fingerprintNarrativeProjectDirectory(projectRoot);
  return NarrativeRuntimeSmokeReceipt(
    projectFingerprint: fingerprint,
    validatorVersion: 'narrative-validator-v1',
    profileId: profile.id,
    profileVersion: profile.version,
    suiteIds: executed,
    fixtureId: p.basename(p.normalize(p.absolute(projectRoot))),
    result: NarrativeRuntimeSmokeResult.pass,
    completedAt: completedAt ?? DateTime.now().toUtc(),
    limitations: const [
      'PARTIAL / NO-GO baseline: runtime smoke only; FG-185 is not promoted.',
    ],
  );
}

Future<String> fingerprintNarrativeProjectDirectory(String projectRoot) async {
  final root = Directory(p.normalize(p.absolute(projectRoot)));
  if (!await root.exists()) {
    throw FileSystemException('Project root does not exist.', root.path);
  }
  final entries = <NarrativeProjectFingerprintEntry>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = p.posix.normalize(
      p.relative(entity.path, from: root.path).replaceAll('\\', '/'),
    );
    if (_ignoredPath(relative)) continue;
    entries.add(
      NarrativeProjectFingerprintEntry(
        relativePath: relative,
        bytes: await entity.readAsBytes(),
      ),
    );
  }
  return computeNarrativeProjectFingerprint(entries);
}

Future<void> writeNarrativeRuntimeSmokeReceiptAtomically({
  required String projectRoot,
  required NarrativeRuntimeSmokeReceipt receipt,
  Future<void> Function(File temporaryFile)? beforeRename,
}) async {
  final destination = File(
    p.join(
      projectRoot,
      '.pokemap',
      'validation',
      'narrative_runtime_smoke_receipt.json',
    ),
  );
  await destination.parent.create(recursive: true);
  final temporary = File(
    '${destination.path}.${pid}_${DateTime.now().microsecondsSinceEpoch}.tmp',
  );
  try {
    final sink = temporary.openWrite();
    sink.write(const JsonEncoder.withIndent('  ').convert(receipt.toJson()));
    sink.write('\n');
    await sink.flush();
    await sink.close();
    if (beforeRename != null) await beforeRename(temporary);
    await temporary.rename(destination.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}

Future<bool> _runFlutterSuite(String suiteId, String testPath) async {
  final configured = Platform.environment['FLUTTER_BIN'];
  final homebrew = File('/opt/homebrew/bin/flutter');
  final executable =
      configured ?? (await homebrew.exists() ? homebrew.path : 'flutter');
  stdout.writeln('Running $suiteId ($testPath)…');
  final result = await Process.run(
    executable,
    ['test', '--reporter', 'compact', testPath],
    workingDirectory: Directory.current.path,
    runInShell: true,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  return result.exitCode == 0;
}

bool _ignoredPath(String relativePath) =>
    relativePath.startsWith('.pokemap/validation/') ||
    relativePath.endsWith('.tmp') ||
    relativePath == '.DS_Store';

final class _Arguments {
  const _Arguments({
    required this.projectRoot,
    required this.profileId,
    required this.writeReceipt,
  });

  final String projectRoot;
  final String profileId;
  final bool writeReceipt;

  static _Arguments? parse(List<String> args) {
    String? projectRoot;
    String? profileId;
    var writeReceipt = false;
    for (var index = 0; index < args.length; index++) {
      switch (args[index]) {
        case '--project-root':
          if (++index >= args.length) return null;
          projectRoot = args[index];
        case '--profile':
          if (++index >= args.length) return null;
          profileId = args[index];
        case '--write-receipt':
          writeReceipt = true;
        default:
          return null;
      }
    }
    if (projectRoot == null || profileId == null) return null;
    return _Arguments(
      projectRoot: projectRoot,
      profileId: profileId,
      writeReceipt: writeReceipt,
    );
  }
}
