import 'dart:async';

import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui10_workspace_harness.dart';

void main() {
  testWidgets(
    'UI10 uses owner actions for actor recovery and real controls for invalid fields',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = (await tester.runAsync(
        () => Ui10WorkspaceHarness.create(tester),
      ))!;
      await tester.pumpWidget(harness.app());
      await pumpIo(tester);
      await harness.open(tester);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(harness.dispose);
      });
      final controller = harness.page(tester).controller;
      final mapBefore = await tester.runAsync(harness.workspace.mapBytes);
      await _tap(tester, find.text('Nouvelle cinématique'));
      await tester.enterText(
        find.byType(TextField).last,
        'Récupération acteur',
      );
      await _tap(tester, find.text('Créer'));
      final id = controller.activeId!;
      expect(controller.active!.asset.requiredActors, isEmpty);
      expect(
        await controller.addAction(
          CinematicTimelineStepKind.actorMove,
          flushInputs: true,
          choose: (_, _) async => null,
        ),
        isNull,
      );
      await pumpIo(tester);
      expect(find.text('Ajoutez et sélectionnez un acteur.'), findsOneWidget);
      expect(controller.active!.asset.timeline.steps, isEmpty);
      await _tap(tester, find.text('Acteurs').last);
      await _tap(tester, find.text('Ajouter un acteur'));
      expect(controller.active!.asset.requiredActors, hasLength(1));
      final moveId = await controller.addAction(
        CinematicTimelineStepKind.actorMove,
        actorId: harness.page(tester).views.forAsset(id).actorId,
        flushInputs: true,
        choose: (_, _) async => null,
      );
      expect(moveId, isNotNull, reason: controller.error);
      await pumpIo(tester);
      expect(controller.active!.asset.timeline.steps, hasLength(1));
      expect(find.text('Ajoutez et sélectionnez un acteur.'), findsNothing);
      await _select(tester, 'Rôle dans le jeu', 'Joueur');
      await _tap(tester, find.text('Séquence').last);
      final maps = tester
          .widget<StudioSelect>(_selectField('Carte de contexte'))
          .options;
      await _select(
        tester,
        'Carte de contexte',
        maps.entries.firstWhere((e) => e.key.isNotEmpty).value,
      );
      await pumpIo(tester, frames: 25);
      await _tap(tester, find.text('Acteurs').last);
      await _tap(tester, find.text('Placer sur la carte'));
      await _point(tester, 8, 9);
      await _tap(tester, find.text('Séquence').last);
      await _tap(
        tester,
        find.byKey(ValueKey('cinematic-sequence-step-$moveId')),
      );
      await _tap(tester, find.text('Choisir la destination'));
      await _point(tester, 13, 9);
      final duration = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Durée (ms)',
      );
      await tester.ensureVisible(duration);
      await tester.enterText(duration, '-2');
      await _save(tester);
      expect(harness.port.writes, 0);
      expect(harness.page(tester).views.forAsset(id).error, isNotNull);
      expect(controller.active!.dirty, isTrue);
      await _save(tester);
      expect(harness.port.writes, 0);
      await tester.ensureVisible(duration);
      await tester.enterText(duration, '1000');
      await _save(tester);
      expect(harness.page(tester).views.forAsset(id).error, isNull);
      expect(controller.error, isNull);
      expect(harness.port.writes, 1);
      expect(controller.active!.dirty, isFalse);
      final published = controller.active!.asset.toJson();
      final reopened = await tester.runAsync(
        () => harness.port.delegate.load(id),
      );
      expect(reopened!.asset.toJson(), published);

      await tester.ensureVisible(duration);
      await tester.enterText(duration, '-2');
      await _save(tester);
      expect(harness.port.writes, 1);
      var confirmations = 0;
      final reads = harness.port.reads;
      expect(
        await controller.reload(
          confirm: () async {
            confirmations++;
            return false;
          },
        ),
        isFalse,
      );
      expect(confirmations, 1);
      expect(harness.port.reads, reads);
      expect(tester.widget<TextField>(duration).controller!.text, '-2');
      expect(harness.page(tester).views.forAsset(id).error, isNotNull);

      final inputs = controller.inputsFor(id);
      final inputId =
          'duration-$id-${controller.active!.asset.timeline.steps.last.id}';
      final confirmation = Completer<bool>();
      final staleReload = controller.reload(confirm: () => confirmation.future);
      inputs.field(inputId, '1000').edit('-3');
      confirmation.complete(true);
      expect(await staleReload, isFalse);
      expect(harness.port.reads, reads);
      expect(inputs.field(inputId, '1000').text, '-3');
      expect(inputs.dirty, isTrue);

      final reloading = controller.reload(confirm: () async => true);
      await pumpIo(tester, frames: 20);
      expect(await reloading, isTrue);
      expect(controller.active!.asset.toJson(), published);
      expect(harness.page(tester).views.forAsset(id).error, isNull);
      expect(tester.widget<TextField>(duration).controller!.text, '1000');
      expect(harness.port.writes, 1);
      await _tap(tester, find.text('Prévisualiser'));
      expect(controller.transport.playing, isTrue);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.transport.timeMs, greaterThan(0));
      await _tap(tester, find.byTooltip('Retour à Histoire'));
      expect(find.byType(CinematicWorkspacePage), findsNothing);
      expect(await tester.runAsync(harness.workspace.mapBytes), mapBefore);
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _selectField(String label) =>
    find.byWidgetPredicate((w) => w is StudioSelect && w.label == label);
Future<void> _select(WidgetTester tester, String label, String option) async {
  await _tap(tester, _selectField(label));
  await _tap(tester, find.text(option).last);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.pump();
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await pumpIo(tester, frames: 8);
}

Future<void> _save(WidgetTester tester) => _tap(
  tester,
  find
      .descendant(
        of: find.byType(CinematicWorkspacePage),
        matching: find.text('Enregistrer'),
      )
      .first,
);
Future<void> _point(WidgetTester tester, int x, int y) async {
  final box = tester.renderObject<RenderBox>(
    find.byKey(const ValueKey('cinematic-map-pick')),
  );
  await tester.tapAt(box.localToGlobal(Offset(32 * (x + .4), 32 * (y + .4))));
  await tester.pump();
}
