import '../../../features/scenes/application/scene_condition_draft.dart';
import 'periodic_reward_picker.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'scene_integer_condition_form.dart';

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';

class SceneConditionForm extends StatefulWidget {
  const SceneConditionForm({
    super.key,
    required this.project,
    required this.current,
    required this.onApply,
    this.loadMoves,
    this.loadItems,
    this.loadMap,
  });
  final ProjectManifest project;
  final SceneConditionPayload current;
  final ValueChanged<SceneConditionSource> onApply;
  final Future<Map<String, String>> Function()? loadMoves;
  final Future<Map<String, String>> Function()? loadItems;
  final Future<MapData> Function(String)? loadMap;
  @override
  State<SceneConditionForm> createState() => _SceneConditionFormState();
}

class _SceneConditionFormState extends State<SceneConditionForm> {
  late final SceneConditionDraft draft;
  @override
  void initState() {
    super.initState();
    draft = SceneConditionDraft(
      project: widget.project,
      current: widget.current,
      loadMoves: widget.loadMoves,
      loadItems: widget.loadItems,
      loadMap: widget.loadMap,
      changed: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void didUpdateWidget(SceneConditionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    draft.configure(
      project: widget.project,
      current: widget.current,
      loadMoves: widget.loadMoves,
      loadItems: widget.loadItems,
      loadMap: widget.loadMap,
    );
  }

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (draft.family == 'periodicRewardAvailable') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioSelect(
            label: 'Source de la condition',
            value: draft.family,
            options: draft.availableFamilies,
            onChanged: draft.selectFamily,
          ),
          PeriodicRewardPicker(
            initial: widget.current.conditionSource?.rewardReference,
            expectedValue:
                widget.current.conditionSource?.operator !=
                SceneConditionOperator.isFalse,
            onApply: (reference, expected) => widget.onApply(
              SceneConditionSource.periodicRewardAvailable(
                reference: reference,
                expectedValue: expected,
              ),
            ),
          ),
        ],
      );
    }
    if (draft.family == 'integerComparison') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioSelect(
            label: 'Source de la condition',
            value: draft.family,
            options: draft.availableFamilies,
            onChanged: draft.selectFamily,
          ),
          const SizedBox(height: 12),
          SceneIntegerConditionForm(
            project: widget.project,
            current:
                widget.current.conditionSource?.sourceKind ==
                    SceneConditionSourceKind.integerComparison
                ? widget.current.conditionSource
                : null,
            onApply: widget.onApply,
            loadItems: widget.loadItems,
          ),
        ],
      );
    }
    final fact = draft.family == 'fact' ? draft.selectedFact : null;
    final references = draft.references;
    final source = draft.prepared;
    final current = widget.current.conditionSource;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (draft.unsupported) ...[
          StudioNotice(
            'Condition avancée conservée : ${current?.label ?? widget.current.conditionLabel ?? current?.sourceId ?? 'référence existante'}. Pour la remplacer, choisissez une source puis appliquez explicitement.',
          ),
          const SizedBox(height: 12),
        ],
        StudioSelect(
          label: 'Source de la condition',
          value: draft.family,
          options: draft.availableFamilies,
          onChanged: draft.selectFamily,
        ),
        const SizedBox(height: 12),
        if (draft.isMapSource) ...[
          StudioSelect(
            key: const ValueKey('scene-condition-map'),
            label: 'Carte',
            value: draft.selectedMapId,
            options: draft.mapOptions,
            onChanged: draft.selectMap,
          ),
          if (draft.mapLoading)
            const StudioNotice('Chargement des entités de la carte…'),
          if (draft.mapError != null)
            StudioNotice(draft.mapError!, isError: true),
          if (draft.selectedMapId != null &&
              !draft.mapOptions.containsKey(draft.selectedMapId))
            const StudioNotice(
              'La carte référencée est absente ou ambiguë. La condition actuelle est conservée.',
              isError: true,
            ),
          const SizedBox(height: 12),
        ],
        if (draft.family == 'inventoryItem') ...[
          if (draft.itemsLoading)
            const StudioNotice('Chargement des objets du projet…'),
          if (draft.itemsError != null)
            StudioNotice(draft.itemsError!, isError: true),
        ],
        if (draft.family != 'pokedexCaughtCount' &&
            draft.family != 'partyState')
          StudioSelect(
            label: 'Référence',
            value: draft.referenceId,
            options: references,
            onChanged: draft.selectReference,
          ),
        if (draft.family != 'pokedexCaughtCount' &&
            draft.family != 'partyState' &&
            !draft.referencesLoading &&
            references.isEmpty) ...[
          const SizedBox(height: 8),
          const StudioNotice(
            'Aucune référence disponible dans ce projet. La condition actuelle reste conservée.',
          ),
        ],
        if (draft.referenceId != null &&
            !draft.referencesLoading &&
            draft.family != 'partyState' &&
            draft.family != 'pokedexCaughtCount' &&
            !references.containsKey(draft.referenceId)) ...[
          const SizedBox(height: 8),
          const StudioNotice(
            'La référence actuelle est absente ou ambiguë. Elle reste conservée tant qu’aucune nouvelle condition n’est appliquée.',
            isError: true,
          ),
        ],
        if (draft.family == 'inventoryItem' && !draft.unsupported) ...[
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('scene-inventory-minimum'),
            label: 'Quantité minimale',
            value: draft.minimumQuantity,
            onChanged: (value) => setState(() => draft.minimumQuantity = value),
          ),
          if (int.tryParse(draft.minimumQuantity) case final minimum?
              when minimum < 1 || '$minimum' != draft.minimumQuantity)
            const StudioNotice(
              'Choisissez un nombre entier positif.',
              isError: true,
            ),
          if (int.tryParse(draft.minimumQuantity) == null)
            const StudioNotice(
              'Choisissez un nombre entier positif.',
              isError: true,
            ),
        ],
        if (draft.family == 'mapEventInstanceBoolean' &&
            !draft.unsupported) ...[
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('scene-instance-boolean-key'),
            label: 'Nom de l’état local',
            value: draft.instanceKey,
            onChanged: (value) => setState(() => draft.instanceKey = value),
          ),
          const SizedBox(height: 8),
          const StudioNotice(
            'Cet état appartient à l’entité choisie dans l’instance courante de la carte. Son nom doit correspondre à celui utilisé par les actions qui le modifient.',
          ),
          if (draft.instanceKey.isEmpty ||
              draft.instanceKey.trim() != draft.instanceKey)
            const StudioNotice(
              'Choisissez un nom non vide, sans espace au début ni à la fin.',
              isError: true,
            ),
        ],
        const SizedBox(height: 12),
        if (draft.family == 'partyState' && !draft.unsupported) ...[
          StudioSelect(
            key: const ValueKey('scene-party-kind'),
            label: 'Condition d’équipe',
            value: draft.partyKind.name,
            options: {
              for (final kind in ScenePartyConditionKind.values)
                kind.name: kind.label,
            },
            onChanged: draft.selectPartyKind,
          ),
          const SizedBox(height: 12),
          if (draft.partyKind == ScenePartyConditionKind.knowsMove ||
              draft.partyKind == ScenePartyConditionKind.hasUsableMove) ...[
            StudioSelect(
              key: const ValueKey('scene-party-move'),
              label: 'Capacité de l’équipe',
              value: draft.referenceId,
              options: draft.moveOptions,
              onChanged: (value) => setState(() => draft.referenceId = value),
            ),
            if (draft.movesLoading)
              const StudioNotice('Chargement des capacités du projet…'),
            if (draft.movesError != null)
              StudioNotice(draft.movesError!, isError: true),
            if (!draft.movesLoading &&
                draft.movesError == null &&
                draft.moveOptions.isEmpty)
              const StudioNotice(
                'Aucune capacité disponible dans le catalogue du projet.',
              ),
          ],
          if (draft.partyKind == ScenePartyConditionKind.canUseFieldAbility)
            StudioSelect(
              key: const ValueKey('scene-party-ability'),
              label: 'Capacité de terrain',
              value: draft.ability?.moveId,
              options: {
                for (final ability in FieldAbility.values)
                  ability.moveId: sceneFieldAbilityLabel(ability),
              },
              onChanged: (value) => setState(
                () => draft.ability = FieldAbility.values.singleWhere(
                  (ability) => ability.moveId == value,
                ),
              ),
            ),
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('scene-party-expected'),
            label: 'Condition remplie',
            value: '${draft.expected}',
            options: const {'true': 'Oui', 'false': 'Non'},
            onChanged: (value) =>
                setState(() => draft.expected = value == 'true'),
          ),
          const SizedBox(height: 8),
          StudioNotice(switch (draft.partyKind) {
            ScenePartyConditionKind.canReceivePokemon => 'Vérifie une place dans l’équipe, puis dans le PC. Aucun Pokémon n’est reçu par cette condition.',
            ScenePartyConditionKind.knowsMove =>
              'Un membre connaît cette capacité, même K.O. ou sans PP.',
            ScenePartyConditionKind.hasUsableMove => 'Un membre non K.O. connaît cette capacité et possède au moins un PP.',
            ScenePartyConditionKind.canUseFieldAbility => 'La capacité de terrain doit être prise en charge et débloquée ; un membre non K.O. doit la connaître. Aucun PP requis, y compris à PP0 ; aucun PP n’est consommé.',
          }),
          if (draft.partyKind == ScenePartyConditionKind.canUseFieldAbility &&
              widget.project.settings.dimension == ProjectDimension.threeD)
            const StudioNotice(
              'Les capacités de terrain sont actuellement disponibles dans le Player 2D ; elles ne sont pas disponibles dans les projets 3D. La condition est donc fausse en 3D, et sa négation reste utilisable.',
            ),
        ] else if (draft.family == 'pokedexCaughtCount' &&
            !draft.unsupported) ...[
          StudioDraftField(
            key: const ValueKey('pokedex-first-national'),
            label: 'Premier numéro du Pokédex national',
            value: draft.firstNational,
            onChanged: (value) => setState(() => draft.firstNational = value),
          ),
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('pokedex-last-national'),
            label: 'Dernier numéro du Pokédex national',
            value: draft.lastNational,
            onChanged: (value) => setState(() => draft.lastNational = value),
          ),
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('pokedex-minimum-count'),
            label: 'Nombre d’espèces capturées',
            value: draft.minimumCount,
            onChanged: (value) => setState(() => draft.minimumCount = value),
          ),
          const SizedBox(height: 12),
          StudioSelect(
            label: 'Comparaison',
            value: '${draft.expected}',
            options: const {
              'true': 'Au moins ce nombre',
              'false': 'Moins que ce nombre',
            },
            onChanged: (value) =>
                setState(() => draft.expected = value == 'true'),
          ),
          if (source == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: StudioNotice(
                'Choisissez des numéros ordonnés et un nombre entier positif, au plus 65 535.',
                isError: true,
              ),
            ),
        ] else if (fact != null) ...[
          StudioSelect(
            label: 'Comparaison',
            value: draft.comparisonOperator.name,
            options: {
              for (final value in fact.valueKind.compatibleOperators)
                value.name: SceneConditionDraft.operators[value.name]!,
            },
            onChanged: (value) => setState(
              () => draft.comparisonOperator = NarrativeFactOperator.values
                  .byName(value),
            ),
          ),
          const SizedBox(height: 12),
          if (fact.valueKind == NarrativeValueKind.boolean)
            StudioSelect(
              label: 'Valeur attendue',
              value: '${draft.expected}',
              options: const {'true': 'Oui', 'false': 'Non'},
              onChanged: (value) =>
                  setState(() => draft.expected = value == 'true'),
            )
          else
            StudioDraftField(
              label: fact.valueKind == NarrativeValueKind.integer
                  ? 'Nombre entier attendu'
                  : 'Texte attendu',
              value: draft.text,
              onChanged: (value) => setState(() => draft.text = value),
            ),
          if (source == null && !draft.unsupported)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: StudioNotice(
                'Saisissez une valeur compatible avec cet état.',
                isError: true,
              ),
            ),
        ] else if (draft.referenceId != null &&
            references.containsKey(draft.referenceId))
          StudioSelect(
            label: draft.family == 'storyStepCompletion'
                ? 'État de l’étape'
                : draft.family == 'playerFacing'
                ? 'Regarde dans cette direction'
                : draft.family == 'trainerDefeated'
                ? 'Dresseur déjà vaincu'
                : draft.family == 'badge'
                ? 'Badge obtenu'
                : draft.family == 'inventoryItem'
                ? 'Présent en quantité suffisante'
                : draft.family == 'playerAtEntityAnchor'
                ? 'Joueur à cette position'
                : draft.family == 'mapEventInstanceBoolean' ||
                      draft.family == 'factLikeStoryFlag'
                ? 'État activé'
                : 'Déjà jouée',
            value: '${draft.expected}',
            options: draft.family == 'storyStepCompletion'
                ? const {'true': 'Terminée', 'false': 'Non terminée'}
                : const {'true': 'Oui', 'false': 'Non'},
            onChanged: (value) =>
                setState(() => draft.expected = value == 'true'),
          ),
        const SizedBox(height: 12),
        StudioButton(
          label: 'Appliquer la condition',
          onPressed: source == null
              ? null
              : () {
                  final latest = draft.prepared;
                  if (latest != null) widget.onApply(latest);
                },
        ),
        const SizedBox(height: 8),
        const Text('Oui : condition remplie\nNon : condition non remplie'),
      ],
    );
  }
}
