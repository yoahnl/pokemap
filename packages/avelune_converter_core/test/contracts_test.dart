import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

Map<String, Object?> fixture(String name) =>
    (jsonDecode(File('test/fixtures/$name.example.json').readAsStringSync())
            as Map)
        .cast<String, Object?>();

void main() {
  for (final name in [
    'source_map_ir',
    'asset_candidate',
    'review_decisions',
    'vision_response',
    'target_capabilities',
    'conversion_plan',
    'conversion_report',
  ]) {
    test('IR-01 $name preserves the supplied envelope', () {
      final input = fixture(name);
      final result = decodeContract(input);
      expect(result, isNotNull);
      expect((result as dynamic).toJson(), equals(input));
    });
    test('IR-01 $name rejects unknown root properties', () {
      final input = fixture(name)..['unexpected'] = 1;
      expect(() => decodeContract(input), throwsFormatException);
    });
    test('IR-01 $name rejects unsupported versions', () {
      final input = fixture(name)..['schemaVersion'] = '2.0';
      expect(() => decodeContract(input), throwsFormatException);
    });
  }
}
