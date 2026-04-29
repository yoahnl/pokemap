import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/preview/surface_studio_surface_preview_cells.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_role_assignment_draft.dart';

void main() {
  test('rect preview uses assigned exterior roles at the expected cells', () {
    final draft = const SurfaceStudioRoleAssignmentDraft.empty()
        .assignColumns(SurfaceVariantRole.isolated, <int>[1]).assignColumns(SurfaceVariantRole.cornerNW, <int>[2]).assignColumns(
            SurfaceVariantRole.cornerNE,
            <int>[3]).assignColumns(SurfaceVariantRole.cornerSW, <int>[4]).assignColumns(SurfaceVariantRole.cornerSE, <int>[
      5
    ]).assignColumns(SurfaceVariantRole.endNorth, <int>[6]).assignColumns(SurfaceVariantRole.endEast, <int>[7]).assignColumns(
            SurfaceVariantRole.endSouth, <int>[8]).assignColumns(SurfaceVariantRole.endWest, <int>[9]);

    final cells = buildSurfaceStudioRectPreviewCells(
      assignmentDraft: draft,
      previewSize: 5,
      frameIndex: 0,
    );

    expect(_cell(cells, 0, 0).role, SurfaceVariantRole.cornerNW);
    expect(_cell(cells, 0, 0).sourceColumn, 2);
    expect(_cell(cells, 4, 0).role, SurfaceVariantRole.cornerNE);
    expect(_cell(cells, 4, 0).sourceColumn, 3);
    expect(_cell(cells, 0, 4).role, SurfaceVariantRole.cornerSW);
    expect(_cell(cells, 0, 4).sourceColumn, 4);
    expect(_cell(cells, 4, 4).role, SurfaceVariantRole.cornerSE);
    expect(_cell(cells, 4, 4).sourceColumn, 5);
    expect(_cell(cells, 2, 0).role, SurfaceVariantRole.endNorth);
    expect(_cell(cells, 2, 0).sourceColumn, 6);
    expect(_cell(cells, 4, 2).role, SurfaceVariantRole.endEast);
    expect(_cell(cells, 4, 2).sourceColumn, 7);
    expect(_cell(cells, 2, 4).role, SurfaceVariantRole.endSouth);
    expect(_cell(cells, 2, 4).sourceColumn, 8);
    expect(_cell(cells, 0, 2).role, SurfaceVariantRole.endWest);
    expect(_cell(cells, 0, 2).sourceColumn, 9);
    expect(_cell(cells, 2, 2).role, SurfaceVariantRole.isolated);
    expect(_cell(cells, 2, 2).sourceColumn, 1);
  });

  test('missing exterior roles fall back to isolated with explicit flag', () {
    final draft = const SurfaceStudioRoleAssignmentDraft.empty()
        .assignColumns(SurfaceVariantRole.isolated, <int>[3]);

    final cells = buildSurfaceStudioRectPreviewCells(
      assignmentDraft: draft,
      previewSize: 5,
      frameIndex: 0,
    );

    expect(_cell(cells, 2, 0).role, SurfaceVariantRole.endNorth);
    expect(_cell(cells, 2, 0).sourceColumn, 3);
    expect(_cell(cells, 2, 0).usedFallback, isTrue);
    expect(_cell(cells, 2, 2).usedFallback, isFalse);
  });

  test('isolated multi-columns alternate by cell and frame', () {
    final draft = const SurfaceStudioRoleAssignmentDraft.empty()
        .assignColumns(SurfaceVariantRole.isolated, <int>[1, 2]);

    final frame0 = buildSurfaceStudioRectPreviewCells(
      assignmentDraft: draft,
      previewSize: 5,
      frameIndex: 0,
    );
    final frame1 = buildSurfaceStudioRectPreviewCells(
      assignmentDraft: draft,
      previewSize: 5,
      frameIndex: 1,
    );

    expect(_cell(frame0, 2, 2).sourceColumn, 1);
    expect(_cell(frame0, 3, 2).sourceColumn, 2);
    expect(_cell(frame1, 2, 2).sourceColumn, 2);
  });
}

SurfaceStudioPreviewCell _cell(
  List<SurfaceStudioPreviewCell> cells,
  int x,
  int y,
) =>
    cells.singleWhere((cell) => cell.x == x && cell.y == y);
