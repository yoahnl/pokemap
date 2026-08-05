import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  group('AveluneCustomBackgroundImporter', () {
    test('cancelled picker does not process or write', () async {
      final processor = _RecordingProcessor();
      final storage = _MemoryBackgroundStorage();
      final importer = AveluneCustomBackgroundImporter(
        picker: _Picker(null),
        processor: processor,
        storage: storage,
      );

      final outcome = await importer.pickAndImport();

      expect(outcome, AveluneCustomBackgroundImportOutcome.cancelled);
      expect(processor.calls, 0);
      expect(storage.replacements, 0);
    });

    test('rejects content whose signature is not JPEG, PNG or WebP', () async {
      final processor = _RecordingProcessor();
      final importer = AveluneCustomBackgroundImporter(
        picker: _Picker(
          AvelunePickedBackground(
            name: 'pretend.png',
            bytes: Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]),
          ),
        ),
        processor: processor,
        storage: _MemoryBackgroundStorage(),
      );

      await expectLater(
        importer.pickAndImport(),
        throwsA(
          isA<AveluneCustomBackgroundException>().having(
            (error) => error.code,
            'code',
            AveluneCustomBackgroundErrorCode.unsupportedFormat,
          ),
        ),
      );
      expect(processor.calls, 0);
    });

    test('rejects input larger than twelve megabytes before decoding',
        () async {
      final processor = _RecordingProcessor();
      final bytes = Uint8List(kAveluneMaximumCustomBackgroundBytes + 1)
        ..setAll(0, <int>[0xFF, 0xD8, 0xFF]);
      final importer = AveluneCustomBackgroundImporter(
        picker: _Picker(
          AvelunePickedBackground(name: 'large.jpg', bytes: bytes),
        ),
        processor: processor,
        storage: _MemoryBackgroundStorage(),
      );

      await expectLater(
        importer.pickAndImport(),
        throwsA(
          isA<AveluneCustomBackgroundException>().having(
            (error) => error.code,
            'code',
            AveluneCustomBackgroundErrorCode.fileTooLarge,
          ),
        ),
      );
      expect(processor.calls, 0);
    });

    test('storage failure is reported without claiming an import', () async {
      final storage = _MemoryBackgroundStorage(failReplace: true);
      final importer = AveluneCustomBackgroundImporter(
        picker: _Picker(_validPickedBackground()),
        processor: _RecordingProcessor(),
        storage: storage,
      );

      await expectLater(
        importer.pickAndImport(),
        throwsA(
          isA<AveluneCustomBackgroundException>().having(
            (error) => error.code,
            'code',
            AveluneCustomBackgroundErrorCode.writeFailed,
          ),
        ),
      );
      expect(storage.committed, isFalse);
    });
  });

  test('isolate processor orients, bounds and JPEG-encodes both images',
      () async {
    final source = image.Image(width: 2400, height: 1200, numChannels: 4);
    image.fill(source, color: image.ColorRgba8(80, 30, 120, 128));
    final processor = AveluneIsolateBackgroundImageProcessor();

    final processed = await processor.process(image.encodePng(source));
    final full = image.decodeJpg(processed.imageBytes);
    final thumbnail = image.decodeJpg(processed.thumbnailBytes);

    expect(full, isNotNull);
    expect(full!.width, 1800);
    expect(full.height, 900);
    expect(thumbnail, isNotNull);
    expect(thumbnail!.width, lessThanOrEqualTo(480));
    expect(thumbnail.height, lessThanOrEqualTo(480));
    expect(processed.imageBytes.take(3), <int>[0xFF, 0xD8, 0xFF]);
    expect(processed.thumbnailBytes.take(3), <int>[0xFF, 0xD8, 0xFF]);
  });

  test('local storage validates, replaces and deletes fixed local files',
      () async {
    final supportRoot = await Directory.systemTemp.createTemp('avelune-image-');
    addTearDown(() async {
      if (await supportRoot.exists()) await supportRoot.delete(recursive: true);
    });
    final processor = AveluneIsolateBackgroundImageProcessor();
    final storage = AveluneLocalCustomBackgroundStorage(
      supportRoot: supportRoot,
      processor: processor,
    );
    final processed = await processor.process(
      _validPickedBackground().bytes,
    );

    await storage.replace(processed);

    expect(await storage.isValid(), isTrue);
    expect(storage.imageFile.path, endsWith('custom-background.jpg'));
    expect(
      storage.thumbnailFile.path,
      endsWith('custom-background.thumbnail.jpg'),
    );
    expect(
      storage.appearanceRoot.listSync().where(
            (entry) =>
                entry.path.contains('.tmp.') ||
                entry.path.contains('.previous.'),
          ),
      isEmpty,
    );

    await storage.delete();
    expect(await storage.imageFile.exists(), isFalse);
    expect(await storage.thumbnailFile.exists(), isFalse);
    expect(await storage.isValid(), isFalse);
  });

  test('failed replacement restores the previously validated image', () async {
    final supportRoot =
        await Directory.systemTemp.createTemp('avelune-rollback-');
    addTearDown(() async {
      if (await supportRoot.exists()) await supportRoot.delete(recursive: true);
    });
    final processor = AveluneIsolateBackgroundImageProcessor();
    final healthyStorage = AveluneLocalCustomBackgroundStorage(
      supportRoot: supportRoot,
      processor: processor,
    );
    final previous = await processor.process(_validPickedBackground().bytes);
    await healthyStorage.replace(previous);
    final previousImage = await healthyStorage.imageFile.readAsBytes();
    final replacementSource = image.Image(width: 48, height: 36);
    image.fill(replacementSource, color: image.ColorRgb8(10, 180, 90));
    final replacement =
        await processor.process(image.encodePng(replacementSource));
    final failingStorage = AveluneLocalCustomBackgroundStorage(
      supportRoot: supportRoot,
      processor: _FailingCommitValidator(processor),
    );

    await expectLater(
      failingStorage.replace(replacement),
      throwsA(isA<AveluneCustomBackgroundException>()),
    );

    expect(await healthyStorage.imageFile.readAsBytes(), previousImage);
    expect(await healthyStorage.isValid(), isTrue);
  });
}

AvelunePickedBackground _validPickedBackground() {
  final source = image.Image(width: 32, height: 24);
  image.fill(source, color: image.ColorRgb8(80, 30, 120));
  return AvelunePickedBackground(
    name: 'background.png',
    bytes: image.encodePng(source),
  );
}

final class _Picker implements AveluneBackgroundPicker {
  const _Picker(this.result);

  final AvelunePickedBackground? result;

  @override
  Future<AvelunePickedBackground?> pick() async => result;
}

final class _RecordingProcessor implements AveluneBackgroundImageProcessor {
  int calls = 0;

  @override
  Future<AveluneProcessedBackground> process(Uint8List bytes) async {
    calls++;
    return AveluneProcessedBackground(
      imageBytes: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xD9]),
      thumbnailBytes: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xD9]),
      width: 32,
      height: 24,
    );
  }

  @override
  Future<bool> validateJpeg(Uint8List bytes) async => true;
}

final class _MemoryBackgroundStorage implements AveluneCustomBackgroundStorage {
  _MemoryBackgroundStorage({this.failReplace = false});

  final bool failReplace;
  int replacements = 0;
  bool committed = false;

  @override
  String get imagePath => '/support/avelune/appearance/custom-background.jpg';

  @override
  String get thumbnailPath =>
      '/support/avelune/appearance/custom-background.thumbnail.jpg';

  @override
  Future<void> delete() async => committed = false;

  @override
  Future<bool> isValid() async => committed;

  @override
  Future<void> replace(AveluneProcessedBackground background) async {
    replacements++;
    if (failReplace) throw const FileSystemException('simulated');
    committed = true;
  }
}

final class _FailingCommitValidator implements AveluneBackgroundImageProcessor {
  _FailingCommitValidator(this.delegate);

  final AveluneBackgroundImageProcessor delegate;
  int validations = 0;

  @override
  Future<AveluneProcessedBackground> process(Uint8List bytes) =>
      delegate.process(bytes);

  @override
  Future<bool> validateJpeg(Uint8List bytes) async {
    validations++;
    if (validations == 4) {
      throw const AveluneCustomBackgroundException(
        AveluneCustomBackgroundErrorCode.decodeFailed,
        'simulated confirmation failure',
      );
    }
    return delegate.validateJpeg(bytes);
  }
}
