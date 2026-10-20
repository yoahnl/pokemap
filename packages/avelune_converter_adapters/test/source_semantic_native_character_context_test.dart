import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

void main() {
  test(
      'native connection context preserves custom and standard character clips',
      () async {
    final fixture = await LiteralTileFixture.create();
    final literal = await const LiteralTileComposer().compose(
      source: fixture.source,
      files: fixture.files,
      selectedSourceMapIds: [1],
      projectName: 'Character context',
      parentPath: '/private/tmp',
      folderName: 'unused-character-context',
    );
    final draft = literal.draft!;
    final tilesetId = draft.mutations
        .firstWhere((entry) => entry.actionId == 'tileset.import_image')
        .parameters['tilesetId'] as String;
    var index = 0;
    NativeMutation mutation(String action, Map<String, Object?> parameters) =>
        NativeMutation(
          operationId: ConverterId('character_context_${index++}'),
          actionId: action,
          sourceEntityIds: const [],
          targetEntityIds: const [],
          parameters: parameters,
        );
    const frame = CharacterAnimationFrame(
      source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
      durationMs: 100,
    );
    const standard = CharacterAnimation(
      state: CharacterAnimationState.idle,
      direction: EntityFacing.south,
      frames: [frame],
    );
    final custom = CharacterCustomAnimationClip(
      definitionId: 'source-pose',
      sourceAssetId: 'image_$tilesetId',
      frames: const [frame, frame],
      loop: false,
    );
    final context = sourceSemanticNativeProject(
      draft: draft,
      maps: literal.nativeMaps,
      mutations: [
        ...draft.mutations,
        mutation('characterStudio.character.create', {
          'name': 'Source Actor',
          'tilesetId': tilesetId,
          'frameWidth': 1,
          'frameHeight': 2,
          'tags': ['source-event'],
        }),
        mutation('characterStudio.animationClip.upsert', {
          'characterId': 'source-actor',
          ...standard.toJson(),
        }),
        mutation('characterStudio.animationDefinition.create', {
          'displayName': 'Source pose',
          'mode': 'single',
        }),
        mutation('characterStudio.animationClip.upsert', {
          'characterId': 'source-actor',
          'kind': 'custom',
          ...custom.toJson(),
        }),
        mutation('characterStudio.character.update', {
          'characterId': 'source-actor',
          'name': 'Source actor label',
        }),
        mutation('characterStudio.character.setDefault', {
          'characterId': 'source-actor',
        }),
      ],
    );
    final reloaded = ProjectManifest.fromJson(
      jsonDecode(jsonEncode(context.toJson())) as Map<String, dynamic>,
    );
    final actor = reloaded.characters.single;
    expect(actor.id, 'source-actor');
    expect(actor.name, 'Source actor label');
    expect(actor.tilesetId, tilesetId);
    expect(actor.frameWidth, 1);
    expect(actor.frameHeight, 2);
    expect(actor.animations, [standard]);
    expect(actor.customAnimations, [custom]);
    expect(reloaded.settings.defaultPlayerCharacterId, actor.id);
    expect(
      reloaded.characterStudioCatalog.customAnimationDefinitions,
      const [
        CharacterCustomAnimationDefinition(
          id: 'source-pose',
          displayName: 'Source pose',
          mode: CharacterCustomAnimationMode.single,
        ),
      ],
    );
    expect(
      () => ProjectValidator.validate(reloaded, maps: literal.nativeMaps.values),
      returnsNormally,
    );
    expect(
      () => ProjectValidator.validate(
        reloaded.copyWith(
          characterStudioCatalog: const ProjectCharacterStudioCatalog(),
        ),
        maps: literal.nativeMaps.values,
      ),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.code,
          'code',
          'character_studio.custom_animation.definition_unknown',
        ),
      ),
    );
  });
}
