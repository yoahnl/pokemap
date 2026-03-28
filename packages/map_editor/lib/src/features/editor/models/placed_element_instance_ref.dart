import 'package:map_core/map_core.dart';

class PlacedElementInstanceRef {
  const PlacedElementInstanceRef({
    required this.layerId,
    required this.elementId,
    required this.pos,
  });

  final String layerId;
  final String elementId;
  final GridPos pos;

  String get id => encode(
        layerId: layerId,
        elementId: elementId,
        x: pos.x,
        y: pos.y,
      );

  static String encode({
    required String layerId,
    required String elementId,
    required int x,
    required int y,
  }) {
    return '${Uri.encodeComponent(layerId)}::${Uri.encodeComponent(elementId)}::$x::$y';
  }

  static PlacedElementInstanceRef? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final parts = raw.split('::');
    if (parts.length != 4) {
      return null;
    }
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) {
      return null;
    }
    final layerId = Uri.decodeComponent(parts[0]);
    final elementId = Uri.decodeComponent(parts[1]);
    if (layerId.isEmpty || elementId.isEmpty) {
      return null;
    }
    return PlacedElementInstanceRef(
      layerId: layerId,
      elementId: elementId,
      pos: GridPos(x: x, y: y),
    );
  }
}
