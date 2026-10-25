import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/platform/files/local_rendering_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late File file;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('studio-rendering-');
    file = File('${directory.path}/settings/rendering-preferences.json');
  });
  tearDown(() => directory.delete(recursive: true));

  test('missing preference file does not create storage', () async {
    final store = LocalRenderingPreferencesStore(file.path);

    expect(await store.load(), isNull);
    expect(await file.parent.exists(), isFalse);
  });

  test(
    'all five limits survive reopening without touching unrelated content',
    () async {
      final unrelated = File('${directory.path}/project.json');
      await unrelated.writeAsString('unrelated project and journal content');
      final before = await unrelated.readAsBytes();
      final store = LocalRenderingPreferencesStore(file.path);

      for (final limit in [30, 45, 60, 90, 120]) {
        await store.save(limit);
        expect(await LocalRenderingPreferencesStore(file.path).load(), limit);
        expect(await unrelated.readAsBytes(), before);
        expect(await file.parent.list().map((entry) => entry.path).toList(), [
          file.path,
        ]);
      }
      expect(jsonDecode(await file.readAsString()), {
        'schemaVersion': 1,
        'targetFramesPerSecond': 120,
      });
    },
  );

  test('malformed and future preferences are preserved and rejected', () async {
    await file.parent.create(recursive: true);
    final store = LocalRenderingPreferencesStore(file.path);
    for (final content in [
      '{broken',
      '{"schemaVersion":2,"targetFramesPerSecond":60}',
      '{"schemaVersion":1,"targetFramesPerSecond":59}',
      '{"schemaVersion":1,"targetFramesPerSecond":60.0}',
    ]) {
      await file.writeAsString(content);

      await expectLater(store.load(), throwsFormatException);

      expect(await file.readAsString(), content);
    }
  });

  test('invalid new values cannot replace the durable file', () async {
    final store = LocalRenderingPreferencesStore(file.path);
    await store.save(45);
    final before = await file.readAsBytes();

    await expectLater(store.save(0), throwsArgumentError);

    expect(await file.readAsBytes(), before);
  });

  test('failed replacement retains the previous destination', () async {
    await Directory(file.path).create(recursive: true);
    final preserved = File('${file.path}/owned.txt');
    await preserved.writeAsString('preserved');

    await expectLater(
      LocalRenderingPreferencesStore(file.path).save(90),
      throwsA(isA<FileSystemException>()),
    );

    expect(await preserved.readAsString(), 'preserved');
    expect(await file.parent.list().map((entry) => entry.path).toList(), [
      file.path,
    ]);
  });
}
