import 'package:avelune_studio/features/map_workspace/coordination/workspace_map_catalog_actions.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import 'map_catalogue_form_dialog.dart';
import 'map_lifecycle_issues.dart';
import 'map_resize_preview.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';

Future<void> showResizeMapDialog(
  BuildContext context,
  MapWorkspaceController controller,
  ProjectMapEntry entry, {
  MapWorkspaceVisuals? visuals,
}) async {
  final project = controller.project!;
  final resizing = WorkspaceMapResize(controller, entry);
  await resizing.load();
  if (!context.mounted || controller.isDisposed) return;
  await showMapCatalogueForm(
    context,
    title: 'Redimensionner la carte',
    submitLabel: 'Appliquer le redimensionnement',
    currentSubmitLabel: () => resizing.published
        ? 'Relire la carte'
        : 'Appliquer le redimensionnement',
    additionalBusy: () => resizing.analyzing,
    valid: () => resizing.valid,
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(entry.name, style: Theme.of(context).textTheme.titleMedium),
        if (resizing.source != null)
          Text(
            'Dimensions actuelles : ${resizing.source!.size.width} × ${resizing.source!.size.height} cases',
          ),
        Text(
          'Cases : ${project.settings.tileWidth} × ${project.settings.tileHeight} px · grille du projet',
        ),
        const SizedBox(height: 12),
        StudioDraftField(
          key: const ValueKey('resize-map-width'),
          value: resizing.width,
          label: 'Largeur (cases)',
          enabled: !busy && !resizing.published,
          errorText: WorkspaceMapResize.positive(resizing.width) == null
              ? 'Entier positif requis'
              : null,
          onChanged: (value) {
            resizing.setWidth(value);
            refresh();
          },
        ),
        const SizedBox(height: 12),
        StudioDraftField(
          key: const ValueKey('resize-map-height'),
          value: resizing.height,
          label: 'Hauteur (cases)',
          enabled: !busy && !resizing.published,
          errorText: WorkspaceMapResize.positive(resizing.height) == null
              ? 'Entier positif requis'
              : null,
          onChanged: (value) {
            resizing.setHeight(value);
            refresh();
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'L’origine reste en haut à gauche. Les nouvelles cases sont ajoutées '
          'à droite et en bas. Aucun contenu ne sera déplacé ni coupé. '
          'L’application renouvelle la base enregistrée de cette carte et efface '
          'son ancien historique de géométrie.',
        ),
        const SizedBox(height: 12),
        StudioButton(
          label: 'Analyser les conséquences',
          secondary: true,
          icon: Icons.search,
          loading: resizing.analyzing,
          onPressed: busy || !resizing.canAnalyze
              ? null
              : () async {
                  final pending = resizing.analyze();
                  refresh();
                  await pending;
                  refresh();
                },
        ),
        if (resizing.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: StudioNotice(resizing.error!, isError: true),
          ),
        if (resizing.preparation?.noChange == true)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: StudioNotice(
              'Aucune modification : les dimensions sont identiques.',
            ),
          ),
        if (resizing.preparation?.canApply == true &&
            resizing.preparation?.noChange == false)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: StudioNotice(
              'Analyse terminée : aucun contenu ni référence ne déborde.',
            ),
          ),
        if (resizing.preparation != null)
          MapLifecycleIssues(
            issues: resizing.preparation!.issues,
            controller: controller,
          ),
        if (resizing.preparation != null && visuals != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: MapResizePreview(
              map: resizing.preparation!.sourceMap,
              project: project,
              visuals: visuals,
              proposedWidth: WorkspaceMapResize.positive(resizing.width)!,
              proposedHeight: WorkspaceMapResize.positive(resizing.height)!,
            ),
          ),
      ],
    ),
    submit: resizing.submit,
  );
}
