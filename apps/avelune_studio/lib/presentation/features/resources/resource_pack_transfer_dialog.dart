import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../features/resources/application/resource_pack_transfer_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/dialogs/studio_review_dialog.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'resource_pack_selection.dart';

class _PackIdentity extends StatelessWidget {
  const _PackIdentity({required this.controller});
  final ResourcePackTransferController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    final pack = Map<String, Object?>.from(c.inspection['pack']! as Map);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StudioPanel(
        compact: true,
        title: '${pack['name']} · ${pack['version']}',
        children: [
          Text('Univers : ${pack['universeId']}'),
          Text('Provenance déclarée : ${pack['provenance']}'),
          Text(
            'Traçabilité : ${switch (c.inspection['provenanceStatus']) {
              'qualified' => 'qualifiée',
              'declared' => 'déclarée',
              _ => 'non qualifiée',
            }}',
          ),
          Text(
            'Archive : ${c.inspection['archiveBytes']} octets · ${c.inspection['authorCount']} auteurs · ${c.inspection['sourceCount']} sources',
          ),
          Text(
            'Capacités requises : ${(c.inspection['requiredCapabilities']! as List).map(resourcePackCapabilityLabel).join(', ')}',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StudioButton(
                label: 'Auteurs',
                secondary: true,
                onPressed: c.operationActive
                    ? null
                    : () => c.showAttributions('authors'),
              ),
              StudioButton(
                label: 'Sources',
                secondary: true,
                onPressed: c.operationActive
                    ? null
                    : () => c.showAttributions('sources'),
              ),
            ],
          ),
          Text(
            '${c.attributions.length} ${c.attributionSection == 'authors' ? 'auteurs' : 'sources'} affichés sur ${c.attributionCount}',
          ),
          for (final row in c.attributions)
            Text(
              '${row['label']}${row['labelComplete'] == false ? '… (nom abrégé)' : ''}${row['sourceUrl'] == null ? '' : ' · ${row['sourceUrl']}'}',
            ),
          if (c.attributionCursor != null)
            StudioButton(
              label: 'Suite des attributions',
              secondary: true,
              onPressed: c.operationActive ? null : c.nextAttributionPage,
            ),
        ],
      ),
    );
  }
}

class _PackReviewSummary extends StatelessWidget {
  const _PackReviewSummary({required this.summary});
  final Map<String, Object?> summary;
  @override
  Widget build(BuildContext context) => StudioPanel(
    compact: true,
    title: 'Bilan préparé avant cet import',
    children: [
      Text(
        '${summary['selectedResourceCount']} ressources choisies · ${summary['selectedPatternCount']} motifs choisis',
      ),
      Text(
        '${summary['resourceCount']} ressources · ${summary['supportCount']} supports d’édition · ${summary['dependencyCount']} dépendances automatiques, sources comprises',
      ),
      Text(
        '${summary['createdDefinitionCount']} nouvelles définitions · ${summary['copiedDefinitionCount']} copies · ${summary['reusedDefinitionCount']} réutilisées ou déjà installées',
      ),
      Text(
        '${summary['blockedDefinitionCount']} définitions bloquées pour cette installation · ${summary['presentDefinitionCount']} présentes avant cet import',
      ),
      Text(
        'Sources sélectionnées : ${summary['sourceBytes']} octets · licences : ${summary['licenseBytes']} octets',
      ),
      Text(
        'Écritures prévues pour cette installation : fichiers ${summary['outputBytes']} octets · métadonnées ${summary['metadataBytes']} octets · total prévu : ${summary['writeBytes']} octets',
      ),
      Text('Dont nouveaux contenus prévus : ${summary['newBlobBytes']} octets'),
      Text(
        '${summary['localModifiedResourceCount']} définitions modifiées et ${summary['localDeletedResourceCount']} suppressions locales conservées. Le détail des modifications porte sur les ressources principales.',
      ),
    ],
  );
}

String resourcePackPhaseLabel(String? phase) => switch (phase) {
  'queued' => 'Transfert en attente',
  'running' => 'Démarrage du transfert',
  'staging' => 'Copie de l’archive',
  'inspecting' => 'Vérification du pack',
  'preparing' => 'Préparation de la sélection',
  'applying' => 'Installation des ressources',
  'finalizing' => 'Finalisation de l’installation',
  'completed' => 'Étape terminée',
  'cancelling' => 'Annulation en cours',
  'recoveryRequired' => 'Reprise nécessaire',
  'checkingRecovery' => 'Vérification de la reprise',
  _ => 'Préparation du transfert',
};
String resourcePackCapabilityLabel(Object? capability) => switch (capability) {
  'images.png' => 'Images PNG',
  'models.glb' => 'Modèles GLB',
  'resources.element' => 'Décors',
  'resources.model3d' => 'Ressources 3D',
  'resources.smart-tile-preset' => 'Terrains',
  'resources.tileset' => 'Planches d’images',
  'resources.border-blueprint' => 'Bordures',
  'resources.environment-preset' => 'Environnements',
  'resources.character' => 'Personnages',
  'smart_tiles.patterns' => 'Motifs de terrain',
  _ => 'Capacité du pack',
};

Future<void> showResourcePackImport(
  BuildContext context,
  ResourcePackTransferController controller, {
  VoidCallback? onShowImported,
}) async {
  if (controller.routeActive) return;
  controller.routeActive = true;
  try {
    unawaited(controller.beginImport());
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ResourcePackTransferDialog(
        controller: controller,
        onShowImported: onShowImported,
      ),
    );
  } finally {
    controller.routeActive = false;
  }
}

class ResourcePackTransferDialog extends StatefulWidget {
  const ResourcePackTransferDialog({
    super.key,
    required this.controller,
    this.onShowImported,
  });
  final ResourcePackTransferController controller;
  final VoidCallback? onShowImported;
  @override
  State<ResourcePackTransferDialog> createState() =>
      _ResourcePackTransferDialogState();
}

class _ResourcePackTransferDialogState
    extends State<ResourcePackTransferDialog> {
  bool _popping = false;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    if (widget.controller.phase == ResourcePackTransferPhase.closed) _changed();
  }

  void _changed() {
    if (!mounted) return;
    if (widget.controller.phase == ResourcePackTransferPhase.closed &&
        !_popping) {
      _popping = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  Future<void> _close() async {
    await widget.controller.requestClose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final selection = c.phase == ResourcePackTransferPhase.selecting;
    final review = c.phase == ResourcePackTransferPhase.preview;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: _popping,
          onPopInvokedWithResult: (popped, _) {
            if (!popped) unawaited(_close());
          },
          child: StudioReviewDialog(
            title: 'Importer un pack de ressources',
            cancelLabel: c.operationActive && c.cancelAllowed
                ? 'Annuler le transfert'
                : 'Fermer',
            onCancelled: _close,
            confirmLabel: c.requiresReconciliation
                ? 'Relire la bibliothèque'
                : c.requiresRecovery
                ? 'Reprendre la finalisation'
                : selection
                ? 'Vérifier l’import'
                : review
                ? 'Importer la sélection'
                : 'Choisir un pack',
            onConfirmed: c.operationActive
                ? null
                : c.requiresReconciliation
                ? () => c.retryReconciliation()
                : c.requiresRecovery
                ? c.recover
                : c.canPrepare
                ? c.prepare
                : c.canApply
                ? c.apply
                : c.phase == ResourcePackTransferPhase.idle
                ? c.beginImport
                : null,
            secondaryActionLabel:
                c.phase == ResourcePackTransferPhase.complete &&
                    c.firstImported != null
                ? 'Voir les ressources importées'
                : review
                ? (c.conflictCount > 0
                      ? 'Importer une copie'
                      : 'Modifier la sélection')
                : null,
            onSecondaryAction:
                c.phase == ResourcePackTransferPhase.complete &&
                    c.firstImported != null
                ? () async {
                    if (await c.requestClose()) widget.onShowImported?.call();
                  }
                : review && !c.operationActive
                ? c.conflictCount > 0
                      ? () => c.prepare(importCopy: true)
                      : c.backToSelection
                : null,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (c.notice != null) StudioNotice(c.notice!),
                if (c.error != null) StudioNotice(c.error!, isError: true),
                if (c.inspection.isNotEmpty) _PackIdentity(controller: c),
                if (c.operationActive) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    '${resourcePackPhaseLabel(c.jobPhase)}${c.jobCounters['copiedBytes'] == null ? '' : ' · ${c.jobCounters['copiedBytes']} octets copiés'}${c.cancelAllowed ? '' : '. Attendez la relecture de la bibliothèque avant de fermer le projet.'}',
                  ),
                ],
                if (selection) ResourcePackSelection(controller: c),
                if ((review || c.phase == ResourcePackTransferPhase.complete) &&
                    c.preparedSummary.isNotEmpty)
                  _PackReviewSummary(summary: c.preparedSummary),
                if (review) ...[
                  const Text(
                    'Les dépendances sont incluses automatiquement. Les ressources présentes dans le projet sont conservées.',
                  ),
                  const SizedBox(height: 12),
                  StudioPanel(
                    compact: true,
                    title: 'Ressources incluses',
                    children: [
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: c.preview.length,
                          itemBuilder: (_, index) {
                            final row = c.preview[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                row['conflict'] != null
                                    ? '${row['label']} : ${row['message']}'
                                    : '${row['label'] ?? resourcePackKindLabel(row['kind'])}${row['labelComplete'] == false ? '… (nom abrégé)' : ''} · ${resourcePackKindLabel(row['kind'])}\n${row['selected'] == true ? 'Ressource choisie' : 'Nécessaire pour « ${row['requiredByLabel']} » (exemple de ressource choisie)'}',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  if (c.previewCursor != null)
                    StudioButton(
                      label: 'Suite des ressources incluses',
                      secondary: true,
                      onPressed: c.operationActive ? null : c.nextPreviewPage,
                    ),
                ],
                if (c.phase == ResourcePackTransferPhase.idle)
                  const Text(
                    'Choisissez un fichier .aveluneassets pour consulter son contenu avant l’installation.',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
