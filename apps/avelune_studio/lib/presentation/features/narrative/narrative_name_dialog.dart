import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_button.dart';

Future<String?> askNarrativeName(
  BuildContext context,
  String title, {
  bool multiline = false,
}) async {
  var value = '';
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, rebuild) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 400,
          child: TextField(
            autofocus: true,
            minLines: multiline ? 3 : 1,
            maxLines: multiline ? 6 : 1,
            onChanged: (text) => rebuild(() => value = text),
            decoration: InputDecoration(
              labelText: multiline ? 'Une étape par ligne' : 'Nom',
            ),
          ),
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context),
          ),
          StudioButton(
            label: 'Créer',
            onPressed: value.trim().isEmpty
                ? null
                : () => Navigator.pop(context, value.trim()),
          ),
        ],
      ),
    ),
  );
}
