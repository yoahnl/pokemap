import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const contour = [
  GridPos(x: 0, y: 0),
  GridPos(x: 1, y: 0),
  GridPos(x: 2, y: 0),
  GridPos(x: 2, y: 1),
  GridPos(x: 1, y: 1),
  GridPos(x: 1, y: 2),
  GridPos(x: 0, y: 2),
  GridPos(x: 0, y: 1),
];

void main() {
  test('directed contours keep explicit edges at neighboring return sections', () {
    final stroke = canonicalizeBorderStrokeV1(
        id: 'contour', sampledPoints: contour, closed: true, preserveTraversal: true);
    expect(stroke.points, contour);
  });

  test('directed lattice does not infer an edge from neighboring sections', () {
    final lattice = buildBorderLinearLatticeV1(
        stroke: BorderStroke(id: 'contour', points: contour, closed: true),
        tileSizePx: const GridSize(width: 32, height: 32), preserveTraversal: true);
    expect(lattice.nodes.map((node) => node.cell), contour);
    expect(lattice.edges, hasLength(8));
    expect(lattice.totalLengthPx, 256);
    expect(lattice.edges.any((edge) => edge.startCell == contour[1] && edge.endCell == contour[4]), isFalse);
  });

  test('undirected contours still reject ambiguous neighboring contacts', () {
    expect(() => canonicalizeBorderStrokeV1(id: 'contour', sampledPoints: contour, closed: true),
        throwsA(isA<ValidationException>()));
  });

  test('directed contours still reject a repeated crossing vertex', () {
    expect(() => canonicalizeBorderStrokeV1(id: 'crossing', sampledPoints: const [
      GridPos(x: 0, y: 0), GridPos(x: 2, y: 0), GridPos(x: 2, y: 2),
      GridPos(x: 1, y: 2), GridPos(x: 1, y: -1),
    ], closed: false, preserveTraversal: true), throwsA(isA<ValidationException>()));
  });

  test('erasing a directed return contour preserves valid fragment lineage', () {
    final geometry = BorderStrokeGeometry(strokes: [BorderStroke(id: 'contour', points: contour, closed: true)]);
    final draft = BorderStrokeEditingDraft.begin(baseGeometry: geometry,
        mode: BorderStrokeEditingMode.erase, pointerDown: contour.first, preserveTraversal: true);
    final erased = draft.previewGeometry!;
    expect(erased.strokes, hasLength(1));
    expect(erased.strokes.single.points, contour.skip(1));
    final lattice = buildBorderLinearLatticeV1(stroke: erased.strokes.single, tileSizePx: const GridSize(width: 32, height: 32));
    expect(lattice.nodes, hasLength(7));
    expect(resolveBorderStrokeLineageIdentityV1(erased.strokes.single).preserveTraversal, isTrue);
  });
}
