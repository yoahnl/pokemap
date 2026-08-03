import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tiles_studio_availability.dart';

void main() {
  group('SmartTilesStudioAvailability', () {
    test('keeps STN-04 hidden while canonical boundaries are incomplete', () {
      const availability = SmartTilesStudioAvailability.stn04Baseline;

      expect(availability.isReady, isFalse);
      expect(
        availability.missingCapabilities,
        SmartTilesStudioCapability.values.toSet(),
      );
    });

    test('becomes ready only when every canonical boundary is available', () {
      const availability = SmartTilesStudioAvailability(
        durableDrafts: true,
        canonicalPublication: true,
        smartTilesOnlyProject: true,
      );

      expect(availability.isReady, isTrue);
      expect(availability.missingCapabilities, isEmpty);
    });
  });
}
