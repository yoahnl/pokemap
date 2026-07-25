import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('library round-trips 100 independent games inside the reference guard',
      () async {
    final root =
        await Directory.systemTemp.createTemp('pokemap-phase8-library-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final games = <InstalledGame>[
      for (var index = 0;
          index < ProductCertificationBudgets.libraryGameCount;
          index++)
        _installedGame(index),
    ];
    final store = GameLibraryStore(supportRoot: root);
    final watch = Stopwatch()..start();

    await store.save(
      GameLibrary(
        revision: 1,
        updatedAt: DateTime.utc(2026, 7, 25),
        games: games,
      ),
    );
    final reopened = await GameLibraryStore(supportRoot: root).load();
    watch.stop();
    final measurement = ProductCertificationMeasurement.evaluate(
      id: 'library-100-roundtrip',
      elapsed: watch.elapsed,
      budget: ProductCertificationBudgets.libraryLoad,
    );

    expect(reopened.library.games, hasLength(100));
    expect(reopened.library.games.first.gameId, 'games.certification.game000');
    expect(reopened.library.games.last.gameId, 'games.certification.game099');
    expect(measurement.passed, isTrue, reason: measurement.toJson().toString());
  });

  test('export and hostile reopen cover a 2000-entry species catalogue',
      () async {
    final root =
        await Directory.systemTemp.createTemp('pokemap-phase8-catalog-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final authorRoot = Directory(p.join(root.path, 'author'));
    final fixture = NeutralCertificationGameFixture();
    await fixture.writeAuthorWorkspace(authorRoot);
    await fixture.writeSpeciesCatalog(
      authorRoot,
      count: ProductCertificationBudgets.speciesCatalogCount,
    );
    final watch = Stopwatch()..start();

    final artifact = await fixture.export(
      authorRoot,
      File(p.join(root.path, 'catalog.pokemapgame')),
    );
    watch.stop();
    final measurement = ProductCertificationMeasurement.evaluate(
      id: 'catalog-2000-export-inspect',
      elapsed: watch.elapsed,
      budget: ProductCertificationBudgets.catalogExportAndInspection,
    );

    expect(artifact.certification.isCertified, isTrue);
    expect(
      artifact.manifest.content.files
          .where((entry) => entry.path.contains('/species/')),
      hasLength(ProductCertificationBudgets.speciesCatalogCount),
    );
    expect(measurement.passed, isTrue, reason: measurement.toJson().toString());
  });
}

InstalledGame _installedGame(int index) {
  final suffix = index.toString().padLeft(3, '0');
  final digest = index.toRadixString(16).padLeft(64, '0');
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.0.0'),
    treeSha256: digest,
    installedAt: DateTime.utc(2026, 7, 25),
    receiptFileName: '1.0.0-$digest.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return InstalledGame(
    gameId: 'games.certification.game$suffix',
    title: 'Certification Game $suffix',
    authorName: 'PokeMap',
    defaultLocale: 'en',
    supportedLocales: const <String>['en'],
    current: version.pointer,
    versions: <InstalledGameVersion>[version],
  );
}
