import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/transport_certification.dart';

Future<void> main(List<String> arguments) async {
  if (arguments case ['--actions']) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert([
        for (final descriptor
            in AuthoringMutationDispatcher.canonical().descriptors)
          {
            'id': descriptor.id,
            'resourceKinds': descriptor.resourceKinds,
          },
      ]),
    );
    return;
  }
  late final _Options options;
  try {
    options = _Options.parse(arguments);
  } on FormatException {
    stderr.writeln(
      'Usage: dart run tool/pmcp085_conformance.dart '
      '[--actions | [--transport-receipts <path>] [--require-transports] '
      '[--source-revision <git-id>] [--dart <executable>] '
      '[--transport-run <bundle> <recipes> <fixtures>]...]',
    );
    exitCode = 64;
    return;
  }
  AuthoringFullParityCatalog catalog;
  try {
    final item = _readItemReceiptBundle(options.itemReceiptPath);
    final runs = <VerifiedAuthoringTransportEvidence>[
      for (final run in options.runs)
        await _verifyRun(run, options.sourceRevision!, options.dart ?? 'dart'),
    ];
    catalog = AuthoringFullParityCatalog.canonical(
      transportExecutionReceipts: item.receipts,
      transportEvidenceRevision: item.evidenceRevision,
      transportFixtureDigest: item.fixtureDigest,
      transportSourceRevision: item.sourceRevision,
      verifiedTransportRuns: runs,
    );
  } on Object catch (error) {
    stderr.writeln('Invalid transport receipt bundle: $error');
    exitCode = 65;
    return;
  }
  final output = catalog.toJson();
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(output));
  final summary = output['summary']! as Map<String, Object?>;
  if (catalog.blockedOrMissingCells.isNotEmpty ||
      summary['itemTransportCertificationComplete'] != true ||
      (options.requireTransports &&
          summary['transportCertificationComplete'] != true)) {
    if (options.requireTransports) {
      stderr.writeln(
        'PMCP-085: '
        '${summary['fullyEndToEndVerifiedMutationActionCount']}/'
        '${summary['mutationActionCount']} actions verified on every transport.',
      );
    }
    exitCode = 1;
  }
}

Future<VerifiedAuthoringTransportEvidence> _verifyRun(
  _Run input,
  String sourceRevision,
  String dart,
) async {
  final recipes = jsonDecode(await File(input.recipes).readAsString());
  final expected = await AuthoringTransportEvidenceInputs.capture(
    repository: Directory.fromUri(Platform.script.resolve('../../../')),
    fixtures: Directory(input.fixtures),
    sourceRevision: sourceRevision,
    scenarios: AuthoringTransportScenario.parse(recipes),
    dart: dart,
  );
  return VerifiedAuthoringTransportEvidence.verify(
    jsonDecode(await File(input.bundle).readAsString()),
    recipes: recipes,
    expected: expected,
  );
}

typedef _Run = ({String bundle, String recipes, String fixtures});

final class _Options {
  String? itemReceiptPath;
  String? sourceRevision;
  String? dart;
  bool requireTransports = false;
  final runs = <_Run>[];

  static _Options parse(List<String> arguments) {
    final options = _Options();
    var index = 0;
    String value() {
      if (index >= arguments.length ||
          arguments[index].startsWith('--') ||
          arguments[index].isEmpty) {
        throw const FormatException('An option is missing its value.');
      }
      return arguments[index++];
    }

    while (index < arguments.length) {
      switch (arguments[index++]) {
        case '--transport-receipts' when options.itemReceiptPath == null:
          options.itemReceiptPath = value();
        case '--source-revision' when options.sourceRevision == null:
          options.sourceRevision = value();
        case '--dart' when options.dart == null:
          options.dart = value();
        case '--require-transports' when !options.requireTransports:
          options.requireTransports = true;
        case '--transport-run':
          options.runs
              .add((bundle: value(), recipes: value(), fixtures: value()));
        default:
          throw const FormatException('Unknown or repeated option.');
      }
    }
    if (options.runs.isNotEmpty && options.sourceRevision == null) {
      throw const FormatException('Transport runs require a source revision.');
    }
    return options;
  }
}

({
  List<AuthoringTransportExecutionReceipt> receipts,
  String? sourceRevision,
  String? evidenceRevision,
  String? fixtureDigest,
}) _readItemReceiptBundle(String? path) {
  if (path == null) {
    return (
      receipts: const [],
      sourceRevision: null,
      evidenceRevision: null,
      fixtureDigest: null,
    );
  }
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
    throw const FormatException('bundle must be a JSON object');
  }
  final bundle = Map<String, dynamic>.from(decoded);
  const fields = <String>{
    'sourceRevision',
    'evidenceRevision',
    'fixtureDigest',
    'receipts',
  };
  if (bundle.keys.toSet().difference(fields).isNotEmpty ||
      !bundle.keys.toSet().containsAll(fields)) {
    throw const FormatException('bundle fields are invalid');
  }
  final rawReceipts = bundle['receipts'];
  if (rawReceipts is! List) {
    throw const FormatException('receipts must be a JSON list');
  }
  return (
    receipts: <AuthoringTransportExecutionReceipt>[
      for (final raw in rawReceipts)
        if (raw is Map && raw.keys.every((key) => key is String))
          AuthoringTransportExecutionReceipt.fromJson(
            Map<String, dynamic>.from(raw),
          )
        else
          throw const FormatException('receipt must be a JSON object'),
    ],
    evidenceRevision: bundle['evidenceRevision'] as String,
    fixtureDigest: bundle['fixtureDigest'] as String,
    sourceRevision: bundle['sourceRevision'] as String,
  );
}
