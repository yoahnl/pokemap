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
    'PST-060 navigates, edits, saves, restarts, and restores from disk',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'personalization-phase-6-restart-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final projectFile = File('${root.path}/project.json');
      final initial = buildShellChromeProject(name: 'Phase 6 Studio');
      projectFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(initial.toJson()),
        flush: true,
      );
      const expectedProfile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(
          accentColor: '#6750A4',
          layoutVariant: 'cinematic',
        ),
        theme: safeProjectSemanticTheme,
      );

      final firstContainer = ProviderContainer();
      final firstSubscription = firstContainer.listen<EditorState>(
        editorNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );
      final firstNotifier =
          firstContainer.read(editorNotifierProvider.notifier);
      firstNotifier.state = EditorState(
        projectRootPath: root.path,
        project: initial,
        workspaceMode: EditorWorkspaceMode.map,
      );

      expect(firstNotifier.state.workspaceMode, EditorWorkspaceMode.map);
      firstNotifier.selectPersonalizationStudioWorkspace();
      expect(
        firstNotifier.state.workspaceMode,
        EditorWorkspaceMode.personalizationStudio,
      );
      expect(
        await firstNotifier.applyPersonalizationStudioProfile(
          expectedProfile,
          label: 'PST-060 certification edit',
        ),
        isTrue,
      );
      expect(firstNotifier.state.isProjectDirty, isTrue);
      expect(await firstNotifier.savePersonalizationStudio(), isTrue);
      expect(firstNotifier.state.isProjectDirty, isFalse);

      final savedJson =
          jsonDecode(projectFile.readAsStringSync()) as Map<String, dynamic>;
      expect(
        ProjectManifest.fromJson(savedJson).presentation,
        expectedProfile,
      );
      expect(
        File(
          '${root.path}/.pokemap/recovery/personalization-studio.json',
        ).existsSync(),
        isFalse,
      );

      firstSubscription.close();
      firstContainer.dispose();

      final restartedProject = ProjectManifest.fromJson(
        jsonDecode(projectFile.readAsStringSync()) as Map<String, dynamic>,
      );
      final restartedContainer = ProviderContainer();
      addTearDown(restartedContainer.dispose);
      final restartedSubscription = restartedContainer.listen<EditorState>(
        editorNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(restartedSubscription.close);
      final restartedNotifier =
          restartedContainer.read(editorNotifierProvider.notifier);
      restartedNotifier.state = EditorState(
        projectRootPath: root.path,
        project: restartedProject,
        workspaceMode: EditorWorkspaceMode.map,
      );

      restartedNotifier.selectPersonalizationStudioWorkspace();
      expect(
        restartedNotifier.state.workspaceMode,
        EditorWorkspaceMode.personalizationStudio,
      );
      expect(
        await restartedNotifier.initializePersonalizationStudioSession(),
        isTrue,
      );
      expect(
        restartedNotifier.personalizationStudioSessionState?.draftProfile,
        expectedProfile,
      );
      expect(
        restartedNotifier.personalizationStudioSessionState?.savedProfile,
        expectedProfile,
      );
      expect(restartedNotifier.state.isProjectDirty, isFalse);
    },
  );
}
