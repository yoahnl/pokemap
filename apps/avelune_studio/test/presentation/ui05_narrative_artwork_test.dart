import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_artwork_image.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_overview_landing.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/m2_ui_fixture.dart';
import '../support/ui05_narrative_fixture.dart';

void main() {
  testWidgets('switching project hides the previous artwork while loading', (
    tester,
  ) async {
    final first = _PendingArtwork();
    final second = _PendingArtwork();
    Widget page(NarrativeArtworkPort port) => MaterialApp(
      home: Scaffold(
        body: NarrativeArtworkImage(
          key: const ValueKey('artwork'),
          port: port,
          kind: NarrativeArtworkKind.hero,
          fallback: const Text('Image par défaut'),
        ),
      ),
    );
    await tester.pumpWidget(page(first));
    final image = await tester.runAsync(
      () => File('assets/home/hero_landscape.png').readAsBytes(),
    );
    first.complete(image!);
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);

    await tester.pumpWidget(page(second));
    expect(find.text('Image par défaut'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    second.complete(null);
    await tester.pump();
    expect(find.text('Image par défaut'), findsOneWidget);
  });

  testWidgets('overview uses project artwork for hero, story, and scene', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(
      () => Ui05NarrativeFixture.create(tester),
    ))!;
    addTearDown(fixture.dispose);
    final root = fixture.source.session.directoryPath;
    final sceneId = fixture.controller.project!.scenes.first.id;
    await tester.runAsync(() async {
      final image = await File('assets/home/hero_landscape.png').readAsBytes();
      for (final path in [
        'hero.png',
        'stories/departure.png',
        'scenes/$sceneId.png',
      ]) {
        final file = File('$root/assets/studio/narrative/$path');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(image);
      }
    });
    await tester.pumpWidget(fixture.app(tester, withOwners: true));
    await pumpIo(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(StudioPrimaryNavigation),
        matching: find.byTooltip('Histoire'),
      ),
    );
    await pumpIo(tester);

    for (final key in [
      'narrative-hero-artwork',
      'narrative-story-artwork-departure',
      'narrative-scene-artwork-$sceneId',
    ]) {
      final artwork = find.byKey(ValueKey(key));
      expect(artwork, findsOneWidget);
      expect(
        tester
            .widget<Image>(
              find.descendant(of: artwork, matching: find.byType(Image)),
            )
            .image,
        isA<MemoryImage>(),
      );
    }
    expect(find.byType(NarrativeArtworkImage), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a project without storylines features its real scenes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(
      () => Ui05NarrativeFixture.create(tester),
    ))!;
    addTearDown(fixture.dispose);
    final project = fixture.controller.project!;
    final first = project.scenes.first;
    final root = fixture.source.session.directoryPath;
    await tester.runAsync(() async {
      final image = await File('assets/home/hero_landscape.png').readAsBytes();
      final file = File('$root/assets/studio/narrative/scenes/${first.id}.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(image);
    });
    final search = TextEditingController();
    addTearDown(search.dispose);
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: NarrativeOverviewLanding(
            artworkPort: fixture.port,
            overview: NarrativeOverview(
              stories: const [],
              facts: const [],
              interactions: const [],
              stepsById: const {},
              stepLinks: const {},
              factLinks: const {},
              dirtyCount: 0,
            ),
            project: project,
            scenes: project.scenes,
            dialogues: project.dialogues,
            events: project.eventRegistry?.records ?? const [],
            search: search,
            onSearch: (_) {},
            resultsScroll: ScrollController(),
            onLibrary: () {},
            onCreateStory: null,
            onCreateScene: null,
            onCreateEvent: null,
            onProgression: null,
            onScenes: null,
            onEvents: null,
            onVerification: null,
            onOpenStory: (_) {},
            onOpenStep: (_, _) {},
            onOpenScene: (id) => opened = id,
            onOpenInteraction: (_) {},
            onOpenDialogue: null,
            onOpenEvent: null,
            onOpenMap: null,
          ),
        ),
      ),
    );
    await pumpIo(tester);

    expect(
      find.text('Scènes du projet · ${project.scenes.length}'),
      findsOneWidget,
    );
    final card = find.byKey(ValueKey('overview-featured-scene-${first.id}'));
    expect(card, findsOneWidget);
    expect(
      tester
          .widget<Image>(
            find.descendant(of: card, matching: find.byType(Image)),
          )
          .image,
      isA<MemoryImage>(),
    );
    await tester.tap(card);
    expect(opened, first.id);
    expect(tester.takeException(), isNull);
  });
}

class _PendingArtwork implements NarrativeArtworkPort {
  final _response = Completer<Uint8List?>();

  void complete(Uint8List? bytes) => _response.complete(bytes);

  @override
  Future<Uint8List?> readArtwork(NarrativeArtworkKind kind, {String? id}) =>
      _response.future;
}
