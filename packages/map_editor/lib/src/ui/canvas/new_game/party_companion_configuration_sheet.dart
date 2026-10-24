import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../app/providers/core/repository_providers.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../../features/narrative/state/scene_consequence_catalog_providers.dart';
import '../../design_system/design_system.dart';

class PartyCompanionConfigurationSheet extends ConsumerWidget {
  const PartyCompanionConfigurationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final project = state.project;
    final path = state.projectRootPath;
    if (project == null ||
        path == null ||
        project.settings.dimension != ProjectDimension.threeD ||
        !project.pokemon.enabled) {
      return const PokeMapEmptyState(
        title: 'Compagnon indisponible',
        description:
            'Activez les Pokémon dans un projet 3D pour associer les apparences des compagnons.',
        icon: Icon(Icons.pets),
      );
    }
    return ref
        .watch(sceneConsequenceCatalogsProvider(path))
        .when(
          loading: () => const PokeMapEmptyState(
            title: 'Chargement des espèces…',
            description: 'Lecture du catalogue du projet.',
            icon: Icon(Icons.hourglass_top),
          ),
          error: (error, _) => PokeMapEmptyState(
            title: 'Catalogue indisponible',
            description: error.toString(),
            icon: const Icon(Icons.error_outline),
          ),
          data: (catalogs) => PartyCompanionConfigurationForm(
            project: project,
            species: catalogs.species.options,
            onSave: (config) async {
              final queries = ref.read(authoringQueryAdapterProvider);
              await queries.invalidate(path);
              final before = await queries.open(path);
              if (before.manifest != ref.read(editorNotifierProvider).project) {
                throw StateError(
                  'Le projet a changé. Rechargez sa configuration avant de continuer.',
                );
              }
              final operation =
                  'editor_companion_${DateTime.now().microsecondsSinceEpoch}';
              final mutations = ref.read(authoringMutationAdapterProvider);
              final plan = await mutations.plan(
                path,
                actionId: 'party_companion.configure',
                parameters: config.toJson(),
                idempotencyKey: operation,
                requestId: operation,
                expectedRevision: before.snapshotRevision,
              );
              await mutations.apply(plan, operationId: operation);
              await queries.invalidate(path);
              ref
                  .read(editorNotifierProvider.notifier)
                  .acceptCanonicalProjectManifest(
                    (await queries.open(path)).manifest,
                    statusMessage: 'Compagnon d’équipe sauvegardé.',
                  );
              return true;
            },
          ),
        );
  }
}

class PartyCompanionConfigurationForm extends StatefulWidget {
  const PartyCompanionConfigurationForm({
    super.key,
    required this.project,
    required this.species,
    required this.onSave,
  });
  final ProjectManifest project;
  final List<SceneConsequenceCatalogOption> species;
  final Future<bool> Function(ProjectPartyCompanionConfig) onSave;

  @override
  State<PartyCompanionConfigurationForm> createState() =>
      _PartyCompanionConfigurationFormState();
}

class _PartyCompanionConfigurationFormState
    extends State<PartyCompanionConfigurationForm> {
  late bool enabled = widget.project.partyCompanion.enabled;
  late final mappings = {
    for (final value in widget.project.partyCompanion.mappings)
      (value.speciesId, value.formId): value.characterId,
  };
  bool saving = false;
  String? message;

  Future<void> save() async {
    setState(() {
      saving = true;
      message = null;
    });
    try {
      final accepted = await widget.onSave(
        ProjectPartyCompanionConfig(
          enabled: enabled,
          mappings: [
            for (final value in mappings.entries)
              PartyCompanionVisual(
                speciesId: value.key.$1,
                formId: value.key.$2,
                characterId: value.value,
              ),
          ],
        ),
      );
      if (mounted) {
        setState(
          () => message = accepted
              ? 'Compagnon sauvegardé.'
              : 'La configuration n’a pas été enregistrée.',
        );
      }
    } on Object catch (error) {
      if (mounted) setState(() => message = error.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actors = widget.project.characters
        .where(
          (actor) => EntityFacing.values.every(
            (facing) => actor.animations.any(
              (clip) =>
                  clip.state == CharacterAnimationState.walk &&
                  clip.direction == facing &&
                  clip.frames.isNotEmpty,
            ),
          ),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapToggleTile(
          key: const Key('party-companion-enabled'),
          label: 'Compagnon d’équipe',
          value: enabled,
          description:
              'Le premier Pokémon apte suit le joueur. Son apparence change avec l’équipe.',
          onChanged: (value) => setState(() {
            enabled = value;
            message = null;
          }),
        ),
        const SizedBox(height: 12),
        for (final species in widget.species)
          for (final form in species.catalogGiftFormIds) ...[
            PokeMapDropdownField<String>(
              key: Key('party-companion-${species.id}-$form'),
              label: species.label,
              value: mappings[(species.id, form)] ?? '',
              enabled: !saving,
              items: [
                const PokeMapDropdownItem(
                  value: '',
                  label: 'Aucun compagnon associé',
                ),
                for (final actor in actors)
                  PokeMapDropdownItem(value: actor.id, label: actor.name),
              ],
              onChanged: (value) => setState(() {
                if (value.isEmpty) {
                  mappings.remove((species.id, form));
                } else {
                  mappings[(species.id, form)] = value;
                }
                message = null;
              }),
            ),
            const SizedBox(height: 10),
          ],
        if (widget.species.isEmpty)
          const PokeMapEmptyState(
            title: 'Aucune espèce disponible',
            description: 'Ajoutez des espèces au catalogue du projet.',
            icon: Icon(Icons.pets),
          ),
        if (message != null) PokeMapBadge(label: message!),
        const SizedBox(height: 12),
        PokeMapButton(
          key: const Key('party-companion-save'),
          onPressed: saving || enabled && mappings.isEmpty ? null : save,
          child: Text(saving ? 'Enregistrement…' : 'Enregistrer le compagnon'),
        ),
      ],
    );
  }
}
