import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/path_studio/path_studio_fr_copy.dart';

void main() {
  group('path_studio_fr_copy', () {
    test('pluralizeFr uses singular for 0 and 1', () {
      expect(pluralizeFr(0, 'blocage', 'blocages'), '0 blocage');
      expect(pluralizeFr(1, 'blocage', 'blocages'), '1 blocage');
      expect(pluralizeFr(2, 'blocage', 'blocages'), '2 blocages');
      expect(pluralizeFr(1, 'frame', 'frames'), '1 frame');
      expect(pluralizeFr(2, 'frame', 'frames'), '2 frames');
    });

    test('formatDiagnosticsSeveritySummary omits zero segments', () {
      expect(
        formatDiagnosticsSeveritySummary(
          blocking: 0,
          warning: 1,
          info: 2,
        ),
        '1 warning · 2 infos',
      );
      expect(
        formatDiagnosticsSeveritySummary(
          blocking: 1,
          warning: 0,
          info: 0,
        ),
        '1 blocage',
      );
    });
  });
}
