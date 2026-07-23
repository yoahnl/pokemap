import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/project_tree_digest.dart';

const _journeySource = 'test/selbrume_player_journey_e2e_test.dart';
const _journeyTestName =
    'player completes Selbrume through PlayableMapGame production hooks';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    final verifier = SelbrumeMvpJourneyVerifier(
      hostRoot: Directory.current,
      projectRoot: Directory(options.projectRoot),
    );
    final receipt = await verifier.verify();
    await _writeAtomically(
      File(options.outputPath),
      const JsonEncoder.withIndent('  ').convert(receipt.toJson()),
    );
    stdout.writeln(jsonEncode(receipt.toJson()));
    if (!receipt.isSuccessful) exitCode = 1;
  } on Object catch (error, stackTrace) {
    stderr
      ..writeln('Selbrume MVP journey verification failed: $error')
      ..writeln(stackTrace);
    exitCode = 2;
  }
}

final class SelbrumeMvpJourneyVerifier {
  const SelbrumeMvpJourneyVerifier({
    required this.hostRoot,
    required this.projectRoot,
    this.projectTreeDigest = const ProjectTreeDigest(),
  });

  final Directory hostRoot;
  final Directory projectRoot;
  final ProjectTreeDigest projectTreeDigest;

  Future<MvpReleaseEvidenceReceipt> verify() async {
    final projectFile = File(p.join(projectRoot.path, 'project.json'));
    if (!await projectFile.exists()) {
      throw ArgumentError.value(
        projectRoot.path,
        'projectRoot',
        'does not contain project.json',
      );
    }
    final commandArguments = <String>[
      'test',
      _journeySource,
      '--plain-name',
      _journeyTestName,
      '-r',
      'compact',
    ];
    final command = 'flutter ${commandArguments.map(_shellWord).join(' ')}';
    final process = await Process.start(
      'flutter',
      commandArguments,
      workingDirectory: hostRoot.path,
      runInShell: false,
    );
    await Future.wait<void>(<Future<void>>[
      stdout.addStream(process.stdout),
      stderr.addStream(process.stderr),
    ]);
    final processExitCode = await process.exitCode;
    final repositoryRoot = Directory(
      p.normalize(p.join(hostRoot.path, '..', '..')),
    );
    final commitResult = await Process.run(
      'git',
      const <String>['rev-parse', 'HEAD'],
      workingDirectory: repositoryRoot.path,
    );
    if (commitResult.exitCode != 0) {
      throw StateError('Unable to resolve release candidate commit.');
    }
    final commit = (commitResult.stdout as String).trim();
    final treeHash = await projectTreeDigest.compute(projectRoot);
    final status = processExitCode == 0
        ? MvpProductCriterionStatus.passed
        : MvpProductCriterionStatus.failed;
    return MvpReleaseEvidenceReceipt.validated(
      command: command,
      exitCode: processExitCode,
      releaseCandidateCommit: commit,
      capturedAtUtc: DateTime.now().toUtc(),
      source: _journeySource,
      projectTreeHashSha256: treeHash,
      criteria: <MvpProductCriterionEvidence>[
        for (final criterion in MvpProductCriterion.values)
          MvpProductCriterionEvidence(
            criterion: criterion,
            status: status,
            summary: _executedProofFor(criterion, processExitCode),
            source: '$_journeySource#${criterion.id}',
          ),
      ],
    );
  }
}

String _executedProofFor(MvpProductCriterion criterion, int commandExitCode) {
  final outcome = commandExitCode == 0 ? 'observé' : 'non prouvé';
  return switch (criterion) {
    MvpProductCriterion.mvp01NewGame =>
      'New Game et spawn initial $outcome par PlayableMapGame.',
    MvpProductCriterion.mvp02Starter =>
      'Choix du starter auprès de Maël $outcome.',
    MvpProductCriterion.mvp03ConnectedExploration =>
      'Transitions physiques entre les maps Selbrume $outcome.',
    MvpProductCriterion.mvp04NpcDialogue =>
      'Interactions PNJ et dialogues Yarn $outcome.',
    MvpProductCriterion.mvp05ConditionalDialogue =>
      'Branches de dialogue liées à la progression $outcome.',
    MvpProductCriterion.mvp06Cutscene =>
      'Scenes et séquences narratives du phare $outcome.',
    MvpProductCriterion.mvp07WildEncounter =>
      'Rencontres sauvages issues des zones authorées $outcome.',
    MvpProductCriterion.mvp08Capture =>
      'Captures via le battle overlay et consommation de Balls $outcome.',
    MvpProductCriterion.mvp09PcOverflow =>
      'Capture avec party pleine puis destination Box $outcome.',
    MvpProductCriterion.mvp10TrainerBattle =>
      'Défaite, reprise et victoire contre Lysa $outcome.',
    MvpProductCriterion.mvp11ExperienceAndMoney =>
      'Récompenses de combat et économie du shop $outcome.',
    MvpProductCriterion.mvp12LevelUp =>
      'Progression de niveau produite par les combats $outcome.',
    MvpProductCriterion.mvp13MoveLearning =>
      'Carapuce apprend Morsure dans la file post-combat réelle $outcome.',
    MvpProductCriterion.mvp14BadgeOrFlag =>
      'Badge des Brisants et faits narratifs $outcome.',
    MvpProductCriterion.mvp15FieldAbility =>
      'Refus puis traversée effective du gate Surf $outcome.',
    MvpProductCriterion.mvp16Shop =>
      'Catalogue et achat avant Lysa, catalogue et prix modifiés après Lysa, '
          'comptoir fermé pendant l’alerte du phare, achat dans l’état final '
          'et stock après sauvegarde et chargement $outcome.',
    MvpProductCriterion.mvp17HealCenter =>
      'Soin de la party depuis la source physique du Port $outcome.',
    MvpProductCriterion.mvp18SaveLoad =>
      'Sauvegarde, reload et reprise de progression $outcome.',
    MvpProductCriterion.mvp19StoryEnd =>
      'Phare terminé puis épilogue du Port atteint $outcome.',
  };
}

String _shellWord(String value) =>
    RegExp(r'^[A-Za-z0-9_./:-]+$').hasMatch(value)
        ? value
        : "'${value.replaceAll("'", "'\\''")}'";

Future<void> _writeAtomically(File target, String content) async {
  await target.parent.create(recursive: true);
  final temporary = File('${target.path}.tmp');
  await temporary.writeAsString('$content\n', flush: true);
  if (await target.exists()) await target.delete();
  await temporary.rename(target.path);
}

final class _Options {
  const _Options({required this.projectRoot, required this.outputPath});

  final String projectRoot;
  final String outputPath;

  static _Options parse(List<String> arguments) {
    var projectRoot = p.normalize(p.join('..', '..', 'selbrume'));
    var outputPath = p.join(
      'build',
      'mvp-release',
      'selbrume-journey-receipt.json',
    );
    for (var index = 0; index < arguments.length; index += 1) {
      final argument = arguments[index];
      if (argument == '--project-root' && index + 1 < arguments.length) {
        projectRoot = arguments[++index];
      } else if (argument == '--output' && index + 1 < arguments.length) {
        outputPath = arguments[++index];
      } else {
        throw ArgumentError('Unknown or incomplete argument: $argument');
      }
    }
    return _Options(
      projectRoot: p.normalize(p.absolute(projectRoot)),
      outputPath: p.normalize(p.absolute(outputPath)),
    );
  }
}
