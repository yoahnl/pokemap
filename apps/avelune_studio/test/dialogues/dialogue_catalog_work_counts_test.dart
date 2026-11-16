import 'package:flutter_test/flutter_test.dart';

import 'dialogue_catalog_support.dart';

void main() {
  test(
    'only the requested document is read independently of unrelated titles',
    () async {
      for (final count in [2, 500]) {
        final h = DialogueCatalogHarness(count: count);
        await h.controller.open();
        await h.controller.load('talk_0');
        h.controller.previewIn('en');
        final english = h.controller.preview('talk_0');
        expect(identical(english, h.controller.preview('talk_0')), isTrue);
        h.controller.previewIn('es');
        h.controller.preview('talk_0');
        await h.controller.load('talk_0');
        h.controller.filter('499');
        expect(h.port.requests, ['talk_0']);
        expect(h.index.documentRequests, isEmpty);
        expect(h.index.directoryRequests, isEmpty);
        expect(h.port.languageReads, 1);
      }
    },
  );
}
