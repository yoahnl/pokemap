import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the legacy map inspector is the only encounter table panel host', () {
    final hosts =
        Directory('lib/src')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) => !file.path.endsWith('encounter_tables_panel.dart'))
            .where(
              (file) => file.readAsStringSync().contains(
                RegExp(r'\bEncounterTablesPanel\s*\('),
              ),
            )
            .map((file) => file.path.replaceAll('\\', '/'))
            .toList()
          ..sort();

    expect(hosts, <String>['lib/src/ui/panels/map_inspector_panel.dart']);
  });
}
