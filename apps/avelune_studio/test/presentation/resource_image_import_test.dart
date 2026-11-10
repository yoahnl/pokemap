import 'dart:typed_data';

import 'package:avelune_studio/features/resources/application/resource_image_import_draft.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/platform/rendering/resource_image_content_verifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unreadable PNG preflight reports a recoverable refusal and closing keeps no import request', () async {
    final draft = ResourceImageImportDraft(
      image: PickedResourceImage('/unused.png', 'Image', Uint8List(24), 16, 24),
      tileWidth: 16,
      tileHeight: 24,
    );
    await draft.verify(verifyResourceImageContent);
    expect(draft.decoded, isFalse);
    expect(draft.valid, isFalse);
    expect(draft.build(), isNull);
    draft.dispose();
    expect(draft.build(), isNull);
  });
}
