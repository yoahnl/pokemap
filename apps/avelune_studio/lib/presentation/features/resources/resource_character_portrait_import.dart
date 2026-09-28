import 'package:flutter/material.dart';

import '../../../features/resources/domain/resource_port.dart';
import 'resource_image_import.dart';
import 'resource_navigation.dart';

Future<void> importCharacterPortrait(
  BuildContext context,
  ResourceNavigation navigation,
  PickResourceImage picker,
  String stateId,
) async {
  final characterId = navigation.characters.selectedCharacter?.id;
  if (characterId == null) return;
  final image = await picker();
  if (image == null || !context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Importer un portrait'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 220,
              child: Image.memory(
                image.bytes,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              ),
            ),
            const SizedBox(height: 12),
            Text('${image.width} × ${image.height} px · PNG'),
            const Text(
              'L’image sera copiée dans le projet et associée à cet état. '
              'Une image déjà utilisée ailleurs ne sera pas remplacée.',
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
