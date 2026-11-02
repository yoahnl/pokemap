import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final extended in [false, true]) {
    test('export declares the canvas capability only when used: $extended', () async {
      final root = await Directory.systemTemp.createTemp('canvas-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      final project = ProjectManifest.fromJson(jsonDecode(utf8.decode(files['project/project.json']!)));
      files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(
        characters: [for (final character in project.characters) character.copyWith(
          animations: [for (final animation in character.animations) animation.copyWith(
            presentationReferenceHeightPx: extended ? 32 : null,
          )],
        )],
      ).toJson()));
      for (final entry in files.entries) {
        final file = File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final artifact = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: GamePackageExportProfile(gameId: 'games.example.canvas',
          gameVersion: '0.1.0', title: 'Canvas', authorName: 'Yoahn',
          defaultLocale: 'fr', supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest,
      );
      expect(artifact.manifest.compatibility.requiredCapabilities.contains(
        CharacterAnimationCanvasCapabilities.capabilityId), extended);
      for (final entry in files.entries) {
        expect(await File('${root.path}/${entry.key.substring('project/'.length)}').readAsBytes(), entry.value);
      }
    });
  }
}
