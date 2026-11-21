import 'dart:typed_data';

import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/domain/project_model_workshop_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/project_model_workshop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  testWidgets('validates, saves and resets model collision bounds', (
    tester,
  ) async {
    final model = ProjectModel3dEntry(
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
    var current = model;
    final changes = <(ProjectModelWorkshopSettings, String)>[];
    var exits = 0;
    final visuals = _PreviewVisuals();
    final project = ProjectManifest(name: 'Recette', maps: [], tilesets: []);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectModelWorkshop(
            item: ProjectLibraryItem(
              kind: 'model3d',
              id: 'house',
              name: 'Maison',
            ),
            loadModel: () async => (model: model, revision: 'initial'),
            saveShadow: (_, _) => throw StateError('Use the combined write'),
            saveSettings: (settings, revision) async {
              changes.add((settings, revision));
              current = current.copyWith(
                collisionBounds: settings.collisionBounds,
                clearCollisionBounds:
                    settings.collisionChanged &&
                    settings.collisionBounds == null,
                castsShadowsByDefault: settings.castsShadows,
                scale: settings.scale,
                pivot: settings.pivot,
              );
              return ResourceMutationReceipt(
                before: project,
                manifest: project,
                beforeRevision: revision,
                revision: 'save-${changes.length}',
                changedPaths: const ['catalog/HEAD.json'],
                changedModels: {model.id: current},
              );
            },
            visuals: visuals,
            onBack: () => exits++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(visuals.reads, ['house']);

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder.hitTestable());
      await tester.pumpAndSettle();
    }

    final edit = find.text('Modifier le volume de collision');
    final custom = find.text('Utiliser un volume personnalisé');
    final save = find.byKey(const ValueKey('model-workshop-save'));
    final xMax = find.byKey(const ValueKey('model-workshop-collision-3'));
    await tap(edit);
    await tap(custom);
    await tester.ensureVisible(xMax);
    await tester.enterText(xMax, '0');
    await tester.pumpAndSettle();
    expect(find.textContaining('Chaque maximum'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(of: save, matching: find.byType(FilledButton)),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(xMax, '1,5');
    await tester.pumpAndSettle();
    await tap(find.text('Projeter une ombre'));
    expect(changes, isEmpty);
    await tap(save);
    final bounds = Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1.5, y: 1, z: 1),
    );
    expect(changes, [
      (
        (
          collisionChanged: true,
          collisionBounds: bounds,
          castsShadows: true,
          scale: null,
          pivot: null,
        ),
        'initial',
      ),
    ]);
    expect(find.textContaining('Volume personnalisé'), findsOneWidget);

    await tap(edit);
    await tap(custom);
    await tap(save);
    expect(changes.last, (
      (
        collisionChanged: true,
        collisionBounds: null,
        castsShadows: null,
        scale: null,
        pivot: null,
      ),
      'save-1',
    ));
    expect(find.text('Limites d’origine du modèle'), findsOneWidget);

    await tap(find.text('Modifier le pivot et l’échelle'));
    final scale = find.byKey(const ValueKey('model-workshop-transform-0'));
    final pivotX = find.byKey(const ValueKey('model-workshop-transform-1'));
    await tester.ensureVisible(scale);
    await tester.enterText(scale, '-2');
    await tester.pumpAndSettle();
    expect(find.textContaining('échelle positive'), findsOneWidget);
    await tester.enterText(scale, '2,5');
    await tester.enterText(pivotX, '0,75');
    await tester.pumpAndSettle();
    await tap(save);
    expect(changes.last, (
      (
        collisionChanged: false,
        collisionBounds: null,
        castsShadows: null,
        scale: 2.5,
        pivot: Model3dVector3(x: .75, y: 0, z: 0),
      ),
      'save-2',
    ));
    expect(find.text('Échelle de définition ×2.5'), findsOneWidget);
    expect(visuals.reads, ['house']);

    await tap(edit);
    await tap(custom);
    final back = find.text('Retour à la bibliothèque');
    await tap(back);
    expect(find.text('Abandonner les réglages du modèle ?'), findsOneWidget);
    await tap(find.text('Annuler'));
    expect(exits, 0);
    expect(
      find.byKey(const ValueKey('model-workshop-collision-3')),
      findsOneWidget,
    );
    await tap(back);
    await tap(find.text('Abandonner'));
    expect(exits, 1);
    expect(changes, hasLength(3));
  });
}

class _PreviewVisuals implements MapWorkspaceVisuals, SpatialWorkspaceVisuals {
  final reads = <String>[];

  @override
  Future<Uint8List> readModel(String modelId) {
    reads.add(modelId);
    return Future.error(StateError('Source indisponible dans ce test.'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
