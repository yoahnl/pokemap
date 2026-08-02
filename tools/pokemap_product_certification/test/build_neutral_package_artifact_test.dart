import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  const configuredOutput = String.fromEnvironment(
    'POKEMAP_CERTIFICATION_OUTPUT',
  );

  test('builds the neutral package consumed by the release gate', () async {
    final temporaryRoot = configuredOutput.isEmpty
        ? await Directory.systemTemp.createTemp('pokemap-neutral-artifact-')
        : null;
    addTearDown(() async {
      if (temporaryRoot != null && await temporaryRoot.exists()) {
        await temporaryRoot.delete(recursive: true);
      }
    });
    final output = File(
      configuredOutput.isEmpty
          ? '${temporaryRoot!.path}/neutral-certification.pokemapgame'
          : configuredOutput,
    ).absolute;
    await output.parent.create(recursive: true);
    final authorRoot =
        await Directory.systemTemp.createTemp('pokemap-neutral-author-');
    addTearDown(() async {
      if (await authorRoot.exists()) {
        await authorRoot.delete(recursive: true);
      }
    });

    final fixture = NeutralCertificationGameFixture();
    await fixture.writeAuthorWorkspace(authorRoot);
    final artifact = await fixture.export(authorRoot, output);

    expect(await output.exists(), isTrue);
    expect(artifact.manifest.gameId, fixture.gameId);
    expect(artifact.manifest.gameVersion.toString(), fixture.gameVersion);
    expect(artifact.packageSha256, matches(RegExp(r'^[0-9a-f]{64}$')));
  });
}
