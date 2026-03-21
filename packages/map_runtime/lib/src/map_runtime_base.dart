import 'package:flame/components.dart';
import 'package:map_core/map_core.dart';

class MapRuntime extends Component {
  final MapData mapData;
  final TilesetConfig tileset;

  MapRuntime({
    required this.mapData,
    required this.tileset,
  });

  @override
  Future<void> onLoad() async {
    // Basic processing of layers
    for (final layer in mapData.layers) {
      layer.map(
        tile: (l) => _loadTileLayer(l),
        collision: (l) => _loadCollisionLayer(l),
        object: (l) => _loadObjectLayer(l),
      );
    }
  }

  void _loadTileLayer(TileLayer layer) {}
  void _loadCollisionLayer(CollisionLayer layer) {}
  void _loadObjectLayer(ObjectLayer layer) {}
}
