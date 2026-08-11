import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';

void main(List<String> arguments) {
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
  if (arguments.isNotEmpty &&
      !(arguments.length == 2 && arguments.first == '--transport-receipts')) {
    stderr.writeln(
      'Usage: dart run tool/pmcp085_conformance.dart '
      '[--actions | --transport-receipts <path>]',
    );
    exitCode = 64;
    return;
  }
  AuthoringFullParityCatalog catalog;
  try {
    catalog = arguments.isEmpty
        ? AuthoringFullParityCatalog.canonical()
        : _catalogFromReceiptBundle(File(arguments[1]));
  } on Object catch (error) {
    stderr.writeln('Invalid transport receipt bundle: $error');
    exitCode = 65;
    return;
  }
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert(catalog.toJson()),
  );
  final summary = catalog.toJson()['summary']! as Map<String, Object?>;
  if (catalog.blockedOrMissingCells.isNotEmpty ||
      summary['itemTransportCertificationComplete'] != true) {
    exitCode = 1;
  }
}

AuthoringFullParityCatalog _catalogFromReceiptBundle(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
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
  return AuthoringFullParityCatalog.canonical(
    transportExecutionReceipts: <AuthoringTransportExecutionReceipt>[
      for (final raw in rawReceipts)
        if (raw is Map && raw.keys.every((key) => key is String))
          AuthoringTransportExecutionReceipt.fromJson(
            Map<String, dynamic>.from(raw),
          )
        else
          throw const FormatException('receipt must be a JSON object'),
    ],
    transportEvidenceRevision: bundle['evidenceRevision'] as String,
    transportFixtureDigest: bundle['fixtureDigest'] as String,
    transportSourceRevision: bundle['sourceRevision'] as String,
  );
}
