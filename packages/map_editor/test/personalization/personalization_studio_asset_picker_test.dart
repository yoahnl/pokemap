import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  test('intro picker accepts one video, one poster, and optional captions',
      () async {
    final backend = _Backend(
      <String>[
        '/source/opening.mp4',
        '/source/poster.webp',
        '/source/fr.vtt',
      ],
    );
    final picker = FilePickerPersonalizationStudioAssetPicker(
      backend: backend,
    );

    final selection = await picker.pickIntroAssets();

    expect(selection?.videoPath, '/source/opening.mp4');
    expect(selection?.posterPath, '/source/poster.webp');
    expect(selection?.captionsPath, '/source/fr.vtt');
    expect(
      backend.lastRequest?.allowedExtensions,
      containsAll(<String>['mp4', 'png', 'jpg', 'jpeg', 'webp', 'vtt']),
    );
  });

  test('font picker requires one font and one text license', () async {
    final backend = _Backend(
      <String>['/source/body.otf', '/source/OFL.txt'],
    );
    final picker = FilePickerPersonalizationStudioAssetPicker(
      backend: backend,
    );

    final selection = await picker.pickFontAssets();

    expect(selection?.fontPath, '/source/body.otf');
    expect(selection?.licensePath, '/source/OFL.txt');
    expect(
      backend.lastRequest?.allowedExtensions,
      <String>['ttf', 'otf', 'txt'],
    );
  });

  test('picker cancellation is distinct from an invalid selection', () async {
    final cancelled = FilePickerPersonalizationStudioAssetPicker(
      backend: _Backend(null),
    );
    expect(await cancelled.pickIntroAssets(), isNull);

    final invalid = FilePickerPersonalizationStudioAssetPicker(
      backend: _Backend(<String>['/source/opening.mp4']),
    );
    expect(
      invalid.pickIntroAssets,
      throwsA(
        isA<PersonalizationStudioAssetSelectionException>().having(
          (error) => error.code,
          'code',
          'introSelectionIncomplete',
        ),
      ),
    );
  });

  test('branding picker selects exactly one supported image', () async {
    final backend = _Backend(<String>['/source/cover.webp']);
    final picker = FilePickerPersonalizationStudioBrandingImagePicker(
      backend: backend,
    );

    final selection =
        await picker.pickBrandingImage(ProjectBrandingImageRole.cover);

    expect(selection, '/source/cover.webp');
    expect(
      backend.lastRequest?.allowedExtensions,
      <String>['png', 'jpg', 'jpeg', 'webp'],
    );
    final invalid = FilePickerPersonalizationStudioBrandingImagePicker(
      backend: _Backend(<String>[
        '/source/cover.webp',
        '/source/other.png',
      ]),
    );
    await expectLater(
      invalid.pickBrandingImage(ProjectBrandingImageRole.cover),
      throwsA(
        isA<PersonalizationStudioAssetSelectionException>().having(
          (error) => error.code,
          'code',
          'brandingImageSelectionInvalid',
        ),
      ),
    );
  });

  test('title music picker selects exactly one supported audio file', () async {
    final backend = _Backend(<String>['/source/title.flac']);
    final picker = FilePickerPersonalizationStudioTitleMusicPicker(
      backend: backend,
    );

    expect(await picker.pickTitleMusic(), '/source/title.flac');
    expect(
      backend.lastRequest?.allowedExtensions,
      <String>['ogg', 'wav', 'mp3', 'flac', 'm4a'],
    );

    final invalid = FilePickerPersonalizationStudioTitleMusicPicker(
      backend: _Backend(<String>[
        '/source/title.flac',
        '/source/alternate.ogg',
      ]),
    );
    await expectLater(
      invalid.pickTitleMusic(),
      throwsA(
        isA<PersonalizationStudioAssetSelectionException>().having(
          (error) => error.code,
          'code',
          'titleMusicSelectionInvalid',
        ),
      ),
    );
  });
}

final class _Backend implements PersonalizationStudioFilePickerBackend {
  _Backend(this.result);

  final List<String>? result;
  PersonalizationStudioFilePickerRequest? lastRequest;

  @override
  Future<List<String>?> pick(
    PersonalizationStudioFilePickerRequest request,
  ) async {
    lastRequest = request;
    return result;
  }
}
