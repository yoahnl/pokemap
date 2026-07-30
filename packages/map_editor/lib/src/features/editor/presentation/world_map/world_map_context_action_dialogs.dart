import 'package:flutter/material.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/map_context_target.dart';

typedef WorldMapContextDeleteConfirmationRequested = Future<bool> Function({
  required BuildContext context,
  required MapObjectContextTarget target,
  required String title,
  required String message,
});

Future<bool> showWorldMapContextDeleteConfirmation({
  required BuildContext context,
  required MapObjectContextTarget target,
  required String title,
  required String message,
}) async {
  final result = await showPokeMapConfirmationDialog<bool>(
    context: context,
    title: title,
    message: message,
    actions: const <PokeMapDialogAction<bool>>[
      PokeMapDialogAction(label: 'Annuler', value: false),
      PokeMapDialogAction(
        label: 'Supprimer',
        value: true,
        variant: PokeMapButtonVariant.danger,
      ),
    ],
  );
  return result == true;
}
