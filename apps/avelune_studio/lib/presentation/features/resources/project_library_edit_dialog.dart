import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/resource_port.dart';
import '../../../features/resources/domain/studio_search_text.dart';

part 'project_library_edit_fields.dart';

typedef ProjectLibraryEditDialogResult = ({
  ProjectLibraryEdit? edit,
  ResourceMutationReceipt? partialReceipt,
});

class ProjectLibraryEditDialog extends StatefulWidget {
  const ProjectLibraryEditDialog.rename({
    super.key,
    required this.item,
    required this.saveName,
    this.duplicate = false,
    this.prepareCatalog,
  }) : file = null,
       defaultTileSize = null,
       saveDetails = null,
       saveClassification = null,
       families = const {};

  const ProjectLibraryEditDialog.importFile({
    super.key,
    required this.file,
    required this.defaultTileSize,
    required this.saveName,
  }) : item = null,
       duplicate = false,
       prepareCatalog = null,
       saveDetails = null,
       saveClassification = null,
       families = const {};

  const ProjectLibraryEditDialog.classify({
    super.key,
    required this.item,
    required this.families,
    required this.saveClassification,
  }) : file = null,
       defaultTileSize = null,
       duplicate = false,
       prepareCatalog = null,
       saveDetails = null,
       saveName = null;

  const ProjectLibraryEditDialog.details({
    super.key,
    required this.item,
    required this.saveDetails,
  }) : duplicate = false,
       prepareCatalog = null,
       file = null,
       defaultTileSize = null,
       saveName = null,
       saveClassification = null,
       families = const {};

  final ProjectLibraryItem? item;
  final PickedProjectLibraryFile? file;
  final LibraryImageSize? defaultTileSize;
  final Map<String, String> families;
  final bool duplicate;
  final Future<void> Function()? prepareCatalog;
  final Future<ProjectLibraryEdit> Function(String?, ResourcePlacementContext?)?
  saveDetails;
  final Future<ProjectLibraryEdit> Function(String, LibraryImageSize?)?
  saveName;
  final Future<ProjectLibraryEdit> Function(String?, ResourceLibraryRole)?
  saveClassification;

  @override
  State<ProjectLibraryEditDialog> createState() =>
      _ProjectLibraryEditDialogState();
}

class _ProjectLibraryEditDialogState extends State<ProjectLibraryEditDialog> {
  late String _name = widget.duplicate
      ? '${widget.item!.name} — copie'
      : widget.item?.name ?? widget.file!.name;
  late String _description = widget.item?.description ?? '';
  late ResourcePlacementContext? _placement = widget.item?.placementContext;
  late String? _family = widget.item?.familyId;
  late ResourceLibraryRole _role =
      widget.item?.role ?? ResourceLibraryRole.standard;
  late String _width = '${widget.defaultTileSize?.width ?? 32}';
  late String _height = '${widget.defaultTileSize?.height ?? 32}';
  final _familySearch = TextEditingController();
  bool _tiles = false;
  bool _saving = false;
  ResourceMutationReceipt? _partialReceipt;
  String? _failure;
  bool _needsPreparation = false;

  bool get _published => _partialReceipt != null;
  String? get _descriptionValue {
    final value = _description.trim();
    return value.isEmpty ? null : value;
  }

  void _change(VoidCallback update) => setState(update);

  LibraryImageSize? get _tileSize {
    final image = widget.file?.imageSize;
    if (image == null || !_tiles) return image;
    final width = int.tryParse(_width);
    final height = int.tryParse(_height);
    if (width == null ||
        height == null ||
        width <= 0 ||
        height <= 0 ||
        image.width % width != 0 ||
        image.height % height != 0) {
      return null;
    }
    return (width: width, height: height);
  }

  bool get _canSave {
    if (_saving || _published || _needsPreparation) return false;
    if (widget.saveDetails != null) {
      return _description.length <= 2000 &&
          (_descriptionValue != widget.item!.description ||
              _placement != widget.item!.placementContext);
    }
    if (widget.saveClassification != null) {
      return _family != widget.item!.familyId || _role != widget.item!.role;
    }
    return _name.trim().isNotEmpty &&
        (widget.duplicate || _name.trim() != widget.item?.name) &&
        (widget.file?.imageSize == null || _tileSize != null);
  }

  @override
  void dispose() {
    _familySearch.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      final edit = await switch (widget) {
        ProjectLibraryEditDialog(saveDetails: final save?) => save(
          _descriptionValue,
          _placement,
        ),
        ProjectLibraryEditDialog(saveClassification: final save?) => save(
          _family,
          _role,
        ),
        _ => widget.saveName!(_name.trim(), _tileSize),
      };
      if (mounted) {
        Navigator.of(context).pop<ProjectLibraryEditDialogResult>((
          edit: edit,
          partialReceipt: null,
        ));
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _needsPreparation = error is ProjectLibraryNeedsPreparation;
        _partialReceipt = error is ResourceFailure
            ? error.partialReceipt
            : null;
        _failure = _needsPreparation
            ? 'Préparez le catalogue pour dupliquer cette ressource.'
            : _published
            ? 'La modification a été enregistrée. La bibliothèque sera actualisée à la fermeture.'
            : error is ResourceFailure
            ? error.message
            : 'Cette modification a échoué. Réessayez.';
      });
    }
  }

  Future<void> _prepare() async {
    setState(() => _saving = true);
    try {
      await widget.prepareCatalog!();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _needsPreparation = false;
        _failure = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failure = error is ResourceFailure
            ? error.message
            : 'La préparation du catalogue a échoué.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final importing = widget.file != null;
    final classification = widget.saveClassification != null;
    final details = widget.saveDetails != null;
    final prepare =
        _needsPreparation && !_saving && widget.prepareCatalog != null;
    return PopScope(
      canPop: !_saving && !_published,
      child: StudioReviewDialog(
        title: switch ((importing, classification, details, widget.duplicate)) {
          (true, _, _, _) => 'Importer une ressource',
          (_, true, _, _) => 'Classer la ressource',
          (_, _, true, _) => 'Modifier la fiche',
          (_, _, _, true) => 'Dupliquer la ressource',
          _ => 'Renommer la ressource',
        },
        confirmLabel: _saving
            ? 'En cours…'
            : importing
            ? 'Importer dans la bibliothèque'
            : widget.duplicate
            ? 'Créer la copie'
            : 'Enregistrer',
        onConfirmed: _canSave ? _save : null,
        secondaryActionLabel: prepare ? 'Préparer le catalogue' : null,
        onSecondaryAction: prepare ? _prepare : null,
        onCancelled: () {
          if (_saving) return;
          Navigator.of(context).pop<ProjectLibraryEditDialogResult>((
            edit: null,
            partialReceipt: _partialReceipt,
          ));
        },
        cancelLabel: _published ? 'Fermer' : 'Annuler',
        contentWidth: 440,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (details)
              ..._detailsFields()
            else if (classification)
              ..._classificationFields()
            else
              ..._nameFields(),
            if (_failure case final failure?) ...[
              const SizedBox(height: StudioSpacing.l),
              StudioNotice(failure, isError: !_published),
            ],
          ],
        ),
      ),
    );
  }
}
