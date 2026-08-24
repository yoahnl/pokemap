import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_authoring_transaction.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('Cinematics pilot journals, undoes, redoes and saves through CAS',
      () async {
    final root = await Directory.systemTemp.createTemp('narrative-editor-');
    addTearDown(() => root.delete(recursive: true));
    final before = _project(title: 'Introduction');
    final after = _project(title: 'Introduction locale');
    await _writeProject(root, before);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(editorNotifierProvider, (_, _) {});
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(projectRootPath: root.path, project: before);

    final applied = await notifier.applyNarrativeDocumentEdit(
      after,
      operationId: 'cinematic-title-edit',
      label: 'Renommer la cinématique',
      statusMessage: 'Titre de la cinématique modifié.',
    );

    expect(
      applied,
      isTrue,
      reason: 'status=${notifier.narrativeDocumentStatus} '
          'error=${notifier.state.errorMessage} '
          'message=${notifier.state.statusMessage}',
    );
    expect(notifier.state.project, after);
    expect(notifier.state.isProjectDirty, isTrue);
    expect(notifier.canUndoNarrativeDocument, isTrue);
    expect(
      await File('${root.path}/.pokemap/recovery/narrative-cinematics.json')
          .exists(),
      isTrue,
    );
    expect((await _readProject(root)).cinematics.single.title, 'Introduction');

    expect(await notifier.undoNarrativeDocument(), isTrue);
    expect(notifier.state.project, before);
    expect(await notifier.redoNarrativeDocument(), isTrue);
    expect(notifier.state.project, after);

    expect(await notifier.saveNarrativeDocument(), isTrue);
    expect(notifier.state.isProjectDirty, isFalse);
    expect(
      notifier.narrativeDocumentStatus,
      NarrativeDocumentSessionStatus.saved,
    );
    expect(
      (await _readProject(root)).cinematics.single.title,
      'Introduction locale',
    );
    expect(
      await File('${root.path}/.pokemap/recovery/narrative-cinematics.json')
          .exists(),
      isFalse,
    );

    // A later non-session workspace edit must not expose the old Cinematics
    // history through the shared shell shortcuts.
    notifier.state = notifier.state.copyWith(
      project: after.copyWith(name: 'Unrelated Storyline edit'),
      isProjectDirty: true,
    );
    expect(notifier.canUndoNarrativeDocument, isFalse);
    expect(notifier.canRedoNarrativeDocument, isFalse);
  });

  test('a new editor session restores an unsaved Cinematics journal', () async {
    final root = await Directory.systemTemp.createTemp('narrative-reopen-');
    addTearDown(() => root.delete(recursive: true));
    final before = _project(title: 'Introduction');
    final recovered = _project(title: 'Récupérée');
    await _writeProject(root, before);

    final firstContainer = ProviderContainer();
    firstContainer.listen(editorNotifierProvider, (_, _) {});
    final first = firstContainer.read(editorNotifierProvider.notifier);
    first.state = EditorState(projectRootPath: root.path, project: before);
    final applied = await first.applyNarrativeDocumentEdit(
      recovered,
      operationId: 'cinematic-recovery-edit',
      label: 'Modifier avant fermeture',
    );
    expect(
      applied,
      isTrue,
      reason: 'status=${first.narrativeDocumentStatus} '
          'error=${first.state.errorMessage} '
          'message=${first.state.statusMessage}',
    );
    firstContainer.dispose();

    final secondContainer = ProviderContainer();
    addTearDown(secondContainer.dispose);
    secondContainer.listen(editorNotifierProvider, (_, _) {});
    final second = secondContainer.read(editorNotifierProvider.notifier);
    second.state = EditorState(projectRootPath: root.path, project: before);

    await second.initializeNarrativeDocumentSession();

    expect(second.state.project, recovered);
    expect(second.state.isProjectDirty, isTrue);
    expect(
      second.narrativeDocumentStatus,
      NarrativeDocumentSessionStatus.recovered,
    );
  });

  test('a committed structural mutation rebases the Cinematics pilot session',
      () async {
    final root = await Directory.systemTemp.createTemp('narrative-rebase-');
    addTearDown(() => root.delete(recursive: true));
    final before = _project(title: 'Introduction');
    await _writeProject(root, before);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(editorNotifierProvider, (_, _) {});
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(projectRootPath: root.path, project: before);
    await notifier.initializeNarrativeDocumentSession();

    final created = await notifier.executeNarrativeAuthoringMutation(
      (project) => NarrativeAssetMutation.createCinematic(
        project,
        title: 'Deuxième cinématique',
      ),
      operationId: 'create-second-cinematic',
    );

    expect(created!.status, NarrativeAuthoringTransactionStatus.committed);
    expect(notifier.state.project!.cinematics, hasLength(2));
    expect(
      notifier.narrativeDocumentStatus,
      NarrativeDocumentSessionStatus.saved,
    );

    final rebased = notifier.state.project!;
    final first = rebased.cinematics.first;
    final edited = rebased.copyWith(
      cinematics: [
        CinematicAsset(
          id: first.id,
          title: 'Introduction après création',
          timeline: first.timeline,
        ),
        rebased.cinematics.last,
      ],
    );
    expect(
      await notifier.applyNarrativeDocumentEdit(
        edited,
        operationId: 'edit-after-structural-change',
        label: 'Modifier après une création',
      ),
      isTrue,
    );
    expect(await notifier.saveNarrativeDocument(), isTrue);
    expect(
      (await _readProject(root)).cinematics.first.title,
      'Introduction après création',
    );
  });

  test('Presentation recovery rebases over unrelated project changes',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'presentation-recovery-rebase-',
    );
    addTearDown(() => root.delete(recursive: true));
    final before = _presentationProject(
      name: 'Projet initial',
      title: 'Ouverture initiale',
    );
    final local = _presentationProject(
      name: 'Projet initial',
      title: 'Ouverture locale',
    );
    await _writeProject(root, before);

    final firstContainer = ProviderContainer();
    firstContainer.listen(editorNotifierProvider, (_, _) {});
    final first = firstContainer.read(editorNotifierProvider.notifier);
    first.state = EditorState(projectRootPath: root.path, project: before);
    expect(
      await first.applyNarrativeDocumentEdit(
        local,
        operationId: 'presentation-local-edit',
        label: 'Modifier les propriétés Presentation',
      ),
      isTrue,
    );
    firstContainer.dispose();

    final external = _presentationProject(
      name: 'Projet externe',
      title: 'Ouverture initiale',
    );
    await _writeProject(root, external);

    final secondContainer = ProviderContainer();
    addTearDown(secondContainer.dispose);
    secondContainer.listen(editorNotifierProvider, (_, _) {});
    final second = secondContainer.read(editorNotifierProvider.notifier);
    second.state = EditorState(projectRootPath: root.path, project: external);

    await second.initializeNarrativeDocumentSession();

    expect(
      second.narrativeDocumentStatus,
      NarrativeDocumentSessionStatus.recovered,
    );
    expect(second.state.errorMessage, isNull);
    expect(second.state.project!.name, 'Projet externe');
    expect(
      second.state.project!.presentationCinematics.single.title,
      'Ouverture locale',
    );
    expect(second.state.isProjectDirty, isTrue);
  });

  test('Presentation document saves durably through the narrative session',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'presentation-document-save-',
    );
    addTearDown(() => root.delete(recursive: true));
    final before = _presentationProject(
      name: 'Projet',
      title: 'Ouverture initiale',
    );
    final after = _presentationProject(
      name: 'Projet',
      title: 'Ouverture enregistrée',
    );
    await _writeProject(root, before);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(editorNotifierProvider, (_, _) {});
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(projectRootPath: root.path, project: before);

    expect(
      await notifier.applyNarrativeDocumentEdit(
        after,
        operationId: 'presentation-title-edit',
        label: 'Modifier les propriétés Presentation',
      ),
      isTrue,
    );

    expect(await notifier.saveNarrativeDocument(), isTrue);
    expect(
      notifier.narrativeDocumentStatus,
      NarrativeDocumentSessionStatus.saved,
    );
    expect(notifier.state.isProjectDirty, isFalse);
    expect(
      (await _readProject(root)).presentationCinematics.single.title,
      'Ouverture enregistrée',
    );
    expect(
      await File('${root.path}/.pokemap/recovery/narrative-cinematics.json')
          .exists(),
      isFalse,
    );
  });

  test('keep local preserves unrelated external project changes', () async {
    final root = await Directory.systemTemp.createTemp(
      'presentation-keep-local-',
    );
    addTearDown(() => root.delete(recursive: true));
    final before = _presentationProject(
      name: 'Projet initial',
      title: 'Ouverture initiale',
    );
    final local = _presentationProject(
      name: 'Projet initial',
      title: 'Ouverture locale',
    );
    await _writeProject(root, before);

    final firstContainer = ProviderContainer();
    firstContainer.listen(editorNotifierProvider, (_, _) {});
    final first = firstContainer.read(editorNotifierProvider.notifier);
    first.state = EditorState(projectRootPath: root.path, project: before);
    expect(
      await first.applyNarrativeDocumentEdit(
        local,
        operationId: 'presentation-conflicting-local-edit',
        label: 'Modifier les propriétés Presentation',
      ),
      isTrue,
    );
    firstContainer.dispose();

    final external = _presentationProject(
      name: 'Projet externe',
      title: 'Ouverture externe',
    );
    await _writeProject(root, external);

    final secondContainer = ProviderContainer();
    addTearDown(secondContainer.dispose);
    secondContainer.listen(editorNotifierProvider, (_, _) {});
    final second = secondContainer.read(editorNotifierProvider.notifier);
    second.state = EditorState(projectRootPath: root.path, project: external);
    await second.initializeNarrativeDocumentSession();
    expect(
      second.narrativeDocumentStatus,
      NarrativeDocumentSessionStatus.conflicted,
    );

    expect(await second.keepLocalNarrativeDocument(), isTrue);
    expect(second.state.project!.name, 'Projet externe');
    expect(
      second.state.project!.presentationCinematics.single.title,
      'Ouverture locale',
    );
    expect(await second.saveNarrativeDocument(), isTrue);
    final durable = await _readProject(root);
    expect(durable.name, 'Projet externe');
    expect(durable.presentationCinematics.single.title, 'Ouverture locale');
  });
}

ProjectManifest _project({required String title}) {
  return ProjectManifest(
    name: 'Narrative editor test',
    maps: const [],
    tilesets: const [],
    cinematics: [
      CinematicAsset(
        id: 'cinematic_intro',
        title: title,
        timeline: CinematicTimeline(),
      ),
    ],
  );
}

ProjectManifest _presentationProject({
  required String name,
  required String title,
}) {
  return ProjectManifest(
    name: name,
    version: ProjectVersion.v7,
    maps: const [],
    tilesets: const [],
    presentationCinematics: [
      PresentationCinematicAsset(
        id: 'presentation-opening',
        title: title,
        durationUs: 12000000,
      ),
    ],
  );
}

Future<void> _writeProject(Directory root, ProjectManifest project) {
  return File('${root.path}/project.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(project.toJson()),
    flush: true,
  );
}

Future<ProjectManifest> _readProject(Directory root) async {
  final json =
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>;
  return ProjectManifest.fromJson(json);
}
