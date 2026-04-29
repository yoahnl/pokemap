import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_drag_payload.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_role_assignment_draft.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  test(
      'role drop validation accepts center multi-column and rejects edge multi-column',
      () {
    const payload = SurfaceStudioColumnDragPayload(
      columns: [4, 5, 6],
      tileWidth: 32,
      tileHeight: 32,
      frameCount: 32,
    );
    const draft = SurfaceStudioRoleAssignmentDraft.empty();

    expect(
      validateSurfaceStudioRoleDrop(
        role: SurfaceVariantRole.isolated,
        payload: payload,
        draft: draft,
      ),
      SurfaceStudioDropValidation.valid,
    );
    expect(
      validateSurfaceStudioRoleDrop(
        role: SurfaceVariantRole.endNorth,
        payload: payload,
        draft: draft,
      ),
      SurfaceStudioDropValidation.invalidTooManyColumns,
    );
  });

  test('role assignment draft preserves center order and replaces other roles',
      () {
    const draft = SurfaceStudioRoleAssignmentDraft.empty();
    final withCenter = draft.assignColumns(
      SurfaceVariantRole.isolated,
      const [4, 5],
    );
    final withEdge = withCenter.assignColumns(
      SurfaceVariantRole.endNorth,
      const [7],
    );
    final replacedEdge = withEdge.assignColumns(
      SurfaceVariantRole.endNorth,
      const [8],
    );

    expect(withCenter.columnsForRole(SurfaceVariantRole.isolated), [4, 5]);
    expect(replacedEdge.columnsForRole(SurfaceVariantRole.endNorth), [8]);
    expect(replacedEdge.assignedRoleCount, 2);
  });

  testWidgets('schema panel uses accordions and shows expected roles', (
    tester,
  ) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.schema.group.surfaceMain')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.schema.group.edges')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.schema.role.center')),
        findsOneWidget);
    expect(find.text('Plein (center)'), findsOneWidget);
    expect(find.text('Bord haut'), findsOneWidget);
    expect(find.text('Coin int. haut gauche'), findsOneWidget);

    await tester
        .tap(find.byKey(const Key('surfaceStudio.schema.group.edges.header')));
    await tester.pumpAndSettle();
    expect(find.text('Bord haut'), findsNothing);
  });
}
