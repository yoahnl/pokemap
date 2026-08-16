import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../test_driver/presentation_runtime_performance_driver.dart'
    as performance_driver;

void main() {
  test('macOS CIN-038 profile receipt blocks the protected release', () async {
    final workflow =
        await File(
          '../../.github/workflows/pokemap_hub_product_certification.yml',
        ).readAsString();
    final support =
        jsonDecode(
              await File('tool/release/platform_support.json').readAsString(),
            )
            as Map<String, Object?>;
    final platforms = support['platforms']! as Map<String, Object?>;

    expect(workflow, contains('cinematic-runtime-performance-gate:'));
    expect(
      workflow,
      contains(
        '--target=integration_test/'
        'presentation_runtime_performance_journey_test.dart',
      ),
    );
    expect(
      workflow,
      contains(
        '--driver=test_driver/'
        'presentation_runtime_performance_driver.dart',
      ),
    );
    expect(workflow, contains('certify_presentation_runtime_performance.dart'));
    expect(workflow, contains('presentation_runtime_cin_038_receipt.json'));
    expect(workflow, contains('      - cinematic-runtime-performance-gate'));
    expect(
      (platforms['macos']! as Map<String, Object?>)['status'],
      'supported',
    );
    expect(
      (platforms['ios']! as Map<String, Object?>)['status'],
      'xcode-cloud-target',
    );
    expect(
      (platforms['android']! as Map<String, Object?>)['status'],
      'build-target',
    );
    expect(workflow, isNot(contains('flutter build ios')));
  });

  test('CIN-038 driver confines raw evidence to the Hub package', () {
    expect(
      () => performance_driver.validatePresentationRuntimePerformanceOutput(
        '/tmp/cin038.json',
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => performance_driver.validatePresentationRuntimePerformanceOutput(
        '../cin038.json',
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      performance_driver
          .validatePresentationRuntimePerformanceOutput(
            'build/performance/cin038.json',
          )
          .path,
      endsWith('apps/pokemap_hub/build/performance/cin038.json'),
    );
  });
}
