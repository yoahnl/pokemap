# Map Editor — contrat de validation et de performance

**Date :** 2026-08-15

**Statut :** proposition normative à relire avant implémentation

**Lot :** `BETA-PERF-011`

**Audit source :** `BETA-PERF-010`

**Baseline auditée :** `c3ad77ee0442e4482b5601367b69c3bceb039248`

## 1. Objet

Ce contrat empêche qu'un événement interactif déclenche en cascade des validations, projections,
diffs, sérialisations ou écritures dimensionnés par la map, le projet ou l'historique.

Il s'applique au Map Editor, notamment à World Map, Smart Tiles, masks, Facts, Branding,
Cinematics, à la persistence et aux transports d'authoring. Il ne remplace pas les invariants de
cohérence : il définit **où**, **quand** et **combien de fois** ils peuvent être vérifiés.

Le pipeline cible des mutations interactives est :

```text
événement interactif
    → état transitoire local
    → delta explicite
    → validation incrémentale
    → commit documentaire explicite
    → persistence canonique asynchrone
```

Pan et zoom peuvent s'arrêter à l'état transitoire. Open, import et recovery entrent directement
dans une frontière canonique : ce pipeline n'est pas un rituel universel imposé à toute action.

La règle centrale est la suivante :

> Une interaction locale ne doit déclencher qu'un travail local, borné et réversible. Un travail
> global n'est autorisé qu'à une frontière explicite de commit, de persistence, d'ouverture,
> d'import, d'export ou de certification, et seulement selon les règles et budgets L1 à L3. Le
> résultat d'une vérification globale reste réutilisable tant que sa `contentRevision` et sa
> `policyRevision` d'entrée n'ont pas changé.

## 2. Pourquoi ce contrat existe

L'audit `BETA-PERF-010` a confirmé un pattern transverse :

```text
événement local ou ticker haute fréquence
    → publication globale | setState racine | Future recréé | apply/write
    → travail dimensionné map | projet | catalogue | historique
    → travail synchrone UI ou IO répété
    → allocations et frame ratée
```

Le défaut n'est donc pas « trop de validation » en général. Le défaut est une validation exécutée
au mauvais niveau, plusieurs fois pour la même `contentRevision`/`policyRevision`, ou depuis une
frontière trop fréquente.

Ce contrat conserve les protections utiles : validation canonique, atomicité, idempotence,
recovery, contrôles anti-race et rejet des entrées non fiables. Il interdit leur répétition sans
propriétaire ni justification.

## 3. Vocabulaire normatif

Les termes **DOIT**, **NE DOIT PAS**, **DEVRAIT** et **PEUT** sont normatifs.

| Terme | Définition |
|---|---|
| `contentRevision` | Empreinte du contenu logique et de toutes ses dépendances sémantiques ; clé des projections et validations. |
| `storageRevision` | Jeton frais de l'état durable d'une ressource, utilisable pour CAS uniquement dans la portée qui garantit sa fraîcheur. |
| `sessionGeneration` | Compteur opaque monotone d'une session/cache, valable uniquement dans ce process et cette session. |
| Delta | Ensemble explicite des cellules, chunks, ressources ou propriétés touchés. |
| Invariant | Propriété de cohérence dont un composant identifié est propriétaire. |
| Validation complète | Vérification dont le coût dépend de toute une map, d'un projet, d'un catalogue ou d'un historique. |
| Validation incrémentale | Vérification bornée par le delta et ses dépendances directes. |
| Frontière transitoire | Pointer move, hover, pan, zoom, ticker, drag update, build ou paint. |
| Frontière canonique | Commit, save, apply, import, export, open, recovery ou certification. |
| Résultat validé | Reçu immuable d'une vérification globale/coûteuse contenant portée, `contentRevision`, `policyRevision`, propriétaire, provenance et erreurs. |

Les préconditions locales pures et `O(1)` — bounds check, null check, type check ou validation de
forme immédiate — ne nécessitent ni registry, ni reçu, ni télémétrie dédiée. Le contrat ne doit pas
créer un contrôleur chargé de vérifier que les contrôleurs ne vérifient pas trop.

Ces trois identités ne sont pas interchangeables. Un reçu métier est indexé par
`contentRevision`, dépendances et policy ; save/apply réatteste `storageRevision` sous CAS ou
verrou ; `sessionGeneration` ne franchit aucune frontière de confiance et ne prouve jamais un
contenu durable.

Produire `contentRevision` en L0/L1 DOIT être delta-bounded, incrémental ou consommer une empreinte
déjà portée par l'artefact. Un hash/toJson whole-document n'est autorisé qu'en L2/L3, hors isolate
UI. `sessionGeneration` ne peut jamais être renommée ou emballée pour servir de
`contentRevision`.

## 4. Les quatre niveaux d'exécution

### L0 — Interaction transitoire

Déclencheurs :

- `pointerMove`, hover, pan, zoom ;
- tick d'animation ou playback ;
- delta intermédiaire de drag ;
- `build`, layout, paint et préparation de frame.

Travail autorisé :

- lecture d'un état local déjà prêt ;
- calcul proportionnel au delta ou aux éléments réellement visibles ;
- mise à jour réversible d'un buffer sparse ;
- invalidation ou repaint d'un sous-arbre local ;
- lookup dans un index préparé pour la `contentRevision` courante.

Travail interdit :

- validation complète d'une map ou d'un projet ;
- scan complet ou non borné proportionnel à une map, un manifeste, un catalogue ou l'historique ;
- diff structurel complet ou égalité profonde utilisée comme garde d'événement ;
- lecture ou écriture filesystem ;
- encodage ou décodage JSON/base64 ;
- snapshot, plan, apply, journal ou checkpoint ;
- publication du document complet pour un viewport, un hover ou un ticker ;
- création d'un nouveau `Future` d'IO depuis `build` ;
- reconstruction d'un index stable dont la `contentRevision` d'entrée n'a pas changé.

### L1 — Commit local

Déclencheurs : fin de stroke, `pointerUp`, fin de drag, confirmation d'une édition locale.

Règles :

- le delta, `ChangeSet` ou commande typée connu à la fin de l'interaction DOIT être réutilisé quand
  la mutation en produit un ;
- une validation incrémentale n'est utilisée que si son équivalence avec l'invariant complet est
  démontrée ; sinon L1 consomme un index préparé fiable ou reporte l'invariant requis à L2 ;
- dirty state, historique et undo/redo DEVRAIENT être produits depuis ce même changement ;
- un scan global servant à redécouvrir le delta déjà connu est interdit ;
- si le commit dépasse le budget d'une frame, il DOIT devenir asynchrone avec un feedback
  explicite ; les interactions conflictuelles sur le même document sont sérialisées, les autres ne
  doivent pas être bloquées sans nécessité ;
- retourner un `Future` ne suffit pas : le travail lourd est partitionné ou exécuté hors de
  l'isolate UI ; il capture ses `contentRevision` et `sessionGeneration` de base et ne publie que si
  elles restent applicables, sinon il est rejeté, replanifié ou annulé selon une politique explicite ;
- aucune persistence implicite n'est déclenchée par chaque delta intermédiaire.

### L2 — Opération canonique durable

Déclencheurs : open, save, publication authoring, apply, import, recovery et opération atomique.

Règles :

- chaque opération déclare ses invariants requis et DOIT les exécuter ou consommer leurs reçus
  encore fiables ;
- toute validation complète requise DOIT avoir un propriétaire unique et produire un résultat
  identifié par `contentRevision` et `policyRevision` ;
- snapshot, résultat de validation, plan et reçu d'apply restent des artefacts distincts ; chacun
  DOIT réutiliser les dépendances compatibles déjà produites ;
- la construction et l'encodage whole-document NE DOIVENT PAS bloquer l'isolate UI ;
- les mutations concurrentes d'une même ressource DOIVENT être protégées soit par un CAS atomique
  sur `storageRevision`, soit par un verrou exclusif couvrant sans interruption lecture de
  `storageRevision`, comparaison et publication ; une comparaison pré-write suivie d'une
  publication hors de cette section critique ne protège pas contre TOCTOU ;
- la sérialisation ne doit être réalisée qu'une fois par payload effectivement écrit, sauf
  vérification supplémentaire exigée par une frontière de confiance, TOCTOU ou recovery ;
- un `toJson` complet utilisé uniquement pour décider s'il faut offloader est interdit.

### L3 — Audit global et certification

Déclencheurs opt-in : preflight global, export lorsque son contrat l'exige, diagnostic, release et
certification. Une ouverture normale ne lance jamais silencieusement une certification globale.

Règles :

- les scans whole-project sont autorisés et mesurés ;
- ils ne doivent jamais être atteignables depuis L0 ;
- leur résultat DOIT être réutilisé par `contentRevision` et `policyRevision` tant que le contenu et
  la politique de validation n'ont pas changé ;
- une gate de readiness doit mesurer le shell réel et les frames présentées, pas seulement un
  handler ou un widget isolé.

## 5. Un invariant, un propriétaire, un résultat

Cette section s'applique aux validations ou projections qui sont complètes/globales, font de
l'IO/codec, sont récurrentes et non triviales, ou dépassent un seuil mesuré versionné. Le seul fait
d'être appelé depuis L0/L1 n'impose ni registry ni reçu. Les préconditions et projections locales
pures `O(1)` gardent de simples fonctions et tests.

Chaque invariant dans ce périmètre DOIT déclarer :

| Champ | Exigence |
|---|---|
| Propriétaire | Package, service ou validateur qui tranche l'invariant. |
| Entrées | Révisions et politiques exactes consommées. |
| Portée | Delta, map, ressource, catalogue ou projet. |
| Déclencheurs | Niveaux L1, L2 ou L3 autorisés. |
| Complexité | Ordre de grandeur et unité scannée. |
| Résultat | Reçu stable réutilisable par les consommateurs. |
| Invalidation | Événements précis rendant le reçu obsolète. |
| Télémétrie | Compteur d'appels, cache hit/miss, durée et unités scannées. |

Un consommateur NE DOIT PAS relancer le même invariant « par sécurité » si un résultat valide du
propriétaire existe déjà pour les mêmes entrées. Il consomme le reçu ou demande au propriétaire de
le produire.

Une validation est relancée seulement si au moins une condition est vraie :

- la `contentRevision` d'une entrée a changé ;
- la `policyRevision` de validation a changé ;
- la portée demandée est plus large que celle du reçu ;
- une frontière de confiance impose de ne pas accepter le reçu existant ;
- un contrôle anti-race doit vérifier l'identité au moment de l'écriture.

La clé de réutilisation couvre au minimum
`(propriétaire, invariant, portée, contentRevision, policyRevision)`. `contentRevision` inclut
toutes les dépendances sémantiques ; `policyRevision` inclut schéma, validateur et toolchain
pertinents. Pour un fichier externe, `storageRevision` est réattestée à la frontière de confiance.
Une mutation in-place rend toute `contentRevision` précédente inutilisable.

Deux demandes concurrentes de la même clé partagent un single-flight ; elles ne lancent pas deux
validations avant la création du reçu. Les caches de reçus et projections sont bornés en entrées et
en octets, exposent leur éviction et ne retiennent pas indéfiniment les anciennes
`contentRevision`/`sessionGeneration`.

## 6. Doubles vérifications autorisées

Une double vérification n'est autorisée que dans l'un des cas suivants :

1. **Frontière de confiance** — donnée externe, désérialisée ou non fiable.
2. **Anti-race / TOCTOU** — `storageRevision` est comparée dans le même CAS ou la même section
   critique que la publication durable.
3. **Atomicité et recovery** — une preuve est requise pour reprendre ou valider une transaction.
4. **Défense en profondeur critique** — invariant de sécurité ou de corruption irréversible.

Chaque exception impliquant une validation complète, récurrente ou mesurée comme coûteuse DOIT
documenter :

- pourquoi le résultat précédent ne peut pas être réutilisé ;
- la frontière de confiance ou la race protégée ;
- sa fréquence maximale ;
- sa complexité et son budget ;
- son span et son compteur de télémétrie ;
- pourquoi elle n'est jamais appelée depuis L0.

Un bounds check `O(1)` défensif reste autorisé en L0 sans reçu ni span. Pour une vérification
coûteuse, « on préfère revérifier », « c'est plus sûr » ou « le validateur est déjà disponible » ne
sont pas des justifications suffisantes.

## 7. Règles Flutter et Riverpod

- Le viewport, le hover, le drag et le tick NE DOIVENT PAS être stockés dans l'agrégat documentaire
  global lorsqu'ils n'en modifient pas le contenu.
- Un événement L0 NE DOIT PAS publier un nouveau `EditorState` whole-document.
- Un widget DOIT sélectionner une projection stable et suffisamment petite pour sa fréquence ; il
  n'est pas nécessaire de fragmenter les providers par cérémonie.
- Un ticker DOIT invalider uniquement le sous-arbre visible qui contient une animation réellement
  active.
- `animationActivation=always` n'autorise pas un tick si le preset résolu n'emploie aucune source
  animée visible.
- Les projections de catalogue, chemins, couleurs, footprints et résolutions DOIVENT être mises en
  cache par `contentRevision` stable, indépendamment du viewport.
- Un `Future` d'IO DOIT être créé hors de `build` et mémorisé jusqu'à l'invalidation de ses entrées.
- Le playback Cinematics DOIT rester dans un sous-arbre animé local ; il ne doit pas appeler le
  `setState` d'un builder monolithique à chaque tick.
- Une `RepaintBoundary` PEUT isoler un coût raster prouvé. Elle ne remplace ni l'isolation de l'état
  ni la réduction du travail de build.

## 8. Règles de persistence et d'authoring

- Le document validé, le snapshot et le plan DOIVENT porter leur `contentRevision`. Le plan et le
  reçu d'apply portent aussi les `storageRevision` durables attendues/observées.
- La phase apply DOIT refuser clairement un plan stale ou le replanifier explicitement.
- L'auteur d'une opération DOIT connaître le delta ; le blob store ou le repository ne doit pas
  redécouvrir les ressources touchées par comparaison whole-project.
- Les payloads before/after DEVRAIENT être limités aux ressources affectées quand les garanties
  d'undo et de recovery peuvent être préservées.
- Une queue durable DOIT sérialiser les writes concurrents sur la même ressource.
- Un hit de cache mémoire NE DOIT PAS refaire copie, hash, canonicalisation et metadata filesystem
  sans raison d'invalidation documentée. Un blob content-addressed doit toujours hasher l'entrée
  nécessaire à son adressage, et trust/TOCTOU/recovery peuvent imposer canonicalisation, stat,
  read-after-write ou relecture.
- Les transports direct API, JSONL/CLI, editor et MCP DOIVENT consommer la même opération canonique
  et la même sémantique métier. Chaque transport conserve sa validation de forme et sa frontière de
  confiance ; un reçu ne traverse pas aveuglément un process ou une donnée désérialisée.

## 9. Mesures et budgets bloquants

Les budgets suivants définissent la lane de référence à 60 Hz. Pour une autre fréquence,
`frameBudget = 1 s / targetHz` et le receipt versionne `targetHz`. Ils sont mesurés en profile sur
la gate de merge et confirmés en release pendant la certification, sur une machine de référence.

| Mesure | Budget |
|---|---:|
| Handler `pointerMove` P95 | `< 8 ms` |
| Frame Flutter P95 | `< 1 frameBudget` |
| Feedback input corrélé P95 | budget F0A/F3 versionné, cible provisoire `≤ 2 frameBudget` |
| Blocage UI d'un commit local P95 | `< 1 frameBudget` |
| Délai avant feedback visible d'un commit asynchrone P95 | `< 1 frameBudget` |
| IO filesystem en L0 | `0` |
| JSON/base64 en L0 | `0` |
| Validation complète en L0 | `0` |
| Snapshot, plan, apply ou journal en L0 | `0` |
| Publications documentaires provoquées uniquement par pan/zoom/hover/tick | `0` |
| Samples de télémétrie perdus dans un receipt | `0` |

Le temps total d'un save asynchrone, d'un cold open, d'un warm open, d'un map open et du
time-to-interactive reçoit un budget provisoire en F0A puis final en F3 sur petit projet, fixture synthétique et clone sûr du
projet réel. Cette matrice numérique versionnée est un prérequis aux lots correctifs : une valeur
absente fait échouer la gate. Une interface responsive ne suffit pas à justifier un save de
plusieurs secondes, et le budget UX total ne peut pas rester à cinq secondes par défaut.

### 9.1 Définition des horloges

Chaque métrique temporelle DOIT déclarer début, fin, horloge monotone, isolate et scénario :

| Métrique | Début | Fin |
|---|---|---|
| Handler input | Entrée `pointer.pre_dispatch` | Retour du handler après publication transitoire locale |
| Feedback input corrélé | `interactionGeneration` locale du dernier événement coalescé | `rasterFinish` de la première frame affichant au moins cette génération |
| Frame Flutter | `vsyncStart` | `rasterFinish` du même `FrameTiming` |
| Blocage UI | Entrée du travail synchrone sur l'isolate UI | Retour au scheduler Flutter |
| Feedback visible | Acceptation de la commande | Fin raster de la première frame affichant preview, progression ou état busy |
| Durée totale | Acceptation de la commande | Reçu durable ou erreur finale présenté à l'appelant |

`FrameTiming` est un proxy du pipeline Flutter, pas une preuve universelle de présentation physique
à l'écran. La gate courte peut l'utiliser avec les compteurs déterministes. La certification globale
DOIT ajouter une trace plateforme corrélée jusqu'au frame present ; sans cette trace, elle reste
`BLOCKED` et `FrameTiming` ne peut pas devenir une preuve de remplacement par commodité.

Un commit asynchrone passe trois gates indépendantes : blocage UI, délai avant feedback et durée
totale. Un bon spinner ne blanchit donc pas une opération qui dure trois cafés.

### 9.2 Échantillonnage et distribution

- chaque scénario interactif homogène contient au minimum 120 échantillons ;
- F0A versionne un minimum d'observations pour chaque lane chère non interactive, notamment save,
  cold/warm open et map open ;
- pointer, frame, commit, save, open et fixtures différentes ne sont jamais agrégés ;
- P50, P95, P99, max et taux au-dessus de un et deux `frameBudget` sont conservés ;
- chaque lane interactive possède des plafonds numériques bloquants P99 et max ; aucun freeze
  isolé ne peut être masqué par un taux de jank moyen ;
- les journeys courts sont exécutés au moins trois fois et chaque répétition doit passer ;
- warm-up, durée, cadence et éventuel trimming sont déclarés avant le run ;
- aucun trimming implicite ou retrait a posteriori d'un outlier n'est autorisé ;
- le commit périodique numéro 25 possède sa propre mesure bloquante ;
- la gate échoue si le nombre minimal d'échantillons n'est pas atteint.

Sous le minimum statistique d'une lane, le receipt publie toutes les observations, la médiane et le
max, mais ne nomme pas le max « P95 » et ne certifie aucune distribution.

Le taux de jank toléré est numérique et propre à la lane/scénario versionné. Les zéros absolus sont
réservés aux travaux interdits déterministes, pas aux outliers de scheduling OS. L'overhead de la
télémétrie est mesuré activée/désactivée sur la même fixture ; la collecte exhaustive échoue si les
répétitions montrent un dépassement statistiquement significatif de `max(5 %, 0,5 ms)`.

### 9.3 Soak réel

- la CI ordinaire conserve une gate courte et déterministe sans faux soak ;
- une lane nightly/release opt-in mesure une durée monotone réelle d'au moins 600 secondes ;
- la certification mesure une durée monotone réelle d'au moins 1 800 secondes ;
- le receipt contient durée demandée, durée observée, timestamps monotones et cycles terminés ;
- une durée observée inférieure échoue, même si un nombre minimal de cycles est atteint ;
- l'application reste visible et au foreground, sans perte de télémétrie, pendant tout le soak.

### 9.4 Mémoire et caches

Les budgets numériques sont propres à chaque fixture, provisoires en F0A puis finaux en F3. Une
fixture sans budgets mémoire ne peut pas passer la gate. Les receipts contiennent :

- heap post-GC initial et final ;
- points post-GC périodiques, croissance et pente par minute ;
- RSS et mémoire externe/native ;
- collections GC ;
- taille en octets et nombre d'entrées de chaque cache obligatoire ;
- nombre de sessions, maps ou documents encore retenus.

Les scénarios couvrent open/close répété, navigation entre workspaces, World Map, Cinematics et le
soak. Une mesure isolée ne suffit pas à conclure à une fuite ; la gate porte sur les budgets et la
pente du scénario versionné.

### 9.5 Provenance obligatoire

Chaque receipt contient et vérifie :

- commit exact et véritable Git tree OID ;
- état Git propre ;
- fingerprint de la fixture et de son générateur ;
- lockfiles, Flutter, Dart, engine et Flame ;
- modèle CPU, RAM, architecture et build macOS ;
- taille de fenêtre, device-pixel-ratio et fréquence écran ;
- mode profile ou release ;
- preuve que l'application est visible et au foreground ;
- détection active du plugin d'intégration ;
- artifact ID ou path relatif du log brut, avec hash, conservé avec le receipt.

Un échec de foreground, un plugin non détecté ou un faux fingerprint calculé seulement depuis un
worktree propre invalide le run.

Toute opération complète/récurrente en `O(map)`, `O(projet)`, `O(catalogue)` ou `O(historique)`, ou
mesurée au-dessus de son seuil versionné, DOIT exposer :

- nombre d'invocations ;
- raison et niveau L1/L2/L3 ;
- identités `contentRevision`/`storageRevision`/`sessionGeneration` pertinentes et cache hit/miss ;
- unités réellement scannées ;
- temps total et P95/P99 quand la fréquence le permet ;
- isolate d'exécution.

### 9.6 Matrice de fixtures

La gate de merge utilise une fixture canonique anonymisée, générée, reproductible et fingerprintée.
Le projet utilisateur réel n'est jamais une dépendance CI. Chaque
scénario versionne :

- extent, nombre de couches et cellules visibles/totales ;
- Smart Tiles, animations et éléments visibles/totaux ;
- taille des catalogues, du manifeste et de l'historique ;
- nombre de maps ;
- cadence des événements et durée idle ;
- script d'entrée déterministe ;
- fingerprint attendu.

La certification ajoute un clone sûr du projet réel. Son fingerprint est enregistré et le run doit
prouver qu'il ne l'a pas muté.

## 10. Scénarios d'acceptation obligatoires

### World Map

- 120 événements de pan/zoom produisent zéro validation complète, zéro IO, zéro JSON/base64 et
  zéro publication documentaire.
- Une World Map idle dont les presets visibles n'ont aucune source animée produit zéro tick de
  repaint canvas dû au classifier Smart Tile, même si le catalogue global contient des animations.
- Lors d'un tick d'animation, une animation visible garde ses unités résolues bornées par
  `visibleBounds` ; les couches cachées ou statiques ne sont pas résolues de nouveau et les
  projections stables produisent des cache hits.
- Les dérivations projet sont préparées une fois par `contentRevision`, pas une fois par frame.

### Strokes, Smart Tiles et masks

- 120 `pointerMove` alimentent un buffer local sparse sans validation complète ni copie pleine
  surface.
- `pointerUp` produit un changement unique réutilisé par validation, dirty state et historique.
- Le 25e commit ne sérialise aucun checkpoint JSON sur l'isolate UI.
- Undo/redo restitue exactement le contenu committé après passage au modèle incrémental.

### Cinematics

- 120 deltas de drag produisent zéro apply et zéro write de recovery avant la fin du geste.
- un geste actif produit au plus un résultat terminal idempotent selon la politique explicite
  commit/rollback ; sans delta actif, `pointerUp`, `pointerCancel`, blur ou deactivate est un no-op ;
  des événements lifecycle répétés ne dupliquent jamais mutation ou rollback.
- Le playback ne reconstruit pas le workspace monolithique à chaque tick.
- Deux applies concurrents ne peuvent pas publier deux résultats calculés depuis la même
  `contentRevision`/`sessionGeneration` sans détection de résultat stale.
- Deux writers partant de la même `storageRevision` sont testés : exactement un publie ; l'autre
  reçoit un conflit, ou est sérialisé puis replanifié sur la nouvelle `storageRevision`.

### Facts et Branding

- Un rebuild sans changement de `contentRevision` ne crée aucun nouveau Future d'IO.
- Le résultat chargé reste réutilisé jusqu'au changement du path, de sa `storageRevision` ou de la
  `contentRevision` concernée.

### Save, apply et validation

- Une opération sur une `contentRevision`/`policyRevision` donnée produit au maximum une validation
  complète par clé et single-flight, hors exceptions documentées de la section 6.
- Snapshot, plan et apply réutilisent les reçus compatibles.
- Toute nouvelle `contentRevision` invalide chaque reçu potentiellement dépendant. Une invalidation
  conservatrice plus large reste autorisée tant que le graphe n'est pas prouvé complet ;
  l'invalidation fine est une optimisation mesurée, jamais prioritaire sur la correctness.
- Une entrée désérialisée non fiable est revérifiée à la frontière de confiance.
- `storageRevision` reste comparée dans le même CAS ou verrou exclusif que la publication atomique.

## 11. Enforcement attendu

Le contrat ne sera considéré comme appliqué que lorsque les six couches suivantes seront présentes.

| Couche | Protection attendue | État au 2026-08-15 |
|---|---|---|
| Contrat canonique | Ce document versionné | Proposition à relire |
| Règle agent | Référence obligatoire depuis `AGENTS.md` | Non implémentée |
| Télémétrie | Niveaux, compteurs de validations, identités, cache hits et unités scannées | Partielle |
| Tests d'architecture | Interdiction déterministe des travaux L2/L3 pendant L0 | Non implémentés |
| Journey full-shell | Frames, rebuilds, ticks et work counters sur scénarios réels | Insuffisant |
| Gate CI/release | Budgets bloquants et receipts exact-SHA | Non implémentée |

Les tests d'architecture ne doivent pas chercher à comprendre arbitrairement tout le code Dart.
Ils doivent faire respecter des frontières instrumentées et des contrats explicites :

- ouverture d'un scope L0 avec identifiant de causalité pendant les gestes, ticks et builds
  critiques ;
- échec immédiat si un compteur interdit est incrémenté dans ce scope ;
- compteur de validations par propriétaire, `contentRevision` et `policyRevision` ;
- compteur des publications documentaires ;
- compteur des préparations de projections et cache hits ;
- contrôle des scénarios full-shell en profile/release.

Les gateways partagées d'IO, codec, validation, publication et persistence propagent l'identifiant
de causalité dans les Futures lancés depuis L0 ; fermer le scope synchrone ne blanchit donc pas un IO
qui s'exécute plus tard. Des tests d'architecture ciblés interdisent les bypass directs de ces
gateways dans les surfaces critiques, sans tenter de parser arbitrairement tout le repo.

Le catalogue de spans, compteurs et propriétaires est versionné. Le receipt liste les frontières
réellement couvertes et échoue si un propriétaire obligatoire manque. Des tests négatifs injectent
volontairement IO, JSON, validation complète et publication documentaire dans un scope L0 et
prouvent que la gate les refuse. La collecte exhaustive doit être explicitement activée et attestée
en profile/release ; des compteurs à zéro sans couverture déclarée ne constituent aucune preuve.

Les assertions de tests ne sont pas actives en production. La télémétrie de production doit rester
légère et échantillonnable ; la gate de certification active la collecte exhaustive.

## 12. Checklist obligatoire de review

Toute PR touchant une interaction, une validation, une projection ou la persistence répond à trois
questions universelles :

- Quel niveau L0/L1/L2/L3 déclenche le nouveau travail ?
- Sa complexité dépend-elle du delta, du visible, de la map, du projet ou de l'historique ?
- Crée-t-elle un IO, codec, validation complète, diff global ou publication documentaire depuis
  L0 ?

Si la PR ajoute ou modifie un travail complet/global, récurrent non trivial, IO/codec ou au-dessus
d'un seuil mesuré, elle répond aussi :

- qui possède l'invariant ou la projection ;
- quelle clé `contentRevision`/`policyRevision`, invalidation, single-flight et éviction s'applique ;
- quels compteurs prouvent le nombre d'invocations et l'overhead ;
- quelle exception justifie une double vérification ;
- quelle gate partagée existante couvre le scénario, ou pourquoi elle doit être étendue.

`N/A` est autorisé avec une justification courte. Une PR ne crée pas un journey cérémoniel si une
gate partagée couvre déjà le risque. Une réponse inconnue sur un travail global/coûteux bloque la
review ; une justification sans mesure ne permet pas de déclarer la performance `DONE`.

## 13. Lots d'implémentation après approbation

### F0A — Protocole et baseline initiale

- versionner la machine/lane, les fixtures anonymisées et leurs fingerprints ;
- définir les budgets numériques provisoires handler, frame P95/P99/max/jank, feedback, commit,
  save, cold/warm open, map open, time-to-interactive, mémoire, caches et overhead ;
- produire une baseline profile avec la télémétrie existante, provenance, foreground et gaps de
  couverture explicitement listés ;
- fixer le nombre minimal d'observations de chaque lane avant le run.

F0A passe en `TO REVIEW` avec receipts exact-SHA, budgets provisoires sans valeur manquante et
limites explicites. Les lots suivants ne peuvent pas revendiquer de gain avant cette baseline.

### F1 — Gouvernance

- référencer ce contrat depuis `AGENTS.md` ;
- ajouter la checklist de review ;
- enregistrer la politique dans le domaine Notion `Performance éditeur`.

### F2 — Frontières et télémétrie

- remplacer le contexte global LIFO de `editor_performance_telemetry.dart` par un contexte
  concurrent-safe avec scopes L0/L1/L2/L3 et causalité async ;
- compter validations par propriétaire/`contentRevision`/`policyRevision`, publications,
  préparations, cache hits et unités ;
- faire échouer les tests quand un travail interdit traverse L0 ;
- propager les identifiants de causalité dans les gateways async et borner l'overhead de collecte ;
- agréger/streamer les samples pour qu'un soak ne dépasse pas silencieusement la capacité du
  recorder ;
- prouver les tests négatifs des gateways L0 et documenter la couverture obtenue.

### F3 — Gate full-shell

F3 contient la calibration F0B : les budgets provisoires deviennent la matrice numérique finale
après instrumentation complète de F2.

- ajouter les scénarios World Map idle/pan/zoom/stroke/25e commit/save ;
- ajouter Cinematics drag/playback et Facts/Branding rebuild ;
- rendre les `FrameTiming` et le travail interdit bloquants en profile/release ;
- mesurer petit et synthétique en CI, puis clone sûr du projet réel uniquement en certification
  locale opt-in, cold et warm ;
- versionner budgets save/open/time-to-interactive, mémoire et matrice de fixtures ;
- refuser les receipts sans foreground, provenance complète ou couverture instrumentée.

### F4 — Corrections prioritaires guidées par la trace

F4 est une phase/epic, jamais un lot de livraison unique. Elle DOIT être découpée en tickets
verticaux isolés, avec fichiers, tests, preuves et livraison propres ; leur regroupement dans un
même changement est interdit par défaut.

- F4A — faux positif d'animation Smart Tile ;
- F4B — index et projections cachés par `contentRevision` stable ;
- F4C — viewport, hover et drag isolés de l'état documentaire ;
- F4D — commit, historique et checkpoint delta-bounded ;
- F4E — persistence et journal hors interaction ;
- F4F — Futures Facts/Branding stabilisés ;
- F4G — drag, recovery et playback Cinematics stabilisés.

### F5 — Certification

- exécuter les journeys full-shell exact-SHA ;
- certifier une durée monotone release d'au moins 10 minutes en nightly/release opt-in et 30 minutes
  en certification ;
- conserver les receipts et limites dans Notion ;
- laisser le lot de certification en `TO REVIEW` jusqu'à décision explicite de l'utilisateur.

Ordre exécutable :

```text
F0A baseline existante → F2 instrumentation → F3/F0B calibration finale
    → F4A à F4G corrections isolées → F5 certification

F1 gouvernance peut avancer en parallèle après approbation explicite.
```

## 14. Fichiers probables, sans modification dans cette phase

- `AGENTS.md` ;
- `packages/map_editor/lib/src/application/services/editor_performance_telemetry.dart` ;
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart` ;
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` ;
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` ;
- `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_workspace.dart` ;
- `packages/map_editor/test_driver/performance_driver.dart` ;
- `packages/map_editor/integration_test/editor_project_journey_test.dart` ;
- `packages/map_editor/integration_test/editor_performance_soak_journey_test.dart` ;
- `packages/map_authoring/lib/src/support/authoring_performance_observer.dart` ;
- `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart` ;
- nouveaux tests ciblés sous `packages/map_editor/test/architecture/` et
  `packages/map_editor/integration_test/`.

La liste sera resserrée par lot avant toute implémentation. Les transports authoring et MCP seront
audités dès qu'une sémantique canonique est modifiée.

## 15. Non-objectifs et protections

- Ne pas supprimer les validations complètes nécessaires.
- Ne pas supprimer atomicité, recovery, idempotence ou contrôles anti-race.
- Ne pas remplacer globalement l'égalité structurelle par l'identité.
- Ne pas créer une migration massive de providers avant une trace réelle.
- Ne pas confondre ajout d'une `RepaintBoundary` avec suppression du travail de build.
- Ne pas nettoyer les historiques de transactions dans le lot interactif.
- Ne pas ajouter de compatibilité pre-`1.0.0` sans exigence explicite.
- Ne pas déclarer le problème résolu sur la seule base de tests unitaires ou de widgets isolés.

## 16. Critères de sortie

### BETA-PERF-011 — contrat documentaire

Le lot `BETA-PERF-011` peut passer en `TO REVIEW` lorsque :

- le document a reçu une review architecture, validation et critique sans objection bloquante ;
- le contrat écrit a été remis à l'utilisateur pour review ;
- son statut réel, ses non-objectifs et ses limites sont cohérents dans le repo et Notion ;
- les commandes d'hygiène documentaire et l'état Git final sont conservés.

Ce passage ne signifie pas que le contrat est enforced ni que les performances sont certifiées.
L'approbation explicite de l'utilisateur valide le contrat et peut faire passer ce ticket
documentaire en `DONE`. Elle n'autorise pas implicitement l'édition de F0A à F5 ni aucune opération
Git : chaque lot et chaque Git write gardent leur autorisation propre selon `AGENTS.md`.

### Lots F0A à F5

Chaque lot possède ses propres critères, tests, receipts, fichier(s), SHA et statut. Il peut passer
isolément en `TO REVIEW` après preuve fraîche de son scope sans attendre les autres lots. Aucun lot
ne peut revendiquer le verdict global à lui seul.

### Certification globale

La certification globale peut passer en `TO REVIEW` uniquement si :

- les règles L0 à L3 sont référencées depuis la gouvernance du repo ;
- les scénarios d'acceptation critiques sont automatisés ;
- aucun travail interdit n'est observé en L0 ;
- toute la matrice numérique versionnée des sections 9.2 à 9.6 passe sans budget absent, incluant
  handler, frame P95/P99/max/jank, save/open/map-open/time-to-interactive, mémoire et caches ;
- les durées monotones de soak d'au moins 600 secondes en nightly/release et 1 800 secondes en
  certification sont réellement observées ;
- la trace plateforme frame present, le foreground, la provenance et la couverture instrumentée
  sont complets ;
- les validations globales ont un propriétaire, une `contentRevision`, une `policyRevision` et un
  compteur ;
- les résultats sont conservés sur l'exact SHA testé ;
- les garanties de cohérence, undo/redo, recovery et anti-race restent vertes ;
- les limitations et scénarios non couverts sont explicitement listés.

`DONE` reste une décision explicite de l'utilisateur après review. Un test local vert ne suffit pas
à transformer une application qui lag en application certifiée fluide — ce serait un très joli
mensonge, mais toujours un mensonge.
