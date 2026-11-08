import 'package:flutter/material.dart';

import '../../../features/resources/domain/resource_mutation_preparation.dart';
import '../../../features/resources/domain/resource_usage_port.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import 'resource_catalog.dart';
import 'resource_management_dialog.dart';
import 'resource_navigation.dart';

Future<String?> replaceResourceUsages(
  BuildContext context,
  ResourceNavigation navigation, {
  required ResourceUsageTarget target,
  required String name,
}) async {
  final project = navigation.workspace.project;
  if (project == null ||
      navigation.isDisposed ||
      navigation.busy ||
      !const {'decors', 'models3d'}.contains(target.family)) {
    return null;
  }
  final kind = target.family == 'models3d' ? 'model3d' : 'element';
  final choices = [
    for (final item in resourceCatalog(project))
      if (item.canonicalKind == kind && item.id != target.id) item,
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  final maps = {for (final map in project.maps) map.id: map.name};
  String? summary;
  ResourceMutationPreparation? preparation;
  try {
    await showResourceManagementRoute(
      context,
      (_) => ResourceUsageReplacementDialog(
        name: name,
        spatial: target.family == 'models3d',
        choices: choices,
        mapName: (id) => maps[id] ?? id,
        canApply: () =>
            navigation.pendingReceipt == null &&
            navigation.usageDraftOwners.isEmpty,
        prepare: (replacementId) async {
          final previous = preparation;
          preparation = null;
          if (previous != null) await navigation.releasePreparation(previous);
          return preparation = await navigation.prepareOperation(
            'resource.usages.replace',
            {
              'family': target.family,
              'resourceId': target.id,
              'replacementId': replacementId,
            },
          );
        },
        apply: (prepared, done) async {
          try {
            await navigation.applyPrepared(prepared, confirmDestructive: true);
            summary = done;
            return null;
          } on Object catch (failure) {
            return navigation.pendingReceipt == null
                ? '$failure'
                : 'Publication effectuée, mais l’interface doit être relue. '
                      'Fermez ce dialogue puis utilisez « Relire le résultat ». '
                      'Ne relancez pas la mutation.';
          }
        },
      ),
    );
  } finally {
    final retained = preparation;
    if (retained != null) await navigation.releasePreparation(retained);
  }
  return summary;
}

class ResourceUsageReplacementDialog extends StatefulWidget {
  const ResourceUsageReplacementDialog({
    super.key,
    required this.name,
    required this.spatial,
    required this.choices,
    required this.mapName,
    required this.canApply,
    required this.prepare,
    required this.apply,
  });

  final String name;
  final bool spatial;
  final List<ResourceItem> choices;
  final String Function(String mapId) mapName;
  final bool Function() canApply;
  final Future<ResourceMutationPreparation> Function(String replacementId)
  prepare;
  final Future<String?> Function(
    ResourceMutationPreparation preparation,
    String summary,
  )
  apply;

  @override
  State<ResourceUsageReplacementDialog> createState() =>
      _ResourceUsageReplacementDialogState();
}

class _ResourceUsageReplacementDialogState
    extends State<ResourceUsageReplacementDialog> {
  final _query = TextEditingController();
  ResourceItem? _replacement;
  ResourceMutationPreparation? _preparation;
  String? _error;
  bool _preparing = false;
  bool _confirmed = false;
  int _sequence = 0;

  @override
  void dispose() {
    _sequence++;
    _query.dispose();
    super.dispose();
  }

  Future<void> _choose(ResourceItem choice, VoidCallback refresh) async {
    final sequence = ++_sequence;
    setState(() {
      _replacement = choice;
      _preparation = null;
      _confirmed = false;
      _error = null;
      _preparing = true;
    });
    refresh();
    try {
      final prepared = await widget.prepare(choice.id);
      if (mounted && sequence == _sequence) {
        setState(() => _preparation = prepared);
      }
    } on Object catch (failure) {
      if (mounted && sequence == _sequence) {
        setState(() => _error = '$failure');
      }
    } finally {
      if (mounted && sequence == _sequence) {
        setState(() => _preparing = false);
        refresh();
      }
    }
  }

  List<({String mapId, int count})> get _scope => [
    for (final entry in (_preparation?.impact['maps'] as List? ?? const []))
      if (entry case {
        'mapId': final String mapId,
        'instanceIds': final List ids,
      })
        (mapId: mapId, count: ids.length),
  ];

  String get _summary {
    final occurrences = _preparation?.impact['occurrenceCount'] ?? 0;
    final maps = _preparation?.impact['mapCount'] ?? 0;
    return '$occurrences ${occurrences == 1 ? 'occurrence' : 'occurrences'} '
        'sur $maps ${maps == 1 ? 'carte' : 'cartes'}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.text.trim().toLowerCase();
    final choices = [
      for (final choice in widget.choices)
        if (query.isEmpty || choice.name.toLowerCase().contains(query)) choice,
    ];
    final prepared = _preparation;
    final empty = prepared != null && prepared.noChange;
    return ResourceManagementDialog(
      title: 'Remplacer ses usages',
      submitLabel: empty ? 'Aucun usage à remplacer' : 'Remplacer les usages',
      maxWidth: 640,
      dirty: () => false,
      valid: () =>
          !_preparing &&
          prepared != null &&
          !empty &&
          _confirmed &&
          widget.canApply(),
      submit: () => widget.apply(
        prepared!,
        'Usages remplacés : $_summary vers « ${_replacement!.name} ».',
      ),
      fields: (refresh, busy) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Toutes les occurrences de cette ressource sur les cartes pointeront '
            'vers la ressource choisie. Leur position est conservée et aucune '
            'définition n’est modifiée.',
          ),
          Text(
            'Pour une seule occurrence, utilisez « Remplacer ici » dans la carte. '
            'Pour changer l’apparence partout sans changer de ressource, utilisez '
            '« Modifier la définition ».',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          StudioSearchField(
            key: const ValueKey('resource-usage-replacement-search'),
            controller: _query,
            label: 'Rechercher la ressource de remplacement',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: choices.isEmpty
                ? const Center(
                    child: Text('Aucune ressource compatible ne correspond.'),
                  )
                : ListView.builder(
                    itemCount: choices.length,
                    itemBuilder: (context, index) {
                      final choice = choices[index];
                      return StudioChoice(
                        key: ValueKey(
                          'resource-usage-replacement-${choice.id}',
                        ),
                        label: choice.name,
                        subtitle: choice.category.isEmpty
                            ? null
                            : choice.category,
                        selected: _replacement?.id == choice.id,
                        leading: Icon(
                          widget.spatial
                              ? Icons.view_in_ar_outlined
                              : Icons.image_outlined,
                          size: 18,
                        ),
                        onTap: busy || _preparing
                            ? null
                            : () => _choose(choice, refresh),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          if (_preparing) ...[
            const Text('Calcul de la portée…'),
            const LinearProgressIndicator(),
          ] else if (_error != null)
            Text(
              _error!,
              key: const ValueKey('resource-usage-replacement-error'),
              style: TextStyle(color: theme.colorScheme.error),
            )
          else if (prepared == null)
            const Text('Choisissez la ressource de remplacement.')
          else if (empty)
            const Text(
              'Aucune occurrence sur les cartes : rien ne sera modifié.',
            )
          else ...[
            Text(
              'Portée : $_summary',
              key: const ValueKey('resource-usage-replacement-scope'),
              style: theme.textTheme.titleSmall,
            ),
            for (final entry in _scope)
              Text(
                'Carte « ${widget.mapName(entry.mapId)} » · '
                '${entry.count} ${entry.count == 1 ? 'occurrence' : 'occurrences'}',
              ),
            Text(
              'Les cartes non listées et les définitions restent intactes.',
              style: theme.textTheme.bodySmall,
            ),
            CheckboxListTile(
              key: const ValueKey('resource-usage-replacement-confirm'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Je confirme : « ${widget.name} » devient '
                '« ${_replacement!.name} » sur ces cartes.',
              ),
              value: _confirmed,
              onChanged: busy
                  ? null
                  : (value) {
                      setState(() => _confirmed = value == true);
                      refresh();
                    },
            ),
          ],
        ],
      ),
    );
  }
}
