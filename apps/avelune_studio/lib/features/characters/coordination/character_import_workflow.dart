import 'package:map_core/map_core_domain.dart';

import '../../resources/coordination/resource_navigation.dart';
import '../../resources/domain/resource_image_picker.dart';
import '../../resources/domain/resource_port.dart';

class CharacterImportWorkflow {
  CharacterImportWorkflow({
    required this.navigation,
    required this.picker,
    required this.isActive,
    required this.confirmImage,
    required this.confirmSave,
  });

  final ResourceNavigation navigation;
  final PickResourceImage picker;
  final bool Function() isActive;
  final Future<bool> Function(PickedResourceImage image) confirmImage;
  final Future<bool> Function() confirmSave;

  Future<bool> prepare() async {
    if (!navigation.characters.selectedDraft!.dirty) return true;
    if (!await confirmSave() || !isActive()) return false;
    return navigation.characters.saveSelected();
  }

  Future<void> sheet() async {
    final image = await picker();
    if (image == null || !isActive()) return;
    final n = navigation;
    if (image.width % 3 != 0 || image.height % 4 != 0) {
      n.setImportError(
        'La planche doit contenir 3 colonnes et 4 rangées de même taille.',
      );
      return;
    }
    final settings = n.workspace.project!.settings;
    final poseWidth = image.width ~/ 3;
    final poseHeight = image.height ~/ 4;
    if (poseWidth % settings.tileWidth != 0 ||
        poseHeight % settings.tileHeight != 0 ||
        poseWidth < settings.tileWidth * 2 ||
        poseHeight < settings.tileHeight * 2) {
      n.setImportError(
        'Chaque pose doit occuper au moins deux cases par axe et un nombre entier de cases (${settings.tileWidth} × ${settings.tileHeight} px).',
      );
      return;
    }
    if (!await confirmImage(image) || !isActive()) return;
    n.error = null;
    n.setImportBusy(true);
    try {
      final receipt = await n.port.importImage(
        ResourceImageImport(
          sourcePath: image.path,
          name: image.name,
          tileWidth: poseWidth,
          tileHeight: poseHeight,
        ),
      );
      await n.accept(receipt);
      final tilesetId = receipt.createdTilesetId!;
      if (!await n.characters.create(
        image.name,
        tilesetId,
        frameWidth: poseWidth ~/ settings.tileWidth,
        frameHeight: poseHeight ~/ settings.tileHeight,
      )) {
        n.error =
            'La planche est dans Images, mais le personnage n’a pas été créé : ${n.characters.error}';
      } else {
        final source = n.workspace.project!.tilesets
            .firstWhere((entry) => entry.id == tilesetId)
            .source;
        if (source is ProjectRegularAtlasTilesetSource) {
          n.characters.assignClassicSheet(source);
        }
        n.openCharacters();
      }
    } catch (failure) {
      n.error = '$failure';
    } finally {
      n.setImportBusy(false);
    }
  }

  Future<void> animation(
    CharacterAnimationState state,
    EntityFacing direction,
  ) async {
    final characterId = navigation.characters.selectedCharacter?.id;
    if (characterId == null || !await prepare()) return;
    final image = await picker();
    if (image == null || !isActive()) return;
    final bicycle =
        state == CharacterAnimationState.bicycle ||
        state == CharacterAnimationState.bicycleIdle;
    if (bicycle
        ? image.width <= 0 ||
              image.height <= 0 ||
              image.width % 4 != 0 ||
              image.height % 4 != 0
        : image.width % 3 != 0 || image.height <= 0) {
      navigation.setImportError(
        bicycle
            ? 'Le vélo demande une planche de quatre poses et quatre directions, sans marge.'
            : 'La largeur de l’image doit être divisible par trois pour créer des poses égales.',
      );
      return;
    }
    if (!await confirmImage(image) ||
        !isActive() ||
        navigation.workspace.isDisposed ||
        !navigation.workspace.project!.characters.any(
          (entry) => entry.id == characterId,
        )) {
      return;
    }
    navigation.setImportBusy(true);
    try {
      final receipt = await navigation.port.importCharacterAnimation(
        CharacterAnimationImport(
          sourcePath: image.path,
          characterId: characterId,
          state: state,
          direction: direction,
          poseWidth: image.width ~/ (bicycle ? 4 : 3),
          poseHeight: bicycle ? image.height ~/ 4 : image.height,
        ),
      );
      if (!navigation.workspace.isDisposed) await navigation.accept(receipt);
    } catch (failure) {
      if (!navigation.workspace.isDisposed) {
        navigation.setImportError('$failure');
      }
    } finally {
      if (!navigation.workspace.isDisposed) navigation.setImportBusy(false);
    }
  }

  Future<void> portrait(String stateId) async {
    if (navigation.characters.saving) return;
    final characterId = navigation.characters.selectedCharacter?.id;
    if (characterId == null || !await prepare()) return;
    final image = await picker();
    if (image == null || !isActive()) return;
    if (!await confirmImage(image) ||
        !isActive() ||
        navigation.workspace.isDisposed ||
        !navigation.workspace.project!.characters.any(
          (entry) => entry.id == characterId,
        )) {
      return;
    }
    navigation.setImportBusy(true);
    try {
      final receipt = await navigation.port.importCharacterPortrait(
        CharacterPortraitImport(
          sourcePath: image.path,
          characterId: characterId,
          portraitStateId: stateId,
        ),
      );
      if (!navigation.workspace.isDisposed) await navigation.accept(receipt);
    } catch (failure) {
      if (!navigation.workspace.isDisposed) {
        navigation.setImportError('$failure');
      }
    } finally {
      if (!navigation.workspace.isDisposed) navigation.setImportBusy(false);
    }
  }
}
