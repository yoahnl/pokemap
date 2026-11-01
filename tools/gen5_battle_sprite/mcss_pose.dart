import 'mcss_bin.dart';
import 'multicell.dart';

final class Gen5McssActiveNode {
  const Gen5McssActiveNode(this.node, this.cell);

  final Gen5ActiveNode node;
  final Gen5McssCell cell;
}

List<Gen5McssActiveNode> resolveGen5McssNodes(
  List<Gen5ActiveNode> nodes,
  List<Gen5McssCell> cells,
) {
  final resolved = <Gen5McssActiveNode>[];
  for (final node in nodes) {
    final index = node.cellIndex;
    if (index < 0 || index >= cells.length) {
      throw const FormatException('Invalid MCSS cell reference');
    }
    resolved.add(Gen5McssActiveNode(node, cells[index]));
  }
  return List.unmodifiable(resolved);
}
