import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test('bounded scene history retains latest changes and saved baseline', () {
    const project = ProjectManifest(name: 'Test', maps: [], tilesets: []);
    final base = createSceneDraftInProject(
      project,
      name: 'Origine',
    ).createdScene;
    final session = SceneEditSession(base, base: base);
    expect(SceneEditSession.historyLimit, 64);
    for (var i = 1; i <= 70; i++) {
      expect(session.rename('Version $i'), true);
    }
    final latest = session.current;
    expect(session.undoCount, 64);
    expect(session.base, same(base));
    expect(session.dirty, true);
    for (var i = 0; i < 64; i++) {
      session.restore(redo: false);
    }
    expect(session.current.name, 'Version 6');
    expect(session.canUndo, false);
    expect(session.canRedo, true);
    expect(session.dirty, true);
    expect(session.base, same(base));
    session.restore(redo: false);
    expect(session.current.name, 'Version 6');
    for (var i = 0; i < 64; i++) {
      session.restore(redo: true);
    }
    expect(session.current, same(latest));
    expect(session.undoCount, 64);
    expect(session.canRedo, false);
    session.acceptSave(latest, 'revision-saved');
    expect(session.dirty, false);
    session.restore(redo: false);
    expect(session.dirty, true);
    expect(session.base, same(latest));
    expect(session.savedRevision, 'revision-saved');
    session.restore(redo: true);
    expect(session.dirty, false);
    session.restore(redo: false);
    expect(session.rename('Nouvelle branche'), true);
    expect(session.undoCount, 64);
    expect(session.canRedo, false);
    expect(session.dirty, true);
    expect(session.base, same(latest));
  });
}
