import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/infrastructure/repositories/file_presentation_studio_layout_store.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_shell.dart';

void main() {
  test(
    'persists Presentation panel sizes outside the project document',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'presentation_studio_layout_',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final store = FilePresentationStudioLayoutStore(
        supportDirectory: () async => root,
      );
      const expected = PresentationStudioLayout(
        inspectorWidth: 388,
        timelineHeight: 276,
      );

      await store.write(expected);

      expect(await store.read(), expected);
      expect(
        File('${root.path}/presentation_studio_layout_v1.json').existsSync(),
        isTrue,
      );
    },
  );

  test('fails closed to defaults when the local layout is corrupt', () async {
    final root = Directory.systemTemp.createTempSync(
      'presentation_studio_layout_corrupt_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    File(
      '${root.path}/presentation_studio_layout_v1.json',
    ).writeAsStringSync('{"schemaVersion":1,"inspectorWidth":"wide"}');
    final store = FilePresentationStudioLayoutStore(
      supportDirectory: () async => root,
    );

    expect(await store.read(), isNull);
  });
}
