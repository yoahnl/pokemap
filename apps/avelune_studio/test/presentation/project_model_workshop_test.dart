import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/application/project_resource_preview.dart';
import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/project_model_workshop_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/project_library_page.dart';
import 'package:avelune_studio/presentation/features/resources/project_model_workshop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  final shadow = find.byType(SwitchListTile);
  final save = find.text('Enregistrer');
  final house = find.byKey(const ValueKey('library-item-model3d:house'));

  testWidgets('loads one model and only saves an explicit shadow edit', (
    tester,
  ) async {
    final reading = Completer<ProjectModel3dEntry?>();
    final writing = Completer<ResourceMutationReceipt>();
    final inputs = <bool>[];
    final model = _model();
    await _open(
      tester,
      load: () async => (model: await reading.future, revision: 'before'),
      save: (enabled, revision) {
        expect(revision, 'before');
        inputs.add(enabled);
        return writing.future;
      },
    );
    expect(shadow, findsNothing);
    reading.complete(model);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(shadow).value, isFalse);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(of: save, matching: find.byType(FilledButton)),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Projeter une ombre'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(shadow).value, isTrue);
    expect(inputs, isEmpty);

    await tester.tap(save);
    await tester.pump();
    expect(inputs, [true]);
    expect(find.text('Enregistrement…'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(shadow).onChanged, isNull);

    writing.complete(_receipt(model.copyWith(castsShadowsByDefault: true)));
    await tester.pumpAndSettle();
    expect(find.text('Enregistré'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(shadow).value, isTrue);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(of: save, matching: find.byType(FilledButton)),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'a revision conflict reloads the model and keeps the pending edit',
    (tester) async {
      const conflict = 'Le catalogue a changé. Votre réglage est conservé.';
      var reads = 0;
      final revisions = <String>[];
      await _open(
        tester,
        load: () async {
          return (model: _model(), revision: 'read-${++reads}');
        },
        save: (enabled, revision) async {
          revisions.add(revision);
          if (revisions.length == 1) throw const ResourceFailure(conflict);
          return _receipt(_model().copyWith(castsShadowsByDefault: enabled));
        },
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projeter une ombre'));
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text(conflict), findsOneWidget);
      expect(tester.widget<SwitchListTile>(shadow).value, isTrue);
      expect(tester.widget<SwitchListTile>(shadow).onChanged, isNotNull);
      expect(find.text('Enregistré'), findsNothing);

      await tester.tap(find.text('Relire le modèle'));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(revisions, ['read-1']);
      expect(tester.widget<SwitchListTile>(shadow).value, isTrue);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(revisions, ['read-1', 'read-2']);
      expect(find.text('Enregistré'), findsOneWidget);
    },
  );

  testWidgets(
    'a completed write with failed reconciliation cannot be replayed',
    (tester) async {
      final model = _model();
      final applied = _receipt(model.copyWith(castsShadowsByDefault: true));
      var saves = 0;
      var reconciliations = 0;
      await _open(
        tester,
        load: () async => (model: model, revision: 'before'),
        save: (_, _) async {
          saves++;
          throw ResourceFailure(
            'Relecture indisponible',
            partialReceipt: applied,
          );
        },
        reconcile: (receipt) async {
          expect(receipt, same(applied));
          reconciliations++;
          return receipt;
        },
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projeter une ombre'));
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.textContaining('Le réglage est enregistré'), findsOneWidget);
      expect(tester.widget<SwitchListTile>(shadow).onChanged, isNull);
      expect(save, findsNothing);
      await tester.tap(find.text('Relire l’enregistrement'));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(reconciliations, 1);
      expect(find.text('Enregistré'), findsOneWidget);
      expect(tester.widget<SwitchListTile>(shadow).value, isTrue);
    },
  );

  testWidgets('read-only models show their settings without a save action', (
    tester,
  ) async {
    await _open(
      tester,
      load: () async => (
        model: _model().copyWith(castsShadowsByDefault: true),
        revision: null,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maison'), findsOneWidget);
    expect(find.text('Lecture seule'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(shadow).value, isTrue);
    expect(tester.widget<SwitchListTile>(shadow).onChanged, isNull);
    expect(save, findsNothing);
  });

  testWidgets('a missing model stays visible as unavailable', (tester) async {
    await _open(tester, load: () async => (model: null, revision: null));
    await tester.pumpAndSettle();
    expect(find.text('Modèle introuvable'), findsOneWidget);
    expect(shadow, findsNothing);
  });

  testWidgets('a complete project opens its model from the compact detail', (
    tester,
  ) async {
    await _library(tester);
    await tester.tap(house);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text('Atelier 3D'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Lecture seule'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(shadow).value, isFalse);
    await tester.tap(find.text('Retour à la bibliothèque'));
    await tester.pumpAndSettle();
    expect(house, findsOneWidget);
  });

  testWidgets('an in-flight save holds the workshop open through publication', (
    tester,
  ) async {
    final editor = _WorkshopEditor();
    final publishing = Completer<void>();
    final published = <ResourceMutationReceipt>[];
    await _library(
      tester,
      editor: editor,
      onPublished: (receipt) {
        published.add(receipt);
        return publishing.future;
      },
    );
    await tester.tap(find.text('Ateliers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maison'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projeter une ombre'));
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pump();
    expect(editor.expectedRevision, 'before');
    await tester.tap(find.text('Bibliothèque'));
    await tester.pump();
    expect(find.text('Enregistrement…'), findsOneWidget);
    final receipt = _receipt(_model().copyWith(castsShadowsByDefault: true));
    editor.writing.complete(receipt);
    await tester.pump();
    expect(published, [receipt]);
    await tester.tap(find.text('Bibliothèque'));
    await tester.pump();
    expect(find.text('Enregistrement…'), findsOneWidget);
    publishing.complete();
    await tester.pumpAndSettle();
    expect(find.text('Enregistré'), findsOneWidget);
    await tester.tap(find.text('Bibliothèque'));
    await tester.pumpAndSettle();
    expect(house, findsOneWidget);
  });
}

Future<void> _library(
  WidgetTester tester, {
  _WorkshopEditor? editor,
  Future<void> Function(ResourceMutationReceipt)? onPublished,
}) async {
  tester.view.physicalSize = const Size(850, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final maps = MapWorkspaceController(workspaceSession, _CompleteModelPort());
  addTearDown(maps.dispose);
  await maps.initialize();
  final page = ProjectLibraryPage(
    active: true,
    maps: maps,
    visuals: null,
    management: editor == null
        ? null
        : (editor: editor, pickFile: () async => null),
    onModelWorkshopPublished: onPublished,
  );
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
  await tester.pumpAndSettle();
}

class _CompleteModelPort extends WorkspaceMemoryPort
    implements ProjectResourcePreviewPort {
  _CompleteModelPort()
    : super(manifest: workspaceProject.copyWith(models3d: [_model()]));

  @override
  Future<ProjectManifest> readResourcePreview(
    ProjectSession session,
    String kind,
    String id,
  ) => Future.error(StateError('This project has no partitioned catalogue.'));
}

class _WorkshopEditor
    implements ProjectLibraryEditor, ProjectModelWorkshopPort {
  final writing = Completer<ResourceMutationReceipt>();
  String? expectedRevision;

  @override
  Future<ProjectModelWorkshopRead> readWorkshopModel(String modelId) async =>
      (model: _model(), revision: 'before');

  @override
  Future<ResourceMutationReceipt> saveModelShadow(
    String modelId, {
    required bool castsShadows,
    required String expectedRevision,
  }) {
    this.expectedRevision = expectedRevision;
    return writing.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester, {
  required Future<ProjectModelWorkshopRead> Function() load,
  Future<ResourceMutationReceipt> Function(bool, String)? save,
  Future<ResourceMutationReceipt> Function(ResourceMutationReceipt)? reconcile,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: ProjectModelWorkshop(
        item: ProjectLibraryItem(kind: 'model3d', id: 'house', name: 'Maison'),
        loadModel: load,
        saveShadow: save,
        reconcileShadow: reconcile,
        visuals: null,
        onBack: () {},
      ),
    ),
  ),
);

ProjectModel3dEntry _model() => ProjectModel3dEntry(
  id: 'house',
  name: 'Maison',
  sourceAssetId: 'house-source',
  relativePath: 'assets/models3d/house.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1, y: 1, z: 1),
    ),
    meshCount: 1,
    triangleCount: 1,
  ),
);

ResourceMutationReceipt _receipt(ProjectModel3dEntry updated) {
  final project = ProjectManifest(name: 'Recette', maps: [], tilesets: []);
  return ResourceMutationReceipt(
    before: project,
    manifest: project,
    beforeRevision: 'before',
    revision: 'after',
    changedPaths: const ['catalog/HEAD.json'],
    changedModels: {updated.id: updated},
  );
}
