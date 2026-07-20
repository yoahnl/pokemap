# Evidence Pack — NSC-24 — Overview narrative opérationnelle et traçable

Date : 2026-07-20

Package : `packages/map_editor`

Roadmap : `docs/superpowers/plans/2026-07-19-narrative-studio-completion-roadmap.md`
Verdict proposé : **DONE**

## 1. Résumé exécutif

NSC-24 transforme l'Overview de Narrative Studio en point d'entrée opérationnel. Les compteurs, l'état éditorial, la reprise d'édition, la file de diagnostics et l'activité récente sont maintenant issus de sources identifiées : manifeste canonique, projection Storyline, registre Event, catalogues narratifs, Validator global et journal durable des sessions NSC-13.

Chaque indicateur visible expose sa provenance. Les raccourcis ouvrent la bonne route Narrative Studio et, lorsque la source le permet, le bon asset. Les diagnostics non réparables automatiquement ouvrent le Validator sur leur identifiant stable ; aucune mutation opportuniste n'est exécutée. L'activité runtime n'est jamais déduite ou simulée.

Le journal d'activité est stocké dans `.pokemap/narrative/activity-journal.json`, écrit par remplacement atomique et vérifié avant publication. Sa première intégration réelle observe la session documentaire Cinematics déjà pilotée par NSC-13. Les autres modules restent honnêtement sans activité tant qu'ils n'utilisent pas encore cette passerelle commune.

Validation ciblée : **86 tests passés**, analyse statique propre, golden produit stable et build macOS debug réussi. La première exécution complète a passé 3 569 tests et rencontré un timeout de contention sur un benchmark historique ; ce benchmark repasse seul en 9 secondes. La seconde exécution complète avec concurrence plafonnée passe **3 570 tests** et ferme le gate.

## 2. Audit initial

### Contrats trouvés

- `NarrativeOverviewReadModel` agrégeait déjà plusieurs catalogues, mais certains compteurs restaient sans provenance explicite et plusieurs cartes n'étaient pas actionnables.
- `ProjectManifest.storylines` est la vérité canonique Storyline ; `ScenarioAsset` demeure seulement une source legacy explicite.
- `NarrativeProjectValidationReport` possède les diagnostics globaux et leurs identifiants stables.
- `NarrativeDocumentSession` expose les transitions `edited`, `saved`, `recovered`, `saveFailed` et `conflicted`, mais aucun journal projet durable ne les projetait dans l'Overview.
- la composition NSC-13 est actuellement branchée sur le pilote Cinematics ; elle constitue la seule source d'activité durable autorisée pour ce lot.
- le design system fournit les cartes métriques, badges, surfaces, boutons, états vides et couleurs sémantiques nécessaires.

### Risques identifiés

- compter deux fois Storylines et scénarios legacy ;
- présenter un compteur sans pouvoir en expliquer la source ;
- inventer une activité runtime à partir de dates de fichiers ou de données statiques ;
- faire échouer une édition narrative parce que l'écriture du journal d'activité échoue ;
- proposer un « correctif rapide » non déterministe ;
- deep-linker vers une route ou un asset approximatif ;
- rendre le dashboard illisible dans une largeur desktop réduite ou avec texte agrandi.

### Verdict Audit / Architecture

**PASS** : l'Overview est une projection de sources existantes. Le seul nouvel état durable est un journal d'activité éditoriale borné, versionné et alimenté par les transitions réelles de NSC-13. Il ne devient pas une seconde vérité narrative.

## 3. État Git initial

HEAD initial : `48075688 feat(narrative): make storyline graph semantic and interactive`.

Changements préexistants hors lot, conservés :

~~~text
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
A  examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
 M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
 M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
 M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
 M selbrume/project.json
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md
~~~

Le test lighthouse était déjà indexé avant NSC-24 et doit rester hors du commit du lot.

## 4. Contrat livré

| Besoin | Comportement livré | Source / persistance |
|---|---|---|
| Reprendre l'édition | cible la dernière activité connue ou la Storyline canonique | journal NSC-13, puis projection Storyline |
| Scope Storyline | distingue canonique, fallback legacy, vide et ambigu | `ProjectManifest.storylines`, puis `ScenarioAsset` explicite |
| KPIs | affichent valeur, état et libellé de provenance | read model traçable |
| Santé projet | utilise le rapport global réel | `NarrativeProjectValidationReport` |
| Diagnostics | liste les problèmes bloquants / à revoir | Validator global, ID stable |
| Action diagnostic | ouvre le Validator focalisé | navigation typée ; aucune mutation non prouvée |
| Activité récente | journalise edit/save/recovery/failure/conflict | `.pokemap/narrative/activity-journal.json` |
| Erreur de journal | n'interrompt jamais l'édition auteur | erreur reportée et Overview honnête |
| Activité runtime | reste absente sans source runtime | aucune inférence |
| Modules | chaque tuile expose sa source et sa destination | catalogues / registres réels |

## 5. Journal d'activité durable

Le format JSON est strict et versionné. Les entrées sont triées de la plus récente à la plus ancienne, dédupliquées et bornées. Le repository :

1. crée le dossier projet `.pokemap/narrative` si nécessaire ;
2. écrit un fichier temporaire flushé ;
3. relit et valide strictement le document ;
4. remplace atomiquement le journal publié ;
5. propage les erreurs au recorder, qui les signale sans casser la session auteur.

`NarrativeActivitySessionRecorder<T>` observe une vraie `NarrativeDocumentSession<T>`. Les états transitoires ou inchangés ne produisent aucune entrée. L'intégration provider actuelle cible Cinematics, seule route déjà raccordée à la persistance durable NSC-13.

## 6. Inventaire complet des fichiers

### Fichiers créés

| Fichier | Contenu complet / responsabilité |
|---|---|
| `packages/map_editor/lib/src/application/services/narrative_activity_journal.dart` | 430 lignes : modèle versionné, destinations, sérialisation stricte, journal borné, service de projection des transitions NSC-13 et recorder résilient. |
| `packages/map_editor/lib/src/infrastructure/repositories/narrative_activity_journal_repository.dart` | 83 lignes : repository projet, lecture stricte et publication atomique vérifiée. |
| `packages/map_editor/test/narrative_activity_journal_test.dart` | 277 lignes : modèle, déduplication, transitions réelles, absence d'activité fictive et isolation des erreurs. |
| `packages/map_editor/test/narrative_activity_journal_repository_test.dart` | 102 lignes : absence, roundtrip/reload, version invalide, contenu invalide et échec d'écriture. |
| `reports/narrativeStudio/completion/nsc_24_actionable_narrative_overview_evidence_pack.md` | présent document complet. |

Les fichiers créés ci-dessus constituent leur contenu complet faisant autorité. Leurs contrats et scénarios sont inventoriés exhaustivement ici sans dupliquer 892 lignes de Dart dans un second artefact divergent.

### Fichiers modifiés — zones précises

| Fichier | Zone | Raison / impact |
|---|---|---|
| `packages/map_editor/lib/src/app/providers/core/repository_providers.dart` | providers de session et journal | Branche le recorder NSC-13 Cinematics et recharge l'activité publiée. |
| `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart` | projection globale | Ajoute scope Storyline, reprise, activité, diagnostics, sources métriques et priorité canonique/legacy. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | composition Overview et deep links | Charge journal/Validator pour l'Overview et résout les destinations exactes. |
| `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart` | dashboard, reprise, métriques, files d'action | Rend les sources visibles et toutes les cartes pertinentes actionnables. |
| `packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart` | activité et diagnostics | Remplace les données décoratives par des files réelles et des états honnêtes. |
| `packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart` | inspection de provenance | Affiche scope Storyline, origine et sources de métriques. |
| `packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart` | `PokeMapMetricCard` | Ajoute le libellé de source et la flexibilité de sous-titre au composant partagé. |
| `packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart` | projection | Canonique/legacy, provenance, reprise, activité et diagnostic bloquant. |
| `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart` | UI | Actions, erreurs de chargement, activité, diagnostic sans faux quick-fix et responsive. |
| `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart` | navigation shell | Vérifie les nouvelles destinations Storylines et Validator. |
| `packages/map_editor/test/goldens/narrative_studio/overview/overview_full_product_route_1672x941.png` | golden produit | Référence visuelle de l'Overview opérationnelle à 1672×941. |

Diff textuel suivi avant ajout des quatre nouveaux fichiers et du présent rapport : **1 521 insertions, 237 suppressions** dans 11 fichiers, plus le golden actualisé. Les quatre fichiers Dart créés totalisent **892 lignes**.

## 7. Tests et garde-fous

Couverture positive : source canonique Storyline, fallback legacy explicite, reprise exacte, transitions de session réelles, journal reloadable, diagnostic global bloquant, navigation clavier/souris des cartes, activité récente et responsive.

Couverture négative : version de journal inconnue, JSON invalide, écriture impossible, journal vide, projet non sauvegardé, Validator indisponible, aucune activité runtime fabriquée, aucun bouton de correction lorsque le diagnostic n'est pas déterministement réparable.

Garde-fous : design system et tokens uniquement, journal non bloquant pour l'auteur, sérialisation stricte, taille bornée, aucune règle narrative Flutter, aucune mutation directe du manifeste depuis le dashboard.

## 8. Commandes et résultats exacts

### Validation ciblée

~~~text
cd packages/map_editor
flutter test \
  test/narrative_activity_journal_test.dart \
  test/narrative_activity_journal_repository_test.dart \
  test/features/narrative/application/overview/narrative_overview_read_model_test.dart \
  test/ui/canvas/narrative_overview_workspace_test.dart \
  test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:03 +86: All tests passed!

flutter analyze
Analyzing map_editor...
No issues found! (ran in 4.7s)

dart format --output=none --set-exit-if-changed <14 fichiers Dart NSC-24>
Formatted 14 files (0 changed) in 0.09 seconds.
~~~

### Golden et build

~~~text
flutter test test/ui/canvas/narrative_studio_specialized_routes_test.dart \
  --plain-name 'matches the full overview product route at 1672x941'
00:00 +1: All tests passed!

flutter build macos --debug
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
~~~

Le golden a d'abord signalé le changement visuel attendu, a été régénéré uniquement pour la route Overview, puis inspecté en résolution originale avant le test stable ci-dessus.

### Suite complète et contention historique

~~~text
flutter test --reporter failures-only
+3569 -1: Some tests failed.

Échec unique :
test/narrative_event_authoring_snapshot_performance_test.dart
TimeoutException after 0:00:30.000000

flutter test test/narrative_event_authoring_snapshot_performance_test.dart
00:09 +1: All tests passed!
~~~

Le benchmark historique n'est pas modifié par NSC-24. Son passage isolé en 9 secondes prouve que le timeout venait de la contention de la suite à concurrence par défaut.

~~~text
flutter test --concurrency=4 --reporter failures-only
+3570: All tests passed!
~~~

## 9. Verdict des cinq passes obligatoires

| Passe locale séparée | Verdict | Preuve |
|---|---|---|
| Audit / Architecture | **PASS** | Projection de sources canoniques ; journal borné sans seconde vérité. |
| Implémentation | **PASS** | Reprise, sources visibles, diagnostics actionnables et activité durable. |
| Tests | **PASS** | 86 tests NSC-24, golden produit et 3 570 tests complets stables. |
| Build / Validation | **PASS** | Analyse complète propre et app macOS debug construite. |
| Critique finale | **PASS avec limite explicite** | Intégration d'activité limitée au pilote NSC-13 Cinematics. |

Les instructions actives interdisent les sub-agents sans demande explicite. Les contrôles de `codex_rule.md` ont donc été exécutés comme passes locales distinctes.

## 10. Limites et non-objectifs

- l'activité durable est actuellement alimentée par Cinematics, seul pilote raccordé à `NarrativeDocumentSession` NSC-13. Les autres modules apparaîtront au fur et à mesure de leur migration vers cette session commune ; aucune activité de substitution n'est inventée.
- les diagnostics actuels n'exposent aucun `hasDeterministicRepair` vrai. L'Overview ouvre donc le Validator et son inspecteur exact au lieu de muter le projet.
- le nombre de lignes Yarn demeure indisponible sans source fiable et n'est pas fabriqué.
- le fallback legacy Global Story reste visible et explicitement qualifié. Il n'est jamais fusionné silencieusement avec la Storyline canonique.
- aucun nouveau comportement runtime n'est revendiqué : ce lot couvre l'authoring, la traçabilité et la navigation.

## 11. Auto-critique finale

Le read model Overview devient volumineux parce qu'il centralise la projection de nombreuses sources. Il reste toutefois pur, testé et sans IO. Une décomposition future par domaine pourrait améliorer la navigation dans le code, mais la faire dans NSC-24 aurait augmenté le risque sans modifier le contrat utilisateur.

Le journal d'activité est volontairement hors du manifeste afin de ne pas polluer la donnée de jeu. Son caractère projet-local est approprié pour la continuité éditoriale, mais une future collaboration multi-utilisateur devra définir explicitement si ce journal demeure local ou devient partagé.

La première suite complète a révélé une sensibilité historique du benchmark Event V2 à la contention CPU. Le test isolé passe largement sous son timeout ; le gate final utilise une concurrence bornée pour conserver une preuve reproductible plutôt que d'assouplir un test hors périmètre.

## 12. État Git final avant commit

Le commit doit inclure uniquement les seize chemins NSC-24 inventoriés ci-dessus au moyen de `git commit --only`. Les changements Selbrume préexistants, dont le test lighthouse déjà staged, doivent rester inchangés et hors commit.

## 13. Gate Phase 2

Avec NSC-20 à NSC-24, la Phase 2 livre : cycle de vie Storyline, authoring Chapters/Steps, projection de progression, graph sémantique et Overview opérationnelle. Le gate est **PASS** après confirmation des 3 570 tests complets à concurrence bornée.

Prochaine phase recommandée : Phase 3, en commençant par le premier lot Dialogues/Yarn défini dans la roadmap de completion.
