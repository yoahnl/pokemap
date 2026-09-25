import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';

Future<String?> showPokemonCommerceCreateDialog(
  BuildContext context, {
  required bool items,
}) => showDialog<String>(
  context: context,
  builder: (_) => _CommerceCreateDialog(items: items),
);

class _CommerceCreateDialog extends StatefulWidget {
  const _CommerceCreateDialog({required this.items});

  final bool items;

  @override
  State<_CommerceCreateDialog> createState() => _CommerceCreateDialogState();
}

class _CommerceCreateDialogState extends State<_CommerceCreateDialog> {
  final input = TextEditingController();

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.items ? 'Créer un objet' : 'Créer une boutique'),
    content: TextField(
      controller: input,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'Identifiant stable'),
      onSubmitted: (value) => Navigator.pop(context, value),
    ),
    actions: [
      StudioButton(
        label: 'Annuler',
        secondary: true,
        onPressed: () => Navigator.pop(context),
      ),
      StudioButton(
        label: 'Créer',
        onPressed: () => Navigator.pop(context, input.text),
      ),
    ],
  );
}
