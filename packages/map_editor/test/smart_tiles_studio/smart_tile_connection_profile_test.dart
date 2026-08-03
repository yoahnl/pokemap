import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_connection_profile.dart';

void main() {
  test('projects the six approved no-code families onto core contracts', () {
    expect(
      smartTileConnectionProfiles.map((profile) => profile.label),
      <String>[
        'Sans raccords',
        'Bordures',
        'Coins',
        'Formes organiques',
        'Bordures + coins',
        'Sur mesure',
      ],
    );
    expect(
      smartTileConnectionProfileById(SmartTileConnectionProfileId.none)
          .resolve()
          .topology,
      SmartTileTopology.uniform,
    );
    expect(
      smartTileConnectionProfileById(SmartTileConnectionProfileId.borders)
          .resolve()
          .topology,
      SmartTileTopology.wangEdge4,
    );
    expect(
      smartTileConnectionProfileById(SmartTileConnectionProfileId.corners)
          .resolve()
          .topology,
      SmartTileTopology.wangCorner4,
    );
    expect(
      smartTileConnectionProfileById(SmartTileConnectionProfileId.organic)
          .resolve()
          .topology,
      SmartTileTopology.blob8,
    );
    expect(
      smartTileConnectionProfileById(
        SmartTileConnectionProfileId.bordersAndCorners,
      ).resolve().topology,
      SmartTileTopology.wang8,
    );
  });

  test('recommends exactly one initial family for every usage', () {
    expect(
      recommendedSmartTileConnectionProfile(SmartTileUsage.terrain).id,
      SmartTileConnectionProfileId.borders,
    );
    expect(
      recommendedSmartTileConnectionProfile(SmartTileUsage.path).id,
      SmartTileConnectionProfileId.organic,
    );
    expect(
      recommendedSmartTileConnectionProfile(SmartTileUsage.forestSurface).id,
      SmartTileConnectionProfileId.organic,
    );
  });

  test('all three usages can intentionally select every family', () {
    for (final usage in SmartTileUsage.values) {
      for (final profile in smartTileConnectionProfiles) {
        final configuration = profile.resolve(
          customTopology: profile.id == SmartTileConnectionProfileId.custom
              ? SmartTileTopology.cardinal4
              : null,
        );
        expect(configuration.topology, isNotNull,
            reason: '$usage/${profile.id}');
        expect(
          configuration.templateHint,
          profile.id == SmartTileConnectionProfileId.custom
              ? SmartTileTemplateHint.free
              : isNotNull,
        );
      }
    }
  });

  test('custom family refuses to guess its topology', () {
    final custom = smartTileConnectionProfileById(
      SmartTileConnectionProfileId.custom,
    );

    expect(custom.resolve, throwsArgumentError);
  });
}
