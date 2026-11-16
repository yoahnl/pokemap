import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/dialogues/application/dialogue_localization_editing.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_catalog_session.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/story_draft/application/story_dialogue_text_edits.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';

typedef _Fixture = ({
  Directory root,
  LocalMapWorkspaceAdapter maps,
  ProjectSession session,
  LocalNarrativeCatalogSession owner,
  LocalDialogueAdapter port,
});

void main() {
  test(
    'an authoring connection cannot be borrowed from another project',
    () async {
      final a = await _fixture();
      final b = await _fixture();
      final base = await a.port.load('shared');
      final wrong = LocalDialogueAdapter(
        session: a.session,
        mapAdapter: a.maps,
        publicationSession: b.owner,
      );
      final heads = [
        for (final f in [a, b])
          await File('${f.root.path}/catalog/HEAD.json').readAsBytes(),
      ];
      await expectLater(
        wrong.publish(
          id: 'shared',
          base: base,
          entry: base.entry,
          source: base.source.replaceFirst('Bonjour', 'Modification interdite'),
        ),
        throwsA(isA<DialogueFailure>()),
      );
      for (final (i, f) in [a, b].indexed) {
        expect(
          await File('${f.root.path}/dialogues/shared.yarn').readAsString(),
          base.source,
        );
        expect(
          await File('${f.root.path}/catalog/HEAD.json').readAsBytes(),
          heads[i],
        );
      }
    },
  );

  test(
    'successive durable saves reuse the owned authoring connection',
    () async {
      final f = await _fixture();
      final first = await _context(f);
      var base = await f.port.load('shared');
      for (final text in ['Etiquette : texte', '(Toujours une réplique.)']) {
        base = (await _save(f, base, text)).snapshot!;
        expect(
          await File('${f.root.path}/dialogues/shared.yarn').readAsString(),
          base.source,
        );
        expect(identical(await _context(f), first), isTrue);
      }
      await f.owner.close();
      expect(
        () => first.handles.resolveProject(first.opened.projectHandle),
        throwsA(isA<WorkspaceHandleException>()),
      );
      await expectLater(f.owner.prepare(), throwsStateError);
    },
  );

  test('an external catalog revision renews the connection without losing its edit', () async {
    final f = await _fixture();
    final before = await _context(f);
    var base = await f.port.load('shared');
    final other = LocalDialogueAdapter(session: f.session, mapAdapter: f.maps);
    base = (await other.publish(
      id: 'shared',
      base: base,
      entry: base.entry.copyWith(name: 'Nom externe'),
      source: base.source,
    )).snapshot!;
    final receipt = await _save(f, base, 'Nouvelle source : conservée');
    expect(receipt.snapshot!.entry.name, 'Nom externe');
    expect(identical(await _context(f), before), isFalse);
    expect(
      () => before.handles.resolveProject(before.opened.projectHandle),
      throwsA(isA<WorkspaceHandleException>()),
    );
  });

  test(
    'a cached connection still refuses an externally changed source atomically',
    () async {
      final f = await _fixture();
      final before = await _context(f);
      final base = await f.port.load('shared');
      final file = File('${f.root.path}/dialogues/shared.yarn');
      final external = base.source.replaceFirst('Bonjour', 'Version externe');
      await file.writeAsString(external, flush: true);
      final head = File('${f.root.path}/catalog/HEAD.json');
      final original = await head.readAsBytes();
      await expectLater(
        _save(f, base, 'Saisie conservée : refusée'),
        throwsA(isA<DialogueFailure>()),
      );
      expect(await file.readAsString(), external);
      expect(await head.readAsBytes(), original);
      expect(
        () => before.handles.resolveProject(before.opened.projectHandle),
        throwsA(isA<WorkspaceHandleException>()),
      );
    },
  );

  test('disposing waits for an in-flight durable save before releasing its handles', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final f = await _fixture(
      fault: (context) async {
        if (context.checkpoint ==
            AuthoringTransactionCheckpoint.afterJournalPrepared) {
          if (!entered.isCompleted) entered.complete();
          await release.future;
        }
      },
    );
    final context = await _context(f);
    final saving = _save(
      f,
      await f.port.load('shared'),
      'Publication en cours : durable',
    );
    await entered.future;
    var closed = false;
    final closing = f.owner.close().then((_) => closed = true);
    await Future<void>.delayed(Duration.zero);
    expect(closed, isFalse);
    release.complete();
    final receipt = await saving;
    await closing;
    expect(
      receipt.snapshot!.source,
      contains('Publication en cours : durable'),
    );
    expect(
      () => context.handles.resolveProject(context.opened.projectHandle),
      throwsA(isA<WorkspaceHandleException>()),
    );
  });
}

Future<LocalNarrativeCatalogContext> _context(_Fixture f) =>
    f.maps.withResourceMutation(
      () async => f.owner.obtain(await f.maps.resourceRevision(f.session)),
    );

Future<DialoguePublicationReceipt> _save(
  _Fixture f,
  DialogueSourceSnapshot base,
  String text,
) {
  final form = DialogueLocalizationEditing(
    StoryDialogueSource(
      entry: base.entry,
      source: base.source,
      revision: base.revision,
    ),
  );
  form.writeSource(form.localization.units.single.id, text);
  final next = form.build();
  return f.port.publish(
    id: base.entry.id,
    base: base,
    entry: next.entry,
    source: next.source,
    lineTextEdits: storyDialogueTextEdits(form.base, next),
  );
}

Future<_Fixture> _fixture({AuthoringTransactionFaultInjector? fault}) async {
  final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
  final qa = Directory(
    Platform.environment['AVELUNE_QA_ROOT'] ??
        '$home/Library/Caches/AveluneQA/dialogue-publication-session-tests',
  );
  final root = await (await qa.create(recursive: true)).createTemp('catalog-');
  addTearDown(() => root.delete(recursive: true));
  const source = 'title: Start\n---\nBonjour\n===\n';
  final localization = readLocalizedDialogue(
    source: source,
    sourceLocale: 'fr',
  ).localization;
  final entry = ProjectDialogueEntry(
    id: 'shared',
    name: 'Partagé',
    relativePath: 'dialogues/shared.yarn',
    localization: localization,
  );
  final store = await CatalogStorageStore.open(projectRoot: root.path);
  final working = await WorkingProjectCatalog.create(
    store: store,
    projectId: 'dialogue-session',
    project: ProjectManifest(
      name: 'QA',
      maps: [],
      tilesets: [],
      dialogues: [entry],
    ),
  );
  await working.close();
  final file = File('${root.path}/${entry.relativePath}');
  await file.parent.create(recursive: true);
  await file.writeAsString(source, flush: true);
  final sessions = LocalProjectSessionAdapter();
  final session = await sessions.open(root.path);
  addTearDown(() => sessions.close(session));
  final maps = LocalMapWorkspaceAdapter();
  await maps.loadProject(session);
  final owner = LocalNarrativeCatalogSession(
    session: session,
    mapAdapter: maps,
    faultInjector: fault,
  );
  addTearDown(owner.close);
  await owner.prepare();
  return (
    root: root,
    session: session,
    maps: maps,
    owner: owner,
    port: LocalDialogueAdapter(
      session: session,
      mapAdapter: maps,
      publicationSession: owner,
    ),
  );
}
