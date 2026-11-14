import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

List<GridPos> _points(List<(int, int)> raw) => [
  for (final (x, y) in raw) GridPos(x: x, y: y),
];

BorderStrokeGeometry _geometry(BorderStroke stroke) => BorderStrokeGeometry(
  strokes: [stroke],
  alignment: BorderStrokeAlignment.gridEdges,
);

bool Function(GridPos, GridPos) _edge(GridPos a, GridPos b) =>
    (p, q) => (p == a && q == b) || (p == b && q == a);

void main() {
  test('cutting one edge of an open stroke keeps both sides', () {
    final source = BorderStroke(
      id: 'cliff',
      points: _points([(0, 4), (1, 4), (2, 4), (3, 4), (4, 4)]),
      closed: false,
    );
    final cut = cutBorderStrokeEdges(
      _geometry(source),
      _edge(const GridPos(x: 2, y: 4), const GridPos(x: 3, y: 4)),
    );
    expect(cut.strokes.map((s) => s.points), [
      _points([(0, 4), (1, 4), (2, 4)]),
      _points([(3, 4), (4, 4)]),
    ]);
    expect(cut.strokes.map((s) => borderStrokeAuthoredIdV1(s.id)), [
      'cliff',
      'cliff__fragment_2',
    ]);
    final second = resolveBorderStrokeLineageIdentityV1(cut.strokes.last);
    expect(second.sourceEdgeOffset, 3);
    expect(second.lineageNamespace, 'cliff');
  });

  test('cutting a closed loop opens it at the cut', () {
    final source = BorderStroke(
      id: 'loop',
      points: _points([(2, 2), (3, 2), (4, 2), (4, 3), (3, 3), (2, 3)]),
      closed: true,
    );
    final cut = cutBorderStrokeEdges(
      _geometry(source),
      _edge(const GridPos(x: 4, y: 3), const GridPos(x: 3, y: 3)),
    );
    expect(cut.strokes.single.closed, isFalse);
    expect(
      cut.strokes.single.points,
      _points([(3, 3), (2, 3), (2, 2), (3, 2), (4, 2), (4, 3)]),
    );
  });

  test('untouched strokes stay identical and fully cut strokes vanish', () {
    final source = BorderStroke(
      id: 'short',
      points: _points([(5, 5), (6, 5)]),
      closed: false,
    );
    final geometry = _geometry(source);
    expect(
      cutBorderStrokeEdges(
        geometry,
        _edge(const GridPos(x: 0, y: 0), const GridPos(x: 1, y: 0)),
      ),
      same(geometry),
    );
    expect(
      cutBorderStrokeEdges(
        geometry,
        _edge(const GridPos(x: 5, y: 5), const GridPos(x: 6, y: 5)),
      ).strokes,
      isEmpty,
    );
  });
}
