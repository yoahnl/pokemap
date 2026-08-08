import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('library and inspector live outside the Smart Tiles root panel', () {
    final presentation = Directory(
      'lib/src/features/smart_tiles_studio/presentation',
    );
    final panel = File('${presentation.path}/smart_tiles_studio_panel.dart');
    final library = File(
      '${presentation.path}/smart_tiles_studio_library_pane.dart',
    );
    final inspector = File(
      '${presentation.path}/smart_tiles_studio_inspector.dart',
    );

    expect(library.existsSync(), isTrue, reason: 'Extract the library pane.');
    expect(
      inspector.existsSync(),
      isTrue,
      reason: 'Extract the contextual inspector.',
    );

    final source = panel.readAsStringSync();
    expect(source, contains("'smart_tiles_studio_library_pane.dart'"));
    expect(source, contains("'smart_tiles_studio_inspector.dart'"));
    expect(source, isNot(contains('Widget _buildLibrary(')));
    expect(source, isNot(contains('Widget _buildInspector(')));
    expect(
      source.split('\n').length,
      lessThanOrEqualTo(4200),
      reason: 'The root panel must shrink instead of absorbing new features.',
    );
  });
}
