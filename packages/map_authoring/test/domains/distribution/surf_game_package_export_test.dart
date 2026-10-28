import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final enabled in [null, false, true]) {
    test(
        'export declares Surf only for explicit configuration enabled=$enabled',
        () async {
      final qa =
          Directory('/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring');
      await qa.create(recursive: true);
      final root = await qa.createTemp('export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      final initial = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(files['project/project.json']!))
              as Map<String, dynamic>);
      final project = initial.copyWith(
          settings: initial.settings.copyWith(
              surf: enabled == null
                  ? null
                  : ProjectSurfSettings(enabled: enabled)));
      files['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final source = File('${root.path}/project.json');
      final bytes = await source.readAsBytes();
      final result = await const CanonicalGamePackageExportService().build(
          projectRoot: root,
          profile: GamePackageExportProfile(
              gameId: 'games.example.surf',
              gameVersion: '0.1.0',
              title: 'Surf',
              authorName: 'Yoahn',
              defaultLocale: 'fr',
              supportedLocales: ['fr']),
          mode: GamePackageExportMode.localTest);
      expect(
          result.manifest.compatibility.requiredCapabilities
              .contains('gameplay.surf@1'),
          enabled != null);
      expect(await source.readAsBytes(), bytes);
    });
  }
}
