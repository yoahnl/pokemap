import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/layout/studio_section.dart';
import 'pokemon_species_thumbnail.dart';
import 'pokemon_ui_parts.dart';

class PokemonSpeciesFormLinks extends StatefulWidget {
  const PokemonSpeciesFormLinks({
    super.key,
    required this.controller,
    required this.forms,
  });

  final PokemonWorkspaceController controller;
  final Map<String, dynamic> forms;

  @override
  State<PokemonSpeciesFormLinks> createState() =>
      _PokemonSpeciesFormLinksState();
}

class _PokemonSpeciesFormLinksState extends State<PokemonSpeciesFormLinks> {
  static const _candidateLimit = 12;
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forms = widget.forms;
    final otherForms = List<String>.from(forms['otherForms'] as List? ?? []);
    final siblings = _siblings();
    final needle = _query.trim().toLowerCase();
    final candidates = [
      for (final entry in siblings)
        if (!otherForms.contains(entry.formId) && _matches(entry, needle))
          entry,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PokemonSectionHeading(
          title: 'Autres formes associées',
          description: 'Ces liens ne créent pas de nouvelle espèce.',
        ),
        if (otherForms.isEmpty)
          const Text('Aucune autre forme associée.')
        else
          for (var index = 0; index < otherForms.length; index++)
            _linkedRow(
              context,
              index,
              otherForms[index],
              siblings
                  .where((entry) => entry.formId == otherForms[index])
                  .toList(),
            ),
        const SizedBox(height: 12),
        if (siblings.isEmpty)
          Text(
            'Aucune autre forme n’est déclarée pour cette espèce de base dans le projet.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else ...[
          StudioSearchField(
            key: const ValueKey('species-form-link-search'),
            controller: _search,
            label: 'Ajouter une forme',
            hint: 'Nom ou forme de la même espèce de base',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 6),
          if (candidates.isEmpty)
            Text(
              needle.isEmpty
                  ? 'Toutes les formes de cette espèce de base sont déjà associées.'
                  : 'Aucune forme ne correspond à « ${_query.trim()} ».',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else ...[
            for (final entry in candidates.take(_candidateLimit))
              StudioChoice(
                key: ValueKey('species-form-candidate:${entry.id}'),
                label: entry.name,
                subtitle: 'Forme ${entry.formId} · Ajouter ce lien',
                leading: _thumbnail(entry),
                trailing: const Icon(Icons.add, size: 18),
                onTap: () => _add(entry.formId),
              ),
            if (candidates.length > _candidateLimit)
              Text(
                'Affinez la recherche : ${candidates.length} formes correspondent.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ],
        const SizedBox(height: 8),
        StudioSection(
          key: const PageStorageKey<String>('species-form-links-advanced'),
          title: 'Identifiants avancés',
          collapsible: true,
          initiallyExpanded: false,
          children: [
            SizedBox(
              key: const PageStorageKey<String>(
                'species-form-links-advanced-fields',
              ),
              width: double.infinity,
              child: StudioDraftField(
                key: const ValueKey('species-forms.otherForms'),
                label: 'Identifiants liés · séparés par une virgule',
                value: otherForms.join(', '),
                onChanged: (value) => _write(
                  value
                      .split(',')
                      .map((item) => item.trim())
                      .where((item) => item.isNotEmpty)
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _linkedRow(
    BuildContext context,
    int index,
    String formId,
    List<PokemonSpeciesSummary> matches,
  ) {
    final resolved = matches.length == 1 ? matches.single : null;
    final title = switch (matches.length) {
      1 => resolved!.name,
      0 => 'Forme introuvable · $formId',
      _ => 'Forme ambiguë · $formId',
    };
    final detail = switch (matches.length) {
      1 => 'Forme $formId',
      0 => 'Référence conservée telle quelle.',
      _ => 'Plusieurs fiches déclarent cette forme. Référence conservée.',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: PokemonSurface(
        emphasized: true,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            if (resolved != null)
              _thumbnail(resolved)
            else
              const Icon(Icons.link_off, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            PokemonPill(
              label: switch (matches.length) {
                1 => 'Référencée',
                0 => 'Non résolue',
                _ => 'Ambiguë',
              },
              success: resolved != null,
              warning: resolved == null,
            ),
            IconButton(
              tooltip: 'Retirer le lien vers ${resolved?.name ?? formId}',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => _remove(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(PokemonSpeciesSummary entry) => PokemonSpeciesThumbnail(
    key: ValueKey('species-form-link-preview:${entry.id}'),
    entry: entry,
    port: widget.controller.port,
    mediaRevision: widget.controller.mediaRevision(entry.mediaRelativePath),
    size: 32,
  );

  List<PokemonSpeciesSummary> _siblings() {
    final forms = widget.forms;
    final ownerId = widget.controller.selectedDraft?.id;
    final currentFormId = '${forms['formId'] ?? ''}'.trim();
    final group = forms['isBaseForm'] == true
        ? ownerId
        : '${forms['baseFormId'] ?? ''}'.trim();
    if (group == null || group.isEmpty) return const [];
    return [
      for (final entry
          in widget.controller.index?.entries ??
              const <PokemonSpeciesSummary>[])
        if (entry.id != ownerId &&
            entry.formId.isNotEmpty &&
            entry.formId != currentFormId &&
            (entry.isBaseForm ? entry.id : entry.baseFormId.trim()) == group)
          entry,
    ];
  }

  bool _matches(PokemonSpeciesSummary entry, String needle) =>
      needle.isEmpty ||
      entry.name.toLowerCase().contains(needle) ||
      entry.id.toLowerCase().contains(needle) ||
      entry.formId.toLowerCase().contains(needle);

  void _add(String formId) {
    final current = List<String>.from(
      widget.forms['otherForms'] as List? ?? [],
    );
    if (current.contains(formId)) return;
    _write([...current, formId]);
    _search.clear();
    setState(() => _query = '');
  }

  void _remove(int index) {
    final current = List<String>.from(
      widget.forms['otherForms'] as List? ?? [],
    );
    if (index >= current.length) return;
    current.removeAt(index);
    _write(current);
  }

  void _write(List<String> otherForms) =>
      widget.controller.edit(PokemonDocumentFamily.species, (json) {
        final current = Map<String, dynamic>.from(json['forms'] as Map? ?? {});
        current['otherForms'] = otherForms;
        json['forms'] = current;
      });
}
