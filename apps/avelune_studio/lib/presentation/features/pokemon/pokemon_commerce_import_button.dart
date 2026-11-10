import '../../../features/pokemon/application/pokemon_commerce_import_workflow.dart';
import '../../../features/pokemon/domain/pokemon_commerce_port.dart';

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
  late final PokemonCommerceImportWorkflow _workflow =
      PokemonCommerceImportWorkflow(
        commerce: widget.commerce,
        isActive: () =>
            mounted && identical(widget.commerce, _workflow.commerce),
      );

  Future<void> _import() async {
    final importing = _workflow.importJson(
      items: widget.items,
      picker: widget.pickJson,
      confirm: _confirm,
    );
    setState(() {});
    final imported = await importing;
    if (!mounted) return;
    if (imported) {
      widget.onImported();
    } else if (_workflow.refusal case final refusal?) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(refusal)));
    }
    setState(() {});
  }

  @override
  void dispose() {
    _workflow.dispose();
    super.dispose();
  }

  Future<bool> _confirm(PokemonCommerceImportPreview preview) async {
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
    return accept == true;
  }

  @override
  Widget build(BuildContext context) => StudioButton(
    label: widget.commerce.importing ? 'Import en cours…' : 'Importer un JSON',
    secondary: true,
    icon: Icons.file_upload_outlined,
    onPressed:
        _workflow.choosing ||
            widget.commerce.importing ||
            widget.commerce.saving
        ? null
        : _import,
  );
}
