import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/domain/resource_port.dart';
import 'resource_character_portrait_import.dart';
import 'resource_image_import.dart';
import 'resource_navigation.dart';

Future<void> importCharacterAnimation(
  BuildContext context,
  ResourceNavigation navigation,
  PickResourceImage picker,
  CharacterAnimationState state,
  EntityFacing direction,
) async {
  final characterId = navigation.characters.selectedCharacter?.id;
  if (characterId == null) return;
  if (!await prepareCharacterImport(context, navigation)) return;
  final image = await picker();
  if (image == null || !context.mounted) return;
  final bicycle = state == CharacterAnimationState.bicycle ||
      state == CharacterAnimationState.bicycleIdle;
  if (bicycle ? image.width <= 0 || image.height <= 0 || image.width % 4 != 0 || image.height % 4 != 0
      : image.width % 3 != 0 || image.height <= 0) {
    navigation.setImportError(
      bicycle ? 'Le vélo demande une planche de quatre poses et quatre directions, sans marge.'
          : 'La largeur de l’image doit être divisible par trois pour créer des poses égales.',
    );
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Importer une animation dédiée'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 180,
              child: Image.memory(
                image.bytes,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              bicycle ? 'Quatre poses · ${image.width ~/ 4} × ${image.height ~/ 4} px · Bas, gauche, droite, haut'
                  : 'Trois poses · ${image.width ~/ 3} × ${image.height} px chacune',
            ),
            Text(
              bicycle ? 'La rangée de la direction choisie sera importée. Les autres animations restent intactes.'
                  : 'L’image complète est découpée en trois bandes verticales. '
              'Elle remplacera la source de la direction choisie. '
              'Les autres directions et leurs images restent intactes.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Importer'),
        ),
      ],
    ),
  );
  if (confirmed != true ||
      !context.mounted ||
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
