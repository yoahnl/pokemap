import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../tool/build_selbrume_visual_kit.dart';

void main() {
  test('builds the portable V2 atlas deterministically from approved sources',
      () async {
    final projectRoot = _selbrumeRoot();
    final first = await Directory.systemTemp.createTemp('selbrume_kit_a_');
    final second = await Directory.systemTemp.createTemp('selbrume_kit_b_');
    addTearDown(() async {
      if (await first.exists()) await first.delete(recursive: true);
      if (await second.exists()) await second.delete(recursive: true);
    });

    final firstResult = await buildSelbrumeVisualKit(
      SelbrumeVisualKitOptions(
        projectRoot: projectRoot,
        outputDirectory: first,
        manifestFile: File(p.join(first.path, 'visual_kit_manifest.json')),
      ),
    );
    final secondResult = await buildSelbrumeVisualKit(
      SelbrumeVisualKitOptions(
        projectRoot: projectRoot,
        outputDirectory: second,
        manifestFile: File(p.join(second.path, 'visual_kit_manifest.json')),
      ),
    );

    expect(firstResult.entryCount, 68);
    expect(firstResult.atlasSha256, secondResult.atlasSha256);
    expect(
      firstResult.atlasFile.readAsBytesSync(),
      secondResult.atlasFile.readAsBytesSync(),
    );
    expect(
      firstResult.manifestFile.readAsBytesSync(),
      secondResult.manifestFile.readAsBytesSync(),
    );

    final atlas = img.decodePng(firstResult.atlasFile.readAsBytesSync())!;
    expect(atlas.width % 32, 0);
    expect(atlas.height % 32, 0);
    expect(atlas.width, 1024);

    final manifest = jsonDecode(firstResult.manifestFile.readAsStringSync())
        as Map<String, dynamic>;
    expect(manifest['schemaVersion'], 1);
    expect(manifest['sourceCorpus'], 'chatGPT_user_supplied_2026-07-12');
    expect(manifest['licenseDecision'], 'user_supplied_project_owner_approved');
    expect(manifest['referenceImagesUsedAsUnderlays'], isFalse);
    expect(manifest['atlasSha256'], firstResult.atlasSha256);
    final entries = manifest['entries'] as List<dynamic>;
    expect(entries, hasLength(68));
    expect(
      entries.map((entry) => (entry as Map<String, dynamic>)['id']).toSet(),
      hasLength(68),
    );
    for (final raw in entries.cast<Map<String, dynamic>>()) {
      expect(raw['sourceRelativePath'], startsWith('assets/sources/v2/'));
      expect(raw['sourceRelativePath'], isNot(contains('/map/')));
      expect(raw['sourceSha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(raw['anchor'], 'bottom_center');
      final source = raw['source'] as Map<String, dynamic>;
      expect((source['x'] as int) + (source['width'] as int),
          lessThanOrEqualTo(atlas.width ~/ 32));
      expect((source['y'] as int) + (source['height'] as int),
          lessThanOrEqualTo(atlas.height ~/ 32));
    }

    for (final category in const ['houses', 'vegetation', 'props', 'rocks']) {
      final categoryEntries = entries.cast<Map<String, dynamic>>().where(
            (entry) => entry['category'] == category,
          );
      expect(categoryEntries, isNotEmpty);
      expect(
        categoryEntries.every((entry) => entry['hasRealAlpha'] == true),
        isTrue,
      );
    }
  }, skip: _approvedV2SourceCorpusSkipReason());
}

String? _approvedV2SourceCorpusSkipReason() {
  final sourceRoot = Directory(
    p.join(_selbrumeRoot().path, 'assets', 'sources', 'v2'),
  );
  return sourceRoot.existsSync()
      ? null
      : 'Approved user-supplied V2 source corpus is not versioned.';
}

Directory _selbrumeRoot() {
  final candidates = <Directory>[
    Directory(p.normalize(p.absolute('../../selbrume'))),
    Directory(p.normalize(p.absolute('selbrume'))),
  ];
  return candidates.firstWhere(
    (candidate) => File(p.join(candidate.path, 'project.json')).existsSync(),
    orElse: () => throw StateError('Unable to resolve Selbrume project root.'),
  );
}
