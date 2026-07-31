import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';

void main(List<String> arguments) {
  if (arguments.length > 1 ||
      (arguments.isNotEmpty && arguments.single != '--actions')) {
    stderr.writeln('Usage: dart run tool/pmcp085_conformance.dart [--actions]');
    exitCode = 64;
    return;
  }
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
  final catalog = AuthoringFullParityCatalog.canonical();
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert(catalog.toJson()),
  );
  if (catalog.blockedOrMissingCells.isNotEmpty) exitCode = 1;
}
