import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:avelune_studio/features/scenes/domain/scene_presentation_creation_request.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_linked_document.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  late MapWorkspaceController maps;
  late SceneWorkspaceController scenes;
  late SceneBuilderViewStore views;
  late ValueNotifier<int> changes;
  late _NoWrites port;
  late SceneAsset base, worldScene;
  late String presentationNode, worldNode;
  setUp(() async {
    maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort());
    await maps.initialize();
    var scene = createSceneDraftInProject(
      maps.project!,
      name: 'Origine',
    ).createdScene;
    scene = SceneAsset.fromJson({
      ...scene.toJson(),
      'executionProfile': 'preSession',
    });
    final linked = addSceneLinkedAssetNodeDraft(
      scene,
      payload: ScenePresentationCinematicPayload(
        presentationCinematicId: 'same-id',
      ),
      title: 'Présentation liée',
    );
    presentationNode = linked.createdNode.id;
    final world = addSceneLinkedAssetNodeDraft(
      createSceneDraftInProject(
        maps.project!,
        name: 'Scène sur carte',
      ).createdScene,
      payload: SceneCinematicPayload(cinematicId: 'same-id'),
      title: 'Carte liée',
    );
    worldNode = world.createdNode.id;
    base = linked.updatedScene;
    worldScene = world.updatedScene;
    maps.project = maps.project!.copyWith(
      scenes: [base, worldScene],
      presentationCinematics: [asset('Disque')],
      cinematics: [
        CinematicAsset(
          id: 'same-id',
          title: 'Carte',
          timeline: CinematicTimeline(),
        ),
      ],
    );
    port = _NoWrites();
    changes = ValueNotifier(0);
    scenes = SceneWorkspaceController(
      maps,
      port,
      changed: () => changes.value++,
    );
    scenes.open(base.id);
    views = SceneBuilderViewStore();
  });
  tearDown(() {
    scenes.dispose();
    maps.dispose();
    views.dispose();
    changes.dispose();
  });

  testWidgets(
    'typed linked callbacks retain scene draft, selection and viewport',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = views.forScene(base.id)..nodeId = presentationNode;
      state.viewport.zoomAt(1.4, const Offset(400, 250));
      state.viewport.translate(const Offset(22, -13));
      final pan = state.viewport.pan, zoom = state.viewport.zoom;
      scenes.active!.rename('Brouillon conservé');
      var before = scenes.active!.current;
      ScenePresentationCinematicPayload? presentation;
      SceneCinematicPayload? cinematic;
      ScenePresentationCreationRequest? creation;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: changes,
              builder: (_, value, child) => SceneBuilderPage(
                controller: scenes,
                views: views,
                onBack: () {},
                onPresentation: (p) async {
                  presentation = p;
                },
                onCinematic: (p) async {
                  cinematic = p;
                },
                onCreatePresentation: (request) async {
                  creation = request;
                },
                presentationFor: (_) => asset('Brouillon récent'),
                presentationEntries: () => [asset('Brouillon récent')],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final title = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Nom du bloc',
      );
      await tester.enterText(title, 'Titre encore focalisé');
      await _tap(tester, find.text('Ouvrir la présentation'));
      expect(
        scenes.active!.current.graph.nodes
            .singleWhere((n) => n.id == presentationNode)
            .title,
        'Titre encore focalisé',
      );
      before = scenes.active!.current;
      expect(presentation!.presentationCinematicId, 'same-id');
      expect(cinematic, isNull);
      expect(find.text('Brouillon récent'), findsOneWidget);
      await _tap(tester, find.text('Créer une présentation liée'));
      expect(creation!.baseScene, same(base));
      expect(creation!.scene, same(before));
      expect(creation!.targetNodeId, presentationNode);
      expect(scenes.active!.current, same(before));
      expect(scenes.active!.dirty, isTrue);
      expect(state.nodeId, presentationNode);
      expect(state.viewport.pan, pan);
      expect(state.viewport.zoom, zoom);
      scenes.open(worldScene.id);
      views.forScene(worldScene.id).nodeId = worldNode;
      changes.value++;
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Ouvrir la cinématique'));
      expect(cinematic!.cinematicId, 'same-id');
      expect(port.writes, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'presentation preview resolves current draft and does not revive a deleted source',
    (tester) async {
      PresentationCinematicAsset? working = asset('Texte du brouillon');
      final documents = SceneLinkedDocuments()
        ..presentationFor = (_) => working;
      final node = base.graph.nodes.singleWhere(
        (n) => n.id == presentationNode,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    documents.open(context, node, maps.project!, null),
                child: const Text('Aperçu'),
              ),
            ),
          ),
        ),
      );
      await _tap(tester, find.text('Aperçu'));
      expect(find.text('Texte du brouillon'), findsOneWidget);
      expect(find.text('Disque'), findsNothing);
      await _tap(tester, find.text('Retour à la scène'));
      working = null;
      await _tap(tester, find.text('Aperçu'));
      expect(find.textContaining('Présentation introuvable'), findsOneWidget);
      expect(find.text('Disque'), findsNothing);
      expect(port.writes, 0);
    },
  );
}

PresentationCinematicAsset asset(String title) => PresentationCinematicAsset(
  id: 'same-id',
  title: title,
  durationUs: 2000000,
);
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class _NoWrites implements ScenePort {
  int writes = 0;
  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) async {
    writes++;
    throw StateError('Navigation cannot publish the scene');
  }
}
