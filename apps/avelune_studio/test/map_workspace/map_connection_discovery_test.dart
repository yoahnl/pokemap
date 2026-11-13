import 'package:avelune_studio/features/map_workspace/application/map_workspace_connection_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'border offsets accept signed integer cells and refuse fractional input',
    () {
      expect(mapConnectionOffset(' -3 '), -3);
      expect(mapConnectionOffset('0'), 0);
      for (final invalid in ['1.5', 'NaN', 'Infinity', 'wrong']) {
        expect(mapConnectionOffset(invalid), isNull);
      }
    },
  );
}
