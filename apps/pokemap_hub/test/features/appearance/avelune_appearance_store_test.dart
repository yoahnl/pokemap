import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  group('AveluneAppearancePreferences', () {
    test('uses the exact V1 JSON contract', () {
      const preferences = AveluneAppearancePreferences(
        backgroundId: 'linen',
        furnitureId: 'ivory',
      );

      expect(preferences.toJson(), <String, Object?>{
        'schemaVersion': 1,
        'backgroundId': 'linen',
        'furnitureId': 'ivory',
      });
      expect(
        AveluneAppearancePreferences.fromJson(preferences.toJson()),
        preferences,
      );
    });

    test('rejects unsupported schema, unknown IDs and extra fields', () {
      for (final document in <Map<String, Object?>>[
        <String, Object?>{
          'schemaVersion': 2,
          'backgroundId': 'amber',
          'furnitureId': 'walnut',
        },
        <String, Object?>{
          'schemaVersion': 1,
          'backgroundId': 'unknown',
          'furnitureId': 'walnut',
        },
        <String, Object?>{
          'schemaVersion': 1,
          'backgroundId': 'amber',
          'furnitureId': 'unknown',
        },
        <String, Object?>{
          'schemaVersion': 1,
          'backgroundId': 'amber',
          'furnitureId': 'walnut',
          'absolutePath': '/private/image.jpg',
        },
      ]) {
        expect(
          () => AveluneAppearancePreferences.fromJson(document),
          throwsFormatException,
        );
      }
    });
  });

  test('catalog exposes stable French labels and eleven built-in presets', () {
    expect(
      AveluneAppearanceCatalog.backgrounds.map((option) => option.id),
      <String>['amber', 'dawn', 'linen', 'violet', 'slate', 'custom'],
    );
    expect(
      AveluneAppearanceCatalog.furniture.map((option) => option.id),
      <String>['walnut', 'ivory', 'oak', 'ash', 'mahogany', 'ebony'],
    );
    expect(AveluneAppearanceCatalog.builtInPresets, hasLength(11));
    expect(AveluneAppearanceCatalog.background('custom').label, 'Mon image');
    expect(AveluneAppearanceCatalog.furnitureFinish('ivory').label, 'Ivoire');
    expect(
      appearanceAssetPath(AveluneAppearanceCatalog.background('amber')),
      'assets/avelune/room/backgrounds/amber.webp',
    );
  });

  group('AveluneAppearanceStore', () {
    late Directory supportRoot;

    setUp(() async {
      supportRoot = await Directory.systemTemp.createTemp('avelune-store-');
    });

    tearDown(() async {
      if (await supportRoot.exists()) {
        await supportRoot.delete(recursive: true);
      }
    });

    test('missing documents load the approved amber and ivory defaults',
        () async {
      final store = AveluneAppearanceStore(supportRoot: supportRoot);

      final result = await store.load();

      expect(result.preferences, const AveluneAppearancePreferences());
      expect(result.preferences.backgroundId, 'amber');
      expect(result.preferences.furnitureId, 'ivory');
      expect(result.source, AveluneAppearanceSource.defaults);
      expect(result.currentCorrupt, isFalse);
      expect(result.backupCorrupt, isFalse);
    });

    test('save survives restart and writes only stable IDs', () async {
      final firstStore = AveluneAppearanceStore(supportRoot: supportRoot);
      const preferences = AveluneAppearancePreferences(
        backgroundId: 'violet',
        furnitureId: 'ivory',
      );
      await firstStore.save(preferences);

      final restarted = AveluneAppearanceStore(supportRoot: supportRoot);
      final result = await restarted.load();
      final document = jsonDecode(
        await restarted.preferencesFile.readAsString(),
      ) as Map<String, dynamic>;

      expect(result.preferences, preferences);
      expect(result.source, AveluneAppearanceSource.current);
      expect(document.keys.toSet(),
          <String>{'schemaVersion', 'backgroundId', 'furnitureId'});
      expect(document.values.whereType<String>(), isNot(contains('/')));
    });

    test('corrupt current recovers the last valid backup', () async {
      final store = AveluneAppearanceStore(supportRoot: supportRoot);
      const previous = AveluneAppearancePreferences(
        backgroundId: 'dawn',
        furnitureId: 'oak',
      );
      await store.save(previous);
      await store.save(
        const AveluneAppearancePreferences(
          backgroundId: 'slate',
          furnitureId: 'ebony',
        ),
      );
      await store.preferencesFile.writeAsString('{broken');

      final result = await store.load();

      expect(result.preferences, previous);
      expect(result.source, AveluneAppearanceSource.backup);
      expect(result.currentCorrupt, isTrue);
      expect(result.backupCorrupt, isFalse);
    });

    test('corrupt current and backup safely return defaults', () async {
      final store = AveluneAppearanceStore(supportRoot: supportRoot);
      await store.appearanceRoot.create(recursive: true);
      await store.preferencesFile.writeAsString('{broken');
      await store.backupFile.writeAsString('[]');

      final result = await store.load();

      expect(result.preferences, const AveluneAppearancePreferences());
      expect(result.source, AveluneAppearanceSource.defaults);
      expect(result.currentCorrupt, isTrue);
      expect(result.backupCorrupt, isTrue);
    });

    test('rejects a symlinked appearance directory', () async {
      final outside = await Directory.systemTemp.createTemp('avelune-link-');
      addTearDown(() async {
        if (await outside.exists()) await outside.delete(recursive: true);
      });
      await Directory('${supportRoot.path}/avelune').create();
      await Link('${supportRoot.path}/avelune/appearance').create(outside.path);
      final store = AveluneAppearanceStore(supportRoot: supportRoot);

      expect(store.load(), throwsA(isA<AveluneAppearanceStorageException>()));
    });

    test('write failure preserves the previously confirmed document', () async {
      final healthy = AveluneAppearanceStore(supportRoot: supportRoot);
      const previous = AveluneAppearancePreferences(
        backgroundId: 'linen',
        furnitureId: 'ash',
      );
      await healthy.save(previous);
      final failing = AveluneAppearanceStore(
        supportRoot: supportRoot,
        writeDocument: (_, _) async => throw const FileSystemException(
          'simulated write failure',
        ),
      );

      await expectLater(
        failing.save(
          const AveluneAppearancePreferences(
            backgroundId: 'violet',
            furnitureId: 'ivory',
          ),
        ),
        throwsA(isA<AveluneAppearanceStorageException>()),
      );

      expect((await healthy.load()).preferences, previous);
    });
  });
}
