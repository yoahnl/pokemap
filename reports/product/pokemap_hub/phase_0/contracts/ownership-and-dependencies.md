# Ownership et dépendances

## Matrice d’ownership

| Contrat / service | Propriétaire | Consommateurs autorisés | Interdictions |
|---|---|---|---|
| `GameIdentity` | `map_core` | distribution, runtime, Hub | aucune donnée plateforme |
| `SaveEnvelope` + codec | `map_core` | runtime, Hub | aucun filesystem |
| manifest, SemVer, hashes, validator, receipt | `map_distribution` | Hub, export éditeur futur | aucune UI/runtime |
| gameplay pur | `map_gameplay` | runtime | aucun Flutter/Flame |
| battle pur | `map_battle` | runtime | aucune UI |
| snapshots dialogue/combat/session | `map_runtime` | Hub, player UI, host | aucune dépendance UI |
| `GameSessionPort` | `map_runtime` | Hub, host | implémentation plateforme hors runtime pur |
| design system et écrans joueur | `map_player_ui` | Hub | aucun editor |
| library, installer orchestration, paths, supervisor | Hub | aucun package bas niveau | aucun import du host |
| authoring/export | `map_editor` | package de distribution | aucune clé/secrets dans projection |
| seeds/debug/evaluations | host | développement uniquement | jamais dans release Hub |

## Graphe autorisé

```text
apps/pokemap_hub
├── packages/map_distribution
├── packages/map_runtime
└── packages/map_player_ui

packages/map_player_ui ──> API de présentation publique de map_runtime
packages/map_distribution ──> map_core
packages/map_runtime ──> map_core + map_gameplay + map_battle
```

Les cycles sont interdits. En particulier :

```text
map_runtime -X-> map_player_ui
map_runtime -X-> map_distribution
map_player_ui -X-> map_editor
map_distribution -X-> Flutter | Flame | Hub | editor
pokemap_hub -X-> examples/playable_runtime_host
```

## Futurs fichiers principaux

- `packages/map_core/lib/src/game_identity.dart`
- `packages/map_core/lib/src/save/save_envelope.dart`
- `packages/map_distribution/lib/src/...`
- `packages/map_runtime/lib/src/session/...`
- `packages/map_player_ui/lib/...`
- `apps/pokemap_hub/lib/...`

Les barrels publics existants doivent exporter les contrats publics. Les
adaptateurs filesystem/IPC restent privés aux apps.

## Tests d’architecture futurs

Chaque package doit posséder une garde qui analyse ses `pubspec.yaml` et imports.
Le test échoue sur toute arête interdite. `map_distribution` doit réussir
`dart analyze` sans SDK Flutter. Le Hub doit échouer si un import commence par
un chemin du host ou de l’éditeur.

## Risques et dépendances

La player UI a besoin de snapshots stables, pas d’objets Flame. Le déplacement
de saves existantes nécessite une façade de compatibilité transitoire. Les
contrats runtime publics doivent rester petits pour éviter que l’UI ne pilote
directement le moteur.
