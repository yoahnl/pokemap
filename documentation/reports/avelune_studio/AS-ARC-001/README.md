# AS-ARC-001 — Inventaire de reprise et périmètre de remplacement

Audit du 19 septembre 2026. **Livraison documentaire ; aucune application créée.** Les décisions ci-dessous sont proposées à la revue de Yoahn, pas des capacités déjà livrées d’Avelune Studio.

## Synthèse

1. Reprendre les modèles métier de `map_core`, les capacités canoniques de `map_authoring`, les moteurs gameplay/battle et le runtime existant.
2. Proposer `apps/avelune_studio` comme nouvelle application, avec un point d’entrée distinct de `packages/map_editor`.
3. Réécrire la présentation autour de la carte ; ne pas importer l’ancien contrôleur global ni ses widgets privés.
4. Adapter la session de documents, les commandes locales et les frontières de ressources avant de brancher les gestes.
5. L’empilement de calques existe ; l’ordre fixe universel des décors et son articulation avec les personnages restent à contractualiser.
6. L’historique interne sait refaire, mais le port public de mutation ne propose pas `redo`.
7. Les caches, deltas et contrôles de concurrence existants constituent des points de départ, pas une preuve de fluidité.
8. Le MCP live échoue avec `worker.exited`, code 78 ; aucune parité live n’est certifiée.
9. Les tests ciblés révèlent aussi un échec de garde de taille préexistant ; les résultats sont détaillés ci-dessous.
10. Prochain lot recommandé : AS-ARC-002, clarification des frontières et contrats M1 ; aucune implémentation lancée ici.

## Livrables

| Fichier créé | Zones et rôle |
|---|---|
| [Inventaire de reprise](inventaire_reprise.md) | Matrice des capacités, propriétaires de contrats, décisions, jalons et niveau de preuve. |
| [Dépendances et flux](dependances_et_flux.md) | Quatre chaînes critiques, façades publiques, intégrité et empilement éditeur/runtime. |
| [Risques de performance](risques_performance.md) | Déclencheurs, travail observé, portée, preuves et mesures futures ; aucun benchmark. |
| [Transition et M1](transition_et_perimetre_m1.md) | Emplacement proposé, coexistence, découpage, décisions ouvertes et recette M1/M4. |
| Ce README | Synthèse, état initial/final, sources, commandes, résultats et limites de clôture. |

Le brief propose cinq fichiers sous `documentation/avelune_studio/AS-ARC-001/`. Le dossier retenu est `documentation/reports/avelune_studio/AS-ARC-001/`, selon la convention des audits du dépôt. Il était absent avant écriture ; aucun livrable existant n’a été écrasé. Les cinq fichiers correspondent au découpage explicitement borné du brief, sans rapport supplémentaire par agent.

## Sources et méthode

Brief fourni : `/Users/karim/Downloads/avelune_studio_codex_AS-ARC-001.md`. Instructions lues : `AGENTS.md`, `codex_rule.md`, `skills/README.md`, `skills/using-pokemap-mcp/SKILL.md`, `skills/verification-before-completion/SKILL.md`, puis `README.md`. Aucun `AGENTS.md` plus proche trouvé dans les répertoires documentaires concernés.

Pages Notion consultées en lecture seule le 19 septembre :

- [AS-ARC-001](https://app.notion.com/p/3e0197a7bfa58176b4dafc1f9bd8efb3), état lu `TODO`, jalon `M0`, epic existant ; rattachement au programme Avelune Studio, sans nouvelle famille.
- [Programme V2](https://app.notion.com/p/3e0197a7bfa5819f9c04c9c73b418ba9).
- [Contrat d’architecture](https://app.notion.com/p/3e0197a7bfa581c39914c3f6add029a0).
- [Fluidité, caches et validation](https://app.notion.com/p/3e0197a7bfa5816a846de6422c99ed28).
- [Expérience sans calques](https://app.notion.com/p/3e0197a7bfa581f68609ebbfbed34bc5).
- [Préparation 3D](https://app.notion.com/p/3e0197a7bfa581fca753f8beffb95064).
- [Jalons et critères de livraison](https://app.notion.com/p/3e0197a7bfa5810ea51ff7cd54681d9f).

Ces pages décrivent des intentions et propositions. Le PNG `éditeur_de_carte_pixel_art_village_azuria.png` n’est pas joint à la page selon son contenu ; **image non analysée**. L’audit ne transforme pas sa description en validation visuelle.

L’ancien rapport `documentation/reports/architecture/map_authoring_clean_architecture_audit_2026-08-08.md` a été consulté comme repère historique. Son affirmation « seule dépendance de production : map_core » n’est plus actuelle : `map_authoring/pubspec.yaml:13-23` inclut notamment `map_distribution`. Ses résultats, compteurs et anciennes failles ne sont pas réutilisés comme preuve actuelle.

Les références de code sont relatives à la racine du dépôt et données avec symboles et plages de lignes. Une lecture ciblée ne certifie pas toute une famille. Les termes « trouvé », « lu » et « exécuté » sont distingués dans les livrables.

## État initial capturé avant écriture

Commandes exécutées :

```sh
pwd
git rev-parse --show-toplevel
git branch --show-current
git rev-parse HEAD
git status --short --untracked-files=all
git diff --stat
git diff --cached --stat
git remote -v
```

Résultats : racine et `pwd` = `/Users/karim/Project/pokemonProject` ; branche `main` ; SHA `a42d67945687a931d648c6022519deb2d768c742`. Les remotes `origin` et `github` pointent vers `git@github.com:yoahnl/pokemap.git`.

État initial : **60 suppressions non indexées**, toutes dans `.superpowers/brainstorm/`, **8 731 lignes supprimées** ; index vide ; aucun autre changement. Les sorties complètes de statut et de diff ont été capturées dans la session avant écriture. Ces suppressions sont préexistantes et étrangères au lot ; aucune tentative de restauration ou nettoyage.

## Vérifications et preuves fraîches

| Vérification | Résultat | Limite |
|---|---|---|
| Lecture des six packages demandés, de leurs manifests et façades | Réalisée, avec approfondissement M1 | Pas un audit exhaustif de tous les métiers. |
| `pokemap_describe({})` | `ok:false`, `worker.exited`, `exitCode:78`, non retryable | Le catalogue live n’a pas été obtenu ; aucune réparation ni reconstruction du serveur. |
| Tests ciblés `map_core`, commande ci-dessous | Exit 0, `00:00 +52: All tests passed!` | Contrats actuels de calques/éléments/rotation/opacité, pas la future UX d’empilement. |
| Tests ciblés `map_authoring`, commande ci-dessous | Exit 1, `00:01 +16 -1: Some tests failed.` | Garde `<1300` lignes échouée sur `environment_actions.dart`, 1 304 lignes ; aucun correctif hors périmètre. |

Commande réellement exécutée depuis `packages/map_core`, dépendances déjà présentes, sans installation :

```sh
/opt/homebrew/bin/dart --packages=.dart_tool/package_config.json /Users/karim/.pub-cache/hosted/pub.dev/test-1.31.1/bin/test.dart test/authored_layer_insert_index_test.dart test/placed_elements_test.dart test/placed_element_opacity_test.dart test/map_placed_element_rotation_test.dart --reporter=expanded
```

Commande réellement exécutée depuis `packages/map_authoring` :

```sh
dart test test/package_boundary_test.dart test/history/undo_redo_contract_test.dart
```

L’échec se situe dans `test/package_boundary_test.dart:152-166`, assertion à la ligne 162. Huit tests d’historique et huit tests de frontière ont réussi dans ce run. Aucun fichier de production ni de test n’avait été modifié : cet échec est donc observé sur le code préexistant. Aucun Flutter test lancé ; aucun harness Flutter créé. Les runners Dart terminés n’ont pas nécessité de terminaison forcée.

Tests créés/modifiés : aucun. `dart analyze`, `flutter analyze`, build Flutter, tests UI/runtime, PMCP-085, conformance MCP et benchmarks : **non exécutés**, ce lot ne changeant que la documentation et interdisant installation, correction ou génération. Le build produit est non applicable ; la validation alternative porte sur références, périmètre Git, liens et hygiène Markdown. Aucun succès applicatif n’est inféré de cette validation documentaire.

## Arbitrages, contradictions et limites

- Le brief limite Notion à la lecture, alors que la règle générale demande d’y déposer les preuves. La restriction spécifique du lot est conservée : **aucun ticket, statut ou contenu Notion modifié**. La projection des preuves reste à faire avant clôture du suivi ; ce lot n’est pas déclaré `DONE`.
- La règle générale de `codex_rule.md` demande des tests ajoutés et beaucoup de commentaires ; le brief documentaire et `AGENTS.md` interdisent ces changements ici. Aucun test ni commentaire de production ajouté.
- La charte propose ≤300 lignes et une revue à 301–400. L’ancien audit indique qu’un ancien contrôle global de taille a été retiré ; la nouvelle charte n’est donc pas une preuve que ce garde-fou est déjà actif partout.
- Le chemin de l’application, le contrat d’ordre visuel, la portée de la pile, la sélection multiple et les touches exactes restent à valider. La préparation 3D ne choisit ni moteur ni nouveau format.
- Une API publique et une sérialisation existantes ne suffisent pas à prouver le geste, son rendu ou la parité MCP.

## Revue et clôture documentaire

| Passe indépendante | Verdict |
|---|---|
| Audit / Architecture | Socle métier reprenable ; adaptations ciblées de session, façade redo et ordre partagé nécessaires. Pas de justification à une réécriture générale des moteurs. |
| Implémentation préparatoire | M1 peut reprendre buffers, historique, protections de session et rendu ; présentation à reconstruire. Aucun code implémenté, conformément au lot. |
| Tests | 52 tests core réussis ; 16 authoring réussis et une garde de taille en échec. Empilement Studio et Player non qualifiés par ces tests. |
| Build / Validation documentaire | Avis favorable après correction des chemins, plages et symbole `loadRuntimeMapBundle`. Build produit non applicable ; pas de test applicatif supplémentaire. |
| Critique finale | Avis favorable après correction de l’ambiguïté pile de sélection/ordre persistant. Familles M1/M4 et limites de preuve correctement séparées ; aucun changement de production requis par cet audit. |

Corrections issues des revues : attribution des opérations de régions à `map_authoring`, chemins complets des tests, bornes réelles des fichiers d’état/routage, sémantique exactement `ProjectVersion.v6`, distinction dirty/état de vue. Les cinq nouveaux fichiers non suivis ont été relus explicitement ; leur absence de `git diff` n’a pas servi de validation.

Commandes de clôture :

```sh
POKEMAP_MARKDOWN_MAX_NEW=5 bash tools/scripts/check_markdown_hygiene.sh
git status --short --untracked-files=all
git diff --stat
git diff --cached --stat
git diff --check
```

Le budget Markdown de cinq correspond aux cinq livrables demandés. Résultat de l’hygiène : exit 0, `Markdown hygiene: 5 new Markdown file(s), all in canonical locations.` Le contrôle des références Dart et des liens locaux ne relève plus de cible manquante ou de plage hors fichier après corrections. Vérification complémentaire des espaces de fin de ligne et fences sur les fichiers non suivis : aucune anomalie.

**État final du lot :** mêmes 60 suppressions préexistantes sous `.superpowers/brainstorm/`, plus exactement les cinq fichiers Markdown listés dans ce README. `git diff --stat` reste à `60 files changed, 8731 deletions(-)` ; `git diff --cached --stat` vide ; `git diff --check` sans sortie, exit 0. Branche et SHA inchangés. Aucun fichier source, test, fixture, dépendance, lockfile ou script temporaire ajouté/modifié par ce lot ; aucune commande Git d’écriture, aucune modification Notion.

**Auto-critique :** l’analyse est approfondie sur la boucle carte/décor/ordre/historique/persistance, mais les routes narratives, catalogues et export sont principalement inventoriées. Aucun parcours utilisateur réel ni profilage ne vient confirmer leur fluidité ou leur couverture. Le défaut live MCP empêche la preuve de découverte actuelle. Les décisions de contrat sont proposées, pas figées ; leurs tests d’intégration restent à écrire dans les lots de développement. L’audit est livré pour revue ; la projection des preuves dans Notion reste volontairement non réalisée et empêche de considérer le suivi comme clos.

Le prochain lot et ses prérequis concrets sont dans [Transition et M1](transition_et_perimetre_m1.md#m0-et-livraisons-cohérentes-nécessaires-à-m1). **Arrêt après AS-ARC-001** : AS-ARC-002, prototype UX, AS-PERF-001 et création Flutter non commencés.
