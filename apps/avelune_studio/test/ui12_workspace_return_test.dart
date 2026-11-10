import 'dart:io';

import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_controllers.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_loader.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/map_workspace_fixture.dart';
import 'support/ui12_return_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<
    (Ui12ReturnHarness, WorkspaceSessionControllers, WorkspaceNavigationSession)
  >
  open() async {
    final root = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await root.create(recursive: true);
    final h = await Ui12ReturnHarness.create(parent: root);
    addTearDown(h.dispose);
    final sessions = WorkspaceSessionControllers(
      controller: h.controller,
      changed: () {},
      visualCatalogChanged: (_) {},
      flushEditors: () async => true,
      scenePort: h.scenePort,
      presentationPort: h.presentationPort,
      worldPort: LocalWorldAdapter(session: h.session, mapAdapter: h.maps),
    );
    addTearDown(sessions.dispose);
    final loaded = await loadWorkspaceSession(
      workspace: h.controller,
      loadVisuals: (_, _) async => WorkspaceTestVisuals(),
      narrativePort: h.narrativeAdapter,
      isActive: () => true,
      changed: () {},
      onUse: (_) async {},
    );
    sessions.initializeLoaded(loaded!);
    final navigation = WorkspaceNavigationSession(
      controller: h.controller,
      isActive: () => true,
      changed: () {},
      scenes: () => sessions.scenes,
      presentations: () => sessions.presentations,
      world: () => sessions.world,
    );
    navigation.show(WorkspaceSpace.story);
    return (h, sessions, navigation);
  }

  test('a detour through a second consumer still returns to scene A and keeps its selected clip', () async {
    final (h, sessions, navigation) = await open();
    expect(await navigation.openScene(h.sceneA.id, nodeId: h.nodeA), isNull);
    final scenes = sessions.scenes!;
    expect(scenes.active!.current.id, h.sceneA.id);
    final payload =
        scenes.active!.current.graph.nodes
                .firstWhere((node) => node.id == h.nodeA)
                .payload
            as ScenePresentationCinematicPayload;
    await navigation.openScenePresentation(payload);
    final owner = sessions.presentations!;
    expect(navigation.space, WorkspaceSpace.presentation);
    expect(owner.activeId, h.presentationId);
    expect(navigation.presentationPreviewSceneId, h.sceneA.id);
    final session = owner.active!;
    final editing = sessions.presentationEditing.forAsset(session.asset);
    final clip = session.asset.tracks.expand((track) => track.clips).first.id;
    editing.selectClip(clip);
    expect(navigation.openPresentationConsumer(h.sceneB.id, h.nodeB), isTrue);
    expect(navigation.space, WorkspaceSpace.scene);
    expect(scenes.active!.current.id, h.sceneB.id);
    expect(navigation.sceneNodes[h.sceneB.id], h.nodeB);
    expect(
      await navigation.returnToPresentation(navigation.sceneOrigin.documentId),
      isNull,
    );
    expect(navigation.space, WorkspaceSpace.presentation);
    expect(owner.activeId, h.presentationId);
    expect(owner.active!.asset, session.asset);
    expect(
      sessions.presentationEditing.forAsset(owner.active!.asset),
      same(editing),
    );
    expect(editing.selectedClipIds, contains(clip));
    expect(navigation.presentationPreviewSceneId, h.sceneA.id);
    expect(navigation.returnFromPresentation(), isNull);
    expect(navigation.space, WorkspaceSpace.scene);
    expect(scenes.active!.current.id, h.sceneA.id);
    expect(navigation.sceneNodes[h.sceneA.id], h.nodeA);
  });

  test(
    'World detour through scene B preserves the originating scene A',
    () async {
      final (h, sessions, navigation) = await open();
      expect(await navigation.openScene(h.sceneA.id, nodeId: h.nodeA), isNull);
      navigation.worldOrigin = WorkspaceReturn(
        WorkspaceSpace.scene,
        documentId: h.sceneA.id,
      );
      navigation.show(WorkspaceSpace.world);
      expect(navigation.openSceneFromWorld(h.sceneB.id), isTrue);
      expect(sessions.scenes!.active!.current.id, h.sceneB.id);
      expect(navigation.sceneOrigin.space, WorkspaceSpace.world);
      navigation.show(navigation.sceneOrigin.space);
      expect(navigation.returnFromWorld(), isNull);
      expect(navigation.space, WorkspaceSpace.scene);
      expect(sessions.scenes!.active!.current.id, h.sceneA.id);
      expect(navigation.sceneNodes[h.sceneA.id], h.nodeA);
    },
  );
  test(
    'a missing originating scene returns from World with an explicit failure',
    () async {
      final (_, _, navigation) = await open();
      navigation.worldOrigin = const WorkspaceReturn(
        WorkspaceSpace.scene,
        documentId: 'missing-origin',
      );
      navigation.show(WorkspaceSpace.world);
      expect(
        navigation.returnFromWorld(),
        'Cette scène n’est plus disponible.',
      );
      expect(navigation.space, WorkspaceSpace.story);
      expect(navigation.worldOrigin, same(WorkspaceReturn.story));
    },
  );
}
