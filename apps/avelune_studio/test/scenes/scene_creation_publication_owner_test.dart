import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/ui05_story_backend_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('scene owner still creates saves and cold reopens a native draft', () async {
    final fixture = await createUi05StoryBackend();
    addTearDown(() => fixture.directory.delete(recursive: true));
    final maps = MapWorkspaceController(fixture.session, fixture.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final scenes = SceneWorkspaceController(
      maps,
      LocalSceneAdapter(session: fixture.session, mapAdapter: fixture.maps),
      changed: () {},
    );
    addTearDown(scenes.dispose);
    final previous = scenes.scenes.first;
    expect(scenes.open(previous.id), isTrue);
    final count = scenes.scenes.length;
    final created = scenes.create('Arrivée du train')!;
    final id = created.current.id;
    expect(id, isNot(previous.id));
    expect(scenes.scenes, hasLength(count + 1));
    expect(created.dirty, isTrue);
    expect(await scenes.save(), isTrue, reason: scenes.error);
    expect(created.dirty, isFalse);
    final reopened = await LocalMapWorkspaceAdapter().loadProject(
      fixture.session,
    );
    expect(
      reopened.scenes.singleWhere((scene) => scene.id == id),
      created.current,
    );
    expect(
      reopened.scenes.singleWhere((scene) => scene.id == previous.id),
      previous,
    );
  }, timeout: _slow);
}

const _slow = Timeout(Duration(minutes: 3));
