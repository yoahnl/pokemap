import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/domain/project_border_workshop_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/project_border_workshop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/spatial_border_fixture.dart';

void main() {
  testWidgets('draft settings save separately from an explicit publication', (
    tester,
  ) async {
    final port = _BorderEditingPort();
    await _open(tester, port);
    final original = port.record;
    await tester.tap(find.text('Brouillon'));
    await tester.pumpAndSettle();
    final name = find.byKey(const ValueKey('border-draft-name'));
    await tester.ensureVisible(name);
    await tester.enterText(name, 'Clôture du jardin');
    final weight = find.byKey(
      const ValueKey('border-draft-weight-lineStraight'),
    );
    await tester.ensureVisible(weight);
    await tester.enterText(weight, '20');
    final collision = find.byKey(
      const ValueKey('border-draft-collision-lineStraight'),
    );
    await tester.ensureVisible(collision);
    await tester.tap(collision);
    await tester.pump();
    expect(port.saves, 0);
    expect(port.publications, 0);

    final save = find.text('Enregistrer le brouillon');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(port.saves, 1);
    expect(port.publications, 0);
    expect(port.record.latestPublished, original.latestPublished);
    expect(port.record.draft.definition.name, 'Clôture du jardin');
    final changed = port.record.draft.definition.primitives.singleWhere(
      (piece) => piece.role == BorderPrimitiveRole.lineStraight,
    );
    final previous = original.draft.definition.primitives.singleWhere(
      (piece) => piece.id == changed.id,
    );
    expect(changed.weight, 20);
    expect(changed.blocksMovement, isFalse);
    expect(changed.sourceModelId, previous.sourceModelId);
    expect(changed.transforms, previous.transforms);
    expect(find.text('Brouillon enregistré'), findsOneWidget);

    final publish = find.text('Publier le brouillon');
    await tester.ensureVisible(publish);
    await tester.tap(publish);
    await tester.pumpAndSettle();
    expect(port.publications, 0);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(port.publications, 0);
    await tester.tap(publish);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publier la bordure'));
    await tester.pumpAndSettle();
    expect(port.publications, 1);
    expect(port.record.latestPublished?.revision, 2);
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Publiée · v2'), findsOneWidget);
  });

  for (final stale in [false, true]) {
    testWidgets('a retained receipt recovers on reopening (stale: $stale)', (
      tester,
    ) async {
      final port = _BorderEditingPort()..interruptReconciliation = true;
      ResourceMutationReceipt? pending;
      await _open(
        tester,
        port,
        onPendingChanged: (receipt) => pending = receipt,
      );
      await tester.tap(find.text('Brouillon'));
      await tester.pumpAndSettle();
      final name = find.byKey(const ValueKey('border-draft-name'));
      await tester.ensureVisible(name);
      await tester.enterText(name, 'Brouillon après coupure');
      await tester.pump();
      final save = find.text('Enregistrer le brouillon');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(port.saves, 1);
      expect(port.record.draft.definition.name, 'Brouillon après coupure');
      expect(pending?.revision, port.revision);
      await tester.pumpWidget(const SizedBox.shrink());
      await _open(
        tester,
        port,
        pendingReceipt: pending,
        onPendingChanged: (receipt) => pending = receipt,
      );
      port.reconciliationNeedsReopen = stale;
      final reconcile = find.text('Relire l’enregistrement');
      await tester.ensureVisible(reconcile);
      await tester.tap(reconcile);
      await tester.pumpAndSettle();
      expect(port.saves, 1);
      expect(port.reconciliations, 1);
      if (stale) {
        expect(pending, isNotNull);
        expect(reconcile, findsNothing);
        expect(find.text(BorderWorkshopReopenRequired.message), findsOneWidget);
      } else {
        expect(pending, isNull);
        expect(find.text('Brouillon enregistré'), findsOneWidget);
      }
    });
  }

  testWidgets('keeps the draft on cancel and confirms before leaving', (
    tester,
  ) async {
    final port = _BorderEditingPort();
    final changes = <bool>[];
    var exits = 0;
    await _open(
      tester,
      port,
      onDraftChanged: changes.add,
      onBack: () => exits++,
    );
    await tester.tap(find.text('Brouillon'));
    await tester.pumpAndSettle();
    final name = find.byKey(const ValueKey('border-draft-name'));
    await tester.ensureVisible(name);
    await tester.enterText(name, 'Saisie en cours');
    await tester.pump();
    expect(changes, [true]);

    final back = find.text('Retour à la bibliothèque');
    await tester.tap(back);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rester dans l’atelier'));
    await tester.pumpAndSettle();
    expect(exits, 0);
    expect(find.text('Saisie en cours'), findsOneWidget);
    expect(changes, [true]);

    await tester.tap(back);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitter sans enregistrer'));
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
    expect(exits, 1);
    expect(port.saves, 0);
  });
}

Future<void> _open(
  WidgetTester tester,
  _BorderEditingPort port, {
  ResourceMutationReceipt? pendingReceipt,
  ValueChanged<ResourceMutationReceipt?>? onPendingChanged,
  ValueChanged<bool>? onDraftChanged,
  VoidCallback? onBack,
}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProjectBorderWorkshop(
          item: ProjectLibraryItem(
            kind: 'borderBlueprint',
            id: port.record.id,
            name: port.record.draft.definition.name,
          ),
          loadProject: () async => port.project,
          visuals: null,
          editor: port,
          pendingReceipt: pendingReceipt,
          onPendingReceiptChanged: onPendingChanged,
          onDraftChanged: onDraftChanged,
          onBack: onBack ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _BorderEditingPort implements ProjectBorderWorkshopPort {
  ProjectManifest project = spatialBorderProject();
  BorderBlueprintRecord get record => project.borderCatalog.records.single;
  String get revision => 'r${saves + publications}';
  int saves = 0;
  int publications = 0;
  int reconciliations = 0;
  bool interruptReconciliation = false;
  bool reconciliationNeedsReopen = false;

  @override
  bool get canEditBorderWorkshop => true;

  @override
  Future<ProjectBorderWorkshopRead> readWorkshopBorder(String borderId) async =>
      (project: project, revision: revision);

  @override
  Future<ResourceMutationReceipt> saveBorderDraft(
    String borderId, {
    required BorderBlueprintDraft draft,
    required String expectedRevision,
  }) async {
    expect(expectedRevision, revision);
    saves++;
    final receipt = _persist(
      BorderBlueprintRecord(
        id: record.id,
        draft: draft,
        latestPublished: record.latestPublished,
      ),
      'border.blueprint.draft.upsert',
      expectedRevision,
    );
    if (interruptReconciliation) {
      throw ResourceFailure('Relecture interrompue', partialReceipt: receipt);
    }
    return receipt;
  }

  @override
  Future<ResourceMutationReceipt> publishBorderDraft(
    String borderId, {
    required String expectedRevision,
  }) async {
    expect(expectedRevision, revision);
    publications++;
    final definition = record.draft.definition;
    return _persist(
      BorderBlueprintRecord(
        id: record.id,
        draft: BorderBlueprintDraft(baseRevision: 2, definition: definition),
        latestPublished: BorderBlueprintRevision(
          revision: 2,
          definition: spatialBorderPublicationDefinition(definition),
        ),
      ),
      'border.blueprint.publish',
      expectedRevision,
    );
  }

  @override
  Future<void> reconcileBorderWorkshop(
    String borderId,
    ResourceMutationReceipt receipt,
  ) async {
    expect(receipt.revision, revision);
    reconciliations++;
    if (reconciliationNeedsReopen) throw const BorderWorkshopReopenRequired();
  }

  ResourceMutationReceipt _persist(
    BorderBlueprintRecord saved,
    String action,
    String previous,
  ) {
    final before = project;
    project = project.copyWith(
      borderCatalog: ProjectBorderCatalog(
        formatVersion: before.borderCatalog.formatVersion,
        records: [saved],
      ),
    );
    return ResourceMutationReceipt(
      before: before,
      manifest: project,
      beforeRevision: previous,
      revision: revision,
      actionId: action,
      changedPaths: const ['catalog/HEAD.json'],
    );
  }
}
