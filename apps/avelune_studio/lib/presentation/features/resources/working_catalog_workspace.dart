import 'dart:async';

import 'package:flutter/material.dart';

import '../../../features/project_session/domain/project_session.dart';
import '../../../features/resources/application/working_catalog_controller.dart';
import '../../../features/resources/domain/working_catalog_port.dart';
import '../characters/character_contact_shadow_controls.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/dialogs/studio_review_dialog.dart';
import '../../shared/widgets/feedback/studio_empty_state.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_app_shell.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shell/studio_home_navigation.dart';

class WorkingCatalogWorkspace extends StatefulWidget {
  const WorkingCatalogWorkspace({
    super.key,
    required this.session,
    required this.controller,
    required this.onClose,
    required this.registerExitGuard,
    this.home,
    this.previewBuilder,
    this.embedded = false,
    this.onSaved,
    this.onOpenTools,
    this.onRecovered,
  });

  final ProjectSession session;
  final WorkingCatalogController controller;
  final Future<void> Function() onClose;
  final void Function(Future<bool> Function()?) registerExitGuard;
  final StudioHomeNavigation? home;
  final Widget Function(WorkingCatalogDetail detail)? previewBuilder;
  final bool embedded;
  final Future<void> Function()? onSaved;
  final VoidCallback? onOpenTools;
  final Future<void> Function()? onRecovered;

  @override
  State<WorkingCatalogWorkspace> createState() =>
      _WorkingCatalogWorkspaceState();
}

class _WorkingCatalogWorkspaceState extends State<WorkingCatalogWorkspace> {
  WorkingCatalogController get catalog => widget.controller;
  bool synchronizing = false;
  bool synchronizationPending = false;
  String? saved;
  String? navigationNotice;
  String? tagsIdentity;
  String tagsText = '';
  WorkingCatalogDetail? previewDetail;
  Widget? preview;

  Widget resourcePreview(WorkingCatalogDetail detail) {
    if (preview == null ||
        previewDetail?.entry.identity != detail.entry.identity ||
        !identical(previewDetail?.definitions, detail.definitions)) {
      previewDetail = detail;
      preview = widget.previewBuilder!(detail);
    }
    return preview!;
  }

  @override
  void didUpdateWidget(covariant WorkingCatalogWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewBuilder != widget.previewBuilder) {
      previewDetail = null;
      preview = null;
    }
  }

  @override
  void initState() {
    super.initState();
    catalog.addListener(refresh);
    widget.registerExitGuard(allowExit);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.embedded) {
        widget.home?.publish(
          availableMaps: const [],
          testAvailable: false,
          navigate: (destination, mapId) {
            if (!mounted) return;
            unawaited(showLibrary(destination));
          },
          guard: allowExit,
        );
      }
      unawaited(catalog.search(''));
    });
  }

  void refresh() {
    if (mounted) {
      setState(() {
        if (catalog.dirty) saved = null;
      });
    }
  }

  Future<bool> allowExit() => allowCatalogExit();

  Future<bool> allowCatalogExit() async {
    if (catalog.saving || catalog.recovering || synchronizing) return false;
    if (synchronizationPending && !await synchronize()) return false;
    if (!mounted) return false;
    if (!catalog.dirty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => StudioReviewDialog(
        title: 'Conserver vos modifications ?',
        content: const Text(
          'Cette ressource contient des modifications non enregistrées.',
        ),
        confirmLabel: 'Enregistrer',
        onConfirmed: () => Navigator.pop(context, 'save'),
        secondaryActionLabel: 'Abandonner',
        onSecondaryAction: () => Navigator.pop(context, 'discard'),
        onCancelled: () => Navigator.pop(context, 'cancel'),
      ),
    );
    if (!mounted) return false;
    if (choice == 'save') return save();
    if (choice == 'discard') {
      catalog.discard();
      return true;
    }
    return false;
  }

  Future<void> showLibrary([String destination = 'resources']) async {
    if (!await allowCatalogExit() || !mounted) return;
    setState(() {
      navigationNotice =
          const {
            'resources',
            'resourceLibrary',
            'library',
          }.contains(destination)
          ? null
          : 'Cet atelier est accessible depuis la navigation de Studio.';
    });
    final selected = catalog.selected;
    await catalog.search(catalog.query);
    if (mounted &&
        selected != null &&
        catalog.selected?.identity == selected.identity &&
        !catalog.dirty) {
      await catalog.select(selected);
    }
  }

  Future<void> recover() async {
    await catalog.recover(refresh: widget.onRecovered == null);
    if (!mounted ||
        catalog.error != null ||
        catalog.recoveryOperationIds.isNotEmpty) {
      return;
    }
    try {
      await widget.onRecovered?.call();
    } catch (failure) {
      if (mounted) {
        setState(
          () => navigationNotice =
              'Rouvrez le projet après la reprise : $failure',
        );
      }
    }
  }

  Future<bool> synchronize() async {
    synchronizing = true;
    try {
      await widget.onSaved?.call();
      synchronizationPending = false;
      return true;
    } catch (failure) {
      if (mounted) {
        setState(
          () => navigationNotice =
              'La ressource est enregistrée, mais la carte ne peut pas être actualisée : $failure',
        );
      }
      return false;
    } finally {
      synchronizing = false;
    }
  }

  Future<bool> save() async {
    if (synchronizing) return false;
    saved = null;
    if (!await catalog.save()) return false;
    synchronizationPending = true;
    if (!mounted || !await synchronize() || !mounted) return false;
    setState(() => saved = catalog.dirty ? null : 'Ressource enregistrée.');
    return !catalog.dirty;
  }

  @override
  void dispose() {
    catalog.removeListener(refresh);
    widget.registerExitGuard(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return libraryContent();
    return StudioAppShell(
      projectName: widget.session.name,
      actions: [
        StudioButton(
          label: 'Accueil',
          secondary: true,
          onPressed: widget.home?.showHome,
        ),
        StudioButton(
          key: const ValueKey('working-catalog-close'),
          label: 'Fermer le projet',
          secondary: true,
          onPressed: () async {
            if (await allowExit()) await widget.onClose();
          },
        ),
      ],
      child: catalog.recoveryOperationIds.isNotEmpty
          ? StudioPanel(
              title: 'Reprendre l’enregistrement du projet',
              children: [
                const StudioNotice(
                  'Un enregistrement a été interrompu. Reprenez cette opération pour accéder au projet.',
                ),
                if (catalog.error != null) StudioNotice(catalog.error!),
                StudioButton(
                  key: const ValueKey('working-catalog-recover'),
                  label: catalog.recovering ? 'Reprise…' : 'Reprendre',
                  onPressed: catalog.recovering ? null : recover,
                ),
              ],
            )
          : libraryContent(),
    );
  }

  Widget libraryContent() => Column(
    children: [
      StudioPageHeader(
        title: 'Bibliothèque du projet',
        description:
            widget.session.storage == ProjectSessionStorage.portableCatalog
            ? 'Recherchez une ressource dans toute la bibliothèque et consultez son aperçu.'
            : 'Recherchez une ressource dans toute la bibliothèque, puis ouvrez son aperçu pour la modifier.',
        actions: [
          if (widget.onOpenTools != null)
            StudioButton(
              label: 'Créer et importer',
              onPressed: catalog.saving || synchronizing
                  ? null
                  : widget.onOpenTools,
            ),
          StudioButton(
            label: 'Actualiser',
            secondary: true,
            onPressed: catalog.loading
                ? null
                : () => catalog.search(catalog.query),
          ),
        ],
      ),
      if (!widget.embedded || navigationNotice != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: StudioNotice(
            navigationNotice ??
                (widget.session.storage == ProjectSessionStorage.portableCatalog
                    ? 'L’édition des cartes n’est pas disponible pour ce projet publié. Vous pouvez consulter sa bibliothèque.'
                    : 'L’édition des cartes n’est pas encore disponible pour ce projet. Vous pouvez consulter et modifier les informations de ses ressources.'),
          ),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: (context, bounds) {
            final fields = [
              StudioDraftField(
                key: const ValueKey('working-catalog-search'),
                label: 'Rechercher dans la bibliothèque',
                value: catalog.query,
                onChanged: (value) => catalog.search(value),
              ),
              StudioSelect(
                label: 'Type de ressource',
                value: catalog.kind,
                options: const {
                  'element': 'Décors',
                  'model3d': 'Modèles 3D',
                  'tileset': 'Images et tuiles',
                  'smartTilePreset': 'Terrains',
                  'borderBlueprint': 'Bordures',
                  'environmentPreset': 'Environnements',
                  'character': 'Personnages',
                },
                onChanged: (value) =>
                    catalog.search(catalog.query, kind: value),
              ),
              StudioSelect(
                label: 'Contexte recherché',
                value: catalog.placementContext,
                options: const {
                  '': 'Tous les contextes',
                  'interior': 'Intérieur',
                  'exterior': 'Extérieur',
                  'both': 'Intérieur et extérieur',
                },
                onChanged: (value) =>
                    catalog.search(catalog.query, context: value),
              ),
            ];
            if (bounds.maxWidth < 700) {
              return Column(
                children: [
                  for (final field in fields)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: field,
                    ),
                ],
              );
            }
            return Row(
              children: [
                for (var index = 0; index < fields.length; index++) ...[
                  if (index > 0) const SizedBox(width: 12),
                  Expanded(flex: index == 0 ? 2 : 1, child: fields[index]),
                ],
              ],
            );
          },
        ),
      ),
      if (catalog.error != null)
        Padding(
          padding: const EdgeInsets.all(12),
          child: StudioNotice(catalog.error!),
        ),
      if (saved != null)
        Padding(padding: const EdgeInsets.all(8), child: Text(saved!)),
      Expanded(
        child: LayoutBuilder(
          builder: (context, bounds) => bounds.maxWidth >= 850
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: list()),
                    const SizedBox(width: 12),
                    SizedBox(width: 380, child: detail()),
                  ],
                )
              : ListView(
                  children: [
                    SizedBox(height: 300, child: list()),
                    detail(),
                  ],
                ),
        ),
      ),
    ],
  );

  Widget list() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '${catalog.items.length} ressources affichées sur ${catalog.total} résultats',
        ),
      ),
      Expanded(
        child: catalog.items.isEmpty
            ? catalog.loading
                  ? const Center(child: CircularProgressIndicator())
                  : const StudioEmptyState(
                      title: 'Aucune ressource correspondante.',
                      description:
                          'Changez la recherche, le type ou le contexte.',
                    )
            : ListView.builder(
                key: const ValueKey('working-catalog-results'),
                padding: const EdgeInsets.all(12),
                itemCount: catalog.items.length,
                itemBuilder: (context, index) {
                  final entry = catalog.items[index];
                  return StudioChoice(
                    key: ValueKey('working-resource-${entry.identity}'),
                    label: entry.name,
                    subtitle: entry.description.isEmpty
                        ? null
                        : entry.description,
                    leading: const Icon(Icons.category_outlined),
                    selected: catalog.selected?.identity == entry.identity,
                    onTap: catalog.saving
                        ? null
                        : () {
                            saved = null;
                            unawaited(catalog.select(entry));
                          },
                  );
                },
              ),
      ),
      if (catalog.nextCursor != null || catalog.hasPreviousPage)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              StudioButton(
                label: 'Page précédente',
                secondary: true,
                onPressed: catalog.loading || !catalog.hasPreviousPage
                    ? null
                    : catalog.previousPage,
              ),
              Text('Page ${catalog.pageNumber}'),
              StudioButton(
                key: const ValueKey('working-catalog-more'),
                label: catalog.loading ? 'Chargement…' : 'Page suivante',
                onPressed: catalog.loading || catalog.nextCursor == null
                    ? null
                    : catalog.loadMore,
              ),
            ],
          ),
        ),
    ],
  );

  Widget detail() {
    final draft = catalog.draft;
    final selected = catalog.detail;
    if (catalog.opening) {
      return const Center(child: CircularProgressIndicator());
    }
    if (draft == null || selected == null) {
      return const StudioEmptyState(
        title: 'Choisissez une ressource',
        description: 'Son aperçu et ses informations apparaîtront ici.',
      );
    }
    final editable =
        !catalog.saving &&
        widget.session.storage != ProjectSessionStorage.portableCatalog;
    if (tagsIdentity != selected.entry.identity) {
      tagsIdentity = selected.entry.identity;
      tagsText = draft.tags.join(', ');
    }
    return SingleChildScrollView(
      key: ValueKey('working-catalog-detail-${selected.entry.identity}'),
      padding: const EdgeInsets.fromLTRB(0, 12, 16, 16),
      child: StudioPanel(
        title: selected.entry.name,
        children: [
          if (widget.previewBuilder != null) ...[
            SizedBox(
              height: 180,
              child: Center(child: resourcePreview(selected)),
            ),
            const SizedBox(height: 12),
          ],
          StudioDraftField(
            key: const ValueKey('working-resource-name'),
            label: 'Nom',
            value: draft.name,
            enabled: editable,
            onChanged: (value) => catalog.edit(name: value),
            errorText: draft.name.trim().isEmpty
                ? 'Donnez un nom à cette ressource.'
                : null,
          ),
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('working-resource-description'),
            label: 'Description',
            lines: 3,
            value: draft.description,
            enabled: editable,
            onChanged: (value) => catalog.edit(description: value),
            errorText: draft.description.length > 2000
                ? 'La description ne doit pas dépasser 2000 caractères.'
                : null,
          ),
          const SizedBox(height: 12),
          if (selected.entry.supportsTags)
            StudioDraftField(
              key: const ValueKey('working-resource-tags'),
              label: 'Mots-clés',
              helperText: 'Séparez les mots-clés par des virgules.',
              value: tagsText,
              enabled: editable,
              onChanged: (value) {
                tagsText = value;
                catalog.edit(
                  tags: value
                      .split(',')
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty)
                      .toSet(),
                );
              },
            ),
          const SizedBox(height: 12),
          StudioSelect(
            label: 'Contexte d’usage',
            value: draft.placementContext,
            options: const {
              '': 'Non renseigné',
              'interior': 'Intérieur',
              'exterior': 'Extérieur',
              'both': 'Intérieur et extérieur',
            },
            onChanged: editable
                ? (value) => catalog.edit(placementContext: value)
                : null,
          ),
          if (selected.entry.kind == 'character') ...[
            const SizedBox(height: 16),
            CharacterContactShadowControls(
              projectDefault: selected.contactShadowProjectDefault,
              value: draft.contactShadow,
              onChanged: (value) => catalog.edit(contactShadow: value),
              busy: !editable,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StudioButton(
                key: const ValueKey('working-resource-save'),
                label: catalog.saving ? 'Enregistrement…' : 'Enregistrer',
                onPressed: editable && catalog.dirty && draft.valid
                    ? save
                    : null,
              ),
              StudioButton(
                label: 'Annuler les modifications',
                secondary: true,
                onPressed: editable && catalog.dirty
                    ? () {
                        tagsIdentity = null;
                        catalog.discard();
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          StudioNotice(
            widget.session.storage == ProjectSessionStorage.portableCatalog
                ? 'Ce projet publié est disponible en lecture seule.'
                : 'Enregistrez les informations de cette ressource depuis ce panneau. Les ateliers de composition, le déplacement entre familles et la suppression ne sont pas encore disponibles dans cette bibliothèque.',
          ),
        ],
      ),
    );
  }
}
