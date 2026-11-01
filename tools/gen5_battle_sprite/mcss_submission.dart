import 'mcss_bin.dart';
import 'mcss_pose.dart';

final class Gen5McssSubmission {
  const Gen5McssSubmission({
    required this.nodeIndex,
    required this.quad,
    required this.depth,
    required this.polygonId,
    required this.textureY,
  });

  final int nodeIndex;
  final Gen5McssQuad quad;
  final int depth;
  final int polygonId;
  final int textureY;
}

List<Gen5McssSubmission> planGen5McssSubmission(
  List<Gen5McssActiveNode> nodes, {
  required int alpha,
  required bool reverse,
  bool ortho = false,
  bool orthoNear = false,
  bool flipV = false,
  bool forcePolygonZero = false,
  int cellDepth = 0,
}) {
  RangeError.checkValueInInterval(alpha, 0, 31, 'alpha');
  final reverseTraversal = alpha != 31 || reverse;
  final step = ortho
      ? (orthoNear ? 256 : 1024)
      : (cellDepth == 0 ? 256 : cellDepth);
  var depth = 0;
  final output = <Gen5McssSubmission>[];
  for (var ordinal = 0; ordinal < nodes.length; ordinal++) {
    final index = reverseTraversal ? nodes.length - ordinal - 1 : ordinal;
    final cell = nodes[index].cell;
    final quads = <(Gen5McssQuad, bool)>[
      if (!reverse && cell.secondary.width != 0) (cell.secondary, true),
      (cell.primary, false),
      if (reverse && cell.secondary.width != 0) (cell.secondary, true),
    ];
    for (final (quad, isSecondary) in quads) {
      output.add(
        Gen5McssSubmission(
          nodeIndex: index,
          quad: quad,
          depth: depth,
          polygonId: alpha == 31 || forcePolygonZero ? 0 : index.clamp(0, 63),
          textureY: quad.textureY + (isSecondary && flipV ? quad.height : 0),
        ),
      );
      depth += reverseTraversal ? step : -step;
    }
  }
  return List.unmodifiable(output);
}
