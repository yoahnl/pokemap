import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/personalization/application/project_title_motion_import_service.dart';
import 'package:map_editor/src/features/personalization/presentation/project_title_motion_editor.dart';

void main() {
  testWidgets('explains both title loops and exposes guided actions', (
    tester,
  ) async {
    ProjectTitleMotionLoopRole? imported;
    ProjectTitleMotionLoopRole? removed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectTitleMotionEditor(
            profile: const ProjectTitleMotionProfile(promptLoop: _media),
            onImport: (role) => imported = role,
            onRemove: (role) => removed = role,
          ),
        ),
      ),
    );

    expect(find.text('Boucle d’invitation'), findsOneWidget);
    expect(find.text('Boucle du menu'), findsOneWidget);
    expect(find.textContaining('15 s et 24 Mio'), findsNWidgets(2));

    await tester.tap(
      find.byKey(const ValueKey<String>('title-motion-import-menu')),
    );
    await tester.pump();
    expect(imported, ProjectTitleMotionLoopRole.menu);

    await tester.tap(
      find.byKey(const ValueKey<String>('title-motion-remove-prompt')),
    );
    await tester.pump();
    expect(removed, ProjectTitleMotionLoopRole.prompt);
  });
}

const _media = ProjectResponsiveVideoProfile(
  landscape: ProjectVideoVariantProfile(
    videoPath: 'assets/presentation/intro/loop.mp4',
    posterPath: 'assets/presentation/intro/poster.png',
    durationMilliseconds: 12000,
    width: 1280,
    height: 720,
    bitrateKbps: 512,
    sizeBytes: 1024,
    videoCodec: 'h264',
    audioCodec: 'none',
  ),
);
