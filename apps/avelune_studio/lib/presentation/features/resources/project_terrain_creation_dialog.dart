import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/application/project_resource_preview.dart';
import '../../../features/resources/application/resource_catalog.dart';
import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/resource_port.dart';
import '../../../features/terrains/domain/terrain_connections.dart';
import 'project_library_edit_dialog.dart';
import 'project_library_resource_art.dart';
import 'project_terrain_connection_editor.dart';

class ProjectTerrainCreationDialog extends StatefulWidget {
  const ProjectTerrainCreationDialog({
    super.key,
    required this.templates,
    required this.previews,
    required this.visuals,
    required this.publish,
    required this.reconcile,
    this.importImage,
  });

  final List<ProjectLibraryItem> templates;
  final ProjectResourcePreviews previews;
  final MapWorkspaceVisuals? visuals;
  final Future<ProjectLibraryEdit> Function(ProjectSmartTilePreset) publish;
  final Future<ProjectLibraryEdit> Function(ResourceMutationReceipt) reconcile;
  final VoidCallback? importImage;

  @override
  State<ProjectTerrainCreationDialog> createState() =>
      _ProjectTerrainCreationDialogState();
}

class _ProjectTerrainCreationDialogState
    extends State<ProjectTerrainCreationDialog> {
  late final _templates = {
    for (final template in widget.templates) template.id: template,
  };
  ProjectResourcePreviewLease? _lease;
  ProjectResourcePreview? _base;
  ProjectSmartTilePreset? _draft;
  ResourceMutationReceipt? _pending;
  String? _templateId;
  String? _notice;
  var _name = '';
  var _loading = false;
  var _publishing = false;

  bool get _canPublish =>
      !_publishing &&
      (_pending != null || (_draft != null && _name.trim().isNotEmpty));

  Future<void> _chooseTemplate(String id) async {
    _lease?.release();
    final lease = widget.previews.acquire(_templates[id]!);
    setState(() {
      _templateId = id;
      _lease = lease;
      _base = null;
      _draft = null;
      _notice = null;
      _loading = true;
    });
    ProjectResourcePreview? preview;
    String? problem;
    try {
      preview = await lease.result;
      final preset = preview?.item.terrain;
      if (preview == null ||
          preset == null ||
          preset.status != SmartTilePresetStatus.published) {
        problem = 'Choisissez un terrain publié.';
      } else if (!preview.item.compatibleWith(
        preview.project.settings.dimension,
      )) {
        problem = 'Ce terrain est incompatible avec la dimension du projet.';
      } else if (preview.project.resourceLibraryCatalog.entries.any(
        (entry) => entry.mapId != null,
      )) {
        problem = 'Ce terrain dépend de ressources réservées à une carte.';
      } else if (!preview.project.smartTileCatalog.materials.any(
        (material) => material.id == preset.defaultMaterialId,
      )) {
        problem = 'Le matériau de base de ce terrain est indisponible.';
      }
    } on Object {
      problem = 'Ce terrain n’a pas pu être lu. Sélectionnez-le de nouveau.';
    }
    if (!mounted || !identical(_lease, lease)) return;
    setState(() {
      _base = problem == null ? preview : null;
      _draft = _base?.item.terrain;
      _notice = problem;
      _loading = false;
    });
  }

  Future<void> _publish() async {
    if (!_canPublish) return;
    setState(() {
      _publishing = true;
      _notice = null;
    });
    try {
      final pending = _pending;
      final edit = pending != null
          ? await widget.reconcile(pending)
          : await widget.publish(_draft!.copyWith(name: _name.trim()));
      if (mounted) {
        Navigator.of(context).pop<ProjectLibraryEditDialogResult>((
          edit: edit,
          partialReceipt: null,
        ));
      }
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() {
        if (failure is ResourceFailure) {
          _pending = failure.partialReceipt ?? _pending;
        }
        _notice = _pending != null
            ? 'Le terrain est publié. Relisez la publication pour l’afficher.'
            : failure is ResourceFailure
            ? failure.message
            : 'Le terrain n’a pas pu être publié. Votre saisie est conservée.';
        _publishing = false;
      });
    }
  }

  void _close() => Navigator.of(
    context,
  ).pop<ProjectLibraryEditDialogResult>((edit: null, partialReceipt: _pending));

  @override
  void dispose() {
    _lease?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    return PopScope(
      canPop: !_publishing && pending == null,
      child: StudioReviewDialog(
        title: 'Nouveau terrain',
        confirmLabel: _templates.isEmpty
            ? null
            : _publishing
            ? 'En cours…'
            : pending == null
            ? 'Publier le terrain'
            : 'Relire la publication',
        cancelLabel: pending == null ? 'Annuler' : 'Fermer',
        onConfirmed: _canPublish ? _publish : null,
        onCancelled: _publishing ? null : _close,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pending == null && widget.importImage != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: StudioButton(
                  label: 'Depuis une planche PNG',
                  icon: Icons.image_outlined,
                  secondary: true,
                  onPressed: _publishing ? null : widget.importImage,
                ),
              ),
              const SizedBox(height: StudioSpacing.l),
            ],
            if (pending == null)
              if (_templates.isEmpty)
                StudioNotice(
                  widget.importImage == null
                      ? 'Importez un pack contenant un sol ou un chemin compatible pour créer votre premier terrain.'
                      : 'Sélectionnez une planche PNG pour créer votre premier terrain.',
                )
              else
                _editor(context),
            if (_notice case final message?) ...[
              const SizedBox(height: StudioSpacing.l),
              StudioNotice(message, isError: pending == null),
            ],
          ],
        ),
      ),
    );
  }

  Widget _editor(BuildContext context) {
    final preview = _base;
    final draft = _draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('terrain-creation-name'),
          enabled: !_publishing,
          decoration: const InputDecoration(labelText: 'Nom du terrain'),
          onChanged: (value) => setState(() => _name = value),
        ),
        const SizedBox(height: StudioSpacing.m),
        StudioSelect(
          key: const ValueKey('terrain-creation-template'),
          label: 'Sol ou chemin de départ',
          value: _templateId,
          options: {
            for (final template in _templates.values)
              template.id: template.name,
          },
          onChanged: _publishing ? null : _chooseTemplate,
        ),
        if (_loading) ...[
          const SizedBox(height: StudioSpacing.l),
          const Center(
            child: StudioProgressIndicator(
              label: 'Chargement du terrain de départ',
            ),
          ),
        ],
        if (draft != null && preview != null) ...[
          const SizedBox(height: StudioSpacing.m),
          _configuration(context, draft, preview),
        ],
      ],
    );
  }

  Widget _configuration(
    BuildContext context,
    ProjectSmartTilePreset draft,
    ProjectResourcePreview preview,
  ) {
    final visuals = widget.visuals;
    final project = preview.project;
    final choices = visuals == null
        ? const <TerrainConnectionChoice>[]
        : editableTerrainConnections(project, draft);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: StudioBadge(terrainUsageLabel(draft.usage)),
        ),
        const SizedBox(height: StudioSpacing.m),
        StudioSelect(
          key: const ValueKey('terrain-creation-material'),
          label: 'Matériau par défaut',
          value: draft.defaultMaterialId,
          options: {
            for (final material in project.smartTileCatalog.materials)
              if (draft.allowedMaterialIds.contains(material.id) &&
                  (!material.isEmpty ||
                      material.id == preview.item.terrain?.defaultMaterialId) &&
                  _hasTerrainRule(draft, material.id))
                material.id: material.name,
          },
          onChanged: _publishing
              ? null
              : (id) => setState(
                  () => _draft = draft.copyWith(defaultMaterialId: id),
                ),
        ),
        const SizedBox(height: StudioSpacing.l),
        if (draft.rules.isEmpty)
          const StudioNotice(
            'Les motifs de ce terrain se choisissent dans la palette de la carte.',
          )
        else if (visuals == null)
          const StudioNotice('Aperçu indisponible.')
        else if (choices.isNotEmpty)
          ProjectTerrainConnectionEditor(
            key: ValueKey((draft.id, draft.defaultMaterialId)),
            preset: draft,
            project: project,
            visuals: visuals,
            connections: choices,
            enabled: !_publishing,
            onChanged: (preset) => setState(() => _draft = preset),
            previewLabel: 'Aperçu des raccords',
          )
        else
          Center(
            child: ProjectLibraryResourceArt(
              item: ResourceItem(
                id: draft.id,
                name: draft.name,
                kind: ResourceKind.terrains,
                terrain: draft,
              ),
              project: project,
              visuals: visuals,
              size: 144,
            ),
          ),
      ],
    );
  }

  bool _hasTerrainRule(ProjectSmartTilePreset preset, String materialId) =>
      materialId == _base?.item.terrain?.defaultMaterialId ||
      preset.rules.isEmpty ||
      preset.rules.any(
        (rule) =>
            rule.candidates.isNotEmpty &&
            (rule.centerMatch.kind == SmartTileMatchKind.any ||
                rule.centerMatch.materialId == materialId ||
                (preset.coverageProfile.allowFallback &&
                    preset.fallbackRuleId == rule.id)),
      );
}
