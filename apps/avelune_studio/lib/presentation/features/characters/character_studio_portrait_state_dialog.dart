import 'package:flutter/material.dart';

class CharacterStudioPortraitStateDialog extends StatefulWidget {
  const CharacterStudioPortraitStateDialog({super.key});

  @override
  State<CharacterStudioPortraitStateDialog> createState() =>
      _CharacterStudioPortraitStateDialogState();
}

class _CharacterStudioPortraitStateDialogState
    extends State<CharacterStudioPortraitStateDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nouvelle expression'),
    content: SizedBox(
      width: 360,
      child: TextField(
        controller: _name,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nom de l’expression',
          helperText: 'Commune à tous les personnages du projet.',
          helperMaxLines: 2,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _name.text.trim()),
        child: const Text('Créer l’expression'),
      ),
    ],
  );
}
