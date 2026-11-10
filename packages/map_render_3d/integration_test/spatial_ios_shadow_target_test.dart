import 'dart:io';

import 'package:flame_3d/graphics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_render_3d/src/spatial_shadow_target.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iOS shadow targets retain antialiasing without float MSAA', (
    tester,
  ) async {
    await GpuBackend.initialize();
    final backend = GpuBackend.instance;

    final shadow = SpatialShadowTarget(backend, width: 64, height: 64);
    expect(shadow.samples, 4);
    expect(shadow.supersampled, isTrue);
    expect(shadow.multisampled, isFalse);
    expect(shadow.texture, same(shadow.target.colorTexture));

    final noAntialiasing = SpatialShadowTarget(
      backend,
      width: 64,
      height: 64,
      antialiasing: false,
    );
    expect(noAntialiasing.samples, 1);
    expect(noAntialiasing.supersampled, isFalse);
    expect(noAntialiasing.texture, same(noAntialiasing.target.colorTexture));
  }, skip: !Platform.isIOS);
}
