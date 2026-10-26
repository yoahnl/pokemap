import 'dart:convert';

import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'support/game_package_contract_fixtures.dart';

void main() {
  test('retains the Studio 0.3.31 baseline contracts', () {
    final host = AveluneRuntimeCompatibility.host();

    expect(AveluneRuntimeCompatibility.studioBaseline, '0.3.31+331');
    expect(host.supportedProjectFormats, containsAll({'v8', 'v9'}));
    expect(host.currentProjectFormats, containsAll({'v8', 'v9'}));
    expect(host.supportedSaveFormats, contains(2));
    expect(host.supportedRuntimeApiVersions, contains(Version.parse('1.4.0')));
    expect(
        host.capabilities,
        containsAll({
          'battle.demonstration@1',
          'catalog.partitioned@2',
          'dialogue.choices@1',
          'game.completion-party-journal@1',
          'map3d.animation@1',
          'map3d.actor-occlusion@1',
          'map3d.camera-orthographic@1',
          'map3d.cinematic-connected@1',
          'map3d.day-night@1',
          'map3d.directional-ledges@1',
          'map3d.entity-models@1',
          'map3d.fractional-ramps@1',
          'map3d.gameplay@1',
          'map3d.model-clip@1',
          'map3d.party-companion@1',
          'map3d.point-light-shadows@1',
          'map3d.point-light@1',
          'map3d.scene-audio@1',
          'map3d.scene-music@1',
          'map3d.shadows@1',
          'map3d.story@1',
          'map3d.terrain-appearance@1',
          'map3d.terrain-surfaces@1',
          'map3d@1',
          'map@1',
          'overworld.menu@1',
          'project.contact-device@1',
          'world.shop@1',
        }));
    expect(() => host.supportedProjectFormats.clear(), throwsUnsupportedError);
    expect(() => host.capabilities.clear(), throwsUnsupportedError);
  });

  test('an explicitly retained API contract survives a newer engine version',
      () {
    final original = AveluneRuntimeCompatibility.host();
    final upgraded = GamePackageHostCompatibility(
      hubVersion: Version.parse('3.0.0'),
      runtimeApiVersion: Version.parse('2.0.0'),
      supportedRuntimeApiVersions: {
        ...original.supportedRuntimeApiVersions,
        Version.parse('2.0.0'),
      },
      capabilities: original.capabilities,
      supportedProjectFormats: original.supportedProjectFormats,
      currentProjectFormat: original.currentProjectFormat,
      currentProjectFormats: original.currentProjectFormats,
      supportedSaveFormats: original.supportedSaveFormats,
    );
    final manifest = const GamePackageManifestCodec().decodeJson(
      jsonDecode(gamePackageContractFixture(
        'contracts/examples/minimal-valid/game-manifest.json',
      ).readAsStringSync()) as Map<String, dynamic>,
    );

    expect(
      const GamePackageCompatibilityEvaluator().evaluate(
        manifest,
        GamePackageHostCompatibility(
          hubVersion: upgraded.hubVersion,
          runtimeApiVersion: upgraded.runtimeApiVersion,
          supportedRuntimeApiVersions: upgraded.supportedRuntimeApiVersions,
          capabilities: manifest.compatibility.requiredCapabilities.toSet(),
          supportedProjectFormats: {manifest.compatibility.projectFormat},
          currentProjectFormat: manifest.compatibility.projectFormat,
          supportedSaveFormats: {manifest.compatibility.saveFormat},
        ),
      ),
      const GamePackageCompatibilityResult.accept(),
    );
  });

  test('future API contracts remain rejected until explicitly implemented', () {
    final current = AveluneRuntimeCompatibility.host();
    final oldHost = GamePackageHostCompatibility(
      hubVersion: current.hubVersion,
      runtimeApiVersion: current.runtimeApiVersion,
      capabilities: current.capabilities,
      supportedProjectFormats: current.supportedProjectFormats,
      currentProjectFormat: current.currentProjectFormat,
      supportedSaveFormats: current.supportedSaveFormats,
    );
    expect(oldHost.supportedRuntimeApiVersions, {current.runtimeApiVersion});
    expect(
      () => GamePackageHostCompatibility(
        hubVersion: current.hubVersion,
        runtimeApiVersion: current.runtimeApiVersion,
        supportedRuntimeApiVersions: {Version.parse('2.0.0')},
        capabilities: current.capabilities,
        supportedProjectFormats: current.supportedProjectFormats,
        currentProjectFormat: current.currentProjectFormat,
        supportedSaveFormats: current.supportedSaveFormats,
      ),
      throwsArgumentError,
    );
  });
}
