import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test('writes a passing exact-HEAD CIN-008 receipt', () async {
    final fixture = await _createRepository();
    addTearDown(() => fixture.root.delete(recursive: true));
    final output = File(p.join(fixture.root.path, 'cin008.json'));

    final result = await _runCli(fixture, output);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final receipt =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(receipt['releaseCommit'], fixture.head);
    expect(receipt['treeState'], 'clean');
    expect(receipt['verdict'], 'passed');
    expect(receipt['blockingDependencies'], isEmpty);
    expect(receipt['blockingEvidence'], isEmpty);
  });

  test(
    'writes a failed receipt and exits one for incomplete evidence',
    () async {
      final fixture = await _createRepository(blocked: true);
      addTearDown(() => fixture.root.delete(recursive: true));
      final output = File(p.join(fixture.root.path, 'cin008.json'));

      final result = await _runCli(fixture, output);

      expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
      final receipt =
          jsonDecode(await output.readAsString()) as Map<String, Object?>;
      expect(receipt['verdict'], 'failed');
      expect(receipt['blockingDependencies'], <String>['BETA-CIN-038']);
      expect(receipt['blockingEvidence'], <String>['runtimePerformance']);
    },
  );

  test('rejects a dirty tree without writing a receipt', () async {
    final fixture = await _createRepository();
    addTearDown(() => fixture.root.delete(recursive: true));
    await File(p.join(fixture.root.path, 'tracked.txt')).writeAsString('dirty');
    final output = File(p.join(fixture.root.path, 'cin008.json'));

    final result = await _runCli(fixture, output);

    expect(result.exitCode, 2);
    expect(result.stderr, contains('clean tree'));
    expect(output.existsSync(), isFalse);
  });

  test('rejects a source commit outside the certified history', () async {
    final fixture = await _createRepository(forgedSourceCommit: true);
    addTearDown(() => fixture.root.delete(recursive: true));
    final output = File(p.join(fixture.root.path, 'cin008.json'));

    final result = await _runCli(fixture, output);

    expect(result.exitCode, 2);
    expect(output.existsSync(), isFalse);
  });
}

Future<ProcessResult> _runCli(_RepositoryFixture fixture, File output) =>
    Process.run('dart', <String>[
      'run',
      'bin/certify_cinematic_v2.dart',
      '--repository-root',
      fixture.root.path,
      '--evidence',
      fixture.evidence.path,
      '--output',
      output.path,
    ], workingDirectory: Directory.current.path);

Future<_RepositoryFixture> _createRepository({
  bool blocked = false,
  bool forgedSourceCommit = false,
}) async {
  final root = await Directory.systemTemp.createTemp('cin-008-cli-');
  await _git(root, const <String>['init', '-q']);
  await _git(root, const <String>['config', 'user.email', 'cin008@test']);
  await _git(root, const <String>['config', 'user.name', 'CIN-008']);
  await File(p.join(root.path, 'tracked.txt')).writeAsString('source\n');
  await _git(root, const <String>['add', 'tracked.txt']);
  await _git(root, const <String>['commit', '-q', '-m', 'source evidence']);
  final sourceCommit = await _git(root, const <String>['rev-parse', 'HEAD']);
  final resultSha256 = await _commitObjectSha256(root, sourceCommit);
  final evidence = File(p.join(root.path, 'cinematic_v2_evidence.json'));
  await evidence.writeAsString(
    jsonEncode(
      _input(
        sourceCommit: forgedSourceCommit ? 'f' * 40 : sourceCommit,
        resultSha256: resultSha256,
        blocked: blocked,
      ),
    ),
  );
  await _git(root, <String>['add', evidence.path]);
  await _git(root, const <String>['commit', '-q', '-m', 'final evidence']);
  return _RepositoryFixture(
    root: root,
    evidence: evidence,
    head: await _git(root, const <String>['rev-parse', 'HEAD']),
  );
}

Map<String, Object?> _input({
  required String sourceCommit,
  required String resultSha256,
  required bool blocked,
}) {
  final dependencies = <CinematicV2FinalDependency>[
    for (final ticket
        in CinematicV2FinalCertificationReceipt.requiredDependencyTickets)
      CinematicV2FinalDependency(
        ticket: ticket,
        workflowStatus: blocked && ticket == 'BETA-CIN-038'
            ? CinematicV2DependencyWorkflowStatus.toReview
            : CinematicV2DependencyWorkflowStatus.done,
        technicalVerdict: blocked && ticket == 'BETA-CIN-038'
            ? CinematicV2TechnicalVerdict.partial
            : CinematicV2TechnicalVerdict.pass,
        sourceCommit: sourceCommit,
      ),
  ];
  final evidence = <CinematicV2FinalEvidence>[
    for (final id in CinematicV2FinalEvidenceId.values)
      CinematicV2FinalEvidence(
        id: id,
        sourceTicket: CinematicV2FinalCertificationReceipt.expectedSourceTicket(
          id,
        ),
        sourceCommit: sourceCommit,
        status: blocked && id == CinematicV2FinalEvidenceId.runtimePerformance
            ? CinematicV2FinalEvidenceStatus.blocked
            : CinematicV2FinalEvidenceStatus.passed,
        summary: '${id.name} evidence.',
        command: blocked && id == CinematicV2FinalEvidenceId.runtimePerformance
            ? null
            : 'flutter test test/${id.name}.dart',
        resultSha256:
            blocked && id == CinematicV2FinalEvidenceId.runtimePerformance
            ? null
            : resultSha256,
        limitations:
            blocked && id == CinematicV2FinalEvidenceId.runtimePerformance
            ? const <String>['exact-sha-device-receipt-pending']
            : const <String>[],
      ),
  ];
  return <String, Object?>{
    'schemaVersion': 1,
    'dependencies': dependencies.map((entry) => entry.toJson()).toList(),
    'evidence': evidence.map((entry) => entry.toJson()).toList(),
  };
}

Future<String> _commitObjectSha256(Directory root, String commit) async {
  final result = await Process.run('git', <String>[
    '-C',
    root.path,
    'cat-file',
    'commit',
    commit,
  ], stdoutEncoding: null);
  if (result.exitCode != 0) {
    throw StateError(result.stderr.toString());
  }
  return sha256.convert(result.stdout! as List<int>).toString();
}

Future<String> _git(Directory root, List<String> arguments) async {
  final result = await Process.run('git', <String>[
    '-C',
    root.path,
    ...arguments,
  ]);
  if (result.exitCode != 0) {
    throw StateError('${result.stdout}\n${result.stderr}');
  }
  return result.stdout.toString().trim();
}

final class _RepositoryFixture {
  const _RepositoryFixture({
    required this.root,
    required this.evidence,
    required this.head,
  });

  final Directory root;
  final File evidence;
  final String head;
}
