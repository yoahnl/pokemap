import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:test/test.dart';

import '../support/game_package_fixture.dart';

void main() {
  test('advertises the canonical project format understood by the runtime', () {
    final compatibility = aveluneHostCompatibility();

    expect(compatibility.supportedProjectFormats, <String>{
      ProjectVersion.v8.name,
      ProjectVersion.v9.name,
    });
    expect(compatibility.currentProjectFormat, ProjectVersion.v8.name);
    expect(compatibility.currentProjectFormats, {
      ProjectVersion.v8.name,
      ProjectVersion.v9.name,
    });
    expect(compatibility.capabilities, contains('map3d@1'));
    expect(compatibility.capabilities, contains('map3d.animation@1'));
    expect(
      compatibility.capabilities,
      contains(SpatialGameplayCapabilities.capabilityId),
    );
  });

  test('accepts a package using the current v8 project format', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'avelune-v8-package-',
    );
    addTearDown(() => temporary.delete(recursive: true));
    final package = await writeTestPackage(
      temporary,
      minHubVersion: '0.1.0',
      projectFormat: ProjectVersion.v8.name,
    );

    final inspection = GamePackageInspector(
      hostCompatibility: aveluneHostCompatibility(),
    ).inspect(await package.readAsBytes());

    expect(
      inspection.compatibility?.decision,
      GamePackageCompatibilityDecision.accept,
    );
  });
}
