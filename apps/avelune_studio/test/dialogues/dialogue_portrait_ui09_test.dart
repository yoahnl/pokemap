import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/dialogue_adapter_fixture.dart';

void main() {
  test(
    'portrait resolves canonical character variant to verified asset bytes',
    () async {
      final f = await DialogueAdapterFixture.create();
      addTearDown(f.dispose);
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aEJkAAAAASUVORK5CYII=',
      );
      final artifact = ContentArtifactRef.fromBytes(
        bytes,
        mediaType: 'image/png',
      );
      final record = AssetRecord(
        id: 'portrait.guide.neutral',
        logicalPath: 'assets/portraits/guide.png',
        artifact: artifact,
      );
      final catalog = f.file(assetCatalogStorageKey);
      await catalog.parent.create(recursive: true);
      await catalog.writeAsString(
        jsonEncode(AssetCatalog(records: [record]).toJson()),
      );
      final blob = f.file(assetBlobStorageKey(artifact));
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(bytes);
      await f.writeManifest(
        (await f.readManifest()).copyWith(
          characters: const [
            ProjectCharacterEntry(
              id: 'guide',
              name: 'Guide',
              tilesetId: 'unused',
              portraits: [
                CharacterPortraitVariant(
                  portraitStateId: 'neutral',
                  assetId: 'portrait.guide.neutral',
                ),
              ],
            ),
          ],
          characterStudioCatalog: const ProjectCharacterStudioCatalog(
            portraitStates: [
              CharacterPortraitStateDefinition(
                id: 'neutral',
                displayName: 'Neutre',
              ),
            ],
          ),
        ),
      );
      await f.maps.loadProject(f.session);
      final reader = DialogueCountingReader();
      final port = f.adapter(reader: reader);
      expect(await port.readPortrait('guide', 'neutral'), bytes);
      expect(reader.paths, [
        assetCatalogStorageKey,
        assetBlobStorageKey(artifact),
      ]);
      expect(await port.readPortrait('guide', 'missing'), isNull);
      expect(await port.readPortrait('missing', 'neutral'), isNull);
      expect(reader.paths.length, 2);
      await blob.writeAsBytes([1, 2, 3]);
      expect(await port.readPortrait('guide', 'neutral'), isNull);
      await blob.delete();
      expect(await port.readPortrait('guide', 'neutral'), isNull);
    },
  );

  test('unchanged source publication preserves all authored bytes', () async {
    final f = await DialogueAdapterFixture.create();
    addTearDown(f.dispose);
    final port = f.adapter();
    final base = await port.load('gare');
    final manifest = await f.file('project.json').readAsBytes();
    final result = await port.publish(
      id: 'gare',
      base: base,
      entry: base.entry,
      source: base.source,
    );
    expect(result.resources.changedPaths, isEmpty);
    expect(result.snapshot!.revision, base.revision);
    expect(await f.file('project.json').readAsBytes(), manifest);
    expect(await f.file(base.entry.relativePath).readAsString(), base.source);
  });
}
