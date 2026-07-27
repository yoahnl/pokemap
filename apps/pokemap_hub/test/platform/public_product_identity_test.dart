import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/src/platform/public_product_identity.dart';

void main() {
  test('mobile players use the Avelune public product name', () {
    expect(publicProductNameForOperatingSystem('android'), 'Avelune');
    expect(publicProductNameForOperatingSystem('ios'), 'Avelune');
  });

  test('desktop Hub keeps its authoring ecosystem name', () {
    expect(publicProductNameForOperatingSystem('macos'), 'PokeMap Hub');
    expect(publicProductNameForOperatingSystem('windows'), 'PokeMap Hub');
    expect(publicProductNameForOperatingSystem('linux'), 'PokeMap Hub');
  });
}
