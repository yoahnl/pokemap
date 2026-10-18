import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/infrastructure/repositories/journaled_file_promotion_repository.dart';

void main() {
  for (final name in ['alpha', 'beta']) {
    test(
      'promotion locks and writes only the declared $name project',
      () async {
        final root = await Directory.systemTemp.createTemp('promotion-scope-');
        addTearDown(() => root.delete(recursive: true));
        final project = File('${root.path}/$name/project.json');
        await project.parent.create(recursive: true);
        await project.writeAsString('{"name":"$name"}');
        final other = File('${root.path}/other/project.json');
        await other.parent.create(recursive: true);
        await other.writeAsString('untouched');
        final fixture = Directory('${root.path}/fixture');
        await fixture.create();
        final after = utf8.encode('{"name":"$name updated"}');
        await File('${fixture.path}/after.json').writeAsBytes(after);
        final manifest = File('${fixture.path}/promotion.json');
        await manifest.writeAsString(
          jsonEncode({
            'schemaVersion': 1,
            'state': 'frozenForJ5',
            'orderedFiles': [
              {
                'order': 1,
                'source': 'after.json',
                'destination': '$name/project.json',
                'beforeExists': true,
                'beforeSha256': narrativeEventBytesFingerprint(
                  await project.readAsBytes(),
                ),
                'afterSha256': narrativeEventBytesFingerprint(after),
              },
            ],
          }),
        );
        final repository = JournaledFilePromotionRepository(
          repositoryRoot: root.path,
          projectManifestPath: project.path,
          manifestPath: manifest.path,
          allowedDestinations: {'$name/project.json'},
        );
        expect(repository.projectManifestPath, project.path);
        expect(repository.journalPath, startsWith('${project.parent.path}/'));
        final result = await repository.promote();
        expect(
          result.status,
          JournaledFilePromotionStatus.promoted,
          reason: '${result.code}: ${result.message}',
        );
        expect(await project.readAsBytes(), after);
        expect(await other.readAsString(), 'untouched');
        expect(
          (await repository.promote()).status,
          JournaledFilePromotionStatus.noOp,
        );
      },
    );
  }

  test('another project cannot be included in the destination policy', () {
    expect(
      () => JournaledFilePromotionRepository(
        repositoryRoot: '/tmp/promotion-root',
        projectManifestPath: '/tmp/promotion-root/alpha/project.json',
        manifestPath: '/tmp/promotion-root/fixture/promotion.json',
        allowedDestinations: {'beta/project.json'},
      ),
      throwsArgumentError,
    );
  });

  test('a journal cannot escape the declared project', () {
    expect(
      () => JournaledFilePromotionRepository(
        repositoryRoot: '/tmp/promotion-root',
        projectManifestPath: '/tmp/promotion-root/alpha/project.json',
        manifestPath: '/tmp/promotion-root/fixture/promotion.json',
        allowedDestinations: {'alpha/project.json'},
        journalPath: '/tmp/promotion-root/beta/journal.json',
      ),
      throwsArgumentError,
    );
  });

  test('a symbolic project is refused before acquiring its lock', () async {
    final root = await Directory.systemTemp.createTemp('promotion-link-');
    final external = await Directory.systemTemp.createTemp(
      'promotion-external-',
    );
    addTearDown(() => root.delete(recursive: true));
    addTearDown(() => external.delete(recursive: true));
    await File('${external.path}/project.json').writeAsString('untouched');
    await Link('${root.path}/alpha').create(external.path);
    final repository = JournaledFilePromotionRepository(
      repositoryRoot: root.path,
      projectManifestPath: '${root.path}/alpha/project.json',
      manifestPath: '${root.path}/fixture.json',
      allowedDestinations: {'alpha/project.json'},
    );
    final result = await repository.promote();
    expect(result.status, JournaledFilePromotionStatus.blocked);
    expect(result.code, 'promotionSymlinkRefused');
    expect(await external.list().length, 1);
    expect(
      await File('${external.path}/project.json').readAsString(),
      'untouched',
    );
  });
}
