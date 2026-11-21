part of 'project_character_workshop_test.dart';

class _CharacterEditorPort implements ProjectCharacterWorkshopPort {
  var project = _project;
  var revision = 'rev-1';
  final portraitReads = <String>[];

  @override
  Future<ProjectCharacterWorkshopRead> readWorkshopCharacter(String id) async {
    expect(id, _character.id);
    return (project: project, revision: revision);
  }

  @override
  Future<Uint8List?> readCharacterPortrait(
    String characterId,
    String stateId,
  ) async {
    expect(characterId, _character.id);
    portraitReads.add(stateId);
    return null;
  }

  @override
  Future<ResourceMutationReceipt> editWorkshopCharacter(
    String id,
    String action,
    Map<String, Object?> parameters, {
    required String expectedRevision,
    PickedProjectLibraryFile? image,
  }) async {
    expect(id, _character.id);
    expect(action, 'characterStudio.animationClip.upsert');
    expect(expectedRevision, 'rev-1');
    expect(parameters['state'], 'walk');
    expect(parameters['direction'], 'south');
    final frames = (parameters['frames'] as List).cast<Map<String, dynamic>>();
    expect(frames.first['durationMs'], 177);
    final before = project;
    final steps = _character.animations.toList();
    steps[1] = steps[1].copyWith(
      frames: frames.map(CharacterAnimationFrame.fromJson).toList(),
    );
    project = project.copyWith(
      characters: [_character.copyWith(animations: steps)],
    );
    revision = 'rev-2';
    return ResourceMutationReceipt(
      before: before,
      manifest: project,
      beforeRevision: expectedRevision,
      revision: revision,
      changedPaths: const ['catalog/HEAD.json'],
      actionId: action,
    );
  }

  @override
  Future<void> reconcileWorkshopCharacter(
    String id,
    ResourceMutationReceipt receipt,
  ) => throw UnimplementedError();
}

final _projectWithPortraits = _project.copyWith(
  characterStudioCatalog: const ProjectCharacterStudioCatalog(
    portraitStates: [
      CharacterPortraitStateDefinition(id: 'neutral', displayName: 'Neutre'),
      CharacterPortraitStateDefinition(id: 'happy', displayName: 'Souriant'),
      CharacterPortraitStateDefinition(id: 'sad', displayName: 'Triste'),
    ],
  ),
  characters: [
    _character.copyWith(
      portraits: const [
        CharacterPortraitVariant(
          portraitStateId: 'neutral',
          assetId: 'guide-neutral',
        ),
        CharacterPortraitVariant(
          portraitStateId: 'happy',
          assetId: 'guide-happy',
        ),
      ],
    ),
  ],
);

Future<void> _select(WidgetTester tester, String field, String value) async {
  await tester.tap(find.widgetWithText(StudioSelect, field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

Widget _workshop(
  ProjectResourcePreviews previews,
  _CharacterVisuals visuals, {
  bool active = true,
  String name = 'Guide du jardin',
  Future<void> Function()? onRename,
  VoidCallback? onBack,
  ProjectCharacterEditor? editor,
}) => MaterialApp(
  home: Scaffold(
    body: ProjectCharacterWorkshop(
      item: ProjectLibraryItem(
        kind: 'character',
        id: _character.id,
        name: name,
      ),
      previews: previews,
      visuals: visuals,
      active: active,
      onBack: onBack ?? () {},
      onRename: onRename,
      editor: editor,
    ),
  ),
);

const _project = ProjectManifest(
  name: 'Jardin',
  maps: [],
  tilesets: [],
  characters: [_character],
);

const _character = ProjectCharacterEntry(
  id: 'garden-guide',
  name: 'Guide du jardin',
  tilesetId: 'guide',
  animations: [
    CharacterAnimation(
      state: CharacterAnimationState.idle,
      direction: EntityFacing.south,
      frames: [_firstFrame],
    ),
    CharacterAnimation(
      state: CharacterAnimationState.walk,
      direction: EntityFacing.south,
      frames: [_firstFrame, _secondFrame],
    ),
    CharacterAnimation(
      state: CharacterAnimationState.walk,
      direction: EntityFacing.east,
      frames: [_firstFrame, _secondFrame],
    ),
    CharacterAnimation(
      state: CharacterAnimationState.walk,
      direction: EntityFacing.north,
    ),
    CharacterAnimation(
      state: CharacterAnimationState.cut,
      direction: EntityFacing.west,
      frames: [_firstFrame, _secondFrame],
      loop: false,
    ),
  ],
);

const _firstFrame = CharacterAnimationFrame(
  source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 32),
  durationMs: 100,
);
const _secondFrame = CharacterAnimationFrame(
  source: TilesetSourceRect(x: 16, y: 0, width: 16, height: 32),
  durationMs: 100,
);

class _CharacterVisuals extends WorkspaceTestVisuals
    implements ScopedResourcePreviewVisuals {
  late CharacterPreviewSource last;

  @override
  Widget scopedResourcePreview(
    ResourcePreviewSource source,
    ProjectManifest project, {
    required double size,
  }) {
    if (size >= 100) last = source as CharacterPreviewSource;
    return SizedBox.square(dimension: size);
  }

  @override
  void refreshResourcePreviews() {}

  @override
  void invalidateResourcePreviews(Set<String> changedRelativePaths) {}
}
