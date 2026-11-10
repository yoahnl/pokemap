import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/verification/data/local_verification_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'load_desktop_capture_fonts.dart';
import 'm2_ui_fixture.dart';
import 'm3_story_fixture.dart';
import 'ui05_story_backend_fixture.dart';

part 'ui05_narrative_port.dart';

class Ui05NarrativeFixture {
  Ui05NarrativeFixture(this.source, this.controller, this.port, this.visuals);
  final M3StoryFixture source;
  final WidgetMapController controller;
  final Ui05NarrativePort port;
  final StudioMapResources visuals;
  final captureKey = GlobalKey();
  static String eventId(int number) =>
      'evt_019abcde-9000-7000-8000-${number.toString().padLeft(12, '0')}';

  static Future<Ui05NarrativeFixture> create(
    WidgetTester tester, {
    int extraStories = 0,
  }) async {
    await loadDesktopCaptureFonts();
    final fixture = await createUi05StoryBackend(extraStories: extraStories);
    final port = LocalNarrativeAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
    );
    final controller = WidgetMapController(
      fixture.session,
      fixture.maps,
      tester,
    );
    await controller.initialize();
    final visuals = await StudioMapResources.load(
      fixture.session,
      controller.project!,
    );
    return Ui05NarrativeFixture(
      fixture,
      controller,
      Ui05NarrativePort(port, tester),
      visuals,
    );
  }

  Widget app(
    WidgetTester tester, {
    double textScale = 1,
    bool withOwners = false,
  }) => RepaintBoundary(
    key: captureKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: studioTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: MapWorkspaceScreen(
        controller: controller,
        narrativePort: port,
        storyPort: withOwners
            ? LocalStoryAdapter(
                session: source.session,
                mapAdapter: source.maps,
              )
            : null,
        scenePort: withOwners
            ? LocalSceneAdapter(
                session: source.session,
                mapAdapter: source.maps,
              )
            : null,
        eventPort: withOwners
            ? LocalEventAdapter(
                session: source.session,
                mapAdapter: source.maps,
              )
            : null,
        dialoguePort: withOwners
            ? LocalDialogueAdapter(
                session: source.session,
                mapAdapter: source.maps,
              )
            : null,
        verificationPort: withOwners
            ? LocalVerificationAdapter(
                session: source.session,
                mapAdapter: source.maps,
              )
            : null,
        loadVisuals: (_, _) async => visuals,
        runtimeBuilder: (_, _, _) => const SizedBox(),
        onClose: () async {},
        registerExitGuard: (_) {},
      ),
    ),
  );

  Future<void> seedLocalDraft(NarrativeWorkspaceController narrative) async {
    final record = controller.project!.eventRegistry!.records.firstWhere(
      (record) => record.id == eventId(2),
    );
    await narrative.openRecord(record);
    final edit = narrative.active!;
    final updated = edit.current.interaction.revise(
      name: 'Voyageuse · texte en préparation',
    );
    edit.change(interaction: updated);
    edit.document.commit(
      edit.document.current.copyWith(name: 'Jardin · travail non enregistré'),
    );
    narrative.changed();
  }

  Future<Map<String, List<int>>> diskSnapshot() async => {
    for (final file
        in await source.directory
            .list(recursive: true)
            .where((file) => file is File && !file.path.contains('/.pokemap/'))
            .cast<File>()
            .toList())
      file.path.substring(source.directory.path.length): await file
          .readAsBytes(),
  };
  Future<void> dispose() async {
    controller.dispose();
    await visuals.dispose();
    await source.directory.delete(recursive: true);
  }
}
