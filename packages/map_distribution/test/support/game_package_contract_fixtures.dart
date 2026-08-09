import 'dart:io';
import 'dart:isolate';

final Directory gamePackageContractFixtureRoot = Directory.fromUri(
  Isolate.resolvePackageUriSync(
    Uri.parse('package:map_distribution/map_distribution.dart'),
  )!
      .resolve('../test/fixtures/game_package_contract/'),
);

File gamePackageContractFixture(String relativePath) {
  final file = File.fromUri(
    gamePackageContractFixtureRoot.uri.resolve(relativePath),
  );
  if (!file.existsSync()) {
    throw StateError('Missing game package contract fixture: $relativePath');
  }
  return file;
}

Directory gamePackageContractFixtureDirectory(String relativePath) =>
    Directory.fromUri(
      gamePackageContractFixtureRoot.uri.resolve(
        relativePath.endsWith('/') ? relativePath : '$relativePath/',
      ),
    );
