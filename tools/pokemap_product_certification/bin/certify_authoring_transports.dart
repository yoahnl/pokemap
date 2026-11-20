import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/transport_certification.dart';
import 'package:path/path.dart' as p;

import '../lib/src/transport_certification_catalog_fixture.dart';
import '../lib/src/transport_certification_session.dart';

Future<void> main(List<String> arguments) async {
  final catalogFixtures = TransportCatalogFixturePreparation();
  try {
    await _run(
      arguments,
      catalogFixtures,
    ).whenComplete(catalogFixtures.removeAdmissions);
  } on Object catch (error) {
    stderr.writeln('Authoring transport certification failed: $error');
    exitCode = 1;
  }
}

Future<void> _run(
  List<String> arguments,
  TransportCatalogFixturePreparation catalogFixtures,
) async {
  final options = _parseArguments(arguments);
  final repository = Directory(
    options['--repository'] ?? Directory.current.parent.parent.path,
  );
  final recipes = jsonDecode(await File(options['--recipes']!).readAsString());
  final scenarios = AuthoringTransportScenario.parse(recipes);
  final fixtures = Directory(options['--fixtures']!);
  final qaRoot = Directory(
    await Directory(options['--qa-root']!).resolveSymbolicLinks(),
  );
  final output = File(p.absolute(options['--out']!));
  final outputParent = await output.parent.resolveSymbolicLinks();
  if (!p.isWithin(qaRoot.path, output.path) ||
      outputParent != output.parent.path ||
      await FileSystemEntity.type(output.path, followLinks: false) !=
          FileSystemEntityType.notFound) {
    throw const FormatException(
      'The output must be a new file in the QA root.',
    );
  }
  final dart = options['--dart'] ?? 'dart';
  Future<AuthoringTransportEvidenceInputs> capture() =>
      AuthoringTransportEvidenceInputs.capture(
        repository: repository,
        fixtures: fixtures,
        sourceRevision: options['--source-revision']!,
        scenarios: scenarios,
        dart: dart,
      );
  final inputs = await capture();
  final recipeDigest = transportEvidenceDigest(recipes);
  final rows = <Map<String, Object?>>[];
  final versions = {
    for (final action in AuthoringMutationDispatcher.canonical().descriptors)
      action.id: action.version,
  };

  for (final scenario in scenarios) {
    try {
      for (final step in scenario.steps) {
        if (versions[step.actionId] != step.actionVersion) {
          throw FormatException('Undiscovered action: ${step.actionId}.');
        }
      }
      final source = await resolveAuthoringFixture(fixtures, scenario);
      if (p.isWithin(source.path, qaRoot.path) ||
          p.equals(source.path, qaRoot.path)) {
        throw const FormatException('The QA root must be outside the fixture.');
      }
      final trial = await qaRoot.createTemp('${scenario.id}-');
      try {
        final executions = await Future.wait([
          for (final transport in AuthoringTransport.values)
            _trial(
              transport,
              scenario,
              inputs,
              recipeDigest,
              source,
              trial,
              catalogFixtures,
              repository,
              dart,
            ),
        ]);
        final matchedSteps = executions
            .map((execution) => execution.rows.length)
            .reduce((left, right) => left < right ? left : right);
        for (final execution in executions) {
          if (execution.failure case final failure?) {
            stderr.writeln('${scenario.id}: $failure');
            exitCode = 1;
          }
        }
        if (matchedSteps == 0) continue;
        final observed = [
          for (final execution in executions)
            ...execution.rows.take(matchedSteps),
        ];
        VerifiedAuthoringTransportEvidence.verify(
          buildAuthoringTransportEvidenceBundle(
            recipes: recipes,
            inputs: inputs,
            results: observed,
          ),
          recipes: recipes,
          expected: inputs,
        );
        rows.addAll(observed);
        stderr.writeln(
          '${scenario.id}: ${observed.length} verified executions.',
        );
      } finally {
        await trial.delete(recursive: true);
      }
    } on Object catch (error) {
      stderr.writeln('${scenario.id}: $error');
      exitCode = 1;
    }
  }

  if (rows.isEmpty) {
    throw StateError('No cross-transport evidence was produced.');
  }
  final after = await capture();
  final bundle = buildAuthoringTransportEvidenceBundle(
    recipes: recipes,
    inputs: inputs,
    results: rows,
  );
  final verified = VerifiedAuthoringTransportEvidence.verify(
    bundle,
    recipes: recipes,
    expected: after,
  );
  await output.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(bundle)}\n',
  );
  stdout.writeln(
    jsonEncode({
      'verifiedActions': verified.receipts
          .map((receipt) => receipt.actionId)
          .toSet()
          .length,
      'verifiedReceipts': verified.receipts.length,
      'bundle': output.path,
    }),
  );
}

Future<({List<Map<String, Object?>> rows, String? failure})> _trial(
  AuthoringTransport transport,
  AuthoringTransportScenario scenario,
  AuthoringTransportEvidenceInputs inputs,
  String recipeDigest,
  Directory source,
  Directory trial,
  TransportCatalogFixturePreparation catalogFixtures,
  Directory repository,
  String dart,
) async {
  final rows = <Map<String, Object?>>[];
  try {
    final project = Directory(p.join(trial.path, transport.name));
    await copyAuthoringFixture(source, project);
    if (await authoringFixtureDigest(project) !=
        inputs.fixtureDigests[scenario.id]) {
      throw const FormatException(
        'The copied fixture differs from the input digest.',
      );
    }
    if (scenario.catalogPreparation case final scopes?) {
      await catalogFixtures.prepare(project, trial, scopes);
    }
    final measuresPreviews = scenario.steps.any((step) => step.planOnly);
    if (measuresPreviews) {
      final gateway = await LocalTransactionFileGateway.open(
        projectRoot: project.path,
        expectedProjectRoot: project.path,
      );
      await gateway.withExclusiveWriteLock<void>(() async {});
    }
    final session = await openTransportCertificationSession(
      transport,
      project,
      repository,
      dart,
      measurePlanPreimage: measuresPreviews,
    );
    try {
      for (final (index, step) in scenario.steps.indexed) {
        try {
          final before = await step.observe(project);
          final beforeProjectDigest = step.planOnly
              ? await authoringFixtureDigest(project)
              : null;
          final applied = await session.apply(
            step,
            authoringTransportProofIdentity(
              scenario.id,
              index,
              transport,
              inputs: inputs,
              recipeDigest: recipeDigest,
            ),
          );
          final after = await step.observe(project);
          final afterProjectDigest = step.planOnly
              ? await authoringFixtureDigest(project)
              : null;
          if (beforeProjectDigest != afterProjectDigest) {
            throw const FormatException('Planning changed the project files.');
          }
          step.verify(before, after);
          rows.add({
            'scenario': scenario.id,
            'step': index,
            'transport': transport.name,
            'before': before,
            'after': after,
            'receipt': applied.receipt.toJson(),
            if (step.planOnly) ...{
              'beforeProjectDigest': beforeProjectDigest,
              'afterProjectDigest': afterProjectDigest,
            },
            if (applied.stagedArtifacts.isNotEmpty)
              'stagedArtifacts': [
                for (final artifact in applied.stagedArtifacts)
                  artifact.toJson(),
              ],
          });
        } on Object catch (error) {
          return (
            rows: rows,
            failure: '${transport.name}/${step.actionId}: $error',
          );
        }
      }
    } finally {
      await session.close();
    }
    return (rows: rows, failure: null);
  } on Object catch (error) {
    return (
      rows: const <Map<String, Object?>>[],
      failure: '${transport.name}: $error',
    );
  }
}

Map<String, String> _parseArguments(List<String> arguments) {
  const required = {
    '--recipes',
    '--fixtures',
    '--qa-root',
    '--source-revision',
    '--out',
  };
  const allowed = {...required, '--repository', '--dart'};
  final options = <String, String>{};
  if (arguments.length.isEven) {
    for (var index = 0; index < arguments.length; index += 2) {
      if (!allowed.contains(arguments[index]) ||
          options.containsKey(arguments[index])) {
        break;
      }
      options[arguments[index]] = arguments[index + 1];
    }
    if (options.length * 2 == arguments.length &&
        options.keys.toSet().containsAll(required)) {
      return options;
    }
  }
  throw const FormatException(
    'Usage: certify_authoring_transports.dart --recipes <file> '
    '--fixtures <dir> --qa-root <dir> --source-revision <git-id> '
    '--out <file> [--repository <dir>] [--dart <executable>]',
  );
}
