import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderStrokeEditingDraft draw', () {
    test('rebuilds one canonical stroke from the pointer-down snapshot', () {
      final source = BorderStrokeGeometry(strokes: const <BorderStroke>[]);

      final afterFirstMove = BorderStrokeEditingDraft.begin(
        baseGeometry: source,
        mode: BorderStrokeEditingMode.draw,
        pointerDown: const GridPos(x: 1, y: 1),
      ).sample(const GridPos(x: 3, y: 1));
      final afterSecondMove = afterFirstMove.sample(const GridPos(x: 3, y: 3));

      expect(afterFirstMove.previewGeometry!.strokes, hasLength(1));
      expect(afterSecondMove.previewGeometry!.strokes, hasLength(1));
      expect(
        afterSecondMove.previewGeometry!.strokes.single.points,
        const <GridPos>[
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
          GridPos(x: 3, y: 2),
          GridPos(x: 3, y: 3),
        ],
      );
      expect(source.strokes, isEmpty);
      expect(afterSecondMove.baseGeometry, same(source));
    });

    test('allocates one stable first-free id and keeps explicit openings', () {
      final source = BorderStrokeGeometry(
        strokes: <BorderStroke>[
          _openStroke('stroke', 0, 2),
          _openStroke('stroke_2', 5, 7),
        ],
      );

      final first = BorderStrokeEditingDraft.begin(
        baseGeometry: source,
        mode: BorderStrokeEditingMode.draw,
        pointerDown: const GridPos(x: 10, y: 0),
      ).sample(const GridPos(x: 12, y: 0));
      final repeated = BorderStrokeEditingDraft.begin(
        baseGeometry: source,
        mode: BorderStrokeEditingMode.draw,
        pointerDown: const GridPos(x: 10, y: 0),
      ).sample(const GridPos(x: 12, y: 0));

      expect(first.pendingStrokeId, 'stroke_3');
      expect(repeated.pendingStrokeId, first.pendingStrokeId);
      expect(
        first.previewGeometry!.strokes.map((stroke) => stroke.id),
        <String>['stroke', 'stroke_2', 'stroke_3'],
      );
      expect(
        first.previewGeometry!.strokes
            .expand((stroke) => stroke.points)
            .map((point) => point.x),
        isNot(containsAll(<int>[3, 4, 8, 9])),
        reason: 'separate strokes must remain explicit openings',
      );
    });

    test('does not produce a draft stroke before two distinct cells', () {
      final draft = BorderStrokeEditingDraft.begin(
        baseGeometry: BorderStrokeGeometry(
          strokes: const <BorderStroke>[],
        ),
        mode: BorderStrokeEditingMode.draw,
        pointerDown: const GridPos(x: 2, y: 2),
      ).sample(const GridPos(x: 2, y: 2));

      expect(draft.previewGeometry, isNull);
    });

    test('preserves grid-edge alignment in the draw preview', () {
      final source = BorderStrokeGeometry(
        strokes: const <BorderStroke>[],
        alignment: BorderStrokeAlignment.gridEdges,
      );

      final preview = BorderStrokeEditingDraft.begin(
        baseGeometry: source,
        mode: BorderStrokeEditingMode.draw,
        pointerDown: const GridPos(x: 0, y: 0),
      ).sample(const GridPos(x: 2, y: 0)).previewGeometry!;

      expect(preview.alignment, BorderStrokeAlignment.gridEdges);
    });
  });

  group('BorderStrokeEditingDraft erase', () {
    test('rasterizes the eraser and splits with deterministic fragment ids',
        () {
      final source = BorderStrokeGeometry(
        strokes: <BorderStroke>[_openStroke('wall', 0, 8)],
      );

      final erased = BorderStrokeEditingDraft.begin(
        baseGeometry: source,
        mode: BorderStrokeEditingMode.erase,
        pointerDown: const GridPos(x: 3, y: 0),
      ).sample(const GridPos(x: 5, y: 0));
      final repeated = BorderStrokeEditingDraft.begin(
        baseGeometry: source,
        mode: BorderStrokeEditingMode.erase,
        pointerDown: const GridPos(x: 3, y: 0),
      ).sample(const GridPos(x: 5, y: 0));

      final identities = erased.previewGeometry!.strokes
          .map(resolveBorderStrokeLineageIdentityV1)
          .toList(growable: false);
      expect(
        identities.map((identity) => identity.authoredStrokeId),
        <String>['wall', 'wall__fragment_2'],
      );
      expect(
        identities.map((identity) => identity.sourceEdgeOffset),
        <int>[0, 6],
      );
      expect(
        identities.map((identity) => identity.preserveTraversal),
        everyElement(isTrue),
      );
      expect(
        erased.previewGeometry!.strokes.map((stroke) => stroke.points),
        <List<GridPos>>[
          const <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 2, y: 0),
          ],
          const <GridPos>[
            GridPos(x: 6, y: 0),
            GridPos(x: 7, y: 0),
            GridPos(x: 8, y: 0),
          ],
        ],
      );
      expect(repeated.previewGeometry, erased.previewGeometry);
      expect(source.strokes.single.points, hasLength(9));
    });

    test('first surviving fragment keeps the original authored id', () {
      final source = BorderStrokeGeometry(
        strokes: <BorderStroke>[_openStroke('wall', 0, 4)],
      );

      final erased = BorderStrokeEditingDraft.begin(
        baseGeometry: source,
        mode: BorderStrokeEditingMode.erase,
        pointerDown: const GridPos(x: 1, y: 0),
      ).previewGeometry!;

      expect(erased.strokes, hasLength(1));
      final identity = resolveBorderStrokeLineageIdentityV1(
        erased.strokes.single,
      );
      expect(identity.authoredStrokeId, 'wall');
      expect(identity.sourceEdgeOffset, 2);
      expect(identity.preserveTraversal, isTrue);
      expect(
        erased.strokes.single.points,
        const <GridPos>[
          GridPos(x: 2, y: 0),
          GridPos(x: 3, y: 0),
          GridPos(x: 4, y: 0),
        ],
      );
    });

    test('opens a touched closed loop and removes fragments shorter than two',
        () {
      final source = BorderStrokeGeometry(
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'loop',
            points: const <GridPos>[
              GridPos(x: 0, y: 0),
              GridPos(x: 1, y: 0),
              GridPos(x: 2, y: 0),
              GridPos(x: 2, y: 1),
              GridPos(x: 2, y: 2),
              GridPos(x: 1, y: 2),
              GridPos(x: 0, y: 2),
              GridPos(x: 0, y: 1),
            ],
            closed: true,
          ),
          _verticalStroke('short', x: 5, fromY: 0, toY: 1),
        ],
      );

      final opened = BorderStrokeEditingDraft.begin(
        baseGeometry: source,
        mode: BorderStrokeEditingMode.erase,
        pointerDown: const GridPos(x: 1, y: 0),
      ).sample(const GridPos(x: 5, y: 0));

      expect(opened.previewGeometry!.strokes, hasLength(1));
      final identity = resolveBorderStrokeLineageIdentityV1(
        opened.previewGeometry!.strokes.single,
      );
      expect(identity.authoredStrokeId, 'loop');
      expect(identity.sourceEdgeOffset, 3);
      expect(identity.wrapLength, 8);
      expect(identity.preserveTraversal, isTrue);
      expect(opened.previewGeometry!.strokes.single.closed, isFalse);
      expect(
        opened.previewGeometry!.strokes.single.points,
        isNot(contains(const GridPos(x: 1, y: 0))),
      );
      expect(
        opened.previewGeometry!.strokes.single.points,
        isNot(contains(const GridPos(x: 5, y: 1))),
        reason: 'a one-cell remainder must be removed',
      );
    });

    test('never reconnects independent strokes across an opening', () {
      final source = BorderStrokeGeometry(
        strokes: <BorderStroke>[
          _openStroke('left', 0, 3),
          _openStroke('right', 5, 8),
        ],
      );

      final erased = BorderStrokeEditingDraft.begin(
        baseGeometry: source,
        mode: BorderStrokeEditingMode.erase,
        pointerDown: const GridPos(x: 2, y: 0),
      ).sample(const GridPos(x: 6, y: 0));

      final identities = erased.previewGeometry!.strokes
          .map(resolveBorderStrokeLineageIdentityV1)
          .toList(growable: false);
      expect(
        identities.map((identity) => identity.authoredStrokeId),
        <String>['left', 'right'],
      );
      expect(
        identities.map((identity) => identity.sourceEdgeOffset),
        <int>[0, 2],
      );
      expect(
        erased.previewGeometry!.strokes.map((stroke) => stroke.points),
        <List<GridPos>>[
          const <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
          ],
          const <GridPos>[
            GridPos(x: 7, y: 0),
            GridPos(x: 8, y: 0),
          ],
        ],
      );
      expect(source.strokes, hasLength(2));
    });

    test('preserves grid-edge alignment in a changed erase preview', () {
      final source = BorderStrokeGeometry(
        strokes: <BorderStroke>[_openStroke('wall', 0, 4)],
        alignment: BorderStrokeAlignment.gridEdges,
      );

      final preview = BorderStrokeEditingDraft.begin(
        baseGeometry: source,
        mode: BorderStrokeEditingMode.erase,
        pointerDown: const GridPos(x: 2, y: 0),
      ).previewGeometry!;

      expect(preview, isNot(same(source)));
      expect(preview.alignment, BorderStrokeAlignment.gridEdges);
    });
  });
}

BorderStroke _openStroke(String id, int fromX, int toX) => BorderStroke(
      id: id,
      points: <GridPos>[
        for (var x = fromX; x <= toX; x += 1) GridPos(x: x, y: 0),
      ],
      closed: false,
    );

BorderStroke _verticalStroke(
  String id, {
  required int x,
  required int fromY,
  required int toY,
}) =>
    BorderStroke(
      id: id,
      points: <GridPos>[
        for (var y = fromY; y <= toY; y += 1) GridPos(x: x, y: y),
      ],
      closed: false,
    );
