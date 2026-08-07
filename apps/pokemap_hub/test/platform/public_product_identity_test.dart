import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/core/config/public_product_identity.dart';

void main() {
  test('every platform shows the Avelune identity', () {
    for (final os in <String>[
      'android',
      'ios',
      'macos',
      'windows',
      'linux',
    ]) {
      expect(
        publicProductNameForOperatingSystem(os),
        'Avelune',
        reason: 'Desktop renders the same console as mobile, so it carries the '
            'same name. Only the distribution bundle name stays PokeMap Hub.',
      );
    }
  });
}
