import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  test('a new editor session restores the journaled presentation and history',
      () async {
    final root =
        Directory.systemTemp.createTempSync('personalization-recovery-test-');
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
    final firstNotifier = firstContainer.read(editorNotifierProvider.notifier);
    firstNotifier.state = EditorState(
      projectRootPath: root.path,
      project: project,
      workspaceMode: EditorWorkspaceMode.personalizationStudio,
    );
    expect(
        await firstNotifier.initializePersonalizationStudioSession(), isTrue);
    expect(
      await firstNotifier.applyPersonalizationStudioProfile(profile),
      isTrue,
    );
    final journal = File(
      '${root.path}/.pokemap/recovery/personalization-studio.json',
    );
    expect(journal.existsSync(), isTrue);
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
    final secondNotifier =
        secondContainer.read(editorNotifierProvider.notifier);
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
    expect(
      secondNotifier.personalizationStudioSessionState?.canUndo,
      isTrue,
    );

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
  });
}
