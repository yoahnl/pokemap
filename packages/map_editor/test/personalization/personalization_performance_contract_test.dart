import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile certification keeps the Personalization journey in CI', () {
    final target = File(
      'integration_test/personalization_performance_journey_test.dart',
    );
    expect(target.existsSync(), isTrue);
    if (!target.existsSync()) return;

    final source = target.readAsStringSync();
    expect(source, contains("'benchmark': 'personalization_studio_journey'"));
    expect(source, contains("'frameSpanP95Us'"));
    expect(source, contains("'frameSpanP99Us'"));
    expect(source, contains("'rssGrowthBytes'"));
    expect(source, contains("'io': ioAfterSave.toJson()"));
    expect(source, contains("'sliderTicks': 100"));
    expect(source, contains("'soakGestures': 10"));

    final workflow = File(
      '../../.github/workflows/pokemap_hub_product_certification.yml',
    ).readAsStringSync();
    expect(
      workflow,
      contains(
        '--target=integration_test/personalization_performance_journey_test.dart',
      ),
    );
    expect(
      workflow,
      contains('build/performance/personalization_studio_journey.json'),
    );
  });
}
