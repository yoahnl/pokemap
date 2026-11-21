part of 'project_character_workshop_test.dart';

void _appearanceTests() {
  testWidgets('sets and then clears the character contact shadow in 3D', (
    tester,
  ) async {
    final port = _CharacterAppearancePort();
    final previews = ProjectResourcePreviews((_) async => port.project);
    await tester.pumpWidget(
      _workshop(
        previews,
        _CharacterVisuals(),
        editor: (
          port: port,
          pickImage: () async => null,
          resolveSpatialModel: null,
          pending: null,
          retain: (_) {},
          publish: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apparence 3D'));
    await tester.pumpAndSettle();

    final save = find.widgetWithText(StudioButton, 'Enregistrer l’apparence');
    await _select(tester, 'Ombre de contact', 'Toujours afficher');
    expect(port.overrides, isEmpty);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(port.overrides, [true]);
    expect(port.project.characters.single.contactShadow, isTrue);

    await _select(tester, 'Ombre de contact', 'Réglage du projet');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(port.overrides, [true, null]);
    expect(port.project.characters.single.contactShadow, isNull);
  });

  testWidgets('edits a persisted GLB clip and restores the sprite', (
    tester,
  ) async {
    final port = _CharacterAppearancePort(model: _riggedModel);
    final previews = ProjectResourcePreviews((_) async => port.project);
    Future<void> open() async {
      await tester.pumpWidget(
        _workshop(
          previews,
          _CharacterVisuals(),
          editor: (
            port: port,
            pickImage: () async => null,
            resolveSpatialModel: null,
            pending: null,
            retain: (_) {},
            publish: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apparence 3D'));
      await tester.pumpAndSettle();
    }

    await open();
    expect(find.text(_riggedModel.name), findsOneWidget);
    await _select(tester, 'État du personnage', 'Marche');
    await _select(tester, 'Clip GLB', 'Pas léger');
    final save = find.widgetWithText(StudioButton, 'Enregistrer l’apparence');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(port.edits.single.keys, ['spatialModel']);
    expect(port.project.characters.single.spatialModel?.clips, {
      CharacterAnimationState.idle: 0,
      CharacterAnimationState.walk: 1,
    });
    expect(port.project.characters.single.contactShadow, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await open();
    await _select(tester, 'État du personnage', 'Marche');
    expect(find.text('Pas léger'), findsOneWidget);
    await tester.tap(find.text('Utiliser le sprite'));
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(port.edits.last, {'spatialModel': null});
    expect(port.project.characters.single.spatialModel, isNull);
    expect(port.project.characters.single.contactShadow, isTrue);
  });

  testWidgets('waits for a clip before assigning a selected model', (
    tester,
  ) async {
    final port = _CharacterAppearancePort();
    final reads = <String?>[];
    await tester.pumpWidget(
      _workshop(
        ProjectResourcePreviews((_) async => port.project),
        _CharacterVisuals(),
        editor: (
          port: port,
          pickImage: () async => null,
          resolveSpatialModel: (_, modelId) async {
            reads.add(modelId);
            return _riggedModel;
          },
          pending: null,
          retain: (_) {},
          publish: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apparence 3D'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir un modèle'));
    await tester.pumpAndSettle();
    expect(reads, [null]);
    final save = find.widgetWithText(StudioButton, 'Enregistrer l’apparence');
    expect(tester.widget<StudioButton>(save).onPressed, isNull);

    await _select(tester, 'Clip GLB', 'Respiration');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      port.project.characters.single.spatialModel?.modelId,
      _riggedModel.id,
    );
    expect(port.project.characters.single.spatialModel?.clips, {
      CharacterAnimationState.idle: 0,
    });

    await tester.tap(find.text('Animations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apparence 3D'));
    await tester.pumpAndSettle();
    expect(reads, [null, _riggedModel.id]);
    expect(find.text('Respiration'), findsOneWidget);
  });
}

final class _CharacterAppearancePort extends _CharacterEditorPort {
  _CharacterAppearancePort({ProjectModel3dEntry? model}) {
    project = project.copyWith(
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      models3d: [?model],
      characters: [
        model == null
            ? _character
            : _character.copyWith(
                contactShadow: true,
                spatialModel: ProjectCharacterSpatialModel(
                  modelId: model.id,
                  clips: const {CharacterAnimationState.idle: 0},
                ),
              ),
      ],
    );
  }

  final overrides = <bool?>[];
  final edits = <Map<String, Object?>>[];

  @override
  Future<ResourceMutationReceipt> editWorkshopCharacter(
    String id,
    String action,
    Map<String, Object?> parameters, {
    required String expectedRevision,
    PickedProjectLibraryFile? image,
  }) async {
    expect(id, _character.id);
    expect(action, 'characterStudio.character.update');
    expect(expectedRevision, revision);
    edits.add(parameters);
    final character = project.characters.single;
    final shadow = parameters.containsKey('contactShadow')
        ? parameters['contactShadow'] as bool?
        : character.contactShadow;
    if (parameters.containsKey('contactShadow')) overrides.add(shadow);
    final spatialModel = parameters.containsKey('spatialModel')
        ? switch (parameters['spatialModel']) {
            final Map<String, dynamic> model =>
              ProjectCharacterSpatialModel.fromJson(model),
            _ => null,
          }
        : character.spatialModel;
    final before = project;
    project = project.copyWith(
      characters: [
        character.copyWith(contactShadow: shadow, spatialModel: spatialModel),
      ],
    );
    revision = 'rev-${edits.length + 1}';
    return ResourceMutationReceipt(
      before: before,
      manifest: project,
      beforeRevision: expectedRevision,
      revision: revision,
      changedPaths: const ['catalog/HEAD.json'],
      actionId: action,
    );
  }
}

final _riggedModel = ProjectModel3dEntry(
  id: 'guide-rig',
  name: 'Guide riggé',
  sourceAssetId: 'guide-model',
  relativePath: 'assets/models3d/guide-rig.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1, y: 1, z: 1),
    ),
    meshCount: 1,
    triangleCount: 1,
    skinned: true,
    animations: [
      Model3dAnimation(index: 0, name: 'Respiration', durationSeconds: 1),
      Model3dAnimation(index: 1, name: 'Pas léger', durationSeconds: 2),
    ],
  ),
);
