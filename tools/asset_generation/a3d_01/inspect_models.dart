import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    stderr.writeln('Expected one or more GLB paths.');
    exitCode = 64;
    return;
  }
  final results = <Map<String, dynamic>>[];
  for (final path in arguments) {
    final bytes = File(path).readAsBytesSync();
    try {
      final inspection = const GlbModel3dInspector(
        maxTextureDimension: 512,
        requireStaticTextures: true,
      ).inspect(bytes);
      results.add({
        'path': File(path).absolute.path,
        'byteLength': bytes.length,
        'sha256': sha256.convert(bytes).toString(),
        'inspection': inspection.toJson(),
      });
    } on FormatException catch (error) {
      results.add({'path': path, 'error': error.message});
      exitCode = 1;
    }
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(results));
}
