# NS-EVENT-V2 V0 — Contrat visuel de référence

## 1. Lot, statut et verdict exécutif

- **Lot exact :** `V0 — Figer le contrat visuel avant l’intégration UI`.
- **Statut à cette révision :** `VERIFYING` après replay vert du gate Phase 1,
  dans l'attente de l'approbation utilisateur de l'exception P2 proposée.
- **Référence canonique :**
  `packages/map_editor/test/goldens/event_builder_v2/reference/event_builder_v2_reference_1672x941.png`.
- **Dimensions :** `1672 × 941` pixels.
- **SHA-256 :**
  `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885`.

Ce contrat fige la composition, la densité, la hiérarchie et l’état métier à
comparer. Il ne déclare pas que la route produit actuelle correspond déjà à
la référence. La mesure de l’écart réel, les corrections et l’overlay final
restent respectivement les lots K1, K2 et K3.

## 2. Scope confirmé et décisions produit

V0 ne modifie aucun contrat Event, Scene, Map ou runtime et n’applique aucun
polish à la production. Il conserve les décisions déjà ratifiées avec
l’utilisateur :

- `Event ≠ Scene` ;
- l’Event référence une source physique déjà créée sur une map ;
- la map est dérivée de la source atomique, jamais choisie dans un sélecteur
  indépendant de l’Event Builder ;
- les résultats, réactions, combats, dialogues, cinématiques, inventaire et
  changements du monde appartiennent à la Scene liée et sont projetés en
  lecture seule ;
- les cibles de drop visibles dans l’image ne deviennent pas de faux contrôles
  tant qu’un drag-and-drop réel, clavier et testé n’existe pas.

Ces divergences fonctionnelles conservent la hiérarchie visuelle de la
référence sans mentir sur l’ownership métier.

## 3. Provenance et reproductibilité

La provenance historique est documentée dans
`ns_event_reset_00_event_builder_v2_reference_ui_spec_v0.md`. La copie de ce
contrat est autonome : aucun test ne dépend d’un chemin Desktop ou d’un asset
extérieur au dépôt.

État de comparaison figé :

- plateforme de capture : macOS ;
- viewport physique : `1672 × 941` ;
- device pixel ratio : `1.0` ;
- text scale : `text scale 1.0` ;
- thème : PokeMap sombre ;
- locale et libellés : français ;
- police de capture candidate :
  `NsEventV2PhaseKCaptureFont` chargée depuis Arial système ;
- mode : `EventSystemMode.dualRead` ;
- projet : `Selbrume Demo` ;
- recherche vide, filtre `all`, side sheet fermé ;
- Event sélectionné : `event:rival`, « Rencontre rival au port », actif ;
- groupe : « Port Selbrume » ;
- source : interaction avec le Rival sur Port Selbrume ;
- deux conditions, Scene « Rencontre rival », projections en lecture seule et
  réutilisation one-shot ;
- scrolls à zéro, aucune animation en cours, aucun hover et aucun focus forcé.

Le builder de fixture `buildEventBuilderV2PhaseKReadModel()` reste un support
de comparaison déterministe. Son chrome synthétique n’est jamais une preuve de
route produit : K doit capturer l’application réellement montée.

## 4. Les huit zones normatives

Coordonnées au format `x, y, largeur, hauteur` :

| Ordre | Zone | Rectangle normatif |
|---:|---|---:|
| 1 | Enveloppe fenêtre | `0, 0, 1672, 941` |
| 2 | Header marque | `0, 0, 1672, 50` |
| 3 | Barre contexte/actions | `207, 50, 1465, 52` |
| 4 | Navigation produit | `8, 102, 191, 817` |
| 5 | Colonne Événements | `207, 102, 266, 817` |
| 6 | Bibliothèque | `481, 102, 213, 817` |
| 7 | Éditeur central | `702, 102, 565, 817` |
| 8 | Inspecteur | `1275, 102, 388, 817` |

La lecture du raster place visuellement le premier bord de l’Inspecteur autour
de `x = 1274`. Le contrat Flutter retient `x = 1275`, seule valeur cohérente
avec trois gouttières structurelles de 8 px :

```text
207 + 266 + 8 + 213 + 8 + 565 + 8 = 1275
```

Cette différence de bord de 1 px est une exception P2 **proposée** par le
présent contrat. Elle reste en attente d'une approbation explicite de
l'utilisateur et ne peut pas masquer un écart de largeur ou une gouttière
incorrecte.

Ordre obligatoire à droite de la navigation :

```text
Événements → Bibliothèque → Éditeur → Inspecteur
```

## 5. Grille et espacements structurants

- origine verticale du workspace : `y = 102 px` ;
- hauteur utile des panneaux : `817 px` ;
- gouttières métier : `8 px` ;
- largeur métier totale entre `x = 207` et le bord droit : `1456 px` ;
- la colonne centrale absorbe en priorité les écarts de largeur ;
- aucune barre de défilement horizontale cachée ;
- à `1672 × 941`, les quatre panneaux métier restent simultanément visibles ;
- le sélecteur de projet visible en haut de la navigation reste inclus dans le
  chrome de navigation, mais ne devient pas une neuvième zone de comparaison.

## 6. Sévérités et tolérances

### P0 — Bloquant, tolérance zéro

Un seul de ces écarts invalide la comparaison :

- mauvais fichier, hash, dimensions, viewport, mode, projet ou Event ;
- zone normative absente, réordonnée ou remplacée ;
- overflow, clipping majeur ou panneau inaccessible ;
- contrôle visiblement interactif sans comportement réel ;
- violation de `Event ≠ Scene` ou map sélectionnée indépendamment de la source ;
- capture K issue d’un harness au lieu de la route produit ;
- perte de sélection, de contexte ou de données projet lors du flow principal.

### P1 — Structure et géométrie

- bord de panneau : `±4 px` maximum ;
- gouttière : `±2 px` maximum ;
- hauteur de chrome : `±3 px` maximum ;
- baseline de titre : `±3 px` maximum ;
- largeur de colonne : `±1,5 %` maximum ;
- aucune différence de hiérarchie principale.

Tout dépassement P1 exige une correction avant clôture K2 ; il ne peut pas
être reclassé silencieusement en détail cosmétique.

### P2 — Détail visible

- géométrie interne et padding : `±2 px` ;
- taille ou hauteur de texte : `±1 px` ;
- épaisseur de bordure : `±1 px` ;
- rayon : `±2 px` ;
- icônes, ports, densité et accents : comparaison visuelle contextualisée ;
- couleurs : tokens sémantiques PokeMap et contraste AA, sans exiger une
  égalité RGB avec la maquette.

Un écart P2 au-delà de ces seuils doit être corrigé ou consigné comme exception
explicitement approuvée. La proposition `Inspecteur x = 1275` ci-dessus est la
seule exception géométrique initiale et ne sera considérée comme approuvée
qu'après confirmation explicite de l'utilisateur.

## 7. Méthode de comparaison K

1. ouvrir la vraie route produit sur le projet et l’Event figés ;
2. stabiliser viewport, DPR, text scale, police, scrolls et animations ;
3. capturer l’application complète, pas seulement le workspace ;
4. créer une image côte-à-côte référence/candidate à taille identique ;
5. créer un overlay 50 % ;
6. classer chaque écart P0, P1 ou P2 ;
7. corriger, recapturer et comparer de nouveau ;
8. conserver les artefacts et hashes de la capture finale.

Une capture seule n’est pas un QA visuel. La référence et la candidate doivent
être inspectées ensemble.

## 8. Audit initial et verdicts indépendants

État Git initial de la Phase 1 : `42` fichiers suivis modifiés, `84` fichiers
non suivis, soit `126` entrées. Le checkout contenait déjà F2, G, la candidate
H/K, les preuves L et des changements non Event ; aucune opération Git
d’écriture n’a été exécutée.

- **Audit / Architecture :** G est implémenté mais attend sa preuve route ; V0
  était absent ; la route produit montait toujours V1 ; H2 n’existait que dans
  un harness/state isolé.
- **Tests :** les tests K existants validaient la géométrie candidate mais pas
  les octets de la référence ni la route produit.
- **Audit visuel :** dimensions et SHA-256 confirmés ; huit zones et seuils
  P0/P1/P2 proposés ; le bord Inspecteur `1274/1275` a été identifié avant H.

## 9. Fichiers du lot V0

### Créés

- `packages/map_editor/test/goldens/event_builder_v2/reference/event_builder_v2_reference_1672x941.png`
  — copie binaire canonique ; contenu identifié par le hash et les dimensions
  de la section 1 ;
- `packages/map_editor/test/ui/canvas/event_builder_v2_reference_contract_test.dart`
  — garde automatisée du hash, des dimensions, de la fixture et du contrat ;
- `reports/narrativeStudio/events/ns_event_v2_v0_visual_contract.md`
  — présent contrat.

### Modifiés

Aucun fichier de production n’est modifié par V0.

## 10. Tests, analyse et build du lot

RED observé avant l’ajout des artefacts :

```text
flutter test --no-pub test/ui/canvas/event_builder_v2_reference_contract_test.dart
00:00 +1 -2: Some tests failed.
```

Les deux échecs attendus étaient l’absence de la référence versionnée et du
présent contrat. Les résultats GREEN, l’analyse, le format, le build et l’état
Git final sont consignés dans l’Evidence Pack vivant de la Phase 1 après H2,
afin de ne pas figer ici des preuves périmées par les modifications suivantes.

## 11. Limites, auto-critique et risques conservés

- La police de capture dépend encore d’Arial macOS ; une police de projet
  versionnée rendrait la capture portable.
- La fixture porte encore un nom Phase K bien que V0 la réutilise ; ce renommage
  serait cosmétique et reste hors scope de ce lot.
- Le contrat ne valide pas le rendu actuel : il protège uniquement la cible.
- Les défauts globaux préexistants du package editor ne sont ni masqués ni
  corrigés par V0.
- Le binaire ne peut pas être reproduit comme texte intégral dans un rapport ;
  son contenu complet est attesté par le SHA-256 canonique et son décodage PNG.

Prochaine étape de clôture : obtenir l'approbation utilisateur de l'exception
P2 proposée, puis fermer les dépendances formelles dans l'ordre prévu.
