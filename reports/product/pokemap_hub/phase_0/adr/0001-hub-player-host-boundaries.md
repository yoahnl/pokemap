# ADR-0001 — Frontières Hub, player, runtime et host

- Statut : **Accepted**
- Date : 2026-07-25
- Décisions : P0-D01, P0-D02, P0-D03

## Contexte

Le runtime est jouable, mais le repository ne possède ni produit Hub, ni format
installable, ni bibliothèque multijeu. Le host actuel mélange volontairement
chargement direct de workspace, choix de map, seeds, debug et évaluations.

## Décision

Créer ultérieurement trois unités séparées :

- `packages/map_distribution` : Dart pur, package, manifest, canonicalisation,
  compatibilité, validation, receipts ;
- `packages/map_player_ui` : Flutter, design system et surfaces joueur ;
- `apps/pokemap_hub` : composition, stockage plateforme, bibliothèque,
  installation, lifecycle et supervision des sessions.

`examples/playable_runtime_host` reste un harness interne. Il ne sera ni renommé,
ni importé, ni empaqueté comme Hub.

```text
map_core <── map_distribution
    ▲                ▲
    │                │
map_gameplay     pokemap_hub ──> map_player_ui
    ▲                │                 │
    └──── map_runtime ◀────────────────┘
              ▲
         map_battle
```

La flèche signifie « dépend de ». Le schéma simplifie les dépendances déjà
existantes ; les interdictions ci-dessous font foi.

## Règles contraignantes

- `map_distribution` NE DOIT PAS dépendre de Flutter, Flame, du runtime, de
  l’éditeur ou du Hub.
- `map_runtime` NE DOIT PAS dépendre de `map_player_ui`,
  `map_distribution`, `map_editor` ou du Hub.
- `map_player_ui` NE DOIT PAS dépendre de `map_editor` ou du Hub. Il PEUT
  consommer uniquement les snapshots/ports publics de `map_runtime`.
- le Hub PEUT dépendre de distribution, runtime et player UI ; il NE DOIT PAS
  importer le code du host.
- `map_battle` reste un moteur pur et n’est pas réécrit.
- les règles métier ne sont jamais cachées dans des widgets ou composants Flame.

## Ownership

`GameIdentity` et `SaveEnvelope` sont des contrats partagés de `map_core`.
Les types de package et receipts appartiennent à `map_distribution`. Les
snapshots et ports de session appartiennent à `map_runtime`. La bibliothèque,
les chemins Application Support et le superviseur plateforme appartiennent au
Hub. Les composants visuels appartiennent à `map_player_ui`.

## Conséquences

Le Hub peut évoluer sans polluer le moteur, et le host conserve sa vitesse
d’itération. Une petite surface de contrats publics runtime doit être stabilisée.
Certains adaptateurs seront implémentés deux fois (in-process et child-process),
mais derrière un même port.

## Alternatives rejetées

- transformer directement le host : expose le debug et fige des dépendances de
  harness dans le produit ;
- faire dépendre le runtime de l’UI : inverse l’ownership ;
- placer les modèles de package dans `map_core` : impose la distribution à tous
  les consommateurs du cœur.

## Tests futurs

- gardes d’imports par package ;
- analyse Dart pure de `map_distribution` ;
- test que le Hub n’importe aucun chemin `examples/playable_runtime_host` ;
- caractérisation du host avant et après branchement du nouveau runtime public.

## DONE

ADR accepté, ownership exhaustif, sens des dépendances testable et aucun contrat
partagé sans propriétaire.
