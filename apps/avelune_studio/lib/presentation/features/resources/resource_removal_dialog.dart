import 'package:flutter/material.dart';
import '../../../features/resources/domain/resource_mutation_preparation.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'resource_catalog.dart';
import 'resource_management_dialog.dart';

class ResourceRemovalDialog extends StatefulWidget {
  const ResourceRemovalDialog({
    super.key,
    required this.item,
    required this.preview,
    required this.prepare,
    required this.apply,
    required this.openUsages,
    required this.dirtyOwners,
    required this.canApply,
  });
  final ResourceItem item;
  final Widget preview;
  final Future<ResourceMutationPreparation> Function(bool removeSource) prepare;
  final Future<String?> Function(ResourceMutationPreparation) apply;
  final VoidCallback openUsages;
  final List<String> Function() dirtyOwners;
  final bool Function() canApply;

  @override
  State<ResourceRemovalDialog> createState() => _ResourceRemovalDialogState();
}

class _ResourceRemovalDialogState extends State<ResourceRemovalDialog> {
  ResourceMutationPreparation? _preparation;
  bool _working = false;
  bool _removeSource = false;
  bool _confirmed = false;
  bool _sourceRemovalSupported = false;
  String? _sourceRemovalReason;
  String? _error;
  int _sequence = 0;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _sequence++;
    super.dispose();
  }

  Future<void> _prepare() async {
    final sequence = ++_sequence;
    setState(() {
      _preparation = null;
      _working = true;
      _confirmed = false;
      _error = null;
      _sourceRemovalReason = null;
    });
    try {
      final result = await widget.prepare(_removeSource);
      if (mounted && sequence == _sequence) {
        if (widget.item.tileset != null &&
            (result.impact['sourceRemoved'] == true) != _removeSource) {
          throw StateError(
            'Le plan ne correspond plus au choix de conservation de la source.',
          );
        }
        setState(() {
          _preparation = result;
          _sourceRemovalSupported =
              result.impact['sourceRemovalSupported'] == true;
          _sourceRemovalReason =
              result.impact['sourceRemovalReason'] as String?;
        });
      }
    } on Object catch (failure) {
      if (mounted && sequence == _sequence) {
        setState(() {
          _error = '$failure';
          _sourceRemovalSupported = false;
        });
      }
    } finally {
      if (mounted && sequence == _sequence) {
        setState(() => _working = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.item.tileset != null;
    return ResourceManagementDialog(
      title: image
          ? 'Supprimer la planche'
          : 'Supprimer la définition de décor',
      submitLabel: image ? 'Supprimer la planche' : 'Supprimer la définition',
      dirty: () => false,
      valid: () =>
          !_working &&
          _preparation != null &&
          _confirmed &&
          widget.dirtyOwners().isEmpty &&
          widget.canApply(),
      submit: () => widget.apply(_preparation!),
      fields: (refresh, busy) {
        final dirty = widget.dirtyOwners();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 140, child: widget.preview),
            const SizedBox(height: 12),
            Text(
              widget.item.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(
              '${image ? 'Définition de planche' : 'Définition de décor'} : '
              '${widget.item.id}',
            ),
            const SizedBox(height: 12),
            Text(
              image
                  ? 'Seule cette planche est retirée. Aucun décor, terrain, '
                        'personnage ou placement n’est supprimé.'
                  : 'Seule cette définition est retirée. Les images, catégories '
                        'et instances ne sont jamais supprimées en cascade.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Les blobs partagés et versions historiques nécessaires sont '
              'conservés. Cette action ne promet aucune collecte de pixels.',
            ),
            if (image)
              CheckboxListTile(
                key: const ValueKey('resource-removal-source'),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Supprimer aussi le fichier source inutilisé',
                ),
                subtitle: Text(_sourceRemovalMessage()),
                value: _removeSource,
                onChanged:
                    busy ||
                        _working ||
                        (!_sourceRemovalSupported && !_removeSource)
                    ? null
                    : (value) {
                        _removeSource = value == true;
                        _prepare();
                      },
              ),
            if (_working) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                'Suppression refusée : $_error',
                key: const ValueKey('resource-removal-refusal'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (dirty.isNotEmpty)
              Text(
                'Brouillons à résoudre avant suppression : ${dirty.join(' · ')}',
              ),
            if (_preparation != null) ...[
              const SizedBox(height: 12),
              Text('Analyse canonique prête pour la révision identifiée.'),
              SelectableText('Révision : ${_preparation!.snapshotRevision}'),
              Text(
                '${_preparation!.changedPaths.length} document(s) concernés.',
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StudioButton(
                  label: 'Voir les usages dans le projet',
                  secondary: true,
                  icon: Icons.account_tree_outlined,
                  onPressed: busy || _working ? null : widget.openUsages,
                ),
                StudioButton(
                  label: 'Réanalyser',
                  secondary: true,
                  onPressed: busy || _working ? null : _prepare,
                ),
              ],
            ),
            CheckboxListTile(
              key: const ValueKey('resource-removal-confirm'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                _preparation?.impact['sourceRemoved'] == true
                    ? 'Je confirme le retrait de la définition et de sa source logique.'
                    : 'Je confirme le retrait de cette définition.',
              ),
              value: _confirmed,
              onChanged:
                  busy || _working || _preparation == null || dirty.isNotEmpty
                  ? null
                  : (value) {
                      _confirmed = value == true;
                      refresh();
                    },
            ),
          ],
        );
      },
    );
  }

  String _sourceRemovalMessage() {
    if (_working) return 'Analyse du choix en cours ; rien n’est supprimé.';
    if (_preparation?.impact['sourceRemoved'] == true) {
      return _preparation!.impact['logicalFileRemoved'] == true
          ? 'La source logique et son fichier seront retirés. Le blob est conservé.'
          : 'La source logique sera retirée. Son fichier adressé par contenu est conservé.';
    }
    if (_removeSource) {
      return 'Aucun retrait préparé. Décochez pour conserver la source ou réanalysez.';
    }
    return _sourceRemovalReason ??
        (_sourceRemovalSupported
            ? 'La source reste conservée ; cochez pour analyser son retrait.'
            : 'Le fichier source restera intact.');
  }
}
