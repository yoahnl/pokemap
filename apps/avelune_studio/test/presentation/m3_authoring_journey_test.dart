import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_interaction_pane.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/m3_story_fixture.dart';
import '../support/m2_ui_fixture.dart';
import '../support/load_desktop_capture_fonts.dart';

void main() {
  testWidgets(
    'author edits choices conditions and story, publishes and reopens',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late M3StoryFixture fixture;
      late WidgetMapController controller;
      late StudioMapResources visuals;
      await tester.runAsync(() async {
        await loadDesktopCaptureFonts();
        fixture = await M3StoryFixture.create();
        controller = WidgetMapController(fixture.session, fixture.maps, tester);
        await controller.initialize();
        visuals = await StudioMapResources.load(
          fixture.session,
          controller.project!,
        );
      });
      addTearDown(() async {
        controller.dispose();
        await visuals.dispose();
        await fixture.directory.delete(recursive: true);
      });
      final port = LocalNarrativeAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
      );
      final capture = GlobalKey();
      Future<bool> Function()? exitGuard;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: RepaintBoundary(
            key: capture,
            child: MapWorkspaceScreen(
              controller: controller,
              loadVisuals: (_, _) async => visuals,
              narrativePort: _WidgetNarrativePort(port, tester),
              runtimeBuilder: (_, _, _) => const SizedBox(),
              onClose: () async {},
              registerExitGuard: (g) => exitGuard = g,
            ),
          ),
        ),
      );
      await pumpIo(tester);
      if (find.text('Personnages').evaluate().isEmpty) {
        await tester.tap(find.byTooltip('Palette'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Personnages').last);
      await tester.pump();
      if (find.byTooltip('Retour à la carte').evaluate().isNotEmpty) {
        await tester.tap(find.byTooltip('Retour à la carte'));
        await tester.pumpAndSettle();
      }
      final canvas = find.byKey(const ValueKey('map-canvas'));
      final settings = controller.project!.settings;
      await tester.tapAt(
        tester
            .renderObject<RenderBox>(canvas)
            .localToGlobal(
              Offset(
                8.4 * settings.tileWidth * settings.displayScale,
                10.4 * settings.tileHeight * settings.displayScale,
              ),
            ),
      );
      await tester.pump();
      expect(find.text('Écrire son interaction'), findsOneWidget);
      await _capture(tester, capture, '01-carte-personnages');
      await tester.tap(find.text('Histoire').first);
      await tester.pump();
      expect(find.byType(NarrativeStoryPane), findsOneWidget);
      await _capture(tester, capture, '02-histoire');
      final story = tester.widget<NarrativeStoryPane>(
        find.byType(NarrativeStoryPane),
      );
      await tester.tap(find.text('Carte').first);
      await tester.pump();
      await tester.tap(find.text('Écrire son interaction'));
      await pumpIo(tester);
      expect(find.byType(NarrativeInteractionPane), findsOneWidget);
      final pane = tester.widget<NarrativeInteractionPane>(
        find.byType(NarrativeInteractionPane),
      );
      final original = pane
          .controller
          .active!
          .current
          .dialogue
          .branches
          .first
          .lines
          .first
          .text;
      final line = find.widgetWithText(TextField, original).first;
      await tester.enterText(
        line,
        'Voulez-vous aider au départ ?\nTexte littéral <<stop>> et # sans commande.',
      );
      await tester.pump();
      expect(pane.controller.active!.dirty, isTrue);
      await _capture(tester, capture, '03-dialogue-choix');
      final close = exitGuard!();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler').last);
      await tester.pumpAndSettle();
      expect(await close, isFalse);
      expect(pane.controller.active!.dirty, isTrue);
      await tester.tap(find.text('Enregistrer l’interaction et la carte'));
      await pumpIo(tester, frames: 50);
      expect(pane.controller.error, isNull);
      expect(pane.controller.active!.dirty, isFalse);
      final source = await tester.runAsync(
        () => port.readDialogue(
          controller.project!.dialogues.firstWhere(
            (d) => d.id == pane.controller.active!.current.dialogue.entry.id,
          ),
        ),
      );
      expect(
        const DialogueDraftCodec()
            .decode(source!)!
            .branches
            .first
            .lines
            .first
            .text,
        contains('<<stop>>'),
      );
      await tester.tap(find.text('Retour à la carte'));
      await tester.pump();
      await tester.tap(find.text('Histoire').first);
      await tester.pump();
      await tester.tap(find.text('Voir tous les documents').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer une histoire'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'La visite du quai');
      await tester.pump();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        'Préparer\nRencontrer\nRevenir',
      );
      await tester.pump();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      expect(
        story.controller.stories.any((s) => s.title == 'La visite du quai'),
        isTrue,
      );
      await tester.tap(find.text('Enregistrer les modifications'));
      await pumpIo(tester, frames: 50);
      expect(story.controller.error, isNull);
      expect(story.controller.dirty, isFalse);
      await tester.tap(find.text('Carte').first);
      await tester.pump();
      await tester.tap(find.text('Écrire son interaction'));
      await pumpIo(tester);
      final addVariant = find.text('Ajouter une conversation conditionnelle');
      await tester.scrollUntilVisible(
        addVariant,
        450,
        scrollable: find
            .descendant(
              of: find.byType(NarrativeInteractionPane),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(addVariant);
      await pumpIo(tester);
      final variant = tester.widget<NarrativeInteractionPane>(
        find.byType(NarrativeInteractionPane),
      );
      final newLine = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'Texte de la réplique 1',
      );
      await tester.ensureVisible(newLine);
      await tester.enterText(newLine, 'Le quai vous attend.');
      await tester.pump();
      final condition = find.text('Ajouter une condition');
      await tester.ensureVisible(condition);
      await tester.tap(condition);
      await tester.pump();
      expect(
        variant.controller.active!.current.interaction.conditions,
        hasLength(1),
      );
      await tester.tap(find.text('Enregistrer l’interaction et la carte'));
      await pumpIo(tester, frames: 50);
      expect(variant.controller.error, isNull);
      expect(variant.controller.active!.dirty, isFalse);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}

class _WidgetNarrativePort implements NarrativePort {
  _WidgetNarrativePort(this.port, this.tester);
  final NarrativePort port;
  final WidgetTester tester;
  Future<T> run<T>(Future<T> Function() action) async {
    final pending = tester.runAsync(action);
    WidgetResourcePort.pending = pending;
    try {
      return (await pending)!;
    } finally {
      WidgetResourcePort.pending = null;
    }
  }

  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) =>
      run(() => port.readDialogue(entry));
  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) => run(() => port.publish(publication));
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final path = Platform.environment['AVELUNE_CAPTURE_DIR'];
  if (path == null) return;
  await tester.pump();
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(path).create(recursive: true);
    await File('$path/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
