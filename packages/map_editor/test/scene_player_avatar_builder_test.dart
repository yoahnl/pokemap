import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_node_read_only_inspector.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('L15 Scene inspector recognizes a persisted avatar consequence', (
    tester,
  ) async {
    final node = SceneNode(
      id: 'avatar',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.fromJson({
        'consequence': {'kind': 'setPlayerAvatar', 'characterId': 'uniform'},
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SceneNodeReadOnlyInspector(
              scene: NarrativeSceneSummary(
                id: 'scene',
                name: 'Tenue',
                nodeCount: 3,
                edgeCount: 2,
                declaredOutcomeCount: 0,
                declaredOutcomes: [],
                tags: [],
                graph: _graph(node),
                layout: SceneGraphLayout(),
                diagnostics: SceneDiagnosticsReport(diagnostics: []),
              ),
              selectedNodeId: 'avatar',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Changer l’avatar du joueur'), findsWidgets);
    expect(find.text('Conséquence non reconnue.'), findsNothing);
  });

  testWidgets(
    'L15 avatar builder selects labelled project characters without raw IDs',
    (tester) async {
      expect(
        NarrativeCommandCatalog.canonical().byId('setPlayerAvatar'),
        isNotNull,
      );
      SceneNodePayload? submitted;
      await _pump(tester, onSubmit: (value) => submitted = value);
      expect(find.text('Tenue de voyage'), findsOneWidget);
      expect(find.byType(PokeMapTextField), findsNothing);
      final picker = find.byType(PokeMapDropdownField<String>);
      expect(picker, findsOneWidget);
      final widget = tester.widget<PokeMapDropdownField<String>>(picker);
      expect(widget.items.map((entry) => entry.label), [
        'Tenue de voyage',
        'Uniforme',
      ]);
      widget.onChanged('uniform');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
      final action = submitted! as SceneActionPayload;
      expect(action.consequence!.toJson(), {
        'kind': 'setPlayerAvatar',
        'characterId': 'uniform',
      });
    },
  );

  testWidgets(
    'L15 Scene inspector edits the saved costume and preserves its metadata',
    (tester) async {
      SceneConsequence? updated;
      final node = SceneNode(
        id: 'avatar',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setPlayerAvatar(
            characterId: 'uniform',
            label: 'Tenue de service',
            notes: 'Conserver ces notes',
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SceneNodeReadOnlyInspector(
                project: _project(),
                scene: NarrativeSceneSummary(
                  id: 'scene',
                  name: 'Tenue',
                  nodeCount: 3,
                  edgeCount: 2,
                  declaredOutcomeCount: 0,
                  declaredOutcomes: [],
                  tags: [],
                  graph: _graph(node),
                  layout: SceneGraphLayout(),
                  diagnostics: SceneDiagnosticsReport(diagnostics: []),
                ),
                selectedNodeId: 'avatar',
                onUpdateActionConsequence:
                    ({required nodeId, required consequence}) async {
                      expect(nodeId, 'avatar');
                      updated = consequence;
                      return true;
                    },
              ),
            ),
          ),
        ),
      );
      final picker = tester.widget<PokeMapDropdownField<String>>(
        find.byType(PokeMapDropdownField<String>),
      );
      expect(picker.value, 'uniform');
      picker.onChanged('original');
      await tester.pump();
      final submit = find.byKey(const ValueKey('scene-action-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      expect(updated!.toJson(), {
        'kind': 'setPlayerAvatar',
        'characterId': 'original',
        'label': 'Tenue de service',
        'notes': 'Conserver ces notes',
      });
      expect(find.byType(PokeMapTextField), findsNothing);
    },
  );

  testWidgets(
    'L15 avatar builder reopens the saved selection instead of first costume',
    (tester) async {
      expect(
        NarrativeCommandCatalog.canonical().byId('setPlayerAvatar'),
        isNotNull,
      );
      final payload = SceneActionPayload.fromJson({
        'consequence': {'kind': 'setPlayerAvatar', 'characterId': 'uniform'},
      });
      await _pump(tester, initialPayload: payload);
      final picker = tester.widget<PokeMapDropdownField<String>>(
        find.byType(PokeMapDropdownField<String>),
      );
      expect(picker.value, 'uniform');
    },
  );

  testWidgets(
    'L15 avatar builder blocks empty or invalid character catalogues',
    (tester) async {
      expect(
        NarrativeCommandCatalog.canonical().byId('setPlayerAvatar'),
        isNotNull,
      );
      for (final characters in [
        <ProjectCharacterEntry>[],
        [_character('invalid', 'Sans animation', animations: false)],
        [_character('duplicate', 'A'), _character('duplicate', 'B')],
      ]) {
        await _pump(tester, characters: characters);
        expect(
          tester
              .widget<PokeMapButton>(
                find.byKey(const ValueKey('scene-action-submit')),
              )
              .onPressed,
          isNull,
        );
        expect(find.byType(PokeMapTextField), findsNothing);
        expect(find.textContaining('Aucun'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'L15 avatar builder refuses a removed saved costume without replacing it',
    (tester) async {
      expect(
        NarrativeCommandCatalog.canonical().byId('setPlayerAvatar'),
        isNotNull,
      );
      final payload = SceneActionPayload.fromJson({
        'consequence': {'kind': 'setPlayerAvatar', 'characterId': 'removed'},
      });
      SceneNodePayload? repaired;
      await _pump(tester, initialPayload: payload, onSubmit: (value) => repaired = value);
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('scene-action-submit')),
            )
            .onPressed,
        isNull,
      );
      expect(find.textContaining('supprimé'), findsOneWidget);
      expect(find.byType(PokeMapTextField), findsNothing);
      final picker = tester.widget<PokeMapDropdownField<String>>(find.byType(PokeMapDropdownField<String>));
      expect(picker.value, '');
      picker.onChanged('original');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
      expect((repaired! as SceneActionPayload).consequence!.toJson(), {'kind': 'setPlayerAvatar', 'characterId': 'original'});
    },
  );
}

SceneGraph _graph(SceneNode node) => SceneGraph(
  startNodeId: 'start',
  nodes: [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    node,
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ],
  edges: [
    SceneEdge(
      id: 'enter',
      fromNodeId: 'start',
      fromPortId: 'completed',
      toNodeId: node.id,
      kind: SceneEdgeKind.defaultFlow,
    ),
    SceneEdge(
      id: 'leave',
      fromNodeId: node.id,
      fromPortId: 'completed',
      toNodeId: 'end',
      kind: SceneEdgeKind.actionCompleted,
    ),
  ],
);

ProjectCharacterEntry _character(
  String id,
  String name, {
  bool animations = true,
}) => ProjectCharacterEntry(
  id: id,
  name: name,
  tilesetId: 'actors',
  animations: [
    if (animations)
      for (final direction in EntityFacing.values)
        CharacterAnimation(
          state: CharacterAnimationState.walk,
          direction: direction,
          frames: [
            CharacterAnimationFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
            ),
          ],
        ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  ValueChanged<SceneNodePayload>? onSubmit,
  SceneActionPayload? initialPayload,
  List<ProjectCharacterEntry>? characters,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SceneActionBuilder(
            key: ValueKey(characters),
            initialCommandId: 'setPlayerAvatar',
            runtimeCommandIds: const {'setPlayerAvatar'},
            allowCommandSelection: false,
            project: _project(characters),
            initialPayload: initialPayload,
            onSubmit: onSubmit ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ProjectManifest _project([List<ProjectCharacterEntry>? characters]) =>
    ProjectManifest(
      name: 'Avatar',
      maps: [],
      tilesets: [
        const ProjectTilesetEntry(
          id: 'actors',
          name: 'Acteurs',
          relativePath: 'actors.json',
        ),
      ],
      characters:
          characters ??
          [
            _character('original', 'Tenue de voyage'),
            _character('uniform', 'Uniforme'),
          ],
    );
