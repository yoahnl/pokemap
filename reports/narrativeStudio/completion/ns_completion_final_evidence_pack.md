# Evidence Pack final — NSC-83 / Narrative Studio v1

Date : 2026-07-21

Branche : `main`

Lot : `NSC-83 — QA humaine, documentation et release gate`
Lots mécaniques alimentés : `FG-180`, `FG-181`, `FG-182`, `FG-183`,
`FG-184`, `FG-185` (sous-ensemble Narrative Studio/Selbrume uniquement)

## 1. Résumé exécutif

Verdict : **GO — Narrative Studio v1 / Selbrume**.

La phase 8 est fermée. NSC-80 prouve la reconstruction du domaine depuis un
projet minimal sans authoring JSON ; NSC-81 livre la campagne canonique ;
NSC-82 prouve victoire, défaite, retry, persistance, Validator et receipt ;
NSC-83 ajoute le walkthrough humain sur les deux vrais binaires macOS, les
captures, l'accessibilité, les petites fenêtres, les pannes injectées, la
documentation reproductible et la gate transversale complète.

Le premier run complet de l'éditeur a révélé deux régressions produit et une
limite responsive réelle. Elles ont été corrigées avant la gate : snapshot
Validator avec géométrie Freezed imbriquée, écrasement de la scène centrale à
768 px et overflows Facts/World Rules. Les 38 échecs initiaux de la suite
éditeur ont ensuite été réduits à zéro après correction et rebasage contrôlé
des références visuelles intentionnellement modifiées.

Ce verdict ne transforme pas `FG-185` en GO global du MVP : il ferme la
dimension Narrative Studio/Selbrume. Les mécaniques hors Studio conservent
leur autorité dans `pokemap_roadmap_mecaniques_fangame.md`.

## 2. Confirmation du scope et remise en cause du prompt

Le prompt demandait la phase 8 entière et un commit par lot. La phase contient
quatre lots : NSC-80, NSC-81 et NSC-82 étaient déjà commités séparément ; le
présent changement isole NSC-83.

Une instruction de la roadmap a été interprétée avec précision : le parcours
humain n'a pas ressaisi à la main toute la campagne depuis un projet vierge.
Cette reconstruction est la preuve automatisée publique NSC-80. Le parcours
humain utilise le projet canonique promu et vérifie une mutation no-code,
save/close/reload, Validator et runtime réel. Affirmer une reconstruction
manuelle complète aurait été un mensonge de preuve.

Inclus :

- walkthrough des binaires macOS éditeur et runtime host ;
- sauvegarde, fermeture, relance et lecture disque sur une copie jetable ;
- comparaison aux goldens et captures réelles ;
- clavier, semantics, 200 % de texte, contraste, reduced motion, localisation
  et petites fenêtres ;
- asset absent, écriture refusée, révision stale et commande runtime non
  supportée ;
- corrections strictement nécessaires révélées par la gate ;
- matrice complète test/analyze/build et documentation de reproduction.

Hors scope :

- aucune modification manuelle de `selbrume/project.json` ;
- aucune mutation du projet canonique pendant le walkthrough ;
- aucune mise à jour de la roadmap mécanique source ;
- aucune déclaration de GO pour les mécaniques MVP hors Narrative Studio ;
- aucun push, non demandé par l'utilisateur.

## 3. Audit initial

État Git initial de NSC-83 :

```text
HEAD d7d3a2604 test(narrative): prove Selbrume persistence matrix
$ git status --short --untracked-files=all
(aucune sortie)
```

Contrats trouvés :

- roadmap canonique Phase 8, section 17, et matrice section 18 ;
- matrice de capacités NSC-00 encore marquée avec des cellules `Partial` ;
- preuve de reconstruction NSC-80 ;
- campagne et seeder canonique NSC-81 ;
- fingerprint/receipt et matrice E2E NSC-82 ;
- tests desktop, responsive, semantics, recovery et runtime déjà présents ;
- deux binaires Flutter macOS constructibles localement.

Risques initiaux : faux GO basé uniquement sur des tests, modification du
projet canonique pendant la QA, rebasage aveugle de goldens, petite fenêtre non
testée sur le binaire réel, receipt stale et confusion entre gate narrative et
gate mécanique globale.

## 4. Passes manuelles exigées par `codex_rule.md`

L'orchestrateur interdisait les sub-agents pour ce tour. Les cinq rôles ont
donc été exécutés comme passes manuelles distinctes et nommées.

| Passe | Verdict | Conclusion indépendante |
|---|---|---|
| Audit / Architecture | PASS | frontières `map_core`/`map_gameplay`/`map_runtime`/`map_editor` préservées ; corrections dans leur propriétaire |
| Implémentation | PASS | sérialisation du snapshot, layouts responsive et recovery testés sans nouvelle double vérité |
| Tests | PASS | 12 426 tests de package réussis, 1 skip déclaré, négatifs et non-régressions présents |
| Build / Validation | PASS | 6 analyses propres, 2 smokes verts et 2 applications macOS debug produites |
| Critique finale | PASS / GO | aucune limitation P0/P1 ni commande publiée silencieusement ignorée ; limites de preuve documentées |

## 5. Walkthrough humain des binaires

### 5.1 Isolation et intégrité

Copie jetable :

```text
/Users/karim/Library/Containers/com.example.mapEditor/Data/Documents/selbrume-nsc83-1HCsfW
```

Fingerprints après QA :

```text
a1ab8c3646be969745767effcda9f00f26f677e3acc1535a36cdcac6d4e3d7a0  selbrume/project.json
cfc58c7dbe4f807e07bc43a1875190db12cff2fdab20767211dfb57876ff3bd1  copie-qa/project.json
```

Le projet source conserve son fingerprint. La différence de la copie est la
mutation UI attendue `playerName = "Joueur QA NSC83"`.

### 5.2 Éditeur

Observations réelles :

- bandeau `Projet QA « Selbrume » chargé`, `Synchronisé`, `Sauvegardé`,
  `Projet : Bon` ;
- Overview : 4 chapitres, 31 Scenes, 16 Cinematics, 3 quêtes secondaires,
  22 Dialogues, 49 Facts, 34 World Rules et 4 éléments legacy ;
- Event Builder : 31 Events et sélection d'un Event lié à un vrai PNJ, une
  Scene, des Facts, des outcomes starter et des World Rules ;
- Validator : `Jouable`, 0 erreur, 51 avertissements de qualité et 29 Events
  contrôlés ;
- Nouveau jeu : nom modifié, sauvegardé, application fermée puis relancée ; le
  champ et la valeur disque sont conservés.

### 5.3 Runtime host

Le binaire réel a chargé 10 maps, 31 tilesets et 3 scenarios. Selbrume est
affiché sur `map_bourg_selbrume`. La sauvegarde puis le reload ont restauré la
position `(17,24)` et l'overlay a confirmé le succès.

Le serveur Marionette n'était pas exposé dans cette session. Le protocole de
la skill desktop a donc utilisé son fallback Computer Use sur les vraies
applications, et non un widget test présenté comme parcours humain.

## 6. Défauts découverts et corrections

### 6.1 Snapshot Validator et géométries imbriquées

`ProjectManifest.toJson()` pouvait conserver un `GridPos` Freezed imbriqué dans
un trigger de map. Le canonicalizer strict rejetait alors le snapshot réel.

Correction : `narrative_validator_providers.dart` normalise le projet et la
map active par un roundtrip `jsonEncode/jsonDecode` avant canonicalisation.
Le nouveau test prouve qu'une map avec géométrie typée et sa version reloadée
produisent le même fingerprint.

### 6.2 Shell à 768 px

Avec explorateur et inspecteur ouverts, leurs largeurs fixes écrasaient la
scène centrale et produisaient des `RenderFlex overflow`.

Correction : sous 956 px, si les deux panneaux sont ouverts, l'explorateur se
compacte à 52 px. Le clic de réouverture ferme l'inspecteur afin de conserver
une scène centrale utilisable. Le test de handoff et la capture du vrai
binaire prouvent le comportement.

### 6.3 Facts / World Rules en fenêtre basse

Les métriques et formulaires concurrençaient la zone d'authoring à 768 px ou
avec texte agrandi.

Correction : les métriques secondaires sont masquées sous 820 px de hauteur
utile ; les zones création/édition World Rule deviennent deux scrolls bornés
et indépendants. La matrice 1280/1366/1440/1672/1920 à 100/125/150 % passe.

### 6.4 Dette d'analyse et attentes obsolètes

Une ancienne méthode `_save` de Dialogue Studio était inutilisée et accédait
à des membres protégés. Elle a été retirée : l'analyse complète passe de 11
issues à `No issues found`.

Les tests ont été alignés sur les opérateurs Fact typés, les layouts
Cinematic actuels et la nouvelle recherche globale. Le fixture Event V2 a été
régénéré par son builder versionné. Les goldens n'ont été mis à jour qu'après
inspection des master/test images et après passage des comportements ciblés.

## 7. Inventaire complet des fichiers

### Produit et fixtures

| Fichier | Zone | Impact |
|---|---|---|
| `packages/map_editor/lib/src/features/narrative/state/narrative_validator_providers.dart` | construction du snapshot | normalise les valeurs JSON imbriquées avant fingerprint |
| `packages/map_editor/lib/src/ui/editor_shell_page.dart` | `LayoutBuilder` du shell | compacte l'explorateur quand les panneaux écrasent la scène |
| `packages/map_editor/lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart` | métriques et body World Rules | authoring utilisable aux petites hauteurs |
| `packages/map_editor/lib/src/ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart` | méthode privée morte | retire 61 lignes inutilisées et 11 issues d'analyse |
| `examples/playable_runtime_host/event_builder_v2_selbrume_slice/project.json` | fixture générée | réaligne le snapshot autonome sur le seeder actuel |
| `examples/playable_runtime_host/event_builder_v2_selbrume_slice/fixture_manifest.json` | hash généré | atteste le nouveau snapshot |

### Tests texte

| Fichier | Zone | Impact |
|---|---|---|
| `packages/map_editor/test/narrative_validator_provider_test.dart` | nouveau cas géométrie | positif et roundtrip fingerprint |
| `packages/map_editor/test/ui/shell/project_explorer_handoff_test.dart` | nouveau cas compact | non-régression petite largeur avec deux panneaux |
| `packages/map_editor/test/ui/canvas/event_builder_v2_accessibility_test.dart` | scroll du sheet | action sauvegarde testée dans une vraie zone scrollable |
| `packages/map_editor/test/ui/canvas/event_builder_v2_creation_flow_test.dart` | condition Fact | attend `notEquals false` typé |
| `packages/map_editor/test/event_builder_v2_condition_expression_test.dart` | libellé | attend le libellé no-code actuel |
| `packages/map_editor/test/scenes_workspace_shell_test.dart` | Fact Registry | utilise picker typé et vérifie opérateur/valeur |
| `packages/map_editor/test/cinematics_library_workspace_test.dart` | surfaces/scroll | garantit les actions réelles dans un viewport adapté |

### Références visuelles modifiées

- `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png`
- `packages/map_editor/test/goldens/event_builder_v2/phase_k/event_builder_v2_1672x941.png`
- `packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_builder_full_product_route_1672x941.png`
- `packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_legacy_full_product_route_1672x941.png`
- `packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_library_full_product_route_1672x941.png`
- `packages/map_editor/test/goldens/narrative_studio/dialogues/dialogues_full_product_route_1672x941.png`
- `packages/map_editor/test/goldens/narrative_studio/events/event_builder_legacy_full_product_route_1672x941.png`
- `packages/map_editor/test/goldens/narrative_studio/facts/facts_full_product_route_1672x941.png`
- `packages/map_editor/test/goldens/narrative_studio/overview/overview_full_product_route_1672x941.png`
- `packages/map_editor/test/goldens/narrative_studio/scenes/scenes_full_product_route_1672x941.png`
- `packages/map_editor/test/goldens/narrative_studio/step/step_full_product_route_1672x941.png`
- `packages/map_editor/test/goldens/narrative_studio/storylines/storylines_full_product_route_1672x941.png`
- `packages/map_editor/test/goldens/narrative_studio/world_rules/world_rules_full_product_route_1672x941.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.png`

### Documentation créée/modifiée

| Fichier | État | Impact |
|---|---|---|
| `reports/narrativeStudio/completion/ns_completion_capability_matrix.md` | modifié | 0 cellule Partial, preuve finale et verdict actualisés |
| `reports/narrativeStudio/completion/ns_completion_human_qa_checklist.md` | créé | reproduction par une autre personne |
| `reports/narrativeStudio/completion/narrative_studio_user_guide.md` | créé | workflow no-code et modèle mental |
| `docs/superpowers/plans/2026-07-21-nsc-83-human-qa-release-gate.md` | créé, chemin ignoré | micro-plan exécutable et clôturé |
| `reports/narrativeStudio/completion/ns_completion_final_evidence_pack.md` | créé | présent rapport ; auto-inclusion textuelle impossible |

### Captures créées

| Fichier | Dimensions | SHA-256 |
|---|---:|---|
| `captures/nsc_83_desktop_before_world_editor.png` | 1366×768 | `fc4462d758b8ca8759d0b05c91263f8df252557dceee8c2a4822e8160ed9b2c5` |
| `captures/nsc_83_desktop_after_event_builder.png` | 1366×768 | `94c992dfce2e229049160a403096a4b1075f2b2b1b8251def1dcfa574131f42c` |
| `captures/nsc_83_desktop_event_selected.png` | 1366×768 | `26c90eed6528518a4292f664314c0895dad7fc9a12c0a18f6ced7267c0854d17` |
| `captures/nsc_83_desktop_validator_pass.png` | 1366×768 | `c5d449bed31a22bd5dd48ed5b37213e234909075db646a18cb9944f6ad7f7474` |
| `captures/nsc_83_desktop_new_game_saved.png` | 1366×768 | `bdaa3e28d09796812d1c2b011d48f564a191c9e6aca33e23c41aa13b85ee24d6` |
| `captures/nsc_83_desktop_new_game_reloaded.png` | 768×870 | `73c36149bde66771d42a6679f8c32812d286da3efd020a5d48665a7e354ce90b` |
| `captures/nsc_83_desktop_compact_shell_after_fix.png` | 768×870 | `c7fe52ac0b3d5d335f80aeab367e1ccf321304c043dff582dc88f6733f34aa3b` |
| `captures/nsc_83_desktop_runtime_selbrume.png` | 800×632 | `22c24f804791432fa8663cbe2c8fe172f7cb68e4d0130de834a627652e05bdb4` |
| `captures/nsc_83_desktop_runtime_save_reload.png` | 800×632 | `175903cdbcc92198a3f50429212f1d559e66ff237f5345cad94121e947561977` |

Les captures sont des binaires PNG ; leur contenu complet est attesté par
dimensions et SHA-256, plutôt que copié comme texte illisible dans ce rapport.

## 8. Tests ciblés et pannes injectées

Résultats notables :

```text
Validator core / media / stale refs : 28 tests passed
Écriture refusée / recovery editor : 1 test passed
Accessibilité editor : 17 tests passed
Commande runtime non supportée : 1 test passed
Shell compact et handoff : 8 tests passed
Reconstruction/persistance/éditeur ciblés : 53 tests passed
Routes et goldens rebasés, relance normale : 272 tests passed
```

Le run ciblé de 53 tests couvre notamment création Event, condition typée,
snapshot Validator, Cinematics Library, shell et fixture autonome
save/reload/retry/stale revision.

## 9. Matrice obligatoire — résultats exacts

Environnement :

```text
Flutter 3.46.0-0.3.pre • channel beta
Dart 3.13.0 (build 3.13.0-167.1.beta)
macOS arm64, Europe/Paris
```

| Package | Tests frais | Analyze frais |
|---|---:|---|
| `map_core` | `02:01 +4323: All tests passed!` | `No issues found!` |
| `map_gameplay` | `+300: All tests passed!` | `No issues found!` |
| `map_battle` | `+1722: All tests passed!` | `No issues found!` |
| `map_runtime` | `+1909`, 1 skip déclaré, `All tests passed!` | `No issues found!` |
| `map_editor` | `04:17 +4096: All tests passed!` | `No issues found! (ran in 3.7s)` |
| `playable_runtime_host` | `03:41 +76: All tests passed!` | `No issues found! (ran in 4.5s)` |

Total : **12 426 tests réussis**, plus un skip runtime explicitement déclaré.

Format Dart :

```text
dart format --output=none --set-exit-if-changed lib test tool
Formatted 1120 files (107 changed) in 3.86 seconds.
exit 1

dart format --output=none --set-exit-if-changed <11 fichiers Dart NSC-83>
Formatted 11 files (0 changed) in 0.16 seconds.
exit 0
```

Le contrôle package entier expose une dette de format préexistante sur 107
fichiers propres au commit initial et hors scope ; aucun des 11 fichiers Dart
du lot n'en fait partie. Les reformater aurait créé un churn massif et violé
la règle de modification chirurgicale. Ce signal P3 est conservé explicitement
au lieu d'être maquillé ; tests, analyses et builds restent verts.

Le premier run editor, avant corrections, avait terminé avec :

```text
+4057 -38: Some tests failed.
```

Il n'est pas masqué : il a servi à découvrir les régressions et références
stales décrites plus haut. Le run final complet est celui de 4 096 tests verts.

Smokes :

```text
packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
00:01 +3: All tests passed!

examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
00:01 +1: All tests passed!
```

Builds :

```text
cd packages/map_editor
/opt/homebrew/bin/flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app

cd examples/playable_runtime_host
/opt/homebrew/bin/flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app
```

Receipt runtime frais hérité de NSC-82 et revalidé par les suites complètes :

```text
profile: selbrume-release-v1
result: pass
projectFingerprint: sha256:dab55e949848f49bcfb863bc4c771ffbf0bed6cdad8f1203679a4232bf79d445
retry suites: 3 passed
player journey suites: 5 passed
```

## 10. Diffs / zones précises

- `narrative_validator_providers.dart` : import `dart:convert`, helper
  `_jsonTree`, normalisation de `project` et `activeMap` avant canonicalizer.
- `editor_shell_page.dart` : `LayoutBuilder`, seuil 956 px, largeur compacte
  52 px et handoff inspecteur/explorateur.
- `facts_world_rules_workspace.dart` : seuil hauteur 820 px, masquage des
  métriques secondaires et double scroll borné World Rule.
- `dialogue_studio_dialogs.dart` : suppression de la méthode `_save` privée
  inutilisée, sans modification du chemin de sauvegarde actif.
- tests : attentes Fact typées, scrolls réels, surfaces Cinematic adaptées,
  régressions snapshot/compact.
- images : recherche globale, nouveaux contrôles typés et layouts actuels.

`git diff --check` termine avec le code 0 et aucune sortie.

## 11. Limites et risques conservés

1. Le walkthrough humain n'est pas une ressaisie complète de la campagne ; la
   reconstruction exhaustive sans JSON est automatisée par NSC-80.
2. Quatre artefacts legacy restent lisibles avec migration visible. Ils ne
   constituent pas le chemin d'authoring normal.
3. Les 51 avertissements Selbrume sont des diagnostics de qualité, pas des
   erreurs bloquantes ; ils restent visibles et traçables.
4. Le Validator physique est statique et borné ; les parcours réels du host
   restent la preuve supérieure pour le mouvement pixel par pixel.
5. Le fallback Computer Use remplace Marionette uniquement pour cette session ;
   les captures et les tests permanents conservent la preuve reproductible.
6. La gate mécanique globale `FG-185` peut rester NO-GO/PARTIAL pour des
   dimensions hors Narrative Studio.
7. Le package editor contient 107 fichiers historiques que le formatter Dart
   3.13 voudrait réécrire ; les 11 fichiers Dart NSC-83 sont propres.

Aucune de ces limites n'est P0/P1 pour Narrative Studio v1 et aucune ne crée
une divergence connue entre un bouton publiable et le runtime.

## 12. Auto-critique finale

- Modifications inutiles : aucune détectée ; les changements produit répondent
  à des échecs réels du binaire ou de la suite complète.
- Effets de bord : les seuils responsive sont couverts par matrices et test de
  handoff ; aucun schema n'est modifié.
- Commentaires manquants : les normalisations et seuils non évidents sont
  commentés au point de décision.
- Tests insuffisants : la QA humaine reste non déterministe par nature, mais
  chaque résultat critique a une preuve automatisée permanente.
- Scope mélangé : le retrait de code mort Dialogue est justifié par la gate
  `flutter analyze`, sans refactor adjacent.
- Goldens accidentels : chaque image modifiée correspond à un changement
  inspecté ; relance normale de 272 tests puis suite complète verte.
- Mensonge utilisateur/moteur : aucun trouvé ; les commandes non supportées
  échouent explicitement et le Validator reste fail-closed.

## 13. Prochaine étape proposée

Proposer `DONE` pour NSC-83 et la Phase 8 Narrative Studio. Dans la roadmap
mécanique, rattacher ce Evidence Pack comme preuve des sous-dimensions
FG-180→FG-185 sans modifier leur statut global avant audit des autres
mécaniques.

## 14. État Git final avant commit

Tous les changements attendus sont ceux de l'inventaire ci-dessus. Les builds
et caches restent ignorés. Le micro-plan sous `docs/` est ignoré par la règle
historique du dépôt et doit être ajouté explicitement avec `git add -f`.

Revue finale avant indexation : `git diff --check` retourne 0 sans sortie ; le
statut ne contient aucun fichier étranger à l'inventaire NSC-83.

Commit attendu :

```text
feat(narrative): close Selbrume release gate
```

## 15. Contenu complet des fichiers texte créés

Le contenu complet du micro-plan, de la checklist et du guide est conservé
dans leurs fichiers versionnés et reproduit ci-dessous. Le présent Evidence
Pack ne peut pas s'auto-inclure sans récursion infinie.

### 15.1 Micro-plan NSC-83

```markdown
# NSC-83 — QA humaine, documentation et release gate

Date : 2026-07-21

Branche : `main`

## Contrat du lot

Clore la phase 8 avec un parcours réel des binaires macOS, une matrice de
validation complète, une documentation reproductible et un verdict honnête
sur la gate Narrative Studio v1. Ce lot n'autorise pas à déclarer terminé le
MVP mécanique global `FG-185`.

## Audit initial

- [x] Vérifier que NSC-80, NSC-81 et NSC-82 sont commités et que le dépôt est
  propre au commit `d7d3a2604`.
- [x] Lire la roadmap Narrative Studio, la roadmap mécanique et
  `codex_rule.md`.
- [x] Identifier les parcours desktop, les tests d'accessibilité, les tests de
  panne et la matrice de validation obligatoire.
- [x] Utiliser une copie jetable de `selbrume/` pour toute mutation humaine.

## Parcours humain réel

- [x] Ouvrir le binaire macOS de `map_editor` sur la copie Selbrume.
- [x] Inspecter Overview, Event Builder, un Event sélectionné et Validator.
- [x] Modifier le nom du joueur via Nouveau jeu, sauvegarder, fermer et
  relancer ; vérifier la persistance sur disque.
- [x] Lancer le binaire macOS du runtime host, charger Selbrume, sauvegarder et
  recharger la position `(17,24)` sur `map_bourg_selbrume`.
- [x] Capturer les états avant/après, validation, compactage et runtime.
- [x] Vérifier que le projet canonique source conserve son SHA-256.

## Accessibilité et résilience

- [x] Exécuter clavier, semantics, 200 % de texte, reduced motion, contraste et
  localisation.
- [x] Exécuter les matrices responsive, dont `1280x768` et `800x650`.
- [x] Injecter asset absent, écriture refusée, référence stale et commande
  runtime non supportée.
- [x] Corriger la sérialisation des géométries typées du snapshot Validator.
- [x] Corriger les overflows réels du shell et de Facts/World Rules.
- [x] Rebaser uniquement les goldens correspondant aux changements visuels
  intentionnels, puis les rejouer sans `--update-goldens`.

## Gate technique

- [x] `map_core` : tests et analyze.
- [x] `map_gameplay` : tests et analyze.
- [x] `map_battle` : tests et analyze.
- [x] `map_runtime` : tests et analyze.
- [x] `map_editor` : tests, analyze et build macOS debug.
- [x] `playable_runtime_host` : tests, analyze et build macOS debug.
- [x] Smoke tests Phase A runtime et host.
- [x] `git diff --check`.

## Documentation et verdicts

- [x] Écrire la checklist humaine reproductible.
- [x] Écrire le guide utilisateur Narrative Studio.
- [x] Actualiser la matrice de capacités.
- [x] Produire les passes manuelles nommées Audit/Architecture,
  Implémentation, Tests, Build/Validation et Critique finale.
- [x] Documenter les limites sans transformer la gate narrative en GO global
  du MVP.

## Verdict

`GO — Narrative Studio v1 / Selbrume`, sous réserve des limites explicites du
Evidence Pack. Aucun P0/P1 ni divergence editor/runtime n'est connu sur les
chemins de la matrice promue.
```

### 15.2 Checklist humaine

```markdown
# Narrative Studio v1 — Checklist humaine reproductible

Version de preuve : 2026-07-21
Lot : `NSC-83`
Projet : `selbrume/`

Cette checklist permet à une autre personne de reproduire la gate sans
contexte oral et sans modifier manuellement un JSON. Toujours travailler sur
une copie du projet pour les étapes qui écrivent.

## 1. Prérequis

- macOS avec Flutter `3.46.0-0.3.pre` et Dart `3.13.0-167.1.beta`, ou une
  version compatible avec le dépôt ;
- dépôt positionné sur le commit de la gate ou un descendant ;
- accès en écriture à un dossier de test ;
- aucun éditeur JSON utilisé comme outil d'authoring.

Contrôles initiaux depuis la racine :

    git status --short --untracked-files=all
    shasum -a 256 selbrume/project.json

Fingerprint attendu pour le manifeste canonique :

    a1ab8c3646be969745767effcda9f00f26f677e3acc1535a36cdcac6d4e3d7a0

## 2. Préparer une copie jetable

Copier le dossier `selbrume/` dans un emplacement local, ouvrir le
`project.json` de cette copie depuis l'éditeur, puis conserver le projet source
fermé. Le SHA-256 source doit être identique après le parcours.

## 3. Parcours Map Editor → Narrative Studio

1. Lancer l'application macOS `map_editor.app`.
2. Ouvrir la copie du projet Selbrume.
3. Vérifier le bandeau : projet chargé, synchronisé, sauvegardé, état bon.
4. Ouvrir Narrative Studio → Aperçu.
5. Attendre les compteurs attendus : 4 chapitres, 31 Scenes, 16 Cinematics,
   3 quêtes secondaires, 22 Dialogues, 49 Facts et 34 World Rules.
6. Ouvrir Événements : 31 Events doivent être listés.
7. Sélectionner un Event actif. Vérifier qu'il référence une vraie source de
   map, une Scene, des Facts/conditions et des conséquences lisibles.
8. Ouvrir Validateur et lancer la validation.

Résultat attendu : `Jouable`, 0 erreur bloquante. Les avertissements de qualité
restent consultables et ne sont pas présentés comme des erreurs.

## 4. Sauvegarde, fermeture et reload

1. Ouvrir Nouveau jeu.
2. Modifier le nom du joueur avec une valeur reconnaissable.
3. Sauvegarder depuis l'UI.
4. Fermer complètement l'application.
5. Relancer l'éditeur et rouvrir la même copie.
6. Revenir dans Nouveau jeu.

Résultat attendu : le nom est toujours présent ; aucun JSON n'a été édité à la
main et aucune donnée narrative n'a disparu.

## 5. Runtime réel

1. Construire puis lancer `playable_runtime_host.app`.
2. Charger la copie Selbrume.
3. Vérifier l'affichage de `map_bourg_selbrume`.
4. Déplacer le joueur, sauvegarder depuis l'overlay, puis recharger.

Résultat attendu : le runtime restaure la même map, la même position et le
même état. La session NSC-83 a vérifié la position `(17,24)`.

## 6. Accessibilité et petites fenêtres

Exécuter les tests suivants depuis `packages/map_editor` :

    /opt/homebrew/bin/flutter test \
      test/ui/canvas/narrative_studio_responsive_accessibility_test.dart \
      test/ui/canvas/narrative_studio_semantics_test.dart \
      test/ui/canvas/event_builder_v2_accessibility_test.dart \
      test/ui/shell/project_explorer_handoff_test.dart

Résultat attendu : navigation clavier et labels sémantiques présents, aucun
overflow à 200 % ni dans les fenêtres basses, compactage du panneau projet
quand les deux panneaux latéraux écraseraient la scène centrale.

## 7. Pannes à injecter

Ces contrôles sont automatisés pour rester déterministes :

| Panne | Preuve attendue |
|---|---|
| Asset Cinematic absent | fallback/diagnostic explicite, pas de crash |
| Écriture refusée | état de recovery visible, aucune fausse sauvegarde |
| Révision/référence stale | action de reprise, aucune écriture aveugle |
| Commande runtime non supportée | rejet fail-closed, jamais ignorée |

Commande minimale :

    cd packages/map_editor
    /opt/homebrew/bin/flutter test \
      test/cinematics_library_workspace_test.dart \
      test/ui/canvas/event_builder_v2_accessibility_test.dart \
      test/selbrume_event_v2_persistence_migration_test.dart

    cd ../map_runtime
    /opt/homebrew/bin/flutter test \
      test/cinematic_runtime_playback_controller_test.dart

## 8. Gate technique complète

Exécuter, package par package :

    cd packages/map_core && dart test && dart analyze
    cd ../map_gameplay && dart test && dart analyze
    cd ../map_battle && dart test && dart analyze
    cd ../map_runtime && flutter test && flutter analyze
    cd ../map_editor && flutter test && flutter analyze
    cd ../../examples/playable_runtime_host && flutter test && flutter analyze

Puis :

    cd packages/map_runtime
    flutter test test/phase_a_golden_battle_slice_smoke_test.dart

    cd ../../examples/playable_runtime_host
    flutter test test/phase_a_golden_slice_launch_test.dart

    cd ../../packages/map_editor
    flutter build macos --debug

    cd ../../examples/playable_runtime_host
    flutter build macos --debug

## 9. Critères GO / NO-GO

GO seulement si :

- aucune suite obligatoire n'échoue ;
- les deux applications macOS sont produites ;
- le Validator affiche 0 erreur bloquante ;
- save/close/reload et runtime save/load sont observés ;
- aucune commande publiée n'est silencieusement ignorée par le runtime ;
- aucune limitation P0/P1 n'est connue ;
- le projet source conserve son fingerprint.

Cette checklist ferme la gate Narrative Studio/Selbrume. Elle ne remplace pas
la release gate mécanique globale `FG-185`.
```

### 15.3 Guide utilisateur

```markdown
# Guide utilisateur — Narrative Studio

Version : Narrative Studio v1 / Selbrume, 2026-07-21

## Le modèle mental en une phrase

La map contient les choses physiques ; Narrative Studio décrit ce qui arrive
quand le joueur interagit avec elles.

Un PNJ, un objet ou une zone doit donc d'abord exister dans le Map Editor.
L'Event Builder ne crée pas une seconde copie de cet élément : il sélectionne
sa source physique et lui associe des conditions, une Scene et un comportement
narratif.

## Ordre d'authoring recommandé

1. **Maps** — placer les PNJ, objets, zones et points d'entrée physiques.
2. **Facts** — définir les informations persistantes du monde : booléens,
   nombres ou textes.
3. **Dialogues** — écrire les échanges et déclarer leurs outcomes.
4. **Cinematics** — préparer les séquences linéaires et leurs médias/FX.
5. **Scenes** — assembler Dialogue, Cinematic, Combat, Conditions, Actions,
   branches, merges et fins.
6. **Storylines** — organiser Chapters et Steps, puis lier les Scenes.
7. **Events** — choisir une source réelle de map et la Scene à lancer.
8. **World Rules** — projeter les Facts sur la visibilité, les dialogues et
   l'état des Events.
9. **Validateur** — corriger les erreurs, examiner les avertissements et
   produire une preuve runtime fraîche.

## Storylines, Chapters et Steps

Une Storyline représente un arc narratif. Ses Chapters structurent cet arc et
ses Steps décrivent la progression jouable. Utilisez les pickers de Scenes et
de dépendances : un ID technique ne doit pas être saisi manuellement dans le
workflow normal.

Le graph est une projection de la structure canonique. Déplacer un élément
dans le graph ne doit pas créer une deuxième vérité narrative.

## Dialogues et outcomes

Le Dialogue Studio conserve le document Yarn riche. Un outcome est un résultat
nommé, par exemple `accepted`, `refused` ou `completed`. Les Scenes utilisent
ces outcomes comme ports de sortie. Avant de renommer ou supprimer un outcome,
examinez ses consommateurs ; l'outil bloque les suppressions dangereuses.

Utilisez Preview pour vérifier la lecture, puis sauvegardez. Après fermeture et
reload, le document, son nœud d'entrée et ses outcomes doivent rester identiques.

## Scenes

Une Scene est le graphe exécutable :

- **Start** démarre le flux ;
- **Dialogue**, **Cinematic** et **Combat** attendent un résultat réel ;
- **Condition** lit un Fact, une Step ou un Event consommé ;
- **Action/Consequence** applique une commande typée ;
- **Branch** sépare les outcomes ;
- **Merge** rassemble des chemins ;
- **End** publie le résultat terminal et sa politique de retry.

Reliez toujours les ports nommés. Le Validator signale les chemins sans fin,
les références absentes et les outcomes impossibles.

## Events et sources de map

Dans Événements, la liste peut être regroupée par map, mais la map n'est pas
un conteneur narratif supplémentaire. Elle sert à retrouver les sources
physiques disponibles :

- entrée sur une map ;
- entrée dans une zone/trigger ;
- interaction avec un PNJ ;
- interaction avec un objet ;
- réception d'un outcome.

Pour créer un Event :

1. créer le brouillon et lui donner un nom lisible ;
2. choisir une source physique existante ;
3. ajouter les conditions avec les pickers de Facts/Events ;
4. choisir la Scene ;
5. régler réutilisation, reset, priorité et ordre ;
6. publier puis activer ;
7. lancer la simulation et le Validator.

Si la source physique n'existe pas, revenez au Map Editor pour la placer. Une
source proposée par l'Event Builder passe par une transaction récupérable : en
cas d'écriture interrompue, utilisez l'action de reprise au lieu de recréer la
source.

## Facts et World Rules

Les Facts sont la mémoire narrative persistante. Choisissez le type avant la
valeur et utilisez uniquement les opérateurs compatibles proposés par l'UI.

Les World Rules traduisent un état narratif en changement visible du monde.
Le simulateur permet d'essayer des Facts hypothétiques sans modifier le projet
et explique quelles règles contribuent au résultat.

## Cinematics

Une Cinematic reste linéaire : les décisions de gameplay appartiennent à la
Scene. La timeline peut contenir caméra, déplacement, orientation, emote,
dialogue, shake, fade, son, musique, FX et markers selon les contrats publiés.

Un média absent ou une commande non supportée doit produire un diagnostic
explicite. Ne publiez jamais une séquence qui ne peut pas être jouée par le
runtime.

## Validator

Le Validator sépare quatre dimensions :

- structure et références ;
- solvabilité narrative bornée ;
- atteignabilité physique ;
- receipt runtime frais.

`Jouable` signifie que les dimensions obligatoires passent pour le fingerprint
courant. Un budget dépassé reste `indeterminate`, jamais un succès. Les
avertissements supprimés restent traçables ; ils ne disparaissent pas sans
justification.

## Sauvegarde et recovery

- sauvegardez après une modification cohérente ;
- attendez l'état Synchronisé/Sauvegardé avant de fermer ;
- si une révision stale ou une écriture interrompue est détectée, utilisez
  l'action de recovery présentée par l'UI ;
- une demande de sauvegarde pendant une Scene awaitable est refusée sans
  écriture partielle ; sauvegardez après l'outcome/End ;
- vérifiez toujours une campagne importante par fermeture et reload.

## Compatibilité legacy

Les anciens GlobalStory et Map Events peuvent encore être lus et prévisualisés
pour migration. Ils ne sont pas le chemin d'authoring normal. Utilisez les
écrans de migration consolidés, examinez le diff, appliquez la conversion puis
validez. Ne modifiez pas l'ancien JSON comme solution permanente.

## Avant de livrer

1. sauvegarder, fermer et recharger le projet ;
2. lancer le Validator et obtenir 0 erreur bloquante ;
3. exécuter les chemins victoire, défaite et retry ;
4. sauvegarder/recharger dans le runtime ;
5. vérifier clavier, 200 % de texte et petite fenêtre ;
6. conserver le receipt correspondant exactement au fingerprint livré.

Pour la procédure exhaustive, suivre
`reports/narrativeStudio/completion/ns_completion_human_qa_checklist.md`.
```
