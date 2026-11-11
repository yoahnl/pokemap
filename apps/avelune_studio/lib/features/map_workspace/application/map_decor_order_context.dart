import 'package:map_core/map_core_domain.dart';

final class MapDecorOrderContext {
  MapDecorOrderContext({
    required this.instanceId,
    required this.target,
    required this.position,
    required this.pixelPosition,
    required List<MapPlacedElement> stack,
    required List<MapPlacedElement> reorderable,
    required List<MapPlacedElement> other,
    required this.forwardProblem,
    required this.backwardProblem,
  }) : stack = List.unmodifiable(stack),
       reorderable = List.unmodifiable(reorderable),
       other = List.unmodifiable(other);

  final String instanceId;
  final MapPlacedElement? target;
  final GridPos position;
  final PixelPosition? pixelPosition;
  final List<MapPlacedElement> stack, reorderable, other;
  final String? forwardProblem, backwardProblem;

  int get rank => reorderable.indexWhere((element) => element.id == instanceId);
}
