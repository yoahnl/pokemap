import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('dialogue and script authoring', () {
    test('strict Yarn compilation reports unknown commands and line numbers',
        () {
      final result = const DialogueAuthoringCompiler().compile(
        entry: _dialogue(),
        source: 'title: Start\n---\nBonjour\n<<teleport town>>\n===\n',
      );

      expect(result.canPublish, isFalse);
      expect(
        result.diagnostics
            .where((item) => item.code == 'yarn.command_unknown')
            .single,
        isA<DialogueAuthoringDiagnostic>()
            .having((value) => value.code, 'code', 'yarn.command_unknown')
            .having((value) => value.line, 'line', 4),
      );
    });

    test(
        'dialogue simulation exposes choices and outcomes without side effects',
        () {
      const source = '''
title: Start
---
Bonjour
-> Accepter
  <<outcome accepted>>
  Merci
-> Refuser
  <<outcome refused>>
  Au revoir
===
''';
      final compiled = const DialogueAuthoringCompiler().compile(
        entry: _dialogue(),
        source: source,
      );
      final trace = const DialogueSimulationService().simulate(
        compiled,
        choices: const {'Start': 1},
      );

      expect(compiled.canPublish, isTrue);
      expect(trace.transcript, ['Bonjour', 'Au revoir']);
      expect(trace.selectedChoices, ['Refuser']);
      expect(trace.outcomes, ['refused']);
      expect(trace.terminated, isTrue);
    });

    test('outcome removal is blocked while a Scene still consumes it', () {
      final manifest = _manifest(
        scenes: [_dialogueScene(outcomeId: 'accepted')],
      );
      final replacement = _dialogue().copyWith(
        declaredOutcomes: const [
          DialogueDeclaredOutcome(id: 'refused', label: 'Refuser'),
        ],
      );

      expect(
        () => const DialogueActions().update(
          manifest,
          entry: replacement,
        ),
        throwsA(
          isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'dialogue.outcome_references_blocking',
          ),
        ),
      );
    });

    test('legacy migration keeps identity and an exact readable source', () {
      const legacy = 'Bonjour, dresseur !\n<<ancienne_commande>>\nAu revoir.';
      final preview = const DialogueLegacyMigrationService().preview(
        entry: ProjectDialogueEntry(
          id: 'intro',
          name: 'Intro',
          relativePath: 'dialogues/intro.txt',
        ),
        source: legacy,
      );

      expect(preview.dialogueId, 'intro');
      expect(preview.sourcePreservedVerbatim, legacy);
      expect(preview.targetPath, 'dialogues/intro.yarn');
      expect(preview.generatedYarn, contains('ancienne_commande'));
      expect(preview.diagnostics.map((item) => item.code),
          contains('legacy.command_escaped'));
    });

    test('script simulation previews effects and never executes them', () {
      const script = ScriptAsset(
        id: 'reward',
        nodes: [
          ScriptNode(
            id: 'start',
            commands: [
              ScriptCommand(
                type: ScriptCommandType.giveItem,
                params: {'itemId': 'potion', 'quantity': '2'},
              ),
              ScriptCommand(type: ScriptCommandType.end),
            ],
          ),
        ],
      );

      final trace = const ScriptAuthoringSimulator().simulate(script);

      expect(trace.canRun, isTrue);
      expect(trace.effects, hasLength(1));
      expect(trace.effects.single.type, ScriptCommandType.giveItem);
      expect(trace.effects.single.parameters['quantity'], '2');
      expect(trace.terminated, isTrue);
    });

    test('generic dispatcher exposes dialogue and script lifecycle actions',
        () {
      final ids = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll({
          'dialogue.create',
          'dialogue.update',
          'dialogue.source_update',
          'dialogue.delete',
          'dialogue.migrate_legacy',
          'script.upsert',
          'script.delete',
        }),
      );
      expect(MapMutationDispatcher.canonical().descriptors.length, ids.length);
    });

    test('source update plan/apply/undo restores exact Yarn bytes', () async {
      final directory = await Directory.systemTemp.createTemp(
        'pokemap_dialogue_transaction_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await Directory('${directory.path}/dialogues').create();
      final original = utf8.encode(
        'title: Start\n---\nAncienne ligne\n-> Accepter\n'
        '  <<outcome accepted>>\n-> Refuser\n'
        '  <<outcome refused>>\n===\n',
      );
      final sourceFile = File('${directory.path}/dialogues/intro.yarn');
      await sourceFile.writeAsBytes(original);
      await File('${directory.path}/project.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(_manifest().toJson())}\n',
      );
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ).openProject(directory.path);
      final loader = ProjectSnapshotLoader(handles: handles);
      final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: loader,
        clock: () => DateTime.utc(2026, 7, 31, 12),
      );
      await api.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      final baseSnapshot = await loader.load(opened.projectHandle);
      final baseRevision = baseSnapshot.revision;
      final read = const ProjectQueryService().query(
        baseSnapshot,
        AuthoringQueryRequest(
          resourceKind: 'dialogue',
          operation: AuthoringQueryOperation.get,
          view: AuthoringQueryView.detail,
          ids: ['intro'],
        ),
      );
      expect(
        (read.items.single['source']! as Map)['text'],
        utf8.decode(original),
      );
      expect((read.items.single['compile']! as Map)['canPublish'], isTrue);
      const updated = 'title: Start\n---\nNouvelle ligne\n'
          '-> Accepter\n  <<outcome accepted>>\n'
          '-> Refuser\n  <<outcome refused>>\n===\n';

      final plan = await api.plan(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'req-dialogue-source-update',
          actionId: 'dialogue.source_update',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: const {'dialogueId': 'intro', 'source': updated},
          expectedRevision: baseRevision,
          idempotencyKey: 'idem-dialogue-source-update',
        ),
      );
      final applied = await api.apply(
        opened.projectHandle,
        planId: plan['planId']! as String,
        operationId: 'op-dialogue-source-update',
      );
      expect(await sourceFile.readAsString(), updated);
      final receipt = Map<String, Object?>.from(applied['receipt']! as Map);

      await api.undo(
        opened.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'idem-dialogue-source-update-undo',
      );
      expect(await sourceFile.readAsBytes(), original);
    });
  });
}

ProjectDialogueEntry _dialogue() => const ProjectDialogueEntry(
      id: 'intro',
      name: 'Intro',
      relativePath: 'dialogues/intro.yarn',
      defaultStartNode: 'Start',
      declaredOutcomes: [
        DialogueDeclaredOutcome(id: 'accepted', label: 'Accepter'),
        DialogueDeclaredOutcome(id: 'refused', label: 'Refuser'),
      ],
    );

ProjectManifest _manifest({List<SceneAsset> scenes = const []}) =>
    ProjectManifest(
      name: 'Narrative fixture',
      maps: const [],
      tilesets: const [],
      dialogues: [_dialogue()],
      scenes: scenes,
    );

SceneAsset _dialogueScene({required String outcomeId}) => SceneAsset(
      id: 'intro_scene',
      name: 'Intro scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
              dialogueId: 'intro',
              expectedOutcomes: [outcomeId],
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start_dialogue',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'dialogue',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'dialogue_outcome',
            fromNodeId: 'dialogue',
            fromPortId: outcomeId,
            toNodeId: 'end',
            kind: SceneEdgeKind.dialogueOutcome,
          ),
        ],
      ),
    );
