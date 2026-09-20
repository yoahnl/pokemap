import 'dart:async';

import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/dialogue_adapter_fixture.dart';

void main() {
  test(
    'interruption between manifest and source recovers the coherent pair',
    () async {
      final f = await DialogueAdapterFixture.create();
      addTearDown(f.dispose);
      var interrupted = false;
      final port = f.adapter(
        faultInjector: (context) {
          if (!interrupted &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted) {
            interrupted = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      final base = await port.load('gare');
      final entry = base.entry.copyWith(
        declaredOutcomes: const [
          DialogueDeclaredOutcome(id: 'partir', label: 'Partir'),
        ],
      );
      final source = base.source.replaceFirst(
        'Bonjour !',
        'Bon départ !\n-> Partir\n  <<outcome partir>>',
      );
      final receipt = await port.publish(
        id: 'gare',
        base: base,
        entry: entry,
        source: source,
      );
      expect(interrupted, isTrue);
      final disk = (await f.readManifest()).dialogues.single;
      final written = await f.file(disk.relativePath).readAsString();
      expect(disk, entry);
      expect(written, source);
      expect(receipt.snapshot!.source, source);
      expect(
        const DialogueAuthoringCompiler()
            .compile(entry: disk, source: written)
            .canPublish,
        isTrue,
      );
      expect(
        const DialogueAuthoringCompiler()
            .compile(entry: disk, source: written)
            .emittedOutcomes,
        ['partir'],
      );
    },
  );

  test(
    'strict compilation rejects unsupported commands without touching either file',
    () async {
      final f = await DialogueAdapterFixture.create();
      addTearDown(f.dispose);
      final port = f.adapter();
      final base = await port.load('gare');
      final before = await f.file('project.json').readAsBytes();
      await expectLater(
        port.publish(
          id: 'gare',
          base: base,
          entry: base.entry.copyWith(name: 'Nom non publié'),
          source: base.source.replaceFirst('Bonjour !', '<<giveItem potion>>'),
        ),
        throwsA(
          isA<DialogueFailure>().having(
            (e) => e.details['code'],
            'code',
            'dialogue.compile_blocking',
          ),
        ),
      );
      expect(await f.file('project.json').readAsBytes(), before);
      expect(await f.file(base.entry.relativePath).readAsString(), base.source);
    },
  );

  test(
    'delete and missing external Yarn entry refuse with consumer paths',
    () async {
      final f = await DialogueAdapterFixture.create(scenes: [_scene()]);
      addTearDown(f.dispose);
      final port = f.adapter();
      final base = await port.load('gare');
      final before = await f.file('project.json').readAsBytes();
      await expectLater(
        port.publish(id: 'gare', base: base, entry: null, source: null),
        throwsA(
          isA<DialogueFailure>().having(
            (e) => e.details['references'],
            'consumers',
            isNotEmpty,
          ),
        ),
      );
      await expectLater(
        port.publish(
          id: 'gare',
          base: base,
          entry: base.entry.copyWith(defaultStartNode: 'Renomme'),
          source: base.source.replaceFirst('Accueil', 'Renomme'),
        ),
        throwsA(
          isA<DialogueFailure>().having(
            (e) => e.details['code'],
            'code',
            'dialogue.scene_start_references_blocking',
          ),
        ),
      );
      expect(await f.file('project.json').readAsBytes(), before);
      expect(await f.file(base.entry.relativePath).readAsString(), base.source);
    },
  );

  test(
    'mutex rechecks the exact source baseline after waiting for another save',
    () async {
      final f = await DialogueAdapterFixture.create();
      addTearDown(f.dispose);
      final entered = Completer<void>();
      final release = Completer<void>();
      final delayed = f.adapter(
        faultInjector: (context) async {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterJournalPrepared) {
            entered.complete();
            await release.future;
          }
        },
      );
      final base = await delayed.load('gare');
      final first = delayed.publish(
        id: 'gare',
        base: base,
        entry: base.entry,
        source: base.source.replaceFirst('Bonjour', 'Premier'),
      );
      await entered.future;
      final second = f.adapter().publish(
        id: 'gare',
        base: base,
        entry: base.entry,
        source: base.source.replaceFirst('Bonjour', 'Second'),
      );
      final failed = expectLater(second, throwsA(isA<DialogueFailure>()));
      release.complete();
      await first;
      await failed;
      expect(
        await f.file(base.entry.relativePath).readAsString(),
        contains('Premier'),
      );
    },
  );

  test(
    'missing malformed and empty sources do not fabricate a replacement',
    () async {
      final f = await DialogueAdapterFixture.create();
      addTearDown(f.dispose);
      final file = f.file(DialogueAdapterFixture.entry.relativePath);
      final manifest = await f.file('project.json').readAsBytes();
      await file.delete();
      await expectLater(
        f.adapter().load('gare'),
        throwsA(isA<DialogueFailure>()),
      );
      expect(await file.exists(), isFalse);
      await file.writeAsBytes([0xff, 0xfe]);
      await expectLater(
        f.adapter().load('gare'),
        throwsA(isA<DialogueFailure>()),
      );
      expect(await file.readAsBytes(), [0xff, 0xfe]);
      await file.writeAsString('');
      expect((await f.adapter().load('gare')).source, isEmpty);
      expect(await f.file('project.json').readAsBytes(), manifest);
    },
  );

  test(
    'an existing unregistered source cannot be overwritten by creation',
    () async {
      final f = await DialogueAdapterFixture.create(entries: []);
      addTearDown(f.dispose);
      final file = f.file(DialogueAdapterFixture.entry.relativePath);
      await file.parent.create(recursive: true);
      await file.writeAsString('unregistered original');
      await expectLater(
        f.adapter().publish(
          id: 'gare',
          base: null,
          entry: DialogueAdapterFixture.entry,
          source: DialogueAdapterFixture.source,
        ),
        throwsA(isA<DialogueFailure>()),
      );
      expect(await file.readAsString(), 'unregistered original');
      expect((await f.readManifest()).dialogues, isEmpty);
    },
  );
}

SceneAsset _scene() => SceneAsset(
  id: 'scene_consumer',
  name: 'Consommateur',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'conversation',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(
          dialogueId: 'gare',
          yarnNodeName: 'Accueil',
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'a',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'conversation',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'b',
        fromNodeId: 'conversation',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);
