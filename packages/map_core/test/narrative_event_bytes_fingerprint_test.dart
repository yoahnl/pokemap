import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('NS-EVENT-V2 Phase E hashes raw project bytes with SHA-256', () {
    expect(
      narrativeEventBytesFingerprint(const [0, 1, 2, 255]),
      'sha256:3d1f57c984978ef98a18378c8166c1cb8ede02c03eeb6aee7e2f121dfeee3e56',
    );
  });
}
