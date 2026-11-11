import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'destination opening still activates the real owner after closing',
    () async {
      final maps = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(maps.dispose);
      await maps.initialize();
      final previous = maps.active!;
      previous.commit(previous.current.copyWith(name: 'Brouillon conservé'));
      final draft = previous.current;
      var closed = false;
      Future<void>? activation;
      final open = mapLibraryOpenAction(maps.project!, (entry) {
        expect(closed, isTrue);
        activation = maps.activate(entry);
      }, () => closed = true);
      open('missing');
      expect(closed, isFalse);
      expect(maps.active, same(previous));
      open('b');
      await activation;
      expect(maps.active!.base.mapId, 'b');
      expect(maps.documents['a'], same(previous));
      expect(previous.current, same(draft));
      expect(previous.undoCount, 1);
      expect(previous.dirty, isTrue);
    },
  );
}
