# Audit produit, fonctionnel et technique ultra-complet — Avelune & PokeMap

**Date de référence :** 2026-07-28
**Dépôt audité :** `/Users/karim/Project/pokemonProject`
**Branche / commit :** `main` / `a3d741818c1961ac2f653da235bb30c20df75b00`
**Nature de l’audit :** lecture du code, des tests, des fixtures, des rapports, des
workflows et exécutions fraîches ; aucune modification de code.
**Verdict global :** `CONTRADICTORY` — le dépôt contient une base RPG et une
chaîne d’authoring beaucoup plus avancées que ne le disent plusieurs roadmaps,
mais la promesse complète « créer sans code, distribuer, installer dans Avelune,
jouer et terminer » n’est pas certifiée de bout en bout aujourd’hui.

> Les comparaisons avec les jeux de collection de créatures portent uniquement
> sur des fonctions abstraites et des parcours produit. Cet audit ne recommande
> aucune reprise d’asset, de personnage, de nom, de texte ou d’élément protégé.

---

## 1. Résumé exécutif

### 1.1 Verdict très simple

- **Avelune :** une vraie application joueur existe : bibliothèque, import
  sécurisé, installation transactionnelle, lancement du runtime, profils,
  slots, sauvegarde atomique, options et contrôles. Elle n’est toutefois pas
  encore une application mobile de production démontrée : le smoke iOS installé
  frais est rouge depuis l’ajout du dialogue d’identité, les opérations
  update/réparation/désinstallation ne sont pas câblées dans l’interface de
  production, aucune démo embarquée ni découverte de jeux n’existe, et aucune
  release Android/iOS signée et distribuée n’a été prouvée.
- **PokeMap :** l’éditeur no-code est vaste et possède réellement les cartes,
  événements, Facts/variables, conditions, commandes narratives, combats,
  rencontres, shops, soins, progression, fin de jeu et Personalization Studio.
  Les contrats et tests automatiques sont souvent solides. Le point non prouvé
  reste l’expérience créateur complète, depuis un projet vide jusqu’à une
  aventure exportée et terminable, réalisée uniquement dans l’UI sans IDs
  manuels ni intervention technique.
- **Peut-on créer et terminer une aventure complète ?** Une fixture canonique,
  Selbrume, est terminable automatiquement jusqu’à `finishGame`, l’écran de
  victoire et les crédits, avec un parcours installé évalué sur 19 critères.
  Cela prouve que le moteur peut exécuter une aventure complète préparée. Cela
  ne prouve pas encore qu’un créateur peut fabriquer et publier cette aventure
  entièrement via PokeMap, ni que le parcours est actuellement vert dans
  Avelune mobile : le smoke iOS frais échoue avant l’entrée en jeu.
- **Obstacle principal :** la fermeture et la certification de la chaîne
  produit transversale, pas l’absence d’un moteur de combat. Les briques
  existent, mais leur composition `éditeur → JSON → validation → package →
  Avelune → runtime → sauvegarde → fin` n’a pas un unique test de vérité à jour.

### 1.2 Ce qui est déjà particulièrement solide

1. Les frontières `map_core` / `map_gameplay` / `map_battle` / `map_runtime` /
   `map_player_ui` / `map_editor` sont nettes et testées.
2. Le catalogue narratif canonique est publié, sérialisable, diagnostiqué et
   relié au runtime. Les anciennes affirmations « commandes/Facts/variables
   absents » sont fausses.
3. Les mécaniques de base — starter, party, capture, combats simples,
   switch, statuts, PP, XP, montée de niveau, apprentissage, évolution,
   récompenses, sac, shop, soin, PC, badges et fin — possèdent du code et des
   tests frais.
4. Le format de package et l’import Avelune ont des protections substantielles
   contre traversée de chemin, liens, entrées spéciales, inventaires/digests
   incohérents et dépassement de quotas.
5. Personalization Studio possède une chaîne automatisée profonde : modèle,
   éditeur, aperçu, export, package, lecture Avelune/runtime et replis sur
   corruption.

### 1.3 Ce qui empêche un « prêt MVP » honnête

1. La gate mobile installée « Nouvelle partie » est actuellement rouge : le
   driver iOS ne traite pas le nouveau dialogue « Votre identité » et
   n’atteint pas l’état `playing`. Cela rend le produit `UNPROVEN` sur ce
   parcours, sans démontrer que la fonctionnalité elle-même est cassée.
2. Avelune expose des fondations de maintenance, mais la composition de
   production garde les updates désactivées via `UnsupportedError`; réparation,
   désinstallation et politiques de conservation des saves ne forment pas un
   parcours joueur actif.
3. Le test standard de crash atomique des saves Avelune dépasse 30 secondes :
   il échoue dans la suite normale mais passe isolément avec `--timeout 2m`.
4. Aucune preuve fraîche d’APK release signé publié, d’AAB Play, d’archive
   iOS/TestFlight Xcode Cloud, ni de notarisation macOS acceptée.
5. Le dashboard FG est cohérent avec sa propre source, mais sa source reste la
   roadmap : il affiche `DONE: 40 · PARTIAL: 12 · BLOCKED: 0 · TODO: 41 ·
   DEFERRED: 21` et contredit de nombreux contrats/tests actuels.
6. Aucune gate unique n’atteste un projet créé de zéro uniquement dans
   l’éditeur, exporté, importé sur mobile, joué humainement, sauvegardé, repris
   et terminé sur le même candidat de release.
7. L’export affiche « Package certifié », mais le pipeline
   `src/features/game_export` ne prouve pas l’appel des validateurs de projet,
   carte, narration et jouabilité ; il certifie surtout structure, compatibilité,
   hash, présentation et dialogues.
8. Les suites intégrales fraîches révèlent deux dettes de test que les
   sélections ciblées ne voyaient pas : un smoke runtime dépend d’un projet
   externe codé en dur sur le Desktop, et un budget performance éditeur échoue
   dans la suite concurrente tout en passant isolément.

### 1.4 Tableau rapide des quinze priorités

| Rang | Fonctionnalité | Produit | Statut | Impact | Effort | Pourquoi maintenant |
|---:|---|---|---|---|---|---|
| 1 | Gate de jouabilité avant export | PokeMap | `CONTRADICTORY` | Un package « certifié » peut rester injouable | M | Le validator existe mais n’est pas appelé par l’export |
| 2 | Golden journey éditeur→Avelune→fin | Transverse | `MISSING` | La promesse produit centrale n’a pas de preuve unique | XL | C’est l’arbitre qui empêchera les futurs faux positifs |
| 3 | Smoke iOS avec écran d’identité | Avelune | `CONTRADICTORY` | Nouvelle partie n’atteint plus le gameplay dans le test installé | S | Régression fraîche, localisée et directement visible au joueur |
| 4 | Câblage update/réparation/désinstallation | Avelune | `PARTIAL` | Bibliothèque non maintenable sans intervention technique | M | Les services existent déjà, le coût marginal est raisonnable |
| 5 | Picker de rencontre statique | PokeMap | `CONTRADICTORY` | L’auteur produit un payload rejeté par les diagnostics | S | Faux-complet no-code à forte valeur gameplay |
| 6 | Timeout du test de save atomique | Avelune | `CONTRADICTORY` | La suite standard et donc la confiance CI restent rouges | XS | Le comportement passe en 31–37 s avec un budget adapté |
| 7 | Storylines exécutables | PokeMap/runtime | `PARTIAL` | L’histoire est structurée mais plusieurs métadonnées sont inertes | L | La progression narrative est nécessaire pour terminer un RPG |
| 8 | Cadeau avec party pleine vers PC | PokeMap/runtime | `PARTIAL` | Un cadeau scénarisé peut échouer dans une partie normale | M | Cas joueur courant, facile à rendre atomique et testable |
| 9 | Contrat public `.avelunegame`/`.pokemapgame` | Transverse | `CONTRADICTORY` | Import, communication et tests divergent selon la plateforme | M | Il conditionne export, association de fichiers et migration |
| 10 | Publication directe vers Avelune | PokeMap→Avelune | `CONTRADICTORY` | L’UI créateur expose encore « PokeMap Hub » | M–L | L’identité publique imposée n’est pas respectée de bout en bout |
| 11 | Cutscene Studio historique | PokeMap/runtime | `CONTRADICTORY` | Des blocs sauvegardables n’ont aucun effet ou sont bloqués | M–L | Il faut masquer, migrer ou implémenter avant publication |
| 12 | Conditions fail-closed | PokeMap/runtime | `PARTIAL` | Un état legacy malformé peut lever une exception | S | Petit durcissement sur un chemin de progression critique |
| 13 | Vidéo intro portrait | PokeMap/Avelune | `CONTRADICTORY` | L’éditeur l’accepte mais le player force le 16:9 | S–M | Divergence de preview concrète du Personalization Studio |
| 14 | Connexions de cartes E2E | PokeMap/runtime | `PARTIAL` | Une aventure multi-cartes n’a pas de preuve authoring→transition | M | Exploration et progression dépendent de cette jonction |
| 15 | Releases signées et installées | Avelune/PokeMap | `UNPROVEN` | Impossible de déclarer une distribution production | L | Les builds locaux ne remplacent ni signature ni stores |

### 1.5 Trois stratégies possibles

**Stratégie centrée Avelune.** Fermer d’abord le parcours mobile : premier
démarrage, démo, import, maintenance de bibliothèque, saves, reprise,
diagnostics et distribution signée.

- Avantages : transforme rapidement le moteur existant en produit joueur
  démontrable ; réduit le risque App Store/Play Store et les régressions de
  cycle de vie.
- Risques : peut polir un contenant alors que l’éditeur publie encore des
  projets invalides ; l’offre de jeux reste faible sans chaîne créateur
  fiable.

**Stratégie centrée PokeMap/no-code.** Fermer l’authoring, le playtest et le
release gate, puis faire consommer exactement le même artefact certifié par
Avelune.

- Avantages : traite le principal risque observé — les faux-complets
  modèle/UI — et rend chaque fonctionnalité reproductible par un créateur sans
  code ; capitalise sur le moteur déjà riche.
- Risques : les problèmes natifs Avelune et la distribution signée peuvent
  rester tardifs si les lots ne gardent pas un smoke mobile obligatoire.

**Stratégie centrée mécaniques RPG.** Ajouter de la profondeur : météo/terrain,
held items, field abilities, arènes/rival, postgame, puis fonctions différées.

- Avantages : rapproche l’expérience de la richesse d’un RPG de collection de
  créatures principal et valorise `map_battle`.
- Risques : accroît la surface sans résoudre export, installation, validation
  et production ; ce serait aujourd’hui le plus grand risque de dispersion.

**Recommandation unique : stratégie PokeMap/no-code, avec gate transverse
Avelune obligatoire à chaque phase.** Le dépôt ne manque pas d’un deuxième
moteur de combat ; il manque une chaîne de vérité fermée. La séquence
recommandée corrige d’abord les authorings trompeurs et l’export, produit un
artefact unique certifié, puis exige que cet artefact soit installé, repris et
terminé dans Avelune. La distribution native devient alors un lot de
production mesurable, et non une validation abstraite.

---

## 2. Périmètre et méthode

### 2.1 Périmètre inspecté

- packages purs : `map_core`, `map_gameplay`, `map_battle`,
  `map_distribution` ;
- packages Flutter : `map_runtime`, `map_player_ui`, `map_editor` ;
- application joueur : `apps/pokemap_hub` dans sa composition publique
  Avelune sur iOS/Android ;
- host et fixtures : `examples/playable_runtime_host`, Selbrume et Golden
  Slice ;
- certification : `tool/pokemap_product_certification` ;
- intégration et production : `.github/workflows`, scripts Xcode Cloud,
  manifests Android/iOS, rapports et reçus ;
- gouvernance : `AGENTS.md`, `codex_rule.md`, `skills/README.md`,
  `pokemap_roadmap_mecaniques_fangame.md` et dashboard FG.

### 2.2 Instructions et skills lus avant le rapport

Les fichiers suivants ont été lus intégralement avant la rédaction :

- `AGENTS.md` racine — aucun `AGENTS.md` plus proche ne s’applique au rapport ;
- `codex_rule.md` ;
- `skills/README.md` ;
- `pokemap_roadmap_mecaniques_fangame.md` — 2 055 lignes et 127 identifiants
  FG uniques inventoriés ;
- skills locaux `using-superpowers`, `dispatching-parallel-agents`,
  `writing-plans`, `verification-before-completion`,
  `systematic-debugging` ;
- skill `product-design:audit` et ses références obligatoires ;
- skill `test-flutter-desktop`.

Les skills ont imposé des passes indépendantes, une tentative d’observation
réelle des applications, une séparation stricte entre constat automatisé et
preuve humaine, et une vérification finale avant toute conclusion.

### 2.3 Modèle de preuve

Chaque fonction a été recherchée dans les six couches suivantes :

1. **modèle/JSON** : contrat, sérialisation, migration ;
2. **authoring** : interface no-code et pickers ;
3. **validation** : diagnostic avant export/exécution ;
4. **runtime** : exécution réelle, pas seulement présence d’un bouton ;
5. **persistance et UI joueur** : écriture/reprise et surface utilisable ;
6. **E2E** : scénario qui franchit les frontières précédentes.

Une roadmap ou un ancien rapport ne compte jamais comme preuve unique. Une
absence n’est retenue qu’après recherche dans le modèle, l’éditeur, le runtime
et les tests. Inversement, un modèle, un bouton ou un test unitaire isolé ne
suffit pas à déclarer une fonction complète.

### 2.4 Sémantique stricte des statuts

| Statut | Sens dans ce rapport |
|---|---|
| `COMPLETE` | La chaîne requise pour le périmètre annoncé est présente et possède une preuve fraîche suffisante. |
| `PARTIAL` | Plusieurs couches existent et fonctionnent, mais une ou plusieurs couches nécessaires manquent ou ne sont pas reliées. |
| `MISSING` | La recherche croisée n’a pas trouvé de fonction dédiée exploitable pour le besoin. |
| `DEFERRED` | La fonction est explicitement repoussée et n’est pas un blocker du MVP retenu. |
| `UNPROVEN` | Une implémentation ou une configuration paraît exister, mais aucune preuve fraîche suffisante n’a pu être produite. |
| `CONTRADICTORY` | Code, tests, exécution, rapport, CI ou roadmap donnent des vérités incompatibles. |

### 2.5 Passes indépendantes et verdicts

| Passe / rôle | Verdict | Apport |
|---|---|---|
| Audit / Architecture | `CONTRADICTORY` | Architecture saine ; dashboard auto-cohérent mais incomplet comme source de vérité, rapports imbriqués ignorés et roadmaps en retard sur le code. |
| Audit Avelune | `PARTIAL` | Fondations joueur réelles ; maintenance non câblée, démo/catalogue absents, production non prouvée et smoke iOS frais rouge. |
| Audit PokeMap/no-code | `PARTIAL` | Authoring très avancé, mais export non gaté, playtest global absent, Storylines/legacy incomplets et défauts no-code concrets. |
| Implémentation / vérité du code | `CONTRADICTORY` | Facts/shop/heal/badge/Surf/fin réellement câblés ; static générique, certification d’export et maintenance Avelune faux-complets. |
| Tests | `CONTRADICTORY` | Grande matrice ciblée verte ; suite Avelune standard rouge sur timeout, verte avec timeout étendu ; smoke iOS installé rouge. |
| Build / Validation | `CONTRADICTORY` | Builds Apple locaux verts, mais production non signée et prerelease mélangeant deux commits. |
| Critique finale | `CONTRADICTORY` avant corrections | Relecture hostile : état Git concurrent, traçabilité commandes, statuts static/narration/templates et roadmap à corriger ; intégration documentée §23.4. |
| Critique finale 2 | `COMPLETE` après corrections | Relecture de livraison : IDs de contradictions, preuve des sélections, registre E-*, granularité des lots, dépendances et DMG historiques corrigés puis revalidés ; verdict documenté §23.4. |

La demande utilisateur interdisait toute modification de code. La passe
« Implémentation » exigée par `codex_rule.md` a donc été transformée en passe
read-only **vérité de câblage** : lecture des compositions et adapters réels,
sans écrire l’implémentation ni créer/modifier des tests. La règle directe de
l’utilisateur prime ici sur la création habituelle de tests de cette passe.

### 2.6 Limites de la méthode

- Les exécutions ont lieu sur le working tree local, qui était déjà sale avant
  l’audit ; elles ne constituent donc pas une reproduction sur checkout propre.
- Les builds non signés/debug prouvent la compilabilité, pas une distribution
  App Store, Play Store ou Gatekeeper.
- Une fixture et un driver E2E peuvent prouver le moteur sans prouver
  l’ergonomie humaine de l’éditeur.
- Aucun appareil Android n’était connecté. Le téléphone iOS physique visible
  dans `flutter devices` n’a pas été modifié.
- Une première tentative desktop a perdu sa connexion ; une seconde a confirmé
  le projet actif et l’ouverture du Personalization Studio/Branding. Elle ne
  couvre pas le parcours création→export et les captures d’une autre instance
  ont été rejetées.

---

## 3. État Git initial

Commande :

```bash
git status --short --untracked-files=all
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD
```

Résultat initial exact :

```text
 M reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json
 M tool/pokemap_product_certification/pubspec.lock
?? packages/gamepads_darwin/macos/gamepads_darwin/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/gamepads_ios/ios/gamepads_ios/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
main
a3d741818c1961ac2f653da235bb30c20df75b00
```

Ces quatre changements préexistaient. Ils ont été considérés comme appartenant
à l’utilisateur, n’ont pas été restaurés, nettoyés, indexés ni modifiés par
l’audit. Aucun `git add`, commit, tag, push, release, checkout, stash ou autre
écriture Git n’a été effectué.

---

## 4. Inventaire architectural

### 4.1 Responsabilités et frontières

| Unité | Responsabilité constatée | Frontière publique / preuve |
|---|---|---|
| `packages/map_core` | Modèles JSON, manifests, événements, Facts/variables, conditions, commandes narratives, validation, saves, diagnostics. | Pur Dart ; barrel `lib/map_core.dart`. |
| `packages/map_gameplay` | Opérations overworld, party/bag/PC, capture, progression, shops, narration et outbox. | Pur Dart ; dépend de `map_core` ; barrel `lib/map_gameplay.dart`. |
| `packages/map_battle` | Moteur de combat, règles, actions, statuts, terrain de combat, capture, PP et résultats. | Pur Dart ; barrel `lib/map_battle.dart`. |
| `packages/map_runtime` | Session Flutter/Flame, monde, commandes, handoff combat, overlays, menus et save/load. | Barrel `lib/map_runtime.dart` ; règles principales gardées hors des composants Flame. |
| `packages/map_player_ui` | UI joueur réutilisable : HUD, menus, contrôles, préférences et surfaces de session. | Package Flutter indépendant de l’application publique. |
| `packages/map_distribution` | Construction, inspection, compatibilité, sécurité et intégrité des packages. | Pur Dart ; consommé par l’éditeur et Avelune. |
| `packages/map_editor` | Éditeur desktop no-code, builders, pickers, validation, aperçu, Personalization Studio et export. | Flutter macOS/Windows/Linux ; ne dépend pas des internals du runtime. |
| `apps/pokemap_hub` | Composition joueur publique Avelune sur iOS/Android ; bibliothèque, installation, sessions et saves. | Nom historique interne du dossier, identité publique calculée par `public_product_identity.dart`. |
| `examples/playable_runtime_host` | Host d’intégration, Selbrume, Golden Slice, smokes runtime et parcours complets. | Preuve interpackages ; ce n’est pas l’application de production. |
| `tool/pokemap_product_certification` | Outils et gates de certification transversale. | Preuves et reçus ; ne remplace pas une distribution signée. |

### 4.2 Taille de la surface auditée

Inventaire des fichiers Dart effectué avec `rg --files` et comptage des lignes
au moment de l’audit :

| Unité | Dart sous `lib/` | Dart sous `test/` | Dart outils/dev | LOC `lib/` | LOC `test/` | Plateformes déclarées |
|---|---:|---:|---:|---:|---:|---|
| `map_core` | 381 | 372 | 6 | 204 162 | 152 263 | — |
| `map_gameplay` | 41 | 54 | 0 | 11 768 | 15 198 | — |
| `map_battle` | 327 | 145 | 7 | 96 619 | 77 074 | — |
| `map_runtime` | 199 | 266 | 16 | 371 928 | 122 905 | — |
| `map_player_ui` | 40 | 21 | 0 | 8 957 | 4 838 | — |
| `map_editor` | 667 | 524 | 22 | 312 086 | 244 955 | macOS, Windows, Linux, Web |
| `map_distribution` | 28 | 14 | 0 | 7 042 | 4 207 | — |
| `apps/pokemap_hub` | 54 | 60 | 1 | 12 530 | 9 758 | Android, iOS, macOS, Windows, Linux |
| `playable_runtime_host` | 60 | 78 | 6 | 18 319 | 15 142 | Android, iOS, macOS |
| certification | 4 | 6 | 10 | 526 | 613 | — |

Le dépôt possède aussi 2 070 fichiers sous `reports/`, 46 fichiers de fixtures
éditeur, 10 fichiers dans la Golden Battle Slice et deux documents sous
`docs/combat`. Le volume documentaire élevé explique pourquoi les rapports
historiques se contredisent : il faut privilégier le code et les validations
fraîches.

### 4.3 Interfaces et contrats structurants

- `NarrativeCommandCatalog` publie les commandes `setFact`,
  `markEventConsumed`, `completeStoryStep`, `giveItem`, `takeItem`,
  `giveMoney`, `givePokemon`, `giveConfiguredStarter`, `healParty`,
  `awardBadge`, `unlockFieldAbility`, `finishGame`, `setNpcPresence`,
  `warp`, `openShop`, `openHeal`, `openPc`, `moveNpc`, ainsi que les nœuds
  dédiés dialogue, combat de trainer, rencontre statique et cinématique.
- `narrative_command_contract_parity_test.dart` vérifie la
  sérialisation, le diagnostic et le plan d’exécution de chaque commande
  publiable.
- `narrative_command_runtime_parity_test.dart` vérifie le passage des
  conséquences atomiques, les ports interactifs, les callbacks des nœuds
  dédiés et leur surface dans `PlayableMapGame`.
- `narrative_command_palette_test.dart` vérifie que la palette éditeur expose
  les commandes prêtes et masque les contrats incomplets.
- Le système de save est partagé par contrats dans `map_core`, appliqué par le
  runtime, puis persisté atomiquement par Avelune via `HubSaveStore`.
- `map_distribution` isole l’inspection/sécurité des archives de l’UI de
  l’éditeur et de l’application joueur.

### 4.4 Dashboard FG : utile, mais pas vérité produit

Commande fraîche :

```bash
cd packages/map_core
dart run tool/generate_gameplay_roadmap_dashboard.dart --check ../..
```

Résultat : exit `0`, aucune sortie stderr, dashboard cohérent avec les sources
qu’il sait lire :

```text
DONE: 40 · PARTIAL: 12 · BLOCKED: 0 · TODO: 41 · DEFERRED: 21
```

Cette réussite signifie « le fichier généré correspond à l’algorithme », pas
« le statut correspond au produit ». L’audit architecture a montré que
l’agrégateur :

- reste fondé d’abord sur la roadmap ;
- ignore 41 rapports Markdown et 12 reçus JSON imbriqués à cause d’une
  ingestion non récursive ;
- n’associe que le premier FG dans certains noms de fichiers multi-lots ;
- reconnaît certaines formulations anglaises comme `Proposed status:` mais
  pas toutes les formulations françaises historiques.

Le dashboard doit donc devenir consommateur d’un registre de preuves
structuré, et non arbitre autonome de complétude.

---


## 5. Audit Avelune — application joueur

### 5.1 Premier démarrage, bibliothèque et import

La composition de production démarre sur `PokeMapHubApp` mais injecte
`publicProductName`, qui retourne **Avelune** sur Android et iOS. Le shell sait
afficher une bibliothèque vide, lancer le picker d’import et refléter
l’installation dans `GameLibraryStore`.

L’import n’est pas un simple unzip :

1. sélection/entrée native via les adapters Android, iOS et macOS ;
2. copie vers une source contrôlée ;
3. inspection du package et vérification de compatibilité ;
4. contrôles d’archive et d’inventaire ;
5. staging, smoke de chargement et journal de transaction ;
6. promotion atomique et mise à jour de la bibliothèque ;
7. résolution des assets uniquement depuis l’arbre installé.

Preuves principales :

- `lib/src/platform/android_hub_platform_adapter.dart` ;
- `lib/src/platform/ios_hub_platform_adapter.dart` et
  `ios/Runner/AppDelegate.swift` ;
- `lib/src/install/game_package_installer.dart`,
  `game_installation_transaction.dart`, `installed_game_verifier.dart` ;
- `lib/src/library/game_library_store.dart` ;
- `test/install/game_package_installer_test.dart`,
  `game_install_recovery_test.dart`,
  `installed_game_verifier_concurrency_test.dart` ;
- `test/platform/android_hub_platform_adapter_test.dart`,
  `ios_distribution_contract_test.dart`.

Les deux extensions `.avelunegame` et `.pokemapgame` sont acceptées sur les
ports mobiles. L’identité publique iOS décrit le type comme « Avelune Game
Package », mais l’éditeur et certains contrats utilisent encore
`.pokemapgame` comme extension canonique alors que les tests Android
privilégient `.avelunegame`. Ce n’est pas une absence fonctionnelle, mais un
contrat de distribution `CONTRADICTORY` à stabiliser.

La bibliothèque vide est utilisable, mais elle ne contient ni démo embarquée,
ni bouton « jouer maintenant », ni catalogue/découverte. Pour un premier
démarrage grand public, l’utilisateur doit déjà posséder un package externe.

### 5.2 Installation, lancement, Nouvelle partie et Continuer

`InstalledGameLaunchResolver`, `HubInProcessSessionFactory`,
`HubRuntimeGameSource` et `HubInstalledGamePlayer` chargent le projet depuis
l’installation, construisent une session runtime et exposent Nouvelle partie
et Continuer. Les écrans de profils et de slots sont réels ; l’application ne
se contente pas de déléguer à une fixture.

L’exécution fraîche sur le simulateur **iPhone 17 Pro** a donné un signal
important :

```bash
cd apps/pokemap_hub
flutter test integration_test/runtime_owned_player_flow_test.dart \
  -d 53A65644-3BE1-4AF0-9AF3-CD792CA62612
```

- build et installation iOS simulator réussis ;
- package de test chargé et écran titre atteint ;
- après tap sur Nouvelle partie, le nouveau dialogue de personnalisation
  « Votre identité » apparaît ;
- le driver attend directement l’état `playing`, ne remplit pas nom/pronoms et
  finit en timeout ;
- résultat : exit `1`, `+0 -1` après un build Xcode d’environ 51,3 s.

Cette exécution ne démontre pas que Nouvelle partie est intrinsèquement cassée :
elle démontre que **la preuve installée n’a pas suivi l’évolution produit**.
Tant que le driver ne franchit pas le vrai parcours d’identité puis ne vérifie
pas save/teardown/Continue, la gate mobile reste rouge.

### 5.3 Profils, slots, saves et cycle de vie

`HubSaveProfileManager`, `HubSaveStore`, `HubPlayerSaveGateway`,
`HubSessionCheckpointCommitter` et `HubSaveLifecycleCoordinator` couvrent :

- plusieurs profils ;
- plusieurs slots par jeu et isolation entre jeux/profils ;
- métadonnées, preview et sélection dans l’UI ;
- enveloppes versionnées et migration ;
- écriture via fichier temporaire, remplacement atomique, backup et reprise ;
- récupération de candidats current/backup/temp ;
- commit de checkpoint du runtime ;
- coordination avec le cycle de vie.

Les tests de profils, isolation, migration, corruption, gateway et lifecycle
sont présents et majoritairement verts. Une contradiction fraîche subsiste :

```bash
cd apps/pokemap_hub
flutter test --no-pub -r expanded
```

donne `+189 -1` : le cas
`recovers after a process dies at every atomic write stage` dépasse le timeout
de 30 s. Isolé avec le même timeout, il échoue encore ; isolé puis dans la
suite avec `--timeout 2m`, il passe, et la suite donne `+190`. La logique est
donc couverte, mais la gate standard est instable/trop stricte et ne peut pas
être décrite comme verte.

Il n’existe pas de parcours joueur d’export/import de sauvegarde. Le
`LegacyGlobalSaveImporter` existe et est testé, mais n’est pas exposé comme
outil général de sauvegarde portable.

### 5.4 Update, réparation et désinstallation

`GameMaintenanceService` contient de vraies transactions de réparation,
désinstallation d’une version, fallback et désinstallation d’un jeu, avec des
tests dédiés. L’UI possède aussi les actions et motifs désactivés correspondants.

Mais la composition de production ne fournit que `onImportRequested` :

```dart
final actions = HubUiActions(
  onImportRequested: () {
    unawaited(initializedComposition._pickAndImport());
  },
);
```

De plus, l’installer de production fournit une callback
`prepareSavesForUpdate` qui lève explicitement `UnsupportedError` tant que les
migrations de save ne sont pas récupérables. En conséquence :

- le backend de maintenance est réel ;
- update/réparation/désinstallation ne sont pas des parcours utilisateur
  actifs ;
- conservation ou suppression des saves n’est pas un choix joueur démontré ;
- la récupération d’une transaction d’installation existe, mais son appel
  systématique au bootstrap de production n’est pas prouvé.

### 5.5 Contrôles, affichage, accessibilité et diagnostics

Les couches runtime/host possèdent contrôles tactiles, profils de contrôle,
pont gamepad, menu pause et préférences. Avelune persiste préférences joueur et
préférences d’affichage. Les manifests iOS autorisent portrait et paysage ;
les widgets utilisent des surfaces responsives et plusieurs `SafeArea`.

La preuve reste inégale :

- contrôles tactiles et bridge gamepad : tests automatiques verts ;
- manette physique : non testée ;
- bouton Retour Android : contrats et navigation widget, pas de test frais sur
  appareil Android ;
- rotation réelle, clavier externe, Dynamic Type très élevé, lecteur d’écran,
  contraste et zones sûres sur appareils à encoche : non parcourus
  humainement ;
- diagnostics locaux et recommandations de réparation : présents ;
- remontée distante/consentie d’erreurs : absente.

### 5.6 Identité publique Avelune

Points conformes :

- label Android : `Avelune` ;
- `CFBundleDisplayName` iOS : `Avelune` ;
- application/bundle ID : `com.yoahnl.avelune.player` ;
- identité Flutter de production : Avelune pour `android` et `ios` ;
- type de document iOS : « Avelune Game Package » ;
- tests `public_product_identity_test.dart` et release mobile.

Les chaînes « PokeMap Hub » restantes sont des noms internes, valeurs desktop
ou defaults de widgets de développement. Elles ne sont pas injectées par la
composition mobile de production. Il faut néanmoins garder une gate
automatique sur l’artefact final, car l’acceptation legacy de
`.pokemapgame`, les logs et les écrans d’erreur sont des voies possibles de
régression publique.

### 5.7 Verdict Avelune

**`PARTIAL`** : Avelune n’est plus un prototype vide ; ses fondations
d’installation, session et sauvegarde sont substantielles. Son problème est la
fermeture produit : premier démarrage sans jeu, parcours installé mobile rouge,
maintenance non câblée, portabilité des saves absente et distribution signée
non prouvée.

---

## 6. Audit PokeMap — éditeur no-code

### 6.1 Création et monde

Le package `map_editor` possède des use cases et surfaces pour :

- créer/ouvrir un projet ;
- créer et éditer des cartes ;
- poser et inspecter tiles, collisions et terrains ;
- définir zones, connexions et destinations ;
- créer des PNJ, leurs apparences, présence et interactions ;
- prévisualiser et valider avant export.

Les données sont des contrats PokeMap ; Tiled, RMXP ou un SDK tiers ne sont pas
des dépendances runtime. Les pickers et builders visent une expérience guidée,
mais des champs techniques/IDs restent possibles dans des zones avancées et
certains liens inter-ressources. La règle « aucun ID manuel dans le parcours
normal » n’est donc pas encore prouvée globalement.

### 6.2 Narration no-code : état réel

Contrairement à plusieurs anciens TODO, les éléments suivants existent :

- dialogues, choix et branches ;
- Event Builder V2 ;
- Scenes et Storylines ;
- Facts/flags et variables, avec deux voies historiques encore à unifier ;
- conditions simples et composées ;
- catalogue canonique de commandes ;
- pickers de Facts, scènes, story steps, maps, NPC, items, espèces et autres
  ressources ;
- templates et nœuds dédiés ;
- diagnostics de publication.

La chaîne est particulièrement forte pour le catalogue narratif :

```text
palette éditeur
→ commande typée map_core
→ JSON
→ diagnostic / plan
→ exécution runtime
→ conséquence atomique ou port interactif
→ save
→ tests de parité
```

Les preuves cardinales sont :

- `packages/map_core/lib/src/read_models/narrative_command_catalog.dart` ;
- `packages/map_core/test/narrative_command_catalog_test.dart` ;
- `packages/map_core/test/narrative_command_contract_parity_test.dart` ;
- `packages/map_core/test/narrative_authoring_golden_path_test.dart` ;
- `packages/map_editor/test/ui/canvas/narrative_command_palette_test.dart` ;
- `packages/map_runtime/test/narrative_command_runtime_parity_test.dart`.

Les statuts roadmap FG-080/081/088 qui laissent entendre que commandes,
conditions ou Facts seraient encore globalement absents sont donc
`CONTRADICTORY`. Une nuance importante ne doit pas être masquée : Event Builder
V2 authorise surtout Facts et événements consommés, tandis que
`StoryFlags`/`ScriptVariables` et `setVariable` restent une voie legacy.
Le bridge `SaveData` réinitialise actuellement les `scriptVariables` dans
`game_state_persistence.dart` autour de la ligne 31, alors que l’enveloppe
canonique de `GameState` sait conserver l’état complet. Les variables existent
donc réellement, mais leur chaîne cross-save n’est que `PARTIAL`.

### 6.3 Builders de gameplay et de progression

L’éditeur possède des surfaces dédiées ou des commandes typées pour :

- combats de trainers ;
- rencontres statiques ;
- cadeaux de créatures et starter configuré ;
- boutiques dynamiques ;
- soin ;
- badges ;
- déverrouillage de capacités terrain ;
- cinématiques ;
- fin de jeu et crédits ;
- déplacement/présence de PNJ et warp.

Le niveau de finition diffère : shop, soin, starter, trainer battle et fin de
jeu ont des chaînes runtime fortes. Le boss statique Selbrume spécialisé est
fort, mais le static générique ne l’est pas. Les capacités terrain au-delà de
Surf, les objets tenus, certains objets cachés et les templates d’arène/rival
restent moins guidés.

La passe indépendante de vérité de câblage a toutefois invalidé deux
généralisations :

- **rencontre statique générique — `CONTRADICTORY`** : le catalogue transforme
  `speciesId` en `battleTemplateId` sans `trainerId`
  (`narrative_template_catalog.dart` autour de la ligne 751), puis
  `SceneBattleRuntimeOutcomeAdapter` refuse tout intent sans `trainerId`
  (autour de la ligne 42). Le picker Scenes fait l’inverse : il écrit
  `trainerId` mais omet `battleTemplateId`, que les diagnostics exigent pour
  un static. Le test de parité utilise un callback factice retournant
  directement `victory` et ne traverse pas l’adapter réel. Le boss Selbrume
  reste un E2E valide d’un chemin spécialisé, pas la preuve du builder
  générique ;
- **cadeau — `PARTIAL`** : le writer ajoute et persiste la créature si la party
  a une place, mais renvoie explicitement `partyFull` au lieu d’utiliser le PC.
  Le chemin capture sait déjà router la septième capture vers une box.

Le Cutscene Studio historique est également `CONTRADICTORY` : plusieurs blocs
authorables et sauvegardables (choice/wait, apparitions, caméra ou appels)
restent placeholders ou sont bloqués par l’executor legacy. Ils doivent être
masqués, migrés vers Scenes/Cinematics ou rendus exécutables avant publication.

### 6.4 Validation, preview, export et installation

Des validateurs projet, carte, narration et MVP existent dans le dépôt.
L’éditeur sait construire un package via `map_distribution`, y inclure
personnalisation/assets et produire un candidat consommable par Avelune.
Cependant, aucune invocation de `ProjectValidator`, `MapValidator`,
`validateNarrativeProject` ou d’une validation d’atteignabilité de fin n’a été
trouvée dans `src/features/game_export`. Le libellé « Package certifié » est
donc plus fort que la preuve réellement réalisée par l’export.

La fin de chaîne reste `PARTIAL` :

- le contrat d’extension n’est pas stabilisé entre `.pokemapgame` et
  `.avelunegame` ;
- l’export peut être installé automatiquement dans certains parcours desktop,
  mais le parcours public mobile repose encore sur import ;
- aucune gate fraîche ne part d’un projet vide manipulé uniquement par un
  humain dans l’éditeur et ne finit sur la victoire dans Avelune mobile ;
- l’E2E Selbrume utilise une fixture canonique et un driver, pas la preuve que
  tous ses éléments ont été authored dans l’UI courante.
- la publication desktop vers l’inbox affiche encore « PokeMap Hub » au
  créateur au lieu de présenter clairement la destination mobile Avelune.

### 6.5 Inspection réelle de l’application desktop

Une copie jetable de la fixture source
`/Users/karim/Project/pokemonProject/selbrume` a été créée hors du dépôt sous
`/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/pokemap-ultra-audit-20260728.xoXKKT`,
afin de ne pas toucher la source. Son fingerprint agrégé avant copie était
`7a79fd23b07bbc9cc8451860412edb7e3a0364450f29d23594b0350f1fb2c5de`
pour 11 259 fichiers.

Commande de lancement :

```bash
cd packages/map_editor
flutter run -t dev/marionette_main.dart -d macos --debug --no-pub \
  --dart-define=MARIONETTE_PROJECT_PATH=<copie-jetable>
```

Une première tentative de l’agent racine a compilé puis perdu la connexion
avant inspection. La seconde tentative de la passe PokeMap/no-code a établi la
preuve suivante : le build macOS et la connexion VM service ont réussi. Les
extensions ont
confirmé que `activeProjectPath` correspondait exactement à la copie Selbrume
et que `openPersonalizationStudio` avait ouvert le workspace
`personalizationStudio`. L’inspection interactive a vu le titre
« Personalization Studio », l’état « Enregistré », autosave, save, le hub de
catégories et Branding. Deux captures Marionette inline ont été inspectées,
mais n’ont fourni aucun PNG durable.

Les logs stdout ont signalé deux `RenderFlex overflow` de 29 px et 26 px dans
`lib/src/ui/shared/map_workspace_empty_state.dart` autour de la ligne 206.
Deux captures OS ont été rejetées car elles montraient une autre instance
PokeMap. `get_logs` a ensuite renvoyé une erreur serveur ; la session de cet
audit a été déconnectée et quittée sans interrompre l’autre processus.

Conclusion visuelle : le chargement du projet et du Personalization Studio est
prouvé sur ce viewport ; un défaut responsive reproductible est détecté ; le
parcours humain création→export complet reste `UNPROVEN`.

### 6.6 Verdict PokeMap

**`PARTIAL`**, proche d’un éditeur techniquement très capable mais pas encore
certifié comme produit no-code de bout en bout. Le cœur narratif annoncé comme
manquant par d’anciens documents est présent ; les priorités doivent être la
fermeture des parcours, les pickers exhaustifs, la preuve de création depuis
zéro et la cohérence export/Avelune.

---

## 7. Audit gameplay et runtime

### 7.1 Boucle jouable démontrée

Les tests du host Selbrume et du runtime démontrent la séquence :

```text
nouvelle partie
→ identité/starter/party
→ exploration et dialogues
→ Facts/conditions/progression
→ rencontres et combats
→ capture/récompenses/shop/soin/PC
→ sauvegarde et reprise
→ finishGame
→ victoire et crédits
```

`phase_7a_installed_golden_journey_test.dart` vérifie 19 critères, interdit
les raccourcis forgés, et exige exactement une complétion :
`ending.selbrume-sauvee`, titre « Selbrume est sauvée », crédits et retour au
hub. Le contenu canonique ne permet pas Continuer en postgame.

`selbrume_player_journey_e2e_test.dart` utilise un vrai `PlayableMapGame` et
exclut des shortcuts de source. Il reste piloté par des commandes d’évaluation
scriptées : c’est une excellente preuve de moteur et une preuve limitée
d’expérience humaine.

### 7.2 Progression et collection

Preuves fraîches :

- starter et party initiale : `new_game_initial_party_test.dart` et tests
  runtime de new game ;
- PC/boxes et destinations de capture :
  `player_storage_operations_test.dart`,
  `capture_destination_operations_test.dart`, pages PC du host ;
- capture et combats : suites `map_battle` capture/flow et handoff runtime ;
- XP, niveaux, apprentissage et évolution :
  `battle_progression_service_test.dart`,
  `battle_move_learning_test.dart`,
  `pokemon_evolution_service_test.dart` ;
- argent, récompenses, badges et capacités :
  commandes narratives et écriture atomique runtime ;
- sac, soin, objets et machines :
  `party_bag_heal_operations_test.dart`,
  `pokemon_move_machine_service_test.dart`, tests runtime bag/TM.

La profondeur n’est pas uniforme : la boucle solo V0 est bien couverte, mais
les fonctions avancées et l’authoring de certaines règles de combat sont
partiels.

### 7.3 Combat

`map_battle` démontre fraîchement :

- combats sauvages et trainers simples ;
- choix et résolution d’actions ;
- changement et remplacement après K.O. ;
- capture et formules ;
- objets génériques et objets de soin/réanimation ;
- statuts majeurs et cycle de vie ;
- PP et historique/writeback ;
- météo, terrain de combat et hazards sélectionnés ;
- résultat final transmis au runtime.

Les limites MVP à rendre explicites :

- la profondeur météo/terrain/hazards du moteur dépasse parfois ce que
  l’éditeur et le runtime savent configurer de bout en bout ;
- le catalogue exhaustif des objets/effets/abilities n’est pas requis pour
  terminer Selbrume ;
- doubles/multi, métagame compétitif et parité exhaustive sont différés.

### 7.4 Monde, narration et fin

Facts typés, conditions Event V2, scènes, présence PNJ, warp, dialogues,
combats narratifs, shop, heal, badges, Surf, cinématique canonique et
`finishGame` sont exécutables. Les Storylines et variables legacy restent
`PARTIAL`; le static générique est `CONTRADICTORY`; le cadeau est `PARTIAL`
quand la party est pleine. Selbrume prouve un chemin spécialisé, pas chacun de
ces builders génériques.

`finishGame` n’est plus un TODO abstrait : la commande est authored,
sérialisée, validée, exécutée, persistée et testée jusqu’à la surface
victoire/crédits. L’affirmation contraire de l’audit mécanique du 2026-07-26
est périmée.

Arènes et rival peuvent être assemblés à partir des briques existantes, mais
les templates guidés et une campagne entièrement authored via UI restent
partiels. Le postgame est supporté par politique de fin, mais Selbrume choisit
le retour hub sans Continuer et aucun contenu postgame complet n’est démontré.

### 7.5 Verdict gameplay/runtime

**`PARTIAL` au niveau produit, largement `COMPLETE` pour la boucle solo V0
automatisée.** Le moteur permet une aventure terminable préparée. Le manque
principal est la preuve no-code et mobile unifiée ; ce n’est pas une raison
pour réécrire les mécaniques déjà testées.

---

## 8. Comparaison fonctionnelle avec une aventure de collection de créatures

La comparaison suivante porte sur l’expérience abstraite d’une aventure
principale, pas sur une parité de contenu propriétaire.

### 8.1 Expérience déjà atteignable

- commencer une partie, choisir/recevoir une créature et former une party ;
- explorer des cartes connectées, rencontrer des PNJ, lire des dialogues et
  faire des choix ;
- déclencher une progression conditionnelle par Facts/variables ;
- combattre des créatures sauvages et des trainers en solo ;
- capturer, envoyer vers party ou storage, gérer PC et boxes ;
- utiliser sac, soins, shops, objets en combat et machines ;
- gagner XP/niveaux, apprendre des attaques, évoluer, recevoir argent et
  badges ;
- sauvegarder, reprendre et atteindre une fin avec crédits.

### 8.2 Expérience encore moins aboutie qu’un RPG principal

- onboarding Avelune sans contenu et découverte de jeux ;
- richesse du résumé de créature, organisation/qualité de vie des boxes et
  gestion directe des objets tenus ;
- Surf prouvé mais ensemble de capacités terrain incomplet ;
- rencontres surf de bout en bout et objets cachés dédiés ;
- richesse de Pokédex, recherche/tri, silhouettes, habitats ou objectifs ;
- variété météo/terrain/hazards authorable ;
- templates guidés d’arène, rival, cinématique longue et campagne ;
- télémétrie consentie, récupération assistée et support joueur ;
- contenu de postgame ;
- finition mobile sur appareils réels et distribution stores.

### 8.3 Fonctions avancées non bloquantes pour le MVP

Sont volontairement traitées comme valeur post-MVP : doubles/multi,
multijoueur/online, métagame compétitif, breeding, concours, économie réseau,
catalogue exhaustif de capacités/objets/effets, postgame massif et parité
exhaustive avec une génération particulière. Une aventure originale complète
en solo n’en dépend pas.

---

## 9. Audit Personalization Studio

### 9.1 Chaîne couverte

Le Personalization Studio ne se résume pas à une page de réglages. Les preuves
automatiques couvrent :

- identité du jeu, branding et palettes ;
- thème et typographie ;
- présentation du titre ;
- musique de titre ;
- vidéo d’introduction et variantes portrait/paysage ;
- aperçu éditeur ;
- sérialisation dans le projet ;
- inclusion dans le package ;
- lecture par Avelune et le runtime ;
- fallback déterministe en cas d’asset absent/corrompu ;
- golden gates de packaging et présentation.

Preuves notables :

- tests Personalization Studio sous `packages/map_editor/test/` ;
- `apps/pokemap_hub/test/ui/player/phase_5_personalization_golden_gate_test.dart` ;
- `phase_6_personalization_packaging_e2e_test.dart` ;
- `hub_title_presentation_loader_test.dart`,
  `hub_intro_video_player_test.dart`,
  `intro_codec_fixture_test.dart` ;
- reçu
  `reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json`.

### 9.2 Limites et contradiction de preuve

Le reçu PH-007 était déjà modifié localement au début de l’audit. Il n’a pas
été utilisé comme vérité exclusive et n’a pas été touché.

La chaîne automatisée est forte, mais l’audit n’a pas obtenu une inspection
humaine fraîche de toutes les combinaisons portrait/paysage, safe areas,
polices, audio et vidéo sur appareils mobiles. La fonctionnalité est donc
`COMPLETE` pour le contrat automatisé V0 et `UNPROVEN` pour la certification
visuelle multi-appareils ; le studio global est classé `PARTIAL`.

Une contradiction concrète empêche toutefois de présenter la preview comme
fidèle : le profil et l’éditeur acceptent une vidéo portrait et conservent ses
dimensions, tandis que
`packages/map_player_ui/lib/src/player/player_intro_video_surface.dart`
force actuellement `AspectRatio(16 / 9)`. L’intro portrait est donc
`CONTRADICTORY` jusqu’à un test player réel 1080×1920 et un rendu fondé sur le
ratio source. Le preview éditeur réimplémente en outre ses surfaces au lieu de
réutiliser directement `map_player_ui`, ce qui rend d’autres dérives possibles.

---

## 10. Audit UX, accessibilité, localisation et responsive

### 10.1 UX joueur

Forces :

- séparation bibliothèque / profils / player ;
- erreurs d’installation structurées ;
- diagnostics et recommandations de réparation ;
- title/intro/personnalisation du jeu installé ;
- contrôles tactiles, pause et préférences ;
- reprise par slot.

Faiblesses :

- bibliothèque vide sans démo ;
- maintenance visible mais désactivée ;
- pas d’export/import save ;
- parcours Nouvelle partie modifié sans mise à jour de la gate installée ;
- absence de récupération guidée/rapport partageable ;
- catalogue et découverte absents.

### 10.2 UX créateur

Forces :

- surfaces dédiées, palette narrative et nombreux pickers ;
- diagnostics avant export ;
- preview et builders spécialisés ;
- design system éditeur.

Faiblesses :

- aucune certification « projet vide à aventure terminée » ;
- couverture des IDs manuels non prouvée globalement ;
- certaines fonctions avancées sont composées à partir de commandes génériques
  plutôt qu’un template orienté intention ;
- overflows desktop observés sur un empty state ;
- densité fonctionnelle très élevée : le volume de `map_editor` rend la
  découvrabilité et la cohérence difficiles à déduire des tests seuls.

Le guardrail design-system est vert en mode ratchet, mais accepte encore une
baseline de 82 fichiers, 573 références directes de couleurs et 61 imports de
chrome legacy. Le Narrative Studio tient une baseline stricte à zéro ; le
reste de l’éditeur n’est donc pas uniformément migré.

### 10.3 Accessibilité et responsive

Les semantics, tooltips, localisations et layouts adaptatifs sont présents dans
plusieurs surfaces, mais aucune matrice fraîche n’a couvert :

- VoiceOver/TalkBack de bout en bout ;
- navigation clavier complète de l’éditeur ;
- ordre de focus et pièges de modal ;
- tailles de texte extrêmes ;
- contraste mesuré dans toutes les personnalisations ;
- rotation pendant vidéo, combat et écriture de save ;
- petits écrans Android et tablettes.

Le statut global est `PARTIAL`. Les deux overflows desktop constituent une
preuve concrète qu’« analyseur vert » ne signifie pas « responsive complet ».

### 10.4 Localisation

Des chaînes joueur localisées et une infrastructure de localisation existent,
notamment via `map_player_ui`. La couverture de tous les messages éditeur,
diagnostics, erreurs natives et contenus authored n’est pas certifiée.
L’audit ne prétend pas à une couverture linguistique exhaustive : statut
`PARTIAL`.

---

## 11. Audit saves, migrations et récupération

### 11.1 Ce qui fonctionne

- enveloppes de save versionnées ;
- profils, slots, isolation par jeu ;
- temp/current/backup et checksum ;
- récupération après interruption à chaque étape simulée ;
- migrations et import legacy testés ;
- checkpoint runtime vers Avelune ;
- conséquences narratives écrites atomiquement ;
- conservation de la progression de fin.

### 11.2 Ce qui manque ou reste contradictoire

- timeout standard du test multi-processus ;
- aucune preuve de kill OS réel pendant background/rotation sur appareils ;
- aucune interface export/import save ;
- migration transactionnelle de save avant update volontairement bloquée ;
- choix explicite conserver/supprimer les saves lors d’une désinstallation non
  câblé ;
- aucune matrice de compatibilité long terme sur plusieurs versions publiques
  réellement distribuées ;
- restauration utilisateur guidée et diagnostics partageables partiels.

### 11.3 Verdict

Le stockage est techniquement avancé, mais la promesse de sauvegarde produit
est `CONTRADICTORY` : la logique passe avec un timeout réaliste, tandis que la
commande standard échoue ; les scénarios update/export/import et kill OS réel
restent incomplets.

---

## 12. Audit distribution et production

### 12.1 Android

`.github/workflows/avelune_android_release.yml` :

- pinne Flutter `3.46.0-0.3.pre` ;
- teste la gate mobile ;
- construit un APK debug de preview sur push ;
- exige des secrets et `AVELUNE_REQUIRE_RELEASE_SIGNING=true` sur tag
  `avelune-v*` ;
- construit et publie un APK release renommé.

La run GitHub Actions fraîche associée au HEAD,
[`30303222458`](https://github.com/yoahnl/pokemap/actions/runs/30303222458),
est verte. L’artefact de workflow annoncé pèse 107 923 409 octets, mais il
s’agit de l’archive d’artefact GitHub. La prerelease
`preview-2026.07.27`, liée au HEAD, contient un APK debug brut de
187 491 909 octets (`sha256` commençant par `9367c541`), avec trois ABI et
279 158 145 octets non compressés. `kernel_blob.bin` représente à lui seul
110 506 784 octets. Ces mesures sont des signaux de budget, pas une estimation
de release optimisée.

Limites :

- aucun tag/release `avelune-v*` trouvé ;
- aucune preuve de signature finale inspectée ;
- pas d’AAB ni de track Play ;
- pas de split ABI, shrink/obfuscation ou budget binaire ;
- le `pubspec.yaml` reste `0.1.0+1` et le workflow ne démontre pas que
  versionName/versionCode reflètent le tag ;
- aucun test sur appareil Android dans cet audit.

Verdict Android production : `UNPROVEN`.

### 12.2 iOS / Xcode Cloud

Les scripts `apps/pokemap_hub/ios/ci_scripts/ci_post_clone.sh` construisent
l’app iOS avec nom/numéro de build Xcode Cloud. Le contrat native Avelune et le
build simulator sont valides.

Limites :

- Flutter est cloné depuis la branche mouvante `stable`, contrairement au pin
  exact de GitHub Actions ;
- aucun `flutter test`/`flutter analyze` n’est démontré dans le script Xcode
  Cloud ;
- aucune run Xcode Cloud, archive signée, export IPA, TestFlight ni installation
  production n’a été fournie ;
- la valeur de fallback de version iOS et la version du pubspec ne constituent
  pas un versionnement cross-platform unique.

Verdict iOS production : `UNPROVEN`.

### 12.3 Desktop PokeMap

Les workflows desktop construisent macOS/Windows/Linux. Le build macOS éditeur
local est possible. Les anciens rapports de certification macOS indiquent
explicitement :

- aucune identité Developer ID disponible sur la machine ;
- signature ad hoc ;
- notarisation/stapling non prouvés ;
- rejet Gatekeeper pour le candidat historique.

L’état externe a changé. Cinq identités de signature valides, dont Developer ID
Application, sont aujourd’hui présentes. Deux DMG **PokeMap Hub** préexistants
et ignorés sont réellement signés Developer ID, staplés et acceptés par
`spctl`; l’un est lié au commit ancêtre `52f43e2d` avec résultats notarytool
Accepted. Cela prouve que la chaîne Hub a déjà fonctionné, mais pas qu’elle
fonctionne pour le HEAD, pour PokeMap Editor ou pour une release publique
actuelle.

Les builds **release** frais du HEAD donnent des preuves plus précises :

- Avelune/Hub macOS : exit 0 en 72,25 s, app universelle x86_64+arm64 de
  87 441 441 octets de fichiers, signature ad hoc avec hardened runtime,
  `spctl` exit 3 et `stapler` exit 65 ;
- PokeMap Editor macOS : exit 0 en 55,19 s, app arm64 de 44 452 425 octets,
  version `0.2.0`, signature ad hoc, `spctl` exit 3 et `stapler` exit 65 ;
- DMG Editor local : exit 0 en 6,56 s, 20 525 866 octets, SHA-256
  `dca36192668a714b5cbf688a00ea4be59b1e398b2703fa031b0dc99a2e4709f9`,
  `hdiutil verify` exit 0, mais DMG non signé, Gatekeeper exit 3 et stapler
  exit 65.

L’éditeur macOS release est explicitement Apple Silicon uniquement dans
`Release.xcconfig`; Intel n’est pas couvert. Le bundle preview local contient
`get-task-allow=true`; le workflow stable prévoit une re-signature avec des
entitlements plus stricts, mais ce chemin n’a pas été exercé. Windows
signing/installer et Linux packaging ont besoin de reçus frais. Verdict
desktop production : `UNPROVEN` pour une release stable, malgré des builds
locaux `COMPLETE` au sens strict de la compilation.

### 12.4 Sécurité des packages

Le modèle de menace testé couvre traversée de chemin, chemins absolus,
symlinks, hardlinks/entrées spéciales, collisions, inventaire, digest, quotas
et résolution des assets dans l’installation. Les packages issus d’un
catalogue public exigent une signature ; l’import local peut rester non signé.

Verdict :

- sûreté structurelle de l’archive dans le modèle testé : `COMPLETE` ;
- authenticité de tout package local et chaîne de confiance publique :
  `PARTIAL` ;
- sandboxing d’un contenu hostile au-delà des données déclaratives et audit
  externe : `UNPROVEN`.

### 12.5 Performance, stabilité et taille

Aucun budget mesuré et rejouable n’a été trouvé pour :

- temps cold start ;
- mémoire runtime/éditeur ;
- FPS sur cartes lourdes ;
- temps d’import et espace disque sur package maximal ;
- batterie/thermique ;
- taille installée par ABI ;
- vidéo d’introduction sur appareils bas de gamme.

Les tests de quotas, catalogues volumineux et builds sont utiles mais ne
remplacent pas ces métriques. Statut global : `UNPROVEN`.

La toolchain locale renforce ce besoin de reproductibilité : Flutter
`3.46.0-0.3.pre` beta utilise Dart 3.13 beta, tandis que le binaire `dart`
résolu directement dans le PATH est 3.12.1 stable et `flutter doctor` signale
le décalage.

### 12.6 Provenance de la prerelease

La prerelease `preview-2026.07.27` pointe vers le HEAD
`a3d741818c1961ac2f653da235bb30c20df75b00`, mais ses artefacts ne proviennent
pas tous de ce commit :

| Artefact | Octets | SHA-256 | Run / commit source |
|---|---:|---|---|
| `Avelune-Android-preview.apk` | 187 491 909 | `9367c5416924fae8b74195380884dfa410483aab517cc735bc556126f9e7a5b3` | `30303222458` / `a3d741818…` |
| `PokeMap-linux-x64.tar.gz` | 17 629 903 | `feb0360c008e243fcf16de18a20c8f045952c0a710819d6b431119556888476c` | `30302704506` / `28c03879…` |
| `PokeMap-macos-preview.dmg` | 20 779 679 | `2d8838b07260ac386d70000ae2c6fa60e81e9390fdbd904741146e36a1baabe1` | `30302704506` / `28c03879…` |
| `PokeMap-windows-x64.zip` | 20 046 779 | `4b49bc260e961930ee1c61d273751720422e8cce7ed76ba131565a4c50a9bfe1` | `30302704506` / `28c03879…` |

Le run desktop du HEAD `30303220984` est annulé et possède zéro artefact. Les
trois fichiers desktop sont bit-à-bit ceux du run réussi sur le commit
antérieur. La release mélange donc deux SHA : statut `CONTRADICTORY`. La
présence d’un tag sur HEAD ne suffit pas ; la promotion doit être atomique
depuis un run unique et chaque receipt doit porter le SHA source.

Le build iOS simulateur frais a réussi en 50,77 s (app Avelune universelle,
230 135 195 octets de fichiers, signature ad hoc). Le build iOS device release
`--no-codesign` a réussi en 67,13 s (arm64, 46 303 072 octets), mais
`codesign --verify` retourne 1 et aucun provisioning profile n’est présent.
Cela prouve la compilation, pas l’installation ni TestFlight.

---

## 13. Matrice exhaustive des fonctionnalités

**Échelle d’effort :** `XS` ≤ 2 jours, `S` ≈ 3–5 jours, `M` ≈ 1–2 semaines,
`L` ≈ 3–5 semaines, `XL` > 5 semaines pour une petite équipe connaissant le
dépôt. Ce sont des ordres de grandeur de lot, pas des engagements calendaires.
Les priorités sont `P0` blocker de preuve/MVP, `P1` valeur MVP forte, `P2`
post-MVP proche, `P3` différable.

### 13.0 Registre de preuves

Les cellules de matrice utilisent des noms courts ; ce registre les résout en
chemins et validations reproductibles. Les résultats frais complets sont au
§21.

| ID | Preuve exacte |
|---|---|
| E-ARCH | `packages/*/lib/*.dart` barrels; `map_core/test/package_boundary_test.dart`, `map_runtime/test/package_boundary_test.dart`, `apps/pokemap_hub/test/architecture/hub_architecture_boundary_test.dart`; tests ciblés verts |
| E-AV-BOOT | `apps/pokemap_hub/lib/src/bootstrap/hub_bootstrap.dart`; `lib/src/ui/hub_shell.dart`; `test/ui/hub_bootstrap_test.dart`, `hub_shell_test.dart`, `hub_app_player_navigation_test.dart` |
| E-AV-INSTALL | `lib/src/install/game_package_installer.dart`, `game_installation_transaction.dart`, `installed_game_verifier.dart`; tests homonymes et recovery verts |
| E-AV-SMOKE | `apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart`; build iOS 51,3 s puis timeout sur le dialogue identité |
| E-AV-SAVE | `lib/src/saves/hub_save_store.dart`, `hub_save_profile_manager.dart`; suite standard 189/190, crash-stage 7/7 avec `--timeout 2m` |
| E-AV-MAINT | `lib/src/install/game_maintenance_service.dart`; `test/install/game_maintenance_service_test.dart`; `hub_composition.dart:52` et callbacks UI nuls |
| E-MISS-DEMO | `rg -n 'DemoPackage\|EmbeddedDemo\|seedDemo\|GameCatalog\|CatalogScreen\|DiscoveryScreen\|discoverGames\|downloadGame' apps/pokemap_hub/lib apps/pokemap_hub/test apps/pokemap_hub/pubspec.yaml` → exit 1, aucun match |
| E-MISS-SAVE-PORT | `rg -n 'exportSave\|importSave\|shareSave\|SaveExport\|SaveImport' apps/pokemap_hub/lib apps/pokemap_hub/test` → uniquement `LegacyGlobalSaveImporter`, aucun export/import moderne |
| E-MISS-CRASH | `rg -n 'Sentry\|Crashlytics\|FirebaseCrash\|captureException\|reportCrash' apps/pokemap_hub/lib apps/pokemap_hub/pubspec.yaml` → exit 1 |
| E-CORE-NARR | `map_core/lib/src/read_models/narrative_command_catalog.dart`; `test/narrative_command_contract_parity_test.dart`; ciblé +19 et matrice core +58 |
| E-ED-EVENT | `map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart`; `scene_action_builder.dart`; commande éditeur 225/225 |
| E-ED-WORLD | `map_core/lib/src/models/map_data.dart`; `map_editor/lib/src/ui/panels/map_connections_panel.dart`; `map_gameplay/lib/src/gameplay_step.dart`; tests collision/runtime cités |
| E-ED-PLAYTEST-MISS | `global_story_studio_panels.dart:157-159` contient `enabled: false` et « Lecture test globale — bientôt disponible » |
| E-ED-EXPORT | `runtime_project_projection_builder.dart:75`; `game_package_export_service.dart:199`; tests export +29; aucun appel global `ProjectValidator`/`validateNarrativeProject` |
| E-STATIC | `narrative_template_catalog.dart:751`; `scenes_workspace.dart:2152`; `scene_battle_runtime_outcome_adapter.dart:42`; parity test `:154`; boss Selbrume integration test `:15` |
| E-RUN-NARR | `map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`; command/save/cinematic/writer ciblés +48 |
| E-HOST-JOURNEY | `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart`; 28/28 sélection host et phase 7A 19 critères |
| E-BATTLE | `map_battle` sélection core/capture/switch/items/status/weather/terrain/hazards/PP → +117 |
| E-PERS | `project_presentation_profile.dart`; tests Personalization/export; `player_intro_video_surface.dart:53`; Hub phases 5/6 |
| E-BUILD | Builds frais §12/§21 : iOS simulator/device, Hub macOS, Editor macOS et DMG avec exits, tailles, signatures |
| E-RELEASE | runs `30303222458`, `30302704506`, `30303220984`; quatre SHA publiés §12.6; provenance mixte |
| E-MISS-AUTHORING | `rg -n 'authoring.*journey\|project.*empty.*export.*install.*finish\|empty.*project.*ending' packages/map_editor/test apps/pokemap_hub/test examples/playable_runtime_host/test` → exit 1 |
| E-FULL-CORE | `cd packages/map_core && dart test -r expanded` → exit 0, `02:06 +4502`; `dart analyze` → exit 0 |
| E-FULL-GAMEPLAY | `cd packages/map_gameplay && dart test -r expanded` → exit 0, `00:03 +428`; `dart analyze` → exit 0 |
| E-FULL-BATTLE | `cd packages/map_battle && dart test -r expanded` → exit 0, `00:21 +1764`; `dart analyze` → exit 0 |
| E-FULL-RUNTIME | `cd packages/map_runtime && flutter test -r expanded` → exit 1, `03:17 +2240 ~1 -1`; seul échec `test/le_train_m00_external_runtime_smoke_test.dart`, reproduit seul |
| E-FULL-EDITOR | `cd packages/map_editor && flutter test -r expanded` → exit 1, `06:31 +4265 -1`; seul échec budget 1 000 Steps, puis test isolé exit 0, `p95 7 644 µs < 20 000 µs` |
| E-FULL-HOST | `cd examples/playable_runtime_host && flutter test -r expanded` → exit 0, `07:32 +257 ~2`; `flutter analyze` → exit 0 |
| E-FULL-PLAYER-UI | `cd packages/map_player_ui && flutter test -r expanded` → exit 0, `+102`; `flutter analyze` → exit 0 |
| E-FULL-DIST | `cd packages/map_distribution && dart test -r expanded` → exit 0, `+81`; `dart analyze` → exit 0 |
| E-FULL-AVELUNE | suite standard `apps/pokemap_hub` → `+189 -1` au timeout 30 s ; même suite `--timeout 2m` → exit 0, `+190`; analyzers et builds Apple §21 |
| E-AV-MOBILE | `apps/pokemap_hub/ios/Runner/AppDelegate.swift`; `lib/src/platform/ios_hub_platform_adapter.dart`; `android/app/src/main/AndroidManifest.xml`; `lib/src/platform/android_hub_platform_adapter.dart`; tests adapters/release |
| E-AV-UX | `apps/pokemap_hub/test/ui/hub_display_preferences_ui_test.dart`, `hub_display_preferences_controller_test.dart`, `hub_preferences_store_test.dart`; `packages/map_player_ui/test/player_localizations_test.dart` |
| E-ED-CREATE | `packages/map_editor/lib/src/application/use_cases/project_management_use_cases.dart`; `lib/src/features/editor/application/project_content_controller.dart`; tests provider/content controller |
| E-ED-GRAPH | `packages/map_core/test/project_manifest_storylines_test.dart`; `map_editor/test/storylines_graph_authoring_test.dart`, `storylines_workspace_scene_links_test.dart`; `map_runtime/test/side_quest_optional_storyline_readiness_test.dart` |
| E-ED-UX | `map_editor/test/ui/canvas/narrative_studio_responsive_accessibility_test.dart`, `event_builder_v2_accessibility_test.dart`, `narrative_studio_localization_test.dart`; build/inspection §21.5 |
| E-GP-LOOP | `map_gameplay/test/new_game_state_builder_test.dart`, `new_game_initial_party_test.dart`, `capture_destination_operations_test.dart`, `party_bag_heal_operations_test.dart`; `map_runtime/test/playable_map_game_project_new_game_boot_test.dart`, `p6_selbrume_route_1_encounter_capture_golden_slice_test.dart` |
| E-GP-COMBAT | `map_battle/test/battle_capture_flow_test.dart`, `battle_switch_test.dart`, `psdk_switch_action_test.dart`, `psdk_status_effects_test.dart`, `psdk_status_lifecycle_test.dart`; `map_runtime/test/runtime_battle_status_bridge_test.dart` |
| E-GP-SAVE | `map_runtime/test/file_game_save_repository_test.dart`, `playable_map_game_initial_save_restore_activation_test.dart`, `p5_gameplay_save_load_beta_roundtrip_test.dart`; menus/preferences ciblés et E-FULL-RUNTIME |
| E-DIST-SEC | `map_distribution/test/game_package_inspector_test.dart`, `game_package_release_policy_test.dart`, `game_package_compatibility_test.dart`; `pokemap_hub/test/install/game_package_installer_test.dart`, `game_install_recovery_test.dart` |
| E-CI | `.github/workflows/avelune_android_release.yml`, `pokemap_desktop_release.yml`, `pokemap_hub_product_certification.yml`; `apps/pokemap_hub/ios/ci_scripts/ci_post_clone.sh`; runs/hash §12.6 et §21.6 |
| E-MAC-HIST | deux DMG Hub historiques : chemins, SHA-256, Team ID `NLNMNV3B3S`, `codesign`, `stapler` et `spctl` exacts au §21.6 ; aucun ne prouve le HEAD audité |

### 13.1 Avelune

| Produit | Fonctionnalité | Statut | Preuves exactes | Ce qui fonctionne | Ce qui manque | Impact joueur/créateur | Priorité | Effort | Dépendances | Prochain test ou lot recommandé |
|---|---|---|---|---|---|---|---|---|---|---|
| Avelune | Nom et bundle natifs mobiles | `COMPLETE` | E-AV-MOBILE : `public_product_identity.dart`; AndroidManifest label; Info.plist/Xcode bundle ID; `public_product_identity_test.dart` | Avelune sur Android/iOS, IDs `com.yoahnl.avelune.player` | Gate binaire finale à conserver | Identité native correcte | P0 | XS | Builds mobile | Scanner les chaînes de l’APK/IPA final dans AV-006 |
| Avelune/PokeMap | Identité publique bout en bout | `CONTRADICTORY` | E-AV-MOBILE/E-ED-EXPORT : export service `:258`; UI « PokeMap Hub » `game_package_export_dialog.dart:116`; adapters mobiles | Bundle mobile Avelune | Suffixe `.pokemapgame` et cible Hub restent visibles côté créateur/joueur | Exposition publique d’un nom interdit | P0 | M | PK-1/PK-2 | Gate chaînes+extensions sur package et binaires |
| Avelune | Premier démarrage | `PARTIAL` | E-AV-BOOT : `hub_bootstrap.dart`; `hub_bootstrap_test.dart`; `hub_shell_test.dart` | L’app initialise stockage, préférences et dashboard | Onboarding guidé et contenu jouable immédiat | Premier contact vide et dépendant d’un fichier externe | P1 | S | Démo embarquée | AV-005 : cold start sur app fraîche |
| Avelune | Bibliothèque vide | `COMPLETE` | E-AV-BOOT : `hub_shell.dart`; `hub_shell_test.dart`; `hub_app_player_navigation_test.dart` | Empty state, import et états d’activité | Rien de bloquant pour l’état vide lui-même | Compréhensible mais peu engageant | P1 | XS | Localisation | Widget golden + lecteur d’écran |
| Avelune | Démo immédiatement jouable | `MISSING` | E-MISS-DEMO : requête `rg` modèle/app/tests exit 1 | — | Package démo, seed idempotent, bouton jouer, politique de mise à jour | Bloque l’essai sans fichier externe | P1 | M | Package canonique neutre, taille | AV-005 : fresh install → Démo → save → Continue |
| Avelune | Import local `.avelunegame` / `.pokemapgame` | `CONTRADICTORY` | E-AV-MOBILE/E-AV-INSTALL/E-ED-EXPORT : `apps/pokemap_hub/lib/src/platform/ios_hub_platform_adapter.dart`; `apps/pokemap_hub/lib/src/platform/android_hub_platform_adapter.dart`; `apps/pokemap_hub/test/install/game_package_installer_test.dart`; `packages/map_editor/lib/src/features/game_export/application/game_package_export_service.dart:258` | Avelune accepte les deux extensions et installe transactionnellement | PokeMap refuse autre chose que `.pokemapgame`; contrats iOS/Android divergent | Le nom public legacy expose « PokeMap » au joueur | P0 | M | Contrat extension + migration | Canoniser `.avelunegame`, legacy invisible |
| Avelune | Import Android réel | `PARTIAL` | E-AV-MOBILE : `android_hub_platform_adapter.dart`; test adapter; manifest | Intent et copie contrôlée couverts automatiquement | Aucun appareil/émulateur Android disponible durant l’audit | Risque d’échec OEM/permission non vu | P0 | S | SDK + appareil Android | AV-001 : instrumentation sur 2 API levels |
| Avelune | Import iOS réel | `PARTIAL` | E-AV-MOBILE : AppDelegate document types; adapter; build simulator et package de test | Build/install simulator et chargement du package jusqu’au titre | Parcours Files/Share Sheet humain et reprise complète non franchis | Risque de handoff natif | P0 | S | Driver iOS à jour | AV-001 : Files → identité → jeu → save |
| Avelune | Sécurité structurelle des archives | `COMPLETE` | E-DIST-SEC/E-AV-INSTALL : `map_distribution`; installer/security tests traversal, symlink, special entry, quota, digest | Rejet fail-closed des archives malformées du modèle testé | Audit externe/fuzz long terme | Réduit corruption et écriture hors sandbox | P0 | M | Corpus de menaces | Fuzz corpus + property tests |
| Avelune | Authenticité des packages | `PARTIAL` | E-DIST-SEC : politique `publicCatalog` et tests signature | Signature exigée pour source catalogue | Import local non signé ; chaîne de confiance publique non opérée | Un package local peut être d’origine inconnue | P1 | M | PKI/catalogue | Gate clés, révocation et rotation |
| Avelune | Installation transactionnelle | `PARTIAL` | E-AV-INSTALL : `game_package_installer.dart`; `game_installation_transaction.dart`; recovery tests | staging, smoke, journal, promotion, rollback | Appel systématique de recovery au bootstrap non prouvé | Risque résiduel après kill au mauvais instant | P0 | S | Bootstrap | AV-002 : kill/relaunch app complète |
| Avelune | Détection d’intégrité et diagnostic de réparation | `COMPLETE` | E-AV-INSTALL : `installed_game_verifier.dart`; launch resolver tests | Vérification digest et blocage avec recommandation de réparation | Action joueur de réparation non câblée | Empêche de lancer une installation corrompue | P0 | XS | Maintenance UI | Test corruption → diagnostic |
| Avelune | Lancement d’un jeu installé | `PARTIAL` | E-AV-SMOKE : `HubInProcessSessionFactory`; `HubInstalledGamePlayer`; smoke iOS frais | Package et écran titre atteints dans l’app | Gate mobile ne franchit plus l’identité jusqu’à `playing` | Promesse centrale non certifiée | P0 | S | AV-001 | Réparer le smoke installé sans shortcut |
| Avelune | Nouvelle partie | `CONTRADICTORY` | E-AV-SMOKE : `runtime_owned_player_flow_test.dart`; build 51,3 s puis identité non traitée | Flux identité/starter/session existe | Driver installé attend l’ancien flux et timeoute | La gate de release est rouge | P0 | XS | Driver Personalization | AV-001 : remplir identité puis vérifier spawn |
| Avelune | Continuer | `PARTIAL` | E-AV-SAVE/E-AV-SMOKE : gateways/tests verts, smoke bloqué avant save | Résolution du slot et reprise automatisées | Pas de reprise fraîche issue du smoke iOS actuel | Confiance joueur non certifiée sur mobile | P0 | S | Nouvelle partie verte | New Game → kill → Continue sur candidat identique |
| Avelune | Profils de joueur | `COMPLETE` | E-AV-SAVE : `hub_save_profile_manager_test.dart`; `hub_save_profiles_screen_test.dart` | Création/sélection, métadonnées et isolation | UX multi-appareils non requise V0 | Plusieurs joueurs sur un appareil | P1 | XS | Save store | E2E deux profils/deux jeux |
| Avelune | Slots de sauvegarde | `COMPLETE` | E-AV-SAVE : `hub_save_store_isolation_test.dart`; écran slots | Plusieurs slots, previews, isolation | Export/duplication manuels absents | Sécurise essais et parties parallèles | P1 | S | Profils | Golden UI + corruption d’un seul slot |
| Avelune | Atomicité et récupération des saves | `CONTRADICTORY` | E-AV-SAVE/E-FULL-AVELUNE : `hub_save_store_atomic_test.dart`; suite +189 -1 à 30 s, +190 à 2 min | Scénarios de mort process passent avec timeout réaliste | Gate standard rouge/lente | CI peut masquer ou bloquer une vraie régression | P0 | S | Harness subprocess | AV-002 : paralléliser/réduire fixtures sans réduire cas |
| Avelune | Sauvegarde au cycle de vie | `PARTIAL` | E-AV-SAVE : `hub_save_lifecycle_coordinator.dart` et test | Coordinator et checkpoint existent | Kill/background réel iOS/Android non testé | Perte possible lors d’interruption OS | P0 | M | App lifecycle integration | Tests background/terminate sur devices |
| Avelune | Backup/restauration/quarantaine | `PARTIAL` | E-AV-SAVE : `hub_save_store.dart`; atomic/migration tests | Candidats previous/backup et quarantaine de corruption | Restauration choisie par le joueur absente | La récupération reste opaque | P1 | M | UI diagnostics | Restaurer un backup depuis le profil |
| Avelune | Migration de saves | `PARTIAL` | E-AV-SAVE : `hub_save_migration_test.dart`; `legacy_global_save_importer_test.dart` | Enveloppes/migrations et import legacy testés | Historique de versions publiques réel absent | Risque lors des futures updates | P0 | M | Versioning | Corpus N-2/N-1/N → N |
| Avelune | Export/import de sauvegardes | `MISSING` | E-MISS-SAVE-PORT : requête `rg` ne trouve que `LegacyGlobalSaveImporter` | Import legacy interne seulement | Export portable, import, consentement, conflit | Pas de backup manuel/transfert | P1 | M | Format public + sécurité | AV-003 : export chiffré/contrôlé aller-retour |
| Avelune | Mise à jour transactionnelle d’un jeu | `CONTRADICTORY` | E-AV-MAINT : installer transactions ; `prepareSavesForUpdate` lève `UnsupportedError`; action UI nulle | Fondations staging/rollback et tests avec doubles | Service non composé, migration save et action production désactivées | Le produit suggère une capacité non livrée | P0 | L | Migrations + maintenance | AV-004 : v1 save → update v2 → rollback |
| Avelune | Réparation déclenchée par le joueur | `PARTIAL` | E-AV-MAINT : `GameMaintenanceService.repair`; tests ; action UI nullable | Backend de repair | Callback non injectée en production et source de réparation | Joueur bloqué malgré diagnostic | P0 | S | Source package fiable | AV-003 : corrompre → Réparer → relancer |
| Avelune | Désinstallation | `PARTIAL` | E-AV-MAINT : `uninstallVersion`/`uninstallGame`; tests ; UI nullable | Transactions et fallback backend | Callback/confirmation/politique saves non câblées | Stockage impossible à gérer dans le produit | P1 | S | Maintenance UI | AV-003 : uninstall avec/ sans saves |
| Avelune | Conservation/suppression des saves | `PARTIAL` | E-AV-SAVE : tests maintenance/store | Backend peut préserver l’espace save | Choix joueur et wording non démontrés | Risque de perte ou résidus inattendus | P0 | S | Désinstallation | Dialogue explicite + tests |
| Avelune | Catalogue/découverte de jeux | `MISSING` | E-MISS-DEMO : recherche `GameCatalog/CatalogScreen/DiscoveryScreen/discoverGames/downloadGame` exit 1 | Bibliothèque locale uniquement | Source/catalogue, metadata, signature, recherche | Acquisition de jeux impossible in-app | P2 | XL | Trust/signature/backend | Post-MVP : catalogue signé minimal |
| Avelune | Contrôles tactiles | `PARTIAL` | E-AV-UX : `runtime_touch_controls_test.dart`; player UI tests | D-pad/actions/profils et overlays | QA physique, latence et ergonomie multi-écrans | Boucle théorique jouable sans périphérique | P0 | M | Runtime input + devices | Device E2E déplacement/dialogue/combat |
| Avelune | Manette | `PARTIAL` | `runtime_gamepad_bridge_test.dart`; packages gamepads | Bridge et mappings automatiques | Manette physique, reconnexion et plateformes non parcourues | Confort paysage/TV variable | P2 | M | Plugins natifs | Matrix Xbox/PS/MFi/Bluetooth |
| Avelune | Bouton Retour Android | `PARTIAL` | E-AV-UX : navigation widgets/Pop scopes recherchés ; tests release | Navigation logique et exit contrôlé | Aucun device Android frais | Risque de fermer/perdre le contexte | P0 | S | Android instrumentation | Back depuis dialogue, menu, combat, player |
| Avelune | Portrait/paysage | `PARTIAL` | E-AV-UX : Info.plist orientations ; display prefs ; intro codec tests | Deux orientations déclarées et variantes média | Rotation réelle pendant flux critiques | Overflows/coupures possibles | P1 | M | Device lab | Rotation titre/vidéo/combat/save |
| Avelune | Safe areas et responsive | `PARTIAL` | E-AV-UX : `SafeArea`, `MediaQuery`, tests widget | Plusieurs surfaces adaptatives | Matrice encoche/tablette/petit Android absente | Contrôles ou texte peuvent être masqués | P1 | M | Golden device matrix | Goldens tailles extrêmes |
| Avelune | Accessibilité | `PARTIAL` | E-AV-UX : options de session, semantics/tooltips, l10n | Base technique et préférences | VoiceOver/TalkBack, focus et texte extrême non certifiés | Exclusion de joueurs | P1 | L | Audit device | Parcours lecteur d’écran complet |
| Avelune | Options joueur | `PARTIAL` | E-AV-UX : preferences gateway/store ; display/control tests | Préférences, profils de contrôle, affichage | Audio, texte et accessibilité non exhaustifs; pas de device journey | Personnalisation et confort incomplets | P1 | M | map_player_ui | E2E persistance après relaunch |
| Avelune | Diagnostics locaux | `PARTIAL` | E-AV-INSTALL/E-AV-SAVE : diagnostics install/save ; `hub-player.log`, `hub-import.log` | Codes, logs et recommandations | Export/redaction/partage guidé incomplets | Support difficile sans accès développeur | P1 | M | Privacy | « Exporter diagnostic » redacted |
| Avelune | Remontée distante d’erreurs | `MISSING` | E-MISS-CRASH : recherche Sentry/Crashlytics/reportCrash exit 1 | Logs locaux seulement | Consentement, upload, corrélation de release | Régressions terrain invisibles | P2 | M | Politique confidentialité | ADR puis crash reporter opt-in |
| Avelune | Taille et performances | `UNPROVEN` | E-BUILD : Builds et quotas ; aucune baseline profile | L’app compile et traite les fixtures | Budgets cold start/RAM/FPS/ABI/thermique | Risque stores et appareils modestes | P1 | M | Device lab | Benchmarks reproductibles et budgets |
| Avelune | CI Android preview | `COMPLETE` | E-CI/E-RELEASE : run HEAD 30303222458 ; prerelease `preview-2026.07.27` ; hash APK | Test/analyze/APK debug et provenance du HEAD | Ne constitue pas une release | Démo technique installable | P1 | S | GitHub Actions | Conserver receipt/hash à chaque HEAD |
| Avelune | Signature/distribution Android | `UNPROVEN` | E-CI : workflow tag/signing ; run preview 30303222458 verte | Chemin CI signé fail-closed configuré | Aucun tag/release signé inspecté, pas d’AAB/Play | Impossible de déclarer prêt production | P0 | M | Secrets, versioning, Play | AV-006 : release candidate signée + install |
| Avelune | AAB / Play Store | `MISSING` | E-CI : workflow construit uniquement APK ; aucune track Play | — | App Bundle, listing et internal testing | Distribution Android store incomplète | P1 | L | Signing/versioning/store | AAB sur track interne avec receipt |
| Avelune | Xcode Cloud/TestFlight | `UNPROVEN` | E-CI : `ios/ci_scripts/ci_post_clone.sh`; build simulator | Contrat Xcode Cloud et version args | Aucune run/archive/IPA/TestFlight | iOS production non démontré | P0 | M | Compte Apple, pin Flutter | AV-006 : receipt Xcode Cloud + TestFlight |
| Avelune | Versionnement cross-platform | `CONTRADICTORY` | E-CI/E-RELEASE : pubspec `0.1.0+1`; tag workflow ; fallbacks Xcode Cloud | Chaque pipeline sait fournir une version | Pas de source unique ni preuve tag→binary | Updates/stores/migrations fragiles | P0 | S | Release manifest | Lot version contract + tests binaires |
| Avelune | Vidéo d’introduction | `CONTRADICTORY` | E-PERS/E-AV-UX : intro player/codec tests; profil accepte portrait; `player_intro_video_surface.dart:53` | Packaging, lecture et fallback automatiques | Player force 16:9, codecs/device/rotation non rejoués | Le rendu Avelune peut contredire la preview créateur | P0 | M | Dimensions + device lab | 1080×1920 et paysage sur iOS/Android |

### 13.2 PokeMap / authoring no-code

| Produit | Fonctionnalité | Statut | Preuves exactes | Ce qui fonctionne | Ce qui manque | Impact joueur/créateur | Priorité | Effort | Dépendances | Prochain test ou lot recommandé |
|---|---|---|---|---|---|---|---|---|---|---|
| PokeMap | Création de projet | `PARTIAL` | E-ED-CREATE : use cases/dialogs projet et tests éditeur | Nouveau projet structuré et ouvrable | Aucun assistant map/spawn/starter jouable | Le créateur démarre sur une structure technique | P0 | M | Templates + New Game | Projet neuf jouable sans ID |
| PokeMap | Cartes | `PARTIAL` | E-ED-WORLD/E-ED-CREATE : `packages/map_core/lib/src/models/map_data.dart`; `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart:26`; `packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart:118` | Création, édition et sérialisation | Le formulaire demande encore un `Map ID` manuel | Fuite d’internal et risque de référence invalide | P0 | M | Slug/validation | Nom convivial→ID généré→runtime |
| PokeMap | Collisions | `COMPLETE` | E-ED-WORLD : modèles terrains/collisions et tests canvas/runtime | Authoring et exécution de blocage | QA visuelle intensive | Exploration cohérente | P0 | S | Canvas | Golden collision editor→runtime |
| PokeMap | Terrains et zones | `CONTRADICTORY` | E-ED-WORLD : `map_data.dart:62`; enum zones `enums.dart:296`; gameplay consumers | Encounter/movement/hazard sont édités et consommés | `movementEffect`, `special`, `custom` restent authorables sans consumer équivalent | Une zone publiée peut être inerte | P0 | L | Gameplay zone engine | Bloquer ou implémenter chaque type |
| PokeMap | Connexions de cartes | `PARTIAL` | E-ED-WORLD : `map_connections_panel.dart:47`; connection use cases; `gameplay_step.dart:37` | Picker, validation inverse/overlap et transition existent | Pas de test unique UI→disque→franchissement réel | L’exploration multi-cartes n’est pas certifiée | P0 | M | Validation refs + runtime loader | E2E connexion authorée |
| PokeMap | PNJ et interactions | `COMPLETE` | E-ED-EVENT/E-RUN-NARR : `setNpcPresence`, `moveNpc`, NPC interaction runtime tests | Placement, présence et déclencheurs | Workflows de masse/duplication avancés | Dialogues et histoire | P0 | M | Sprites + events | PNJ conditionnel saved/reloaded |
| PokeMap | Dialogues et choix | `COMPLETE` | `dialogue_preview_runner.dart`; `dialogue_preview_runner_test.dart`; E-HOST-JOURNEY | Texte, choix, branches et callbacks | QA localisation/overflow | Narration interactive | P0 | S | Conditions | E2E branche choix→Fact→suite |
| PokeMap | Event Builder V2 | `COMPLETE` | E-ED-EVENT : UI event builder tests ; contrats commands | Nœuds typés et diagnostics | UX humaine complexe à recertifier | Réduit le besoin de code | P0 | M | Catalog/pickers | Créateur novice reproduit quête |
| PokeMap | Scenes | `COMPLETE` | E-CORE-NARR/E-ED-GRAPH : `project_manifest_scenes_test.dart`; editor/runtime refs | Modèle, JSON, validation et usage | Bibliothèque/template plus riche | Séquences structurées | P1 | M | Commands | Scene authored→save→resume |
| PokeMap | Storylines | `PARTIAL` | E-ED-GRAPH : modèle/workspace/JSON et story step tests | Graphe, liens Scene/outcome et persistance | Histoire complète créée via GUI puis exécutée non prouvée | Campagne structurée mais chaîne créateur incomplète | P0 | L | Facts/scenes/save | Storyline GUI multi-map→ending |
| PokeMap | Facts/flags | `COMPLETE` | E-CORE-NARR/E-RUN-NARR : `project_manifest_facts_test.dart`; catalog/runtime parity | Déclaration, picker, mutation, save | Outils de debug joueur/éditeur limités | Progression persistante | P0 | S | Save contract | Fact false→true→relaunch |
| PokeMap | Variables legacy | `PARTIAL` | E-CORE-NARR/E-RUN-NARR : `StoryFlags`, `ScriptVariables`, `setVariable`, executor et tests branching ; `game_state_persistence.dart:31` | Modèle, commande legacy et comparateurs existent | Pas de picker/commande V2 moderne ; bridge `SaveData` vide les variables arbitraires | Une branche peut diverger après certains bridges de save | P0 | M | Unification Facts/GameState | Test variable→save bridge→reload avant correction |
| PokeMap | Conditions simples | `PARTIAL` | E-CORE-NARR/E-ED-EVENT : `script_conditions_test.dart`; evaluator; `script_condition_evaluator.dart:278` | Facts, variables et états courants sont évalués | Valeur legacy malformée ou ability inconnue peut lever au lieu d’échouer proprement | Un vieux save peut casser la progression | P0 | S | Validation/migration | Tests malformed fail-closed |
| PokeMap | Conditions composées | `PARTIAL` | E-CORE-NARR/E-ED-EVENT : Event V2 leaf/all/any/not; `script_condition_evaluator.dart:278`; tests composition | Arbres Facts V2 sérialisés et évalués | Un enfant legacy malformé peut lever récursivement | Une quête legacy peut casser malgré AND/OR/NOT | P0 | M | Builder + migration | Expressions V2 `COMPLETE`; legacy fail-closed |
| PokeMap | Catalogue canonique de commandes | `CONTRADICTORY` | E-CORE-NARR/E-STATIC : 22 IDs `narrative_command_catalog.dart:4-25`; parity tests; static builder/adapter `:751/:42` | Contrat et palette synchronisés pour 22 IDs | `staticEncounter` ne traverse pas l’adapter produit générique | Le catalogue sur-promet une commande | P0 | M | map_core/runtime/editor | Parité via composition réelle |
| PokeMap | Pickers narratifs modernes | `PARTIAL` | E-ED-EVENT : `scene_action_builder.dart:28-378`; Event Builder/workspace pickers; tests frais | La majorité des références est guidée | Static picker produit un payload invalide; IDs projet et legacy restent bruts | Le parcours n’est pas uniformément no-code | P0 | M | Index projet + static contract | Test paramétré des 22 via adapter réel |
| PokeMap | Templates d’événements | `PARTIAL` | E-ED-EVENT : `narrative_template_catalog.dart:7-219`; 15 templates; transaction/recovery tests | Preview, validation, application atomique, undo/recovery | Templates arène/rival/static/gift générique incomplets | Accélérateurs utiles mais couverture incomplète | P1 | M | Command catalog | Ajouter seulement les 4 templates manquants |
| PokeMap | Combats de trainers | `COMPLETE` | E-ED-EVENT/E-GP-COMBAT : picker/commande/template trainer; runtime/Golden tests | Authoring, JSON, runtime, save/récompense | Richesse avancée post-MVP | Fonction centrale exploitable V0 | P0 | M | map_battle | Trainer GUI→KO→reward→resume |
| PokeMap | Rencontres statiques | `CONTRADICTORY` | E-STATIC : catalog builder `:751`; Scenes workspace `:2152`; runtime adapter `:42`; boss Selbrume E2E | Un boss spécialisé fonctionne | Builder, picker et adapter génériques attendent des payloads incompatibles; parity callback factice | Fonction publiée mais non fiable | P0 | M | Battle public contract | Builder→JSON→adapter réel→game |
| PokeMap | Cadeaux et starter | `PARTIAL` | E-RUN-NARR/E-GP-LOOP : `givePokemon`, `giveConfiguredStarter`; writer `:333`; test party pleine | Starter et cadeau avec place sont typés/persistés | Cadeau party pleine renvoie erreur au lieu du PC; template dédié absent | Une récompense narrative normale peut échouer | P0 | M | Species picker + storage | Gift party-or-box atomique |
| PokeMap | Boutiques | `COMPLETE` | E-ED-EVENT/E-HOST-JOURNEY : shop builders ; resolver validator ; Selbrume FG-079 tests | Catalogue/conditions/stock/transactions | UX catalogue large à polir | Économie jouable | P0 | M | Items/money | Shop authored→buy→save/reopen |
| PokeMap | Centres de soin | `COMPLETE` | E-RUN-NARR/E-HOST-JOURNEY : `openHeal`/`healParty`; UI/runtime host tests | Dialogue/port, soin et persistance | Animation/service avancé optionnel | Boucle exploration/combat | P0 | S | Party/save | Heal authored + PP/status |
| PokeMap | Badges | `COMPLETE` | E-RUN-NARR/E-HOST-JOURNEY : `awardBadge`; catalog/runtime parity ; save | Attribution typée et persistée | Dashboard progression plus riche | Jalons d’aventure | P0 | S | Facts/save | Badge conditionne zone/ending |
| PokeMap | Capacités terrain | `PARTIAL` | `unlockFieldAbility`; Surf runtime/roadmap tests | Déverrouillage et Surf V0 | Ensemble Cut/Strength/etc. et authoring E2E | Exploration verrouillée limitée | P2 | L | Terrain/runtime | Field Ability Framework après MVP |
| PokeMap | Cinématiques canoniques | `COMPLETE` | E-RUN-NARR : `CinematicAsset`; playback controller/sinks et tests frais | Timeline supportée, caméra, acteurs, dialogue, media/fx | E2E auteur neutre souhaitable | Mise en scène canonique viable | P1 | M | Scene/runtime/media | Cinematic→Fact→save |
| PokeMap | Cutscene Studio historique | `CONTRADICTORY` | E-CORE-NARR/E-RUN-NARR : `cutscene_studio_models.dart:171`; advisories/executor legacy | Quelques blocs simples | Choice/wait, apparition, caméra/call authorables mais inertes ou bloqués | L’éditeur accepte des séquences non exécutables | P0 | L | Migration Scenes/Cinematic | Masquer, migrer ou implémenter |
| PokeMap | Fin de jeu et crédits | `COMPLETE` | E-RUN-NARR/E-HOST-JOURNEY : `finishGame`; contract/runtime parity ; phase 7A 19 critères | Politique fin, victoire, crédits, retour hub | Authoring humain de bout en bout non certifié | Aventure réellement terminable | P0 | S | Ending config | UI builder→package→Avelune |
| PokeMap | Personalization Studio | `PARTIAL` | E-PERS : tests editor + PH-007 + phases 5/6 Avelune | Modèle, preview, package et runtime V0 | Certification visuelle multi-device | Identité originale du jeu | P1 | M | Media/device lab | PST release receipt frais sur HEAD |
| PokeMap | Intro portrait/paysage | `CONTRADICTORY` | E-PERS : validation profil accepte portrait; preview; `player_intro_video_surface.dart:53` | Import/export et preview au ratio source | Player impose 16:9; pas de playback device frais | Preview créateur potentiellement fausse | P0 | M | Encodage + player | Golden shared + devices |
| PokeMap | Prévisualisation | `PARTIAL` | E-ED-UX : preview tests ; build desktop réussi | Preview fonctionnelle automatisée | Session visuelle perdue ; deux overflows | Défauts vus tardivement | P0 | M | Marionette stable | Walkthrough screenshots + overflow regression |
| PokeMap | Validation narrative disponible | `COMPLETE` | E-CORE-NARR/E-ED-EXPORT : `validateNarrativeProject`; validators/tests | Diagnostics projet/narration riches existent | Branchement export traité séparément | Réparations identifiables | P0 | M | Catalog/schema | Garder diagnostics navigables |
| PokeMap | Validation de jouabilité avant export | `CONTRADICTORY` | E-ED-EXPORT : UI « Package certifié » ; `runtime_project_projection_builder.dart:75-255`; aucune invocation des validateurs globaux dans `features/game_export` | Projection, présentation, dialogues, symlinks, budgets, hash et compatibilité vérifiés | Starter/spawn/références globales/fin atteignable non gatés | Un package certifié peut rester injouable | P0 | L | Project/Map/Narrative validators | `GameplayPublishReadinessGate` bloquante |
| PokeMap | Export de package | `PARTIAL` | E-ED-EXPORT : map_distribution ; packaging E2E ; export tests | Package déterministe/inspectable consommable | Extension canonique et release chain incohérentes | Créateur peut produire un fichier, pas le publier sereinement | P0 | M | Version/signature | Export `.avelunegame` canonique + compat legacy |
| PokeMap | Installation dans Avelune | `PARTIAL` | E-AV-INSTALL : inbox tests ; package → hub phases 5/6 | Import/installation automatisés | Parcours public mobile complet rouge | Dernier kilomètre non certifié | P0 | M | AV-001/extension | Editor export → Files → Avelune → ending |
| PokeMap | Parcours sans ID manuel | `UNPROVEN` | E-ED-EVENT : pickers nombreux, pas de census exhaustif | Parcours courants guidés | Preuve globale et détection des champs ID | Erreurs et sentiment « pas no-code » | P0 | M | Picker inventory | Test robot sans saisie libre d’ID |
| PokeMap | Playtest global du projet courant | `MISSING` | E-ED-PLAYTEST-MISS : `global_story_studio_panels.dart:157-159` | Dialogue/Event/Personalization ont des previews | Aucun lancement sandbox unique de tout le projet | Les bugs inter-systèmes arrivent à l’export | P0 | L | Runtime host/projection | Playtest local du workspace courant |
| PokeMap | Projet vide → aventure finie uniquement via UI | `UNPROVEN` | E-MISS-AUTHORING exit 1; E-HOST-JOURNEY ne part que d’une fixture | Runtime termine une fixture riche | Création UI complète non rejouée | Promesse centrale no-code non certifiée | P0 | XL | Tous builders + Avelune | Golden Authoring Journey |
| PokeMap | Accessibilité/clavier éditeur | `PARTIAL` | E-ED-UX : semantics/tooltips/design system ; tests widgets | Base Flutter et composants cohérents | Audit clavier/focus/screen reader complet | Créateurs exclus ou ralentis | P1 | L | Design system | Desktop accessibility matrix |
| PokeMap | Responsive desktop | `CONTRADICTORY` | E-ED-UX : analyseur/build verts ; overflows 29/26 px observés | Fenêtres standards compilent | Empty state déborde dans run frais | Défaut visible malgré gates vertes | P1 | S | Golden sizing | Test fenêtre min sur `map_workspace_empty_state` |
| PokeMap | Adoption du design system | `PARTIAL` | E-ED-UX : guardrail ratchet vert ; baseline 82 fichiers, 573 couleurs directes, 61 imports chrome legacy | Narrative Studio garde une baseline stricte à zéro | Dette historique tolérée ailleurs | Cohérence et thèmes fragiles | P1 | L | Design-system migration | Réduire baseline par studio sans refonte globale |

### 13.3 Gameplay / runtime

| Produit | Fonctionnalité | Statut | Preuves exactes | Ce qui fonctionne | Ce qui manque | Impact joueur/créateur | Priorité | Effort | Dépendances | Prochain test ou lot recommandé |
|---|---|---|---|---|---|---|---|---|---|---|
| Gameplay | Nouvelle partie | `COMPLETE` | E-GP-LOOP : tests new game map_gameplay/runtime/host | État initial, spawn et session V0 | Gate Avelune distinctement rouge | Démarrage moteur fiable | P0 | S | Manifest | Garder test contract + installed |
| Gameplay | Starter | `COMPLETE` | E-GP-LOOP/E-RUN-NARR : `new_game_initial_party_test.dart`; `giveConfiguredStarter` parity | Choix/configuration et party/save | Présentation avancée optionnelle | Boucle collection démarre | P0 | S | Species/party | Starter multi-choix authoring E2E |
| Gameplay | Party | `COMPLETE` | E-GP-LOOP : opérations party ; runtime summaries/tests | Ajout/retrait/ordre et combat/save | QoL avancée | Équipe jouable | P0 | S | Player state | Reprise après battle/capture |
| Gameplay | Résumé de créature | `COMPLETE` | E-GP-LOOP/E-FULL-PLAYER-UI : `save_data.dart`; `runtime_player_detail_router.dart`; party/PC/player UI tests | Infos essentielles, lead/reorder et navigation V0 | EV/IV et profondeur avancée explicitement post-MVP | Compréhension de l’équipe suffisante V0 | P1 | M | Player UI | Golden résumé petits écrans |
| Gameplay | PC et boxes | `COMPLETE` | E-GP-LOOP/E-FULL-PLAYER-UI : `player_storage_operations.dart`; `player_pc_overlay.dart`; tests dépôt/retrait/swap/inter-box portrait/paysage | Gestion storage et destination de capture traversantes | Recherche/tri/rename/release avancés post-MVP | Collection V0 viable | P1 | M | Party/storage UI | PC full journey + capacity edges |
| Gameplay | Capture | `COMPLETE` | E-GP-LOOP : capture flow/formula ; destination operations ; runtime tests | Tentative, résultat, party/box et save | Catalogue exhaustif de balls différé | Cœur collection | P0 | M | Battle/storage | Capture sixième+ et box pleine |
| Gameplay | Rencontres à pied | `COMPLETE` | E-GP-LOOP : encounter tables/runtime host Golden Slice | Zones, tirage et handoff sauvage | Tuning/outils statistiques avancés | Exploration déclenche les combats | P0 | M | Terrain/map | Determinism + save RNG policy |
| Gameplay | Rencontres Surf | `PARTIAL` | données terrain/Surf et branches runtime | Primitives existent | E2E authoring→runtime→save dédié non identifié | Monde aquatique non certifié | P2 | M | Field ability | Surf encounter Golden Slice |
| Gameplay | Rencontres statiques | `CONTRADICTORY` | E-STATIC : boss Selbrume E2E; builder/picker/adapter génériques incompatibles | Combat spécialisé, défaite/retry/victoire et save existent | La commande no-code générique n’atteint pas l’adapter réel | Boss possibles seulement via un chemin non généralisable | P0 | M | Narrative/battle contract | KO/capture/fuite/reload via builder réel |
| Gameplay | Cadeaux | `PARTIAL` | E-GP-LOOP/E-RUN-NARR : `givePokemon` contract/writer/save tests | Don direct et persistance si party non pleine | Aucun fallback PC; `partyFull` explicite | Récompense peut échouer dans une partie normale | P0 | M | Species/storage/template | Gift box-full editor→host |
| Gameplay | Combats sauvages | `COMPLETE` | E-BATTLE : sélection battle +117; phase A runtime smoke | Solo, fuite/capture/KO, writeback | Doubles différés | Boucle de base | P0 | M | map_battle | Installed wild battle device |
| Gameplay | Combats de trainers | `COMPLETE` | E-GP-COMBAT/E-HOST-JOURNEY : trainer node/runtime ; Golden Journey | Déclenchement, victoire/défaite, récompenses | IA/format avancés | Progression principale | P0 | M | Narrative/battle | Rematch policy + resume |
| Gameplay | Objets en combat | `PARTIAL` | E-GP-COMBAT : generic/battle item tests, medicine/revive | Consommation et effets V0 | Catalogue/targeting exhaustif | Stratégie limitée mais jouable | P1 | L | Item catalog | Item parity registry |
| Gameplay | Changement de créature | `COMPLETE` | E-GP-COMBAT : battle switch + PSDK switch tests | Switch volontaire et writeback | Formats multi différés | Contrôle tactique solo | P0 | S | Battle flow | Switch + status/held regression |
| Gameplay | Remplacement après K.O. | `COMPLETE` | E-BATTLE : switch/KO targeted tests +117 | Choix forcé et fin si aucune option | UX device à recertifier | Évite softlock combat | P0 | S | Party UI | KO chain host E2E |
| Gameplay | Statuts | `COMPLETE` | E-GP-COMBAT : status effects/lifecycle suites | Statuts majeurs et cycles V0 | Interactions exhaustives post-MVP | Profondeur combat suffisante | P1 | L | Battle rules | Runtime hydration/writeback matrix |
| Gameplay | Météo | `PARTIAL` | weather/terrain/battle field tests | Règles moteur sélectionnées | Authoring/runtime complet et catalogue | Profondeur non uniforme | P2 | L | Battle setup/editor | Weather authored battle E2E |
| Gameplay | Terrain de combat | `PARTIAL` | terrain/battle field tests | États/effets V0 du moteur | Exposition no-code et parité exhaustive | Créateur ne contrôle pas tout | P2 | L | Editor schema | Terrain setup builder |
| Gameplay | Hazards | `PARTIAL` | spikes/stealth rock tests | Hazards principaux moteur | Authoring et visualisation runtime incomplets | Stratégie avancée limitée | P2 | M | Move registry/UI | Hazard trainer battle E2E |
| Gameplay | PP | `COMPLETE` | E-GP-COMBAT/E-BATTLE : `pp_history_test.dart`; runtime writeback tests | Consommation, historique et persistance | Cas exhaustifs post-MVP | Ressource de combat fiable | P0 | S | Moves/save | PP across heal/save/continue |
| Gameplay | XP | `COMPLETE` | E-GP-COMBAT/E-FULL-GAMEPLAY : `battle_progression_service_test.dart`; runtime postbattle | Attribution postcombat et persistance | Courbes/balance contenu à authorer | Progression de l’équipe | P0 | M | Species/progression | Multi-level edge tests |
| Gameplay | Montée de niveau | `COMPLETE` | E-FULL-GAMEPLAY : progression service/runtime tests | Stats/level et événements postbattle | Mise en scène plus riche | Feedback de progression | P0 | S | XP | Installed level-up |
| Gameplay | Apprentissage d’attaques | `COMPLETE` | E-GP-COMBAT/E-FULL-GAMEPLAY : `battle_move_learning_test.dart`; runtime UI tests | Proposition/remplacement et writeback | UX exhaustive petits écrans | Progression tactique | P0 | M | Move catalog/UI | Four-move replacement E2E |
| Gameplay | Évolutions | `COMPLETE` | E-GP-LOOP/E-FULL-GAMEPLAY : `pokemon_evolution_service_test.dart`; runtime evolution tests | Conditions V0, résultat/save | Méthodes très avancées différées | Collection progresse | P0 | M | Species/items | Cancel/retry/item evolution |
| Gameplay | Argent et récompenses | `COMPLETE` | E-GP-LOOP/E-RUN-NARR : `giveMoney`; battle/shop/outbox tests | Gains, dépenses, conséquences atomiques | Balance/formatage contenu | Économie fonctionnelle | P0 | S | Save/shop | Loss/overflow/rollback |
| Gameplay | Badges | `COMPLETE` | E-GP-LOOP/E-HOST-JOURNEY : `awardBadge` parity ; Golden narrative tests | Attribution, condition et save | Écran collection riche | Jalons de campagne | P0 | S | Facts/UI | Badge gate→field ability |
| Gameplay | Sac | `COMPLETE` | E-GP-LOOP : `party_bag_heal_operations_test.dart`; in-game bag tests | Stock, catégories/usage V0 et save | Tri/filtre/catalogue avancé | Gestion objets jouable | P0 | M | Item registry | Capacity/duplicate/import migration |
| Gameplay | Objets hors combat | `COMPLETE` | E-GP-LOOP : heal/evolution/TM gameplay/runtime tests | Soin, évolution et machines V0 | Tous effets spéciaux non couverts | Préparation/exploration | P1 | M | Bag/party | Unified item capability registry |
| Gameplay | Objets tenus | `PARTIAL` | battle hydration/writeback tests | Effets sélectionnés traversent le combat | Équiper/retirer via UI joueur et catalogue complet | Stratégie/collection incomplète | P2 | L | Summary/bag | Held-item equip flow |
| Gameplay | CT/CS | `PARTIAL` | E-GP-LOOP : `pokemon_move_machine_service_test.dart`; runtime bag tests | Machines et remplacement de move V0 | CS/field abilities unifiées et authoring global | Progression partiellement couplée | P1 | L | Field ability | TM use + Surf unlock journey |
| Gameplay | Boutiques | `COMPLETE` | E-GP-LOOP/E-HOST-JOURNEY : shop validator ; party/bag ops ; FG-079 | Conditions, stock, achat et save | Polissage catalogue | Économie principale | P0 | M | Money/items | Installed shop transaction |
| Gameplay | Soins | `COMPLETE` | E-GP-LOOP : heal operations ; runtime host heal tests | HP/PP/statuts et persistance V0 | Présentation avancée | Boucle combat durable | P0 | S | Party | Heal after status/PP depletion |
| Gameplay | Objets ramassables | `PARTIAL` | E-GP-LOOP/E-RUN-NARR : template canonique `Item ball`; `giveItem` + consommation ; `item_pickup_give_item_readiness_test.dart` | Template no-code et save existent | Pas de host E2E après export | Pickup peut régresser entre couches | P1 | M | Event template/host | Item ball editor→export→reload |
| Gameplay | Objets cachés | `PARTIAL` | template canonique `Objet caché` dans `narrative_template_catalog.dart:117-127` | Composition give+consommation prête | Pas de host E2E spécialisé après export | Fonction réelle mais preuve transversale absente | P2 | M | Template/host | Hidden item editor→runtime→save |
| Gameplay | Pokédex | `COMPLETE` | E-GP-LOOP/E-FULL-PLAYER-UI : seen/caught `PlayerProgression`; normalisation party/boxes ; pause UI et tests runtime/player | Consultation read-only V0 traversante | Recherche/tri/habitat riches post-MVP | Collection lisible pour le MVP | P2 | L | Species registry/UI | Garder Golden Pokédex V0 |
| Gameplay | Pause | `COMPLETE` | E-GP-SAVE/E-FULL-PLAYER-UI : `in_game_menu_test.dart`; runtime overlays | Ouverture/fermeture et navigation V0 | Device back QA | Contrôle de session | P0 | S | Input | Pause during events/battle |
| Gameplay | Sauvegarde et options runtime | `COMPLETE` | E-GP-SAVE : in-game menu/save/preferences tests | Save/checkpoint/options dans host | Preuve Avelune device distincte | Session moteur exploitable | P0 | M | Host/Avelune gateways | Installed device checkpoint |
| Gameplay | Capacités terrain | `PARTIAL` | Surf/unlock tests et commandes | Framework et Surf V0 | Ensemble complet et interactions authorées | Exploration moins riche | P2 | XL | Terrain/editor/UI | Post-MVP field framework |
| Gameplay | Progression narrative globale | `PARTIAL` | E-CORE-NARR/E-RUN-NARR/E-HOST-JOURNEY : catalog/runtime parity; Storylines; `game_state_persistence.dart:31`; Selbrume | Facts, steps et conséquences atomiques | Storylines partielles et bridge variables legacy incomplet | Une campagne générique peut diverger après save | P0 | L | Save/editor | Unifier état puis Golden Authoring |
| Gameplay | Campagne fixture Selbrume | `COMPLETE` | E-HOST-JOURNEY : `selbrume_player_journey_e2e_test.dart`; phase 7A 19 critères | Quêtes, Surf, trainer, capture PC, shop, heal, save/reload et fin | Ne prouve pas tout builder générique | Capacité moteur complète sur cette fixture | P0 | M | Host fixture | Garder comme regression, pas comme vérité auteur |
| Gameplay | Arènes | `PARTIAL` | E-HOST-JOURNEY : trainers, badges, conditions et fin composables | Briques nécessaires disponibles | Template/UX d’arène et campagne UI complète | Créateur assemble manuellement | P1 | L | Templates | Gym template → badge → gate |
| Gameplay | Rival | `PARTIAL` | NPC presence, trainers, story steps composables | Rencontres évolutives possibles | Template roster/progression dédié | Complexité de campagne | P2 | L | Storyline/templates | Rival arc sample |
| Gameplay | Fin de l’histoire | `COMPLETE` | E-RUN-NARR/E-HOST-JOURNEY : `finishGame` parity ; phase 7A 19/19 | Ending, victoire, politique de sortie et save | Human mobile walkthrough | Aventure terminable moteur | P0 | S | Credits/Avelune | Installed ending on release candidate |
| Gameplay | Crédits | `COMPLETE` | E-HOST-JOURNEY : host phase 7A et runtime credits tests | Surface crédits et retour hub | Accessibilité/long contenu device | Fermeture produit V0 | P0 | S | Ending config | Rotation/screen reader credits |
| Gameplay | Postgame | `PARTIAL` | politique de fin supporte continue ; Selbrume le désactive | Contrat permet un choix | Aucun contenu postgame complet démontré | Pas blocker de l’aventure principale | P3 | L | Ending/save/content | Post-MVP mini-quest |
| Gameplay | Combats doubles/multi | `DEFERRED` | roadmap mécanique et non-objectifs MVP | Solo solide | Moteur/UI/authoring complets multi | Aucun impact sur MVP solo | P3 | XL | Battle architecture/UI | Après certification MVP |
| Gameplay | Parité exhaustive objets/abilities/moves | `DEFERRED` | roadmap et rapports de lots de parité | Sous-ensemble utile V0 | Long tail exhaustif | Ne bloque pas une aventure originale | P3 | XL | Registries | Prioriser seulement besoins de contenu |
| Gameplay | Multijoueur/online compétitif | `DEFERRED` | hors boucle MVP et aucun contrat produit requis | — | Réseau, comptes, sécurité, matchmaking | Risque majeur de diversion | P3 | XL | Backend entier | Ne pas démarrer avant MVP solo |

### 13.4 Qualité, production et gouvernance

| Produit | Fonctionnalité | Statut | Preuves exactes | Ce qui fonctionne | Ce qui manque | Impact joueur/créateur | Priorité | Effort | Dépendances | Prochain test ou lot recommandé |
|---|---|---|---|---|---|---|---|---|---|---|
| Transverse | Architecture par packages | `COMPLETE` | E-ARCH : barrels et boundary/session tests exacts | Règles, UI et intégration séparées | Réduire quelques noms historiques plus tard | Facilite évolution/test | P0 | S | CI | Garder boundary tests obligatoires |
| Transverse | Localisation | `PARTIAL` | E-ED-UX : l10n map_player_ui/hub/editor ; tests strings | Plusieurs surfaces localisées | Couverture exhaustive/native/content non mesurée | Texte incohérent possible | P1 | L | String catalog | Census hardcoded player strings |
| Transverse | Responsive | `CONTRADICTORY` | E-ED-UX : analyses vertes ; overflows editor observés | Beaucoup de layouts adaptatifs | Défaut concret sur petite contrainte | UI peut casser sans alerte | P1 | M | Golden matrix | Device/window size CI |
| Transverse | Accessibilité | `PARTIAL` | E-ED-UX/E-AV-UX : semantics/tooltips/options ; tests widgets | Fondations disponibles | Audit assistive tech complet | Accessibilité non garantie | P1 | L | Devices/design system | WCAG/mobile/desktop walkthrough |
| Transverse | Performance | `UNPROVEN` | E-FULL-EDITOR : aucun benchmark/budget frais ; builds seulement | Compilation et fixtures passent | RAM/FPS/start/import/battery | Risque terrain inconnu | P1 | L | Perf harness | Budgets et trace profiles |
| Transverse | Stabilité | `CONTRADICTORY` | E-FULL-RUNTIME/E-FULL-EDITOR/E-FULL-AVELUNE : matrices ciblées vertes ; save timeout, smoke iOS, runtime externe et budget éditeur globaux rouges | Cœur largement testé ; runtime/editor isolés utiles | Quatre gates présentent intégration, herméticité ou flake | Release non fiable | P0 | M | AV-001/002 + test hygiene | Stabiliser avant nouvelles features |
| Transverse | Migrations schéma/projet | `PARTIAL` | E-AV-SAVE : modèles/migrations/tests | Compatibilité V0 couverte | Corpus de versions distribuées absent | Projets créateurs à risque | P0 | L | Version source unique | Fixture matrix N-2/N-1/N |
| Transverse | Récupération après crash | `PARTIAL` | E-AV-INSTALL/E-AV-SAVE : install/save crash writers et tests | Interruptions simulées couvertes | Kill OS app entière et bootstrap recovery | Corruption/perte potentielle | P0 | M | Device integration | Fault injection mobile |
| Distribution | Compatibilité de packages | `COMPLETE` | E-DIST-SEC : inspector/host compatibility/tests | Version/schema/assets vérifiés fail-closed | Politique long terme à maintenir | Rejet clair des incompatibles | P0 | M | Version contract | Old/new host corpus |
| Distribution | Sécurité des archives | `COMPLETE` | E-DIST-SEC : map_distribution tests de menaces | Défenses structurelles substantielles | Fuzz/audit externe | Réduit risque import | P0 | M | CI corpus | Continuous fuzz |
| Distribution | Chaîne de confiance | `PARTIAL` | E-DIST-SEC : signature publicCatalog | Mode public signé prévu | Catalogue, rotation/révocation non opérés | Authenticité variable | P1 | L | PKI/backend | Signed sample + revoked key |
| Transverse | Diagnostics | `PARTIAL` | E-AV-INSTALL/E-AV-SAVE : typed diagnostics/logs/recommendations | Erreurs structurées | Bundle redacted et observabilité release | Support plus lent | P1 | M | Privacy | Diagnostic export contract |
| Transverse | Couverture de tests | `PARTIAL` | E-FULL-CORE/E-FULL-GAMEPLAY/E-FULL-BATTLE/E-FULL-RUNTIME/E-FULL-EDITOR/E-FULL-HOST : suites fraîches : core +4502, gameplay +428, battle +1764, host +257 ; editor/runtime globaux chacun 1 échec ; aucune mesure coverage | Profondeur unitaire/intégration forte | Trous devices et gates globales non vertes | Faux sentiment de complétude possible | P0 | M | Test inventory | Requirement→test traceability |
| CI | Couverture package par PR | `PARTIAL` | E-CI : workflows et audit architecture | Plusieurs gates/release jobs | Chaque package n’est pas directement garanti sur chaque PR | Régression interpackage | P0 | M | Workflow matrix | CI monorepo package-scoped |
| CI | Dashboard FG | `CONTRADICTORY` | E-CI : generator `--check` vert ; 41 MD/12 JSON imbriqués ignorés | Vue synthétique reproductible | Source de vérité incomplète/périmée | Mauvaise priorisation produit | P0 | M | Evidence registry | FG Evidence Registry récursif |
| Distribution | GitHub Releases desktop | `CONTRADICTORY` | E-CI/E-RELEASE : prerelease tag HEAD; artefacts desktop SHA identiques au run `28c03879`; run HEAD annulé | Trois previews téléchargeables | Tag `a3d741818` mais binaires d’un commit antérieur | Provenance trompeuse | P0 | M | Signing/versioning | Release atomique mono-SHA |
| Distribution | Signature Android | `UNPROVEN` | E-CI : Gradle fail-closed + workflow secrets | Configuration robuste sur le papier | APK release réel inspecté absent | Avelune non publiable avec preuve | P0 | M | Secrets/tag | apksigner + install + receipt |
| Distribution | Notarisation macOS | `CONTRADICTORY` | E-MAC-HIST/E-BUILD : anciens rapports NO-GO ; DMG Hub historiques staplés/acceptés ; build HEAD ad hoc rejeté | La chaîne a déjà produit un Hub accepté | Pas de candidat HEAD ni preuve éditeur actuelle | Impossible d’extrapoler au release courant | P0 | M | Developer ID/notary | Rebuild HEAD, notarize, cold install |
| Distribution | Xcode Cloud | `UNPROVEN` | E-CI : scripts présents | Build iOS préparé | Run/archive/TestFlight absents | iOS production non certifié | P0 | M | Apple services | Export receipt machine-readable |
| Distribution | Versionnement | `CONTRADICTORY` | E-CI/E-RELEASE : pubspec/tag/Xcode fallbacks divergents | Versions injectables par pipeline | Source unique et tests artefact absents | Updates/migrations/stores fragiles | P0 | S | Release manifest | Version contract V0 |
| Distribution | Mises à jour | `CONTRADICTORY` | E-AV-MAINT/E-CI : installer/maintenance services; composition `UnsupportedError` | Transactions de base testées | Save migration et UI production explicitement bloquées | Jeux figés malgré backend présent | P0 | L | Migrations/versioning | AV-004 |
| Distribution | Taille des artefacts | `UNPROVEN` | E-BUILD/E-RELEASE : tailles build local/CI ponctuelles | Des octets peuvent être relevés | Budget, ABI, taille installée, tendance | Risque de rejet/abandon | P1 | M | Reproducible builds | Size gate par plateforme |
| Distribution | Reproductibilité | `CONTRADICTORY` | E-CI/E-RELEASE : Flutter pin GitHub; Xcode stable mouvant; prerelease mélange deux SHA | GitHub épingle une version sur certains jobs | Toolchains non uniformes et promotion multi-commit | Une release ne correspond pas à une source unique | P0 | M | Toolchain/release manifest | Pin unique + promotion mono-SHA |

---

## 14. Contradictions découvertes

| ID | Sources en contradiction | Constat actuel | Conséquence |
|---|---|---|---|
| C-01 | Roadmap Phase 5 / code et tests actuels | Des lots TODO décrivent commandes narratives, Facts, variables ou conditions comme manquants ; catalogue, authoring, runtime, save et parités existent. | Les priorités déduites uniquement de la roadmap seraient fausses. |
| C-02 | Audit mécanique du 2026-07-26 / `finishGame` actuel | L’ancien audit dit la fin absente ; commande, mapper runtime, victoire, crédits et parcours 19/19 existent. | Ne pas réimplémenter la fin ; certifier son authoring/mobile. |
| C-03 | Dashboard `--check` vert / collecte de preuves | Le générateur est cohérent mais ignore 41 Markdown et 12 JSON imbriqués et interprète mal certains noms/formats. | Le résumé FG n’est pas une vérité code. |
| C-04 | Suite Avelune standard / timeout étendu | `+189 -1` à 30 s ; `+190` avec `--timeout 2m`. | La logique atomique paraît bonne, la gate standard ne l’est pas. |
| C-05 | Tests new game/runtime / smoke iOS installé | Les contrats sont verts ; le driver mobile ne traite pas « Votre identité » et timeoute. | La fonctionnalité et la certification divergent. |
| C-06 | `GameMaintenanceService` / composition production | Repair/update/uninstall ont code et tests ; seule l’action import est injectée, et update lève `UnsupportedError`. | Boutons ou services présents ne signifient pas fonction livrée. |
| C-07 | `.pokemapgame` / `.avelunegame` | Éditeur et certains tests gardent l’ancien canon ; mobile accepte les deux et iOS présente Avelune. | Confusion de distribution, docs et association de fichiers. |
| C-08 | Preview Android verte / production | La run HEAD produit un gros APK debug ; aucun tag release signé, AAB ou Play n’est prouvé. | Un artefact installable de CI n’est pas une release. |
| C-09 | Noms de fichiers par tag / métadonnées binaires | Les workflows nomment les archives depuis le tag ; pubspec/buildName/buildNumber peuvent rester `0.1.0+1` ou `0.2.0`. | Stores, migrations et support voient une autre version. |
| C-10 | Rapports historiques / état externe courant | Des rapports disent qu’aucune identité Developer ID n’est disponible ; cinq identités valides sont visibles aujourd’hui et deux DMG Hub historiques sont staplés/acceptés. | Les credentials sont temporels ; l’absence historique n’est pas une absence actuelle. |
| C-11 | DMG Hub historiques / candidat HEAD | Un DMG Hub d’un commit ancêtre est notaré ; les builds debug HEAD sont ad hoc et rejetés par `spctl`. | La chaîne a déjà fonctionné, mais le HEAD n’est pas certifié. |
| C-12 | Analyze/build éditeur verts / run réel | Aucun diagnostic statique ; deux `RenderFlex overflow` visibles au lancement. | Il faut des goldens dimensionnels et une QA visuelle. |
| C-13 | Golden Journey 19/19 / parcours humain | Le driver prouve le moteur et interdit les shortcuts ; aucune walkthrough humaine fraîche du même package/candidat n’existe. | « E2E automatisé » ne doit pas devenir « UX validée ». |
| C-14 | Reçu PH-007 / working tree | Le reçu de Personalization était modifié avant l’audit. | Il reste une preuve secondaire, jamais la seule source. |
| C-15 | CI desktop/certification / HEAD | Les runs HEAD récentes sont annulées ; les dernières réussites portent sur des commits antérieurs et les jobs notarisation sont sautés. | Aucun GO production ne peut être attribué au HEAD. |
| C-16 | « aventure terminable » / « aventure créable no-code » | Selbrume se termine dans le moteur ; son authoring intégral via l’UI courante n’est pas rejoué. | La capacité runtime ne clôt pas la promesse produit. |
| C-17 | Tests nombreux / couverture produit | Des milliers de tests existent, mais aucun lien exhaustif requirement→six couches→device release. | Les trous sont transversaux, pas nécessairement unitaires. |
| C-18 | Variables annoncées complètes / voies V2 et save bridge | `ScriptVariables` et `setVariable` existent, mais ne sont pas dans le catalogue moderne V2 et le bridge `SaveData` les remet à vide. | Une quête legacy basée sur variables peut perdre son état selon le chemin de persistance. |
| C-19 | Libellé « Package certifié » / pipeline export | L’export vérifie projection, sécurité, hash, présentation et dialogues, mais ne branche pas la validation globale de jouabilité. | Un créateur peut prendre une certification technique pour une preuve d’aventure terminable. |
| C-20 | Guardrail design vert / baseline réelle | La gate passe en ratchet tout en tolérant 82 fichiers, 573 couleurs directes et 61 imports legacy. | « Test vert » ne signifie pas adoption complète du design system. |
| C-21 | Destination éditeur / identité mobile | La publication inbox parle encore de « PokeMap Hub », alors que l’application mobile publique est Avelune. | Confusion créateur sans violation du bundle mobile natif. |
| C-22 | Tests runtime ciblés / suite intégrale | La sélection gameplay est verte ; la suite complète échoue sur `le_train_m00_external_runtime_smoke_test.dart`, qui lit `/Users/karim/Desktop/...` et attend une couche `l_structure` absente. | La gate runtime globale n’est pas hermétique ni portable. |
| C-23 | Tests éditeur ciblés / suite intégrale | Les sélections éditeur documentées (225/225 et +29, non additionnées car potentiellement chevauchantes) sont vertes ; la suite complète échoue sur un budget 1 000 Steps, lequel passe immédiatement seul (`p95 7 644 µs < 20 000 µs`). | Le budget est sensible à la concurrence/charge et rend la gate globale flaky. |
| C-24 | Catalogue `staticEncounter` / builder, picker et adapter réels | Le builder fournit `battleTemplateId` sans `trainerId`, le picker fait l’inverse et l’adapter exige `trainerId`; la parité utilise un callback factice. | Une commande déclarée supportée peut échouer dans le chemin produit générique. |
| C-25 | Preview intro portrait / player Avelune | L’éditeur accepte et prévisualise le ratio source ; `PlayerIntroVideoSurface` force 16:9. | La personnalisation visible au joueur peut contredire celle validée par le créateur. |
| C-26 | Prerelease taggée HEAD / SHA des artefacts | L’APK vient du HEAD, les trois desktops sont bit-à-bit ceux du run sur `28c03879`; le run desktop HEAD est annulé. | La release publiée n’est pas une unité reproductible. |

### 14.1 Crosswalk FG proposé — roadmap non modifiée

| Lot(s) | Statut roadmap observé | Statut proposé après audit | Preuve / réserve |
|---|---|---|---|
| FG-071 | ancien texte d’absence | `DONE` V0 proposé | `healParty`, `openHeal`, template Nurse, writer et host flow verts |
| FG-080 | `TODO` | `PARTIAL` proposé | Conditions V2 fonctionnelles ; conditions legacy malformées pas fail-closed |
| FG-081 | `TODO` | `PARTIAL` proposé | Facts typés complets ; variables legacy et bridge `SaveData` incomplets |
| FG-082 | référence 18 commandes | `PARTIAL` proposé | Catalogue à 22 IDs ; static générique casse la fermeture produit |
| FG-086 | `TODO` | `DONE` V0 proposé | Trainer authoring, JSON, battle, récompense, save et Golden Journey |
| FG-088 | `TODO` | `DONE` V0 proposé | Event Builder V2 modèle/editor/runtime/persistence et tests frais |
| FG-093 | référence 18 commandes | `PARTIAL` proposé | Parités fortes mais callback static factice ; nombre à corriger à 22 |
| FG-094 | `TODO` | `PARTIAL` proposé | 15 templates réels ; static/gift/gym/rival restent à fermer |
| FG-100–103 | `TODO` historiques | `PARTIAL` proposé | Static spécialisé réel mais générique `CONTRADICTORY`; cadeau party pleine incomplet |
| FG-140/143 | statuts historiques dépassés | revue lot par lot | Trainers/badges beaucoup plus avancés ; done criteria produit à relire |
| FG-146 | ancien gate incomplet | `PARTIAL` proposé | Validators existent, export ne les appelle pas tous |
| FG-147 | ancien manque de fin | `DONE` V0 proposé | `finishGame`, checkpoint terminal, résultat et crédits verts |
| FG-160–164 | `TODO` malgré rapports de clôture | `CONTRADICTORY` | Rapports présents mais dashboard ne les ingère pas récursivement ; ne pas passer `DONE` sans receipt frais par lot |
| FG-180–184 | `DONE` | conserver `DONE` sous preuves actuelles | Lots Golden/Personalization déjà fermés par leurs gates |
| FG-185 | `PARTIAL` / NO-GO | conserver `PARTIAL` | Huit blockers MVP du §19 restent ouverts |

Ce tableau est une proposition de correction, pas une modification de
`pokemap_roadmap_mecaniques_fangame.md`.

---

## 15. Risques

### 15.1 Risques critiques

1. **Fausse confiance de release.** Un dashboard vert, un APK debug ou un
   Golden Slice vert peut être interprété à tort comme une application
   distribuable.
2. **Perte de save lors d’une update future.** L’équipe a justement bloqué
   `prepareSavesForUpdate`, mais publier avant de fermer cette transaction
   transformerait la dette en incident utilisateur.
3. **Dérive d’intégration.** Le dialogue d’identité a été ajouté sans faire
   évoluer le smoke installé ; le même pattern peut toucher starter, save,
   ending ou personnalisation.
4. **Version binaire incohérente.** Le tag, le nom du fichier et la version
   interne peuvent diverger ; toute migration/support devient ambigu.
5. **Preuve no-code insuffisante.** Des mécaniques très riches peuvent rester
   inutilisables par un créateur si un picker, un template ou un diagnostic
   manque au milieu.

### 15.2 Risques élevés

- taille énorme du preview Android debug : APK raw 187 491 909 octets, trois
  ABI et `kernel_blob.bin` de 110 506 784 octets ; non représentatif d’une
  release, mais signal qu’un budget est nécessaire ;
- Xcode Cloud dépend d’une branche Flutter mouvante ou d’un Flutter préexistant
  non vérifié ;
- CLI Flutter `3.46.0-0.3.pre`/Dart 3.13 beta alors que le `dart` du PATH est
  3.12.1 stable ; les toolchains ne sont pas homogènes ;
- aucune matrice devices Android, iOS, petits écrans et accessibilité ;
- rapports et reçus trop nombreux, parfois sales ou hors HEAD ;
- cancellation des workflows HEAD sans cause prouvée ;
- densité/complexité de `map_editor`, qui peut cacher une forte dette UX.

### 15.3 Risques modérés

- acceptation d’un package local non signé ;
- logs locaux pouvant exposer des noms techniques internes ;
- dette de templates qui pousse les créateurs à recomposer des séquences
  sensibles ;
- features avancées moteur non accessibles dans l’authoring ;
- fixtures canoniques qui évoluent plus vite que les parcours humains.

---

## 16. Dette technique réellement bloquante

| Dette | Pourquoi elle bloque réellement | Sortie attendue |
|---|---|---|
| Gate installée Avelune obsolète | La promesse centrale est rouge sur iOS simulator | Un seul test sans shortcut franchit identité, jeu, checkpoint, teardown et Continue |
| Transaction save/update incomplète | Empêche volontairement l’update production | Migration préparée, commit/rollback récupérables et test kill à chaque phase |
| Actions maintenance non composées | Un backend non accessible ne résout aucun incident joueur | Repair/uninstall/update câblés avec confirmations et politiques saves |
| Source de version multiple | Rend artefacts, stores et migrations non traçables | Manifest de release unique injecté et vérifié dans chaque binaire/package |
| Evidence dashboard non récursif | Fait remonter des TODO périmés et masque des preuves | Registre de preuves structuré, HEAD, commande, résultat, date et portée |
| Variables/Facts en deux voies | Peut perdre des variables de quête au passage par `SaveData` | Contrat d’état narratif unique, migration et round-trip tests |
| Golden Authoring Journey absent | La capacité no-code principale n’est pas certifiée | Projet créé/authoré via UI, exporté, installé et terminé |
| CI monorepo partielle | Des changements interpackages peuvent éviter leur gate directe | Matrice package-scoped + gates transversales |
| Tests globaux non hermétiques | Le runtime dépend d’un projet machine et un budget perf dépend de la concurrence | Fixtures versionnées dans le dépôt et lane perf séquentielle dédiée |
| QA responsive/device absente | Des overflows existent malgré analyse verte | Goldens fenêtres/devices + walkthrough réelle |

La taille, le catalogue et la richesse postgame sont importantes, mais ne sont
pas la dette la plus bloquante tant que cette chaîne n’est pas fermée.

---

## 17. Fonctionnalités à ne pas prioriser maintenant

1. Combats doubles/multi et online.
2. Parité exhaustive avec des catalogues historiques d’abilities, objets et
   attaques.
3. Postgame long.
4. Breeding, concours, fonctionnalités sociales ou économie réseau.
5. Marketplace/catalogue public complet avant contrat de signature,
   versionnement et update.
6. Field abilities nombreuses au-delà de ce que demande l’aventure Golden.
7. Refonte visuelle large du moteur ou de l’éditeur sans lien avec un
   parcours bloqué.
8. Micro-polish d’ombres, tilesets et animations non nécessaire aux gates.
9. Refactorisations opportunistes de packages déjà bien séparés.
10. Objectif de « pourcentage de complétude » : il masquerait la nature
    transversale des blockers.

Ces sujets ont de la valeur post-MVP, mais chacun augmente la surface à
certifier sans résoudre la promesse centrale.

---

## 18. Quick wins

| Ordre | Quick win | Effort | Gain |
|---:|---|---|---|
| 1 | Mettre à jour `runtime_owned_player_flow_test.dart` pour remplir le dialogue d’identité | XS | Restaure la preuve installée de base |
| 2 | Donner au crash-test atomique un budget explicite ou réduire son coût sans retirer d’étapes | XS | Rend la suite standard honnêtement verte/rouge |
| 3 | Centraliser la constante d’extension canonique `.avelunegame` avec compat legacy | S | Supprime une contradiction publique |
| 4 | Tester l’appel de recovery d’installation au bootstrap | S | Ferme un risque crash immédiat |
| 5 | Ajouter le test fenêtre minimale de `map_workspace_empty_state` | XS | Reproduit les overflows observés |
| 6 | Ajouter le test rouge de round-trip `ScriptVariables` via `SaveData` | XS | Matérialise une perte d’état narrative |
| 7 | Remplacer le chemin Desktop du smoke runtime par une fixture versionnée | S | Rend la suite portable et non destructive |
| 8 | Isoler les budgets performance éditeur dans une lane séquentielle | S | Supprime le flake sans relâcher le budget |
| 9 | Pinner et vérifier le même Flutter dans Xcode Cloud | S | Réduit la non-reproductibilité |
| 10 | Injecter build-name/build-number depuis un manifest unique | S | Aligne tag, binaire et migrations |
| 11 | Rendre la collecte de rapports FG récursive et multi-ID | M | Améliore immédiatement la vérité de roadmap |
| 12 | Ajouter un census automatisé des champs ID/pickers | M | Rend mesurable la promesse no-code |
| 13 | Produire une démo neutre seedée au premier lancement | M | Rend Avelune testable sans fichier externe |
| 14 | Exposer Repair/Uninstall avec politiques saves avant Update | M | Valorise un backend déjà construit |
| 15 | Ajouter un budget et un rapport de taille release par ABI | S | Transforme une inquiétude en gate |

---

## 19. Blockers MVP

Le MVP « créer, distribuer, installer, jouer, sauvegarder et terminer » ne doit
pas être déclaré prêt tant que les huit blockers suivants restent ouverts :

1. **Avelune Installed Journey vert** sur au moins iOS simulator et Android
   emulator/device, sans contourner identité, starter, runtime, save et reprise.
2. **Golden Authoring Journey** partant d’un projet vide et utilisant uniquement
   les surfaces no-code supportées.
3. **Gate de jouabilité avant export** qui réutilise les validateurs projet,
   carte et narration et ne présente pas un package comme certifié sans
   starter/spawn/références/fin valides.
4. **Update/save transaction** avec migration, rollback et récupération
   démontrés.
5. **Maintenance joueur** : repair et uninstall réellement câblés, avec choix
   de conservation des saves.
6. **Release contract** unique : version, extension, compatibilité, signature,
   identité Avelune et reçus liés au même HEAD.
7. **Candidat production prouvé** : APK/AAB ou distribution Android retenue,
   archive/TestFlight iOS, et binaires desktop PokeMap signés/notariés selon la
   plateforme cible.
8. **État narratif unifié** : Facts et variables survivent à tous les bridges
   de save/migration réellement utilisés.

L’accessibilité device, les tailles et la stabilité responsive doivent faire
partie de cette certification, même si leurs enrichissements avancés peuvent
continuer après le MVP.

---

## 20. Recommandations post-MVP

Une fois les blockers fermés :

- catalogue signé minimal et découverte ;
- backup/export/import de saves avec conflits gérés ;
- Pokédex, boxes, résumé et objets tenus enrichis ;
- field abilities supplémentaires ;
- rencontres Surf et météo/terrain/hazards authorables de bout en bout ;
- templates d’arène, rival et postgame ;
- profils de performance et optimisation taille ;
- langues supplémentaires ;
- diagnostics consentis et support ;
- doubles/multi uniquement si un contenu concret les exige.

---

## 20 bis. Roadmap recommandée en lots commitables

La recommandation reste la stratégie **PokeMap/no-code avec gate transverse
Avelune**. Les lots mécaniques suivants n’avancent qu’après un artefact
créateur réellement publiable.

### Phase 0 — Restaurer les signaux et les contrats

| Lot | Objectif | Périmètre | Dépendances | Tests exigés | Définition de terminé | Risques |
|---|---|---|---|---|---|---|
| T0-1a | Réparer la gate mobile | Driver identité iOS uniquement | Aucune | Smoke iOS titre→identité→playing | Gate installée verte sans shortcut | Confondre driver et défaut produit |
| T0-1b | Stabiliser la gate save | Harness/timeout du crash-stage uniquement | Aucune | Hub standard et 7 crash stages | Suite standard verte sans supprimer de stage | Cacher une lenteur réelle |
| T0-1c | Rendre le runtime hermétique | Remplacer le projet Desktop absolu par une fixture versionnée | Aucune | Suite runtime complète depuis checkout isolé | Aucun chemin machine ni écriture hors temp | Taille/fidélité de fixture |
| T0-1d | Isoler les budgets performance | Lane éditeur séquentielle, charge et warmups documentés | Aucune | Trois runs du budget 1 000 Steps + suite fonctionnelle | Budget stable sans relever le seuil | Masquer une vraie régression |
| T0-2 | Unifier `staticEncounter` | Catalogue, builder, picker, diagnostics, adapter | Battle public contract | Builder→JSON→adapter réel→`PlayableMapGame`; boss Selbrume regression | Un payload unique, aucun callback factice | Migration des fixtures |
| T0-3 | Bloquer l’export injouable | Project/Map/Narrative validators, spawn, starter, fin | T0-2 | Négatifs ref/map/spawn/fin/static; positif Selbrume | « Certifié » implique tous les diagnostics P0 verts | Temps de validation |
| T0-4 | Fiabiliser le dashboard FG | Registre lot/SHA/commandes/résultats/fraîcheur | CI metadata | Rapports imbriqués, multi-ID, statuts contradictoires | Dashboard dérivé de preuves structurées | Migration documentaire |

### Phase 1 — Fermer le parcours auteur no-code

| Lot | Objectif | Périmètre | Dépendances | Tests exigés | Définition de terminé | Risques |
|---|---|---|---|---|---|---|
| NC-1 | Créer un minimum jouable | Wizard nom, IDs générés, map, spawn, starter | T0-3 | Widget+disque+runtime start | Projet neuf jouable sans ID manuel | Trop d’implicite |
| NC-2a | Rendre Storylines autoritaires | Activation et transitions canoniques | Facts/Scenes | State machine, branches et reprise | Toute transition visible agit ou est masquée | Migration projets |
| NC-2b | Persister les effets Storylines | Effets, save/reload et migration | NC-2a | Roundtrip, restart et N-1→N | État et effets identiques après reprise | Migration saves |
| NC-3a | Fermer le cadeau | Routage party-or-box atomique | Storage | Party pleine, box pleine, rollback | Cadeau ne soft-fail plus selon la party | Capacité storage |
| NC-3b | Fermer les zones | Types `movementEffect/special/custom` | Gameplay zones | Publish + runtime par type | Type implémenté ou masqué | Compat projets |
| NC-3c1 | Masquer les blocs Cutscene inertes | Inventaire et retrait des blocs sans consumer | T0-3 | Chaque bloc encore visible a un consumer | Aucun placeholder inerte authorable | Régression projets legacy |
| NC-3c2 | Migrer Cutscene vers le canonique | Convertisseurs explicites vers Scenes/Cinematics | NC-3c1 | Fixture par bloc migré, reload et runtime | Migration déterministe ou diagnostic bloquant | Compatibilité contenu |
| NC-4 | Ajouter les templates utiles | Static, cadeau, arène, rival | T0-2, NC-2a, NC-2b | Template→reload→runtime | Quatre templates sans identifiant brut | Contenu trop prescriptif |
| NC-5 | Activer un playtest sandbox | Projet courant, save isolée, reset | Runtime host | Start/stop/reload; aucune save production touchée | Bouton Tester actif et déterministe | Isolation process/assets |
| NC-6 | Rendre la preview fidèle | Surfaces player partagées; ratio vidéo | `map_player_ui` | Goldens editor↔player portrait/paysage | Même rendu contractuel | Dépendances de packages |
| NC-7a | Définir l’état narratif canonique | Contrat Facts, variables, `GameState` et `SaveData` | NC-2a, NC-2b | Tests de mapping purs | Une source de vérité documentée | Compatibilité legacy |
| NC-7b | Fermer les bridges narratifs | Lecture/écriture runtime de chaque type canonique | NC-7a | Roundtrip via tous les bridges et restart | Aucune valeur remise à vide | Régression runtime |
| NC-7c | Migrer les saves narratives | N-1→N et refus future-version | NC-7b | Fixtures N-1, corruption et rollback | Migration atomique et diagnostiquée | Perte de progression |

### Phase 2 — Produire le package Avelune canonique

| Lot | Objectif | Périmètre | Dépendances | Tests exigés | Définition de terminé | Risques |
|---|---|---|---|---|---|---|
| PK-1 | Neutraliser le format public | `.avelunegame`, MIME/UTI, migration legacy | T0-3 | Core/editor/iOS/Android compatibility | Aucun nom public mobile « Poke » | Rupture packages existants |
| PK-2 | Publier vers Avelune | Export et import/install du même octet | PK-1 | Hash identique éditeur→Avelune | UI nommée Avelune, transaction récupérable | Transfert mobile |
| PK-3a | Authorer la fixture Golden | Projet neuf UI→aventure terminable | NC-1, NC-2a, NC-2b, NC-3a, NC-3b, NC-3c1, NC-3c2, NC-4, NC-5, NC-6, NC-7a, NC-7b, NC-7c | Tests de contrats par couche + replay éditeur | Fixture créée sans JSON manuel et versionnée | Fragilité UI |
| PK-3b | Publier et installer la Golden | Export→octets→import→installation | PK-3a, PK-1, PK-2 | Hash cross-stack, négatifs archive/version | Même paquet vérifié des deux côtés | Taille/transfert |
| PK-3c | Certifier la Golden jouée | New game→save→continue→crédits | PK-3b | Tests de contrats par couche + golden cross-stack ; reçu par SHA | Même candidat traverse toutes les couches | Durée/flakiness |

### Phase 3 — Rendre Avelune résiliente

| Lot | Objectif | Périmètre | Dépendances | Tests exigés | Définition de terminé | Risques |
|---|---|---|---|---|---|---|
| AV-1a | Câbler la réparation | Diagnostic→confirmation→repair→revalidation | PK-1 | Corruption, succès, échec et rollback | Action joueur récupérable et revalidée | Écrasement installation |
| AV-1b | Câbler la désinstallation | Transaction et nettoyage package | PK-1 | Succès, crash et relance | Jeu retiré sans état intermédiaire | Données orphelines |
| AV-1c | Appliquer la politique de saves | Choix conserver/supprimer et confirmation | AV-1b | Deux politiques, annulation et rollback | Choix explicite sans perte silencieuse | Erreur utilisateur |
| AV-2a | Définir le contrat de mise à jour | Versions, compatibilité et migrations N→N+1 | AV-1a, AV-1b, AV-1c, versioning | Matrice versions et future-version refusal | Décision de migration déterministe | Matrice versions |
| AV-2b | Exécuter la transaction de mise à jour | Staging, swap et conservation des saves | AV-2a | Succès, échec I/O et rollback | Update atomique ou invisible | Perte de données |
| AV-2c | Récupérer après interruption | Journal, reprise et nettoyage au redémarrage | AV-2b | Crash à chaque stage | Aucun état intermédiaire lancé | Complexité recovery |
| AV-3 | Porter les saves | Export/import versionné et protégé | AV-1a, AV-1b, AV-1c | Roundtrip, mauvais jeu, archive corrompue | Transfert/restauration guidés | Données personnelles |
| AV-4 | Réussir le premier contact | Démo offline et onboarding import | PK-3c | Fresh install offline | Jouer en moins de trois actions | Taille app |
| AV-5a | Certifier interactions/lifecycle | Touch, back, rotation, background/kill | Device lab | iOS+Android, deux tailles/API minimum | Aucun P0 input/lifecycle | Coût matériel |
| AV-5b | Certifier accès/média | Safe areas, VoiceOver/TalkBack, texte, codecs | Device lab | AT + portrait/paysage video sur iOS/Android | Aucun P0 access/media | Matrice longue |
| AV-6 | Outiller le support | Diagnostic exporté et redacted | AV-1a, AV-1b, AV-1c, AV-2a, AV-2b, AV-2c | Fault injection→bundle diagnostic | Reproduction sans exposer la save | Vie privée |

### Phase 4 — Prouver la production

| Lot | Objectif | Périmètre | Dépendances | Tests exigés | Définition de terminé | Risques |
|---|---|---|---|---|---|---|
| PR-1 | Unifier version et provenance | Tag, bundles, receipts, promotion mono-SHA | PK-3c | Assertions CI + hashes | Impossible d’agréger deux commits | Refonte release |
| PR-2a | Produire Android signé | Keystore, release APK et AAB | PR-1, AV-5a, AV-5b | Certificat, install, startup, taille | APK/AAB attestés du même SHA | Secrets |
| PR-2b | Valider Play internal | Upload, install et update track interne | PR-2a | Fresh install + N→N+1 sur device | Reçu Play installable et mesuré | Compte/store |
| PR-3a | Stabiliser Xcode Cloud | Flutter épinglé, analyze/tests et archive | PR-1, AV-5a, AV-5b | Gate cloud + archive signée | Archive Apple issue du même SHA | Configuration Apple |
| PR-3b | Valider TestFlight | Upload, installation et smoke installé | PR-3a | Titre→identité→jeu→reprise | Reçu TestFlight et smoke vert | Délai Apple |
| PR-4a | Livrer macOS notarized | Developer ID, notary et cold launch | PR-1, NC-5 | `codesign`, `stapler`, `spctl`, fresh VM | DMG du même SHA accepté | Secrets Apple |
| PR-4b | Livrer Windows/Linux | Packages, install et cold launch | PR-1, NC-5 | Smoke runner propre par OS | Deux artefacts attestés du même SHA | Runners |

### Phase 5 — Approfondir le RPG après le MVP

| Lot | Objectif | Périmètre | Dépendances | Tests exigés | Définition de terminé | Risques |
|---|---|---|---|---|---|---|
| RPG-1 | Enrichir le battle utile | Objets, held equip, weather/terrain/hazards authoring | PK-3c | Engine+runtime+UI par effet | Chaque effet est authorable et persistant | Explosion combinatoire |
| RPG-2 | Étendre le monde | Field ability par lot après Surf | NC-1, NC-2a, NC-2b | Traversal, save/reload, map invalide | Une capacité complète par lot | Complexité maps |
| RPG-3 | Fournir des arcs | Arène, rival, postgame léger | NC-2a, NC-2b, NC-4 | Projet template terminable | Personnalisable sans script brut | Contenu trop rigide |
| RPG-4 | Réexaminer les différés | Doubles, gimmicks, breeding, online, concours | Gates stables | Plan/POC séparé par fonctionnalité | Aucun mégalot | Dispersion |

**Ordre de départ recommandé : T0-1a à T0-1d en petits lots indépendants, puis
T0-2 et T0-3.** Cette séquence répare d’abord les indicateurs, supprime le
faux-complet le plus dangereux et rend enfin l’export digne du mot
« certifié ».

---

## 21. Commandes exécutées et résultats

### 21.1 État, inventaire et dashboard

| Commande | Résultat exact |
|---|---|
| `git status --short --untracked-files=all` | 2 fichiers suivis modifiés et 2 fichiers SwiftPM non suivis préexistants ; rapport absent au départ |
| `git rev-parse --abbrev-ref HEAD && git rev-parse HEAD` | `main`; `a3d741818c1961ac2f653da235bb30c20df75b00` |
| inventaire `rg --files` + comptage des fichiers/lignes Dart par unité | Comptages §4.2 ; aucun write |
| `cd packages/map_core && dart run tool/generate_gameplay_roadmap_dashboard.dart --check ../..` | exit 0 ; `DONE 40`, `PARTIAL 12`, `BLOCKED 0`, `TODO 41`, `DEFERRED 21` |

### 21.2 Tests Dart/Flutter — commandes littérales conservées

| Commande ou sélection exacte | Résultat |
|---|---|
| `cd packages/map_player_ui && flutter test --no-pub -r expanded` | exit 0 ; `+102` |
| `cd packages/map_distribution && dart test -r expanded` | exit 0 ; `+81` |
| `cd examples/playable_runtime_host && flutter test --machine test/phase_7a_installed_golden_journey_test.dart test/selbrume_player_journey_e2e_test.dart test/phase_a_golden_slice_launch_test.dart test/in_game_menu_test.dart test/in_game_shop_page_test.dart test/in_game_heal_flow_test.dart test/in_game_pc_page_test.dart` | exit 0 ; `28/28` ; 328,491 s |
| `cd packages/map_editor && flutter test test/scene_action_builder_test.dart test/event_builder_v2_condition_expression_test.dart test/narrative_template_catalog_test.dart test/personalization/phase_6_personalization_studio_export_e2e_test.dart test/game_export/game_package_export_service_test.dart` | exit 0 ; `+29` |
| `cd packages/map_core && dart test test/narrative_command_contract_parity_test.dart test/project_presentation_profile_test.dart test/scene_runtime_dry_run_preview_test.dart` | exit 0 ; `+19` |
| `cd packages/map_runtime && flutter test test/narrative_command_runtime_parity_test.dart test/narrative_command_save_load_integration_test.dart test/cinematic_runtime_playback_controller_test.dart test/scene_consequence_runtime_writer_test.dart` | exit 0 ; `+48` |
| `cd tool/pokemap_product_certification && dart test` | exit 65 : package dépend de `flutter_test`; runner incorrect, pas un défaut produit |
| `cd tool/pokemap_product_certification && flutter test --no-pub -r expanded` | exit 0 ; `+9` |

La commande éditeur 225/225 était exactement :

```bash
cd packages/map_editor
flutter test --machine \
  test/event_builder_v2_condition_expression_test.dart \
  test/event_builder_v2_simulation_test.dart \
  test/event_builder_v2_template_sheet_test.dart \
  test/event_builder_workspace_test.dart \
  test/ui/canvas/event_builder_v2_creation_flow_test.dart \
  test/ui/canvas/event_builder_v2_validation_navigation_test.dart \
  test/scene_action_builder_test.dart \
  test/personalization/personalization_studio_workspace_test.dart \
  test/personalization/personalization_publish_readiness_test.dart \
  test/personalization/personalization_readiness_accessibility_test.dart \
  test/personalization/phase_6_personalization_negative_gate_test.dart \
  test/personalization/phase_6_personalization_studio_export_e2e_test.dart \
  test/personalization/phase_6_personalization_studio_restart_e2e_test.dart \
  test/game_export/game_package_export_controller_test.dart \
  test/game_export/game_package_export_service_test.dart \
  test/game_export/runtime_project_projection_builder_test.dart \
  test/game_export/generic_release_gate_test.dart \
  test/game_export/hub_install_request_publisher_test.dart
```

Résultat : exit 0, 225/225, 43,813 s.

### 21.2 bis Runs complémentaires à trace argv partielle

Cinq exécutions parentes ont produit des résultats utiles, mais leur ligne
argv complète n’a pas été conservée dans un artefact durable. Elles ne sont
donc pas présentées comme commandes littérales :

| Package/périmètre capturé | Résultat exact conservé |
|---|---|
| `map_core` dashboard/catalogue/parité/authoring/Facts/Scenes/Storylines/conditions/release gate | exit 0 ; `+58` |
| `map_gameplay` new game/storage/capture/progression/move learning/evolution/TM/heal/shop/conditions/outbox | exit 0 ; `+111` |
| `map_battle` core/capture/switch/items/status/weather/terrain/hazards/PP/parité | exit 0 ; `+117` |
| `map_runtime` new game/starter/save/capture/static/items/held/TM/progression/narrative/finish/crédits | exit 0 ; `+95` |
| host phase A/Golden/Selbrume/menus/PC/shop/heal/Pokédex/touch/gamepad/campagne | exit 0 ; `+40` ; 270,142 s |

Cette perte de l’argv brut est une limite de traçabilité du rapport. Les
preuves principales reposent sur les commandes littérales ci-dessus et sur
les tests nommés dans E-CORE-NARR, E-STATIC, E-HOST-JOURNEY et E-BATTLE. Les
suites intégrales ont ensuite été lancées lors de la vérification finale et
sont consignées séparément ci-dessous.

### 21.2 ter Suites intégrales de vérification finale

Les commandes volumineuses ont utilisé `set -o pipefail` et un `tail` de sortie
pour préserver le code de sortie tout en bornant le journal affiché.

| Répertoire | Commande de test | Résultat frais |
|---|---|---|
| `packages/map_core` | `dart test -r expanded` | exit 0 ; `02:06 +4502: All tests passed!` |
| `packages/map_gameplay` | `dart test -r expanded` | exit 0 ; `00:03 +428: All tests passed!` |
| `packages/map_battle` | `dart test -r expanded` | exit 0 ; `00:21 +1764: All tests passed!` |
| `packages/map_runtime` | `flutter test --no-pub -r expanded` | exit 1 ; `03:17 +2240 ~1 -1` |
| `packages/map_editor` | `flutter test --no-pub --timeout 2m -r expanded` | exit 1 ; `06:31 +4265 -1` |
| `examples/playable_runtime_host` | `flutter test --no-pub --timeout 2m -r expanded` | exit 0 ; `07:32 +257 ~2: All tests passed!` |

L’unique échec runtime est reproductible :

```bash
cd packages/map_runtime
flutter test --no-pub -r expanded \
  test/le_train_m00_external_runtime_smoke_test.dart
```

Résultat : exit 1, `Bad state: No element` à
`le_train_m00_external_runtime_smoke_test.dart:55`. Le test lit le projet
machine-spécifique
`/Users/karim/Desktop/pokeMap Project/le_train_de_17h42`, puis cherche avec
`singleWhere` une couche `l_structure` que la map externe actuelle ne possède
plus. Il contient aussi une écriture de preview vers ce projet après ses
assertions ; l’échec est survenu avant cette écriture. Ce smoke doit utiliser
une fixture versionnée ou sortir de la suite hermétique.

L’unique échec éditeur est un budget performance en exécution concurrente :

```text
narrative_large_project_workspace_performance_test.dart:
Storyline graph projects 1000 Steps within budget
```

Rejoué seul :

```bash
cd packages/map_editor
flutter test --no-pub --timeout 2m -r expanded \
  test/narrative_large_project_workspace_performance_test.dart \
  --plain-name 'Storyline graph projects 1000 Steps within budget'
```

Résultat : exit 0, `+1`, `p50_us=3267`, `p95_us=7644`,
`budget_p95_us=20000`. La fonction respecte le budget isolément ; la gate
globale reste rouge et la mesure doit vivre dans une lane séquentielle dédiée.

### 21.3 Anomalie Avelune save

| Commande | Résultat exact |
|---|---|
| `cd apps/pokemap_hub && flutter test --machine` | exit 1 ; 189 succès, 1 erreur ; 59,759 s ; timeout 30 s du crash-stage |
| `flutter test test/saves/hub_save_store_atomic_test.dart -r expanded` | exit 1 ; 6 succès, 1 timeout à 30 s |
| `cd apps/pokemap_hub && flutter test test/saves/hub_save_store_atomic_test.dart -r expanded --timeout 2m` | exit 0 ; 7/7 ; durée précise non conservée, observation ~31 s |
| commande littérale ci-dessous, 51 fichiers hors crash-stage | exit 0 ; 183/183 ; 50,649 s |
| `cd apps/pokemap_hub && flutter test --no-pub --timeout 2m -r expanded` | exit 0 ; `+190` |

```bash
cd apps/pokemap_hub
flutter test --machine \
  $(rg --files test -g '*_test.dart' |
    sort |
    rg -v '^test/saves/hub_save_store_atomic_test\.dart$')
```

### 21.4 Analyses statiques

| Commande | Résultat |
|---|---|
| `cd packages/map_core && dart analyze` | exit 0 ; `No issues found!` |
| `cd packages/map_gameplay && dart analyze` | exit 0 ; `No issues found!` |
| `cd packages/map_battle && dart analyze` | exit 0 ; `No issues found!` |
| `cd packages/map_distribution && dart analyze` | exit 0 ; `No issues found!` |
| `cd packages/map_runtime && flutter analyze --no-pub` | exit 0 ; `No issues found!` ; 5,7 s |
| `cd packages/map_player_ui && flutter analyze --no-pub` | exit 0 ; `No issues found!` ; 4,7 s |
| `cd apps/pokemap_hub && flutter analyze --no-pub` | exit 0 ; `No issues found!` ; 5,6 s lors de la passe Tests |
| `cd examples/playable_runtime_host && flutter analyze --no-pub` | exit 0 ; `No issues found!` ; 12,2 s lors de la passe Tests |
| `cd packages/map_editor && flutter analyze --no-pub` | exit 0 ; `No issues found!` ; 7,4 s lors de la passe Tests |

### 21.5 Lancements et intégration

| Commande | Résultat |
|---|---|
| `cd apps/pokemap_hub && flutter test integration_test/runtime_owned_player_flow_test.dart` sur simulateur iOS | build Xcode réussi en 51,3 s ; exit 1 ; atteint titre puis dialogue « Votre identité », n’atteint pas `playing` |
| `cd packages/map_editor && flutter run -t dev/marionette_main.dart -d macos --debug --no-pub --dart-define=MARIONETTE_PROJECT_PATH=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/pokemap-ultra-audit-20260728.xoXKKT` | seconde tentative : projet actif, Studio/Branding confirmés ; overflows 29/26 px ; session limitée puis teardown |
| `find selbrume -type f -print0 \| LC_ALL=C sort -z \| xargs -0 shasum -a 256 \| shasum -a 256` avant et après l’inspection | même résultat : `7a79fd23b07bbc9cc8451860412edb7e3a0364450f29d23594b0350f1fb2c5de  -`; 11 259 fichiers |

Aucune capture Avelune n’a été retenue : les trois PNG diagnostics montraient
l’accueil iOS ou un runner blanc. Les captures Marionette utiles étaient
inline, sans chemin durable. Aucune image rejetée n’est utilisée comme preuve
produit.

### 21.6 Builds et artefacts

| Commande | Résultat |
|---|---|
| `flutter build ios --simulator --debug --no-pub` dans Avelune | exit 0 ; 50,77 s ; app 230 135 195 octets, ad hoc |
| `flutter build ios --release --no-codesign --no-pub` | exit 0 ; 67,13 s ; app 46 303 072 octets, non signée |
| `flutter build macos --release --no-pub` dans le Hub | exit 0 ; 72,25 s ; 87 441 441 octets ; Gatekeeper 3 |
| `flutter build macos --release --no-pub` dans l’éditeur | exit 0 ; 55,19 s ; 44 452 425 octets ; arm64/ad hoc |
| `tool/release/package_macos_preview.sh --app "build/macos/Build/Products/Release/PokeMap.app" --dmg build/release/PokeMap-macos-local-validation.dmg` | exit 0 ; 6,56 s ; 20 525 866 octets ; `hdiutil verify` 0 ; Gatekeeper 3 |
| commandes `gh` littérales ci-dessous et téléchargement/hash read-only | APK HEAD confirmé ; desktops issus de `28c03879`; run desktop HEAD annulé |
| `stat -f '%N|%z'` et `shasum -a 256` sur les deux DMG Hub historiques | `PokeMap-Hub-notarized.dmg` : 49 840 918 octets, `b8ca44a4973aebbf05380257b862da2c7f4c0249f4a9c6cd368909ce5610a6db`; `PokeMap-Hub-52f43e2d.dmg` : 49 116 221 octets, `b67d234b7cf8917bd01a31e5a5d5d4f800446df07b89f876b782dc7433e303f4` |
| boucle `codesign --verify --deep --strict`, `codesign -dv`, `xcrun stapler validate`, `spctl --assess --type open` sur ces deux DMG | exits 0 ; Developer ID `Yoahn Linard (NLNMNV3B3S)` ; ticket staplé valide ; Gatekeeper `accepted`, source `Notarized Developer ID` |
| `jq '{id,status,message,issues}'` sur les quatre reçus sous `build/phase-7-distribution/52f43e2d/macos-notary` | app `53824f75-7d75-4616-871c-65d8cfd029be` et DMG `79369f16-7e94-4c23-9720-7dc36c8fb5ef` : `Accepted`, `Processing complete`; logs app/DMG `Accepted` |

Android local n’a pas été construit : `flutter doctor -v` indique
`Unable to locate Android SDK`. Aucune clé de production Apple/Android n’a été
utilisée.

Les deux DMG Hub signés sont des artefacts **historiques et ignorés par Git**,
pas des builds du HEAD audité. Leurs chemins exacts sont :

```text
apps/pokemap_hub/build/macos/Build/Products/Release/PokeMap-Hub-notarized.dmg
apps/pokemap_hub/build/phase-7-distribution/52f43e2d/macos-notary/PokeMap-Hub-52f43e2d.dmg
apps/pokemap_hub/build/phase-7-distribution/52f43e2d/macos-notary/notarization-result.json
apps/pokemap_hub/build/phase-7-distribution/52f43e2d/macos-notary/logs/app-notary-result.json
apps/pokemap_hub/build/phase-7-distribution/52f43e2d/macos-notary/logs/app-notary-log.json
apps/pokemap_hub/build/phase-7-distribution/52f43e2d/macos-notary/logs/dmg-notary-log.json
```

Vérifications de signature/architecture exécutées littéralement :

```bash
codesign --verify --deep --strict \
  packages/map_editor/build/macos/Build/Products/Release/PokeMap.app
spctl --assess --type execute -vv \
  packages/map_editor/build/macos/Build/Products/Release/PokeMap.app
xcrun stapler validate \
  packages/map_editor/build/macos/Build/Products/Release/PokeMap.app

codesign --verify --deep --strict \
  "apps/pokemap_hub/build/macos/Build/Products/Release/PokeMap Hub.app"
spctl --assess --type execute -vv \
  "apps/pokemap_hub/build/macos/Build/Products/Release/PokeMap Hub.app"
xcrun stapler validate \
  "apps/pokemap_hub/build/macos/Build/Products/Release/PokeMap Hub.app"

codesign --verify --deep --strict \
  apps/pokemap_hub/build/ios/iphonesimulator/Runner.app
codesign --verify apps/pokemap_hub/build/ios/iphoneos/Runner.app
hdiutil verify \
  packages/map_editor/build/release/PokeMap-macos-local-validation.dmg
codesign --verify \
  packages/map_editor/build/release/PokeMap-macos-local-validation.dmg
spctl --assess --type open --context context:primary-signature -vv \
  packages/map_editor/build/release/PokeMap-macos-local-validation.dmg
xcrun stapler validate \
  packages/map_editor/build/release/PokeMap-macos-local-validation.dmg
lipo -archs \
  packages/map_editor/build/macos/Build/Products/Release/PokeMap.app/Contents/MacOS/PokeMap
lipo -archs \
  "apps/pokemap_hub/build/macos/Build/Products/Release/PokeMap Hub.app/Contents/MacOS/PokeMap Hub"
security find-identity -v -p codesigning

for f in \
  apps/pokemap_hub/build/macos/Build/Products/Release/PokeMap-Hub-notarized.dmg \
  apps/pokemap_hub/build/phase-7-distribution/52f43e2d/macos-notary/PokeMap-Hub-52f43e2d.dmg
do
  stat -f '%N|%z' "$f"
  shasum -a 256 "$f"
  codesign --verify --deep --strict --verbose=2 "$f"
  codesign -dv --verbose=4 "$f"
  xcrun stapler validate "$f"
  spctl --assess --type open --context context:primary-signature -vv "$f"
done

for f in \
  apps/pokemap_hub/build/phase-7-distribution/52f43e2d/macos-notary/notarization-result.json \
  apps/pokemap_hub/build/phase-7-distribution/52f43e2d/macos-notary/logs/app-notary-result.json \
  apps/pokemap_hub/build/phase-7-distribution/52f43e2d/macos-notary/logs/app-notary-log.json \
  apps/pokemap_hub/build/phase-7-distribution/52f43e2d/macos-notary/logs/dmg-notary-log.json
do
  jq '{id,status,message,issues}' "$f"
done
```

Résultats : apps macOS `codesign=0`, `spctl=3`, `stapler=65`; iOS simulator
`codesign=0`; iOS device `codesign=1`; DMG `hdiutil=0`, `codesign=1`,
`spctl=3`, `stapler=65`; architectures Editor `arm64`, Hub
`x86_64 arm64`; cinq identités de signature valides visibles.

Métadonnées GitHub recapturées :

```bash
gh run view 30303222458 --repo yoahnl/pokemap \
  --json databaseId,headSha,status,conclusion,createdAt,updatedAt
gh run view 30302704506 --repo yoahnl/pokemap \
  --json databaseId,headSha,status,conclusion
gh run view 30303220984 --repo yoahnl/pokemap \
  --json databaseId,headSha,status,conclusion
gh release view preview-2026.07.27 --repo yoahnl/pokemap \
  --json tagName,targetCommitish,publishedAt,isPrerelease,assets
```

Résultats : run Android `success` sur `a3d741818…`, run desktop publié
`success` sur `28c03879…`, run desktop HEAD `cancelled`, prerelease
`preview-2026.07.27` ciblant `a3d741818…` avec quatre assets. Les archives ont
été téléchargées avec `gh release download`, puis comparées par
`shasum -a 256`; les tailles et quatre digests sont reproduits au §12.6.

### 21.7 Contrôles finaux d’intégrité du rapport et de provenance

Commandes finales :

```bash
git status --short --untracked-files=all
git diff --name-only
git diff --check
git diff --no-index --check /dev/null \
  reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
rg -c '^## [0-9]+' \
  reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
rg -c '^```' \
  reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
find selbrume -type f -print0 \
  | LC_ALL=C sort -z \
  | xargs -0 shasum -a 256 \
  | shasum -a 256
```

Un contrôle `awk` limité aux sous-sections 13.1–13.4 a également compté les
lignes de classification, leurs séparateurs et leur troisième champ après
normalisation des backticks.

Résultats exacts :

- matrice : `154` lignes, `0` ligne avec un nombre de séparateurs différent
  de 12, `0` statut hors des six valeurs autorisées ;
- preuves : `0` cellule `COMPLETE`/P0/P1 sans chemin backtické ou référence
  E-* ; `0` référence E-* non définie ;
- contradictions : `26` IDs uniques, aucun doublon ; roadmap : `47` lots
  uniques, aucune dépendance vers un ID d’epic remplacé ;
- tableau rapide : `15` lignes ;
- `24` titres numérotés, dont le complément `20 bis`, et `48` fences Markdown,
  donc un nombre pair ;
- `git diff --check` : exit `0` ;
- `git diff --no-index --check` : exit `1` attendu parce que le rapport
  non suivi diffère de `/dev/null`, avec `0` octet de diagnostic d’espace ;
- `git diff --name-only` ne retourne que les deux fichiers suivis déjà
  modifiés avant l’audit ;
- source Selbrume : `11 259` fichiers et hash agrégé inchangé
  `7a79fd23b07bbc9cc8451860412edb7e3a0364450f29d23594b0350f1fb2c5de`.

---

## 22. État Git final et fichiers modifiés

### 22.1 Fichiers appartenant déjà à l’utilisateur

Ils sont restés présents et n’ont pas été restaurés, nettoyés, indexés ni
committés :

```text
 M reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json
 M tool/pokemap_product_certification/pubspec.lock
?? packages/gamepads_darwin/macos/gamepads_darwin/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/gamepads_ios/ios/gamepads_ios/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
```

### 22.2 Fichier créé par l’audit

```text
?? reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
```

Il s’agit du seul fichier du dépôt créé **par cet audit**. La zone modifiée est
l’intégralité de ce nouveau document ; aucun fichier source, test, fixture,
workflow, roadmap ou reçu n’a été édité par cette tâche. Le contenu complet du
fichier créé est le présent document lui-même ; le recopier à l’intérieur
créerait une récursion sans fin.

### 22.3 Changements concurrents apparus pendant l’audit

Quatre PNG et deux rapports Markdown non suivis, absents de l’état Git initial,
sont apparus pendant la critique :

```text
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/01-empty-world-map-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/02-port-open-overview-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/03-inspector-scroll-layer-context-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/04-layers-expanded-truncated-actions-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md
?? reports/gameplay/avelune_pokemap_product_roadmap_2026-07-28.md
```

Ils proviennent d’un processus/tâche concurrent utilisant une autre copie de
projet, n’ont été ni créés, ni lus comme preuve, ni modifiés, ni supprimés par
le présent audit. Ils sont préservés et explicitement exclus de sa provenance.

### 22.4 État Git final recapturé

```text
 M reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json
 M tool/pokemap_product_certification/pubspec.lock
?? packages/gamepads_darwin/macos/gamepads_darwin/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/gamepads_ios/ios/gamepads_ios/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/01-empty-world-map-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/02-port-open-overview-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/03-inspector-scroll-layer-context-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/04-layers-expanded-truncated-actions-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md
?? reports/gameplay/avelune_pokemap_product_roadmap_2026-07-28.md
```

Les builds sont sous des répertoires ignorés. Aucun `git add`, commit, tag,
push, release, checkout, stash ou nettoyage Git n’a été effectué.

La copie Selbrume jetable, les téléchargements de validation et les captures
rejetées ont été déplacés dans la Corbeille et restent récupérables. La source
`selbrume` garde le même hash agrégé avant/après.

---

## 23. Auto-critique et limites de l’audit

### 23.1 Ce que l’audit prouve bien

- présence réelle des packages, frontières, modèles et surfaces ;
- parité forte de nombreuses commandes narratives et mécaniques ;
- exécution fraîche de parcours ciblés gameplay/battle/runtime/editor ;
- compilation fraîche iOS/macOS ;
- échec reproductible du smoke iOS et du timeout Hub standard ;
- contradictions précises builder/adapters/export/composition/release ;
- provenance et hashes des artefacts preview inspectés.

### 23.2 Ce qu’il ne prouve pas

- aucune aventure n’a été authorée manuellement de zéro jusqu’à la fin pendant
  cet audit ;
- aucune session humaine complète Avelune n’a franchi import, identité,
  gameplay, save, reprise et crédits ;
- aucun appareil Android n’était disponible ;
- aucun run Xcode Cloud/TestFlight, Play internal, Developer ID/notarisation
  du HEAD n’a été obtenu ;
- les suites intégrales ont été exécutées, mais `map_runtime` et `map_editor`
  restent rouges chacune sur un cas précis ; elles ne sont pas globalement
  vertes malgré les reproductions ciblées ;
- aucune mesure de couverture, RAM, FPS, batterie ou taille installée release
  n’a été inventée ;
- les screenshots rejetés ne valent aucune preuve visuelle ;
- le working tree était sale et les résultats décrivent précisément cet état,
  pas un checkout propre.

### 23.3 Auto-critique

Le risque principal de cet audit est l’asymétrie de preuve : le dépôt possède
beaucoup de tests et de documents, ce qui peut pousser à surclasser un sous-
système. La passe de vérité de câblage a justement corrigé ce biais pour
`staticEncounter`, la maintenance Avelune et la certification d’export.

À l’inverse, classer une fonction `MISSING` à partir d’un ancien rapport aurait
été tout aussi faux. Les Facts, conditions, commandes, soins, fin/crédits,
PC/boxes et de nombreuses mécaniques existent. Le rapport préfère donc
`PARTIAL`, `UNPROVEN` ou `CONTRADICTORY` lorsque les couches se contredisent.

Les estimations d’effort sont des tailles relatives, pas des promesses
calendaires. Elles supposent une petite équipe familière du dépôt et ne
comprennent ni validation store ni création de contenu artistique.

### 23.4 Verdict du sub-agent Critique finale et corrections

Verdict indépendant reçu avant correction :

```text
CONTRADICTORY — CORRECTIONS REQUISES AVANT LIVRAISON
```

Le reviewer a confirmé les 23 sections, les 11 champs de chaque ligne de
matrice, l’usage exclusif des six statuts et l’absence de pourcentages inventés.
Il a demandé des corrections P0/P1, intégrées comme suit :

- état Git final recapturé avec les six artefacts concurrents (quatre PNG et
  deux rapports), explicitement
  exclus de la provenance de cet audit ;
- verdict de critique ajouté et passe Implémentation read-only expliquée ;
- commandes éditeur/host/Hub/analyzers/build/signature/GitHub rendues
  littérales ; cinq anciennes sélections dont l’argv brut n’était plus
  disponible sont isolées comme limite au lieu d’être présentées comme
  exactes ;
- deux tentatives desktop distinguées et preuve visuelle limitée à
  projet/Studio/Branding réellement observés ;
- « produit cassé » remplacé par « gate installée rouge, produit non
  certifié » ;
- nom/bundle Avelune séparés de l’identité publique bout en bout ;
- conditions legacy, progression narrative globale, templates, trainers,
  static et cadeaux reclassés selon la chaîne réelle ;
- « six blockers » corrigé en huit ;
- lots gate mobile/save, gift/zones/Cutscene et mobile quality scindés ;
- lot NC-7 ajouté pour Facts/variables/save avant le Golden Journey ;
- source, destination, commande et hash Selbrume documentés ;
- crosswalk FG proposé ajouté sans modifier la roadmap ;
- registre E-* et recherches `MISSING` reproductibles ajoutés.

Limite résiduelle assumée : l’argv complet des cinq runs complémentaires
`+58/+111/+117/+95/+40` n’a pas été conservé. Le rapport l’indique
explicitement et ne les utilise pas comme unique preuve. La critique elle-même
n’a modifié aucun fichier et n’a relancé aucun test.

#### Critique finale 2 — verdict ultime

La seconde contre-lecture a d’abord rendu `NON PRÊT` sur trois défauts
documentaires : deux preuves P0 trop génériques, des dépendances de roadmap
pointant vers des IDs scindés, et trois lots encore trop larges. Les corrections
ont ajouté les chemins/références E-* exacts pour l’import et les cartes, scindé
Cutscene legacy en `NC-3c1/c2`, l’état narratif en `NC-7a/b/c` et la maintenance
de bibliothèque en `AV-1a/b/c`, puis développé toutes leurs dépendances.

L’ultime contrôle read-only indépendant conclut :

**`PRÊT POUR LIVRAISON DU RAPPORT`** — ce verdict porte sur la cohérence de
l’audit, pas sur la readiness production d’Avelune/PokeMap.

Le reviewer confirme `154` lignes de matrice à `11` champs, uniquement les six
statuts autorisés, aucune preuve critique générique, `26` IDs de contradiction
uniques, `47` lots sans doublon ni dépendance inexistante, un état Git conforme,
`24` titres numérotés et `48` fences Markdown paires. Il n’a détecté aucun autre
blocker documentaire et n’a modifié aucun fichier.

### 23.5 Décision demandée

Valider cette roadmap signifie commencer par **T0-1a à T0-1d** en petits lots
indépendants, puis **T0-2** et **T0-3**. Aucun travail d’implémentation n’a
commencé. La décision attendue est donc : valider la roadmap proposée ou
choisir explicitement une autre première phase.

---
