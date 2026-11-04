import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog variants point to their own source programs', () async {
    final index = jsonDecode(
      await rootBundle.loadString('assets/bw2/batch/index.json'),
    ) as List;
    final variants = index.cast<Map>().where(
      (item) => item['sourceVariant'] is String,
    );
    expect(variants.length, greaterThanOrEqualTo(40));
    expect(
      variants.map((item) => item['bundleAsset']).toSet(),
      hasLength(variants.length),
    );
    for (final entry in variants) {
      final path = entry['bundleAsset'] as String;
      final bundle = jsonDecode(await rootBundle.loadString(path)) as Map;
      final program = bundle['program'] as Map;
      expect(bundle['id'], entry['id'], reason: path);
      expect(
        program['variant'],
        entry['resolvedVariant'] ?? entry['sourceVariant'],
        reason: path,
      );
      expect(program['conversion'], 'supported', reason: path);
      final labels = (program['labels'] as List).cast<Map>();
      expect(
        labels.any(
          (label) =>
              label['name'] == program['variant'] &&
              label['instructionIndex'] == program['entryIndex'],
        ),
        isTrue,
        reason: path,
      );
    }
  });

  test('delegated variants use the referenced source programs', () async {
    final index = jsonDecode(
      await rootBundle.loadString('assets/bw2/batch/index.json'),
    ) as List;
    final entry = index.cast<Map>().singleWhere(
      (item) =>
          item['originMoveId'] == 'secret-power' &&
          item['sourceVariant'] == 'SecretPower_Variant1',
    );
    expect(entry['id'], 'mud-slap');
    expect(entry['resolvedVariant'], 'MudSlap');
    expect(entry['bundleAsset'], 'assets/bw2/batch/mud-slap.json');
    final bide = index.cast<Map>().singleWhere(
      (item) =>
          item['originMoveId'] == 'bide' &&
          item['sourceVariant'] == 'Bide_Variant1',
    );
    expect(bide['id'], 'tackle');
    expect(bide['resolvedVariant'], 'Tackle');
    expect(bide['bundleAsset'], 'assets/bw2/batch/tackle--delegated.json');
  });
}
