import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/characters/application/character_studio_draft.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  const character = ProjectCharacterEntry(
    id: 'agent',
    name: 'Agent',
    tilesetId: 'agent-sheet',
    frameWidth: 1,
    frameHeight: 1,
  );

  test(
    'la planche classique affecte exactement trois poses aux quatre directions',
    () {
      final draft = CharacterStudioDraft(character);
      final assigned = draft.assignClassicSheet(
        CharacterAnimationState.walk,
        const ProjectRegularAtlasTilesetSource(
          assetId: 'agent-sheet',
          pixelWidth: 96,
          pixelHeight: 192,
          tileWidth: 32,
          tileHeight: 48,
        ),
        frameWidth: 32,
        frameHeight: 48,
      );

      expect(assigned, isTrue);
      expect(draft.changedClips.length, 4);
      expect(
        draft
            .completeFrames((CharacterAnimationState.walk, EntityFacing.north))
            .last
            .source,
        const TilesetSourceRect(x: 2, y: 3),
      );
      expect(draft.dirty, isTrue);
      draft.discard();
      expect(draft.dirty, isFalse);
    },
  );

  test(
    'une pose isolée reste brouillon et ne publie pas de trou implicite',
    () {
      final draft = CharacterStudioDraft(character);
      const key = (CharacterAnimationState.walk, EntityFacing.south);
      draft.assign(key, 2, const TilesetSourceRect(x: 2, y: 0));

      expect(draft.problemFor(key), isNotNull);
      expect(() => draft.completeFrames(key), throwsStateError);
      expect(character.animations, isEmpty);
    },
  );

  test('modifier une pose conserve les frames supplémentaires existantes', () {
    final existing = character.copyWith(
      animations: [
        CharacterAnimation(
          state: CharacterAnimationState.walk,
          direction: EntityFacing.south,
          frames: [
            for (var index = 0; index < 4; index++)
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: index, y: 0),
              ),
          ],
        ),
      ],
    );
    final draft = CharacterStudioDraft(existing);
    const key = (CharacterAnimationState.walk, EntityFacing.south);
    draft.assign(key, 1, const TilesetSourceRect(x: 1, y: 1));

    expect(draft.completeFrames(key), hasLength(4));
    expect(
      draft.completeFrames(key).last,
      existing.animations.single.frames.last,
    );
  });

  test('découper une planche remplace exactement les anciennes poses', () {
    final existing = character.copyWith(
      animations: [
        CharacterAnimation(
          state: CharacterAnimationState.walk,
          direction: EntityFacing.south,
          frames: [
            for (var index = 0; index < 5; index++)
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: index, y: 0),
              ),
          ],
        ),
      ],
    );
    final draft = CharacterStudioDraft(existing);
    expect(
      draft.assignClassicSheet(
        CharacterAnimationState.walk,
        const ProjectRegularAtlasTilesetSource(
          assetId: 'agent-sheet',
          pixelWidth: 96,
          pixelHeight: 192,
          tileWidth: 32,
          tileHeight: 48,
        ),
        frameWidth: 32,
        frameHeight: 48,
      ),
      isTrue,
    );
    expect(
      draft.completeFrames((CharacterAnimationState.walk, EntityFacing.south)),
      hasLength(3),
    );
  });

  test('une pose identique choisie sur atlas remplace une source dédiée', () {
    const key = (CharacterAnimationState.walk, EntityFacing.south);
    final existing = character.copyWith(
      animations: const [
        CharacterAnimation(
          state: CharacterAnimationState.walk,
          direction: EntityFacing.south,
          sourceAssetId: 'dedicated-sheet',
          frames: [
            CharacterAnimationFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
      ],
    );
    final draft = CharacterStudioDraft(existing);
    expect(draft.sourceAssetIdFor(key), 'dedicated-sheet');
    draft.assign(key, 0, const TilesetSourceRect(x: 0, y: 0));

    expect(draft.clipChanged(key), isTrue);
    expect(draft.sourceAssetIdFor(key), isNull);
    expect(draft.previewCharacter.animations.single.sourceAssetId, isNull);
    draft.accept(draft.previewCharacter);
    expect(draft.dirty, isFalse);
  });

  test('changer la durée conserve la source et les rectangles dédiés', () {
    const key = (CharacterAnimationState.walk, EntityFacing.south);
    final existing = character.copyWith(
      animations: const [
        CharacterAnimation(
          state: CharacterAnimationState.walk,
          direction: EntityFacing.south,
          sourceAssetId: 'dedicated-sheet',
          frames: [
            CharacterAnimationFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 48),
            ),
            CharacterAnimationFrame(
              source: TilesetSourceRect(x: 32, y: 0, width: 32, height: 48),
            ),
          ],
        ),
      ],
    );
    final draft = CharacterStudioDraft(existing);
    draft.setDuration(key, 0, 300);

    expect(draft.dirty, isTrue);
    expect(draft.sourceAssetIdFor(key), 'dedicated-sheet');
    expect(draft.completeFrames(key).first.durationMs, 300);
    expect(
      draft.previewCharacter.animations.single.sourceAssetId,
      'dedicated-sheet',
    );
    expect(
      draft.previewCharacter.animations.single.frames.last,
      existing.animations.single.frames.last,
    );
  });

  test('retirer une pose dédiée conserve la source des poses restantes', () {
    const key = (CharacterAnimationState.walk, EntityFacing.south);
    final existing = character.copyWith(
      animations: const [
        CharacterAnimation(
          state: CharacterAnimationState.walk,
          direction: EntityFacing.south,
          sourceAssetId: 'dedicated-sheet',
          frames: [
            CharacterAnimationFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 48),
            ),
            CharacterAnimationFrame(
              source: TilesetSourceRect(x: 32, y: 0, width: 32, height: 48),
            ),
          ],
        ),
      ],
    );
    final draft = CharacterStudioDraft(existing);
    draft.clear(key, 1);

    expect(draft.sourceAssetIdFor(key), 'dedicated-sheet');
    expect(
      draft.previewCharacter.animations.single.sourceAssetId,
      'dedicated-sheet',
    );
    expect(draft.previewCharacter.animations.single.frames, hasLength(1));
  });
}
