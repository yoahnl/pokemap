import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  test('save then reopen restores the exact presentation profile', () async {
    final root =
        Directory.systemTemp.createTempSync('personalization-reopen-test-');
    addTearDown(() => root.deleteSync(recursive: true));
    final projectFile = File('${root.path}/project.json');
    final initial = buildShellChromeProject(name: 'Reopen presentation');
    projectFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(initial.toJson()),
      flush: true,
    );
    const profile = ProjectPresentationProfile(
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
    final firstNotifier = firstContainer.read(editorNotifierProvider.notifier);
    firstNotifier.state = EditorState(
      projectRootPath: root.path,
      project: initial,
      workspaceMode: EditorWorkspaceMode.personalizationStudio,
    );

    expect(
        await firstNotifier.initializePersonalizationStudioSession(), isTrue);
    expect(
      await firstNotifier.applyPersonalizationStudioProfile(profile),
      isTrue,
    );
    expect(
      ProjectManifest.fromJson(
        jsonDecode(projectFile.readAsStringSync()) as Map<String, dynamic>,
      ).presentation,
      isNull,
    );
    expect(await firstNotifier.saveProjectManifest(), isTrue);
    expect(firstNotifier.state.isProjectDirty, isFalse);
    final durable = ProjectManifest.fromJson(
      jsonDecode(projectFile.readAsStringSync()) as Map<String, dynamic>,
    );
    expect(durable.presentation, profile);
    firstSubscription.close();
    firstContainer.dispose();

    final secondContainer = ProviderContainer();
    addTearDown(secondContainer.dispose);
    final secondSubscription = secondContainer.listen<EditorState>(
      editorNotifierProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(secondSubscription.close);
    final secondNotifier =
        secondContainer.read(editorNotifierProvider.notifier);
    secondNotifier.state = EditorState(
      projectRootPath: root.path,
      project: durable,
      workspaceMode: EditorWorkspaceMode.personalizationStudio,
    );

    expect(
      await secondNotifier.initializePersonalizationStudioSession(),
      isTrue,
    );
    expect(
      secondNotifier.personalizationStudioSessionState?.draftProfile,
      profile,
    );
    expect(
      secondNotifier.personalizationStudioSessionState?.savedProfile,
      profile,
    );
    expect(secondNotifier.state.isProjectDirty, isFalse);
  });
}
