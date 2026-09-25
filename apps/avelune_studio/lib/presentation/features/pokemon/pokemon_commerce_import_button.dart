import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';

class PokemonCommerceImportButton extends StatefulWidget {
  const PokemonCommerceImportButton({
    super.key,
    required this.commerce,
    required this.items,
    required this.pickJson,
    required this.onImported,
  });

  final PokemonCommerceController commerce;
  final bool items;
  final Future<String?> Function() pickJson;
  final VoidCallback onImported;

  @override
  State<PokemonCommerceImportButton> createState() =>
      _PokemonCommerceImportButtonState();
}

class _PokemonCommerceImportButtonState
    extends State<PokemonCommerceImportButton> {
  Future<void> _import() async {
    if (widget.commerce.dirty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enregistrez ou annulez le brouillon avant l’import.'),
        ),
      );
      return;
    }
    final path = await widget.pickJson();
    if (!mounted || path == null) return;
    await widget.commerce.prepareImport(path, item: widget.items);
    if (!mounted) return;
    final preview = widget.commerce.importPreview;
    if (preview == null) return;
    final accept = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(
          preview.conflict
              ? 'Remplacer ${preview.label} ?'
              : 'Importer ${preview.label} ?',
        ),
        content: Text(
          '${widget.items ? 'Objet' : 'Boutique'} : ${preview.id}\n'
          '${preview.conflict ? 'Une fiche du projet porte déjà cet identifiant. Le remplacement doit être confirmé.' : 'Aucun conflit trouvé lors de la prévisualisation.'}\n'
          'Aucune écriture n’a encore été effectuée.',
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(dialog, false),
          ),
          StudioButton(
            label: preview.conflict ? 'Remplacer' : 'Importer',
            onPressed: () => Navigator.pop(dialog, true),
          ),
        ],
      ),
    );
    if (!mounted || accept != true) {
      widget.commerce.cancelImport();
      return;
    }
    if (await widget.commerce.applyImport(confirmOverwrite: preview.conflict) &&
        mounted) {
      widget.onImported();
    }
  }

  @override
  Widget build(BuildContext context) => StudioButton(
    label: widget.commerce.importing ? 'Import en cours…' : 'Importer un JSON',
    secondary: true,
    icon: Icons.file_upload_outlined,
    onPressed: widget.commerce.importing || widget.commerce.saving
        ? null
        : _import,
  );
}
