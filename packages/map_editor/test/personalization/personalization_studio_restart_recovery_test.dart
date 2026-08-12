import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  test(
    'a new editor session restores the journaled presentation and history',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'personalization-recovery-test-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final projectFile = File('${root.path}/project.json');
      final project = buildShellChromeProject(name: 'Recovered presentation');
      projectFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(project.toJson()),
        flush: true,
      );
      const profile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(
          accentColor: '#765432',
          layoutVariant: 'cinematic',
        ),
      );

      final firstContainer = ProviderContainer();
      final firstSubscription = firstContainer.listen<EditorState>(
        editorNotifierProvider,
        (_, _) {},
        fireImmediately: true,
      );
      final firstNotifier = firstContainer.read(
        editorNotifierProvider.notifier,
      );
      firstNotifier.state = EditorState(
        projectRootPath: root.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      );
      expect(
        await firstNotifier.initializePersonalizationStudioSession(),
        isTrue,
      );
      expect(
        await firstNotifier.applyPersonalizationStudioProfile(profile),
        isTrue,
      );
      final journal = File(
        '${root.path}/.pokemap/recovery/personalization-studio.json',
      );
      expect(journal.existsSync(), isTrue);
      final journalJson =
          jsonDecode(journal.readAsStringSync()) as Map<String, dynamic>;
      final journalDocument = journalJson['document'] as Map<String, dynamic>;
      expect(journalDocument['schemaVersion'], 10);
      expect(journalDocument, isNot(contains('maps')));
      expect(journalDocument, isNot(contains('name')));
      expect(
        ProjectManifest.fromJson(
          jsonDecode(projectFile.readAsStringSync()) as Map<String, dynamic>,
        ).presentation,
        isNull,
      );
      firstSubscription.close();
      firstContainer.dispose();

      final secondContainer = ProviderContainer();
      addTearDown(secondContainer.dispose);
      final secondSubscription = secondContainer.listen<EditorState>(
        editorNotifierProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(secondSubscription.close);
      final secondNotifier = secondContainer.read(
        editorNotifierProvider.notifier,
      );
      secondNotifier.state = EditorState(
        projectRootPath: root.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      );

      expect(
        await secondNotifier.initializePersonalizationStudioSession(),
        isTrue,
      );
      expect(
        secondNotifier.personalizationStudioSessionState?.isRecovered,
        isTrue,
      );
      expect(
        secondNotifier.personalizationStudioSessionState?.draftProfile,
        profile,
      );
      expect(secondNotifier.state.isProjectDirty, isTrue);
      expect(secondNotifier.personalizationStudioSessionState?.canUndo, isTrue);

      expect(await secondNotifier.undoPersonalizationStudio(), isTrue);
      expect(
        secondNotifier.personalizationStudioSessionState?.draftProfile,
        project.effectivePresentation,
      );
      expect(await secondNotifier.redoPersonalizationStudio(), isTrue);
      expect(
        secondNotifier.personalizationStudioSessionState?.draftProfile,
        profile,
      );
    },
  );

  test(
    'migrates a stale full-project journal without blocking the Studio',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'personalization-legacy-recovery-test-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final projectFile = File('${root.path}/project.json');
      final recoveryFile = File(
        '${root.path}/.pokemap/recovery/personalization-studio.json',
      );
      final previousProject = buildShellChromeProject(name: 'Previous project');
      const currentProfile = ProjectPresentationProfile();
      final currentProject = previousProject.copyWith(
        name: 'Current project',
        presentation: currentProfile,
      );
      const recoveredProfile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(accentColor: '#765432'),
      );
      projectFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(currentProject.toJson()),
        flush: true,
      );
      recoveryFile.parent.createSync(recursive: true);
      final legacyBaseline = <String, Object?>{
        ...previousProject.toJson(),
        'presentation': <String, Object?>{
          ...currentProfile.toJson(),
          'schemaVersion': 4,
        },
      };
      final legacyDocument = <String, Object?>{
        ...previousProject.toJson(),
        'presentation': <String, Object?>{
          ...recoveredProfile.toJson(),
          'schemaVersion': 4,
        },
      };
      recoveryFile.writeAsStringSync(
        jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'documentId': 'personalization-studio',
          'baseRevision': 'stale-project-revision',
          'baseline': legacyBaseline,
          'document': legacyDocument,
          'undoEntries': <Object?>[
            <String, Object?>{
              'operationId': 'legacy-edit',
              'label': 'Ancienne modification',
              'before': legacyBaseline,
              'after': legacyDocument,
            },
          ],
          'redoEntries': <Object?>[],
        }),
        flush: true,
      );
      final legacyJournalLength = recoveryFile.lengthSync();

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: root.path,
        project: currentProject,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      );

      expect(await notifier.initializePersonalizationStudioSession(), isTrue);

      final session = notifier.personalizationStudioSessionState;
      expect(session?.isConflicted, isFalse);
      expect(session?.isDirty, isTrue);
      expect(session?.draftProfile, recoveredProfile);
      expect(notifier.state.project?.name, 'Current project');
      final migratedJournal =
          jsonDecode(recoveryFile.readAsStringSync()) as Map<String, dynamic>;
      final migratedDocument =
          migratedJournal['document'] as Map<String, dynamic>;
      expect(migratedDocument['schemaVersion'], 10);
      expect(migratedDocument, isNot(contains('maps')));
      expect(migratedDocument, isNot(contains('name')));
      expect(recoveryFile.lengthSync(), lessThan(legacyJournalLength ~/ 4));
    },
  );

  test(
    'compacts a matching legacy journal as soon as it is restored',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'personalization-matching-legacy-recovery-test-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final projectFile = File('${root.path}/project.json');
      final recoveryFile = File(
        '${root.path}/.pokemap/recovery/personalization-studio.json',
      );
      final project = buildShellChromeProject(name: 'Current project');
      const recoveredProfile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(accentColor: '#765432'),
      );
      projectFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(project.toJson()),
        flush: true,
      );
      final projectRevision = narrativeEventBytesFingerprint(
        projectFile.readAsBytesSync(),
      );
      recoveryFile.parent.createSync(recursive: true);
      final legacyDocument = project.copyWith(presentation: recoveredProfile);
      recoveryFile.writeAsStringSync(
        jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'documentId': 'personalization-studio',
          'baseRevision': projectRevision,
          'baseline': project.toJson(),
          'document': legacyDocument.toJson(),
          'undoEntries': <Object?>[
            <String, Object?>{
              'operationId': 'legacy-edit',
              'label': 'Ancienne modification',
              'before': project.toJson(),
              'after': legacyDocument.toJson(),
            },
          ],
          'redoEntries': <Object?>[],
        }),
        flush: true,
      );
      final legacyJournalLength = recoveryFile.lengthSync();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: root.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      );

      expect(await notifier.initializePersonalizationStudioSession(), isTrue);

      expect(
        notifier.personalizationStudioSessionState?.draftProfile,
        recoveredProfile,
      );
      final compacted =
          jsonDecode(recoveryFile.readAsStringSync()) as Map<String, dynamic>;
      expect(compacted['document'], recoveredProfile.toJson());
      expect(recoveryFile.lengthSync(), lessThan(legacyJournalLength ~/ 4));
    },
  );
}
