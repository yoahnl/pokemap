import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';
import 'package:path/path.dart' as p;

/// BETA-CIN-084 — writes the journey's measurements where the CLI can certify
/// them.
///
/// Same shape as the CIN-038 driver next to it, for the same reason: the journey
/// runs inside the app and cannot write outside it, so the measurements travel
/// back through `reportData` and land here. A killed run must not leave a
/// partial file that later reads as evidence, hence the temporary-then-rename.
Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) {
        throw const FormatException('CIN-084 hold response is missing.');
      }
      final requestedOutput = data['requestedOutputPath'];
      if (requestedOutput is! String || requestedOutput.trim().isEmpty) {
        throw const FormatException('POKEMAP_CIN084_OUTPUT is required.');
      }
      final output = validatePresentationHoldPerformanceOutput(
        requestedOutput,
      );
      final measurements = Map<String, Object?>.from(data)
        ..remove('requestedOutputPath');
      await output.parent.create(recursive: true);
      final temporary = File('${output.path}.tmp-$pid');
      await temporary.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(measurements)}\n',
        flush: true,
      );
      if (await output.exists()) await output.delete();
      await temporary.rename(output.path);
      stdout.writeln(jsonEncode(measurements));
    },
  );
}

File validatePresentationHoldPerformanceOutput(String relativePath) {
  final packageRoot = Directory(Directory.current.resolveSymbolicLinksSync());
  if (p.isAbsolute(relativePath)) {
    throw const FormatException(
      'POKEMAP_CIN084_OUTPUT must stay inside apps/pokemap_hub.',
    );
  }
  final output =
      File(p.normalize(p.join(packageRoot.path, relativePath))).absolute;
  if (!p.isWithin(packageRoot.path, output.path)) {
    throw const FormatException(
      'POKEMAP_CIN084_OUTPUT must stay inside apps/pokemap_hub.',
    );
  }
  return output;
}
