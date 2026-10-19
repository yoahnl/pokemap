import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_model_triangle_clip.dart';

const _renouetBoundaryTriangle = [
  SpatialModelClipVertex(x: -14.1875, y: -.125, z: -6, u: -5.125, v: 4.5078125),
  SpatialModelClipVertex(x: -11, y: -.125, z: -6, u: -1.98046875, v: 4.5078125),
  SpatialModelClipVertex(
    x: -11,
    y: -.125,
    z: -6.625,
    u: -1.98046875,
    v: 3.88671875,
    r: .929411769,
    g: .929411769,
    b: .858823538,
  ),
];

void main() {
  test('cuts a source triangle into the requested one-cell square', () {
    final result = clipSpatialModelTriangles(
      vertices: [_vertex(-1, 0, 0), _vertex(2, 0, 0), _vertex(-1, 0, 3)],
      indices: [0, 1, 2],
      material: 'original-material',
      clip: SpatialModelClipRect(left: 0, top: 0, right: 1, bottom: 1),
    );

    expect(_areaXZ(result), closeTo(1, 1e-12));
    expect(
      result.vertices.every(
        (vertex) =>
            vertex.x >= -1e-12 &&
            vertex.x <= 1 + 1e-12 &&
            vertex.z >= -1e-12 &&
            vertex.z <= 1 + 1e-12,
      ),
      isTrue,
    );
  });

  test('preserves source UVs, float RGBA and the opaque material binding', () {
    final material = Object();
    SpatialModelClipVertex vertex(double x, double z) => SpatialModelClipVertex(
      x: x,
      y: -.125,
      z: z,
      u: 3 * x - 2,
      v: 2 * z + 1,
      r: (x + 1) / 3,
      g: .670588255,
      b: .56078434,
      a: (z + 1) / 4,
      normal: (x: 0, y: 1, z: 0),
    );
    final result = clipSpatialModelTriangles(
      vertices: [vertex(-1, 0), vertex(2, 0), vertex(-1, 3)],
      indices: [0, 1, 2],
      material: material,
      clip: SpatialModelClipRect(left: 0, top: 0, right: 1, bottom: 1),
    );
    expect(identical(result.material, material), isTrue);
    for (final v in result.vertices) {
      expect(v.y, -.125);
      expect(v.u, closeTo(3 * v.x - 2, 1e-12));
      expect(v.v, closeTo(2 * v.z + 1, 1e-12));
      expect(v.r, closeTo((v.x + 1) / 3, 1e-12));
      expect(v.g, closeTo(.670588255, 1e-12));
      expect(v.b, closeTo(.56078434, 1e-12));
      expect(v.a, closeTo((v.z + 1) / 4, 1e-12));
      expect(v.normal, (x: 0.0, y: 1.0, z: 0.0));
    }
    expect(result.vertices.any((v) => v.u < 0), isTrue);
    expect(result.vertices.any((v) => v.v > 1), isTrue);
  });

  test('leaves contained vertices and triangle winding unchanged', () {
    final vertices = [
      _vertex(.1, 0, .1),
      _vertex(.9, 0, .1),
      _vertex(.1, 0, .9),
    ];
    final result = _clip(vertices, indices: [2, 1, 0]);
    expect(result.indices, [0, 1, 2]);
    expect(identical(result.vertices[0], vertices[2]), isTrue);
    expect(identical(result.vertices[1], vertices[1]), isTrue);
    expect(identical(result.vertices[2], vertices[0]), isTrue);
    expect(_signedAreaXZ(result), lessThan(0));
  });

  test('retains vertical triangles whose XZ area is zero', () {
    final result = _clip([
      _vertex(.5, 0, -1),
      _vertex(.5, 2, 2),
      _vertex(.5, 0, 2),
    ]);
    expect(result.indices, isNotEmpty);
    expect(_areaXZ(result), 0);
    expect(result.vertices.every((v) => v.x == .5), isTrue);
    expect(result.vertices.any((v) => v.y > 0), isTrue);
  });

  test('isolated clips retain vertical faces on their outer boundaries', () {
    for (final axis in [0, 2]) {
      final vertices = axis == 0
          ? [_vertex(1, 0, .1), _vertex(1, 2, .1), _vertex(1, 0, .9)]
          : [_vertex(.1, 0, 1), _vertex(.1, 2, 1), _vertex(.9, 0, 1)];
      final result = clipSpatialModelTriangles(
        vertices: vertices,
        indices: [0, 1, 2],
        material: 'wall',
        clip: SpatialModelClipRect(left: 0, top: 0, right: 1, bottom: 1),
      );
      expect(result.indices, hasLength(3));
      expect(result.vertices.every((v) => vertices.contains(v)), isTrue);
    }
  });

  test('separate integer-plane carriers admit disjoint half-cell windows', () {
    final vertices = [
      _vertex(0, 0, .1),
      _vertex(0, 2, .1),
      _vertex(0, 0, .9),
    ];
    final transform = <double>[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1];
    for (final left in [0.0, 1.0]) {
      final result = clipSpatialModelTriangles(
        vertices: vertices,
        indices: [0, 1, 2],
        material: 'wall',
        clip: SpatialModelClipRect(left: left, top: 0, right: left + .5, bottom: 1),
        nodeTransform: transform,
      );
      expect(result.indices.length, left == 0 ? 0 : 3);
      expect(result.vertices.every((v) => v.x == 0), isTrue);
    }
  });

  test('preserves both fractional source heights without rounding', () {
    for (final height in [-.125, -.1240234375]) {
      final result = _clip([
        _vertex(-1, height, 0),
        _vertex(2, height, 0),
        _vertex(-1, height, 3),
      ]);
      expect(result.vertices.every((v) => v.y == height), isTrue);
    }
  });

  test(
    'clips in transformed node space and returns original local attributes',
    () {
      final transform = <double>[
        2,
        0,
        -1,
        0,
        1,
        3,
        .25,
        0,
        0,
        .5,
        1,
        0,
        4,
        -2,
        1,
        1,
      ];
      final result = clipSpatialModelTriangles(
        vertices: [
          _vertex(-2, -.125, -2),
          _vertex(4, -.125, -2),
          _vertex(-2, -.125, 5),
        ],
        indices: [0, 1, 2],
        material: null,
        clip: SpatialModelClipRect(left: 3, top: 0, right: 5, bottom: 2),
        nodeTransform: transform,
      );
      expect(result.indices, isNotEmpty);
      for (final vertex in result.vertices) {
        final x = 2 * vertex.x + vertex.y + 4;
        final z = -vertex.x + .25 * vertex.y + vertex.z + 1;
        expect(x, inInclusiveRange(3 - 1e-12, 5 + 1e-12));
        expect(z, inInclusiveRange(-1e-12, 2 + 1e-12));
        expect(vertex.y, -.125);
        expect(vertex.u, closeTo(vertex.x * 3 - 2, 1e-12));
        expect(vertex.v, closeTo(vertex.z * 2 + 1, 1e-12));
      }
    },
  );

  test('keeps local winding under an affine reflection', () {
    final result = clipSpatialModelTriangles(
      vertices: [_vertex(-1, 0, 0), _vertex(2, 0, 0), _vertex(-1, 0, 3)],
      indices: [0, 1, 2],
      material: null,
      clip: SpatialModelClipRect(left: 0, top: 0, right: 1, bottom: 1),
      nodeTransform: [-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1],
    );
    expect(result.indices, isNotEmpty);
    expect(_signedAreaXZ(result), greaterThan(0));
  });

  test('interpolates normals with the original edge coefficients', () {
    SpatialModelClipVertex vertex(double x, double z) => SpatialModelClipVertex(
      x: x,
      y: 0,
      z: z,
      u: x,
      v: z,
      normal: (x: x / 3, y: 1, z: z / 3),
    );
    final result = _clip([vertex(-1, 0), vertex(2, 0), vertex(-1, 3)]);
    for (final vertex in result.vertices) {
      expect(vertex.normal!.x, closeTo(vertex.x / 3, 1e-12));
      expect(vertex.normal!.y, closeTo(1, 1e-12));
      expect(vertex.normal!.z, closeTo(vertex.z / 3, 1e-12));
    }
  });

  test('returns no geometry when the primitive is outside the clip', () {
    final result = _clip([
      _vertex(2, 0, 2),
      _vertex(3, 0, 2),
      _vertex(2, 0, 3),
    ]);
    expect(result.vertices, isEmpty);
    expect(result.indices, isEmpty);
  });

  test(
    'Renouet source triangle 35 cannot occupy cells beyond its Z boundary',
    () {
      for (final left in [-15.0, -14.0]) {
        final result = clipSpatialModelTriangles(
          vertices: _renouetBoundaryTriangle,
          indices: [0, 1, 2],
          material: 'fhyuka_1',
          clip: SpatialModelClipRect(
            left: left,
            top: -6,
            right: left + 1,
            bottom: -5,
          ),
        );
        expect(result.indices, isEmpty, reason: 'Empty source domain $left,-6');
        expect(result.vertices, isEmpty);
      }
    },
  );

  test('Renouet boundary interpolation preserves exact constant coordinates and fields', () {
    final result = clipSpatialModelTriangles(
      vertices: _renouetBoundaryTriangle,
      indices: [0, 1, 2],
      material: 'fhyuka_1',
      clip: const SpatialModelClipRect(
        left: -14,
        top: -7,
        right: -13,
        bottom: -6,
      ),
    );
    expect(result.indices, isNotEmpty);
    final edge = result.vertices.where((v) => (v.z + 6).abs() < 1e-12);
    expect(edge, isNotEmpty);
    for (final vertex in edge) {
      expect(vertex.z, -6);
      expect(vertex.y, -.125);
      expect(vertex.v, 4.5078125);
      expect((vertex.r, vertex.g, vertex.b, vertex.a), (1, 1, 1, 1));
    }
  });

  test('drops collinear triangles but retains small nonzero 3D areas', () {
    final degenerate = _clip([
      _vertex(0, 0, 0),
      _vertex(.5, 0, .5),
      _vertex(1, 0, 1),
    ]);
    expect(degenerate.indices, isEmpty);
    final small = _clip([
      _vertex(0, 0, 0),
      _vertex(1e-9, 0, 0),
      _vertex(0, 0, 1e-9),
    ]);
    expect(small.indices, hasLength(3));
  });

  test('does not mutate source lists and exposes immutable results', () {
    final vertices = [_vertex(-1, 0, 0), _vertex(2, 0, 0), _vertex(-1, 0, 3)];
    final original = List<SpatialModelClipVertex>.of(vertices);
    final indices = [0, 1, 2];
    final result = _clip(vertices, indices: indices);
    expect(vertices, original);
    expect(indices, [0, 1, 2]);
    expect(() => result.vertices.clear(), throwsUnsupportedError);
    expect(() => result.indices.clear(), throwsUnsupportedError);
    vertices.clear();
    indices.clear();
    expect(result.vertices, isNotEmpty);
    expect(result.indices, isNotEmpty);
  });

  test('rejects empty, reversed and nonfinite clip rectangles', () {
    for (final clip in [
      SpatialModelClipRect(left: 0, top: 0, right: 0, bottom: 1),
      SpatialModelClipRect(left: 1, top: 0, right: 0, bottom: 1),
      SpatialModelClipRect(left: 0, top: 1, right: 1, bottom: 0),
      SpatialModelClipRect(left: double.nan, top: 0, right: 1, bottom: 1),
      SpatialModelClipRect(left: 0, top: 0, right: double.infinity, bottom: 1),
    ]) {
      expect(
        () => clipSpatialModelTriangles(
          vertices: [],
          indices: [],
          material: null,
          clip: clip,
        ),
        throwsFormatException,
      );
    }
  });

  test('rejects invalid source attributes and inconsistent normals', () {
    for (final bad in [
      SpatialModelClipVertex(x: double.nan, y: 0, z: 0, u: 0, v: 0),
      SpatialModelClipVertex(x: 0, y: 0, z: 0, u: double.infinity, v: 0),
      SpatialModelClipVertex(x: 0, y: 0, z: 0, u: 0, v: 0, a: 1.1),
      SpatialModelClipVertex(x: 0, y: 0, z: 0, u: 0, v: 0, r: -.1),
      SpatialModelClipVertex(
        x: 0,
        y: 0,
        z: 0,
        u: 0,
        v: 0,
        normal: (x: double.nan, y: 1, z: 0),
      ),
      SpatialModelClipVertex(
        x: 0,
        y: 0,
        z: 0,
        u: 0,
        v: 0,
        normal: (x: 0, y: 1, z: 0),
      ),
    ]) {
      expect(
        () => _clip([bad, _vertex(1, 0, 0), _vertex(0, 0, 1)]),
        throwsFormatException,
      );
    }
  });

  test('rejects nontriangular or out-of-range indices', () {
    for (final indices in [
      [0, 1],
      [0, 1, -1],
      [0, 1, 3],
    ]) {
      expect(
        () => _clip([
          _vertex(0, 0, 0),
          _vertex(1, 0, 0),
          _vertex(0, 0, 1),
        ], indices: indices),
        throwsFormatException,
      );
    }
  });

  test('rejects singular, nonaffine and nonfinite node transforms', () {
    for (final transform in [
      List<double>.filled(15, 0),
      List<double>.filled(16, 0)..[15] = 1,
      [..._identity]..[3] = .25,
      [..._identity]..[15] = 2,
      [..._identity]..[4] = double.nan,
    ]) {
      expect(
        () => clipSpatialModelTriangles(
          vertices: [],
          indices: [],
          material: null,
          clip: SpatialModelClipRect(left: 0, top: 0, right: 1, bottom: 1),
          nodeTransform: transform,
        ),
        throwsFormatException,
      );
    }
  });

  test('enforces input and output vertex and triangle budgets', () {
    final vertices = [_vertex(-1, 0, 0), _vertex(2, 0, 0), _vertex(-1, 0, 3)];
    expect(
      () => _clip(vertices, maximumInputVertices: 2),
      throwsFormatException,
    );
    expect(
      () => _clip(vertices, maximumInputTriangles: 0),
      throwsFormatException,
    );
    expect(
      () => _clip(vertices, maximumOutputVertices: 3),
      throwsFormatException,
    );
    expect(
      () => _clip(vertices, maximumOutputVertices: 65536),
      throwsFormatException,
    );
    expect(
      () => _clip(vertices, maximumOutputTriangles: 1),
      throwsFormatException,
    );
  });

  test('preserves the exact Renouet 587230 surface 3 triangle 2 gradient', () {
    const material = (
      name: 'fhyuka_1',
      sourceId: '587230',
      sourceMember: 'Nuvema Town House 1 1F.dae',
      memberSha256:
          'ca1dc21fbed28cb7eb7676404d8ea12b1700da8b65fe6f3a1666a9a8b84a7872',
      geometry: 'm_fha01_00_00-3',
      wrapS: 10497,
      wrapT: 10497,
      opacity: 1.0,
    );
    final result = clipSpatialModelTriangles(
      vertices: const [
        SpatialModelClipVertex(
          x: -11,
          y: -.125,
          z: -13.6328125,
          u: -1.98046875,
          v: -3.078125,
          r: .670588255,
          g: .670588255,
          b: .56078434,
        ),
        SpatialModelClipVertex(
          x: -14.1875,
          y: -.125,
          z: -13.6328125,
          u: -5.125,
          v: -3.078125,
          r: .670588255,
          g: .670588255,
          b: .56078434,
        ),
        SpatialModelClipVertex(
          x: -14.1875,
          y: -.125,
          z: -13.5,
          u: -5.125,
          v: -2.9453125,
        ),
      ],
      indices: [0, 1, 2],
      material: material,
      clip: SpatialModelClipRect(
        left: -14,
        top: -13.625,
        right: -13,
        bottom: -13.5,
      ),
    );
    expect(_areaXZ(result), closeTo(37 / 384, 1e-12));
    expect(identical(result.material, material), isTrue);
    for (final vertex in result.vertices) {
      final gradient = (vertex.z + 13.6328125) / .1328125;
      expect(vertex.y, -.125);
      expect(
        vertex.u,
        closeTo(-5.125 + (vertex.x + 14.1875) * 805 / 816, 1e-12),
      );
      expect(vertex.v, closeTo(vertex.z + 10.5546875, 1e-12));
      expect(
        vertex.r,
        closeTo(.670588255 + gradient * (1 - .670588255), 1e-12),
      );
      expect(vertex.g, closeTo(vertex.r, 1e-12));
      expect(vertex.b, closeTo(.56078434 + gradient * (1 - .56078434), 1e-12));
      expect(vertex.a, 1);
    }
    expect(result.vertices.every((vertex) => vertex.v < 0), isTrue);
  });

  test(
    'two independently cut cells retain identical shared UV and RGBA seams',
    () {
      SpatialModelClipVertex vertex(double x, double z) =>
          SpatialModelClipVertex(
            x: x,
            y: -.1240234375,
            z: z,
            u: 3 * x - 2,
            v: 2 * z + 1,
            r: x / 2,
            g: z,
            b: .56078434,
            a: .75,
          );
      final vertices = [vertex(0, 0), vertex(2, 0), vertex(2, 1), vertex(0, 1)];
      final cells = [
        for (var x = 0; x < 2; x++)
          clipSpatialModelTriangles(
            vertices: vertices,
            indices: [0, 1, 2, 0, 2, 3],
            material: null,
            clip: SpatialModelClipRect(
              left: x.toDouble(),
              top: 0,
              right: x + 1.0,
              bottom: 1,
            ),
          ),
      ];
      expect(_areaXZ(cells[0]) + _areaXZ(cells[1]), closeTo(2, 1e-12));
      final seams = [
        for (final cell in cells)
          {
            for (final vertex in cell.vertices)
              if ((vertex.x - 1).abs() < 1e-12)
                (
                  vertex.y,
                  vertex.z,
                  vertex.u,
                  vertex.v,
                  vertex.r,
                  vertex.g,
                  vertex.b,
                  vertex.a,
                ),
          },
      ];
      expect(seams[0], unorderedEquals(seams[1]));
    },
  );

  test(
    'cuts every cell of odd-width source floors without even-cell padding',
    () {
      for (final width in [1, 3, 5]) {
        final vertices = [
          _vertex(0, -.125, 0),
          _vertex(width.toDouble(), -.125, 0),
          _vertex(width.toDouble(), -.125, 1),
          _vertex(0, -.125, 1),
        ];
        var area = 0.0;
        for (var x = 0; x < width; x++) {
          final result = clipSpatialModelTriangles(
            vertices: vertices,
            indices: [0, 1, 2, 0, 2, 3],
            material: null,
            clip: SpatialModelClipRect(
              left: x.toDouble(),
              top: 0,
              right: x + 1.0,
              bottom: 1,
            ),
          );
          expect(_areaXZ(result), closeTo(1, 1e-12));
          area += _areaXZ(result);
        }
        expect(area, closeTo(width.toDouble(), 1e-12));
      }
    },
  );

  test('rejects input triangle overflow and finite values that overflow a transform', () {
    final vertices = [_vertex(0, 0, 0), _vertex(1, 0, 0), _vertex(0, 0, 1)];
    expect(
      () => _clip(
        vertices,
        indices: [0, 1, 2, 0, 2, 1],
        maximumInputTriangles: 1,
      ),
      throwsFormatException,
    );
    expect(
      () => clipSpatialModelTriangles(
        vertices: [_vertex(2, 0, 0), _vertex(3, 0, 0), _vertex(2, 0, 1)],
        indices: [0, 1, 2],
        material: null,
        clip: SpatialModelClipRect(left: 0, top: 0, right: 1, bottom: 1),
        nodeTransform: [..._identity]..[0] = double.maxFinite,
      ),
      throwsFormatException,
    );
  });
}

const _identity = <double>[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];

SpatialModelTriangleClipResult<Object?> _clip(
  List<SpatialModelClipVertex> vertices, {
  List<int> indices = const [0, 1, 2],
  int maximumInputVertices = 65535,
  int maximumInputTriangles = 200000,
  int maximumOutputVertices = 65535,
  int maximumOutputTriangles = 200000,
}) => clipSpatialModelTriangles(
  vertices: vertices,
  indices: indices,
  material: null,
  clip: SpatialModelClipRect(left: 0, top: 0, right: 1, bottom: 1),
  maximumInputVertices: maximumInputVertices,
  maximumInputTriangles: maximumInputTriangles,
  maximumOutputVertices: maximumOutputVertices,
  maximumOutputTriangles: maximumOutputTriangles,
);

SpatialModelClipVertex _vertex(double x, double y, double z) =>
    SpatialModelClipVertex(x: x, y: y, z: z, u: x * 3 - 2, v: z * 2 + 1);

double _areaXZ(SpatialModelTriangleClipResult<Object?> result) {
  var area = 0.0;
  for (var index = 0; index < result.indices.length; index += 3) {
    final a = result.vertices[result.indices[index]];
    final b = result.vertices[result.indices[index + 1]];
    final c = result.vertices[result.indices[index + 2]];
    area += ((b.x - a.x) * (c.z - a.z) - (b.z - a.z) * (c.x - a.x)).abs() / 2;
  }
  return area;
}

double _signedAreaXZ(SpatialModelTriangleClipResult<Object?> result) {
  var area = 0.0;
  for (var index = 0; index < result.indices.length; index += 3) {
    final a = result.vertices[result.indices[index]];
    final b = result.vertices[result.indices[index + 1]];
    final c = result.vertices[result.indices[index + 2]];
    area += ((b.x - a.x) * (c.z - a.z) - (b.z - a.z) * (c.x - a.x)) / 2;
  }
  return area;
}
