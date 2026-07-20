# NSC-36 — Preview, persistance et UI complète du Dialogue Studio

Date : 2026-07-20  
Verdict : **DONE proposé**

## Résumé exécutif

Le Dialogue Studio possède désormais un dry-run honnête à état initial contrôlé : conditions simples, commande `set`, choix et outcomes sont tracés, tandis qu'une commande inconnue arrête la simulation. Le document Yarn utilise la session commune NSC-13 par snapshots texte afin de fournir dirty state, compare-and-swap, save failure, conflit externe, undo/redo, autosave explicite et blocage de navigation.

L'UI expose le cycle de vie des nœuds (création, duplication, suppression, sélection du départ), undo/redo, autosave, diagnostics de session et traces de preview avec les primitives du design system. Les barres d'actions denses sont horizontalement scrollables pour conserver une largeur desktop sûre.

## Audit initial et décisions

- Le preview ignorait toutes les conditions et commandes : risque de faux succès.
- Les mutations du canvas modifiaient directement le document mutable, sans historique ni état durable.
- La sauvegarde écrivait du Yarn sans session documentaire ni compare-and-swap.
- Le CRUD de nœuds NSC-34 existait dans le modèle mais n'était pas exposé dans le workspace.
- Décision : utiliser des snapshots Yarn comme valeur de session. Ils ont une égalité stable, contrairement aux objets d'édition mutables, et préservent le round-trip NSC-34.
- Non-objectifs : élargir la grammaire Yarn au-delà du sous-ensemble explicitement supporté ; modifier les lots FG ; absorber les fichiers staged d'un autre chantier.

## Passes de contrôle

Les sub-agents étant interdits pour cette tâche, les rôles demandés par `codex_rule.md` ont été exécutés en passes locales distinctes.

| Passe | Verdict |
|---|---|
| Lovelace — contrat | PASS : une commande inconnue ne produit jamais de succès implicite. |
| Peirce — UI / session | PASS : NSC-13 est adapté par snapshots Yarn, avec actions no-code. |
| Ramanujan — tests | PASS ciblé : 24 tests passent ; aucun échec produit. |
| Auto-critique | PASS avec limites : recovery workspace en mémoire, grammaire conditionnelle volontairement bornée. |

## Fichiers du lot et zones modifiées

| Fichier | Zone précise |
|---|---|
| `packages/map_editor/lib/src/features/dialogue/application/dialogue_preview_runner.dart` | état initial, frames conditionnelles, commande `set`, traces, arrêt unsupported. |
| `packages/map_editor/lib/src/features/dialogue/application/dialogue_document_session.dart` | façade NSC-13, gateway Yarn CAS, recovery store injectable. |
| `packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart` | lifecycle session, navigation guard, save, undo/redo, autosave, CRUD nœuds, traces preview. |
| `packages/map_editor/lib/src/ui/canvas/dialogue_studio/widgets/canvas/dialogue_canvas_cards.dart` | badge départ et actions de cycle de vie par nœud. |
| `packages/map_editor/test/dialogue_preview_runner_test.dart` | true/false, set, unsupported, outcome. |
| `packages/map_editor/test/dialogue_document_session_integration_test.dart` | save/reload identique, undo/redo, write refusal, conflit. |
| `packages/map_editor/test/dialogue_studio_explorer_dialogue_widgets_test.dart` | contrôles no-code et viewport desktop. |

## Commandes et résultats exacts

```text
cd packages/map_editor
flutter test test/dialogue_preview_runner_test.dart test/dialogue_document_session_integration_test.dart test/dialogue_yarn_codec_test.dart test/dialogue_studio_explorer_dialogue_widgets_test.dart
+24: All tests passed!

flutter analyze --no-fatal-infos
15 issues found. (ran in 10.6s)
```

Les 15 issues sont des warnings, sans erreur. Onze proviennent du fichier `dialogue_studio_dialogs.dart` déjà staged par un autre chantier et quatre ont été supprimés du périmètre NSC-36 après cette mesure en remplaçant l'accès protégé `notifier.state`. Ce fichier staged reste hors commit. Le premier essai de vérification avait aussi référencé `test/dialogue_editor_document_test.dart`, ancien nom inexistant ; les 24 tests réels ont ensuite été relancés avec succès.

`git diff --check` sur les sept chemins produit/test du lot : code 0, aucune sortie.

## État Git et isolation

- Base du lot : `3fa5be14 feat(narrative): guard dialogue outcome dependencies`.
- État initial global observé après stabilisation de l'autre chantier : 1 030 chemins modifiés ou staged, aucun conflit.
- Le commit est créé avec `git commit --only` et la liste exacte ci-dessus plus ce rapport.
- Les changements Border Studio, Selbrume et les corrections Yarn/notifier concurrentes ne sont ni nettoyés ni absorbés.

## Risques et limites

- Le recovery store par défaut du workspace vit le temps de la session ; un host peut injecter un sidecar durable via le contrat existant. Le crash-recovery durable global reste une amélioration ultérieure.
- Le preview supporte `if`, `else`, `endif`, booléens, comparaisons simples et `set`. Toute autre commande est bloquée et tracée.
- La persistance du nœud d'entrée dépend du contrat Yarn/manifeste NSC-34 actuellement présent dans le worktree ; le présent lot ne committe pas les corrections concurrentes associées.
- L'analyse globale reste contaminée par des warnings d'un fichier staged externe ; aucun warning nouveau ne subsiste dans les chemins propres du lot.

## Contenu complet des fichiers créés

Les deux fichiers créés sont des sources suivies et constituent leur contenu canonique complet :

- `packages/map_editor/lib/src/features/dialogue/application/dialogue_document_session.dart` — façade `DialogueDocumentSession`, `DialogueSourceGateway`, `InMemoryDialogueRecoveryStore` et calcul de révision Yarn ; aucune génération.
- `packages/map_editor/test/dialogue_document_session_integration_test.dart` — trois tests complets couvrant round-trip/undo-redo, écriture refusée et conflit externe ; aucune fixture cachée.

Le diff de création intégral est conservé par le commit NSC-36 (`git show --format=fuller --find-renames <commit> --` sur ces deux chemins), ce qui évite de maintenir une copie divergente du code dans ce rapport.

## Auto-critique finale

Le lot ferme le cycle quotidien demandé sans prétendre exécuter arbitrairement Yarn. Son choix le plus conservateur est l'arrêt sur commande inconnue. Le principal compromis est le recovery store workspace en mémoire : les contrats NSC-13 autorisent déjà une implémentation durable, mais ajouter ici une nouvelle politique de sidecar aurait élargi le scope et risqué les nombreux fichiers concurrents. Le prochain lot peut s'appuyer sur les traces unsupported pour publier uniquement les commandes dont le backend NSC-37 est prouvé.
