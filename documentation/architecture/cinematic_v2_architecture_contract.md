# Cinematic V2 — contrat d'architecture

| Champ | Valeur |
|---|---|
| Ticket | `BETA-CIN-001` |
| Statut | Accepté par Yoahn le 14 août 2026 |
| Contrat exécutable | `documentation/architecture/contracts/cinematic_v2_contract_v1.json` |
| SHA audité | `bc16af2aa790c1e0fd24347331866879413edaf7` |
| Portée | ADR, matrices et gates uniquement |

Ce document fixe les décisions P0 de CIN-V2. Il ne crée aucun modèle Dart, aucune exécution runtime et aucune UI. Le JSON compagnon est la projection machine-readable normative ; le test `cinematic_v2_architecture_contract_test.dart` empêche la dérive de ses invariants structurants.

## État audité

Au SHA audité :

- `ProjectVersion` s'arrête à `v6` ;
- `ProjectManifest` possède déjà `cinematics`, `cinematicMediaAssets`, `scenes`, `newGame` et `presentation` ;
- `CinematicAsset` décrit une cinématique monde liée aux maps, acteurs et comportements Flame ;
- `ProjectNewGameConfig` porte encore `starterSelectionSceneId` ;
- aucune phase du Player ne représente `preSession` ;
- `RuntimeAudioMixer` existe dans `map_runtime`, tandis que la vidéo d'introduction possède encore son propre driver audio ;
- les locks prouvent `video_player` sur Android, Apple et Web, pas sur Windows ou Linux ;
- le registre MCP connaît `cinematic`, mais les ressources Presentation et leur parité sémantique 4/4 n'existent pas encore.

Ces faits ne deviennent pas des garanties de support par le seul fait d'être mentionnés ici. Chaque promotion reste portée par son ticket d'implémentation et sa preuve fraîche.

## Principes non négociables

1. Les cinématiques monde et Presentation sont deux familles distinctes.
2. La voie `preSession` textuelle fonctionne sans Presentation, vidéo ou Studio.
3. `Scene` reste le graphe d'orchestration ; une timeline Presentation ne devient pas un second moteur narratif.
4. Une seule autorité existe pour le rendu, l'évaluation temporelle et l'audio.
5. Les versions, capabilities et plateformes sont fail-closed.
6. Une ancienne sauvegarde n'est jamais altérée avant le commit réussi d'une nouvelle partie.
7. Après le cutover strict, aucun dual-reader, writer legacy, fallback ou migration runtime ne subsiste.

## CIN-ADR-001 — Version projet et capability gate

CIN-V2 exige `ProjectVersion.v7` et les capabilities `scene.preSession` et `cinematic.presentation`. Un projet `v6` sans donnée V2 reste lisible selon les garanties déjà existantes. Toute donnée V2 dans un manifeste antérieur est invalide. Un runtime qui ne connaît pas `v7` rejette le projet avant preview ou exécution.

`PresentationCinematicAsset` possède en plus sa propre version de schéma locale, initialement `1`. Une version future inconnue est rejetée ; elle n'est jamais interprétée comme une version courante partielle.

Conséquence de test : `CIN-002` couvre le codec local de l'asset, `CIN-062` couvre la version projet, l'ownership manifeste et les erreurs de version ; `CIN-042` fournit le canary de compatibilité.

## CIN-ADR-002 — Familles cinématiques disjointes

La famille monde conserve `CinematicAsset`, l'espace d'identifiants `worldCinematic` et un nœud `worldCinematic`. La famille hors engine utilise `PresentationCinematicAsset`, l'espace `presentationCinematic` et un nœud `presentationCinematic`.

Il est interdit :

- d'étendre `CinematicAsset` avec une collection de champs nullable Presentation ;
- de déduire la famille à partir des champs présents ;
- de partager un identifiant polymorphe entre les deux familles ;
- d'appliquer un fallback d'une famille vers l'autre.

La première promotion Presentation cible `preSession` et la preview. Son usage dans les scènes monde/interludes reste différé à `BETA-CIN-009` après certification.

Les deux familles sont organisées par un `CinematicLibraryCatalog` séparé des assets. Il porte des identifiants de dossiers stables, une hiérarchie récursive et un ordre persistant par famille. Il référence les `CinematicAsset` monde sans les modifier. `map_authoring` possède les opérations de création, déplacement, renommage, archivage et suppression gardée, avec rejet des cycles, collisions dans un même parent et suppression d'un dossier non vide. La parité API directe, CLI/JSONL, Editor et MCP est obligatoire avant la Library.

## CIN-ADR-003 — Profils Scene et capabilities

`Scene` reste l'unique graphe. Chaque scène déclare un profil d'exécution explicite : `world` ou `preSession`. La même matrice de capabilities est consommée par le codec, la validation, l'authoring et le runtime.

Le profil `preSession` V1 autorise :

- start, end, branchement, merge et conditions locales au draft ;
- assignation structurée au draft ;
- présentation d'un `PresentationCinematicAsset` ;
- requêtes message, choix, texte, confirmation et sélection.

Il refuse les dialogues Yarn tant qu'un adaptateur dédié n'existe pas, les actions monde, combats, cinématiques monde, maps, warps, shops, PC et facts monde. Une capability inconnue est refusée au build et au runtime avec le même code stable.

## CIN-ADR-004 — Interactions structurées awaitables

Le moteur émet des requêtes typées et attend des résultats typés. Aucun caractère, composition IME ou contrôle UI brut ne traverse `RuntimeInputEvent`.

Les requêtes V1 sont `message`, `choice`, `text`, `confirmation` et `selection`. Chaque requête produit exactement un résultat terminal, y compris l'annulation. Le texte est compté en grappes de graphèmes Unicode et la composition IME est obligatoire.

Les widgets structurés appartiennent à `map_player_ui`; les modèles et validations appartiennent à `map_core`.

## CIN-ADR-005 — Timeline absolue et déterministe

La timeline utilise des microsecondes entières avec `1 000 000` ticks par seconde. Les clips occupent des intervalles semi-ouverts `[startUs,endUs)`. Les pistes partagent la même timebase et peuvent s'exécuter simultanément.

Les pistes V1 sont visuelles, audio, captions et markers. Une interaction n'est jamais une piste exécutable : un `interactionCue` de durée nulle porte un identifiant stable distinct de son libellé et indique uniquement l'instant. `Scene` référence le couple `presentationCinematicId + interactionCueId`, possède la requête et son résultat, puis reprend la même exécution au temps narratif retenu. Les markers ordinaires restent non bloquants ; renommage, duplication et suppression d'un cue respectent son identité et ses références.

Le runtime utilise une horloge monotone. Une pause demandée par l'utilisateur ou le lifecycle fige narration et médias. Un hold d'interaction fige seulement l'horloge narrative et les animations authored : la musique et une vidéo de fond déjà actives continuent ou bouclent, tandis qu'un son one-shot ne redémarre jamais. La reprise continue au temps narratif retenu sans seeker l'ambiance qui a continué. La preview et le scrub emploient une horloge éditeur explicite et un seek déterministe. Les easings sont évalués par le même évaluateur pur.

## CIN-ADR-006 — Résultats d'exécution exact-once

Une exécution se termine exactement une fois par `completed`, `skipped`, `cancelled` ou `failed`. `disposed` est une raison d'annulation, pas un cinquième résultat. Un callback tardif est ignoré grâce au token de run.

La restauration n'est possible que depuis un checkpoint explicitement défini. V1 n'invente pas de restauration implicite depuis une frame ou un callback média.

## CIN-ADR-007 — Transaction New Game

La chaîne canonique est :

```text
ProjectNewGameConfig immuable
→ NewGameDraft immuable et révisionné
→ NewGameSeed
→ projection map_gameplay
→ GameState
→ session et sauvegarde
```

Le slot et l'éventuel overwrite sont choisis et confirmés avant `preSession`. Le commit utilise un token composé de la révision projet, du slot et de la révision du draft. Il est exact-once. Annulation, erreur, crash et rejet stale laissent l'ancienne sauvegarde intacte.

En V1, un crash abandonne le draft et renvoie à l'écran titre au prochain lancement. La persistance/reprise d'un draft est différée.

## CIN-ADR-008 — Entrypoint unique et migration contrôlée

Le seul champ runtime V2 est `ProjectNewGameConfig.preSessionSceneId`. `starterSelectionSceneId` ne reste pas un alias lu en parallèle.

La migration est une opération authoring hors ligne explicite :

1. dry-run sans mutation ;
2. résolution de la scène référencée ;
3. validation complète contre la whitelist `preSession` ;
4. rapport des changements ;
5. apply avec contrôle de révision.

Une scène incompatible bloque l'opération sans mutation. Après le cutover, le champ legacy est rejeté. Aucune auto-migration n'a lieu au chargement runtime.

## CIN-ADR-009 — Phase Player et preload

Le Player introduira une phase `preSession` distincte entre la décision slot/overwrite et la création de `GameState`. Cette phase possède un token de run et refuse les callbacks provenant d'une révision projet ou d'un run périmé.

Après la décision de slot, le preload peut lire des octets immuables du projet et de la map de départ. Il ne peut créer ni `GameState`, ni session, ni instance monde, ni descripteur de sauvegarde. Ses ressources sont bornées et libérées sur skip, cancel, échec ou lifecycle stop.

## CIN-ADR-010 — Autorité audio/vidéo et lifecycle

`RuntimeAudioMixer` est l'unique autorité audio runtime. Une vidéo est soit muette, soit `mixerManaged`; son audio ne contourne jamais le mixer. Ducking, mute, volume et pause lifecycle restent cohérents avec les bus existants.

Chaque occurrence de média Presentation peut fournir une source paysage et une source portrait pour les images, vidéos, voix et effets sonores. La musique reste une source partagée unique. Si une seule variante existe, elle est utilisée dans les deux compositions. Les deux variantes partagent le timing et le trim du clip ; une paire dont une source ne couvre pas la plage commune est refusée jusqu'à correction explicite.

Un seul décodeur vidéo peut être actif en V1. Préparation, remplacement, eviction cache, backgrounding, skip, erreur et dispose libèrent les handles. Le cache est un LRU borné ; sa taille exacte est promue par `BETA-CIN-032` après profilage, pas choisie au doigt mouillé dans cet ADR.

## CIN-ADR-011 — Catalogue média transactionnel et sécurisé

Un média possède un `mediaId` logique stable et un hash SHA-256 de contenu distinct. Les chemins canoniques sont :

```text
projet  : assets/presentation/cinematics/<mediaId>/<file>
package : presentation/cinematics/media/<mediaId>/<file>
```

L'import suit `stage → probe réel → validation → hash → publication atomique du manifeste → cleanup/rollback`. Le probe compare header/MIME et extension. Les chemins sont canonisés sous une racine projet étroite ; traversal, symlink escape, TOCTOU, bombes de décompression et tailles excessives sont rejetés.

Le graphe de références gouverne remplacement et suppression. Poster, captions/locales, licence, source et hash sont des métadonnées de premier rang. Le package exporté est utilisable offline.

Les plafonds normatifs initiaux reprennent les protections de distribution existantes : archive et payload total `1 GiB`, `20 000` entrées, fichier `256 MiB`, image `8192 px` et `67 108 864` pixels. Presentation ajoute un plafond total de `220 MiB`, une séquence de `15 min`, une vidéo de `3840×2160` et un décodeur actif. Ces valeurs sont des limites authoring à revoir avec les mesures de `CIN-032`, jamais une promesse que toute plateforme les lit confortablement.

## CIN-ADR-012 — Évaluateur et renderer partagés

`map_core` possède l'évaluateur pur. `map_runtime` produit l'état d'exécution sans dépendre d'une UI. `map_player_ui` possède le renderer Flutter partagé, consomme cet état dans la surface Player et porte les widgets d'interaction ainsi que l'adaptateur vidéo. `map_editor` réutilise le renderer pour la preview avec une horloge contrôlée.

Il est interdit d'entretenir un renderer de preview divergent ou un second évaluateur dans l'éditeur.

## CIN-ADR-013 — Parité authoring 4/4

Les transports requis sont : API directe, CLI/JSONL, Editor et MCP. La sauvegarde JSON globale n'est pas une preuve sémantique.

`cinematic` reste la ressource monde. V2 ajoute `presentationCinematic` et `presentationMedia`; `scene` expose les opérations `preSession`. Les préfixes d'actions sont `presentationCinematic.*`, `presentationMedia.*` et `scene.preSession.*`.

`map_authoring` porte la sémantique, les queries et le graphe de références. Aucun transport ne réimplémente les règles dans sa couche d'adaptation.

`Créer et lier` ouvre un brouillon local récupérable absent du manifeste et du graphe. Les médias importés restent en staging transactionnel. `Enregistrer` ou `⌘S` publie atomiquement la Presentation, le nœud Scene, la référence et les médias staged, puis reste dans l'éditeur ; `Enregistrer et revenir` applique la même transaction puis restaure le contexte exact du graphe. Le commit produit une seule entrée undo. Annulation ou échec laisse zéro mutation projet et zéro orphelin. Une Scene devenue stale refuse la publication tout en conservant le brouillon récupérable.

## CIN-ADR-014 — Accessibilité, localisation et input

Les surfaces Editor sont conçues pour souris et clavier uniquement, avec IME, screen reader et ordre de focus. Le Player certifie séparément clavier, tactile et gamepad, ainsi que l'IME, le screen reader et l'ordre de focus. Les préférences reduced motion et reduced flashes gagnent toujours sur l'intention authored. Captions localisées, skip, pause et replay sont certifiables.

Le fallback captions suit locale demandée, locale projet par défaut, puis état explicite indisponible. Il ne masque jamais silencieusement l'absence d'une ressource obligatoire.

## CIN-ADR-015 — Diagnostics stables et vie privée

Les événements observables couvrent prepare, start, fallback, skip, failure et dispose, avec exactement un terminal par run. La corrélation utilise `runId`, révision projet, ID d'asset, hash de contenu et code stable.

Les logs n'enregistrent jamais nom du joueur, texte soumis, texte de captions ou chemin absolu. Les diagnostics doivent être exportables depuis Editor/runtime/MCP sans données personnelles.

Les codes initiaux sont définis dans le contrat JSON. L'UI les localise ; elle ne parse pas des messages libres.

## CIN-ADR-016 — Budgets et promotion plateforme

Les gates V1 demandent `50` cycles lifecycle, un décodeur maximum, zéro handle média final, une dérive RSS d'au plus `10 %` entre les cycles 5 et 50, skip p95 sous `100 ms`, poster p95 sous `500 ms`, première frame vidéo p95 sous `1 s`, aucun stall main isolate au-delà de `100 ms` et `99 %` des frames UI sous `16,7 ms` dans le scénario certifié.

La décision `BETA-CIN-047` reste volontairement prudente :

| Plateforme | Image | Audio | Vidéo | Captions | Gate |
|---|---|---|---|---|---|
| macOS | supporté | supporté | supporté | supporté | build + lifecycle, SPM uniquement |
| iOS | supporté | supporté | supporté | supporté | build plateforme et distribution Xcode Cloud |
| Android | supporté | supporté | supporté | supporté | build plateforme et distribution GitHub Release |
| Web | non supporté | non supporté | non supporté | non supporté | rejet avant résolution média, aucun runner commité |
| Windows | cible | cible | fallback poster uniquement | cible | build + lancement release avant promotion |
| Linux | cible | cible | fallback poster uniquement | cible | build + lancement release avant promotion |

Un statut `target` n'est pas un statut `supported`. La présence d'un runner, d'un dossier plateforme ou d'un plugin n'est jamais une preuve de support. Web reste fail-closed tant qu'un runner et un parcours autoplay, codecs et offline ne sont pas certifiés. Windows et Linux exigent un poster explicite pour toute vidéo de présentation et restent des cibles jusqu'à une preuve build + lancement fraîche.

## CIN-ADR-017 — Canary et retrait legacy strict

Le cutover suit impérativement :

```text
BETA-CIN-042 canary
→ BETA-CIN-043 suppression core/runtime
→ BETA-CIN-044 suppression authoring/UI/CLI/MCP
→ BETA-CIN-010 gate zéro legacy
→ BETA-LCH-001 builds/lifecycle
→ BETA-CIN-008 certification finale
```

Après `CIN-010`, il ne reste aucun dual-reader, fallback, bridge, writer legacy ou auto-migration runtime. La suppression ne commence pas avant le canary.

## Graphe de packages

| Package | Responsabilité CIN-V2 |
|---|---|
| `map_core` | modèles, codecs, capabilities, erreurs, draft/seed, évaluateur pur |
| `map_gameplay` | projection `NewGameSeed → GameState` |
| `map_authoring` | opérations/queries sémantiques et graphe de références |
| `map_runtime` | orchestration preSession, horloge, transaction save, mixer, lifecycle |
| `map_player_ui` | renderer partagé, interactions structurées, adaptateur vidéo |
| `map_distribution` | sécurité, package offline et preflight plateforme |
| `map_editor` | Studio, preview partagée et authoring guidé |

`map_player_ui` peut dépendre de `map_runtime` selon l'architecture actuelle. L'inverse est interdit. `map_core` et `map_gameplay` restent purs Dart. `map_authoring` ne dépend pas de l'éditeur. `map_editor` ne consomme pas les internals du runtime.

## Deux rails de livraison

Le rail pré-session textuel couvre `CIN-003`, `004`, `005`, `007`, `016`, `034` et `035`. Il interdit toute dépendance à `cinematic.presentation`. Il doit atteindre son canary même si vidéo, compositing ou Studio ne sont pas prêts.

Le rail Presentation couvre modèle, catalogue, évaluateur, renderer, média, authoring et Studio. Les deux rails ne se joignent qu'au point d'intégration explicite `BETA-WLD-008`, puis aux certifications globales.

## Non-objectifs et reports V1

- Aucun modèle, codec, runtime ou écran de production dans `BETA-CIN-001`.
- Pas de Yarn en pré-session sans adaptateur dédié.
- Pas de Presentation dans les scènes monde avant `BETA-CIN-009`.
- Pas de checkpoint persistant de `NewGameDraft` en V1.
- Pas de vidéo Windows/Linux sans promotion `CIN-047`.
- Pas de logique non linéaire dans une timeline.
- Pas de deuxième renderer, évaluateur ou autorité audio.
- Pas de conversion legacy automatique au runtime.

## Validation humaine

Yoahn a validé explicitement le 14 août 2026 :

- `ProjectVersion.v7` et les deux capability IDs ;
- `preSessionSceneId` comme entrypoint unique ;
- l'abandon du draft après crash en V1 ;
- les limites produit `220 MiB`, `15 min`, `3840×2160`, un décodeur ;
- Windows/Linux vidéo non supportés par défaut ;
- le cutover strict sans compatibilité runtime legacy.

Le contrat est donc `accepted` et `BETA-CIN-001` peut être clôturé `DONE`. Cette acceptation ne promeut aucun ticket d'implémentation : chaque lot conserve ses propres dépendances et preuves de sortie.
