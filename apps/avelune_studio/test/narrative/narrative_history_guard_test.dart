import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'undo never removes the source of a published story and keeps history intact',
    () async {
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      await controller.initialize();
      final document = controller.active!;
      document.commit(
        document.current.copyWith(
          entities: [
            const MapEntity(
              id: 'chief',
              name: 'Chef',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 2, y: 2),
              npc: MapEntityNpcData(),
            ),
          ],
        ),
      );
      final snapshot = document.current;
      controller.project = controller.project!.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          legacyClaims: [],
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: 'evt_00000000-0000-7000-8000-000000000001',
                name: 'Conversation',
                source: NarrativeEventSourceRef.entityInteract('a', 'chief'),
                conditions: [],
                priority: 0,
                order: 0,
              ),
            ),
          ],
        ),
      );
      controller.restore(redo: false);
      expect(document.current, snapshot);
      expect(document.undoCount, 1);
      expect(document.canRedo, false);
      expect(document.error, contains('histoire'));
      document.commit(document.current.copyWith(name: 'Nom modifié'));
      controller.restore(redo: false);
      expect(document.current, snapshot);
      expect(document.error, isNull);
      controller.restore(redo: true);
      expect(document.current.name, 'Nom modifié');
      controller.dispose();
    },
  );

  test(
    'pending story guard rejects undo without consuming its entry',
    () async {
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      await controller.initialize();
      final document = controller.active!;
      document.commit(document.current.copyWith(name: 'Modifié'));
      controller.historyGuard = (before, after) => 'Brouillon lié';
      controller.restore(redo: false);
      expect(document.current.name, 'Modifié');
      expect(document.undoCount, 1);
      controller.historyGuard = null;
      controller.restore(redo: false);
      expect(document.current.name, 'a');
      expect(document.canRedo, true);
      controller.dispose();
    },
  );
}
