import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';

Future<bool> confirmBorderDiscard(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abandonner les modifications de la bordure ?'),
        content: const Text('Le brouillon courant ne sera pas enregistré.'),
        actions: [
          StudioButton(
            label: 'Conserver',
            secondary: true,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          StudioButton(
            label: 'Abandonner',
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    ) ??
    false;
