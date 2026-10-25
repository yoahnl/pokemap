import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/flutter_image_presenter_stub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Image sourceImage(int width, int height) {
    final recorder = PictureRecorder();
    Canvas(recorder).drawColor(const Color(0xffff0000), BlendMode.src);
    final picture = recorder.endRecording();
    try {
      return picture.toImageSync(width, height);
    } finally {
      picture.dispose();
    }
  }

  test('presentation survives disposal of the caller source handle', () {
    final source = sourceImage(12, 8);
    final presented = createFlutterImagePresenter()(source);
    addTearDown(presented.dispose);

    expect(presented, isNot(same(source)));
    expect(presented.isCloneOf(source), isTrue);
    source.dispose();

    expect(presented.debugDisposed, isFalse);
    expect((presented.width, presented.height), (12, 8));
  });

  test('repeated presentations return independently owned handles', () {
    final source = sourceImage(12, 8);
    final present = createFlutterImagePresenter();
    final first = present(source);
    final second = present(source);
    addTearDown(source.dispose);
    addTearDown(second.dispose);

    expect(first, isNot(same(second)));
    first.dispose();

    expect(source.debugDisposed, isFalse);
    expect(second.debugDisposed, isFalse);
    expect((second.width, second.height), (12, 8));
  });

  test('presentation retains no image dimensions across calls', () {
    final present = createFlutterImagePresenter();
    final first = sourceImage(12, 8);
    final second = sourceImage(7, 19);
    final firstPresented = present(first);
    final secondPresented = present(second);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    addTearDown(firstPresented.dispose);
    addTearDown(secondPresented.dispose);

    expect((firstPresented.width, firstPresented.height), (12, 8));
    expect((secondPresented.width, secondPresented.height), (7, 19));
  });

  test('an invalid disposed input does not poison later presentation', () {
    final present = createFlutterImagePresenter();
    final invalid = sourceImage(12, 8)..dispose();
    final valid = sourceImage(7, 19);
    addTearDown(valid.dispose);

    expect(() => present(invalid), throwsA(isA<Error>()));
    final presented = present(valid);
    addTearDown(presented.dispose);

    expect((presented.width, presented.height), (7, 19));
    expect(valid.debugDisposed, isFalse);
  });
}
