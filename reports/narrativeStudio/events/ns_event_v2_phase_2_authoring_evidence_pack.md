# Event Builder V2 — Phase 2 Authoring Evidence Pack

Date: 2026-07-16
Lot exact: Phase 2 — Authoring V2, sous-lots H3, H4 et H5
Périmètre: packages/map_editor
Verdict: IMPLÉMENTÉ, GATE TECHNIQUE CIBLÉ VERT, CLÔTURE FORMELLE NON PRONONCÉE

## 1. Résumé exécutif

La Phase 2 livre le flux d’authoring V2 source-first sur la route produit:

- création d’un brouillon avec une source existante ou “Décider plus tard”;
- persistance journalée par composition des opérations core existantes;
- fermeture, rechargement et réouverture sans perte;
- édition des champs Event-owned: source, conditions, Scene cible, reusePolicy, priorité, ordre, publication et activation;
- ajout, inversion de valeur, réordonnancement et suppression des conditions;
- projections Scene-owned conservées en lecture seule;
- suppression des contrôles morts: une action n’est visible que si son callback réel existe;
- états loading, saving, error, missing source, conflict, legacy et recovery, plus les flows vide déjà couverts par le gate;
- clavier Enter, Espace, Escape, Tab, Shift+Tab, retour du focus, largeur 1280 et text scale 125 %;
- aucune écriture de géométrie ou de map depuis l’Event Builder.

Le gate H final passe avec 222 tests. Les 14 fichiers du lot passent une analyse ciblée sans diagnostic et le build macOS debug réussit. La suite et l’analyse globales de map_editor restent rouges sur une baseline extérieure au lot, principalement une désynchronisation du modèle PokemonMove et du convertisseur Pokémon SDK. La roadmap d’exécution n’est donc pas mise à jour en DONE: H1/H2 et les prédécesseurs globaux n’y sont pas formellement fermés, et la Definition of Done demande une analyse package verte.

## 2. Audit initial

### 2.1 Contrats et preuves relus

- MVP Selbrume/road_map_event_builder_v2_execution.md, sections Phase 2, H3, H4 et H5.
- MVP Selbrume/event_builder_v2_architecture_decisions.md et le contrat produit rappelé dans la roadmap.
- codex_rule.md.
- Les opérations d’authoring et la gateway de persistance du registre existantes.
- Les modèles de session, catalogue projet, read model V2 et bridge Event ↔ Map déjà livrés.
- Les widgets Event Builder V2, la route produit, le design system et les tests H1/H2/Phase G existants.
- La référence utilisateur 1672 × 941 comme direction produit, sans prétendre à une clôture pixel dans ce lot fonctionnel.

### 2.2 Gaps constatés avant implémentation

- H3: les opérations core et la persistance existaient, mais aucun coordinateur produit ne composait création multi-étapes, relecture, conflit et brouillon durable.
- H4: les callbacks d’édition étaient absents ou non branchés; les contrôles visibles pouvaient être inertes; les projections Scene devaient rester read-only.
- H5: les états loading/saving/conflict/recovery et les garanties clavier/responsive n’étaient pas couverts ensemble sur la route produit.
- Le design system ne possédait pas de champ texte labellisé et validable adapté aux side sheets.

### 2.3 Risques et limites de scope préservées

- aucun second moteur de registre;
- aucune coordonnée, tuile, zone ou géométrie éditée;
- aucune mutation inline des actions, outcomes, réactions ou changements monde de la Scene;
- aucune map indépendante de la source dans le formulaire;
- aucune saisie d’ID brut dans le flow normal;
- aucun fallback implicite vers l’éditeur legacy;
- aucune opération Git d’écriture;
- aucune modification opportuniste du chantier Pokémon SDK qui casse la baseline globale.

## 3. État Git initial

- branche: main;
- HEAD: 2f68328a38bf218c843e497940f8dd24a7a9c194;
- état relevé au démarrage de Phase 2: 42 fichiers suivis modifiés + 94 non suivis = 136 entrées;
- le checkout était déjà très sale; les modifications étrangères au lot ont été préservées;
- aucun worktree, branche, stage, commit ou push n’a été créé.

## 4. Fichiers du lot

| Fichier | Statut Phase 2 | Zones | Raison et impact |
|---|---|---|---|
| packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart | créé | lignes 1–766 | Coordinateur mince H3/H4; fresh session, opérations core, CAS journalé, relecture et statuts produit. |
| packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_authoring_sheets.dart | créé | lignes 1–918 | Side sheets création, source, Scene, conditions et comportement; pickers guidés et validations. |
| packages/map_editor/lib/src/ui/design_system/pokemap_text_field.dart | créé | lignes 1–114 | Primitive DS labellisée, validable, accessible et compatible clavier. |
| packages/map_editor/lib/src/ui/design_system/design_system.dart | modifié | export pokemap_text_field.dart | Rend la primitive disponible via le barrel officiel. |
| packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart | modifié | lignes 24–806 | Câblage route produit, snapshots, writes, feedback, adoption du registre, retour Map et ouverture Scene. |
| packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_editor.dart | modifié | callbacks lignes 6–24; contrôles lignes 106–229; projection lignes 409–462 | Rend les zones Event-owned interactives et masque les actions sans callback. |
| packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart | modifié | callbacks lignes 6–20; source lignes 88–116; Scene lignes 155–211; ordre lignes 240–265 | Inspecteur fonctionnel et honnête. |
| packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_element_library.dart | modifié | lignes 132–152 | Action Scene uniquement si réelle; badge explicite sinon; aucun faux drag/drop. |
| packages/map_editor/test/support/event_builder_v2_product_route_fixture.dart | modifié | catalogue de triggers, fact_port_open, injection gateway | Données produit réalistes et scénarios d’erreur déterministes. |
| packages/map_editor/test/narrative_event_builder_v2_use_case_test.dart | créé | lignes 1–511 | H3/H4 domaine/persistance, sources, conflits, dirty gate, recovery, champs Event-owned. |
| packages/map_editor/test/ui/canvas/event_builder_v2_creation_flow_test.dart | créé | lignes 1–402 | Cancel, Enter, reopen, map bytes, source, conditions CRUD/ordre, Scene, comportement, publish, activate, Space/saving. |
| packages/map_editor/test/ui/canvas/event_builder_v2_accessibility_test.dart | créé | lignes 1–233 | États H5, récupération, 1280/125 %, Tab, Shift+Tab, Escape et focus. |
| packages/map_editor/test/ui/canvas/event_builder_v2_flow_fidelity_test.dart | modifié | lignes 89–158 | Bibliothèque read-only, action Scene réelle et absence de contrôle mort. |
| packages/map_editor/test/ui/design_system/pokemap_text_field_test.dart | créé | lignes 1–50 | Label, erreur et submit clavier du champ DS. |
| reports/narrativeStudio/events/ns_event_v2_phase_2_authoring_evidence_pack.md | créé | document complet | Audit, preuves, inventaire, critique et contenus complets des fichiers créés. |

Le présent Evidence Pack s’exclut de sa propre annexe de contenu complet afin d’éviter une récursion impossible.

## 5. Décisions d’implémentation

### 5.1 H3 — Création et persistance

NarrativeEventBuilderV2UseCase ne réimplémente ni registre ni map write. Chaque mutation:

1. refuse l’écriture si la map, le projet ou une sauvegarde sont dirty;
2. prépare une session fraîche et attestée;
3. appelle une opération d’authoring core existante;
4. persiste via NarrativeEventRegistryPersistenceGateway;
5. convertit le résultat en statut produit;
6. recharge entre les étapes du flow de création.

Une panne après la création initiale laisse un brouillon durable et explicitement récupérable. La source nulle représente “Décider plus tard” et n’invente aucune map.

### 5.2 H4 — Ownership et contrôles

- Event-owned: source, conditions, Scene cible, reusePolicy, priorité, ordre, publication, activation.
- Scene-owned: actions, outcomes, réactions et changements monde, uniquement projetés.
- La map affichée vient de la source atomique.
- Une source existante est sélectionnée dans l’Event Builder.
- Le Map Editor n’est ouvert que pour voir une source ou créer/réparer une source physique manquante.
- Les boutons sans callback ne sont pas rendus.
- Les conditions ont de vraies actions ajouter, éditer la valeur attendue, monter, descendre et supprimer.

### 5.3 H5 — États et accessibilité

Les tests du gate combinent les huit familles d’état attendues à travers les tests nouveaux et existants. Les side sheets utilisent les primitives DS, gèrent Escape et restaurent le focus. Enter valide la création, Espace active l’action focalisée, Tab/Shift+Tab restent dans la sheet, et 1280 à 125 % ne produit pas d’overflow dans le harness couvert.

## 6. Tests et résultats exacts

### 6.1 TDD et tests ciblés

Premier RED H3: import/use case absent, compilation en échec.
Premier RED design system: PokeMapTextField absent, compilation en échec.

Commande finale du gate H:

    cd packages/map_editor
    flutter test --no-pub       test/narrative_event_builder_v2_use_case_test.dart       test/narrative_event_builder_v2_state_test.dart       test/narrative_event_builder_v2_session_snapshot_test.dart       test/ui/canvas/event_builder_v2_product_route_test.dart       test/ui/canvas/event_builder_v2_project_list_test.dart       test/ui/canvas/event_builder_v2_creation_flow_test.dart       test/ui/canvas/event_builder_v2_workspace_test.dart       test/ui/canvas/event_builder_v2_accessibility_test.dart       test/ui/canvas/event_builder_v2_flow_fidelity_test.dart       test/event_builder_workspace_test.dart       test/event_builder_map_focus_return_flow_test.dart

Résultat final exact:

    00:27 +222: All tests passed!
    exit 0

Test du champ DS:

    flutter test --no-pub test/ui/design_system/pokemap_text_field_test.dart

Résultat:

    00:00 +1: All tests passed!
    exit 0

Test isolé final du flow création/édition avant le gate:

    flutter test --no-pub test/ui/canvas/event_builder_v2_creation_flow_test.dart

Résultat:

    00:25 +3: All tests passed!
    exit 0

### 6.2 Suite complète map_editor

Commande:

    flutter test --no-pub

Résultat exact de synthèse:

    +3000 -96: Some tests failed.
    exit 1

La suite globale n’est donc pas verte. Parmi les familles observées: désynchronisation Pokémon SDK/PokemonMove, guardrails design system historiques, données Selbrume et plusieurs goldens historiques. Les 88 images de failure générées par cette exécution à 17:56–17:57 ont été supprimées; les quatre images de failure antérieures ont été conservées.

Relance isolée d’un échec représentatif:

    flutter test --no-pub test/application/services/pokemon_sdk_move_catalog_converter_test.dart

Résultat:

    loading ... pokemon_sdk_move_catalog_converter_test.dart
    Error: Type 'PokemonMoveAimedTarget' not found.
    Error: Type 'PokemonMoveFlags' not found.
    Error: Type 'PokemonMoveBattleStageMod' not found.
    Error: Type 'PokemonMoveStatus' not found.
    Some tests failed.
    exit 1

Cet échec ne référence aucun fichier de Phase 2 et reproduit une désynchronisation de modèle existante hors scope.

## 7. Analyse, format et build

Analyse ciblée finale:

    flutter analyze --no-pub [14 fichiers Phase 2]

Résultat:

    Analyzing 14 items...
    No issues found! (ran in 3.9s)
    exit 0

Analyse globale finale:

    flutter analyze --no-pub

Résultat:

    451 issues found. (ran in 4.6s)
    exit 1

Premiers blockers: paramètres dbSymbol, battleEngineAimedTarget, battleEngineMethod et types PokemonMoveAimedTarget/PokemonMoveFlags absents dans le contrat map_core courant. Aucun diagnostic final ne vise les 14 fichiers de Phase 2.

Format final:

    dart format --output=none --set-exit-if-changed [14 fichiers Phase 2]

Résultat:

    Formatted 14 files (0 changed) in 0.05 seconds.
    exit 0

Build final:

    flutter build macos --debug --no-pub

Résultat:

    Building macOS application...
    ✓ Built build/macos/Build/Products/Debug/map_editor.app
    exit 0

## 8. Verdicts des sub-agents et passes

| Passe | Verdict | Justification |
|---|---|---|
| Audit H3 / Architecture | PASS | Les opérations et le journal existaient; un coordinateur mince suffisait; aucune géométrie map requise. |
| Audit H4 / Ownership UI | PASS | Les callbacks manquants et contrôles morts ont été identifiés; les données Scene restent read-only. |
| Audit H5 / États et clavier | PASS | Les états et raccourcis manquants ont été transformés en scénarios widget ciblés. |
| Implémentation | PASS | H3/H4/H5 sont câblés sur la route produit avec design system et tokens existants. |
| Tests | PASS CIBLÉ / FAIL GLOBAL BASELINE | Gate H 222/222 et tests DS verts; suite complète +3000/-96. |
| Build / Validation | PASS BUILD / FAIL ANALYSE GLOBALE | Build macOS vert, analyse ciblée verte, analyse package 451 diagnostics. |
| Critique finale | PASS AVEC RÉSERVES | Aucun blocker trouvé dans le scope; réserves documentées ci-dessous. |

Aucun nouveau sub-agent n’a été lancé pendant la passe finale, conformément à la consigne d’orchestration active. Les audits H3/H4/H5 déjà disponibles ont été réutilisés, puis les passes Implementation, Tests, Build et Critique ont été conduites séquentiellement.

## 9. Auto-critique et risques restants

1. La commande “Ouvrir la Scene” ouvre le workspace Scenes, mais ne focalise pas encore l’ID exact de Scene. L’action n’est pas mensongère, mais la navigation précise reste une amélioration possible.
2. La sauvegarde du comportement compose plusieurs writes atomiques séquentiels. Une panne intermédiaire laisse les mutations précédentes durablement enregistrées et signalées; ce n’est pas une transaction tout-ou-rien.
3. Le flow source-less peut reprendre le contexte Map via le bridge existant, mais la création/placement physique reste volontairement propriétaire du Map Editor.
4. Aucun claim de fidélité pixel à la référence 1672 × 941 n’est fait ici. La phase 2 ferme l’interaction, pas la pixel closure; une comparaison visuelle combinée référence/candidate appartient à la phase visuelle correspondante.
5. La suite globale et l’analyse package empêchent une clôture formelle DONE tant que la baseline Pokémon SDK et les autres échecs globaux ne sont pas stabilisés.
6. La roadmap laisse H3/H4/H5 à NOT STARTED parce que leurs prédécesseurs formels ne sont pas DONE. Le code est candidate technique, pas une autorisation de sauter S0/H1/H2.
7. Le checkout final reste très sale à cause de travaux préexistants; aucun de ces travaux n’a été masqué, stage ou réécrit.

## 10. État Git final

État attendu après création du présent rapport:

- branche main;
- HEAD inchangé: 2f68328a38bf218c843e497940f8dd24a7a9c194;
- 42 entrées suivies modifiées + 107 non suivies = 149 entrées;
- quatre artefacts de failure historiques conservés;
- aucun stage, commit, push, branche, stash, reset ou worktree;
- la hausse par rapport au baseline comprend les fichiers Phase 2 et ce rapport; aucun artefact de failure créé par la suite globale n’est conservé.

## 11. Statut proposé et prochaine étape

Statut technique proposé:

- H3: IMPLEMENTED / TARGETED GREEN;
- H4: IMPLEMENTED / TARGETED GREEN;
- H5: IMPLEMENTED / TARGETED GREEN;
- Phase 2: CANDIDATE TECHNIQUE, pas DONE formel.

Prochaine étape proposée, non implémentée: fermer ou rebaseliner explicitement S0/H1/H2 et la baseline map_editor, puis seulement ratifier H3/H4/H5 dans la roadmap. Si l’ordre d’exécution formel est repris tel quel, le lot suivant après H5 est I1, mais il ne doit pas commencer avant satisfaction des prédécesseurs.

## Annexe — contenu complet: packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart

```dart
import 'package:map_core/map_core.dart';

import '../models/narrative_event_authoring_session.dart';
import '../models/narrative_event_registry_persistence_models.dart';
import '../ports/narrative_event_registry_persistence_gateway.dart';

typedef PrepareNarrativeEventBuilderV2Session
    = Future<NarrativeEventAuthoringSession> Function(String projectPath);
typedef NarrativeEventBuilderV2IdGeneratorFactory = NarrativeEventIdGenerator
    Function();

/// Editor state that must be clean before a registry transaction starts.
///
/// Event V2 writes replace `project.json` through the journaled persistence
/// gateway. Starting that transaction while the editor owns newer in-memory
/// map/project bytes would make either side silently stale.
final class NarrativeEventBuilderV2WriteEnvironment {
  const NarrativeEventBuilderV2WriteEnvironment({
    required this.mapDirty,
    required this.projectDirty,
    required this.saving,
  });

  const NarrativeEventBuilderV2WriteEnvironment.clean()
      : mapDirty = false,
        projectDirty = false,
        saving = false;

  final bool mapDirty;
  final bool projectDirty;
  final bool saving;
}

enum NarrativeEventBuilderV2WriteStatus {
  blocked,
  committed,
  noOp,
  conflict,
  recoveryRequired,
  rejected,
  failed,
}

/// Product-facing result of one atomic Event-owned mutation.
///
/// The result deliberately keeps the authoring and persistence evidence so
/// tests and recovery UI can explain a failure without pretending that a
/// rejected draft reached disk.
final class NarrativeEventBuilderV2WriteResult {
  const NarrativeEventBuilderV2WriteResult({
    required this.status,
    required this.code,
    required this.message,
    this.eventId,
    this.authoringResult,
    this.persistenceResult,
  });

  final NarrativeEventBuilderV2WriteStatus status;
  final String code;
  final String message;
  final String? eventId;
  final NarrativeEventAuthoringResult? authoringResult;
  final NarrativeEventRegistryPersistenceResult? persistenceResult;

  bool get succeeded =>
      status == NarrativeEventBuilderV2WriteStatus.committed ||
      status == NarrativeEventBuilderV2WriteStatus.noOp;
}

enum NarrativeEventBuilderV2CreationStep {
  draft,
  scene,
  reusePolicy,
  publication,
  reload,
}

/// Complete no-code creation intent.
///
/// A null source is the explicit “Décider plus tard” path. Such a record stays
/// a non-publishable draft; the workflow never invents a map or physical owner.
final class NarrativeEventBuilderV2CreationRequest {
  const NarrativeEventBuilderV2CreationRequest({
    required this.name,
    this.source,
    this.sceneId,
    this.reusePolicy,
    required this.publish,
  });

  final String name;
  final NarrativeEventSourceRef? source;
  final String? sceneId;
  final NarrativeEventReusePolicy? reusePolicy;
  final bool publish;
}

/// Result of the ordered creation workflow.
///
/// [hasDurableDraft] is intentionally separate from [succeeded]: a later
/// conflict can leave a useful draft committed by the first transaction.
final class NarrativeEventBuilderV2CreationResult {
  const NarrativeEventBuilderV2CreationResult({
    required this.status,
    required this.code,
    required this.message,
    required this.eventId,
    required this.hasDurableDraft,
    required this.failedStep,
    required this.initialRegistry,
    required this.finalRegistry,
    required this.finalRecord,
    required this.writes,
  });

  final NarrativeEventBuilderV2WriteStatus status;
  final String code;
  final String message;
  final String? eventId;
  final bool hasDurableDraft;
  final NarrativeEventBuilderV2CreationStep? failedStep;
  final NarrativeEventRegistry? initialRegistry;
  final NarrativeEventRegistry? finalRegistry;
  final NarrativeEventRecord? finalRecord;
  final List<NarrativeEventBuilderV2WriteResult> writes;

  bool get succeeded =>
      failedStep == null &&
      (status == NarrativeEventBuilderV2WriteStatus.committed ||
          status == NarrativeEventBuilderV2WriteStatus.noOp);
}

/// Attested editor detail that the project list intentionally does not carry.
///
/// Raw identities remain internal dropdown values; visible widgets use only
/// the human labels carried by the catalog entries.
final class NarrativeEventBuilderV2EditorSnapshot {
  NarrativeEventBuilderV2EditorSnapshot({
    required this.projectRevision,
    required this.record,
    required List<NarrativeSpatialEventSourceOption> spatialSources,
    required List<NarrativeOutcomeEventSourceOption> outcomeSources,
    required List<NarrativeEventProjectSceneEntry> scenes,
    required List<NarrativeEventProjectFactEntry> facts,
    required List<NarrativeEventProjectEventEntry> events,
  })  : spatialSources = List.unmodifiable(spatialSources),
        outcomeSources = List.unmodifiable(outcomeSources),
        scenes = List.unmodifiable(scenes),
        facts = List.unmodifiable(facts),
        events = List.unmodifiable(events);

  final String projectRevision;
  final NarrativeEventRecord? record;
  final List<NarrativeSpatialEventSourceOption> spatialSources;
  final List<NarrativeOutcomeEventSourceOption> outcomeSources;
  final List<NarrativeEventProjectSceneEntry> scenes;
  final List<NarrativeEventProjectFactEntry> facts;
  final List<NarrativeEventProjectEventEntry> events;

  List<NarrativeEventCondition> get conditions =>
      record?.draftOrNull?.conditions ??
      record?.definitionOrNull?.conditions ??
      const [];
}

/// Thin H3/H4 coordinator over the existing core authoring operations and the
/// Phase E journaled registry writer.
///
/// It owns no registry algorithm and performs no map mutation. Every command
/// prepares a fresh attested session, applies exactly one core mutation, then
/// persists it with compare-and-swap semantics through the existing gateway.
final class NarrativeEventBuilderV2UseCase {
  NarrativeEventBuilderV2UseCase({
    required NarrativeEventRegistryPersistenceGateway persistenceGateway,
    PrepareNarrativeEventBuilderV2Session? prepareSession,
    NarrativeEventBuilderV2IdGeneratorFactory? idGeneratorFactory,
    String Function()? operationIdFactory,
  })  : _persistenceGateway = persistenceGateway,
        _prepareSession =
            prepareSession ?? NarrativeEventAuthoringSession.prepare,
        _idGeneratorFactory =
            idGeneratorFactory ?? NarrativeEventIdGenerator.new,
        _operationIdFactory = operationIdFactory ?? _defaultOperationId;

  final NarrativeEventRegistryPersistenceGateway _persistenceGateway;
  final PrepareNarrativeEventBuilderV2Session _prepareSession;
  final NarrativeEventBuilderV2IdGeneratorFactory _idGeneratorFactory;
  final String Function() _operationIdFactory;

  Future<NarrativeEventBuilderV2EditorSnapshot> loadEditorSnapshot({
    required String projectPath,
    String? eventId,
  }) async {
    final session = await _prepareSession(projectPath);
    final catalog = session.context.catalog;
    return NarrativeEventBuilderV2EditorSnapshot(
      projectRevision: session.projectRevision,
      record: eventId == null
          ? null
          : _findRecord(session.context.registryOrNull, eventId),
      spatialSources: catalog.spatialSources.selectableOptions,
      outcomeSources: catalog.outcomeSources.selectableOptions,
      scenes: [
        for (final entry in catalog.scenes)
          if (entry.buildable) entry
      ],
      facts: catalog.facts,
      events: [
        for (final entry in catalog.events)
          if (!entry.proposed && entry.applicableReferenceTarget) entry,
      ],
    );
  }

  /// Persists each authoring step independently and reloads the attested
  /// session between steps. This matches the one-mutation journal contract and
  /// makes a partial failure recoverable instead of rolling back good bytes.
  Future<NarrativeEventBuilderV2CreationResult> create({
    required String projectPath,
    required NarrativeEventBuilderV2CreationRequest request,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) async {
    final writes = <NarrativeEventBuilderV2WriteResult>[];
    final draftWrite = await createDraft(
      projectPath: projectPath,
      name: request.name,
      source: request.source,
      environment: environment,
    );
    writes.add(draftWrite);
    final eventId = draftWrite.eventId;
    final initialRegistry = draftWrite.authoringResult?.previousRegistry;
    if (!draftWrite.succeeded || eventId == null) {
      return _creationFailure(
        write: draftWrite,
        eventId: eventId,
        failedStep: NarrativeEventBuilderV2CreationStep.draft,
        hasDurableDraft: false,
        initialRegistry: initialRegistry,
        writes: writes,
      );
    }

    Future<NarrativeEventBuilderV2CreationResult?> runStep(
      NarrativeEventBuilderV2CreationStep step,
      Future<NarrativeEventBuilderV2WriteResult> Function() action,
    ) async {
      final write = await action();
      writes.add(write);
      if (write.succeeded) return null;
      final snapshot = await _reloadRecord(projectPath, eventId);
      return _creationFailure(
        write: write,
        eventId: eventId,
        failedStep: step,
        hasDurableDraft: true,
        initialRegistry: initialRegistry,
        finalRegistry: snapshot.registry,
        finalRecord: snapshot.record,
        writes: writes,
      );
    }

    final sceneId = request.sceneId;
    if (sceneId != null) {
      final failure = await runStep(
        NarrativeEventBuilderV2CreationStep.scene,
        () => setScene(
          projectPath: projectPath,
          eventId: eventId,
          sceneId: sceneId,
          environment: environment,
        ),
      );
      if (failure != null) return failure;
    }

    final reusePolicy = request.reusePolicy;
    if (reusePolicy != null) {
      final failure = await runStep(
        NarrativeEventBuilderV2CreationStep.reusePolicy,
        () => setReusePolicy(
          projectPath: projectPath,
          eventId: eventId,
          reusePolicy: reusePolicy,
          environment: environment,
        ),
      );
      if (failure != null) return failure;
    }

    if (request.publish) {
      final failure = await runStep(
        NarrativeEventBuilderV2CreationStep.publication,
        () => publish(
          projectPath: projectPath,
          eventId: eventId,
          environment: environment,
        ),
      );
      if (failure != null) return failure;
    }

    try {
      final snapshot = await _reloadRecord(projectPath, eventId);
      final finalWrite = writes.last;
      return NarrativeEventBuilderV2CreationResult(
        status: writes.any(
          (write) =>
              write.status == NarrativeEventBuilderV2WriteStatus.committed,
        )
            ? NarrativeEventBuilderV2WriteStatus.committed
            : finalWrite.status,
        code: finalWrite.code,
        message: finalWrite.message,
        eventId: eventId,
        hasDurableDraft: true,
        failedStep: null,
        initialRegistry: initialRegistry,
        finalRegistry: snapshot.registry,
        finalRecord: snapshot.record,
        writes: List.unmodifiable(writes),
      );
    } on Object {
      return NarrativeEventBuilderV2CreationResult(
        status: NarrativeEventBuilderV2WriteStatus.failed,
        code: 'committedOutOfSync',
        message: 'Le brouillon est enregistré, mais sa relecture a échoué.',
        eventId: eventId,
        hasDurableDraft: true,
        failedStep: NarrativeEventBuilderV2CreationStep.reload,
        initialRegistry: initialRegistry,
        finalRegistry: null,
        finalRecord: null,
        writes: List.unmodifiable(writes),
      );
    }
  }

  Future<NarrativeEventBuilderV2WriteResult> createDraft({
    required String projectPath,
    required String name,
    NarrativeEventSourceRef? source,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _execute(
      projectPath: projectPath,
      environment: environment,
      author: (session) => createNarrativeEventDraft(
        context: session.context,
        expectedRevision: session.projectRevision,
        name: name,
        initialSource: source,
        idGenerator: _idGeneratorFactory(),
      ),
    );
  }

  Future<_ReloadedNarrativeEvent> _reloadRecord(
    String projectPath,
    String eventId,
  ) async {
    final session = await _prepareSession(projectPath);
    return _ReloadedNarrativeEvent(
      registry: session.context.registryOrNull,
      record: _findRecord(session.context.registryOrNull, eventId),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> rename({
    required String projectPath,
    required String eventId,
    required String name,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => renameNarrativeEvent(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        name: name,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setSource({
    required String projectPath,
    required String eventId,
    required NarrativeEventSourceRef source,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) {
        final current = _findRecord(
          session.context.registryOrNull,
          eventId,
        );
        final currentSource =
            current?.draftOrNull?.source ?? current?.definitionOrNull?.source;
        return currentSource == null
            ? selectNarrativeEventSource(
                context: session.context,
                expectedRevision: session.projectRevision,
                eventId: eventId,
                source: source,
              )
            : replaceNarrativeEventSource(
                context: session.context,
                expectedRevision: session.projectRevision,
                eventId: eventId,
                source: source,
              );
      },
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setConditions({
    required String projectPath,
    required String eventId,
    required List<NarrativeEventCondition> conditions,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => setNarrativeEventConditions(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        conditions: conditions,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setScene({
    required String projectPath,
    required String eventId,
    required String sceneId,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => setNarrativeEventScene(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        sceneId: sceneId,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> removeScene({
    required String projectPath,
    required String eventId,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => removeNarrativeEventScene(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setReusePolicy({
    required String projectPath,
    required String eventId,
    required NarrativeEventReusePolicy reusePolicy,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => setNarrativeEventReusePolicy(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        reusePolicy: reusePolicy,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setPriority({
    required String projectPath,
    required String eventId,
    required int priority,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => setNarrativeEventPriority(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        priority: priority,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setOrder({
    required String projectPath,
    required String eventId,
    required int order,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => setNarrativeEventOrder(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        order: order,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> publish({
    required String projectPath,
    required String eventId,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => publishNarrativeEvent(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setEnabled({
    required String projectPath,
    required String eventId,
    required bool enabled,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => enabled
          ? activateNarrativeEvent(
              context: session.context,
              expectedRevision: session.projectRevision,
              eventId: eventId,
            )
          : deactivateNarrativeEvent(
              context: session.context,
              expectedRevision: session.projectRevision,
              eventId: eventId,
            ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> _executeForEvent({
    required String projectPath,
    required String eventId,
    required NarrativeEventBuilderV2WriteEnvironment environment,
    required NarrativeEventAuthoringResult Function(
      NarrativeEventAuthoringSession session,
    ) author,
  }) {
    return _execute(
      projectPath: projectPath,
      environment: environment,
      expectedEventId: eventId,
      author: author,
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> _execute({
    required String projectPath,
    required NarrativeEventBuilderV2WriteEnvironment environment,
    required NarrativeEventAuthoringResult Function(
      NarrativeEventAuthoringSession session,
    ) author,
    String? expectedEventId,
  }) async {
    final blocked = _dirtyGate(environment);
    if (blocked != null) return blocked;

    late final NarrativeEventAuthoringSession session;
    try {
      session = await _prepareSession(projectPath);
    } on Object catch (error) {
      return NarrativeEventBuilderV2WriteResult(
        status: NarrativeEventBuilderV2WriteStatus.rejected,
        code: 'preflightRejected',
        message: 'La session Event ne peut pas être préparée: $error',
        eventId: expectedEventId,
      );
    }

    final authoring = author(session);
    final eventId = expectedEventId ?? authoring.eventId;
    if (authoring.status == NarrativeEventAuthoringStatus.noOp) {
      return NarrativeEventBuilderV2WriteResult(
        status: NarrativeEventBuilderV2WriteStatus.noOp,
        code: 'noOp',
        message: 'Aucune modification à enregistrer.',
        eventId: eventId,
        authoringResult: authoring,
      );
    }
    if (authoring.status != NarrativeEventAuthoringStatus.applied ||
        authoring.nextRegistry == null) {
      return NarrativeEventBuilderV2WriteResult(
        status: NarrativeEventBuilderV2WriteStatus.rejected,
        code: authoring.rejectionCode ?? authoring.status.name,
        message: authoring.humanReason ??
            'Cette modification ne peut pas être enregistrée.',
        eventId: eventId,
        authoringResult: authoring,
      );
    }

    final request = NarrativeEventRegistryWriteRequest.fromAuthoringSession(
      session: session,
      operationId: _operationIdFactory(),
      result: authoring,
    );
    late final NarrativeEventRegistryPersistenceResult persistence;
    try {
      persistence = await _persistenceGateway.persist(request);
    } on Object {
      return NarrativeEventBuilderV2WriteResult(
        status: NarrativeEventBuilderV2WriteStatus.failed,
        code: 'persistenceException',
        message: 'La modification n’a pas pu être enregistrée.',
        eventId: eventId,
        authoringResult: authoring,
      );
    }
    return NarrativeEventBuilderV2WriteResult(
      status: _writeStatus(persistence),
      code: persistence.code,
      message: persistence.message,
      eventId: eventId,
      authoringResult: authoring,
      persistenceResult: persistence,
    );
  }
}

NarrativeEventBuilderV2CreationResult _creationFailure({
  required NarrativeEventBuilderV2WriteResult write,
  required String? eventId,
  required NarrativeEventBuilderV2CreationStep failedStep,
  required bool hasDurableDraft,
  required NarrativeEventRegistry? initialRegistry,
  required List<NarrativeEventBuilderV2WriteResult> writes,
  NarrativeEventRegistry? finalRegistry,
  NarrativeEventRecord? finalRecord,
}) {
  return NarrativeEventBuilderV2CreationResult(
    status: write.status,
    code: write.code,
    message: write.message,
    eventId: eventId,
    hasDurableDraft: hasDurableDraft,
    failedStep: failedStep,
    initialRegistry: initialRegistry,
    finalRegistry: finalRegistry,
    finalRecord: finalRecord,
    writes: List.unmodifiable(writes),
  );
}

final class _ReloadedNarrativeEvent {
  const _ReloadedNarrativeEvent({
    required this.registry,
    required this.record,
  });

  final NarrativeEventRegistry? registry;
  final NarrativeEventRecord? record;
}

NarrativeEventBuilderV2WriteResult? _dirtyGate(
  NarrativeEventBuilderV2WriteEnvironment environment,
) {
  if (environment.saving) {
    return const NarrativeEventBuilderV2WriteResult(
      status: NarrativeEventBuilderV2WriteStatus.blocked,
      code: 'saveInProgress',
      message: 'Attendez la fin de la sauvegarde.',
    );
  }
  if (environment.mapDirty) {
    return const NarrativeEventBuilderV2WriteResult(
      status: NarrativeEventBuilderV2WriteStatus.blocked,
      code: 'mapDirty',
      message: 'Enregistrez la map avant de modifier cet Event.',
    );
  }
  if (environment.projectDirty) {
    return const NarrativeEventBuilderV2WriteResult(
      status: NarrativeEventBuilderV2WriteStatus.blocked,
      code: 'projectDirty',
      message: 'Enregistrez le projet avant de modifier cet Event.',
    );
  }
  return null;
}

NarrativeEventBuilderV2WriteStatus _writeStatus(
  NarrativeEventRegistryPersistenceResult persistence,
) {
  return switch (persistence.status) {
    NarrativeEventRegistryPersistenceStatus.committed ||
    NarrativeEventRegistryPersistenceStatus.recovered =>
      NarrativeEventBuilderV2WriteStatus.committed,
    NarrativeEventRegistryPersistenceStatus.noOp =>
      NarrativeEventBuilderV2WriteStatus.noOp,
    NarrativeEventRegistryPersistenceStatus.staleRevision ||
    NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot =>
      NarrativeEventBuilderV2WriteStatus.conflict,
    NarrativeEventRegistryPersistenceStatus.recoveryRequired =>
      NarrativeEventBuilderV2WriteStatus.recoveryRequired,
    NarrativeEventRegistryPersistenceStatus.blocked =>
      NarrativeEventBuilderV2WriteStatus.blocked,
    NarrativeEventRegistryPersistenceStatus.ioFailure =>
      NarrativeEventBuilderV2WriteStatus.failed,
    NarrativeEventRegistryPersistenceStatus.staleUndo ||
    NarrativeEventRegistryPersistenceStatus.rejected ||
    NarrativeEventRegistryPersistenceStatus.unsupportedRegistry ||
    NarrativeEventRegistryPersistenceStatus.invalidRegistry =>
      NarrativeEventBuilderV2WriteStatus.rejected,
  };
}

String _defaultOperationId() {
  return 'v2_phase2_${DateTime.now().microsecondsSinceEpoch}';
}

NarrativeEventRecord? _findRecord(
  NarrativeEventRegistry? registry,
  String eventId,
) {
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    if (record.id == eventId) return record;
  }
  return null;
}
```

## Annexe — contenu complet: packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_authoring_sheets.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../application/use_cases/narrative_event_builder_v2_use_case.dart';
import '../../design_system/design_system.dart';

typedef EventBuilderV2CreationSubmit = Future<String?> Function(
  NarrativeEventBuilderV2CreationRequest request,
);

final class EventBuilderV2SourceChoice {
  const EventBuilderV2SourceChoice({
    required this.id,
    required this.label,
    required this.description,
    required this.source,
  });

  final String id;
  final String label;
  final String description;
  final NarrativeEventSourceRef? source;
}

List<EventBuilderV2SourceChoice> eventBuilderV2SourceChoices(
  NarrativeEventBuilderV2EditorSnapshot snapshot, {
  bool includeDecideLater = true,
}) {
  var index = 0;
  return [
    if (includeDecideLater)
      const EventBuilderV2SourceChoice(
        id: 'later',
        label: 'Décider plus tard',
        description: 'Conserver un brouillon sans déclencheur.',
        source: null,
      ),
    for (final option in snapshot.spatialSources)
      EventBuilderV2SourceChoice(
        id: 'spatial_${index++}',
        label: '${option.sourceTypeLabel} · ${option.humanLabel}',
        description: '${option.humanDescription} · ${option.mapLabel}',
        source: option.source,
      ),
    for (final option in snapshot.outcomeSources)
      EventBuilderV2SourceChoice(
        id: 'outcome_${index++}',
        label: 'Résultat · ${option.outcomeLabel}',
        description: option.humanSourceSentence,
        source: option.outcome == null
            ? null
            : NarrativeEventSourceRef.outcomeReceived(option.outcome!),
      ),
  ];
}

class EventBuilderV2CreationSheet extends StatefulWidget {
  const EventBuilderV2CreationSheet({
    super.key,
    required this.snapshot,
    required this.onSubmit,
  });

  final NarrativeEventBuilderV2EditorSnapshot snapshot;
  final EventBuilderV2CreationSubmit onSubmit;

  @override
  State<EventBuilderV2CreationSheet> createState() =>
      _EventBuilderV2CreationSheetState();
}

class _EventBuilderV2CreationSheetState
    extends State<EventBuilderV2CreationSheet> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode(debugLabel: 'new event name');
  late final List<EventBuilderV2SourceChoice> _sources;
  String _sourceId = 'later';
  String _sceneId = 'later';
  String _reusePolicy = 'later';
  bool _submitted = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sources = eventBuilderV2SourceChoices(widget.snapshot);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  EventBuilderV2SourceChoice get _selectedSource =>
      _sources.firstWhere((choice) => choice.id == _sourceId);

  bool get _hasName => _nameController.text.trim().isNotEmpty;
  bool get _canPublish =>
      _hasName &&
      _selectedSource.source != null &&
      _sceneId != 'later' &&
      _reusePolicy != 'later';

  Future<void> _submit(bool publish) async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_hasName || (publish && !_canPublish)) return;
    setState(() => _saving = true);
    final error = await widget.onSubmit(
      NarrativeEventBuilderV2CreationRequest(
        name: _nameController.text.trim(),
        source: _selectedSource.source,
        sceneId: _sceneId == 'later' ? null : _sceneId,
        reusePolicy: switch (_reusePolicy) {
          'oneShot' => NarrativeEventReusePolicy.oneShot,
          'reusable' => NarrativeEventReusePolicy.reusable,
          _ => null,
        },
        publish: publish,
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final source = _selectedSource;
    return ListView(
      key: const ValueKey('event-builder-v2-creation-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapTextField(
          key: const ValueKey('event-builder-v2-create-name'),
          label: 'Nom de l’événement',
          controller: _nameController,
          focusNode: _nameFocusNode,
          autofocus: true,
          enabled: !_saving,
          hintText: 'Ex. Rencontre rival au port',
          errorText: _submitted && !_hasName
              ? 'Le nom de l’événement est obligatoire.'
              : null,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(false),
        ),
        const SizedBox(height: 14),
        PokeMapDropdownField<String>(
          label: 'Déclencheur existant',
          value: _sourceId,
          enabled: !_saving,
          items: [
            for (final choice in _sources)
              PokeMapDropdownItem(value: choice.id, label: choice.label),
          ],
          onChanged: (value) => setState(() => _sourceId = value),
        ),
        const SizedBox(height: 6),
        PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          title: source.label,
          message: source.description,
        ),
        const SizedBox(height: 14),
        PokeMapDropdownField<String>(
          label: 'Scene à jouer',
          value: _sceneId,
          enabled: !_saving,
          items: [
            const PokeMapDropdownItem(
              value: 'later',
              label: 'Décider plus tard',
            ),
            for (final entry in widget.snapshot.scenes)
              PokeMapDropdownItem(
                value: entry.scene.id,
                label: entry.scene.name,
              ),
          ],
          onChanged: (value) => setState(() => _sceneId = value),
        ),
        const SizedBox(height: 14),
        PokeMapDropdownField<String>(
          label: 'Réutilisation',
          value: _reusePolicy,
          enabled: !_saving,
          items: const [
            PokeMapDropdownItem(
              value: 'later',
              label: 'Décider plus tard',
            ),
            PokeMapDropdownItem(
              value: 'oneShot',
              label: 'Une seule fois',
            ),
            PokeMapDropdownItem(
              value: 'reusable',
              label: 'Réutilisable',
            ),
          ],
          onChanged: (value) => setState(() => _reusePolicy = value),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            title: 'Enregistrement interrompu',
            message: _error!,
          ),
        ],
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            PokeMapButton(
              key: const ValueKey('event-builder-v2-save-draft'),
              onPressed: _saving ? null : () => _submit(false),
              isLoading: _saving,
              variant: PokeMapButtonVariant.secondary,
              child: const Text('Enregistrer le brouillon'),
            ),
            PokeMapButton(
              key: const ValueKey('event-builder-v2-publish-create'),
              onPressed: !_saving && _canPublish ? () => _submit(true) : null,
              variant: PokeMapButtonVariant.success,
              child: const Text('Publier désactivé'),
            ),
          ],
        ),
      ],
    );
  }
}

class EventBuilderV2SourceSheet extends StatefulWidget {
  const EventBuilderV2SourceSheet({
    super.key,
    required this.snapshot,
    required this.currentSource,
    required this.onSubmit,
  });

  final NarrativeEventBuilderV2EditorSnapshot snapshot;
  final NarrativeEventSourceRef? currentSource;
  final Future<String?> Function(NarrativeEventSourceRef source) onSubmit;

  @override
  State<EventBuilderV2SourceSheet> createState() =>
      _EventBuilderV2SourceSheetState();
}

class _EventBuilderV2SourceSheetState extends State<EventBuilderV2SourceSheet> {
  late final List<EventBuilderV2SourceChoice> _sources;
  late String _sourceId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sources = eventBuilderV2SourceChoices(
      widget.snapshot,
      includeDecideLater: false,
    );
    _sourceId = _sources
            .where((choice) => choice.source == widget.currentSource)
            .map((choice) => choice.id)
            .firstOrNull ??
        (_sources.isEmpty ? '' : _sources.first.id);
  }

  Future<void> _save() async {
    final selected =
        _sources.where((choice) => choice.id == _sourceId).firstOrNull;
    final source = selected?.source;
    if (source == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSubmit(source);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_sources.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucun déclencheur disponible',
        description:
            'Placez d’abord un PNJ ou une zone sur une map, ou créez un outcome.',
        icon: Icon(CupertinoIcons.bolt_slash),
      );
    }
    final selected = _sources.firstWhere((choice) => choice.id == _sourceId);
    return ListView(
      key: const ValueKey('event-builder-v2-source-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapDropdownField<String>(
          label: 'Déclencheur existant',
          value: _sourceId,
          enabled: !_saving,
          items: [
            for (final choice in _sources)
              PokeMapDropdownItem(value: choice.id, label: choice.label),
          ],
          onChanged: (value) => setState(() => _sourceId = value),
        ),
        const SizedBox(height: 8),
        PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          title: selected.label,
          message: selected.description,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            message: _error!,
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            onPressed: _saving ? null : _save,
            isLoading: _saving,
            child: const Text('Enregistrer le déclencheur'),
          ),
        ),
      ],
    );
  }
}

class EventBuilderV2SceneSheet extends StatefulWidget {
  const EventBuilderV2SceneSheet({
    super.key,
    required this.snapshot,
    required this.currentSceneId,
    required this.onSubmit,
  });

  final NarrativeEventBuilderV2EditorSnapshot snapshot;
  final String? currentSceneId;
  final Future<String?> Function(String? sceneId) onSubmit;

  @override
  State<EventBuilderV2SceneSheet> createState() =>
      _EventBuilderV2SceneSheetState();
}

class _EventBuilderV2SceneSheetState extends State<EventBuilderV2SceneSheet> {
  late String _sceneId = widget.currentSceneId ?? 'none';
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSubmit(_sceneId == 'none' ? null : _sceneId);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final validSceneIds = widget.snapshot.scenes.map((entry) => entry.scene.id);
    if (_sceneId != 'none' && !validSceneIds.contains(_sceneId)) {
      _sceneId = 'none';
    }
    return ListView(
      key: const ValueKey('event-builder-v2-scene-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapDropdownField<String>(
          label: 'Scene à jouer',
          value: _sceneId,
          enabled: !_saving,
          items: [
            const PokeMapDropdownItem(
              value: 'none',
              label: 'Aucune Scene',
            ),
            for (final entry in widget.snapshot.scenes)
              PokeMapDropdownItem(
                value: entry.scene.id,
                label: entry.scene.name,
              ),
          ],
          onChanged: (value) => setState(() => _sceneId = value),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            message: _error!,
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            onPressed: _saving ? null : _save,
            isLoading: _saving,
            child: const Text('Enregistrer la Scene'),
          ),
        ),
      ],
    );
  }
}

class EventBuilderV2ConditionsSheet extends StatefulWidget {
  const EventBuilderV2ConditionsSheet({
    super.key,
    required this.snapshot,
    required this.onSubmit,
  });

  final NarrativeEventBuilderV2EditorSnapshot snapshot;
  final Future<String?> Function(List<NarrativeEventCondition> conditions)
      onSubmit;

  @override
  State<EventBuilderV2ConditionsSheet> createState() =>
      _EventBuilderV2ConditionsSheetState();
}

class _EventBuilderV2ConditionsSheetState
    extends State<EventBuilderV2ConditionsSheet> {
  late final List<NarrativeEventCondition> _conditions = [
    ...widget.snapshot.conditions,
  ];
  String _kind = 'fact';
  String? _targetId;
  bool _expected = true;
  bool _saving = false;
  String? _error;

  List<PokeMapDropdownItem<String>> get _targets => _kind == 'fact'
      ? [
          for (final entry in widget.snapshot.facts)
            PokeMapDropdownItem(
              value: entry.fact.id,
              label: entry.fact.label,
            ),
        ]
      : [
          for (final entry in widget.snapshot.events)
            if (entry.record.id != widget.snapshot.record?.id)
              PokeMapDropdownItem(
                value: entry.record.id,
                label: _recordName(entry.record),
              ),
        ];

  void _add() {
    final target = _targetId ?? _targets.firstOrNull?.value;
    if (target == null) return;
    setState(() {
      _conditions.add(
        _kind == 'fact'
            ? NarrativeEventCondition.fact(target, _expected)
            : NarrativeEventCondition.narrativeEventConsumed(
                target,
                _expected,
              ),
      );
    });
  }

  void _toggleExpectedValue(int index) {
    final condition = _conditions[index];
    final updated = condition.when(
      fact: (factId, expected) =>
          NarrativeEventCondition.fact(factId, !expected),
      narrativeEventConsumed: (eventId, expected) =>
          NarrativeEventCondition.narrativeEventConsumed(eventId, !expected),
    );
    setState(() => _conditions[index] = updated);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSubmit(List.unmodifiable(_conditions));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final targets = _targets;
    final targetValue = targets.any((item) => item.value == _targetId)
        ? _targetId!
        : (targets.firstOrNull?.value ?? 'none');
    return ListView(
      key: const ValueKey('event-builder-v2-conditions-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Toutes les conditions doivent être remplies, dans l’ordre affiché.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < _conditions.length; index++) ...[
          PokeMapCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _conditionLabel(widget.snapshot, _conditions[index]),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 2,
                    children: [
                      PokeMapIconButton(
                        key: ValueKey(
                          'event-builder-v2-move-condition-up-$index',
                        ),
                        onPressed: index == 0
                            ? null
                            : () => setState(() {
                                  final condition = _conditions.removeAt(index);
                                  _conditions.insert(index - 1, condition);
                                }),
                        icon: const Icon(CupertinoIcons.arrow_up),
                        tooltip: 'Monter la condition',
                        size: 28,
                      ),
                      PokeMapIconButton(
                        key: ValueKey(
                          'event-builder-v2-move-condition-down-$index',
                        ),
                        onPressed: index == _conditions.length - 1
                            ? null
                            : () => setState(() {
                                  final condition = _conditions.removeAt(index);
                                  _conditions.insert(index + 1, condition);
                                }),
                        icon: const Icon(CupertinoIcons.arrow_down),
                        tooltip: 'Descendre la condition',
                        size: 28,
                      ),
                      PokeMapIconButton(
                        key: ValueKey(
                          'event-builder-v2-toggle-condition-$index',
                        ),
                        onPressed: () => _toggleExpectedValue(index),
                        icon: const Icon(CupertinoIcons.arrow_2_circlepath),
                        tooltip: 'Inverser la valeur attendue',
                        size: 28,
                      ),
                      PokeMapIconButton(
                        key: ValueKey(
                          'event-builder-v2-delete-condition-$index',
                        ),
                        onPressed: () =>
                            setState(() => _conditions.removeAt(index)),
                        icon: const Icon(CupertinoIcons.delete),
                        tooltip: 'Supprimer la condition',
                        variant: PokeMapIconButtonVariant.danger,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 8),
        PokeMapDropdownField<String>(
          label: 'Type de condition',
          value: _kind,
          enabled: !_saving,
          items: const [
            PokeMapDropdownItem(value: 'fact', label: 'Fact projet'),
            PokeMapDropdownItem(
              value: 'event',
              label: 'Événement déjà consommé',
            ),
          ],
          onChanged: (value) => setState(() {
            _kind = value;
            _targetId = null;
          }),
        ),
        const SizedBox(height: 10),
        PokeMapDropdownField<String>(
          label: 'Élément à vérifier',
          value: targetValue,
          enabled: !_saving && targets.isNotEmpty,
          items: targets.isEmpty
              ? const [
                  PokeMapDropdownItem(
                    value: 'none',
                    label: 'Aucun élément disponible',
                  ),
                ]
              : targets,
          onChanged: (value) => setState(() => _targetId = value),
        ),
        const SizedBox(height: 10),
        PokeMapDropdownField<bool>(
          label: 'Valeur attendue',
          value: _expected,
          enabled: !_saving,
          items: const [
            PokeMapDropdownItem(value: true, label: 'Vrai'),
            PokeMapDropdownItem(value: false, label: 'Faux'),
          ],
          onChanged: (value) => setState(() => _expected = value),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: PokeMapButton(
            onPressed: !_saving && targets.isNotEmpty ? _add : null,
            variant: PokeMapButtonVariant.secondary,
            leading: const Icon(CupertinoIcons.add),
            child: const Text('Ajouter à la liste'),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            message: _error!,
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            onPressed: _saving ? null : _save,
            isLoading: _saving,
            child: const Text('Enregistrer les conditions'),
          ),
        ),
      ],
    );
  }
}

final class EventBuilderV2BehaviorUpdate {
  const EventBuilderV2BehaviorUpdate({
    required this.name,
    required this.reusePolicy,
    required this.priority,
    required this.order,
  });

  final String name;
  final NarrativeEventReusePolicy? reusePolicy;
  final int priority;
  final int order;
}

class EventBuilderV2BehaviorSheet extends StatefulWidget {
  const EventBuilderV2BehaviorSheet({
    super.key,
    required this.record,
    required this.onSave,
    required this.onPublish,
    required this.onSetEnabled,
  });

  final NarrativeEventRecord record;
  final Future<String?> Function(EventBuilderV2BehaviorUpdate update) onSave;
  final Future<String?> Function() onPublish;
  final Future<String?> Function(bool enabled) onSetEnabled;

  @override
  State<EventBuilderV2BehaviorSheet> createState() =>
      _EventBuilderV2BehaviorSheetState();
}

class _EventBuilderV2BehaviorSheetState
    extends State<EventBuilderV2BehaviorSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: _recordName(widget.record),
  );
  late final TextEditingController _priorityController = TextEditingController(
    text: _recordPriority(widget.record).toString(),
  );
  late final TextEditingController _orderController = TextEditingController(
    text: _recordOrder(widget.record).toString(),
  );
  late String _reuse = switch (_recordReuse(widget.record)) {
    NarrativeEventReusePolicy.oneShot => 'oneShot',
    NarrativeEventReusePolicy.reusable => 'reusable',
    null => 'later',
  };
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _priorityController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _perform(Future<String?> Function() action) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await action();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    final priority = int.tryParse(_priorityController.text.trim());
    final order = int.tryParse(_orderController.text.trim());
    if (_nameController.text.trim().isEmpty ||
        priority == null ||
        order == null) {
      setState(() => _error = 'Vérifiez le nom, la priorité et l’ordre.');
      return;
    }
    await _perform(
      () => widget.onSave(
        EventBuilderV2BehaviorUpdate(
          name: _nameController.text.trim(),
          reusePolicy: switch (_reuse) {
            'oneShot' => NarrativeEventReusePolicy.oneShot,
            'reusable' => NarrativeEventReusePolicy.reusable,
            _ => null,
          },
          priority: priority,
          order: order,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDraft = widget.record.draftOrNull != null;
    final enabled = widget.record.enabledOrNull ?? false;
    return ListView(
      key: const ValueKey('event-builder-v2-behavior-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapTextField(
          label: 'Nom',
          controller: _nameController,
          enabled: !_saving,
        ),
        const SizedBox(height: 12),
        PokeMapDropdownField<String>(
          label: 'Réutilisation',
          value: _reuse,
          enabled: !_saving,
          items: const [
            PokeMapDropdownItem(
              value: 'later',
              label: 'Décider plus tard',
            ),
            PokeMapDropdownItem(
              value: 'oneShot',
              label: 'Une seule fois',
            ),
            PokeMapDropdownItem(
              value: 'reusable',
              label: 'Réutilisable',
            ),
          ],
          onChanged: (value) => setState(() => _reuse = value),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PokeMapTextField(
                label: 'Priorité',
                controller: _priorityController,
                enabled: !_saving,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PokeMapTextField(
                label: 'Ordre d’évaluation',
                controller: _orderController,
                enabled: !_saving,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            message: _error!,
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PokeMapButton(
              onPressed: _saving ? null : _save,
              isLoading: _saving,
              child: const Text('Enregistrer'),
            ),
            if (isDraft)
              PokeMapButton(
                onPressed: _saving ? null : () => _perform(widget.onPublish),
                variant: PokeMapButtonVariant.success,
                child: const Text('Publier désactivé'),
              )
            else
              PokeMapButton(
                onPressed: _saving
                    ? null
                    : () => _perform(() => widget.onSetEnabled(!enabled)),
                variant: enabled
                    ? PokeMapButtonVariant.danger
                    : PokeMapButtonVariant.success,
                child: Text(enabled ? 'Désactiver' : 'Activer'),
              ),
          ],
        ),
      ],
    );
  }
}

String _recordName(NarrativeEventRecord record) =>
    record.draftOrNull?.name ?? record.definitionOrNull!.name;

int _recordPriority(NarrativeEventRecord record) =>
    record.draftOrNull?.priority ?? record.definitionOrNull!.priority;

int _recordOrder(NarrativeEventRecord record) =>
    record.draftOrNull?.order ?? record.definitionOrNull!.order;

NarrativeEventReusePolicy? _recordReuse(NarrativeEventRecord record) =>
    record.draftOrNull?.reusePolicy ?? record.definitionOrNull?.reusePolicy;

String _conditionLabel(
  NarrativeEventBuilderV2EditorSnapshot snapshot,
  NarrativeEventCondition condition,
) {
  return condition.when(
    fact: (factId, expected) {
      final label = snapshot.facts
              .where((entry) => entry.fact.id == factId)
              .map((entry) => entry.fact.label)
              .firstOrNull ??
          'Fact indisponible';
      return '$label = ${expected ? 'Vrai' : 'Faux'}';
    },
    narrativeEventConsumed: (eventId, expected) {
      final label = snapshot.events
              .where((entry) => entry.record.id == eventId)
              .map((entry) => _recordName(entry.record))
              .firstOrNull ??
          'Événement indisponible';
      return '$label déjà joué = ${expected ? 'Vrai' : 'Faux'}';
    },
  );
}
```

## Annexe — contenu complet: packages/map_editor/lib/src/ui/design_system/pokemap_text_field.dart

```dart
import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Token-driven labelled input for editor forms.
class PokeMapTextField extends StatelessWidget {
  const PokeMapTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.done,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: enabled ? colors.textMuted : colors.textDisabled,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Semantics(
          container: true,
          textField: true,
          enabled: enabled,
          label: label,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            enabled: enabled,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: TextStyle(
              color: enabled ? colors.textPrimary : colors.textDisabled,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: colors.surfaceSubtle,
              hintText: hintText,
              hintStyle: TextStyle(
                color: colors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.focusRing, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.controlBorder),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Text(
              errorText!,
              style: TextStyle(
                color: colors.error,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
```

## Annexe — contenu complet: packages/map_editor/test/narrative_event_builder_v2_use_case_test.dart

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_builder_v2_use_case.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

import 'support/event_builder_v2_product_route_fixture.dart';

void main() {
  group('NS-EVENT-V2 Phase 2 H3/H4 authoring coordinator', () {
    test('creates source-first, persists, closes and reopens without loss',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: FileProjectRepository(),
        operationIdFactory: () => 'phase2_create_reopen',
      );
      final source = NarrativeEventSourceRef.mapEnter('map_forest');

      final result = await useCase.createDraft(
        projectPath: fixture.projectPath,
        name: 'Entrée dans la brume',
        source: source,
        environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
      );

      expect(result.status, NarrativeEventBuilderV2WriteStatus.committed);
      expect(result.eventId, isNotNull);
      final reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final record = reopened.context.registryOrNull!.records.singleWhere(
        (candidate) => candidate.id == result.eventId,
      );
      expect(record.draftOrNull!.name, 'Entrée dans la brume');
      expect(record.draftOrNull!.source, source);
    });

    test('publishes all four atomic source kinds without touching map bytes',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final mapPaths = [
        p.join(fixture.root.path, 'maps', 'port.json'),
        p.join(fixture.root.path, 'maps', 'forest.json'),
      ];
      final mapBytesBefore = [
        for (final path in mapPaths) await File(path).readAsBytes(),
      ];
      var operation = 0;
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: FileProjectRepository(),
        operationIdFactory: () => 'phase2_source_kind_${operation++}',
      );
      final sources = <String, NarrativeEventSourceRef>{
        'Entité existante':
            NarrativeEventSourceRef.entityInteract('map_port', 'npc_rival'),
        'Zone existante': NarrativeEventSourceRef.triggerEnter(
            'map_port', 'trigger_map_port'),
        'Entrée de map': NarrativeEventSourceRef.mapEnter('map_forest'),
        'Résultat existant': NarrativeEventSourceRef.outcomeReceived(
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: 'scene_rival',
            outcomeId: 'victory',
          ),
        ),
      };

      for (final entry in sources.entries) {
        final result = await useCase.create(
          projectPath: fixture.projectPath,
          request: NarrativeEventBuilderV2CreationRequest(
            name: entry.key,
            source: entry.value,
            sceneId: 'scene_action',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            publish: true,
          ),
          environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
        );
        expect(result.status, NarrativeEventBuilderV2WriteStatus.committed);
        expect(result.hasDurableDraft, isTrue);
        expect(result.finalRecord!.definitionOrNull!.source, entry.value);
        expect(result.finalRecord!.enabledOrNull, isFalse);
      }

      for (var index = 0; index < mapPaths.length; index++) {
        expect(
            await File(mapPaths[index]).readAsBytes(), mapBytesBefore[index]);
      }
    });

    test('Decide later persists a non-publishable source-less draft', () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: FileProjectRepository(),
        operationIdFactory: () => 'phase2_decide_later',
      );

      final result = await useCase.create(
        projectPath: fixture.projectPath,
        request: const NarrativeEventBuilderV2CreationRequest(
          name: 'Décider plus tard',
          publish: false,
        ),
        environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
      );

      expect(result.status, NarrativeEventBuilderV2WriteStatus.committed);
      expect(result.finalRecord!.draftOrNull!.source, isNull);
      expect(result.finalRecord!.definitionOrNull, isNull);
    });

    test('keeps the durable draft when a later creation step conflicts',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final gateway = _FailOnSecondGateway(FileProjectRepository());
      var operation = 0;
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: gateway,
        operationIdFactory: () => 'phase2_partial_${operation++}',
      );

      final result = await useCase.create(
        projectPath: fixture.projectPath,
        request: NarrativeEventBuilderV2CreationRequest(
          name: 'Brouillon durable',
          source: NarrativeEventSourceRef.mapEnter('map_port'),
          sceneId: 'scene_action',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          publish: true,
        ),
        environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
      );

      expect(result.status, NarrativeEventBuilderV2WriteStatus.conflict);
      expect(result.failedStep, NarrativeEventBuilderV2CreationStep.scene);
      expect(result.hasDurableDraft, isTrue);
      final reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final durable = reopened.context.registryOrNull!.records.singleWhere(
        (record) => record.id == result.eventId,
      );
      expect(durable.draftOrNull!.name, 'Brouillon durable');
      expect(durable.draftOrNull!.sceneId, isNull);
    });

    test('blocks dirty project state before preparing or writing', () async {
      var prepareCalls = 0;
      final gateway = _RecordingGateway();
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: gateway,
        prepareSession: (path) async {
          prepareCalls++;
          throw StateError('prepare must not run');
        },
      );

      final result = await useCase.createDraft(
        projectPath: '/tmp/project.json',
        name: 'Ne doit pas être créé',
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        environment: const NarrativeEventBuilderV2WriteEnvironment(
          mapDirty: false,
          projectDirty: true,
          saving: false,
        ),
      );

      expect(result.status, NarrativeEventBuilderV2WriteStatus.blocked);
      expect(result.code, 'projectDirty');
      expect(prepareCalls, 0);
      expect(gateway.persistCalls, 0);
    });

    test('reports a revision conflict without pretending the draft was saved',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway(
        persistResult: NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.staleRevision,
          code: 'staleRevision',
          message: 'Le projet a changé.',
        ),
      );
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: gateway,
        operationIdFactory: () => 'phase2_stale_create',
      );

      final result = await useCase.createDraft(
        projectPath: fixture.projectPath,
        name: 'Brouillon conservé dans la feuille',
        source: NarrativeEventSourceRef.mapEnter('map_port'),
        environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
      );

      expect(result.status, NarrativeEventBuilderV2WriteStatus.conflict);
      expect(result.code, 'staleRevision');
      expect(result.eventId, isNotNull);
      expect(gateway.persistCalls, 1);
      final reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      expect(
        reopened.context.registryOrNull!.records
            .where((record) => record.id == result.eventId),
        isEmpty,
      );
    });

    test('surfaces a recovery-required journal state without adopting bytes',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway(
        persistResult: NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.recoveryRequired,
          code: 'recoveryRequired',
          message: 'Une écriture interrompue doit être récupérée.',
        ),
      );
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: gateway,
      );

      final result = await useCase.setConditions(
        projectPath: fixture.projectPath,
        eventId: productRouteDraftEventId,
        conditions: [
          NarrativeEventCondition.fact('fact_port_open', true),
        ],
        environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
      );

      expect(
        result.status,
        NarrativeEventBuilderV2WriteStatus.recoveryRequired,
      );
      final reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      expect(
        reopened.context.registryOrNull!.records
            .singleWhere((record) => record.id == productRouteDraftEventId)
            .draftOrNull!
            .conditions,
        isEmpty,
      );
    });

    test('persists every Event-owned field then publishes and activates',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      var operation = 0;
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: FileProjectRepository(),
        operationIdFactory: () => 'phase2_edit_${operation++}',
      );
      const environment = NarrativeEventBuilderV2WriteEnvironment.clean();
      final source = NarrativeEventSourceRef.mapEnter('map_forest');
      final created = await useCase.createDraft(
        projectPath: fixture.projectPath,
        name: 'Passage secret',
        source: source,
        environment: environment,
      );
      final eventId = created.eventId!;

      expect(
        (await useCase.rename(
          projectPath: fixture.projectPath,
          eventId: eventId,
          name: 'Passage secret révélé',
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.setConditions(
          projectPath: fixture.projectPath,
          eventId: eventId,
          conditions: [
            NarrativeEventCondition.narrativeEventConsumed(
              productRoutePortEventId,
              false,
            ),
          ],
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.setScene(
          projectPath: fixture.projectPath,
          eventId: eventId,
          sceneId: 'scene_action',
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.setReusePolicy(
          projectPath: fixture.projectPath,
          eventId: eventId,
          reusePolicy: NarrativeEventReusePolicy.reusable,
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.setPriority(
          projectPath: fixture.projectPath,
          eventId: eventId,
          priority: 7,
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.setOrder(
          projectPath: fixture.projectPath,
          eventId: eventId,
          order: 17,
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.publish(
          projectPath: fixture.projectPath,
          eventId: eventId,
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.setEnabled(
          projectPath: fixture.projectPath,
          eventId: eventId,
          enabled: true,
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );

      final reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final record = reopened.context.registryOrNull!.records.singleWhere(
        (candidate) => candidate.id == eventId,
      );
      final definition = record.definitionOrNull!;
      expect(definition.name, 'Passage secret révélé');
      expect(definition.source, source);
      expect(definition.conditions.single.toJson(), {
        'kind': 'narrativeEventConsumed',
        'eventId': productRoutePortEventId,
        'expectedValue': false,
      });
      expect(definition.sceneId, 'scene_action');
      expect(definition.reusePolicy, NarrativeEventReusePolicy.reusable);
      expect(definition.priority, 7);
      expect(definition.order, 17);
      expect(record.enabledOrNull, isTrue);
    });

    test('rejects mutation of an enabled Event until it is disabled', () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: gateway,
      );

      final result = await useCase.setScene(
        projectPath: fixture.projectPath,
        eventId: productRoutePortEventId,
        sceneId: 'scene_rival',
        environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
      );

      expect(result.status, NarrativeEventBuilderV2WriteStatus.rejected);
      expect(result.code, 'mustDisableFirst');
      expect(gateway.persistCalls, 0);
    });
  });
}

final class _FailOnSecondGateway
    implements NarrativeEventRegistryPersistenceGateway {
  _FailOnSecondGateway(this.delegate);

  final NarrativeEventRegistryPersistenceGateway delegate;
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    persistCalls++;
    if (persistCalls == 2) {
      return Future.value(
        NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.staleRevision,
          code: 'staleRevision',
          message: 'Le projet a changé pendant la création.',
        ),
      );
    }
    return delegate.persist(request);
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) =>
      delegate.inspectRecovery(projectPath);

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) =>
      delegate.recover(projectPath);

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) =>
      delegate.undo(undoPath);
}

final class _RecordingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  _RecordingGateway({this.persistResult});

  final NarrativeEventRegistryPersistenceResult? persistResult;
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
    return persistResult ??
        NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.committed,
          code: 'committed',
          message: 'Enregistré.',
        );
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) async {
    return NarrativeEventRegistryRecoveryInspection(
      status: NarrativeEventRegistryRecoveryGateStatus.clear,
      issues: const [],
    );
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) async =>
      const [];

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) async {
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.noOp,
      code: 'noOp',
      message: 'Aucune annulation.',
    );
  }
}
```

## Annexe — contenu complet: packages/map_editor/test/ui/canvas/event_builder_v2_creation_flow_test.dart

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import '../../support/event_builder_v2_product_route_fixture.dart';

void main() {
  group('NS-EVENT-V2 Phase 2 H3/H4/H5 creation and editing flow', () {
    testWidgets(
        'cancel writes nothing, Enter saves a draft, and the route reopens it',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );
      final initialMapBytes = await _readBytes(
        tester,
        '${fixture.root.path}/maps/port.json',
      );

      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        readModelLoader: (_) => _reloadReadModel(fixture),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-new-event')),
      );

      await tester.tap(
        find.byKey(const ValueKey('event-builder-v2-new-event')),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-creation-sheet')),
      );
      await tester.enterText(
        _textFieldInside(
          find.byKey(const ValueKey('event-builder-v2-create-name')),
        ),
        'Annulation sans écriture',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(
        (await _readProject(tester, fixture)).eventRegistry!.records,
        hasLength(5),
      );

      await tester.tap(
        find.byKey(const ValueKey('event-builder-v2-new-event')),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-creation-sheet')),
      );
      await tester.enterText(
        _textFieldInside(
          find.byKey(const ValueKey('event-builder-v2-create-name')),
        ),
        'Brouillon clavier',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-creation-sheet')),
        absent: true,
      );
      await pumpEventBuilderV2ProductRouteFrames(tester, count: 4);
      await _waitFor(tester, find.text('Brouillon clavier'));

      final project = await _readProject(tester, fixture);
      final created = project.eventRegistry!.records.singleWhere(
        (record) => record.draftOrNull?.name == 'Brouillon clavier',
      );
      expect(created.draftOrNull?.source, isNull);
      expect(find.text('Brouillon clavier'), findsWidgets);
      expect(
        await _readBytes(tester, '${fixture.root.path}/maps/port.json'),
        initialMapBytes,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'edits source, ordered conditions, Scene, behavior, publication and activation',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );
      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        readModelLoader: (_) => _reloadReadModel(fixture),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-new-event')),
      );
      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRouteDraftEventId',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Choisir un élément').first);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-source-sheet')),
      );
      await tester.tap(find.text('Enregistrer le déclencheur'));
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-source-sheet')),
        absent: true,
      );
      await _refresh(tester);
      await _selectDraft(tester);

      await tester.tap(find.text('Ajouter une condition').first);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-conditions-sheet')),
      );
      await tester.tap(find.text('Ajouter à la liste'));
      await tester.tap(find.text('Ajouter à la liste'));
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey('event-builder-v2-toggle-condition-1'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey('event-builder-v2-move-condition-up-1'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey('event-builder-v2-delete-condition-1'),
        ),
      );
      await tester.tap(find.text('Enregistrer les conditions'));
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-conditions-sheet')),
        absent: true,
      );
      await _refresh(tester);
      await _selectDraft(tester);

      await tester.tap(find.text('Choisir une Scene').first);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-scene-sheet')),
      );
      await tester.tap(find.text('Aucune Scene').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duel du rival').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer la Scene'));
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-scene-sheet')),
        absent: true,
      );
      await _refresh(tester);
      await _selectDraft(tester);

      await _openBehavior(tester);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-behavior-sheet')),
      );
      await tester.tap(find.text('Décider plus tard').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Une seule fois').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        _labelledTextField('Priorité'),
        '7',
      );
      await tester.enterText(
        _labelledTextField('Ordre d’évaluation'),
        '3',
      );
      await tester.tap(find.text('Enregistrer').last);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-behavior-sheet')),
        absent: true,
      );
      await _refresh(tester);
      await _selectDraft(tester);

      await _openBehavior(tester);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-behavior-sheet')),
      );
      await tester.tap(find.text('Publier désactivé').last);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-behavior-sheet')),
        absent: true,
      );
      await _refresh(tester);
      await _selectDraft(tester);

      await _openBehavior(tester);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-behavior-sheet')),
      );
      await tester.tap(find.text('Activer').last);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-behavior-sheet')),
        absent: true,
      );

      final project = await _readProject(tester, fixture);
      final record = project.eventRegistry!.records.singleWhere(
        (candidate) => candidate.id == productRouteDraftEventId,
      );
      final definition = record.definitionOrNull!;
      expect(definition.source, isNotNull);
      expect(definition.conditions, hasLength(1));
      expect(
        definition.conditions.single,
        NarrativeEventCondition.fact('fact_port_open', false),
      );
      expect(definition.sceneId, 'scene_rival');
      expect(definition.reusePolicy, NarrativeEventReusePolicy.oneShot);
      expect(definition.priority, 7);
      expect(definition.order, 3);
      expect(record.enabledOrNull, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Space activates the focused draft action and announces saving',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );
      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        readModelLoader: (_) => _reloadReadModel(fixture),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-new-event')),
      );
      await tester.tap(
        find.byKey(const ValueKey('event-builder-v2-new-event')),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-creation-sheet')),
      );
      await tester.enterText(
        _textFieldInside(
          find.byKey(const ValueKey('event-builder-v2-create-name')),
        ),
        'Brouillon espace',
      );
      for (var index = 0; index < 4; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('event-builder-v2-saving')),
        findsOneWidget,
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-creation-sheet')),
        absent: true,
      );

      final names = (await _readProject(tester, fixture))
          .eventRegistry!
          .records
          .map((record) => record.draftOrNull?.name)
          .whereType<String>();
      expect(names.where((name) => name == 'Brouillon espace'), hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });
}

Future<NarrativeEventBuilderProjectReadModel> _reloadReadModel(
  EventBuilderV2ProductRouteFixture fixture,
) async {
  final session = await NarrativeEventAuthoringSession.prepare(
    fixture.projectPath,
  );
  return buildNarrativeEventBuilderProjectReadModel(
    project: session.manifest,
    maps: session.maps,
  );
}

Future<ProjectManifest> _readProject(
  WidgetTester tester,
  EventBuilderV2ProductRouteFixture fixture,
) async {
  final project = await tester.runAsync(() async {
    final json = jsonDecode(await File(fixture.projectPath).readAsString());
    return ProjectManifest.fromJson((json as Map).cast<String, dynamic>());
  });
  if (project == null) throw TestFailure('Project bytes were not read.');
  return project;
}

Future<List<int>> _readBytes(WidgetTester tester, String path) async {
  final bytes = await tester.runAsync(() => File(path).readAsBytes());
  if (bytes == null) throw TestFailure('File bytes were not read: $path');
  return bytes;
}

Finder _textFieldInside(Finder parent) => find.descendant(
      of: parent,
      matching: find.byType(TextField),
    );

Finder _labelledTextField(String label) {
  final field = find.ancestor(
    of: find.text(label),
    matching: find.byType(PokeMapTextField),
  );
  return _textFieldInside(field);
}

Future<void> _refresh(WidgetTester tester) async {
  await pumpEventBuilderV2ProductRouteFrames(tester, count: 4);
  await _waitFor(
    tester,
    find.byKey(const ValueKey('event-builder-v2-new-event')),
  );
}

Future<void> _selectDraft(WidgetTester tester) async {
  final draft = find.byKey(
    const ValueKey('event-builder-v2-event-v2:$productRouteDraftEventId'),
  );
  await _waitFor(tester, draft);
  await tester.tap(draft);
  await tester.pump();
}

Future<void> _openBehavior(WidgetTester tester) async {
  final action = find.text('Modifier').first;
  await _waitFor(tester, action);
  await tester.ensureVisible(action);
  await tester.pump();
  await tester.tap(action);
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  bool absent = false,
}) async {
  for (var attempt = 0; attempt < 1000; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    final matched = finder.evaluate().isNotEmpty;
    if (absent ? !matched : matched) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .where((value) => value.trim().isNotEmpty)
      .join(' | ');
  throw TestFailure(
    '${absent ? 'Widget remained visible.' : 'Widget never became visible.'} '
    'Visible text: $visibleText',
  );
}
```

## Annexe — contenu complet: packages/map_editor/test/ui/canvas/event_builder_v2_accessibility_test.dart

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import '../../support/event_builder_v2_product_route_fixture.dart';
import '../../support/event_builder_v2_visual_harness.dart';

void main() {
  group('NS-EVENT-V2 Phase 2 H5 states and accessibility', () {
    testWidgets('shows loading then the complete workspace', (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );
      final loading = Completer<NarrativeEventBuilderProjectReadModel>();

      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        readModelLoader: (_) => loading.future,
      );

      expect(
        find.byKey(const ValueKey('event-builder-v2-product-loading')),
        findsOneWidget,
      );
      loading.complete(fixture.readModel);
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('event-builder-v2-new-event')),
        findsOneWidget,
      );
    });

    testWidgets('missing source opens a real repair picker', (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );
      await pumpEventBuilderV2ProductRoute(tester, fixture: fixture);

      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRouteMissingEventId',
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Rebrancher l’élément').first);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-source-sheet')),
      );

      expect(find.text('Choisir le déclencheur'), findsOneWidget);
      expect(find.text('Enregistrer le déclencheur'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('event-builder-v2-source-sheet')),
        findsNothing,
      );
    });

    for (final scenario in const [
      (
        NarrativeEventRegistryPersistenceStatus.staleRevision,
        'staleRevision',
        'Le projet a changé.',
        'Une version plus récente existe',
      ),
      (
        NarrativeEventRegistryPersistenceStatus.recoveryRequired,
        'recoveryRequired',
        'Une écriture interrompue doit être récupérée.',
        'Rechargement nécessaire',
      ),
    ]) {
      testWidgets('surfaces ${scenario.$2} with a recovery action',
          (tester) async {
        final fixture = await createEventBuilderV2ProductRouteFixture(
          tester,
          mode: EventSystemMode.v2Only,
        );
        await pumpEventBuilderV2ProductRoute(
          tester,
          fixture: fixture,
          persistenceGateway: _FixedPersistenceGateway(
            NarrativeEventRegistryPersistenceResult(
              status: scenario.$1,
              code: scenario.$2,
              message: scenario.$3,
            ),
          ),
        );
        await tester.tap(
          find.byKey(const ValueKey('event-builder-v2-new-event')),
        );
        await _waitFor(
          tester,
          find.byKey(const ValueKey('event-builder-v2-creation-sheet')),
        );
        await tester.enterText(
          find.descendant(
            of: find.byKey(
              const ValueKey('event-builder-v2-create-name'),
            ),
            matching: find.byType(TextField),
          ),
          'Écriture interrompue',
        );
        await tester.tap(
          find.byKey(const ValueKey('event-builder-v2-save-draft')),
        );
        await _waitFor(tester, find.text(scenario.$4));

        expect(find.text('Enregistrement interrompu'), findsOneWidget);
        expect(find.text('Recharger les événements'), findsOneWidget);
      });
    }

    testWidgets('supports 1280 at 125 percent text scale', (tester) async {
      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: const Size(1280, 941),
        textScaleFactor: 1.25,
      );

      expect(find.text('Rencontre rival au port'), findsWidgets);
      expect(find.text('DÉCLENCHEUR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps Tab and Shift+Tab inside and restores focus on Escape',
        (tester) async {
      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: const Size(1440, 941),
      );
      await tester.tap(find.text('Ouvrir la bibliothèque'));
      await tester.pumpAndSettle();

      for (var index = 0; index < 5; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focusIsInsideSideSheet(), isTrue);
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(_focusIsInsideSideSheet(), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      final launcher = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('event-builder-v2-open-library')),
      );
      expect(launcher.focusNode!.hasFocus, isTrue);
      expect(find.byType(PokeMapDesktopSideSheet), findsNothing);
    });
  });
}

final class _FixedPersistenceGateway
    implements NarrativeEventRegistryPersistenceGateway {
  const _FixedPersistenceGateway(this.result);

  final NarrativeEventRegistryPersistenceResult result;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async =>
      result;

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) async {
    return NarrativeEventRegistryRecoveryInspection(
      status: NarrativeEventRegistryRecoveryGateStatus.clear,
      issues: const [],
    );
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) async =>
      const [];

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) async {
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.noOp,
      code: 'noOp',
      message: 'Aucune annulation.',
    );
  }
}

bool _focusIsInsideSideSheet() {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return false;
  if (focusContext.widget is PokeMapDesktopSideSheet) return true;
  var found = false;
  (focusContext as Element).visitAncestorElements((ancestor) {
    found = ancestor.widget is PokeMapDesktopSideSheet;
    return !found;
  });
  return found;
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 400; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  throw TestFailure('Expected widget did not appear.');
}
```

## Annexe — contenu complet: packages/map_editor/test/ui/design_system/pokemap_text_field_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('text field exposes label, validation and keyboard submit',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var submitted = '';

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: PokeMapTextField(
              label: 'Nom de l’événement',
              controller: controller,
              hintText: 'Rencontre au port',
              errorText: 'Le nom est obligatoire.',
              onSubmitted: (value) => submitted = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nom de l’événement'), findsOneWidget);
    expect(find.text('Le nom est obligatoire.'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Nom de l’événement' &&
            widget.properties.textField == true,
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Rencontre au port');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, 'Rencontre au port');
    expect(tester.takeException(), isNull);
  });
}
```
