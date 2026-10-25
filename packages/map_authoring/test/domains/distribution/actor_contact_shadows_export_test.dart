import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final (projectDefault, override, required) in [
    (false, null, false),
    (true, null, true),
    (true, false, false),
    (false, true, true),
  ]) {
    test(
        'actor contact export derives $projectDefault/$override, roundtrips and preserves source',
        () async {
      final root =
          await Directory.systemTemp.createTemp('actor-contact-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      final project = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(files['project/project.json']!)));
      files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(
        settings: project.settings
            .copyWith(actorContactShadowsByDefault: projectDefault),
        characters: [
          for (final character in project.characters)
            character.copyWith(contactShadow: override)
        ],
      ).toJson()));
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final before = await File('${root.path}/project.json').readAsBytes();
      final result = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: GamePackageExportProfile(
            gameId: 'games.example.actorcontact',
            gameVersion: '0.1.0',
            title: 'Actor contacts',
            authorName: 'Yoahn',
            defaultLocale: 'fr',
            supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest,
      );
      expect(
          result.manifest.compatibility.requiredCapabilities
              .contains('map3d.actor-contact-shadows@1'),
          required);
      final archive = ZipDecoder().decodeBytes(result.packageBytes);
      final packed = archive.files
          .singleWhere((file) => file.name == 'project/project.json');
      final decoded = PortableCatalogPublication.decodeProjectSync(
          jsonDecode(utf8.decode(packed.content)) as Map<String, dynamic>,
          readObject: (ref) => archive
              .findFile(
                  'project/${PortableCatalogPublication.objectPath(ref)}')!
              .content);
      expect(decoded.settings.actorContactShadowsByDefault, projectDefault);
      expect(decoded.characters.single.contactShadow, override);
      expect(await File('${root.path}/project.json').readAsBytes(), before);
    });
  }
}
