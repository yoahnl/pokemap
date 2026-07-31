import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('MapLayerKind exposes the existing Surface layer contract', () {
    expect(MapLayerKind.surface.name, 'surface');
    expect(
      const MapLayer.surface(id: 'surface', name: 'Forest surface'),
      isA<SurfaceLayer>(),
    );
  });
}
