import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('ElementCollisionProfile JSON supports pixelMask', () {
    final mask = ElementCollisionPixelMask(
      widthPx: 16,
      heightPx: 16,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: 16,
        heightPx: 16,
        solidPixels: List<bool>.filled(256, false),
      ),
    );
    final profile = ElementCollisionProfile(
      source: ElementCollisionProfileSource.generated,
      pixelMask: mask,
      padding: const WarpTriggerPadding(top: 1),
      cells: const [GridPos(x: 0, y: 0)],
    );
    final decoded = ElementCollisionProfile.fromJson(profile.toJson());
    expect(decoded.pixelMask, isNotNull);
    expect(decoded.pixelMask!.widthPx, 16);
    expect(decoded.padding.top, 1);
    expect(decoded.cells, const [GridPos(x: 0, y: 0)]);
  });
}
