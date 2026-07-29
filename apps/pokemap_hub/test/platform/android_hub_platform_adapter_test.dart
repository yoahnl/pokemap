import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/src/platform/android_hub_platform_adapter.dart';
import 'package:pokemap_hub/src/platform/hub_platform_adapter.dart';

void main() {
  test('picker returns the local path copied by the Android host', () async {
    final adapter = AndroidHubPlatformAdapter(
      pickFile: () async => '/tmp/adventure.avelunegame',
      readAvailableDiskBytes: () async => 1024,
    );

    expect(await adapter.pickPackage(), '/tmp/adventure.avelunegame');
  });

  test('picker cancellation is preserved', () async {
    final adapter = AndroidHubPlatformAdapter(
      pickFile: () async => null,
      readAvailableDiskBytes: () async => 1024,
    );

    expect(await adapter.pickPackage(), isNull);
  });

  test('picker failures have an actionable import error', () async {
    final adapter = AndroidHubPlatformAdapter(
      pickFile: () async => throw StateError('picker unavailable'),
      readAvailableDiskBytes: () async => 1024,
    );

    await expectLater(
      adapter.pickPackage(),
      throwsA(
        isA<HubPackagePickerFailure>()
            .having(
              (failure) => failure.code,
              'code',
              'importPicker.openFailed',
            )
            .having(
              (failure) => failure.cause,
              'cause',
              isA<StateError>(),
            ),
      ),
    );
  });

  test('storage reader creates the support root and returns valid bytes',
      () async {
    final root = Directory(
      '${Directory.systemTemp.path}/avelune-android-adapter-'
      '${DateTime.now().microsecondsSinceEpoch}',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final adapter = AndroidHubPlatformAdapter(
      pickFile: () async => null,
      readAvailableDiskBytes: () async => 4096,
    );

    expect(await adapter.availableDiskBytes(root), 4096);
    expect(await root.exists(), isTrue);
  });

  test('storage reader rejects missing or negative native values', () async {
    for (final invalidValue in <num?>[null, -1]) {
      final root = await Directory.systemTemp.createTemp(
        'avelune-android-invalid-storage-',
      );
      addTearDown(() => root.delete(recursive: true));
      final adapter = AndroidHubPlatformAdapter(
        pickFile: () async => null,
        readAvailableDiskBytes: () async => invalidValue,
      );

      await expectLater(
        adapter.availableDiskBytes(root),
        throwsA(isA<FileSystemException>()),
      );
    }
  });
}
