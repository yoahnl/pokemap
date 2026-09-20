# AS-UI-008 — Événements et déclencheurs

Livraison locale du 20 septembre 2026. Validation visuelle attendue. Aucun commit, push, changement de branche, écriture Notion ou modification de projet personnel original.

## Résultat et accès

Dans Avelune Studio : ouvrir un projet, puis **Histoire → Événements**. La page relie une source réelle, une expression de conditions et une scène complète. L’événement conserve une référence de scène : ses actions ne sont pas recopiées.

Les quatre sources sont disponibles : interaction avec une entité, entrée de zone, entrée de carte et réception d’un résultat identifié par son producteur et son résultat. La sélection spatiale utilise la vraie carte en consultation, avec déplacement, zoom, cibles compatibles et annulation. Les brouillons, configuration, activation différée, réemploi, réarmement, priorité et ordre utilisent les opérations canoniques.

Bibliothèque recherchable et filtrable ; événements historiques consultables sans conversion, chargement complémentaire des cartes explicite. Conditions booléennes, entières, chaînes et consommation d’événement, groupes ALL/ANY/NOT conservés. Scènes UI06 ouvertes sans conversion simplifiée ; retour au même événement et conservation des brouillons Carte/scène. Simulation canonique isolée, publication puis relecture indépendante et tests du runtime réel.

Pour lancer depuis le dépôt :

```sh
cd apps/avelune_studio
flutter run -d macos --no-pub
```

## Audit initial et choix de réemploi

État initial : branche `main`, HEAD `142873528400790ab59c3fdba5ab4d5e3cd65aa3`, arbre propre. Le pack UI08 et ses annexes ont été lus ; la maquette 04 a été réellement ouverte avant implémentation puis comparée aux captures.

Réemploi : modèles Event V2, catalogues spatiaux/résultats, conditions typées et dispatcher dans map_core ; transactions ciblées map_authoring ; sessions narratives/UI06/UI07 ; cartes, renderer et caches Studio ; composants et tokens Avelune. Aucun moteur de production ni dépendance/native config modifié. map_runtime reçoit uniquement deux fichiers de tests.

Risques traités : registre périmé, conflit du simplifié avec scène/événement complet, suppression/réapparition d’une session propre, publication différée, saisie encore focalisée, événement A sélectionné puis remplacé par B pendant un chargement, homonymes de cibles/producteurs, conservation des expressions imbriquées.

Adaptations volontaires au dessin : quatre déclencheurs réellement supportés ; pas de chronomètre/contact/variable inventés, pas d’onglet Actions dupliquant UI06, pas d’historique d’activité fictif. Activation préparée puis publiée explicitement. L’illustration de gare n’est pas intégrée dans le produit : les captures montrent le renderer avec une carte temporaire de démonstration.

## Vérifications et preuves

- [Suite Studio finale](logs/studio-suite-final.txt) : `06:06 +475 ~2: All tests passed!`, code 0. Deux tests conditionnels ignorés, sans nouveau skip.
- [Dernière passe et captures](logs/final-captures-context.txt) : `00:30 +9: All tests passed!`, code 0. Après la suite complète, ajout d’un test de redimensionnement et correction ciblée du contexte : même point de carte centré, zoom conservé. Les six tests de contexte et trois parcours UI08 ont été rejoués sur cet état final, puis les sept captures régénérées. Analyse et build ont également été rejoués après ce correctif ; la suite complète n’a pas été répétée.
- [Analyse Studio](logs/studio-analyze.txt) : `No issues found!`.
- [Build macOS](logs/studio-build-macos.txt) : `✓ Built build/macos/Build/Products/Debug/Avelune Studio.app`.
- [Contrats core](logs/core-events-contracts.txt) : 76 tests réussis.
- [Runtime](logs/runtime-ui08.txt) : 16 tests réussis, dont trois nouvelles traversées UI08. Vrais dialogues Yarn lus sur disque, exécution de scènes et résultats distribués par le runtime, consommation/réemploi et sauvegardes isolées. Les tests de raccordement avec runtimeBuilder témoin sont séparés dans [event-playtest](logs/event-playtest.txt).
- [Authoring](logs/authoring-modern-events.txt) : 11 tests réussis. [Transport MCP Event V2](logs/mcp-event-v2.txt) : 1 réussi ; build/check MCP réussis.
- [Parcours UI](logs/ui08-widget-paths.txt) : création, choix explicite, condition guidée, UI06, brouillons, activation, publication et relecture indépendante, mode mixte explicite, simulation et retours. [Tests source lente](logs/source-loading.txt) : aucune cible périmée cliquable pendant le chargement A→B.
- [Coexistence](logs/coexistence-regressions.txt) : 60 tests réussis ; [publication backend](logs/backend-final.txt) : 28 tests réussis ; [consultation historique](logs/legacy-consultation-tests.txt) : 3 réussis.
- [Conditions et contexte](logs/ui-audit-tests.txt) : 10 tests réussis (ALL/ANY/NOT, coordonnées après transformation, source absente, concurrence, nombres invalides, essais isolés).
- Lecture mesurée dans `event_catalog_ui08_test.dart` : une lecture initiale de carte, deux après préparation explicite, toujours deux après 30 accès au catalogue et une nouvelle préparation inchangée. Aucune promesse de zéro E/S pour une carte non chargée.
- Tous les nouveaux/modifiés fichiers Dart sont limités à 300 lignes. Reçus JSON : commandes, codes de sortie, PID du runner/descendants et nettoyage des seuls processus possédés.

La [première suite complète](logs/studio-suite.txt) a échoué sur un diagnostic UI06 devenu trop générique, deux assertions UI08 de libellés et un délai E/S du stress. Le diagnostic a été rétabli sans affaiblir la protection, les assertions ont conservé leurs garanties de comportement, et [le stress a réussi isolément](logs/studio-regressions-isolated.txt) sans hausse du délai. Les journaux intermédiaires sont conservés ; ils ne sont pas présentés comme résultats finaux.

## Captures non retouchées

Rendu Flutter hors écran des vrais widgets, avec adaptateurs disque sur fixtures temporaires. Ce ne sont ni une maquette recomposée, ni une preuve de manipulation native. Formats vérifiés : 1536×1024, 1440×900, 1280×800, 1024×640 à 150 % ; composition initiale à 1584×994 pour comparaison de la cible.

1. [Composition générale](captures/01-evenements-composition.png).
2. [Choix de source sur la carte](captures/02-choix-source-carte.png).
3. [Conditions lisibles](captures/03-conditions-lisibles.png).
4. [Retour de scène et brouillons](captures/04-retour-scene-brouillons.png).
5. [Événement configuré](captures/05-evenement-configure.png).
6. [Simulation canonique réelle](captures/06-simulation-canonique.png).
7. [Format compact, texte à 150 %](captures/07-compact-texte150.png).

Comparaison : navigation Avelune conservée, trois colonnes, bibliothèque gauche, source et grande carte centrale, résumé droit. La première passe a conduit à agrandir le titre et remplacer l’identifiant brut de cible par son nom et sa position. Le résumé final décrit aussi les dialogues, résultats et conséquences possibles de la scène, sans prétendre qu’une branche sera nécessairement exécutée. La densité des données et le décor de fixture diffèrent de l’illustration riche de la cible ; appréciation visuelle à confirmer par Yoahn.

En format compact, bibliothèque/résumé deviennent des vues secondaires et la barre d’actions défile horizontalement. L’aperçu est réduit en hauteur ; le bouton « Cadrer la carte » permet de retrouver l’ensemble de la carte après déplacement ou zoom. La capture compacte a été réellement rouverte après correction du recentrage.

## Passes et verdicts

Trois agents ont travaillé avec le root ; les rôles demandés par codex_rule.md ont été couverts par ces agents et des passes distinctes :

- Audit/Architecture : contrats et frontières conservés ; catalogue préparé sur action explicite, moteur non dupliqué.
- Implémentation : backend événements et coexistence simplifiée, puis page/raccordements ; transactions et brouillons testés.
- Tests : agent coexistence pour parcours UI, agent runtime pour exécution réelle, conditions et contexte ; résultats ci-dessus.
- Build/Validation : root, analyse et build macOS réussis ; instrumentation native absente.
- Critique finale indépendante : trois risques confirmés corrigés (FutureBuilder conservant la carte précédente, localisation tardive après changement d’événement, rechargement échoué effaçant l’erreur locale). Tests de chargement tardif verts. Libellé de politique de réemploi indéfinie rendu fidèle.

La règle « aucun commentaire ajouté au code manuel » du mandat actif a priorité sur l’ancienne préférence inverse de codex_rule.md. Les explications sont centralisées ici.

## Limites et autocritique

- Manipulation native **non vérifiée** : [préflight](logs/native-preflight.json), macOS disponible mais dépendances et entrée Marionette absentes. Aucun ajout de dépendance/SDK n’a été fait.
- MCP live indisponible : [réponse](logs/mcp-live-describe.json), `worker.exited` code 78. Build, vérification et transport ciblé réussis, mais ce n’est pas une vérification du catalogue live.
- Parité de simulation MCP **PARTIAL** : la page appelle la simulation canonique core ; aucune query/action de simulation n’est exposée par map_authoring. Les mutations Event V2 utilisent déjà le contrat authoring existant.
- Les changements externes sur disque ne sont pas surveillés en continu. Publication contrôlée sur état frais ; la simulation annonce le snapshot en mémoire et ne lit pas une sauvegarde personnelle.
- Le mode moderne peut être refusé par le contrat si des sources historiques resteraient actives. Le parcours de test confirme le mode mixte explicite sans contourner ce refus.
- Deux tests Studio conditionnels requièrent une copie externe via `AVELUNE_PROJECT_COPY` ; ils restent ignorés sans cette variable, sans nouveau skip.
- Les couleurs/logo/cadre existants sont conservés. L’esthétique sur un projet riche et le pilotage natif ne sont pas validés par la petite carte de test.
- Aucune validation distante CI/release ni validation visuelle utilisateur revendiquée. UI09 non commencé.

## Inventaire technique complet

Chemins relatifs au dépôt ; les zones identifient les composants/classes à relire. Les diffs Git et fichiers sont la preuve canonique, aucune copie intégrale des sources ici.

<details>
<summary>83 fichiers Dart créés ou modifiés</summary>

| Fichier | Zones | Raison et impact |
| --- | --- | --- |
| [apps/avelune_studio/lib/app/di/event_providers.dart](../../../../apps/avelune_studio/lib/app/di/event_providers.dart) | fonctions et raccordements | injection du port et accès dans le cadre Avelune |
| [apps/avelune_studio/lib/features/events/application/event_publication_order.dart](../../../../apps/avelune_studio/lib/features/events/application/event_publication_order.dart) | EventPublicationOrder (L3) | sessions, opérations et publication Event V2 |
| [apps/avelune_studio/lib/features/events/application/event_workspace_catalog.dart](../../../../apps/avelune_studio/lib/features/events/application/event_workspace_catalog.dart) | EventWorkspaceCatalog (L3) | sessions, opérations et publication Event V2 |
| [apps/avelune_studio/lib/features/events/application/event_workspace_commands.dart](../../../../apps/avelune_studio/lib/features/events/application/event_workspace_commands.dart) | EventWorkspaceCommands (L3) | sessions, opérations et publication Event V2 |
| [apps/avelune_studio/lib/features/events/application/event_workspace_controller.dart](../../../../apps/avelune_studio/lib/features/events/application/event_workspace_controller.dart) | EventWorkspaceController (L12) | sessions, opérations et publication Event V2 |
| [apps/avelune_studio/lib/features/events/application/event_workspace_publication.dart](../../../../apps/avelune_studio/lib/features/events/application/event_workspace_publication.dart) | EventWorkspacePublication (L3) | sessions, opérations et publication Event V2 |
| [apps/avelune_studio/lib/features/events/data/local_event_adapter.dart](../../../../apps/avelune_studio/lib/features/events/data/local_event_adapter.dart) | LocalEventAdapter (L11) | transaction canonique et contrôle de concurrence |
| [apps/avelune_studio/lib/features/events/domain/event_port.dart](../../../../apps/avelune_studio/lib/features/events/domain/event_port.dart) | EventFailure (L12) | contrats du port et lecture du record |
| [apps/avelune_studio/lib/features/events/domain/event_record_view.dart](../../../../apps/avelune_studio/lib/features/events/domain/event_record_view.dart) | EventRecordView (L3) | contrats du port et lecture du record |
| [apps/avelune_studio/lib/features/narrative/application/narrative_interaction_loading.dart](../../../../apps/avelune_studio/lib/features/narrative/application/narrative_interaction_loading.dart) | NarrativeInteractionLoading (L3) | coexistence avec l’éditeur simplifié, bases et récupération |
| [apps/avelune_studio/lib/features/narrative/application/narrative_session_coexistence.dart](../../../../apps/avelune_studio/lib/features/narrative/application/narrative_session_coexistence.dart) | NarrativeSessionCoexistence (L3) | coexistence avec l’éditeur simplifié, bases et récupération |
| [apps/avelune_studio/lib/features/narrative/application/narrative_workspace_publication.dart](../../../../apps/avelune_studio/lib/features/narrative/application/narrative_workspace_publication.dart) | NarrativeWorkspacePublication (L3) | coexistence avec l’éditeur simplifié, bases et récupération |
| [apps/avelune_studio/lib/features/narrative/data/narrative_publication_baselines.dart](../../../../apps/avelune_studio/lib/features/narrative/data/narrative_publication_baselines.dart) | fonctions et raccordements | coexistence avec l’éditeur simplifié, bases et récupération |
| [apps/avelune_studio/lib/presentation/features/events/event_condition_dialog.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_condition_dialog.dart) | _ConditionDialog (L19), _ConditionDialogState (L32) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_condition_labels.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_condition_labels.dart) | fonctions et raccordements | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_conditions.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_conditions.dart) | EventConditions (L9) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_context_map.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_context_map.dart) | EventContextMap (L10), _EventContextMapState (L37) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_labels.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_labels.dart) | fonctions et raccordements | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_legacy_catalog.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_legacy_catalog.dart) | EventLegacyEntry (L4), EventLegacyDetail (L16), EventLegacyCatalog (L26) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_legacy_detail.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_legacy_detail.dart) | fonctions et raccordements | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_library.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_library.dart) | EventLibrary (L14), _EventLibraryState (L44) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_map_loader.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_map_loader.dart) | EventMapLoader (L4) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_options_panel.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_options_panel.dart) | EventOptionsPanel (L11) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_outcome_picker.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_outcome_picker.dart) | EventOutcomeSummary (L49) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_page_content.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_page_content.dart) | EventPageContent (L13) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_playtest.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_playtest.dart) | fonctions et raccordements | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_registry_dialog.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_registry_dialog.dart) | fonctions et raccordements | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_scene_effects.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_scene_effects.dart) | fonctions et raccordements | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_scene_panel.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_scene_panel.dart) | EventScenePanel (L7) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_simulation_dialog.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_simulation_dialog.dart) | _Simulation (L20), _SimulationState (L28) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_source_identity.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_source_identity.dart) | EventSourceIdentity (L6), _EventSourceIdentityState (L18) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_summary.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_summary.dart) | EventSummary (L12) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_trigger_panel.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_trigger_panel.dart) | EventTriggerPanel (L17), _EventTriggerPanelState (L39) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_view_state.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_view_state.dart) | EventTab (L3), EventViewState (L5) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_workspace_layout.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_workspace_layout.dart) | _EventWorkspaceLayout (L3) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/events/event_workspace_page.dart](../../../../apps/avelune_studio/lib/presentation/features/events/event_workspace_page.dart) | EventWorkspacePage (L27), _EventWorkspacePageState (L53) | composition UI08, interaction et contexte en lecture seule |
| [apps/avelune_studio/lib/presentation/features/map_workspace/workspace_event_binding.dart](../../../../apps/avelune_studio/lib/presentation/features/map_workspace/workspace_event_binding.dart) | _WorkspaceEventBinding (L3) | raccordement UI08, retours et barrières de sauvegarde/test |
| [apps/avelune_studio/test/events/event_catalog_ui08_test.dart](../../../../apps/avelune_studio/test/events/event_catalog_ui08_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/events/event_flush_ui08_test.dart](../../../../apps/avelune_studio/test/events/event_flush_ui08_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/events/event_publication_ui08_test.dart](../../../../apps/avelune_studio/test/events/event_publication_ui08_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/events/event_recovery_ui08_test.dart](../../../../apps/avelune_studio/test/events/event_recovery_ui08_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/events/event_sources_ui08_test.dart](../../../../apps/avelune_studio/test/events/event_sources_ui08_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/events/event_workspace_ui08_test.dart](../../../../apps/avelune_studio/test/events/event_workspace_ui08_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/events_ui08_conditions_simulation_test.dart](../../../../apps/avelune_studio/test/events_ui08_conditions_simulation_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/events_ui08_legacy_consultation_test.dart](../../../../apps/avelune_studio/test/events_ui08_legacy_consultation_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/events_ui08_map_context_test.dart](../../../../apps/avelune_studio/test/events_ui08_map_context_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/events_ui08_source_loading_test.dart](../../../../apps/avelune_studio/test/events_ui08_source_loading_test.dart) | _DelayedPreviewLoader (L171) | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/narrative/interaction_event_coexistence_ui08_test.dart](../../../../apps/avelune_studio/test/narrative/interaction_event_coexistence_ui08_test.dart) | _MapPort (L181), _NarrativePort (L195) | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/narrative/interaction_event_publication_ui08_test.dart](../../../../apps/avelune_studio/test/narrative/interaction_event_publication_ui08_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/narrative/interaction_event_roundtrip_ui08_test.dart](../../../../apps/avelune_studio/test/narrative/interaction_event_roundtrip_ui08_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/presentation/ui08_event_focus_test.dart](../../../../apps/avelune_studio/test/presentation/ui08_event_focus_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/presentation/ui08_event_journey_test.dart](../../../../apps/avelune_studio/test/presentation/ui08_event_journey_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/presentation/ui08_event_playtest_test.dart](../../../../apps/avelune_studio/test/presentation/ui08_event_playtest_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/presentation/ui08_event_sources_test.dart](../../../../apps/avelune_studio/test/presentation/ui08_event_sources_test.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/support/delayed_event_port.dart](../../../../apps/avelune_studio/test/support/delayed_event_port.dart) | DelayedEventPort (L6) | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/support/event_backend_fixture.dart](../../../../apps/avelune_studio/test/support/event_backend_fixture.dart) | EventBackendFixture (L11) | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/support/event_playtest_harness.dart](../../../../apps/avelune_studio/test/support/event_playtest_harness.dart) | EventPlaytestHarness (L15), EventTestReadPort (L94) | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/support/ui08_event_fixture.dart](../../../../apps/avelune_studio/test/support/ui08_event_fixture.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/support/ui08_journey_driver.dart](../../../../apps/avelune_studio/test/support/ui08_journey_driver.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/test/support/ui08_workspace_harness.dart](../../../../apps/avelune_studio/test/support/ui08_workspace_harness.dart) | Ui08WorkspaceHarness (L21), Ui08MapPort (L100), Ui08EventPort (L142) | preuve automatisée ou fixture isolée |
| [packages/map_runtime/test/support/ui08_event_runtime_fixture.dart](../../../../packages/map_runtime/test/support/ui08_event_runtime_fixture.dart) | tests et cas de régression | preuve automatisée ou fixture isolée |
| [packages/map_runtime/test/ui08_event_runtime_journey_test.dart](../../../../packages/map_runtime/test/ui08_event_runtime_journey_test.dart) | _LoadedGame (L189) | preuve automatisée ou fixture isolée |
| [apps/avelune_studio/lib/app/di/providers.dart](../../../../apps/avelune_studio/lib/app/di/providers.dart) | fonctions et raccordements | injection du port et accès dans le cadre Avelune |
| [apps/avelune_studio/lib/app/studio_bootstrap.dart](../../../../apps/avelune_studio/lib/app/studio_bootstrap.dart) | StudioBootstrap (L21) | injection du port et accès dans le cadre Avelune |
| [apps/avelune_studio/lib/features/narrative/application/interaction_edit_session.dart](../../../../apps/avelune_studio/lib/features/narrative/application/interaction_edit_session.dart) | InteractionEditState (L6), InteractionEditSession (L12) | coexistence avec l’éditeur simplifié, bases et récupération |
| [apps/avelune_studio/lib/features/narrative/application/narrative_interaction_opener.dart](../../../../apps/avelune_studio/lib/features/narrative/application/narrative_interaction_opener.dart) | NarrativeInteractionOpener (L15) | coexistence avec l’éditeur simplifié, bases et récupération |
| [apps/avelune_studio/lib/features/narrative/application/narrative_workspace_controller.dart](../../../../apps/avelune_studio/lib/features/narrative/application/narrative_workspace_controller.dart) | NarrativeWorkspaceController (L15) | coexistence avec l’éditeur simplifié, bases et récupération |
| [apps/avelune_studio/lib/features/narrative/data/local_narrative_adapter.dart](../../../../apps/avelune_studio/lib/features/narrative/data/local_narrative_adapter.dart) | LocalNarrativeAdapter (L15) | coexistence avec l’éditeur simplifié, bases et récupération |
| [apps/avelune_studio/lib/features/narrative/data/local_narrative_catalog_transaction.dart](../../../../apps/avelune_studio/lib/features/narrative/data/local_narrative_catalog_transaction.dart) | LocalNarrativeCatalogTransaction (L11), NarrativeCatalogFailure (L144) | coexistence avec l’éditeur simplifié, bases et récupération |
| [apps/avelune_studio/lib/features/narrative/domain/narrative_port.dart](../../../../apps/avelune_studio/lib/features/narrative/domain/narrative_port.dart) | NarrativeDialogueSource (L5), NarrativePublication (L16), NarrativePublicationReceipt (L49), NarrativeFailure (L71) | coexistence avec l’éditeur simplifié, bases et récupération |
| [apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_screen.dart](../../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_screen.dart) | MapWorkspaceScreen (L45), _MapWorkspaceScreenState (L77) | raccordement UI08, retours et barrières de sauvegarde/test |
| [apps/avelune_studio/lib/presentation/features/map_workspace/workspace_actions.dart](../../../../apps/avelune_studio/lib/presentation/features/map_workspace/workspace_actions.dart) | WorkspaceActions (L17) | raccordement UI08, retours et barrières de sauvegarde/test |
| [apps/avelune_studio/lib/presentation/features/map_workspace/workspace_screen_body.dart](../../../../apps/avelune_studio/lib/presentation/features/map_workspace/workspace_screen_body.dart) | _WorkspaceScreenBody (L3) | raccordement UI08, retours et barrières de sauvegarde/test |
| [apps/avelune_studio/lib/presentation/features/map_workspace/workspace_secondary_content.dart](../../../../apps/avelune_studio/lib/presentation/features/map_workspace/workspace_secondary_content.dart) | WorkspaceSpace (L21) | raccordement UI08, retours et barrières de sauvegarde/test |
| [apps/avelune_studio/lib/presentation/features/map_workspace/workspace_story_binding.dart](../../../../apps/avelune_studio/lib/presentation/features/map_workspace/workspace_story_binding.dart) | _WorkspaceStoryBinding (L3) | raccordement UI08, retours et barrières de sauvegarde/test |
| [apps/avelune_studio/lib/presentation/features/narrative/narrative_interaction_pane.dart](../../../../apps/avelune_studio/lib/presentation/features/narrative/narrative_interaction_pane.dart) | NarrativeInteractionPane (L16) | coexistence avec l’éditeur simplifié, bases et récupération |
| [apps/avelune_studio/lib/presentation/features/narrative/narrative_overview_header.dart](../../../../apps/avelune_studio/lib/presentation/features/narrative/narrative_overview_header.dart) | NarrativeOverviewHeader (L7) | coexistence avec l’éditeur simplifié, bases et récupération |
| [apps/avelune_studio/lib/presentation/features/narrative/narrative_story_pane.dart](../../../../apps/avelune_studio/lib/presentation/features/narrative/narrative_story_pane.dart) | NarrativeStoryPane (L14), _NarrativeStoryPaneState (L38) | coexistence avec l’éditeur simplifié, bases et récupération |
| [apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_commit_field.dart](../../../../apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_commit_field.dart) | StudioCommitField (L3), _StudioCommitFieldState (L20) | extension ciblée du composant partagé |
| [apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_page_header.dart](../../../../apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_page_header.dart) | StudioPageHeader (L3) | extension ciblée du composant partagé |
| [apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_primary_navigation.dart](../../../../apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_primary_navigation.dart) | StudioPrimaryNavigation (L4) | extension ciblée du composant partagé |
| [apps/avelune_studio/lib/presentation/shell/studio_workspace_host.dart](../../../../apps/avelune_studio/lib/presentation/shell/studio_workspace_host.dart) | StudioWorkspaceHost (L9) | injection du port et accès dans le cadre Avelune |
| [apps/avelune_studio/test/narrative/narrative_error_scope_test.dart](../../../../apps/avelune_studio/test/narrative/narrative_error_scope_test.dart) | _Port (L111) | preuve automatisée ou fixture isolée |

</details>

## Commandes conservées

Les commandes Dart/Flutter sont exécutées depuis leur package (Studio, map_core, map_authoring ou map_runtime selon le journal) ; npm/node depuis tools/pokemap_mcp. Chaque journal dispose d’un reçu JSON homonyme. Les essais intermédiaires échoués restent identifiables par leur code.

<details>
<summary>Commandes et codes de sortie</summary>

| Journal | Commande | Code | Résultat observé |
| --- | --- | --- | --- |
| [authoring-modern-events.txt](logs/authoring-modern-events.txt) | `dart test --reporter expanded test/domains/narrative/modern_narrative_authoring_test.dart` | 0 | 00:00 +11: All tests passed! |
| [backend-final.txt](logs/backend-final.txt) | `flutter test --no-pub --reporter expanded test/events test/stories/story_publication_ui07_test.dart test/scenes/scene_publication_ui06_test.dart` | 0 | 00:04 +28: All tests passed! |
| [backend-flush.txt](logs/backend-flush.txt) | `flutter test --no-pub --reporter expanded test/events/event_flush_ui08_test.dart` | 0 | 00:01 +4: All tests passed! |
| [backend-initial.txt](logs/backend-initial.txt) | `flutter test --no-pub --reporter expanded test/events/event_workspace_ui08_test.dart` | 0 | 00:02 +5: All tests passed! |
| [backend-publication.txt](logs/backend-publication.txt) | `flutter test --no-pub --reporter expanded test/events` | 0 | 00:02 +13: All tests passed! |
| [coexistence-analyze.txt](logs/coexistence-analyze.txt) | `dart analyze lib/features/narrative test/narrative` | 0 | No issues found! |
| [coexistence-publication-tests.txt](logs/coexistence-publication-tests.txt) | `flutter test --no-pub --reporter expanded test/narrative/interaction_event_publication_ui08_test.dart` | 0 | 00:02 +3: All tests passed! |
| [coexistence-regressions.txt](logs/coexistence-regressions.txt) | `flutter test --no-pub --reporter expanded test/narrative test/scenes/scene_reconciliation_ui07_test.dart test/presentation/ui07_scene_linked_source_test.dart` | 0 | 00:05 +60: All tests passed! |
| [coexistence-roundtrip.txt](logs/coexistence-roundtrip.txt) | `flutter test --no-pub --reporter expanded test/narrative/interaction_event_roundtrip_ui08_test.dart` | 1 | 00:02 +1 -1: Some tests failed. |
| [coexistence-tests.txt](logs/coexistence-tests.txt) | `flutter test --no-pub --reporter expanded test/narrative/interaction_event_coexistence_ui08_test.dart test/narrative/narrative_navigation_ui05_test.dart test/scenes/scene_reconciliation_ui07_test.dart` | 0 | 00:00 +19: All tests passed! |
| [core-events-contracts.txt](logs/core-events-contracts.txt) | `dart test --reporter expanded test/narrative_event_source_ref_test.dart test/narrative_event_source_authoring_v2_test.dart test/narrative_event_dispatch_authority_test.dart test/narrative_event_configuration_authoring_test.dart test/narrative_event_publication_test.dart` | 0 | 00:00 +76: All tests passed! |
| [event-playtest.txt](logs/event-playtest.txt) | `flutter test --no-pub --reporter expanded test/presentation/ui08_event_playtest_test.dart test/presentation/ui06_scene_playtest_guard_test.dart test/presentation/ui07_story_playtest_guard_test.dart` | 0 | 00:04 +13: All tests passed! |
| [legacy-consultation-analyze.txt](logs/legacy-consultation-analyze.txt) | `dart analyze lib/presentation/features/events/event_library.dart lib/presentation/features/events/event_legacy_catalog.dart lib/presentation/features/events/event_legacy_detail.dart test/events_ui08_legacy_consultation_test.dart` | 0 | No issues found! |
| [legacy-consultation-tests.txt](logs/legacy-consultation-tests.txt) | `flutter test --no-pub --reporter expanded test/events_ui08_legacy_consultation_test.dart` | 0 | 00:01 +3: All tests passed! |
| [mcp-build.txt](logs/mcp-build.txt) | `npm run build` | 0 | voir journal |
| [mcp-check.txt](logs/mcp-check.txt) | `npm run check` | 0 | voir journal |
| [mcp-event-v2.txt](logs/mcp-event-v2.txt) | `node --import tsx --test --test-concurrency=1 --test-name-pattern MCP exposes Event V2 test/mutation_server.test.ts` | 0 | ℹ pass 1 / ℹ fail 0 |
| [native-devices.txt](logs/native-devices.txt) | `flutter devices --machine` | 0 | voir journal |
| [runtime-ui08-analyze.txt](logs/runtime-ui08-analyze.txt) | `dart analyze test/ui08_event_runtime_journey_test.dart test/support/ui08_event_runtime_fixture.dart` | 0 | No issues found! |
| [runtime-ui08.txt](logs/runtime-ui08.txt) | `flutter test --no-pub --reporter expanded test/ui08_event_runtime_journey_test.dart test/playable_map_game_trigger_enter_v2_integration_test.dart test/playable_map_game_dialogue_outcome_scene_integration_test.dart` | 0 | 00:00 +16: All tests passed! |
| [source-loading.txt](logs/source-loading.txt) | `flutter test --no-pub --reporter expanded test/events_ui08_source_loading_test.dart` | 0 | 00:02 +2: All tests passed! |
| [studio-analyze.txt](logs/studio-analyze.txt) | `flutter analyze --no-pub` | 0 | No issues found! (ran in 6.6s) |
| [studio-build-macos.txt](logs/studio-build-macos.txt) | `flutter build macos --debug --no-pub` | 0 | ✓ Built build/macos/Build/Products/Debug/Avelune Studio.app |
| [studio-regressions-isolated.txt](logs/studio-regressions-isolated.txt) | `flutter test --no-pub --reporter expanded --concurrency=1 test/scenes/scene_session_ui06_test.dart test/presentation/desktop_workspace_layout_test.dart` | 0 | 00:25 +10: All tests passed! |
| [studio-suite.txt](logs/studio-suite.txt) | `flutter test --no-pub --reporter expanded` | 1 | 01:56 +471 ~2 -4: Some tests failed. |
| [ui-audit-analyze.txt](logs/ui-audit-analyze.txt) | `dart analyze lib/presentation/features/events/event_context_map.dart lib/presentation/features/events/event_simulation_dialog.dart test/events_ui08_map_context_test.dart test/events_ui08_conditions_simulation_test.dart` | 0 | No issues found! |
| [ui-audit-tests.txt](logs/ui-audit-tests.txt) | `flutter test --no-pub --reporter expanded test/events_ui08_map_context_test.dart test/events_ui08_conditions_simulation_test.dart` | 0 | 00:02 +10: All tests passed! |
| [ui08-focus.txt](logs/ui08-focus.txt) | `flutter test --no-pub --reporter expanded test/presentation/ui08_event_focus_test.dart` | 1 | 00:00 +0 -1: Some tests failed. |
| [ui08-journey.txt](logs/ui08-journey.txt) | `flutter test --no-pub --reporter expanded test/presentation/ui08_event_journey_test.dart` | 0 | 00:12 +1: All tests passed! |
| [ui08-widget-analyze.txt](logs/ui08-widget-analyze.txt) | `dart analyze test/support/ui08_event_fixture.dart test/support/ui08_journey_driver.dart test/support/ui08_workspace_harness.dart test/presentation/ui08_event_focus_test.dart test/presentation/ui08_event_journey_test.dart test/presentation/ui08_event_sources_test.dart` | 0 | No issues found! |
| [ui08-widget-paths.txt](logs/ui08-widget-paths.txt) | `flutter test --no-pub --reporter expanded test/presentation/ui08_event_journey_test.dart test/presentation/ui08_event_focus_test.dart test/presentation/ui08_event_sources_test.dart` | 0 | 00:23 +3: All tests passed! |

</details>

## État final

Travail uniquement dans l’arbre local sur `main` ; HEAD inchangé. Inventaire ci-dessus, captures et journaux sous ce dossier. Aucun fichier de projet personnel original modifié. Aucun statut Notion modifié. Validation visuelle attendue avant toute autre page.

[Intégrité finale](logs/final-integrity.txt) : branche, HEAD, inventaire Git détaillé, `git diff --check` et taille des 83 fichiers Dart contrôlés. [Hygiène Markdown](logs/markdown-hygiene.txt) : code 0, un seul nouveau Markdown dans l’emplacement canonique.

Dernières commandes (depuis `apps/avelune_studio`, sauf hygiène depuis la racine) :

```sh
flutter test --no-pub --reporter expanded --concurrency=1
AVELUNE_CAPTURE_DIR=/Users/karim/Project/pokemonProject/documentation/reports/avelune_studio/UI08_evenements_declencheurs/captures flutter test --no-pub --reporter expanded --concurrency=1 test/events_ui08_map_context_test.dart test/presentation/ui08_event_journey_test.dart test/presentation/ui08_event_focus_test.dart test/presentation/ui08_event_sources_test.dart
flutter analyze --no-pub
flutter build macos --debug --no-pub
POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh
git diff --check
```

Les captures et journaux, ainsi que leurs reçus JSON, constituent les seuls autres fichiers créés sous ce dossier ; ils n’ajoutent aucune donnée de production. La reprise visuelle demandée ensuite est détaillée ci-dessous.

## Reprise visuelle — accents colorés

À la demande de Yoahn, la page a été rapprochée des accents de la référence 04, réellement rouverte pour cette passe : icônes sur pastilles colorées, surfaces légèrement teintées, bordures de sélection et badges d’état. Cyan pour l’interaction, vert pour la zone et l’étape Conditions, violet pour l’entrée de carte/la scène, doré pour les résultats/conséquences. Les libellés et icônes conservent l’information indépendamment de la couleur ; le vert de Conditions n’indique pas une évaluation réussie.

Réemploi exclusif des tokens Avelune existants. Aucun modèle, moteur, transaction, déclencheur ou comportement de sauvegarde modifié. L’ordre des quatre sources est conservé. Les paramètres de teinte sont optionnels : les autres pages gardent le rendu précédent de StudioChoice.

Fichiers de cette passe (chemins relatifs à `apps/avelune_studio/lib/`) :

| Fichier | Zone et effet |
| --- | --- |
| `presentation/shared/widgets/feedback/studio_badge.dart` | Résolution commune StudioToneColor ; palette du badge inchangée. |
| `presentation/shared/widgets/feedback/studio_icon_tile.dart` | Nouveau composant partagé d’icône avec fond dégradé et contour issus du thème. |
| `presentation/shared/widgets/inputs/studio_choice.dart` | Teinte optionnelle du fond et du contour, sélection clavier/pointeur conservée. |
| `presentation/features/events/event_labels.dart` | Correspondance source/état vers une tonalité et ordre explicite des sources. |
| `presentation/features/events/event_status_badge.dart` | Nouveau badge commun aux états et modifications locales. |
| `presentation/features/events/event_library.dart` | Repères colorés cohérents dans la bibliothèque. |
| `presentation/features/events/event_trigger_panel.dart` | Même code couleur dans les choix de source. |
| `presentation/features/events/event_summary.dart` | Étapes cyan/vert/violet et conséquences dorées. |
| `presentation/features/events/event_workspace_page.dart` | Import du badge d’état partagé avec la composition. |
| `presentation/features/events/event_workspace_layout.dart` | État du document présenté par le badge. |

Ces changements portent l’inventaire à 87 fichiers Dart pour le lot complet (les 83 initiaux plus les deux nouveaux composants et deux fichiers partagés supplémentaires). Les dix fichiers de cette passe restent sous 300 lignes. Aucun nouveau Markdown.

Vérifications fraîches : [14 tests ciblés réussis](logs/color-widgets.txt) (design system, parcours UI08, focus et quatre sources), [capture finale](logs/color-capture-final.txt), [analyse propre](logs/color-analyze.txt), [build macOS](logs/color-build.txt). La suite globale précédente de 475 tests n’a pas été relancée pour cette retouche visuelle. Les sept captures ont été remplacées par des rendus réels non retouchés de la nouvelle version. La manipulation native reste non vérifiée.

Commande ciblée : `flutter test --no-pub --reporter expanded --concurrency=1 test/presentation/studio_design_system_test.dart test/presentation/ui08_event_journey_test.dart test/presentation/ui08_event_focus_test.dart test/presentation/ui08_event_sources_test.dart`, depuis Studio, avec `AVELUNE_CAPTURE_DIR` pointant vers le dossier de captures ci-dessus. Commandes d’analyse/build identiques à la livraison initiale. Reçus JSON avec codes de sortie et suivi des processus à côté de chaque journal.

Verdict de la passe visuelle : accents désormais visibles dans les trois colonnes, fond sombre et boutons d’action bleus conservés ; différences de décor et réserve de validation native inchangées. Validation visuelle utilisateur toujours attendue. Aucune écriture Git ou Notion, aucun projet original modifié.
