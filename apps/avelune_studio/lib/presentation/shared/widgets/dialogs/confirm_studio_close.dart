import 'package:flutter/material.dart';

Future<String?> confirmStudioClose(BuildContext context) => showDialog<String>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Conserver vos modifications ?'),
    content: const Text('Des cartes ont des modifications non enregistrées.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, 'cancel'),
        child: const Text('Annuler'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, 'discard'),
        child: const Text('Abandonner'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, 'save'),
        child: const Text('Enregistrer'),
      ),
    ],
  ),
);
