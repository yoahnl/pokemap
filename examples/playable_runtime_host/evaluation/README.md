# PokeMap Eval

PokeMap Eval pilote le runtime Selbrume à partir de scénarios JSON versionnés,
soit rapidement sans fenêtre, soit dans la véritable fenêtre macOS. Les deux
cibles produisent des événements ordonnés et un reçu portable sans modifier le
projet source ni les sauvegardes habituelles du joueur.

## Commandes

Depuis `examples/playable_runtime_host` :

```bash
dart run tool/pokemap_eval.dart list --project selbrume
dart run tool/pokemap_eval.dart run selbrume.shop.after-lysa
dart run tool/pokemap_eval.dart run selbrume.healing-service
dart run tool/pokemap_eval.dart run selbrume.shop.after-lysa \
  --target interactive
dart run tool/pokemap_eval.dart run selbrume.lysa-retry
dart run tool/pokemap_eval.dart run selbrume.mvp --policy certify
dart run tool/pokemap_eval.dart inspect --checkpoint after-lysa --facts --party --bag
dart run tool/pokemap_eval.dart history
dart run tool/pokemap_eval.dart web --project selbrume
```

Ajouter `--json` à `run`, `inspect` ou `history` produit une seule ligne JSON,
adaptée aux scripts et à la CI.

## Cockpit web local

La commande `web` ouvre le cockpit Timeline C dans le navigateur et réutilise
exactement les mêmes scénarios et reçus que la CLI :

```bash
dart run tool/pokemap_eval.dart web --project selbrume
dart run tool/pokemap_eval.dart web --project selbrume --no-open
dart run tool/pokemap_eval.dart web --project selbrume --port 55123
```

Le port `0` par défaut choisit automatiquement un port libre. Le serveur
n’écoute que sur `127.0.0.1`, injecte un jeton de session éphémère dans la page
et refuse toute mutation qui ne le présente pas. L’URL est transmise au
navigateur comme un argument de processus unique, sans shell.

Le cockpit permet de :

- choisir le projet et le scénario ;
- choisir une cible headless ou, lorsqu’elle est disponible, interactive ;
- régler la vitesse de lecture interactive sur 0,5×, 1× ou 2× ;
- suivre chaque étape dans la timeline en direct ;
- mettre en pause, avancer d’une étape, reprendre ou annuler ;
- inspecter Diff, State, Trace et Proof ;
- retrouver les reçus des exécutions précédentes.

La capacité interactive est annoncée uniquement sur macOS lorsqu’un exécutable
Flutter local peut lancer le host desktop. Elle ouvre une fenêtre de jeu réelle
et utilise les mêmes écrans Boutique, Centre Pokémon et PC que le joueur. La
« Vitesse de lecture » ne modifie ni le delta de simulation Flame ni les
calculs de combat : elle agit uniquement sur les délais entre les actions
automatisées et les avances de dialogue.

La cible ne change jamais la politique du scénario. Un scénario `probe` reste
diagnostique en interactif et une certification conserve toutes ses
restrictions.

## Politiques et preuves

- `probe` autorise les commandes `probe.*` pour préparer ou inspecter un état.
  Son reçu reste toujours `diagnosticOnly` et ne peut jamais servir de preuve
  de release.
- `certify` refuse tout raccourci `probe.*` avant de lancer Flutter. Une
  exécution réussie ne devient `releaseEvidence` que si tous les critères
  déclarés sont présents et passants.
- `selbrume.mvp` démarre obligatoirement une nouvelle partie, rejoue les
  actions physiques du démonstrateur et couvre exactement `MVP-01` à
  `MVP-19`.

L’adaptateur FG-185 vérifie également le commit, le hash de l’arbre projet, la
cardinalité des critères et le chemin de chaque preuve avant de transmettre les
résultats au collecteur de release existant.

## Codes de sortie

| Code | Signification |
|---:|---|
| `0` | scénario réussi |
| `1` | assertion ou action de gameplay échouée |
| `2` | scénario invalide |
| `3` | panne d’infrastructure ou worker sans reçu |
| `4` | violation de politique |
| `130` | exécution annulée |

## Artefacts et isolation

Toutes les écritures sont confinées à des chemins ignorés par Git :

```text
build/pokemap-eval/runs/<run-id>/
  worker-request.json
  worker-result.json
  events.jsonl
  receipt.json
  artifacts/
    frame-metrics.json
    <capture-demandee>.png

build/pokemap-eval/cache/<provenance>/<checkpoint-id>/
  manifest.json
  save.json
```

Un checkpoint n’est réutilisé que si le hash du projet, le digest du code
d’évaluation, la version du scénario et la version de save correspondent
exactement. Un cache incomplet, altéré ou périmé est refusé.

Les métriques de frames sont agrégées uniquement pendant la run interactive :
nombre de frames, moyennes et maxima des durées build/raster. Une capture PNG
n’est créée que lorsqu’une étape `evidence.snapshot` la demande, ou lorsque la
capture du premier échec a été explicitement activée. Il n’existe aucune
capture automatique à chaque étape.

Le bridge interactif est réservé au debug, se connecte exclusivement en
loopback et exige un jeton éphémère fort. Une build release ignore tous les
defines d’évaluation et démarre sans port, jeton ou socket d’évaluation. Les
visualisations de collisions et de collisions PNJ restent forcées à `false`
pendant les runs interactives.

## Gate rapide et validation complète

La gate rapide couvre les contrats de scénario, la politique, le worker
headless et le smoke Boutique :

```bash
flutter test \
  test/evaluation/evaluation_scenario_parser_test.dart \
  test/evaluation/selbrume_evaluation_scenarios_test.dart
flutter test \
  test/evaluation/evaluation_policy_validator_test.dart \
  test/evaluation/evaluation_evidence_contract_test.dart
flutter test test/evaluation/headless_worker_process_test.dart
flutter test test/evaluation/interactive_release_absence_test.dart
flutter test test/evaluation/evaluation_target_parity_test.dart
dart run tool/pokemap_eval.dart run selbrume.shop.after-lysa
```

La validation complète du sous-système est :

```bash
flutter test test/evaluation
dart run tool/pokemap_eval.dart run selbrume.mvp --policy certify
flutter build macos --release
```
