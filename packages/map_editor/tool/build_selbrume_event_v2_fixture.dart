import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../test/support/selbrume_event_v2_fixture.dart';

void main() {
  test('builds the autonomous Selbrume Event V2 fixture', () async {
    final fixture = await SelbrumeEventV2Fixture.create();
    try {
      final destination = Directory(
        p.join(
          fixture.repoRoot.path,
          'examples',
          'playable_runtime_host',
          'event_builder_v2_selbrume_slice',
        ),
      );
      await fixture.exportAutonomousFixture(destination);
      stdout.writeln('Generated ${destination.path}');
    } finally {
      await fixture.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
