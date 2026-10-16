import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'resource_catalog.dart';
import 'resource_management_dialog.dart';
import 'resource_navigation.dart';

Future<String?> _publishLibraryChange(
  ResourceNavigation navigation,
  String action,
  Map<String, Object?> parameters, {
  bool destructive = false,
  String? expectedSnapshotRevision,
}) async {
  try {
    final revision =
        expectedSnapshotRevision ?? await navigation.captureResourceRevision();
    final preparation = await navigation.prepareOperation(
      action,
      parameters,
      expectedSnapshotRevision: revision,
    );
    await navigation.applyPrepared(
      preparation,
      confirmDestructive: destructive,
    );
    return null;
  } on Object catch (failure) {
    return '$failure';
  }
}

String resourceFamilyLabel(ResourceLibraryCatalog catalog, String id) {
  final names = <String>[];
  final visited = <String>{};
  String? current = id;
  while (current != null && visited.add(current)) {
    final family = catalog.effectiveFamilies
        .where((family) => family.id == current)
        .firstOrNull;
    if (family == null) break;
    names.insert(0, family.name);
    current = family.parentId;
  }
  return names.isEmpty ? 'Famille introuvable' : names.join(' / ');
}

Future<void> classifyResource(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) async {
  navigation.beginManagementDialog();
  final project = navigation.workspace.project!;
  final catalog = project.resourceLibraryCatalog;
  final entry = catalog.entryFor(item.canonicalKind, item.id);
  var familyId = entry?.familyId;
  var placementContext = entry?.placementContext;
  var mapId = entry?.mapId;
  var role = entry?.role ?? ResourceLibraryRole.standard;
  try {
    final revision = await navigation.captureResourceRevision();
    if (!context.mounted || navigation.isDisposed) return;
    await showResourceManagementRoute(
      context,
      (_) => ResourceManagementDialog(
        title: 'Ranger « ${item.name} »',
        submitLabel: 'Enregistrer',
        dirty: () =>
            placementContext != entry?.placementContext ||
            familyId != entry?.familyId ||
            mapId != entry?.mapId ||
            role != (entry?.role ?? ResourceLibraryRole.standard),
        valid: () =>
            mapId == null || project.maps.any((map) => map.id == mapId),
        submit: () => _publishLibraryChange(navigation, 'resource.classify', {
          'resourceKind': item.canonicalKind,
          'resourceId': item.id,
          'familyId': familyId,
          'mapId': mapId,
          'role': role.name,
          'placementContext': placementContext?.name,
        }, expectedSnapshotRevision: revision),
        fields: (refresh, busy) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudioSelect(
              key: const ValueKey('resource-classify-context'),
              label: 'Contexte d’usage',
              value: placementContext?.name ?? '',
              options: {
                '': resourcePlacementContextLabel(null),
                for (final value in ResourcePlacementContext.values)
                  value.name: resourcePlacementContextLabel(value),
              },
              onChanged: busy
                  ? null
                  : (value) {
                      placementContext = value.isEmpty
                          ? null
                          : ResourcePlacementContext.values.byName(value);
                      refresh();
                    },
            ),
            const SizedBox(height: 16),
            StudioSelect(
              key: const ValueKey('resource-classify-role'),
              label: 'Présentation dans la bibliothèque',
              value: role.name,
              options: const {
                'standard': 'Ressource standard',
                'component': 'Composant réutilisable',
              },
              onChanged: busy
                  ? null
                  : (value) {
                      role = ResourceLibraryRole.values.byName(value);
                      refresh();
                    },
            ),
            if (role == ResourceLibraryRole.component) ...[
              const SizedBox(height: 8),
              const Text(
                'Disponible dans les ateliers de composition. Le filtre « Afficher les composants » permet de le retrouver dans la bibliothèque.',
              ),
            ],
            const SizedBox(height: 16),
            StudioSelect(
              key: const ValueKey('resource-classify-family'),
              label: 'Famille et sous-famille',
              value: familyId ?? '',
              options: {
                '': 'Sans famille',
                for (final family in catalog.effectiveFamilies)
                  family.id: resourceFamilyLabel(catalog, family.id),
              },
              onChanged: busy
                  ? null
                  : (value) {
                      familyId = value.isEmpty ? null : value;
                      refresh();
                    },
            ),
            const SizedBox(height: 16),
            StudioSelect(
              key: const ValueKey('resource-classify-availability'),
              label: 'Disponibilité',
              value: mapId == null ? 'project' : 'map',
              options: const {
                'project': 'Commune à tout le projet',
                'map': 'Propre à une carte',
              },
              onChanged: busy || project.maps.isEmpty
                  ? null
                  : (value) {
                      mapId = value == 'project'
                          ? null
                          : navigation.workspace.active?.current.id ??
                                project.maps.first.id;
                      refresh();
                    },
            ),
            if (mapId != null) ...[
              const SizedBox(height: 16),
              StudioSelect(
                key: const ValueKey('resource-classify-map'),
                label: 'Carte propriétaire',
                value: mapId,
                options: {for (final map in project.maps) map.id: map.name},
                onChanged: busy
                    ? null
                    : (value) {
                        mapId = value;
                        refresh();
                      },
              ),
              const SizedBox(height: 12),
              const Text(
                'Cette ressource sera proposée uniquement sur cette carte. '
                'Si elle est déjà utilisée ailleurs, Studio refusera ce changement.',
              ),
            ],
          ],
        ),
      ),
    );
  } finally {
    navigation.endManagementDialog();
  }
}

Future<void> manageResourceFamilies(
  BuildContext context,
  ResourceNavigation navigation,
) async {
  navigation.beginManagementDialog();
  try {
    await showResourceManagementRoute(
      context,
      (_) => _ResourceFamilyManager(navigation: navigation),
    );
  } finally {
    navigation.endManagementDialog();
  }
}

class _ResourceFamilyManager extends StatefulWidget {
  const _ResourceFamilyManager({required this.navigation});
  final ResourceNavigation navigation;

  @override
  State<_ResourceFamilyManager> createState() => _ResourceFamilyManagerState();
}

class _ResourceFamilyManagerState extends State<_ResourceFamilyManager> {
  String? selectedId;
  bool busy = false;
  String? error;
  ResourceLibraryCatalog get catalog =>
      widget.navigation.workspace.project!.resourceLibraryCatalog;

  Future<void> edit({ResourceFamily? initial, String? parent}) async {
    final revision = await widget.navigation.captureResourceRevision();
    if (!mounted || widget.navigation.isDisposed) return;
    var name = initial?.name ?? '';
    var parentId = initial?.parentId ?? parent;
    final id = initial?.id ?? 'family_${DateTime.now().microsecondsSinceEpoch}';
    final forbidden = initial == null
        ? <String>{}
        : catalog.descendantFamilyIds(initial.id);
    await showResourceManagementRoute(
      context,
      (_) => ResourceManagementDialog(
        title: initial == null ? 'Créer une famille' : 'Modifier la famille',
        submitLabel: initial == null ? 'Créer' : 'Enregistrer',
        dirty: () =>
            name != (initial?.name ?? '') ||
            parentId != (initial?.parentId ?? parent),
        valid: () => name.trim().isNotEmpty,
        submit: () => _publishLibraryChange(
          widget.navigation,
          initial == null ? 'resource.family.create' : 'resource.family.update',
          {'familyId': id, 'name': name.trim(), 'parentId': parentId},
          expectedSnapshotRevision: revision,
        ),
        fields: (refresh, saving) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudioDraftField(
              key: const ValueKey('resource-family-name'),
              label: 'Nom de la famille',
              value: name,
              enabled: !saving,
              onChanged: (value) {
                name = value;
                refresh();
              },
            ),
            const SizedBox(height: 16),
            StudioSelect(
              key: const ValueKey('resource-family-parent'),
              label: 'Famille parente',
              value: parentId ?? '',
              options: {
                '': 'Aucune · famille principale',
                for (final family in catalog.effectiveFamilies)
                  if (!forbidden.contains(family.id))
                    family.id: resourceFamilyLabel(catalog, family.id),
              },
              onChanged: saving
                  ? null
                  : (value) {
                      parentId = value.isEmpty ? null : value;
                      refresh();
                    },
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> remove(ResourceFamily family) async {
    final revision = await widget.navigation.captureResourceRevision();
    if (!mounted || widget.navigation.isDisposed) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer « ${family.name} » ?'),
        content: const Text(
          'Une famille contenant des ressources ou des sous-familles doit '
          'd’abord être vidée. Aucun fichier de ressource ne sera supprimé.',
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          StudioButton(
            label: 'Supprimer la famille',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    final failure = await _publishLibraryChange(
      widget.navigation,
      'resource.family.delete',
      {'familyId': family.id},
      destructive: true,
      expectedSnapshotRevision: revision,
    );
    if (!mounted) return;
    setState(() {
      busy = false;
      error = failure;
      if (failure == null) selectedId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = catalog.effectiveFamilies
        .where((family) => family.id == selectedId)
        .firstOrNull;
    final predefined = ResourceLibraryCatalog.predefinedFamilies.any(
      (family) => family.id == selectedId,
    );
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.sizeOf(context).height - 80,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: StudioPanel(
              title: 'Familles de ressources',
              children: [
                const Text(
                  'Les familles de base sont communes à la bibliothèque et à la '
                  'palette. Ajoutez vos propres familles ou sous-familles.',
                ),
                const SizedBox(height: 16),
                StudioSelect(
                  key: const ValueKey('resource-family-selected'),
                  label: 'Famille',
                  value: selectedId,
                  options: {
                    for (final family in catalog.effectiveFamilies)
                      family.id: resourceFamilyLabel(catalog, family.id),
                  },
                  onChanged: busy
                      ? null
                      : (value) => setState(() => selectedId = value),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StudioButton(
                      key: const ValueKey('resource-family-create'),
                      label: 'Nouvelle famille',
                      icon: Icons.add,
                      onPressed: busy ? null : () => edit(),
                    ),
                    StudioButton(
                      key: const ValueKey('resource-subfamily-create'),
                      label: 'Nouvelle sous-famille',
                      secondary: true,
                      onPressed: busy || selected == null
                          ? null
                          : () => edit(parent: selected.id),
                    ),
                    if (selected != null && !predefined) ...[
                      StudioButton(
                        label: 'Modifier',
                        secondary: true,
                        onPressed: busy ? null : () => edit(initial: selected),
                      ),
                      StudioButton(
                        label: 'Supprimer',
                        secondary: true,
                        onPressed: busy ? null : () => remove(selected),
                      ),
                    ],
                  ],
                ),
                if (predefined) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Famille de base · vous pouvez y ajouter des sous-familles.',
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                StudioButton(
                  label: 'Fermer',
                  secondary: true,
                  onPressed: busy ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
