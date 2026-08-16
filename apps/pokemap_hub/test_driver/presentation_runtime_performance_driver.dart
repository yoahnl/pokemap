import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) {
        throw const FormatException('CIN-038 performance response is missing.');
      }
      final requestedOutput = data['requestedOutputPath'];
      if (requestedOutput is! String || requestedOutput.trim().isEmpty) {
        throw const FormatException('POKEMAP_CIN038_OUTPUT is required.');
      }
      final output = validatePresentationRuntimePerformanceOutput(
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

File validatePresentationRuntimePerformanceOutput(String relativePath) {
  final packageRoot = Directory(Directory.current.resolveSymbolicLinksSync());
  if (p.isAbsolute(relativePath)) {
    throw const FormatException(
      'POKEMAP_CIN038_OUTPUT must stay inside apps/pokemap_hub.',
    );
  }
  final output =
      File(p.normalize(p.join(packageRoot.path, relativePath))).absolute;
  if (!p.isWithin(packageRoot.path, output.path)) {
    throw const FormatException(
      'POKEMAP_CIN038_OUTPUT must stay inside apps/pokemap_hub.',
    );
  }
  return output;
}
