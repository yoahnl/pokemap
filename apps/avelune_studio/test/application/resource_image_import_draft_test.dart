import 'dart:async';
import 'dart:typed_data';

import 'package:avelune_studio/features/resources/application/resource_image_import_draft.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:flutter_test/flutter_test.dart';

ResourceImageImportDraft _draft({Set<String> existingNames = const {}}) =>
    ResourceImageImportDraft(
      image: PickedResourceImage(
        '/fixture/atlas.png',
        'Atlas',
        Uint8List(0),
        160,
        64,
      ),
      tileWidth: 32,
      tileHeight: 16,
      existingNames: existingNames,
    );

void main() {
  test('image import waits for decoded single-frame content before building a request', () async {
    final draft = _draft();
    expect(draft.build(), isNull);
    await draft.verify((_) async => true);
    draft.name = '  Sources du village  ';
    final request = draft.build()!;
    expect(request.sourcePath, '/fixture/atlas.png');
    expect(request.name, 'Sources du village');
    expect(request.tileWidth, 32);
    expect(request.tileHeight, 16);
  });

  test('existing image names warn without replacing or blocking an independent import', () async {
    final draft = _draft(existingNames: {'  ATLAS '});
    await draft.verify((_) async => true);
    expect(draft.nameTaken, isTrue);
    expect(draft.valid, isTrue);
    expect(draft.build()!.name, 'Atlas');
  });

  test(
    'uneven grids and invalid cell bounds preserve raw input and refuse import',
    () async {
      final draft = _draft();
      await draft.verify((_) async => true);
      draft.width = '48';
      expect(draft.restWidth, 16);
      expect(draft.build(), isNull);
      draft.width = '32';
      draft.height = '24';
      expect(draft.restHeight, 16);
      expect(draft.build(), isNull);
      for (final invalid in ['0', '-1', 'invalid', '320']) {
        draft.width = invalid;
        expect(draft.width, invalid);
        expect(draft.build(), isNull);
      }
      draft.width = '32';
      draft.height = '16';
      expect(draft.valid, isTrue);
      draft.name = '  ';
      expect(draft.build(), isNull);
    },
  );

  test('unreadable content and verifier failures refuse import', () async {
    final draft = _draft();
    await draft.verify((_) async => false);
    expect(draft.decoded, isFalse);
    expect(draft.build(), isNull);
    await draft.verify((_) async => throw StateError('invalid content'));
    expect(draft.decoded, isFalse);
    expect(draft.build(), isNull);
  });

  test(
    'a late verifier cannot overwrite a newer verification result',
    () async {
      final draft = _draft();
      final old = Completer<bool>();
      final pending = draft.verify((_) => old.future);
      await draft.verify((_) async => false);
      old.complete(true);
      await pending;
      expect(draft.decoded, isFalse);
      expect(draft.build(), isNull);
    },
  );

  test('closing the preflight ignores pending decoding and never exposes a request', () async {
    final draft = _draft();
    final decoding = Completer<bool>();
    final pending = draft.verify((_) => decoding.future);
    draft.dispose();
    decoding.complete(true);
    await pending;
    expect(draft.decoded, isNull);
    expect(draft.build(), isNull);
  });
}
