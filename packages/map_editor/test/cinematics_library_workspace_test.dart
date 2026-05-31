import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematics_library_workspace.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('shows empty state and creates a cinematic shell',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(
      _Harness(project: _project(cinematics: const [], includeBridge: false)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cinematics-library-workspace')),
        findsOneWidget);
    expect(find.text('Aucune cinématique canonique'), findsOneWidget);
    expect(find.text('Créer une cinématique'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('cinematics-library-create-title-field')),
      'Opening Camera',
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-create-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Opening Camera'), findsWidgets);
    expect(find.text('Timeline vide'), findsWidgets);
    expect(find.textContaining('Builder V2'), findsWidgets);
  });

  testWidgets('lists canonical and bridge entries with read-only details',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(_Harness(project: _project()));
    await tester.pumpAndSettle();

    expect(find.text('Intro cinematic'), findsWidgets);
    expect(find.text('Legacy cutscene'), findsWidgets);
    expect(find.text('1 scène'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-scenario_cutscene')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Bridge legacy — pas un CinematicAsset canonique',
      ),
      findsOneWidget,
    );
    expect(find.text('Bridge legacy Scenario/Cutscene'), findsOneWidget);
    expect(
      find.textContaining(
        'Les bridges legacy viennent de l’ancien Cutscene Studio',
      ),
      findsOneWidget,
    );
    expect(find.text('Migration future'), findsOneWidget);
    expect(find.text('Sauvegarder les métadonnées'), findsNothing);
  });

  testWidgets('shows timeline summary and scene usages for canonical entry',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(_Harness(project: _project()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Résumé timeline'), findsOneWidget);
    expect(find.text('2 step(s)'), findsWidgets);
    expect(find.text('750 ms estimé(s)'), findsOneWidget);
    expect(find.text('actor_professor'), findsWidgets);
    expect(find.text('Canonical scene'), findsOneWidget);
    expect(find.text('Play intro'), findsOneWidget);
    expect(find.text('Supprimer la cinématique'), findsOneWidget);
    expect(
      tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('cinematics-library-delete-button')),
      ),
      isNotNull,
    );
  });

  testWidgets('edits metadata and deletes only unused canonicals',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(
      _Harness(
        project: _project(
          extraCinematics: [
            CinematicAsset(
              id: 'cinematic_unused',
              title: 'Unused cinematic',
              timeline: CinematicTimeline(),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
    );
    await tester.pumpAndSettle();

    final deleteButton =
        find.byKey(const ValueKey('cinematics-library-delete-button'));
    expect(tester.widget<PokeMapButton>(deleteButton).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('cinematics-library-title-field')),
      'Intro cinematic edited',
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-save-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Intro cinematic edited'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_unused')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<PokeMapButton>(deleteButton).onPressed, isNotNull);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.text('Confirmer suppression'), findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Unused cinematic'), findsNothing);
  });

  testWidgets('captures V1-38 Cinematics Library screenshot when requested',
      (tester) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_38_CAPTURE_CINEMATICS_LIBRARY',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    await tester.pumpWidget(_Harness(project: _project()));
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_38_cinematics_library_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematics-library-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });
}

Future<void> _loadScreenshotFonts() async {
  final fontBytes =
      File('/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytesSync();
  for (final family in <String>[
    'Roboto',
    'Arial',
    '.SF Pro Text',
    'SF Pro Text',
  ]) {
    final loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(fontBytes)));
    await loader.load();
  }
}

class _Harness extends StatefulWidget {
  const _Harness({required this.project});

  final ProjectManifest project;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late ProjectManifest _project = widget.project;

  @override
  Widget build(BuildContext context) {
    return MacosTheme(
      data: MacosThemeData.dark(),
      child: MaterialApp(
        home: CupertinoPageScaffold(
          child: SizedBox(
            width: 1280,
            height: 820,
            child: CinematicsLibraryWorkspace(
              project: _project,
              onCreateCinematicShell: ({required String title}) async {
                final id = _nextCinematicId(title);
                final result = addCinematicAsset(
                  _project,
                  CinematicAsset(
                    id: id,
                    title: title,
                    timeline: CinematicTimeline(),
                  ),
                );
                setState(() => _project = result.updatedProject);
                return id;
              },
              onUpdateCinematicMetadata: ({
                required String cinematicId,
                required String title,
                required String description,
                required String notes,
              }) async {
                final existing = findCinematicById(_project, cinematicId);
                if (existing == null) {
                  return false;
                }
                final result = updateCinematicAsset(
                  _project,
                  CinematicAsset(
                    id: existing.id,
                    title: title,
                    description: description,
                    storylineId: existing.storylineId,
                    chapterId: existing.chapterId,
                    mapId: existing.mapId,
                    tags: existing.tags,
                    requiredActors: existing.requiredActors,
                    timeline: existing.timeline,
                    notes: notes,
                    metadata: existing.metadata,
                    legacyBridge: existing.legacyBridge,
                  ),
                );
                setState(() => _project = result.updatedProject);
                return true;
              },
              onRemoveCinematic: ({required String cinematicId}) async {
                final result = removeCinematicAsset(_project, cinematicId);
                setState(() => _project = result.updatedProject);
                return true;
              },
              onOpenLegacyCutsceneStudio: () {},
            ),
          ),
        ),
      ),
    );
  }

  String _nextCinematicId(String title) {
    final slug = title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final base = slug.isEmpty ? 'cinematic' : 'cinematic_$slug';
    final existingIds = _project.cinematics.map((asset) => asset.id).toSet();
    if (!existingIds.contains(base)) {
      return base;
    }
    var index = 2;
    while (existingIds.contains('${base}_$index')) {
      index++;
    }
    return '${base}_$index';
  }
}

ProjectManifest _project({
  List<CinematicAsset>? cinematics,
  List<CinematicAsset> extraCinematics = const [],
  bool includeBridge = true,
}) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'cinematic_project',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(id: 'map_lab', name: 'Lab map', relativePath: 'lab.json'),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    scenes: [
      if (cinematics == null)
        _sceneReferencing(
          id: 'scene_canonical',
          name: 'Canonical scene',
          nodeId: 'node_cinematic',
          nodeTitle: 'Play intro',
          cinematicId: 'cinematic_intro',
        ),
      if (includeBridge)
        _sceneReferencing(
          id: 'scene_bridge',
          name: 'Bridge scene',
          nodeId: 'node_bridge',
          nodeTitle: 'Play bridge',
          cinematicId: 'scenario_cutscene',
        ),
    ],
    scenarios: includeBridge
        ? const <ScenarioAsset>[
            ScenarioAsset(
              id: 'scenario_cutscene',
              name: 'Legacy cutscene',
              scope: ScenarioScope.localEventFlow,
              entryNodeId: 'start',
              metadata: <String, String>{
                'authoring.cutsceneSchema': 'cutscene-studio-v0',
              },
            ),
          ]
        : const <ScenarioAsset>[],
    cinematics: [
      ...?cinematics,
      if (cinematics == null)
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          description: 'Camera reveal.',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(
              actorId: 'actor_professor',
              label: 'Professor',
            ),
          ],
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_camera',
                kind: CinematicTimelineStepKind.camera,
                label: 'Camera reveal',
                durationMs: 500,
              ),
              CinematicTimelineStep(
                id: 'step_emote',
                kind: CinematicTimelineStepKind.actorEmote,
                label: 'Professor reacts',
                durationMs: 250,
                actorId: 'actor_professor',
              ),
            ],
          ),
        ),
      ...extraCinematics,
    ],
  );
}

SceneAsset _sceneReferencing({
  required String id,
  required String name,
  required String nodeId,
  required String nodeTitle,
  required String cinematicId,
}) {
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: nodeId,
          kind: SceneNodeKind.cinematic,
          title: nodeTitle,
          payload: SceneCinematicPayload(cinematicId: cinematicId),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
    ),
  );
}

void _setLargeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
