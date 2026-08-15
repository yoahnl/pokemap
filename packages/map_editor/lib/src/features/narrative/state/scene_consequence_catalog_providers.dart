import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../app/providers/core/repository_providers.dart';
import '../../../app/providers/pokedex/pokedex_providers.dart';
import '../../gameplay/items/item_studio_gateway.dart';

enum SceneConsequenceCatalogStatus {
  ready,
  unavailable,
  failed,
}

/// Editor-only option projected from a project-owned catalog.
///
/// [id] is kept as the persisted value, while normal authoring surfaces only
/// render [label] and user-facing [details]. This prevents a raw-ID fallback
/// from becoming the default workflow when a catalog entry is missing.
final class SceneConsequenceCatalogOption {
  const SceneConsequenceCatalogOption({
    required this.id,
    required this.label,
    this.details = const <String>[],
    this.formIds = const <String>[],
    this.itemDefinition,
  });

  final String id;
  final String label;
  final List<String> details;
  final List<String> formIds;
  final ProjectItemDefinition? itemDefinition;
}

final class SceneConsequenceCatalogSection {
  const SceneConsequenceCatalogSection({
    required this.status,
    required this.options,
    required this.message,
  });

  const SceneConsequenceCatalogSection.loading()
      : status = SceneConsequenceCatalogStatus.unavailable,
        options = const <SceneConsequenceCatalogOption>[],
        message = 'Chargement du catalogue local…';

  final SceneConsequenceCatalogStatus status;
  final List<SceneConsequenceCatalogOption> options;
  final String message;

  /// A catalog with no selectable entries must not enable its picker.
  bool get isReady =>
      status == SceneConsequenceCatalogStatus.ready && options.isNotEmpty;
}

final class SceneConsequenceCatalogs {
  const SceneConsequenceCatalogs({
    required this.items,
    required this.species,
    this.storySteps = const SceneConsequenceCatalogSection(
      status: SceneConsequenceCatalogStatus.unavailable,
      options: <SceneConsequenceCatalogOption>[],
      message: 'Créez une étape dans une Storyline.',
    ),
    this.configuredStarters = const SceneConsequenceCatalogSection(
      status: SceneConsequenceCatalogStatus.unavailable,
      options: <SceneConsequenceCatalogOption>[],
      message: 'Configurez des starters dans Nouveau Jeu.',
    ),
  });

  const SceneConsequenceCatalogs.loading()
      : items = const SceneConsequenceCatalogSection.loading(),
        species = const SceneConsequenceCatalogSection.loading(),
        storySteps = const SceneConsequenceCatalogSection.loading(),
        configuredStarters = const SceneConsequenceCatalogSection.loading();

  const SceneConsequenceCatalogs.unavailable()
      : items = const SceneConsequenceCatalogSection(
          status: SceneConsequenceCatalogStatus.unavailable,
          options: <SceneConsequenceCatalogOption>[],
          message: 'Ouvrez un projet contenant un catalogue local d’objets.',
        ),
        species = const SceneConsequenceCatalogSection(
          status: SceneConsequenceCatalogStatus.unavailable,
          options: <SceneConsequenceCatalogOption>[],
          message: 'Ouvrez un projet contenant des espèces locales.',
        ),
        storySteps = const SceneConsequenceCatalogSection(
          status: SceneConsequenceCatalogStatus.unavailable,
          options: <SceneConsequenceCatalogOption>[],
          message: 'Créez une étape dans une Storyline.',
        ),
        configuredStarters = const SceneConsequenceCatalogSection(
          status: SceneConsequenceCatalogStatus.unavailable,
          options: <SceneConsequenceCatalogOption>[],
          message: 'Configurez des starters dans Nouveau Jeu.',
        );

  final SceneConsequenceCatalogSection items;
  final SceneConsequenceCatalogSection species;
  final SceneConsequenceCatalogSection storySteps;
  final SceneConsequenceCatalogSection configuredStarters;

  SceneConsequenceCatalogs withConfiguredStarters(
    List<ProjectStarterOption> starters,
  ) {
    final options = <SceneConsequenceCatalogOption>[
      for (final starter in starters)
        if (starter.id.trim().isNotEmpty && starter.label.trim().isNotEmpty)
          SceneConsequenceCatalogOption(
            id: starter.id.trim(),
            label: starter.label.trim(),
            details: <String>[
              'Niveau ${starter.pokemon.level} · ${starter.pokemon.currentHp} PV',
              '${starter.pokemon.knownMoveIds.length} capacité(s) configurée(s)',
            ],
          ),
    ];
    return SceneConsequenceCatalogs(
      items: items,
      species: species,
      storySteps: storySteps,
      configuredStarters: options.isEmpty
          ? const SceneConsequenceCatalogSection(
              status: SceneConsequenceCatalogStatus.unavailable,
              options: <SceneConsequenceCatalogOption>[],
              message: 'Configurez des starters dans Nouveau Jeu.',
            )
          : SceneConsequenceCatalogSection(
              status: SceneConsequenceCatalogStatus.ready,
              options:
                  List<SceneConsequenceCatalogOption>.unmodifiable(options),
              message: '${options.length} starter(s) configuré(s).',
            ),
    );
  }

  SceneConsequenceCatalogs withStorySteps(
    List<NarrativeStoryStepPickerOption> steps,
  ) {
    final options = <SceneConsequenceCatalogOption>[
      for (final step in steps)
        SceneConsequenceCatalogOption(
          id: step.stepId,
          label: step.humanLabel,
          details: <String>[step.debugTechnicalLabel],
        ),
    ];
    return SceneConsequenceCatalogs(
      items: items,
      species: species,
      storySteps: options.isEmpty
          ? const SceneConsequenceCatalogSection(
              status: SceneConsequenceCatalogStatus.unavailable,
              options: <SceneConsequenceCatalogOption>[],
              message: 'Créez une étape dans une Storyline.',
            )
          : SceneConsequenceCatalogSection(
              status: SceneConsequenceCatalogStatus.ready,
              options:
                  List<SceneConsequenceCatalogOption>.unmodifiable(options),
              message: '${options.length} étape(s) narrative(s) disponible(s).',
            ),
      configuredStarters: configuredStarters,
    );
  }

  SceneConsequenceCatalogs withProjectStorySteps(ProjectManifest project) {
    final optionsById = <String, SceneConsequenceCatalogOption>{};
    for (final storyline in project.storylines) {
      for (final chapter in storyline.chapters) {
        for (final step in chapter.steps) {
          optionsById.putIfAbsent(
            step.id,
            () => SceneConsequenceCatalogOption(
              id: step.id,
              label: step.title,
              details: <String>[
                '${storyline.title} · ${chapter.title}',
                if (step.description?.trim().isNotEmpty ?? false)
                  step.description!.trim(),
              ],
            ),
          );
        }
      }
    }
    for (final step in buildNarrativeStoryStepPickerOptions(project)) {
      optionsById.putIfAbsent(
        step.stepId,
        () => SceneConsequenceCatalogOption(
          id: step.stepId,
          label: step.humanLabel,
          details: <String>[step.debugTechnicalLabel],
        ),
      );
    }
    final options = optionsById.values.toList(growable: false)
      ..sort(_compareOptions);
    return SceneConsequenceCatalogs(
      items: items,
      species: species,
      storySteps: options.isEmpty
          ? const SceneConsequenceCatalogSection(
              status: SceneConsequenceCatalogStatus.unavailable,
              options: <SceneConsequenceCatalogOption>[],
              message: 'Créez une étape dans une Storyline.',
            )
          : SceneConsequenceCatalogSection(
              status: SceneConsequenceCatalogStatus.ready,
              options:
                  List<SceneConsequenceCatalogOption>.unmodifiable(options),
              message: '${options.length} étape(s) narrative(s) disponible(s).',
            ),
      configuredStarters: configuredStarters,
    );
  }
}

typedef SceneItemDefinitionLoader = Future<List<ProjectItemDefinition>>
    Function(String projectRootPath);

final sceneItemDefinitionLoaderProvider = Provider<SceneItemDefinitionLoader>(
  (ref) {
    final gateway = CanonicalItemStudioGateway(
      queries: ref.watch(authoringQueryAdapterProvider),
      mutations: ref.watch(authoringMutationAdapterProvider),
    );
    return (projectRootPath) async {
      final snapshot = await gateway.load(projectRootPath);
      return <ProjectItemDefinition>[
        for (final definition in snapshot.definitions)
          if (snapshot.readinessByItemId[definition.id]?.ready != false)
            definition,
      ];
    };
  },
);

final sceneConsequenceCatalogsProvider = FutureProvider.autoDispose
    .family<SceneConsequenceCatalogs, String?>((ref, projectRootPath) async {
  final normalizedRoot = projectRootPath?.trim();
  if (normalizedRoot == null || normalizedRoot.isEmpty) {
    return const SceneConsequenceCatalogs.unavailable();
  }

  final itemsFuture = _loadItems(ref, normalizedRoot);
  final speciesFuture = _loadSpecies(ref, normalizedRoot);
  return SceneConsequenceCatalogs(
    items: await itemsFuture,
    species: await speciesFuture,
  );
});

Future<SceneConsequenceCatalogSection> _loadItems(
  Ref ref,
  String projectRootPath,
) async {
  try {
    final definitions = await ref.watch(sceneItemDefinitionLoaderProvider)(
      projectRootPath,
    );
    final options = <SceneConsequenceCatalogOption>[
      for (final definition in definitions)
        SceneConsequenceCatalogOption(
          id: definition.id,
          label: definition.displayName,
          details: <String>[
            if (definition.description != null) definition.description!,
          ],
          itemDefinition: definition,
        ),
    ]..sort(_compareOptions);
    if (options.isEmpty) {
      return const SceneConsequenceCatalogSection(
        status: SceneConsequenceCatalogStatus.unavailable,
        options: <SceneConsequenceCatalogOption>[],
        message: 'Le catalogue canonique ne contient aucun objet prêt.',
      );
    }
    return SceneConsequenceCatalogSection(
      status: SceneConsequenceCatalogStatus.ready,
      options: List<SceneConsequenceCatalogOption>.unmodifiable(options),
      message: '${options.length} objets locaux disponibles.',
    );
  } catch (_) {
    return const SceneConsequenceCatalogSection(
      status: SceneConsequenceCatalogStatus.failed,
      options: <SceneConsequenceCatalogOption>[],
      message: 'Impossible de charger le catalogue local des objets.',
    );
  }
}

Future<SceneConsequenceCatalogSection> _loadSpecies(
  Ref ref,
  String projectRootPath,
) async {
  try {
    final workspace =
        ref.watch(projectWorkspaceFactoryProvider).create(projectRootPath);
    final entries = await ref.watch(pokedexEntryLoaderProvider)(workspace);
    final options = <SceneConsequenceCatalogOption>[
      for (final entry in entries)
        // A disabled species exists in the database but is deliberately not a
        // valid no-code choice for the current project.
        if (entry.isEnabledInProject &&
            entry.id.trim().isNotEmpty &&
            entry.primaryName.trim().isNotEmpty)
          SceneConsequenceCatalogOption(
            id: entry.id.trim(),
            label: entry.primaryName.trim(),
            formIds: List<String>.from(entry.formIds),
            details: <String>[
              'Pokédex n°${entry.nationalDex}',
            ],
          ),
    ]..sort(_compareOptions);
    if (options.isEmpty) {
      return const SceneConsequenceCatalogSection(
        status: SceneConsequenceCatalogStatus.unavailable,
        options: <SceneConsequenceCatalogOption>[],
        message: 'Aucune espèce locale activée n’est sélectionnable.',
      );
    }
    return SceneConsequenceCatalogSection(
      status: SceneConsequenceCatalogStatus.ready,
      options: List<SceneConsequenceCatalogOption>.unmodifiable(options),
      message: '${options.length} espèces locales disponibles.',
    );
  } catch (_) {
    return const SceneConsequenceCatalogSection(
      status: SceneConsequenceCatalogStatus.failed,
      options: <SceneConsequenceCatalogOption>[],
      message: 'Impossible de charger les espèces locales du projet.',
    );
  }
}

int _compareOptions(
  SceneConsequenceCatalogOption left,
  SceneConsequenceCatalogOption right,
) {
  return left.label.toLowerCase().compareTo(right.label.toLowerCase());
}

String scenePokemonFormLabel(String formId) {
  final normalized = formId.trim();
  if (normalized == 'base') return 'Forme de base';
  if (normalized.isEmpty) return 'Forme indisponible';
  return normalized
      .split(RegExp(r'[-_]'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
