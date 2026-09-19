import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

import '../resource_io/resource_fixture.dart';
import 'dialogue_draft_codec_test.dart' show dialogueFixture;

void main() {
  late ResourceFixture fixture;
  late LocalNarrativeAdapter narrative;
  setUp(() async {
    fixture = await ResourceFixture.create();
    narrative = LocalNarrativeAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
    );
  });
  tearDown(() => fixture.dispose());

  test(
    'interrupted multi file publication resumes before reporting success',
    () async {
      final base = await fixture.loadMap();
      var interrupted = false;
      narrative = LocalNarrativeAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
        faultInjector: (context) {
          if (!interrupted &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted) {
            interrupted = true;
            throw const FileSystemException('Injected failure after promotion');
          }
        },
      );
      final source = const DialogueDraftCodec().encode(dialogueFixture());
      final current = base.map.copyWith(name: 'Publication récupérée');
      final receipt = await narrative.publish(
        NarrativePublication(base: base, current: current, dialogues: [source]),
      );
      expect(interrupted, true);
      expect(receipt.savedMap, current);
      expect(
        (await narrative.readDialogue(
          receipt.manifest.dialogues.single,
        )).source,
        source.source,
      );
      expect((await fixture.loadMap()).map, current);
    },
  );

  test(
    'blocked recovery reports failure and never overwrites external map',
    () async {
      final base = await fixture.loadMap();
      final external = '${await fixture.mapFile.readAsString()}\n';
      narrative = LocalNarrativeAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
        faultInjector: (context) async {
          if (context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted &&
              context.promotionIndex == 0) {
            await fixture.mapFile.writeAsString(external);
            throw const FileSystemException('Injected external conflict');
          }
        },
      );
      final source = const DialogueDraftCodec().encode(dialogueFixture());
      await expectLater(
        narrative.publish(
          NarrativePublication(
            base: base,
            current: base.map.copyWith(name: 'Dirty'),
            dialogues: [source],
          ),
        ),
        throwsA(isA<NarrativeFailure>()),
      );
      expect(await fixture.mapFile.readAsString(), external);
      final journals = await Directory('${fixture.root.path}/.pokemap')
          .list(recursive: true)
          .where((entry) => entry.path.contains('journal'))
          .toList();
      expect(journals, isNotEmpty);
    },
  );

  test(
    'coherent publication keeps dirty map and rereads canonical source',
    () async {
      final base = await fixture.loadMap();
      final document = EditableMapDocument(base)
        ..commit(base.map.copyWith(name: 'Travail conservé'));
      final source = const DialogueDraftCodec().encode(dialogueFixture());
      final snapshot = document.current;
      final receipt = await narrative.publish(
        NarrativePublication(
          base: base,
          current: snapshot,
          dialogues: [source],
        ),
      );
      document.commit(snapshot.copyWith(name: 'Arrivé pendant publication'));
      document.acceptSave(receipt.savedMap, receipt.revision);
      expect(document.dirty, true);
      expect(document.current.name, 'Arrivé pendant publication');
      final reopened = LocalMapWorkspaceAdapter();
      final project = await reopened.loadProject(fixture.session);
      expect(
        (await reopened.loadMap(fixture.session, ResourceFixture.entry)).map,
        snapshot,
      );
      final stored = await narrative.readDialogue(project.dialogues.single);
      expect(stored.source, source.source);
      expect(stored.revision, receipt.sourceRevisions[source.entry.id]);
      document.restore(redo: false);
      expect(document.current, snapshot);
      expect(
        await File(
          '${fixture.root.path}/${source.entry.relativePath}',
        ).exists(),
        true,
      );
      await fixture.maps.saveMap(
        fixture.session,
        document.base,
        document.current.copyWith(name: 'Suite'),
      );
    },
  );
  test('external map edit prevents source and manifest publication', () async {
    final base = await fixture.loadMap();
    final manifest = await fixture.manifestFile.readAsBytes();
    await fixture.mapFile.writeAsString(
      '${await fixture.mapFile.readAsString()}\n',
    );
    final source = const DialogueDraftCodec().encode(dialogueFixture());
    await expectLater(
      narrative.publish(
        NarrativePublication(
          base: base,
          current: base.map,
          dialogues: [source],
        ),
      ),
      throwsA(isA<NarrativeFailure>()),
    );
    expect(await fixture.manifestFile.readAsBytes(), manifest);
    expect(
      await File('${fixture.root.path}/${source.entry.relativePath}').exists(),
      false,
    );
  });
  test('external dialogue edit blocks overwrite after reading draft', () async {
    final base = await fixture.loadMap();
    final source = const DialogueDraftCodec().encode(dialogueFixture());
    final first = await narrative.publish(
      NarrativePublication(base: base, current: base.map, dialogues: [source]),
    );
    final loaded = await narrative.readDialogue(
      first.manifest.dialogues.single,
    );
    final file = File('${fixture.root.path}/${source.entry.relativePath}');
    await file.writeAsString('${loaded.source}\n');
    await expectLater(
      narrative.publish(
        NarrativePublication(
          base: await fixture.loadMap(),
          current: base.map,
          dialogues: [loaded],
        ),
      ),
      throwsA(isA<NarrativeFailure>()),
    );
    expect(await file.readAsString(), '${loaded.source}\n');
  });
}
