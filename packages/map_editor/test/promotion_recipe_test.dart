import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../tool/promote_project_fixture.dart' as cli;

void main() {
  for (final id in ['orchard', 'observatory']) {
    test(
      'an explicit $id promotion recipe changes only its declared project',
      () async {
        final root = await Directory.systemTemp.createTemp('promotion-recipe-');
        addTearDown(() => root.delete(recursive: true));
        final project = File('${root.path}/$id/project.json');
        await project.parent.create();
        await project.writeAsString(jsonEncode({'name': id}));
        final other = File('${root.path}/other/project.json');
        await other.parent.create();
        await other.writeAsString('protected');
        final fixture = Directory('${root.path}/fixture')..createSync();
        final after = utf8.encode(jsonEncode({'name': '$id authored'}));
        await File('${fixture.path}/after.json').writeAsBytes(after);
        await File('${fixture.path}/promotion.json').writeAsString(
          jsonEncode({
            'schemaVersion': 1,
            'state': 'frozenForJ5',
            'orderedFiles': [
              {
                'order': 1,
                'source': 'after.json',
                'destination': '$id/project.json',
                'beforeExists': true,
                'beforeSha256': narrativeEventBytesFingerprint(
                  await project.readAsBytes(),
                ),
                'afterSha256': narrativeEventBytesFingerprint(after),
              },
            ],
          }),
        );
        final recipe = File('${root.path}/recipe.json');
        final data = {
          'schemaVersion': 1,
          'id': id,
          'projectManifest': '$id/project.json',
          'promotionManifest': 'fixture/promotion.json',
          'allowedDestinations': ['$id/project.json'],
        };
        await recipe.writeAsString(jsonEncode(data));
        List<String> arguments(File target) => [
          '--repository-root',
          root.path,
          '--project',
          target.path,
          '--recipe',
          recipe.path,
        ];
        await expectLater(cli.main(arguments(other)), throwsFormatException);
        expect(await other.readAsString(), 'protected');
        await cli.main(arguments(project));
        expect(await project.readAsBytes(), after);
        await cli.main(arguments(project));
        expect(await project.readAsBytes(), after);
        expect(await other.readAsString(), 'protected');
        data['promotionManifest'] = '../outside.json';
        await recipe.writeAsString(jsonEncode(data));
        await expectLater(cli.main(arguments(project)), throwsFormatException);
        expect(await project.readAsBytes(), after);
        expect(await other.readAsString(), 'protected');
      },
    );
  }
}
