# NSC-34 — Document Dialogue, nœuds Yarn et codec lossless

Date : 2026-07-20  
Phase : 3 — Scenes, Dialogues et Actions  
Verdict : **DONE proposé**

## Résumé exécutif

Le document Dialogue possède maintenant un cycle de vie immuable de nœuds : création, suppression, renommage, duplication, déplacement et sélection explicite du nœud d'entrée. Le renommage réécrit les jumps structurés et la duplication alloue de nouveaux IDs pour le nœud, ses blocs et ses branches.

Le codec Yarn conserve les headers ordonnés autres que `title`, notamment les `tags:` déjà présents dans Selbrume. Un document non modifié est réémis byte-for-byte à partir de son snapshot source ; après modification, une sortie canonique conserve headers, Unicode et commandes inconnues. Si le source utilise des espaces, lignes vides ou fins de ligne non canoniques, la validation affiche un avertissement avant sauvegarde au lieu de masquer une normalisation potentielle.

Le nœud d'entrée est émis en premier, seule représentation persistable compatible avec le wire Yarn simplifié actuel. Son choix survit donc au reload disque.

## Scope et audit initial

### État trouvé

- `DialogueEditorDocument` ne portait que `nodes` ; aucun entry explicite ni opérations de cycle de vie.
- `DialogueEditorNode` ne conservait aucun header autre que `title`.
- le parseur ignorait `tags:`, metadata inconnue, lignes vides et espaces de fin ;
- les commandes `<<…>>` inconnues étaient déjà conservées sémantiquement ;
- la validation refusait déjà titres dupliqués et jumps inconnus, mais pas document vide ni entry absente ;
- `selbrume/dialogues/goelise_port.yarn` prouvait immédiatement le risque réel avec plusieurs nœuds et un header `tags:` par nœud.

### Interprétation sûre du plan

Le fichier prévisionnel `packages/map_core/lib/src/operations/dialogue_library_tree.dart` gère la hiérarchie des fichiers, pas les nœuds internes Yarn. L'audit n'a trouvé aucun changement nécessaire dans ce contrat : le modifier aurait mélangé arborescence projet et contenu documentaire. Le lot reste donc volontairement concentré dans le modèle, le codec, la validation et leurs tests existants.

### Non-objectifs

- aucune UI de CRUD nœud dans ce lot ; elle appartient à NSC-36 ;
- aucune exécution conditionnelle ou commande runtime ;
- aucune modification des fichiers `.yarn` Selbrume ;
- aucune nouvelle syntaxe propriétaire de header entry ;
- aucune protection de dépendance Scene, réservée à NSC-35.

## Passes séparées (`codex_rule.md`)

La consigne système de cette tâche interdit de créer de nouveaux sub-agents. Les rôles imposés ont été exécutés comme passes locales séparées.

| Passe | Verdict | Conclusion |
|---|---|---|
| Lovelace — Audit / Architecture | Conforme | La perte de `tags:` était réelle ; la hiérarchie `map_core` ne devait pas être couplée au document Yarn. |
| Peirce — Implémentation | Conforme | Snapshot exact + modèle de headers + émission canonique forment une stratégie minimale et rétrocompatible. |
| Ramanujan — Tests / Build | Conforme | 39 tests ciblés verts, analyse verte, build macOS vert. |
| Critique finale | Conforme | L'entry survit au reload ; les jumps renommés et les IDs dupliqués sont couverts. |

## Fichiers modifiés

| Fichier | Zones | Impact |
|---|---|---|
| `packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_model.dart` | `DialogueSourcePreservation`, `DialogueEditorNodeHeader`, entry et opérations de `DialogueEditorDocument`, clonage profond | Contrat documentaire complet sans mutation partielle du document source. |
| `packages/map_editor/lib/src/features/dialogue/application/dialogue_yarn_codec.dart` | parse headers, snapshot source, émission canonique, ordre entry-first | Round-trip exact inchangé et extensions préservées après édition. |
| `packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_validation.dart` | document vide, entry absente, avertissement de formatage | Empêche un document structurellement invalide et rend la normalisation visible. |
| `packages/map_editor/test/dialogue_yarn_codec_test.dart` | rich headers/Unicode/formatting, édition canonique, entry reload | Prouve fidélité exacte, conservation des extensions et persistance de l'entrée. |
| `packages/map_editor/test/dialogue_editor_validation_test.dart` | invalidité, avertissement et cycle de vie complet | Prouve create/delete/rename/duplicate/reorder/entry et réécriture des jumps. |
| `packages/map_editor/test/dialogue_disk_hierarchy_v13_test.dart` | reload de `goelise_port.yarn` | Prouve la compatibilité avec un vrai document Selbrume multi-nœuds. |

Diff avant rapport : **6 fichiers, 579 insertions, 10 suppressions** environ ; le détail final est celui du commit.

## Tests et validations

Cycle rouge initial : les trois tests ne compilaient pas, car `DialogueEditorNodeHeader`, `entryNodeId`, `DialogueSourcePreservation` et les opérations de nœuds n'existaient pas encore.

Validation ciblée finale :

```text
cd packages/map_editor
flutter test test/dialogue_editor_validation_test.dart test/dialogue_yarn_codec_test.dart test/dialogue_disk_hierarchy_v13_test.dart test/dialogue_preview_runner_test.dart test/dialogue_studio_explorer_dialogue_widgets_test.dart --reporter failures-only
+39: All tests passed!
```

Analyse :

```text
flutter analyze
No issues found! (ran in 5.9s)
```

Build :

```text
flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

Hygiène :

```text
git diff --check -- <6 chemins NSC-34>
```

Résultat : code 0, aucune sortie.

La suite complète `map_editor` n'a pas été relancée pour ce lot car une autre commande `flutter test --reporter failures-only` issue d'un autre worktree était encore active. Les tests ciblés incluent tous les tests directement concernés et les non-régressions preview/widgets Dialogue.

## État git

### Initial

Le commit de départ du lot est `3cd7db78`. Le worktree contient toujours des changements utilisateur Selbrume hors scope, dont `examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart` déjà stagé.

### Final attendu après commit ciblé

- les six fichiers NSC-34 et ce rapport sont commités ;
- le staging Lighthouse reste hors commit et intact ;
- les autres changements Selbrume restent non commités ;
- aucun push n'est réalisé.

## Contenu complet des fichiers créés

Le seul fichier créé par NSC-34 est le présent Evidence Pack ; son contenu complet est ce document. Tous les tests ont été ajoutés à des fichiers existants.

## Auto-critique et risques restants

- Après une édition sémantique, les détails de whitespace sans représentation no-code sont normalisés. Cette limite est honnêtement signalée dans les diagnostics ; un futur modèle trivia par ligne serait plus lourd et n'est pas justifié ici.
- Les headers sont conservés comme paires nom/valeur génériques. Le Dialogue Studio n'offre pas encore d'éditeur spécialisé pour `tags`; NSC-36 pourra les présenter sans modifier le wire.
- Le modèle demeure compatible avec les constructions legacy qui omettent `entryNodeId` en utilisant le premier nœud. Le codec, lui, rend toujours l'entrée explicite au chargement.
- Les objets internes restent éditables par l'UI historique. Les opérations de document offrent une voie immuable sûre, mais NSC-36 devra migrer les mutations de nœuds vers ces opérations.

## Statut et suite

`NSC-34` : **DONE proposé**.  
Suite : `NSC-35 — Outcomes Dialogue et protections de dépendances Scene`.
