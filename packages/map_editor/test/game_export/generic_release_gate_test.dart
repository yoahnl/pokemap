import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/game_export.dart';

import 'game_export_test_fixture.dart';

void main() {
  test('one generic gate exports unrelated neutral projects', () async {
    const service = GamePackageExportService();
    final forest = await createAuthorProject(
      withDialogue: false,
      name: 'Forest Quest',
    );
    final desert = await createAuthorProject(
      withDialogue: false,
      name: 'Desert Quest',
    );
    addTearDown(() async {
      await forest.delete(recursive: true);
      await desert.delete(recursive: true);
    });

    final forestArtifact = await service.build(
      projectRoot: forest,
      profile: neutralExportProfile(
        gameId: 'games.example.forest',
        title: 'Forest Quest',
      ),
    );
    final desertArtifact = await service.build(
      projectRoot: desert,
      profile: neutralExportProfile(
        gameId: 'games.example.desert',
        title: 'Desert Quest',
        version: '2.0.0',
      ),
    );

    expect(forestArtifact.certification.isCertified, isTrue);
    expect(desertArtifact.certification.isCertified, isTrue);
    expect(
      forestArtifact.manifest.content.treeSha256,
      isNot(desertArtifact.manifest.content.treeSha256),
    );
    expect(
      forestArtifact.inspection.payloadPaths,
      isNot(contains('runtime_host_launch_save.json')),
    );
  });
}
