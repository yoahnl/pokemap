import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/map_workspace/domain/map_catalog_preparation.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import 'map_catalogue_form_dialog.dart';
import 'map_lifecycle_issues.dart';
import 'map_resize_preview.dart';
import 'map_workspace_visuals.dart';

Future<void> showResizeMapDialog(
  BuildContext context,
  MapWorkspaceController controller,
  ProjectMapEntry entry, {
  MapWorkspaceVisuals? visuals,
}) async {
  final project = controller.project!;
  MapData? source;
  String? error;
  try {
    source =
        controller.documents[entry.id]?.base.map ??
        (await controller.port.loadMap(controller.session, entry)).map;
  } on Object catch (failure) {
    error = '$failure';
  }
  if (!context.mounted || controller.isDisposed) return;
  var width = '${source?.size.width ?? ''}',
      height = '${source?.size.height ?? ''}';
  var analyzing = false, published = false;
  MapCatalogPreparation? preparation;
  int? positive(String value) {
    final parsed = int.tryParse(value);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  await showMapCatalogueForm(
    context,
    title: 'Redimensionner la carte',
    submitLabel: 'Appliquer le redimensionnement',
    currentSubmitLabel: () =>
        published ? 'Relire la carte' : 'Appliquer le redimensionnement',
    additionalBusy: () => analyzing,
    valid: () =>
        published ||
        (preparation?.canApply == true && preparation?.noChange == false),
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(entry.name, style: Theme.of(context).textTheme.titleMedium),
        if (source != null)
          Text(
            'Dimensions actuelles : ${source.size.width} × ${source.size.height} cases',
          ),
        Text(
          'Cases : ${project.settings.tileWidth} × ${project.settings.tileHeight} px · grille du projet',
        ),
        const SizedBox(height: 12),
        StudioDraftField(
          key: const ValueKey('resize-map-width'),
          value: width,
          label: 'Largeur (cases)',
          enabled: !busy && !published,
          errorText: positive(width) == null ? 'Entier positif requis' : null,
          onChanged: (value) {
            width = value;
            preparation = null;
            error = null;
            refresh();
          },
        ),
        const SizedBox(height: 12),
        StudioDraftField(
          key: const ValueKey('resize-map-height'),
          value: height,
          label: 'Hauteur (cases)',
          enabled: !busy && !published,
          errorText: positive(height) == null ? 'Entier positif requis' : null,
          onChanged: (value) {
            height = value;
            preparation = null;
            error = null;
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
          loading: analyzing,
          onPressed:
              busy ||
                  published ||
                  source == null ||
                  positive(width) == null ||
                  positive(height) == null
              ? null
              : () async {
                  analyzing = true;
                  preparation = null;
                  error = null;
                  refresh();
                  try {
                    preparation = await controller
                        .prepareCatalog('map.resize_apply', {
                          'mapId': entry.id,
                          'width': positive(width)!,
                          'height': positive(height)!,
                        });
                  } on Object catch (failure) {
                    error = '$failure';
                  }
                  analyzing = false;
                  refresh();
                },
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: StudioNotice(error!, isError: true),
          ),
        if (preparation?.noChange == true)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: StudioNotice(
              'Aucune modification : les dimensions sont identiques.',
            ),
          ),
        if (preparation?.canApply == true && preparation?.noChange == false)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: StudioNotice(
              'Analyse terminée : aucun contenu ni référence ne déborde.',
            ),
          ),
        if (preparation != null)
          MapLifecycleIssues(
            issues: preparation!.issues,
            controller: controller,
          ),
        if (preparation != null && visuals != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: MapResizePreview(
              map: preparation!.sourceMap,
              project: project,
              visuals: visuals,
              proposedWidth: positive(width)!,
              proposedHeight: positive(height)!,
            ),
          ),
      ],
    ),
    submit: () async {
      final result = published
          ? await controller.retryCatalogRefresh()
          : await controller.applyPreparedCatalog(preparation!);
      published = result.published;
      return result.integrated
          ? null
          : published
          ? 'Les dimensions sont enregistrées sur disque. ${result.error ?? ''} Relisez la carte.'
          : result.error ??
                'Le redimensionnement a été refusé. Relancez l’analyse.';
    },
  );
}
